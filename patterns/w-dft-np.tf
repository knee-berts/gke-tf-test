terraform {
  required_providers {
    google = {
      version = "~> 4.10.0"
    }
  }
}

data "google_client_openid_userinfo" "me" {
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in"
}

variable "region" {
  type        = string
  description = "The region to host the cluster in"
  default     = "us-central1"
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-central1"
  node_locations = ["us-central1-b"]

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = false
  initial_node_count       = 12
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_locations = ["us-central1-b"]
  initial_node_count       = 12
  autoscaling {
    min_node_count = 1
    max_node_count = 13
  }
  management {
    auto_upgrade       = true
    auto_repair        = true
  }
  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    image_type         = "COS_CONTAINERD"
    disk_type          = "pd-ssd"
    disk_size_gb       = 30
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}