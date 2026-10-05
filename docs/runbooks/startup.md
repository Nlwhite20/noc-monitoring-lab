# Runbook: Starting a Lab Session

> Status: **Runbook.** Use after the Mac or the VM has been shut down or
> restarted. Addresses are placeholders; the real VM address is kept privately.

## Purpose

Bring the lab back to a known-good working state with three terminal tabs and
the dashboards reachable through the SSH tunnel.

## Expected behavior

All five containers restart on their own when the VM boots (Compose restart
policy, observed after an unplanned reboot on 2026-09-28). The only manual
steps are reconnecting SSH and reopening the tunnel.

## Steps

| # | Where | Action |
| --- | --- | --- |
| 1 | UTM | Select the `noc-monitoring` VM and press Play. Wait for the login prompt. |
| 2 | Terminal tab 1 (VM) | `ssh <user>@<LAB_VM_IP>` |
| 3 | Terminal tab 1 (VM) | `cd ~/noc-monitoring-lab` (every `docker compose` command depends on this) |
| 4 | Terminal tab 1 (VM) | `docker compose ps`: all five services `Up` (`uptime-kuma` also `healthy`). If any are missing, check them before starting anything. |
| 5 | Terminal tab 2 (tunnel) | `ssh -N -L 3000:127.0.0.1:3000 -L 3001:127.0.0.1:3001 <user>@<LAB_VM_IP>`. It stays blank while the tunnel is open; leave it alone. |
| 6 | Terminal tab 3 (Mac) | `cd ~/home-labs/repos/noc-monitoring-lab` for Git work |
| 7 | Browser | Grafana at `http://localhost:3000`, Uptime Kuma at `http://localhost:3001` |

## Verification

- Prompt in tab 1 ends in `~/noc-monitoring-lab$`.
- Prometheus targets are `up` (see [prometheus.md](prometheus.md#verification)).
- The `NOC – Host Overview` dashboard shows both status panels green (UP).

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `ssh` hangs or "No route to host" | The VM may still be booting, or its DHCP address changed. Check the address in the UTM console. |
| `localhost:3000` will not load | The tunnel tab closed (for example after a VM reboot). Run step 5 again. |
| Tunnel says "Address already in use" | An old tunnel is still running. Close that tab or end the old `ssh` process. |
| `no configuration file provided` | Run step 3. |

## Shutdown

Close the tunnel tab, `exit` the VM session, then shut the VM down from inside
(`sudo shutdown -h now`, which needs approval under `CLAUDE.md`) or from UTM.
