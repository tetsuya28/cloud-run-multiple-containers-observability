GCP_PROJECT ?=
APP = cloud-run-mco
TARGET ?= app # app or otel
DOCKER_REGISTRY := asia-northeast1-docker.pkg.dev/$(GCP_PROJECT)/$(APP)/$(TARGET)

.PHONY: cue-export
cue-export:
	cue export ./containers/otel/cues --out yaml -t local > ./configs/otel/local.yaml
	cue export ./containers/otel/cues --out yaml -t gcp > ./configs/otel/gcp.yaml

.PHONY: docker/push-all
docker/push-all:
	$(MAKE) docker/push TARGET=app
	$(MAKE) docker/push TARGET=otel

.PHONY: docker/build
docker/build: DOCKER_TAG ?= $(shell git rev-parse --short HEAD)
docker/build:
	docker build --platform linux/amd64 -t $(DOCKER_REGISTRY):$(DOCKER_TAG) -f ./containers/$(TARGET)/Dockerfile .

.PHONY: docker/push
docker/push: docker/build
docker/push: DOCKER_TAG ?= $(shell git rev-parse --short HEAD)
docker/push:
	docker push $(DOCKER_REGISTRY):$(DOCKER_TAG)

.PHONY: terraform/apply
terraform/apply:
	cd terraform && terraform apply -var="project_id=$(GCP_PROJECT)"

.PHONY: cloud-run/deploy
cloud-run/deploy:
	gcloud --project $(GCP_PROJECT) run services --region asia-northeast1 replace service.yaml
