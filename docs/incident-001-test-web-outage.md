# Incident 001: Test Web Service Outage (SIMULATED)

> **SIMULATED INCIDENT.** This was a deliberate, planned exercise on a personal,
> authorized home-lab VM. No production system, employer system or third-party
> network was involved. The "fault" was a manual `docker compose stop` of a
> throwaway nginx container created for this purpose.

| Field | Value |
| --- | --- |
| Incident ID | INC-001 (simulated) |
| Date | 2026-09-21 |
| Affected service | `test-web` (nginx, throwaway target) |
| Detected by | Uptime Kuma HTTP monitor "Test Web" (20-second check interval) |
| Approximate outage | about 100 seconds (5 consecutive failed checks) |
| Severity (simulated) | Low: no user impact, isolated test service |
| Cause | Intentional stop of the container by the operator |

Times below are as displayed by Uptime Kuma and are approximate (plus or minus
one 20-second check interval). Exact command timestamps were not captured.

## Summary

The `test-web` container was stopped on purpose to confirm that the NOC stack
notices a service failure and records recovery. Uptime Kuma marked the monitor
Down after its next failed checks and returned to Up after the container was
started again. The core monitoring services (Prometheus, Node Exporter, Grafana,
Uptime Kuma) were not touched and stayed running throughout.

## Timeline

| Approx. time (Kuma) | Event |
| --- | --- |
| 10:27 | Monitor "Test Web" created; first check returns `200 - OK` |
| 10:27 to 10:32 | Steady green checks, response time about 2 to 5 ms |
| about 10:32 | `docker compose stop test-web` run on the VM; checks begin failing |
| about 10:32 | Monitor status changes to **Down**; red heartbeat bars appear |
| about 10:33:40 | `docker compose start test-web` run on the VM |
| about 10:33:50 | First successful check; status returns to **Up** |
| 10:34 | Response time back to about 2 to 4 ms |

## Evidence

Screenshots contain only localhost dashboard content and internal container
names. No addresses, credentials or account details are shown.

1. Before: [01-test-web-baseline-up.png](../screenshots/01-test-web-baseline-up.png)
   shows the monitor Up with a run of green checks and a 200 OK event.
2. During: [02-test-web-outage-down.png](../screenshots/02-test-web-outage-down.png)
   shows the monitor Down, red heartbeat bars, and a shaded outage region on the
   response-time chart.
3. After: [03-test-web-recovered-up.png](../screenshots/03-test-web-recovered-up.png)
   shows the monitor Up again, with the red bars preserved in the history.

## Detection and response

- **Detection:** automatic, by the Uptime Kuma HTTP check against
  `http://test-web/` inside the `noc-net` Docker network. No human noticed the
  failure first.
- **Response:** the operator started the container again with
  `docker compose start test-web`. No other change was needed.
- **Verification:** the monitor returned to Up on the next check and the
  response time returned to normal.

## Impact

None beyond the test service. The 24-hour uptime figure shown in the "during"
and "after" screenshots (81.25% and 75%) is based on a few minutes of history
since the monitor was created, so it is not a meaningful availability number.

## Limitations and gaps (observed, not assumed)

- **No alert notification was configured.** Detection was visible in the
  dashboard only; no email, chat or push notification fired. A notification
  channel is an open item.
- **Prometheus was not part of this test.** `test-web` is not a Prometheus scrape
  target, so no Prometheus "target down" state or Grafana panel gap was captured
  for this incident.
- **Timestamps are approximate** because they were read from the dashboard, not
  from captured command output.
- The baseline screenshot is scrolled below the monitor title, so the monitor
  name is not visible in that image.

## Follow-up actions

1. Add an Uptime Kuma notification channel and repeat the exercise so that an
   alert is actually delivered.
2. Add a Prometheus alert rule (for example `up == 0`) and a Grafana panel that
   reflects a stopped scrape target.
3. Repeat with the CPU-load and disk-usage scenarios in `docs/outage-scenarios/`.

## Control mapping (evidence supports, not certifies)

| Framework reference | How this exercise supports it |
| --- | --- |
| NIST SP 800-53 SI-4 (System Monitoring) | Availability monitoring detected a service failure |
| NIST SP 800-53 IR-4 (Incident Handling) | Detect, respond, recover and document cycle performed |
| NIST CSF 2.0 DE.CM (Continuous Monitoring) | Automated checks every 20 seconds |
