# Incident 003: Alert Delivery Validation (SIMULATED)

> **SIMULATED INCIDENT.** Deliberate, planned exercises on a personal,
> authorized home-lab VM. The "faults" were manual `docker compose stop`
> commands against the lab's own `node-exporter` and `test-web` containers.
> Alert messages went to a private Discord channel owned by the operator.

| Field | Value |
| --- | --- |
| Incident ID | INC-003 (simulated), with two follow-up runs (INC-003-kuma, INC-003b) |
| Date | 2026-10-05 (all times UTC unless marked EDT) |
| Purpose | Prove that an outage now reaches a person without anyone watching a dashboard (risk R-03) |
| Targets | `node-exporter` (INC-003, INC-003b); `test-web` (INC-003-kuma) |
| Alert paths | Grafana alerting → Discord; Uptime Kuma → Discord |
| Scripts | v2 scripts ([scripts/incident-002/v2/](../scripts/incident-002/v2/)), first live use of `stop.sh` and `restore.sh` |
| Outcome | Grafana and Uptime Kuma both delivered alerts. The notification-policy route delivered a Resolved message grouped by `job` (Follow-up 3); its Firing message was not confirmed. One Kuma "Down" was missed once (cause unknown) |

## Purpose

INC-001 and INC-002 both ended with the same gap: the outage was recorded,
but nobody was told (R-03). This exercise configures alert delivery and then
repeats the INC-002 outage to check that a notification reaches a person.

## Alerting configuration

| Component | Setting |
| --- | --- |
| Channel | Private Discord server, `#alerts` channel, one webhook. The webhook URL is a secret: it is stored only in the Grafana and Uptime Kuma data volumes, never in Git |
| Grafana contact point | `discord-noc` (Discord). Not exported to Git because it contains the webhook URL |
| Grafana rule | `TargetDown` ([export](../configs/grafana/alerting/target-down-rule.yaml)): instant query `up`, fires when the last value is below 1; evaluated every 30 s; pending period 1 min; no data and query errors also alert; label `severity=warning`; summary, description and runbook link as annotations |
| Grafana notification policy | Default policy to `discord-noc`, grouped by `alertname`, `grafana_folder`, `job`; group wait 30 s, group interval 5 min, repeat 4 h ([export](../configs/grafana/alerting/notification-policy.yaml)) |
| Uptime Kuma | Discord notification `discord-noc`, enabled by default and applied to all four monitors |

Data sent outside the lab (approved by the operator before the first test
message): alert names, labels such as `job=node-exporter` and
`instance=node-exporter:9100`, values, timestamps, `localhost` links and the
runbook URL. The first test messages were read to confirm they contained no
addresses, credentials or hostnames beyond container names and `localhost`.

## Expected behavior (written before the test)

| Path | Expected delay after the stop |
| --- | --- |
| Uptime Kuma → Discord | Up to about 60 s (60 s checks, 0 retries) |
| Grafana → Discord | About 1.5 to 2.5 min (≤30 s scrape + ≤30 s evaluation + 1 min pending + 30 s group wait) |
| Resolved / Up messages | Shortly after recovery |

## Pre-test event: false alert from a clock correction

Before the test, the VM clock was found 67 minutes behind after a short break
(the VM had been suspended; risk R-13). `chronyc tracking` still showed a
2 ms offset because its last measurement was from before the suspend, and a
first `sudo chronyc makestep` stepped by zero for the same reason. A fresh
`sudo chronyc burst 4/4` followed by `makestep` corrected it, and a
side-by-side check showed 0 s between the VM and the Mac.

At the moment of the step (16:11:07), both `TargetDown` instances went
Pending (NoData) and then Alerting (NoData) in the same second: after a
67-minute jump the instant query found no samples inside Prometheus's lookback
window, and the pending period had already "elapsed" by the rule's clock.
Both returned to Normal at 16:11:30 and 16:12:00 as fresh scrapes arrived.
Grafana's logs show 15 "Sending alerts to local notifier" lines within 60 ms
at 16:11:07 (replayed evaluations), then one every 30 s, and no notification
errors. **No Discord message was sent.** The probable cause is that the
replayed evaluations carried pre-jump timestamps, so the alerts were already
expired when they reached Grafana's Alertmanager. This is not proven.

