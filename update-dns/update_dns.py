#!/usr/bin/env python3

import boto3
import requests
import os

# Configuration
DOMAIN_NAME = "kominik.net"
RECORD_NAME = "test"
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
        # Look up existing domain entries to get the required `id` for update
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
            # No existing entry found; create a new one
            domain_entry = {"name": record, "type": "A", "target": ip}
            lightsail.create_domain_entry(domainName=DOMAIN_NAME, domainEntry=domain_entry)
            print(f"Successfully created DNS record for {record} -> {ip}")
    except Exception as e:
        print(f"Error updating DNS record: {e}")


if __name__ == "__main__":
    public_ip = get_public_ip()
    print("Public IP:", public_ip)
    record = fqdn(RECORD_NAME, DOMAIN_NAME)
    print(f"Setting {record} to {public_ip}")
    update_dns_record(public_ip)
