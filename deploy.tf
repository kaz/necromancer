variable "project" {}

locals {
  name   = "necromancer"
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

resource "google_service_account" "sa" {
  account_id   = local.name
  display_name = local.name
}

resource "google_compute_instance_iam_binding" "instance_iam_binding" {
  zone          = google_compute_instance.instance.zone
  instance_name = google_compute_instance.instance.name
  role          = "roles/compute.instanceAdmin"

  members = [
    "serviceAccount:${google_service_account.sa.email}",
  ]
}

resource "google_pubsub_topic_iam_binding" "topic_iam_binding" {
  topic = google_pubsub_topic.topic.name
  role  = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.sa.email}",
  ]
}

resource "google_compute_instance" "instance" {
  name         = local.name
  machine_type = "e2-micro"
  zone         = "${local.region}-b"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  service_account {
    email  = google_service_account.sa.email
    scopes = ["pubsub"]
  }

  metadata = {
    shutdown-script    = file("shutdown-script.py")
    ressurection-topic = google_pubsub_topic.topic.id
  }
}

data "archive_file" "archive" {
  type        = "zip"
  output_path = "source.zip"

  dynamic "source" {
    for_each = ["index.js", "package.json", "package-lock.json"]

    content {
      filename = source.value
      content  = file(source.value)
    }
  }
}

resource "google_storage_bucket_object" "object" {
  name   = "${data.archive_file.archive.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.archive.output_path
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.project}-${local.name}"
  location = local.region
}

resource "google_cloudfunctions_function" "function" {
  name = local.name

  runtime             = "nodejs14"
  entry_point         = "ressurect"
  timeout             = 300
  available_memory_mb = 128

  service_account_email = google_service_account.sa.email
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.object.name

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.topic.id
  }
}

resource "google_pubsub_topic" "topic" {
  name = local.name
}

resource "google_cloud_scheduler_job" "job" {
  name     = local.name
  schedule = "*/15 * * * *"

  pubsub_target {
    topic_name = google_pubsub_topic.topic.id
    data       = base64encode("zone=${google_compute_instance.instance.zone}&instance=${google_compute_instance.instance.name}&timeout=0")
  }
}
