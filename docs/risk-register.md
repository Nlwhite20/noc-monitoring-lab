# Risk Register

> Personal home-lab risks, scored by the lab operator on a simple Low / Medium /
> High scale. Likelihood and impact are judgement calls, not measured values.
> Last reviewed: 2026-09-21.

| ID | Risk | Likelihood | Impact | Existing controls | Residual | Treatment | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-01 | Dashboards exposed to the network because Docker-published ports bypass the host firewall | Medium | High | Ports bound to `127.0.0.1` in compose; access only through SSH tunnel; no bridged adapter | Low | Re-run `ss -ltn` after every compose change and save the output as evidence | Open |
| R-02 | Credentials or private details committed to the public repo | Medium | High | `.env` git-ignored; placeholder `.env.example`; staged files reviewed with `git status` before each commit; dashboard JSON scanned before commit | Low to Medium | Add automated secret scanning (for example a pre-commit hook) | Open |
| R-03 | Service failure goes unnoticed because no alert notification is delivered | High | Medium | Dashboard-based detection only (INC-001) | Medium | Add an Uptime Kuma notification channel and a Prometheus alert rule; repeat the outage exercise | Open |
| R-04 | Loss of the VM with no usable recovery | Low | Medium | Full VM clone; dashboard JSON in Git; configuration in Git | Medium | Test a restore from the clone; keep a copy on separate storage | Open |
| R-05 | Pinned container images fall behind security fixes | Medium | Medium | Explicit version pins give a known baseline | Medium | Review image tags monthly and update through Git | Open |
| R-06 | Documentation drifts from the deployed system | Medium | Medium | Docs rewritten to match deployment after drift was found (empty Prometheus config in the repo, docs describing a different network design); compose changes diffed before deployment | Low | Verify repo against the running VM after each change | Mitigated (has occurred once) |
| R-07 | Simulated evidence mistaken for a real incident | Low | Low | Incident report labelled SIMULATED in title and banner | Low | Keep the label on all future exercises | Accepted |
| R-08 | Single Grafana admin account with no MFA | Low | Low | Loopback-only access; self sign-up disabled | Low | Accept for a single-user lab; use a unique strong password | Accepted |
| R-09 | VM address changes after reboot and breaks access or docs | Medium | Low | Address recorded privately, never in Git | Low | Add an SSH config alias; keep placeholders in docs | Open |

## Notes

- R-06 is a realized risk, not a hypothetical one. It is kept here because the
  fix (verify the repo against reality) is an operating habit worth recording.
- Risks R-03 and R-04 are the priorities for the next lab iteration.
