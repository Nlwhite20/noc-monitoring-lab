# NOC Monitoring Lab Safety Rules

This repository supports an authorized personal home-lab monitoring project only.

## Authorized Scope

- Monitor only localhost and virtual machines I own in my isolated home lab.
- Do not monitor, scan, probe, or test public systems, employer systems, school systems,
  neighbors, customer systems, or third-party networks.
- Use synthetic or sanitized monitoring evidence in GitHub documentation.

## Required Approval

Ask before:
- Running `sudo`, installing software, starting Docker containers, or changing VM settings
- Changing firewall or network settings
- Creating checks outside localhost or explicitly approved personal lab VMs
- Deleting containers, volumes, dashboards, alerts, or files
- Committing, pushing, or sending data outside the local lab

## Security

- Do not expose Grafana, Prometheus, Uptime Kuma, or dashboards to the public internet.
- Do not commit passwords, tokens, API keys, cookies, `.env` files, or raw logs.
- Bind web services to localhost or an isolated lab network unless I explicitly approve otherwise.
- Use unique non-default dashboard credentials.

## Documentation

For each monitored service and simulated outage, document:
- Purpose
- Expected behavior
- Verification
- Alert behavior
- Troubleshooting runbook
- Recovery and rollback
