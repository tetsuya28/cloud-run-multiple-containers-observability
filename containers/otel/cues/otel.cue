package main

receivers: {
 	otlp: {
 		protocols: {
 			grpc: {
				endpoint: "0.0.0.0:4317"
 			}
 		}
 	}
	prometheus: {
		config: {
			global: {
				external_labels: {
					service:     "${K_SERVICE}"
					revision:    "${K_REVISION}"
					cluster: "${K_SERVICE}"
					location: "asia-northeast1"
					namespace: "cloud-run"
				}
			}

			scrape_configs: [
				{
					job_name:        "cloud-run-otel"
					scrape_interval: "10s"
					static_configs: [
						{
							targets: ["localhost:8888"]
						},
					]
				}, {
					job_name:        "cloud-run"
					scrape_interval: "10s"
					metrics_path:    "/metrics"
					static_configs: [
						{
							targets: #scraping_targets
						},
					]
				},
			]
		}
	}
}

processors: {
	resourcedetection: {
		detectors: ["gcp"],
		timeout:   "10s",
	}
}

exporters: #exporter

service: {
	telemetry: {
		logs: {
			level:    "WARN"
			encoding: "json"
		}
	}
	extensions: ["health_check"]
	pipelines: #pipelines
}

extensions: {
	health_check: null
}
