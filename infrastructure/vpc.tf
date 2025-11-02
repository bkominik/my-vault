# Create a VPC network
resource "google_compute_network" "main" {
  name                    = "${var.project}-network"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "main" {
  name          = "${var.project}-subnet"
  ip_cidr_range = "10.128.0.0/20"
  network       = google_compute_network.main.id # Use the 'id' attribute
}

resource "google_compute_firewall" "allow_web" {
  name    = "${var.project}-allow-web"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh-v4" {
  name    = "${var.project}-allow-ssh-v4"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
}

resource "google_compute_firewall" "allow_portainer-agent" {
  name    = "${var.project}-allow-portainer-agent"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["9001"]
  }

  source_ranges = var.portainer_source_ranges
}
