# Outage Scenario 3 — Simulated Disk Usage Spike

> Status: **Design document.** Describes a planned, safe simulation for a
> future, separately approved execution phase. Not yet performed.

## Purpose

Verify that Grafana (via Node Exporter/Prometheus) correctly visualizes and
alerts on a disk-usage spike, without risking the VM's actual root filesystem.

## Scope

A small, dedicated loopback filesystem or bind-mounted test volume on the lab
VM — never the VM's root filesystem. Bounded size, easily reversible.

## Trigger (planned)

1. Create a small dedicated test filesystem (e.g. a loopback file mounted at
   a scratch path) sized so it can safely be filled without affecting the
   real root disk.
2. Fill it close to capacity:
   ```
   fallocate -l <size> /mnt/disk-test/fillfile
   ```
   (Illustrative — for a future approved execution phase; creating the
   loopback filesystem itself requires approval as a VM/filesystem change.)

## Expected Behavior

- Node Exporter reports high utilization on the test mount point.
- The Grafana disk-usage panel for that mount shows the spike.
- Any configured Grafana alert rule for disk usage (e.g. > 85% used) fires.

## Alert Behavior

- Grafana alert transitions Normal → Pending → Alerting as usage crosses
  threshold, then back to Normal once the file is removed and usage drops.

## Verification

1. Confirm the disk-usage panel for the test mount shows the spike.
2. Confirm the alert rule fires (if configured) with a correct timestamp.
3. Confirm the real root filesystem was unaffected throughout.

## Recovery & Rollback

```
rm /mnt/disk-test/fillfile
```
1. Confirm usage on the test mount drops back to baseline.
2. Confirm the Grafana alert clears back to Normal.
3. Record the fill→recovery timeline in `evidence/`.
4. If the loopback filesystem itself was created for this test, remove it as
   a separate, approved cleanup step.

## Evidence to Capture

- Sanitized Grafana disk-usage panel screenshot showing the spike.
- Sanitized screenshot of the alert firing (if configured) and clearing.
