# Outage Scenario 2 — Simulated CPU Load Spike

> Status: **Design document.** Describes a planned, safe simulation for a
> future, separately approved execution phase. Not yet performed.

## Purpose

Verify that Grafana (via Node Exporter/Prometheus) correctly visualizes and
alerts on a sustained CPU load spike on the monitoring VM.

## Scope

The lab VM's own CPU only. Bounded duration, no impact outside the VM.

## Trigger (planned)

Run a time-bounded CPU load generator on the VM, e.g.:
```
stress-ng --cpu 4 --timeout 120s
```
or, if `stress-ng` isn't installed, a bounded loop with an explicit `timeout`
wrapper so it cannot run indefinitely. (Illustrative — for a future approved
execution phase; requires approval before installing or running anything.)

## Expected Behavior

- Node Exporter reports elevated CPU utilization.
- The Grafana CPU panel shows a clear spike for the duration of the test.
- Any configured Grafana alert rule for high CPU (e.g. > 80% for N minutes)
  fires.

## Alert Behavior

- Grafana alert transitions Normal → Pending → Alerting as the threshold is
  sustained past its configured `for:` duration, then back to Normal once
  load stops and the metric drops below threshold.

## Verification

1. Confirm the CPU panel shows the spike in real time during the test.
2. Confirm the alert rule fires (if configured) with a correct timestamp.
3. Confirm the VM otherwise remains responsive (SSH, other containers
   unaffected).

## Recovery & Rollback

1. Let the bounded load generator's timeout expire (or kill the process if
   needed: `pkill stress-ng`).
2. Confirm CPU utilization returns to baseline within one scrape interval.
3. Confirm the Grafana alert clears back to Normal.
4. Record the load→recovery timeline in `evidence/`.

## Evidence to Capture

- Sanitized Grafana CPU panel screenshot showing the spike.
- Sanitized screenshot of the alert firing (if configured) and clearing.
