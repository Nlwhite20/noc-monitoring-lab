# Incident 002: Node Exporter Outage (SIMULATED)

> **SIMULATED INCIDENT.** This was a deliberate, planned exercise on a personal,
> authorized home-lab VM. No production system, employer system or third-party
> network was involved. The "fault" was a manual `docker compose stop` of the
> lab's own Node Exporter container.

| Field | Value |
| --- | --- |
| Incident ID | INC-002 (simulated) |
| Date | 2026-09-29 (all times UTC) |
| Affected service | `node-exporter` (host metrics collector, Prometheus scrape target) |
| Unaffected services | `prometheus`, `grafana`, `uptime-kuma`, `test-web` |
| Detected by | Prometheus target health (`up{job="node-exporter"}` = 0), confirmed by query |
| Planned interruption | 2 min 23 s (limit set before the test: 5 min) |
| Severity (simulated) | Low: loss of host metrics only; no user-facing service affected |
| Cause | Intentional stop of the container by the operator |
| Outcome | All success criteria met |

## Purpose

Show that the monitoring stack detects the loss of the `node-exporter` scrape
target and records its recovery, using timestamped, reproducible evidence.
INC-001 tested service availability in Uptime Kuma. This exercise tests the
metrics pipeline (Prometheus and Grafana), which INC-001 explicitly did not
cover.

## Environment

- Ubuntu Server ARM64 VM in UTM. Clock NTP-synchronized, timezone UTC. Mac to
  VM clock offset measured at 0 s (one-second resolution) before the test.
- Docker Compose v5.5.1. Prometheus v3.10.0, Node Exporter v1.12.1, Grafana
  12.4.0, Uptime Kuma 2.4.0, nginx 1.28-alpine (`test-web`).
- Prometheus scrapes every 30 s. Observed scrape phase: `node-exporter` at
  :23 and :53 past each minute, `prometheus` at :05/:06 and :35/:36.
