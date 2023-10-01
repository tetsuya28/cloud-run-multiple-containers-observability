package config

import (
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	OtelCollectorEndpoint string `envconfig:"OTEL_COLLECTOR_ENDPOINT" required:"true"`
}

func NewConfig() (*Config, error) {
	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}
