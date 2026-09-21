# Deployment Plan

## Status

Deployed on the `noc-monitoring` VM. The Compose file, Prometheus config and Grafana datasource are version-controlled here; the real `.env` exists only on the VM.

## Service Exposure

| Service | Port | Access method |
|---|---:|---|
| Grafana | 3000 | VM localhost only; access from macOS through an SSH tunnel |
| Uptime Kuma | 3001 | VM localhost only; access from macOS through an SSH tunnel |
| Prometheus | 9090 | Internal Docker network only |
| Node Exporter | 9100 | Internal Docker network only |

## Deployment Prerequisites

- The `noc-monitoring` Ubuntu ARM64 VM is updated.
- Docker Engine and the Docker Compose plugin are installed.
- UFW is active with OpenSSH allowed.
- A clean UTM export/copy restore point exists.
- Container-image ARM64 support is verified before deployment.
- A unique Grafana password is stored only in the VM-local `.env` file.

## Deployment Steps

1. Transfer the reviewed configuration files to the NOC VM.
2. Create a VM-local `.env` file from `.env.example`.
3. Validate the Compose configuration.
4. Verify ARM64 image manifests.
5. Pull and start the stack only after explicit approval.
6. Access Grafana and Uptime Kuma only through SSH tunnels.
7. Verify Prometheus targets, Grafana datasource health, and Uptime Kuma checks.
