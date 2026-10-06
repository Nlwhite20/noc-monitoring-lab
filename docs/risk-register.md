# Risk Register

> Personal home-lab risks, scored by the lab operator on a simple Low / Medium /
> High scale. Likelihood and impact are judgement calls, not measured values.
> Last reviewed: 2026-10-05 (after INC-003).

| ID | Risk | Likelihood | Impact | Existing controls | Residual | Treatment | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-01 | Dashboards exposed to the network because Docker-published ports bypass the host firewall | Medium | High | Ports bound to `127.0.0.1` in compose; access only through SSH tunnel; no bridged adapter | Low | Re-run `ss -ltn` after every compose change and save the output as evidence | Open |
| R-02 | Credentials or private details committed to the public repo | Medium | High | `.env` git-ignored; placeholder `.env.example`; staged files reviewed with `git status` before each commit; dashboard JSON scanned before commit | Low to Medium | Add automated secret scanning (for example a pre-commit hook) | Open |
| R-03 | Service failure goes unnoticed because no alert notification is delivered | Medium | Medium | Grafana `TargetDown` rule (routed through the notification policy) and Uptime Kuma both notify a private Discord channel. INC-003: Grafana Firing about 2 to 2.5 min after a stop. INC-003c: policy route delivered a Resolved message grouped by `job`. Kuma Down delivered in most runs; one confirmed miss, cause unknown | Low to Medium | Confirm a Firing message through the policy route in a future test; watch for further missed Kuma Down messages | Partially mitigated |
| R-04 | Loss of the VM with no usable recovery | Low | Medium | Full VM clone; dashboard JSON in Git; configuration in Git | Medium | Test a restore from the clone; keep a copy on separate storage | Open |
| R-05 | Pinned container images fall behind security fixes | Medium | Medium | Explicit version pins give a known baseline | Medium | Review image tags monthly and update through Git | Open (2026-10-06: 27 updates pending and a restart required on the VM) |
| R-06 | Documentation drifts from the deployed system | Medium | Medium | Docs rewritten to match deployment after drift was found (empty Prometheus config in the repo, docs describing a different network design); compose changes diffed before deployment. Occurred again 2026-09-28: the repo's Grafana datasource file had been overwritten with the Prometheus scrape config; found by SHA-256 comparison against the VM and fixed in `abdbacf` | Low | Verify repo against the running VM after each change; deploy the VM copy from a Git clone instead of a plain folder (root cause of the second drift) | Mitigated (has occurred twice) |
| R-07 | Simulated evidence mistaken for a real incident | Low | Low | Incident report labelled SIMULATED in title and banner | Low | Keep the label on all future exercises | Accepted |
| R-08 | Single Grafana admin account with no MFA | Low | Low | Loopback-only access; self sign-up disabled | Low | Accept for a single-user lab; use a unique strong password | Accepted |
| R-09 | VM address changes after reboot and breaks access or docs | Medium | Low | Address recorded privately, never in Git | Low | Add an SSH config alias; keep placeholders in docs | Open |
| R-10 | Host network traffic is not monitored: Node Exporter runs on the bridge network and reports the container's `eth0`, not the VM's `enp0s1` | High (current state) | Low | Limitation documented in the Node Exporter runbook; dashboard panel titled "(not host)" so it cannot be misread | Low | Evaluate host networking for Node Exporter without publishing port 9100 beyond loopback | Open |
| R-11 | Operator error during a planned exercise (wrong working directory, pasted commands running early) produces misleading evidence or an unplanned outage | Medium | Low | Exercise steps run from self-contained scripts; v2 (`scripts/incident-002/v2/`) also verifies evidence storage before a stop, preserves Docker exit codes as the script's exit status, and flags failed queries and evidence writes; invalid attempts quarantined, not deleted | Low | Reuse the scripts and the staged-recovery pattern for future scenarios | Mitigated (occurred in INC-002, no outage caused) |
| R-13 | VM clock drifts badly after the VM is suspended, making evidence timestamps wrong | High | Medium | Occurred four times (about 5.4 days and 67 minutes on 2026-10-05; about 6.5 hours found 2026-10-06 01:33 UTC, which had already affected the INC-003b absolute times). After a suspend, `chronyc tracking` shows a stale near-zero offset and `makestep` alone steps by zero; `chronyc burst` then `makestep` fixes it. The 67-minute step caused a false NoData alert in Grafana (not delivered). Startup runbook now compares VM and Mac clocks directly | Medium | Configure chrony to step large offsets at any time (`makestep 1 -1`, needs approval); avoid suspending the VM during exercises | Open |
| R-14 | Discord webhook URL leaks (chat, Git, screenshot or export), letting anyone post fake alerts to the alert channel | Low | Medium | URL entered only in the Grafana and Uptime Kuma UIs; contact point not exported; exports scanned for `discord.com/api/webhooks` before commit; screenshots cropped | Low | If it leaks, delete the webhook in Discord and create a new one | Open |
| R-12 | Dashboard changes made in the Grafana UI do not persist, so the screen and the repo copy differ | Medium | Low | Dashboard exported through the Grafana API and its JSON checked (panel types, titles, legends) before commit | Low | Provision the dashboard from the repo so Git is the source of truth | Open |

## Notes

- R-06 is a realized risk, not a hypothetical one. It is kept here because the
  fix (verify the repo against reality) is an operating habit worth recording.
- Risks R-03 and R-04 are the priorities for the next lab iteration. INC-002
  showed R-03 again: detection worked, notification did not exist.
- R-11 and R-12 came out of INC-002 and the dashboard rebuild. They are kept
  because the controls (scripts, exit-code capture, export checks) are habits
  worth recording.
