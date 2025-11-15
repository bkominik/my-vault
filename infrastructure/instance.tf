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
    # Using the default network for simplicity.
    # Replace with your custom network if needed.
    network = "default"
    access_config {
      # This empty block requests a public IPv4 address
    }
  }

  tags = ["ssh-iap"]

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml.tpl", {
      env_vars   = google_secret_manager_secret_version.aws_credentials_version.secret_data
      aws_region = var.aws_region
    })
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}
