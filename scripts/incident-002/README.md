# INC-002 test scripts

| Version | Location | Status |
| --- | --- | --- |
| v1 | `stop.sh`, `detect.sh`, `restore.sh` in this folder | **Historical.** Exactly as run on 2026-09-29 for [INC-002](../../docs/incident-002-node-exporter-outage.md). Do not reuse: the scripts' exit status comes from `date`/`tee`, and query, parse and evidence-write failures go undetected. |
| v2 | [`v2/`](v2/) | **Use for future runs.** Preserves Docker exit codes, verifies evidence storage before stopping anything, flags failed queries and parsing, and always attempts recovery. |

## v1 (historical)

These are published exactly as run on 2026-09-29.

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

## v2 usage

Same order as v1, using `scripts/incident-002/v2/`: `detect.sh baseline` →
`stop.sh` → `detect.sh` (repeat until 0) → `restore.sh` → `detect.sh recovery`
(repeat until 1). Stop at any non-zero exit code, except that `restore.sh`
must always be run once a stop has happened.

`PROJECT_DIR`, `EVIDENCE_DIR`, `SERVICE` and `CONTAINER` can be overridden
with environment variables; defaults match this lab.

| Exit code | Meaning |
| --- | --- |
| 0 | Success. For `detect.sh`, a DOWN target is a finding and still exits 0 |
| 1 | The Docker command failed (its real exit code is recorded), or for `detect.sh`, at least one query, parse or evidence write failed |
| 10 | Cannot change into the project directory (`restore.sh` falls back to `docker start` instead) |
| 11 | Evidence storage check failed before any action; nothing was changed |
| 12 | Precheck failed: service not in the expected state; nothing was changed |
| 13 | Docker reported success but the service is not in the expected state |
| 14 | The action happened, but its evidence could not be saved. Copy the printed output |

v2 was tested against a simulated `docker` command covering 16 scenarios
(missing evidence folder, failed stop and start, lost evidence after a stop,
wrong project folder, failed and unparseable queries, already-running and
already-stopped services).

Live check (read-only `detect.sh baseline`, 2026-10-05): passed with exit 0;
container state and all three queries were saved and verified. Its evidence
files are stamped 2026-09-30T03:24Z because the VM clock was about 5 days 10
hours behind at the time (see risk R-13); the clock was corrected immediately
afterwards. `stop.sh` and `restore.sh` have not been run against the live
stack.
