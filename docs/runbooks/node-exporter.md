# Runbook — Node Exporter

> Status: **Runbook** for the deployed stack.

## Purpose

Expose Linux host metrics (CPU, memory, disk, network, filesystem) from the
monitoring VM for Prometheus to scrape.

## Expected Behavior

- Runs as a Docker Compose service on `noc-net`, with read-only bind mounts
  of `/proc` and `/sys` from the VM host.
- Serves metrics on port `9100`, reachable only inside `noc-net` (never
  published to the VM's host network).
- Metrics update continuously; Prometheus scrapes every 30s
  (`configs/prometheus/prometheus.yml`).
- Runs on the bridge network, so its network-interface metrics describe the
  container, not the VM. CPU, memory and disk metrics are unaffected.

## Verification

- `curl http://node-exporter:9100/metrics` from inside another container on
  `noc-net` returns metric text.
- Prometheus Targets page shows `node-exporter` job as `UP`.

## Alert Behavior

Node Exporter itself does not alert — it is the metrics source. Alerting is
configured in Grafana/Prometheus against its metrics (e.g. high CPU, low
disk space, host unreachable).

## Troubleshooting Runbook

| Symptom | Check |
|---|---|
| Prometheus target down | Confirm container is running; confirm it's attached to `noc-net`; check `docker compose logs node-exporter` |
| Missing filesystem/CPU metrics | Confirm `/proc` and `/sys` bind mounts are present in `docker-compose.yml` |
| Permission errors in logs | Confirm mounts are read-only (`:ro`) and match expected paths |

## Recovery and Rollback

- Restart: `docker compose restart node-exporter`.
- If a config change broke it: `git checkout` the previous
  `docker-compose.yml` service definition, then `docker compose up -d`.
- No persistent data to lose — Node Exporter is stateless.
