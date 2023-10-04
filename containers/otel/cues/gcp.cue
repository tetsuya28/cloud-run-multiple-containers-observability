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
			endpoint: "cloudtrace.googleapis.com:443"
		}
	}
}

#pipelines: {
	metrics: {
		receivers: ["prometheus"]
		processors: ["batch", "resourcedetection", "resource"]
		exporters: ["googlemanagedprometheus"]
	}
 	traces: {
 		receivers: ["otlp"]
		exporters: ["googlecloud"]
 	}
}

#processors: {
  processors: {
		batch: {
  	  send_batch_max_size: 200
  	  send_batch_size: 200
			timeout: "5s"
		}
  	// https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/resourcedetectionprocessor/README.md#google-cloud-run-services-metadata
		resourcedetection: {
			detectors: ["env", "gcp"]
		}
		resource: {
			attributes: [
				{
					key: "service.name"
					value: "${env:K_SERVICE}"
					action: "upsert"
				},
				{
					key: "service.instance.id"
					from_attribute: "faas.id"
					action: "insert"
				}
			]
		}
	}
}
