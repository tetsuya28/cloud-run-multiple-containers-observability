locals {
  name   = "cloud-run-mco" // cloud-run-multiple-containers-observability
  region = "asia-northeast1"
}

variable "project_id" {
  type = string
}

terraform {
  required_version = "1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.84.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = local.region
}

resource "google_project_service" "default" {
  for_each = toset([
    "artifactregistry.googleapis.com",
		"run.googleapis.com",
  ])
  project = var.project_id
  service = each.value
}

resource "google_artifact_registry_repository" "default" {
  location      = local.region
  repository_id = local.name
  format        = "DOCKER"
}

resource "google_service_account" "default" {
  account_id   = local.name
  display_name = local.name
}

resource "google_project_iam_member" "default" {
  for_each = toset([
    "roles/cloudtrace.agent",
    "roles/monitoring.metricWriter",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.default.email}"
}
