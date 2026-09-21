# Outage Scenario 1 — Simulated Service Down

> Status: **Design document.** Describes a planned, safe simulation for a
> future, separately approved execution phase. Not yet performed.

## Purpose

Verify that Uptime Kuma and Prometheus both correctly detect and alert on an
unexpected stop of a monitored service, and that recovery is clean.

## Scope

Localhost containers on the personally-owned lab VM only. No effect outside
the VM.

## Trigger (planned)

Stop one monitored container, e.g.:
```
docker stop uptime-kuma-lab-target   # a throwaway test service, not a core monitoring component
```
(Illustrative command for a future approved execution phase — not run yet.)

## Expected Behavior

- Uptime Kuma marks the corresponding check **Down** and fires its configured
  notification.
- If the stopped service is also a Prometheus scrape target, the Prometheus
  Targets page marks it **down** and any related Grafana panel reflects the
  gap in data.

## Alert Behavior

- Uptime Kuma: status change to Down, timestamped, with configured
  notification channel firing.
- Prometheus/Grafana: target health flips to down; any alert rule tied to
  `up == 0` for that target fires after its configured `for:` duration.

## Verification

1. Confirm the Uptime Kuma dashboard shows the check as Down with a timestamp.
2. Confirm Prometheus Targets page shows the target as down (if applicable).
3. Confirm no other, unrelated checks were affected.

## Recovery & Rollback

```
docker start uptime-kuma-lab-target
```
1. Confirm the container is running (`docker compose ps`).
2. Confirm Uptime Kuma flips back to **Up** and Prometheus target returns to
   `UP` within the next scrape interval.
3. Record the full down→up timeline in `evidence/` (observed facts only).

## Evidence to Capture

- Sanitized screenshot of the Uptime Kuma Down alert.
- Sanitized screenshot of Prometheus Targets page during the outage.
- Sanitized screenshot of both tools back to green after recovery.
