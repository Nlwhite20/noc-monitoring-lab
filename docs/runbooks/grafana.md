# Runbook — Grafana

> Status: **Runbook** for the deployed stack. Alert rules and notification channels are planned, not yet configured.

## Purpose

Provide dashboards and alerting on top of Prometheus metrics for the lab
stack and any monitored lab VMs.

## Expected Behavior

- Runs as a Docker Compose service on `noc-net`.
- The Prometheus datasource is provisioned as code from
  `configs/grafana/provisioning/`. The NOC Infrastructure Overview dashboard
  was built in the UI; exporting its JSON into this repo is pending.
- Published on port `3000`, bound to `127.0.0.1` on the VM — never `0.0.0.0`,
  never exposed publicly. Reach it from the Mac through an SSH tunnel.
- Admin credentials come from a gitignored `.env`; only variable names are
  committed via `.env.example`.
- Persists its own DB (users, dashboard edits) to the `grafana-data` named
  volume.

## Verification

- Open the SSH tunnel, then log in at `http://localhost:3000` from the Mac browser.
- Datasource test (Configuration → Data Sources → Prometheus → Test) passes.
- Dashboard panels render with live data (CPU/memory/disk panels
  populated from Node Exporter via Prometheus).

## Alert Behavior

- Alert rules defined per panel/metric (e.g. CPU > 80% for 5m, disk > 85%
  used, `up == 0` for a target) transition Normal → Pending → Alerting per
  their configured `for:` duration, and back to Normal once the condition
  clears.
- Notification channel(s) configured in Grafana fire on state transitions.

## Troubleshooting Runbook

| Symptom | Check |
|---|---|
| Can't reach UI from Mac | Confirm the SSH tunnel is open and the VM's DHCP address has not changed; `ss -ltn` on the VM should show `127.0.0.1:3000` |
| Datasource test fails | Confirm URL is `http://prometheus:9090` (Compose service name), not `localhost` |
| Dashboards missing/blank | Confirm the datasource test passes, the time range is Last 1 hour, and each panel uses the Prometheus datasource |
| Alert not firing | Confirm the alert rule's query and threshold; confirm the notification channel is configured and tested |

## Recovery and Rollback

- Restart: `docker compose restart grafana`.
- Bad provisioning change: `git checkout` the previous provisioning files,
  then `docker compose up -d`.
- Data loss/corruption: restore `grafana-data` from the most recent volume
  backup (see `docs/operations.md`); as a last resort, recreate the volume
  let the datasource re-provision from the files in Git, and re-import the
  dashboard from its JSON export (once committed).
