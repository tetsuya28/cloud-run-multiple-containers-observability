GCP_PROJECT ?=
APP = cloud-run-multiple-containers-observability
DOCKER_REGISTRY := asia-northeast1-docker.pkg.dev/$(GCP_PROJECT)/$(APP)/$(APP)

.PHONY: cue-export
cue-export:
	cue export ./containers/otel/cues --out yaml -t local > ./configs/otel/local.yaml
	cue export ./containers/otel/cues --out yaml -t gcp > ./configs/otel/gcp.yaml

.PHONY: docker/build
docker/build: DOCKER_TAG ?= $(shell git rev-parse --short HEAD)
docker/build:
	docker build -t $(DOCKER_REGISTRY):$(DOCKER_TAG) .

.PHONY: docker/push
docker/push: docker/build
docker/push: DOCKER_TAG ?= $(shell git rev-parse --short HEAD)
docker/push:
	docker push $(DOCKER_REGISTRY):$(DOCKER_TAG)

.PHONY: terraform/apply
terraform/apply:
	cd terraform && terraform apply -var="project_id=$(GCP_PROJECT)"