## INC-003: Node Exporter outage with alerting

### Timeline

| Event | Time (UTC) | Source |
| --- | --- | --- |
| Baseline: both targets up, clocks equal | 16:25:52 | `detect.sh baseline`, exit 0 |
| Last successful scrape | 16:28:31.838 | Prometheus sample |
| Stop: `Stopped`, `docker_exit=0`, running → exited | 16:28:45–46 | `stop.sh`, exit 0 |
| Uptime Kuma records Down | 16:28:59 | Kuma event history |
| First failed scrape | 16:29:01.835 | Prometheus sample |
| Detection check: container `Exited (2)`, `up`=0, DNS error | 16:30:08 | `detect.sh`, exit 0 |
| **Grafana "Firing" in Discord** (`node-exporter` target down) | 16:31 (12:31 PM EDT, minute resolution) | Discord |
| Restart: `Started`, `docker_exit=0`, exited → running | 16:31:17–18 | `restore.sh`, exit 0 |
| First successful scrape | 16:31:31.835 | Prometheus sample |
| Uptime Kuma "Up" in Discord | 16:31:59 | Discord message |
| Grafana "Resolved" in Discord | Arrived; time not recorded | Discord |
| Recovery check: both targets up | 16:33:24 | `detect.sh recovery`, exit 0 |

### Durations

| Measure | Result |
| --- | --- |
| Stop to Grafana notification | About 2 to 2.5 min (Discord shows minutes only) |
| Approximate detection latency (Prometheus) | ≈ 16 s |
| Planned interruption (stop to restart) | 2 min 32 s (limit 5 min) |
| Approximate recovery latency | ≈ 14 s |
| Metrics gap | 180 s |

### Evidence

- Window 16:28:00 to 16:33:30: `node-exporter` 11 samples, 5 zeros
  (16:29:01, 16:29:31, 16:30:01, 16:30:31, 16:31:01); `prometheus` 11
  samples, 0 zeros.
- Prometheus scrape error during the outage:
  `lookup node-exporter on 127.0.0.11:53: server misbehaving` (Docker DNS).
- Uptime Kuma error during the outage: `connect EHOSTUNREACH <container-ip>:9100`.
  Kuma reused the container's cached address on the private Docker network,
  while Prometheus re-resolved the name and got a DNS error.
- `node-exporter` exited with code 2 again, after an operator-requested stop.
  This reproduces INC-002; the cause is still unexplained.
- All five services running afterwards. Raw evidence (23 files) kept on the
  VM outside the repository.

### What the alerts showed

- **Grafana delivered a Firing message** about 2 to 2.5 minutes after the
  stop, with labels, description and runbook link. A person was notified
  without watching a dashboard.
- **The same message also carried a "Resolved" entry for `prometheus`**, the
  stale alert from the 16:11 clock event. Exporting the rule afterwards showed
  why: the rule was set to send **directly to the contact point**
  (`notification_settings: receiver: discord-noc`), not through the
  notification policy, so the policy's grouping by `job` never applied.
  Direct routing groups only by `alertname` and `grafana_folder`.
- **Uptime Kuma recorded the Down event (16:28:59) but no Down message reached
  Discord.** The recovery ("Up") message did arrive. Kuma does not log
  notification attempts, so its logs could not show whether it tried.

## Follow-up 1: Uptime Kuma retest on `test-web` (INC-003-kuma)

| Event | Time (UTC) |
| --- | --- |
| Stop `test-web` (`exit=0`) | 17:53:23 |
| Restart (`Started`, `exit=0`) | 17:54:06–07 (43 s outage) |

Uptime Kuma's "Test Web" **Down and Up messages both reached Discord.** Kuma's
Down notifications work in general.

## Follow-up 2: policy route retest (INC-003b)

Before this run the rule was switched to use the notification policy, through
Grafana's provisioning API because the Grafana UI kept failing to load the
editor. The re-exported rule no longer contains `notification_settings`.

