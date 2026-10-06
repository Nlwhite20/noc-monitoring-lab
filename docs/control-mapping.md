# Control Mapping

> Personal home-lab project. This document shows how evidence produced in this
> repository supports common security control objectives. It is a self-review
> by the lab operator, **not** an independent assessment, and it does not claim
> compliance with or certification to any framework.

Frameworks referenced: NIST SP 800-53 Rev. 5 control families and NIST CSF 2.0
categories. Status values: **Implemented** (working and evidenced),
**Partial** (working with a known gap), **Planned** (not yet in place).

Last reviewed: 2026-10-05 (after INC-003).

## Scope

One Ubuntu Server ARM64 VM (`noc-monitoring`) running Prometheus, Node Exporter,
Grafana and Uptime Kuma under Docker Compose, plus a throwaway `test-web`
service used for outage exercises. Personal, authorized lab only. No production
data, employer systems or third-party networks.

## Mapping

| Control | Objective | How the lab addresses it | Evidence | Status |
| --- | --- | --- | --- | --- |
| SC-7 Boundary Protection | Limit network exposure | Grafana and Uptime Kuma publish only on the VM loopback address and are reached through an SSH tunnel. Prometheus and Node Exporter publish no host ports. UTM Shared Network only, no bridged adapter. | `docker-compose.yml` (127.0.0.1 binds); `docker ps` port column checked 2026-09-21; `docs/network-architecture.md` (diagram) | Implemented |
| SC-6 Resource Availability | Prevent one service exhausting the host | Per-container memory and CPU limits set for every service. | `docker-compose.yml` (`mem_limit`, `cpus`) | Implemented |
| SI-4 System Monitoring | Detect abnormal or failed services | Prometheus scrapes itself and Node Exporter every 30 s; Uptime Kuma checks Prometheus, Grafana, Node Exporter and Test Web. | `configs/prometheus/prometheus.yml`; `configs/grafana/dashboards/` (both dashboards); `docs/incident-002-node-exporter-outage.md` (target loss detected within one scrape); `screenshots/` | Implemented |
| IR-4 Incident Handling | Detect, respond, recover, document | Three simulated outage exercises: INC-001 (Uptime Kuma detection), INC-002 (Prometheus detection, timestamped evidence) and INC-003 (alerts delivered to a person through Discord, v2 scripts). All recovered and written up | `docs/incident-001-test-web-outage.md`; `docs/incident-002-node-exporter-outage.md`; `docs/incident-003-alerting-validation.md`; `scripts/incident-002/`; `configs/grafana/alerting/` | Implemented (notification-policy route not yet proven live) |
| IR-5 Incident Monitoring | Track and record incidents | Kuma heartbeat and event history retained across a VM reboot. | `docs/incident-001-test-web-outage.md` | Partial (informal) |
| IA-5 Authenticator Management | Protect credentials | Grafana admin credentials live in a VM-local `.env` that is git-ignored; only a placeholder `.env.example` is committed. Self sign-up disabled in Grafana. | `.gitignore`; `.env.example`; `docker-compose.yml` | Partial (no rotation policy, single admin, no MFA) |
| CM-2 Baseline Configuration | Known, reproducible configuration | Container images pinned to explicit versions; stack defined entirely in `docker-compose.yml` and provisioning files. | `docker-compose.yml`; `configs/` | Implemented |
| CM-3 Configuration Change Control | Controlled, recorded changes | Changes made through Git with descriptive commits; compose changes reviewed with `git diff` before deployment; live file backed up before replacement. | Git history; incident and deployment docs | Partial (single operator, no formal approval) |
| CP-9 System Backup | Recoverable from loss | Full VM clone `noc-monitoring-02-working` taken after a clean shutdown. Dashboard exported as JSON into Git. | Clone visible in UTM (not yet recorded in the foundation repo's VM inventory); `configs/grafana/dashboards/` | Partial (same host, restore not yet tested, no offsite copy) |
| CP-10 System Recovery | Restore after disruption | Stack restarted on its own after a full VM reboot (restart policy) and data persisted in named volumes. | Observed 2026-09-21: all four containers Up and monitors and history intact after reboot. Observed again 2026-09-28 after an unplanned reboot: all five containers restarted on their own; only the SSH tunnel needed reopening. Neither captured as a saved log | Partial (observed, not evidenced in repo) |

## CSF 2.0 view

| CSF 2.0 category | Lab activity |
| --- | --- |
| DE.CM Continuous Monitoring | Automated scraping and availability checks (30 s and 20 s intervals) |
| RS.MA Incident Management | Simulated incident handled and documented (INC-001) |
| RC.RP Incident Recovery Plan Execution | Service restored and verified as Up after the simulated outage |
| PR.PS Platform Security | Pinned images, resource limits, loopback-only publishing |

## Known evidence gaps

1. The listening-port check (`ss -ltn`) was performed but its output was not
   saved to `evidence/`. Capture and commit it (with no addresses beyond
   loopback) to back up the SC-7 claim.
2. Alert notifications were first delivered in INC-003 (Grafana and Uptime
   Kuma to Discord). The Grafana notification-policy route has not yet
   delivered a live alert, and one Kuma Down message was missed.
3. Backup restore has not been tested.
4. The post-reboot check (CP-10) and the VM clone (CP-9) are not yet recorded in
   the repo or in the foundation repo's VM inventory.

See `docs/risk-register.md` for how these gaps are tracked.
