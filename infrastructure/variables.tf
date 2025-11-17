variable "project" {
  description = "The GCP project ID to deploy resources into."
  type        = string
  # No default is set to ensure the project is explicitly provided.
}

variable "region" {
  description = "The GCP region to deploy resources into."
  type        = string
  default     = "us-central1"
}

variable "machine_type" {
  type        = string
  description = "Instance type for the VM. e.g., e2-micro for the free tier."
  default     = "e2-micro"
}

variable "image" {
  type        = string
  description = "The OS image for the VM."
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "ssh_key" {
  type        = string
  description = "User's public SSH key for VM access."
  sensitive   = true # Mark as sensitive to prevent it from being shown in logs/outputs.
}

variable "ssh_source_ranges" {
  type        = list(string)
  description = "A list of CIDR blocks to allow SSH access from. Includes Google's IAP range."
  default     = ["35.235.240.0/20"] # Default to Google IAP range
}

variable "portainer_source_ranges" {
  type        = list(string)
  description = "A list of CIDR blocks to allow Portainer agent access from."
  default     = []
}

variable "aws_access_key_id" {
  description = "AWS access key ID."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "The AWS region."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "The domain name for the DNS record."
  type        = string
}

variable "record_name" {
  description = "The record name for the DNS record."
  type        = string
}