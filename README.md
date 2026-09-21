# NOC Monitoring Lab

## Purpose

An authorized personal home-lab project that demonstrates service monitoring, Linux
administration, Docker, observability, alert triage, troubleshooting, and operational
runbook documentation.

## Status

The stack is deployed on a dedicated ARM64 Ubuntu VM: Prometheus, Node
Exporter, Grafana and Uptime Kuma run under Docker Compose, and the dashboards
are reachable only through an SSH tunnel. Still to do: a simulated outage with
alert evidence and an incident report.

## Stack

- Ubuntu Server ARM64 virtual machine in UTM
- Docker Compose
- Uptime Kuma for availability and service checks
- Prometheus for metrics collection
- Node Exporter for Linux system metrics
- Grafana for dashboards

## Scope

Only localhost and explicitly authorized personal lab virtual machines will be monitored.
No public systems, employer systems, third-party networks, or production data are in scope.

## Security Principles

- Keep dashboards off the public internet.
- Use UTM Shared Network only for controlled updates and Mac-to-VM access.
- Store credentials locally, never in Git.
- Publish sanitized screenshots and simulated incident evidence only.

## Planned Evidence

- Healthy service availability check
- Deliberately stopped local test service
- CPU, memory, and disk dashboard
- Simulated NOC incident report and recovery runbook
