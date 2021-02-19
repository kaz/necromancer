resource "google_compute_instance" "dying_instance" {
  name         = "dying-instance"
  machine_type = "e2-micro"
  zone         = "${local.region}-b"

  allow_stopping_for_update = true

  network_interface {
    network = "default"
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = "projects/arch-linux-gce/global/images/family/arch"
    }
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  service_account {
    email  = google_service_account.dying_man.email
    scopes = ["pubsub"]
  }

  metadata = {
    shutdown-script    = file("../shutdown-script.py")
    resurrection-topic = google_pubsub_topic.resurrection_topic.id
  }
}
