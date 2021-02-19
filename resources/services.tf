resource "google_project_service" "service" {
  for_each = toset([
    "iam.googleapis.com",
    "pubsub.googleapis.com",
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project = var.project
  service = each.key
}
