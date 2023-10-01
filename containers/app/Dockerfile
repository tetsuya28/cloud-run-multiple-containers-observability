FROM golang:1.21 as builder

ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

WORKDIR /build

COPY ./containers/app/go.mod .
COPY ./containers/app/go.sum .
RUN go mod download

COPY ./containers/app .

RUN go build -o main main.go

CMD [ "air" ]

FROM alpine:3.15.0
WORKDIR /

COPY --from=builder /build/main /main

CMD [ "/main" ]
