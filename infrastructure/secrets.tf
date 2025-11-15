
resource "google_secret_manager_secret" "aws_credentials" {
  secret_id = "aws-credentials"
  project   = var.project

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "aws_credentials_version" {
  secret      = google_secret_manager_secret.aws_credentials.id
  secret_data = jsonencode({
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  project   = google_secret_manager_secret.aws_credentials.project
  secret_id = google_secret_manager_secret.aws_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_compute_instance.main.service_account[0].email}"
}
