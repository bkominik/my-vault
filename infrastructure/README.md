# My Vault - Cloud Server Infrastructure

This project contains the configuration for automatically provisioning a cloud server using `cloud-init`. The primary goal is to create a standardized, ready-to-use server environment with Docker and a dynamic DNS service that automatically points a domain name to the server's public IP address.

This setup is designed to be used as `user data` when launching a new cloud instance (e.g., on AWS EC2 or Lightsail).

## Features

The `cloud-init.yaml.tpl` script automates the following tasks on server boot:

-   **User Setup**: Creates a non-root administrative user `barryk` with passwordless `sudo` privileges and adds them to the `docker` group.
-   **System Preparation**: Updates all system packages to their latest versions.
-   **Package Installation**: Installs essential software, including:
    -   Docker Engine, Docker Compose, and related tools.
    -   Python 3, Pip, and the AWS SDK (`boto3`).
    -   Common command-line utilities (`htop`, `nmap`, `tmux`, `zsh`, etc.).
-   **Dynamic DNS (DDNS)**:
    -   Deploys a Python script that fetches the instance's public IP.
    -   Creates/updates a DNS 'A' record in an AWS Lightsail managed domain to point to that IP.
    -   Runs this script as a `systemd` service (`update-dns.service`) to ensure it starts on boot and restarts on failure.
-   **Docker Configuration**: Configures the Docker daemon with log rotation to prevent log files from consuming excessive disk space.

## Prerequisites

1.  **Cloud Provider**: An AWS account. The DDNS script is written specifically for **AWS Lightsail**.
2.  **Managed Domain**: A domain name managed within AWS Lightsail.
3.  **Templating Tool**: A tool like OpenTofu or Terraform to process the `.tpl` file and substitute variables.
4.  **IAM Role**: An IAM Role for the instance with permissions to manage Lightsail DNS records. This is the most secure way to grant access and is required for the `update-dns` script to function.

## Usage

This configuration is a template and is not meant to be used directly. It must be processed by a tool that can substitute the placeholder variables.

1.  **Define Variables**: You need to provide values for the following variables:
    -   `${aws_region}`: The AWS region where your Lightsail domain is hosted (e.g., `us-east-1`).
    -   `${env_vars}`: A block of environment variables required by the `update-dns` script.

2.  **Render the Template**: Use your deployment tool to render the `cloud-init.yaml.tpl` file.

    For example, using Terraform/OpenTofu, you might have something like this:

    ```hcl
    data "template_file" "cloud_init" {
      template = file("${path.module}/cloud-init.yaml.tpl")

      vars = {
        aws_region = "us-east-1"
        env_vars = <<-EOT
          DOMAIN_NAME=example.com
          RECORD_NAME=server1
        EOT
      }
    }

    resource "aws_lightsail_instance" "my_server" {
      # ... other configuration
      user_data = data.template_file.cloud_init.rendered
    }
    ```
    *   `DOMAIN_NAME`: The domain you have registered in Lightsail (e.g., `example.com`).
    *   `RECORD_NAME`: The subdomain you want to point to this server (e.g., `server1` for `server1.example.com`, or `@` for the root domain).

3.  **Launch Instance**: Provide the rendered YAML content as "user data" when launching your new cloud instance. Attach the required IAM Instance Role at launch time.

## Security: IAM Permissions

**Do not use hardcoded AWS access keys.** The `update-dns` script is designed to work with an IAM Role attached to the instance. This is a critical security best practice.

The IAM Role must have a policy granting the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lightsail:GetDomain",
                "lightsail:UpdateDomainEntry",
                "lightsail:CreateDomainEntry"
            ],
            "Resource": "*"
        }
    ]
}
```

This policy adheres to the principle of least privilege by only allowing the actions necessary for the DDNS script to function.

## Troubleshooting

If the server does not configure correctly, you can check the `cloud-init` logs on the instance.

```bash
# View the full output log
cat /var/log/cloud-init-output.log

# Check the status of cloud-init stages
cloud-init status

# Check the status of the DDNS service
systemctl status update-dns.service
journalctl -u update-dns.service
```