@if(gcp)
package main

// 秘匿フィールドとして変数定義
#scraping_targets: [
	"localhost:8080",
]

#exporter: {
	googlemanagedprometheus: {
		project: "${PROJECT_ID}"
	}
	googlecloud: {
		trace: {
			endpoint: "https://cloudtrace.googleapis.com"
		}
	}
}

#pipelines: {
	metrics: {
		receivers: ["prometheus"]
		exporters: ["googlemanagedprometheus"]
	},
 	traces: {
 		receivers: ["otlp"]
		exporters: ["googlecloud"]
 	}
}
