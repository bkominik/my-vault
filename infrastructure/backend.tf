terraform {
  backend "gcs" {
    bucket = "terraform-state-401"  # Replace with your bucket name
    prefix = "vault-terraform-state"        # Optional prefix for state files
  }
}