- Prometheus publishes no host port, so every query ran inside its container
  (see [runbooks/prometheus.md](runbooks/prometheus.md#verification)).

## Expected behavior (written before the test)

| Source | Expected |
| --- | --- |
| Prometheus | `up{job="node-exporter"}` goes 1 → 0 within one scrape interval; `up{job="prometheus"}` stays 1 |
| Uptime Kuma | "Node Exporter" HTTP monitor (60 s interval, 0 retries) marks Down on its next check |
| Grafana | Status panels show DOWN; host panels may or may not show a visible gap (observation only) |
| Notifications | **None expected.** See Alert behavior |

### Success criteria

1. Primary evidence: `up{job="node-exporter"}` changes 1 → 0 → 1.
2. `up{job="prometheus"}` stays at 1 throughout, showing the failure is isolated.
3. Planned interruption stays under 5 minutes.
4. Recovery is clean and all five services are running afterwards.

## Alert behavior

Three independent checks before the test found **no alert delivery path**:

| Tool | Finding |
| --- | --- |
| Prometheus | No `rule_files` and no Alertmanager in `configs/prometheus/prometheus.yml` |
| Uptime Kuma | A "Node Exporter" monitor exists, but zero notification channels are configured |
| Grafana | Zero alert rules; the only contact point has no integrations |

As predicted, no notification was sent. Detection was confirmed by running
queries by hand.

## Pre-test checks

| Check | Result |
| --- | --- |
| Compose service name | `node-exporter` (confirmed with `docker compose config --services`; 5 services) |
| Internal query method | `docker compose exec -T prometheus wget` against `localhost:9090` works |
| Baseline (17:07:57) | Both targets `up`, no scrape errors; 30 samples each over 15 min, 0 values other than 1 |
| Recovery staged | `restore.sh` ready in a separate SSH session; local 4 min 20 s timer to stay inside the 5 min limit |

## Timeline

| ID | Event | Time (UTC) | Source |
| --- | --- | --- | --- |
| T_last | Last successful scrape before the failure | 17:43:23.035 | Prometheus sample |
| T_inj | `docker compose stop node-exporter`: `Stopped`, `exit=0` | 17:43:35 | VM clock (before and after in the same second) |
| T_down_scrape | First failed scrape (`up` = 0) | 17:43:53.033 | Prometheus sample |
| T_down_obs | First observed `0`; container `Exited (2)` | 17:45:22 | Manual query |
| T_restart | `docker compose start node-exporter`: `Started`, `exit=0` | 17:45:58 | VM clock (before and after in the same second) |
| T_up_scrape | First successful scrape after restart | 17:46:23.034 | Prometheus sample |
| T_up_obs | First observed `1` again | 17:47:35 | Manual query |

System times come from Prometheus sample timestamps or the VM clock. Observed
times only record when a person looked. With no alerting, they measure how
often someone checked, not how the system performed.

## Durations

| Measure | Definition | Result |
| --- | --- | --- |
| Approximate detection latency | T_down_scrape − T_inj | ≈ 18 s |
| Observation latency (human) | T_down_obs − T_inj | 1 min 47 s |
| Planned interruption | T_restart − T_inj | 2 min 23 s |
| Approximate recovery latency | T_up_scrape − T_restart | ≈ 25 s |
| Metrics gap | T_up_scrape − T_last | 180 s |

Detection and recovery latencies are approximate. A Prometheus sample's
timestamp marks when that scrape ran, so the moment of failure or recovery is
only bounded to within one 30 s scrape interval. This was one controlled
event, so these are single values, not MTTD or MTTR averages.

The metrics gap is the interval between successful scrapes. During it,
Prometheus recorded `up` = 0 for every Node Exporter scrape. The samples show
that scraping failed; they do not show what the host itself was doing.

## Verification (evidence)

Samples from 17:43:00 to 17:47:30, taken from the saved recovery query
(`up[15m]`, one value per actual scrape):

| Scrape time | `node-exporter` | `prometheus` |
| --- | --- | --- |
| 17:43:05 | | 1 |
| 17:43:23 | 1 | |
| 17:43:35 | | 1 |
| 17:43:53 | **0** | |
| 17:44:05 | | 1 |
| 17:44:23 | **0** | |
| 17:44:35 | | 1 |
| 17:44:53 | **0** | |
| 17:45:05 | | 1 |
| 17:45:23 | **0** | |
| 17:45:35 | | 1 |
| 17:45:53 | **0** | |
| 17:46:05 | | 1 |
| 17:46:23 | 1 | |
| 17:46:36 | | 1 |
| 17:46:53 | 1 | |
| 17:47:05 | | 1 |
| 17:47:23 | 1 | |

Summary: `node-exporter` 9 samples, 5 zeros. `prometheus` 9 samples, 0 zeros.

Scrape error reported by Prometheus during the outage:

```
Get "http://node-exporter:9100/metrics": dial tcp: lookup node-exporter on 127.0.0.11:53: server misbehaving
```

`127.0.0.11` is Docker's embedded DNS resolver inside the container network, not
a real host address. Once the container stopped, its service name no longer
resolved, so the failure surfaced as a DNS lookup error rather than a refused
connection.

Final state after recovery: all five services `running`; `uptime-kuma`
`healthy`.

Raw evidence files are kept on the lab VM outside this repository
(`~/evidence/incident-002/`), in line with the no-raw-logs rule in
`CLAUDE.md`. Only the sanitized excerpts above are published.

### Screenshots

1. Baseline before the test:
   [04-node-exporter-baseline-dashboard.jpg](../screenshots/04-node-exporter-baseline-dashboard.jpg)
   shows the NOC – Host Overview dashboard with both status panels UP.
   Captured at about 17:10 UTC (Mac clock, 0 s offset from the VM), cropped to
   the Grafana window before publishing.

No screenshots were captured during the outage or after recovery. The
query output above is the evidence for those phases.

## Observations

- `node-exporter` exited with code 2 on `docker compose stop`, rather than the
  0 or 143 usually seen from a clean stop. Recorded as an observation only;
  the restart was unaffected.
- No tool sent a notification, as predicted.
- Grafana and Uptime Kuma were not captured during the outage, so their
  behavior is not reported here. The Uptime Kuma "Node Exporter" monitor (60 s
  checks, 0 retries) would be expected to show Down, but this was not
  verified.

## Test-procedure issues (and how they were handled)

Several attempts before the successful run did not inject a fault:

- A baseline command ran outside the project folder and wrongly reported
  "saved", because it checked the exit status of the wrong command.
- Two stop attempts failed with `exit=1` ("no configuration file provided")
  for the same wrong-directory reason.
- Pasted recovery commands ran immediately (macOS Terminal sends the trailing
  newline), so `restore.sh` ran several times against a running container.

Because every stop and start recorded its timestamps and exit code, the
evidence shows that none of these attempts caused an outage. Their files were
moved to an `invalid/` folder rather than deleted. The fix was to move every
step into a self-contained script that changes into the project folder itself
([scripts/incident-002/](../scripts/incident-002/)).

## Findings

| # | Finding | Risk | Follow-up |
| --- | --- | --- | --- |
| F-1 | Still no alert delivery path. The outage was recorded, but nobody was told. Detection depended on a person running queries (1 min 47 s here, unbounded in practice). | R-03 | Add a Prometheus `up == 0` rule and a working notification channel, then repeat this exercise |
| F-2 | Node Exporter runs on the bridge network, so its network metrics describe the container's `eth0`, not the VM's `enp0s1`. The dashboard panel was relabelled "(not host)". | R-10 | Decide whether host networking can be used without publishing port 9100 |
| F-3 | Commands that depend on the current directory caused failed attempts. | R-11 | Use the scripts in `scripts/incident-002/` for future exercises |

## Limitations

- One planned, clean stop. Does not cover crashes, hangs, partial failures or
  resource exhaustion.
- Detection was confirmed by manual polling. No automated alert exists yet.
- No screenshots were taken during the outage or after recovery, so Grafana
  and Uptime Kuma behavior during the incident is unverified.
- Lab environment. Timings are indicative, not service-level targets.

## Recovery and rollback

- Recovery used during the test: `docker compose start node-exporter`
  (`restore.sh`). No other service was restarted or changed.
- Rollback if recovery had failed (decided before the test): collect
  `docker compose ps`, `docker compose logs --tail=50 node-exporter`,
  `docker inspect` state and the Prometheus target error, then stop and
  diagnose. No stack-wide restart, deletion or reconfiguration.

## How to repeat

On the lab VM, using [scripts/incident-002/](../scripts/incident-002/):

1. `detect.sh baseline`: record the starting state.
2. `stop.sh`: inject the failure (timestamps and exit code recorded).
3. `detect.sh`: repeat until `node-exporter` shows 0.
4. `restore.sh`: restart (timestamps and exit code recorded).
5. `detect.sh recovery`: repeat until `node-exporter` shows 1.

## Control mapping (evidence supports, not certifies)

| Framework reference | How this exercise supports it |
| --- | --- |
| NIST SP 800-53 SI-4 (System Monitoring) | Prometheus detected the loss of a monitored target within one scrape interval |
| NIST SP 800-53 IR-4 (Incident Handling) | Planned detect, respond, recover and document cycle with timestamped evidence |
| NIST CSF 2.0 DE.CM (Continuous Monitoring) | Automated 30 s scraping recorded the failure without human input |
| NIST CSF 2.0 RC.RP (Recovery Plan Execution) | Recovery staged in advance, executed inside the planned window and verified |
