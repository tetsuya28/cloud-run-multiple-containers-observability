package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/labstack/echo-contrib/echoprometheus"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"

	"github.com/tetsuya28/cloud-run-multiple-containers-observability/containers/app/config"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"google.golang.org/grpc"
)

const (
	DefaultComponentName = "app"
)

var (
	tracer = otel.Tracer(DefaultComponentName)
)

func main() {
	cfg, err := config.NewConfig()
	if err != nil {
		panic(err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	cleanup, err := SetupTraceProvider(ctx, cfg)
	if err != nil {
		panic(err)
	}
	defer cleanup()

	e := echo.New()
	e.HideBanner = true
	e.HidePort = true

	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(echoprometheus.NewMiddleware(DefaultComponentName))

	e.GET("/", home)
	e.GET("/metrics", echoprometheus.NewHandler())

	e.Logger.Fatal(e.Start(":8080"))
}

func home(c echo.Context) error {
	_, span := tracer.Start(c.Request().Context(), "home")
	defer span.End()
	return c.JSON(http.StatusOK, nil)
}

func NewExporter(ctx context.Context, cfg *config.Config) (sdktrace.SpanExporter, error) {
	client := otlptracegrpc.NewClient(
		otlptracegrpc.WithInsecure(),
		otlptracegrpc.WithEndpoint(cfg.OtelCollectorEndpoint),
		otlptracegrpc.WithDialOption(grpc.WithBlock()),
	)

	exporter, err := otlptrace.New(ctx, client)
	if err != nil {
		return nil, err
	}

	return exporter, nil
}

func SetupTraceProvider(ctx context.Context, cfg *config.Config) (func(), error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	exporter, err := NewExporter(ctx, cfg)
	if err != nil {
		return nil, err
	}

	r := resource.NewWithAttributes(
		semconv.SchemaURL,
		semconv.ServiceNameKey.String(DefaultComponentName),
	)

	traceProvider := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(r),
	)

	otel.SetTracerProvider(traceProvider)

	cleanup := func() {
		ctx, cancel1 := context.WithTimeout(ctx, 5*time.Second)
		defer cancel1()
		if err := traceProvider.ForceFlush(ctx); err != nil {
			panic(err)
		}

		ctx, cancel2 := context.WithTimeout(ctx, 5*time.Second)
		defer cancel2()
		if err := traceProvider.Shutdown(ctx); err != nil {
			panic(err)
		}
	}

	return cleanup, nil
}