| Event | VM clock (UTC), about 6.5 h slow; see correction below |
| --- | --- |
| Baseline, both targets up | 18:15:33 |
| Stop (`exit=0`) | 18:16:22 |
| Uptime Kuma "Node Exporter" Down in Discord | 18:16:59 (37 s after the stop) |
| Restart (`exit=0`) | 18:17:30 (68 s after the stop) |
| Uptime Kuma "Up" in Discord | 18:17:59 |

- **Kuma's Node Exporter Down was delivered this time,** so the INC-003 miss
  was a one-off. Its cause is unknown.
- **No Grafana message was expected or received.** The restart came 68 s
  after the stop, before the 1-minute pending period could complete. The
  notification-policy route therefore remained untested after this run.

**Correction (2026-10-06):** the times in this table come from the VM clock,
which was about 6.5 hours behind real time during this run. Discord's own
header time on the Node Exporter Down message reads 8:49 PM EDT (00:49 UTC),
while the message body, stamped by the VM, reads 14:16:59 EDT. The next clock
check, at 01:33 UTC, found the VM 6 h 29 min behind. The baseline for this
run skipped the VM-to-Mac clock comparison because the Mac's time line was
missing from the output, and the run went ahead anyway. Durations measured on
the VM's own clock (37 s to the Kuma message, 68 s to the restart) are still
valid; the absolute times are not.

## Follow-up 3: notification-policy route verification (INC-003c)

Run on 2026-10-06 under a separately reviewed plan. All times are real UTC,
checked before the test by comparing the VM and Mac clocks directly.

### Pre-checks (read-only)

| Check | Result |
| --- | --- |
| VM vs Mac clock | VM 6 h 29 min behind (fourth R-13 occurrence). Corrected with an approved `sudo chronyc burst 4/4` then `makestep`; re-check showed 0 s |
| Rule (provisioning API) | `TargetDown`, `for: 1m`, no data and errors alert, not paused, condition below 1, **no `notification_settings`** (uses the policy) |
| Policy | Receiver `discord-noc`; group by `grafana_folder`, `alertname`, `job`; 30 s / 5 min / 4 h; no child routes |
| Contact points (names and types only) | `discord-noc` (discord) |
| Active alerts / rule state | None / both instances Normal. No alert from the clock step was active or delivered |

### Attempts

| Run | Stop (UTC) | Restart (UTC) | Outage | What happened |
| --- | --- | --- | --- | --- |
| 1 | 01:45:36 | 01:46:40 | 64 s | Restored manually after the Kuma Down message (delivered 01:45:41, 5 s after the stop). Too short for Grafana's 1-minute pending period, so no Grafana message |
| 2 | 01:54:24 | 01:54:39 | 15 s | A backup restore command pasted into a second terminal ran immediately (macOS Terminal sends the pasted newline), shorter than one scrape interval. The scheduled restore at 01:58:24 recorded a no-op |
| 3 | 02:02:14 | 02:06:14 | 240 s | Automatic, time-based restore in one command (stop, wait 240 s, restore), so no person had to pick the right alert under time pressure. Both scripts exit 0 |

Runs 1 and 2 are kept as recorded; their raw evidence is in separate folders.

### Run 3 result

| Message | Arrival (Discord header) |
| --- | --- |
| Grafana **Resolved**, `TargetDown`, `job=node-exporter` only | 22:09 EDT (02:09 UTC) |
| Uptime Kuma "Node Exporter is up" (downtime 4 min, went offline 02:02 UTC) | 22:06 EDT (02:06 UTC) |
| Grafana **Firing** | Not confirmed (see below) |
| Uptime Kuma "Node Exporter went down" | Not confirmed (see below) |

The Resolved message title was
`[RESOLVED] TargetDown NOC node-exporter (node-exporter:9100 warning)`.
The grouping labels in the title (`TargetDown NOC node-exporter`, that is
alertname, folder and job) match the notification policy's `group_by`, and
the message carried only the `node-exporter` alert. In INC-003, sent by direct
contact-point routing, the title was `[FIRING:1, RESOLVED:1] TargetDown NOC
(warning)` and mixed two jobs. **This shows the notification-policy route
delivering, grouped by `job` as configured.**

