# Runbook — Uptime Kuma

> Status: **Runbook** for the deployed stack. A notification channel has not yet been verified.

## Purpose

Independent black-box availability monitoring (HTTP/TCP checks) for the
stack's own endpoints and any other localhost service on the lab VM,
separate from the Prometheus/Grafana metrics path.

## Expected Behavior

- Runs as a Docker Compose service on `noc-net`.
- Published on port `3001`, bound to `127.0.0.1` on the VM — never `0.0.0.0`,
  never exposed publicly. Reach it from the Mac through an SSH tunnel.
- Configured checks include: Grafana health, Prometheus health, Uptime Kuma's
  own reachability, and any other localhost service added on the VM.
- Persists check history/config to the `uptime-kuma-data` named volume.

## Verification

- Open the SSH tunnel, then log in at `http://localhost:3001` from the Mac browser.
- All configured checks show green/Up with recent "last checked" timestamps.
- A manual "Pause"/"Resume" on a test check correctly reflects state.

## Alert Behavior

- A check transitions to **Down** after its configured number of failed
  retries; configured notification channel(s) fire.
- Transitions back to **Up** on the next successful check, with a recovery
  notification if configured.

## Troubleshooting Runbook

| Symptom | Check |
|---|---|
| Can't reach UI from Mac | Confirm the SSH tunnel is open and the VM's DHCP address has not changed; `ss -ltn` on the VM should show `127.0.0.1:3001` |
| Check flapping | Confirm the target service is actually stable; check interval/retry settings aren't too aggressive for the service's real response time |
| Check stuck "Pending" | `docker compose logs uptime-kuma`; confirm the target hostname/port is correct and reachable on `noc-net` |
| Notifications not firing | Verify the notification channel config/test inside Uptime Kuma's settings |

## Recovery and Rollback

- Restart: `docker compose restart uptime-kuma`.
- Data loss/corruption: restore `uptime-kuma-data` from the most recent
  volume backup (see `docs/operations.md`); as a last resort, recreate the
  volume and re-add checks manually (check definitions are not currently
  stored as code).
