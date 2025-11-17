
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
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  project   = google_secret_manager_secret.aws_credentials.project
  secret_id = google_secret_manager_secret.aws_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.main.email}"
}

resource "google_secret_manager_secret" "dns_config" {
  secret_id = "dns-config"
  project   = var.project

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "dns_config_version" {
  secret      = google_secret_manager_secret.dns_config.id
  secret_data = jsonencode({
    DOMAIN_NAME = var.domain_name
    RECORD_NAME = var.record_name
  })
}

resource "google_secret_manager_secret_iam_member" "dns_config_accessor" {
  project   = google_secret_manager_secret.dns_config.project
  secret_id = google_secret_manager_secret.dns_config.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.main.email}"
}
