# Create a VM instance

locals {
  aws_creds           = jsondecode(google_secret_manager_secret_version.aws_credentials_version.secret_data)
  dns_config          = jsondecode(google_secret_manager_secret_version.dns_config_version.secret_data)
  merged_vars         = merge(local.aws_creds, local.dns_config)
  update_dns_script   = base64encode(file("${path.module}/../update-dns/update_dns.py"))
}

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
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id
    access_config {
      # This empty block requests a public IPv4 address
    }
  }

  tags = ["ssh-iap"]

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml.tpl", {
      env_vars          = jsonencode(local.merged_vars)
      aws_region        = var.aws_region
      update_dns_script = local.update_dns_script
    })
    ssh-keys = var.ssh_key
  }

  service_account {
    email  = google_service_account.main.email
    scopes = ["cloud-platform"]
  }
}

resource "google_service_account" "main" {
  account_id   = "${var.project}-sa"
  display_name = "Service Account for ${var.project}"
  project      = var.project
}
