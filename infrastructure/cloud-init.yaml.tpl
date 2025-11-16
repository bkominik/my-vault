#cloud-config

users:
  - name: barryk
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: docker, sudo, adm
    shell: /usr/bin/zsh

package_update: true
package_upgrade: true

packages:
  # For docker
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  # Utilities
  - htop
  - nmap
  - dnsutils
  - tmux
  - netcat-openbsd
  - whois
  - python3-pip
  - python3-boto3
  - python3-requests
  - zsh
  - jq

write_files:
  - path: /etc/infrastructure.env
    content: |
      ${env_vars}
    permissions: '0600'
    owner: root:root

  - path: /usr/local/bin/update-dns
    permissions: "0755"
    content: |
      #!/usr/bin/env python3
      import boto3
      import requests
      import os

      # Configuration
      DOMAIN_NAME = os.environ.get("DOMAIN_NAME", "FQDN")
      RECORD_NAME = os.environ.get("RECORD_NAME", "test")
      AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
      
      def get_public_ip():
          """Fetches the public IP address."""
          try:
              response = requests.get("https://api.ipify.org")
              response.raise_for_status()
              return response.text
          except requests.exceptions.RequestException as e:
              print(f"Error getting public IP: {e}")
              return None
      def fqdn(record_name, domain_name):
          """Return the fully qualified domain name"""
          if record_name == "@" or record_name == domain_name:
              return domain_name
          return f"{record_name}.{domain_name}"
      def update_dns_record(ip):
          """Updates the Lightsail DNS A record."""
          if not ip:
              return
          record = fqdn(RECORD_NAME, DOMAIN_NAME)
          try:
              lightsail = boto3.client("lightsail", region_name=AWS_REGION)
              domain = lightsail.get_domain(domainName=DOMAIN_NAME)
              entries = domain.get("domain", {}).get("domainEntries", []) if isinstance(domain, dict) else []
              matching = None
              for e in entries:
                  if e.get("name") == record and e.get("type") == "A":
                      matching = e
                      break
              if matching and matching.get("id"):
                  domain_entry = {
                      "id": matching.get("id"),
                      "name": record,
                      "type": "A",
                      "target": ip,
                  }
                  lightsail.update_domain_entry(domainName=DOMAIN_NAME, domainEntry=domain_entry)
                  print(f"Successfully updated DNS record for {record} to {ip}")
              else:
                  domain_entry = {"name": record, "type": "A", "target": ip}
                  lightsail.create_domain_entry(domainName=DOMAIN_NAME, domainEntry=domain_entry)
                  print(f"Successfully created DNS record for {record} -> {ip}")
          except Exception as e:
              print(f"Error updating DNS record: {e}")
      if __name__ == "__main__":
          public_ip = get_public_ip()
          record = fqdn(RECORD_NAME, DOMAIN_NAME)
          print(f"Setting {record} to {public_ip}")
          update_dns_record(public_ip)

  - path: /etc/systemd/system/update-dns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=Update DNS record
      After=network.target
      [Service]
      Environment="AWS_REGION=${aws_region}"
      EnvironmentFile=/etc/infrastructure.env.sh
      ExecStart=/usr/local/bin/update-dns
      Restart=on-failure
      [Install]
      WantedBy=multi-user.target

runcmd:
  # Create the environment file for the update-dns service
  - jq -r 'to_entries|map("export \(.key)=\(.value)")|.[]' /etc/infrastructure.env > /etc/infrastructure.env.sh

  # Enable and start the update-dns service
  - systemctl daemon-reload
  - systemctl enable update-dns.service
  - systemctl start update-dns.service

  # Add Docker's official GPG key:
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - chmod a+r /etc/apt/keyrings/docker.gpg

  # Add the Docker repository to Apt sources:
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Update apt and install Docker packages
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Configure Docker daemon for security (logging driver with size limits)
  - mkdir -p /etc/docker
  - |
    printf '%s' '{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }' | tee /etc/docker/daemon.json > /dev/null

  # Restart docker to apply changes
  - systemctl restart docker