The operator reported only the two messages above from the run 3 window. A
Firing message is expected before any Resolved message, because Alertmanager
does not send a Resolved notification for a group that never notified, but
its arrival was not confirmed and it is not claimed here. Whether Kuma's Down
message for run 3 arrived is also unconfirmed. Scrape-level evidence for run 3
is in the raw evidence on the VM and was not summarized for this report.

## Findings

| # | Finding | Risk | Follow-up |
| --- | --- | --- | --- |
| F-1 | Alert delivery now works: Grafana and Uptime Kuma both notified a person through Discord | R-03 | Mark R-03 as partially mitigated |
| F-2 | The rule bypassed the notification policy (direct contact-point routing), which caused two targets to be grouped into one message. Found only by exporting the rule | R-12 | Switched to the policy via the API; Follow-up 3 shows the policy route delivering a Resolved message grouped by `job` |
| F-3 | One Uptime Kuma Down notification was lost (INC-003), cause unknown. Later Down notifications arrived (Kuma retest, INC-003b, INC-003c run 1); run 3's was not confirmed | R-03 | Watch for a repeat; a missed Down is the failure that matters most |
| F-4 | A clock correction produced a false NoData alert inside Grafana (not delivered). With no-data set to alert, clock steps are a source of noise | R-13 | Keep no-data alerting for now; reduce clock steps with the planned chrony change |
| F-5 | After a suspend, `chronyc tracking` reports a stale, near-zero offset and `makestep` alone does nothing. Only a direct comparison with the Mac caught a 67-minute error | R-13 | Startup runbook updated: compare clocks directly; fix with `burst`, then `makestep` |
| F-6 | Uptime Kuma messages mix time zones: "Went Offline" in UTC, "Time" in New York time | — | Note when reading alerts |
| F-8 | INC-003b ran with the VM clock about 6.5 h slow because a missing clock-check line was treated as a pass. Exposed by Discord's server-side timestamps | R-13 | Never start a timed test without both clock readings; absolute times in Follow-up 2 corrected |
| F-9 | Two policy-route attempts were cut short by the operator procedure: restoring on the faster Kuma alert, and a pasted backup command auto-running | R-11 | Use a single automatic stop-wait-restore command; never paste into the backup terminal |
| F-10 | The VM reports 27 pending updates and "System restart required" | R-05 | Patch and reboot in a planned window, then re-verify the stack |
| F-7 | Grafana 12 shows "Loading OnCall integration failed" on alerting pages because the bundled OnCall plugin has no backend. No effect on alerting | — | Ignore, or disable the plugin later |

## Limitations

- The notification-policy route is shown delivering a Resolved message; its
  Firing message in the same run was not confirmed.
- Discord shows message times to the minute; seconds were not captured for
  Grafana's messages, and the Grafana "Resolved" time was not recorded.
- No screenshots were captured of the Discord messages or Grafana during these
  runs; the evidence is the message text, Kuma's event history, Grafana's state
  history and logs, and the saved script output.
- The cause of the missed Kuma Down notification and of the `node-exporter`
  exit code 2 are unknown.
- All runs were short, planned stops of one service.

## Recovery and rollback

- Every stop was paired with `restore.sh` (exit 0 each time) inside the
  planned limit; no other service was restarted.
- Alerting can be rolled back without touching the monitoring stack: delete
  the rule and contact point in Grafana and disable the Kuma notification.

## Control mapping (evidence supports, not certifies)

| Framework reference | How this exercise supports it |
| --- | --- |
| NIST SP 800-53 SI-4 (System Monitoring) | Detection now ends in a notification to a person, not only a dashboard state |
| NIST SP 800-53 IR-4 (Incident Handling) | Detect, notify, respond and recover cycle, with timestamps from scripts, Prometheus, Kuma and Discord |
| NIST SP 800-53 IR-6 (Incident Reporting) | Alerts are reported to the operator automatically through a defined channel |
| NIST CSF 2.0 DE.AE (Adverse Event Analysis) | Alert content (labels, description, runbook link) supports triage |
