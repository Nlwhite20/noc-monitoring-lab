# Runbook — Grafana

> Status: **Runbook** for the deployed stack. Alerting to Discord configured 2026-10-05 (see INC-003).

## Purpose

Provide dashboards and alerting on top of Prometheus metrics for the lab
stack and any monitored lab VMs.

## Expected Behavior

- Runs as a Docker Compose service on `noc-net`.
- The Prometheus datasource is provisioned as code from
  `configs/grafana/provisioning/`. Dashboards are built in the UI and exported
  to `configs/grafana/dashboards/` (`noc-infrastructure-overview.json`, the
  original, and `noc-host-overview.json`, the current NOC – Host Overview).
  Provisioning dashboards from the repo is planned (R-12).
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

- Rule `TargetDown` (folder `NOC`, group `noc-availability`): instant query
  `up`, fires when the value is below 1 for 1 minute; evaluated every 30 s.
  No data and query errors also alert. Exported in
  `configs/grafana/alerting/`.
- Routing: the default notification policy sends to contact point
  `discord-noc` (a Discord webhook; the URL is a secret and is not in Git),
  grouped by `alertname`, `grafana_folder`, `job`; group wait 30 s, group
  interval 5 min, repeat 4 h.
- Observed in INC-003: a Firing message about 2 to 2.5 min after a target
  stopped, then a Resolved message after recovery (direct contact-point
  routing at the time). After switching to the policy, INC-003c run 3
  delivered a Resolved message about 3 min after recovery, titled
  `[RESOLVED] TargetDown NOC node-exporter (...)`, grouped by `job`.
- For a valid test, the outage must last longer than the 1-minute pending
  period plus group wait (about 2.5 min); use a time-based automatic restore.
- A clock step on the VM can produce a false NoData alert (R-13).

## Troubleshooting Runbook

| Symptom | Check |
|---|---|
| Can't reach UI from Mac | Confirm the SSH tunnel is open and the VM's DHCP address has not changed; `ss -ltn` on the VM should show `127.0.0.1:3000` |
| Datasource test fails | Confirm URL is `http://prometheus:9090` (Compose service name), not `localhost` |
| Dashboards missing/blank | Confirm the datasource test passes, the time range is Last 1 hour, and each panel uses the Prometheus datasource |
| Alert not firing | Confirm the alert rule's query and threshold; confirm the notification channel is configured and tested |
| Alerts grouped or routed unexpectedly | Export the rule (`/api/v1/provisioning/alert-rules/<uid>/export?format=yaml`). If it contains `notification_settings`, it bypasses the notification policy. The contact point **Test** button also bypasses the policy |
| Rule editor will not load in the UI | Change the rule through the provisioning API: GET the rule, edit the JSON, PUT it back with header `X-Disable-Provenance: true` so it stays editable in the UI |
| "Loading OnCall integration failed" banner | Harmless in this lab: the bundled OnCall plugin has no backend |
| Panel edit looks saved but is missing after reload or export | Save the dashboard, reload, then check the exported JSON. When changing visualization type, use the Visualizations tab, not Suggestions |
| Browser Export / Copy to clipboard does nothing | Export through the API over the tunnel instead: `curl -fsS -u <grafana-user> http://localhost:3000/api/dashboards/uid/<uid>`, then save the `dashboard` object (curl prompts for the password) |

## Recovery and Rollback

- Restart: `docker compose restart grafana`.
- Bad provisioning change: `git checkout` the previous provisioning files,
  then `docker compose up -d`.
- Data loss/corruption: restore `grafana-data` from the most recent volume
  backup (see `docs/operations.md`); as a last resort, recreate the volume
  let the datasource re-provision from the files in Git, and re-import the
  dashboard from its JSON export (once committed).
