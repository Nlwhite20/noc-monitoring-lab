# NOC Monitoring Lab

## Purpose

An authorized personal home-lab project that demonstrates service monitoring, Linux
administration, Docker, observability, alert triage, troubleshooting, and operational
runbook documentation.

## Status

The stack is deployed on a dedicated ARM64 Ubuntu VM: Prometheus, Node
Exporter, Grafana and Uptime Kuma run under Docker Compose, with an nginx
`test-web` container as an outage target. Dashboards are reachable only
through an SSH tunnel.

Two simulated outages have been run and documented:

- [INC-001](docs/incident-001-test-web-outage.md): `test-web` stopped, detected
  by Uptime Kuma.
- [INC-002](docs/incident-002-node-exporter-outage.md): `node-exporter` stopped,
  detected by Prometheus within one 30 s scrape, recovered in a planned
  2 min 23 s window, with timestamped evidence.

- [INC-003](docs/incident-003-alerting-validation.md): alerts delivered to a
  person. Grafana and Uptime Kuma now notify a private Discord channel; the
  outage was repeated and the alerts arrived without anyone watching a
  dashboard.

Still to do: prove the Grafana notification-policy route with a live alert,
host-level network metrics, and the CPU and disk scenarios.

## GRC Documentation

- [Control mapping](docs/control-mapping.md): how lab evidence supports NIST 800-53 and CSF 2.0 objectives
- [Risk register](docs/risk-register.md): lab risks, existing controls and open treatments
- Incident reports: [INC-001](docs/incident-001-test-web-outage.md) (Uptime Kuma), [INC-002](docs/incident-002-node-exporter-outage.md) (Prometheus) and [INC-003](docs/incident-003-alerting-validation.md) (alert delivery), each with timeline, evidence and follow-ups
- [Runbooks](docs/runbooks/): per-service runbooks plus a [session startup runbook](docs/runbooks/startup.md)

## AI Collaboration and Human Validation

I built this lab with Claude as an assistant. Claude proposed commands, plans,
queries and first drafts of documentation. I ran every command, made every
change to the VM, and approved every commit and push myself. The rules the
assistant works under are in [AGENTS.md](AGENTS.md) and [CLAUDE.md](CLAUDE.md):
lab-only scope, my approval before `sudo`, container stops, deletions,
commits or pushes, and no secrets in Git.

These are the cases where checking the AI's work changed the outcome:

| What I asked for | What the AI proposed | What I checked or changed | Result |
| --- | --- | --- | --- |
| Reconcile the repo with the running VM | Compare the files by eye | Compared SHA-256 hashes of every runtime file on both machines | Found the repo's Grafana datasource file had been overwritten with the Prometheus scrape config, a bug that looked fine by eye. Fixed in `abdbacf` |
| A plan for the Node Exporter outage test | A first test plan | Reviewed it as an auditor and required changes before anything ran: the `up` metric as primary evidence, defined timestamps, checking notification settings before claiming none existed, a 5-minute interruption limit, recovery staged in advance, exit codes on every stop and start | Plan revised twice; the test met every success criterion (INC-002) |
| A host network panel for the dashboard | A query that assumed Node Exporter saw the VM's network | Compared the interface it reported (`eth0`) with the VM's real interfaces (`ip -br link`, `enp0s1`) | The panel showed the container's traffic, a limit already noted in the Node Exporter runbook. Relabelled "(not host)" and added to the risk register (R-10) |
| Build the dashboard in the Grafana UI | Step-by-step panel settings | Reviewed the panels visually, then checked the exported JSON after every change | Caught a status timeline that would have shown DOWN as green, and three edits that looked saved but were not |
| Run the outage | Commands to paste into the terminal | Read the exit codes the commands recorded instead of assuming they worked | Early attempts ran in the wrong folder and failed (`exit=1`); the evidence proved no outage had occurred. Moved every step into self-contained scripts (`scripts/incident-002/`) |
| Configure Prometheus during the build | `--web.enable-lifecycle=false` | Read the container logs when Prometheus crash-looped | Boolean flags take no value; removed the flag |

Limitations:

- This is a single-operator lab. My review is not independent, and agreement
  between AI tools is a review input, not proof. Official documentation and
  observed lab results settle technical questions.
- Documentation in this repo was drafted with Claude and reviewed and edited
  by me before commit. Evidence excerpts come from saved command output, not
  from the AI.
- Planned, not yet done: alerting (R-03), provisioning dashboards from Git
  (R-12), and deploying the VM copy from a Git clone (R-06).

## Stack

- Ubuntu Server ARM64 virtual machine in UTM
- Docker Compose
- Uptime Kuma for availability and service checks
- Prometheus for metrics collection
- Node Exporter for Linux system metrics
- Grafana for dashboards

## Scope

Only localhost and explicitly authorized personal lab virtual machines will be monitored.
No public systems, employer systems, third-party networks, or production data are in scope.

## Security Principles

- Keep dashboards off the public internet.
- Use UTM Shared Network only for controlled updates and Mac-to-VM access.
- Store credentials locally, never in Git.
- Publish sanitized screenshots and simulated incident evidence only.

## Planned Evidence

- Healthy service availability check
- Deliberately stopped local test service
- CPU, memory, and disk dashboard
- Simulated NOC incident report and recovery runbook
