@if(local)
package main

// 秘匿フィールドとして変数定義
#scraping_targets: [
	"app:8080",
]

#external_labels: {}

#exporter: {
	prometheusremotewrite: {
		endpoint: "http://victoriametrics:8428/api/v1/write"
	}
	otlp: {
		endpoint: "http://tempo:4317"
		tls: {
			insecure: true
		}
	}
}

#pipelines: {
	metrics: {
		receivers: ["prometheus"]
		exporters: ["prometheusremotewrite"]
	},
	traces: {
		receivers: ["otlp"]
		exporters: ["otlp"]
	}
}

#processors: {}
