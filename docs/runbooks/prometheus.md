# Runbook — Prometheus

> Status: **Runbook** for the deployed stack.

## Purpose

Scrape and store time-series metrics from Node Exporter (and itself) so
Grafana can visualize and alert on them.

## Expected Behavior

- Runs as a Docker Compose service on `noc-net`.
- Reads `configs/prometheus/prometheus.yml` for scrape configs and retention
  settings (retention window: 15 days).
- Serves its UI/API on port `9090`, reachable only inside `noc-net` (not
  published to the VM's host network in the default plan).
- Persists TSDB data to the `prometheus-data` named volume.

## Verification

- Targets page (`http://prometheus:9090/targets` from inside `noc-net`, or
  via an internal check) shows all configured jobs as `UP`.
- A test query (e.g. `up`) returns `1` for each target.
- Grafana's Prometheus datasource connection test passes.

## Alert Behavior

Prometheus itself does not send end-user notifications in this design —
Grafana owns alert rules and notification routing against Prometheus data.
Prometheus surfaces target-health (`up`) which those rules read.

## Troubleshooting Runbook

| Symptom | Check |
|---|---|
| Target down | Confirm target container is running and on `noc-net`; check scrape config hostname/port match the service name in `docker-compose.yml` |
| Container restarts on startup | `docker compose logs --tail=50 prometheus`. During the build, `--web.enable-lifecycle=false` crash-looped the container because boolean flags take no value; the fix was to remove the flag. Validate config with `promtool check config` |
| Config reload fails | Validate `prometheus.yml` syntax; check `docker compose logs prometheus` for parse errors |
| Disk usage growing unexpectedly | Check retention setting (`--storage.tsdb.retention.time`) matches the intended window |
| Grafana datasource test fails | Confirm the datasource URL uses the Compose service name (`http://prometheus:9090`), not `localhost` |

## Recovery and Rollback

- Restart: `docker compose restart prometheus`.
- Bad config: `git checkout` the previous `prometheus.yml`, then
  `docker compose up -d` to pick it up.
- Data loss/corruption: restore `prometheus-data` from the most recent volume
  backup (see `docs/operations.md`); as a last resort, recreate the volume and
  accept historical data loss (stateless re-scrape going forward).
