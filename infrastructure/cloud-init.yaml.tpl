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
      ${update_dns_script}

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
  - jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' /etc/infrastructure.env > /etc/infrastructure.env.sh
  - chmod 600 /etc/infrastructure.env.sh

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
