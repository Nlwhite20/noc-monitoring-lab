# INC-002 test scripts

Scripts used for the simulated Node Exporter outage in
[docs/incident-002-node-exporter-outage.md](../../docs/incident-002-node-exporter-outage.md).
They are published exactly as run on 2026-09-29.

Run them **on the lab VM only**, with the stack deployed at `~/noc-monitoring-lab`.
Each script changes into that folder itself, so it works from any directory.
Evidence is written to `~/evidence/incident-002/` on the VM, outside the repo
(create it first with `mkdir -p ~/evidence/incident-002`).

| Script | What it does |
| --- | --- |
| `detect.sh [label]` | Records container state, current `up` values, target health with the last scrape error, and the last 15 minutes of `up` samples. Each output is saved to a timestamped file named with the label (default `detect`). |
| `stop.sh` | Stops `node-exporter` only, recording UTC timestamps before and after plus the exit code. |
| `restore.sh` | Starts `node-exporter` only, recording UTC timestamps before and after plus the exit code. |

Order of use: `detect.sh baseline` → `stop.sh` → `detect.sh` (repeat until 0)
→ `restore.sh` → `detect.sh recovery` (repeat until 1).

Before running `stop.sh`, decide on a maximum interruption and start a timer.
Stopping a container is an action that needs approval under `CLAUDE.md`.

Known limitations: the scripts assume Docker Compose v2+ and Python 3 on the
VM, and they do not check that the evidence folder exists.
