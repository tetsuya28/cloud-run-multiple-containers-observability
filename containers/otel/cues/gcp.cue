@if(gcp)
package main

// 秘匿フィールドとして変数定義
#scraping_targets: [
	"localhost:8080",
]

#exporter: {
	googlemanagedprometheus: {
		project: "${PROJECT_ID}"
		retry_on_failure: {
			enabled: true
		}
	}
	googlecloud: {
		trace: {
			endpoint: "cloudtrace.googleapis.com:443"
		}
	}
}

#pipelines: {
	metrics: {
		receivers: ["prometheus"]
		processors: ["batch"]
		exporters: ["googlemanagedprometheus"]
	},
 	traces: {
 		receivers: ["otlp"]
		exporters: ["googlecloud"]
 	}
}
