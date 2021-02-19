resource "google_service_account" "necromancer" {
  account_id   = "necromancer"
  display_name = "necromancer"
}

resource "google_compute_instance_iam_binding" "instance_iam_binding" {
  zone          = google_compute_instance.dying_instance.zone
  instance_name = google_compute_instance.dying_instance.name
  role          = "roles/compute.instanceAdmin"

  members = [
    "serviceAccount:${google_service_account.necromancer.email}",
  ]
}

resource "google_service_account" "dying_man" {
  account_id   = "dying-man"
  display_name = "dying-man"
}

resource "google_pubsub_topic_iam_binding" "topic_iam_binding" {
  topic = google_pubsub_topic.resurrection_topic.name
  role  = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.dying_man.email}",
  ]
}
