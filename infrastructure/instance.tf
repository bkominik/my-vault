
# Create a VM instance
resource "google_compute_instance" "main" {
  name         = var.project
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = google_compute_network.main.self_link
    subnetwork = google_compute_subnetwork.main.self_link

    access_config {
      # This empty block requests a public IPv4 address
    }
  }

  tags = ["server"]

  metadata = {
    ssh-keys  = var.ssh_key
    user-data = file("cloud-init.yaml")
  }
}



