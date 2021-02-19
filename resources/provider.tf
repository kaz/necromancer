variable "project" {}

locals {
  region = "asia-northeast1"
}

terraform {
  backend "gcs" {
    prefix = "necromancer"
  }
}

provider "google" {
  project = var.project
  region  = local.region
}
