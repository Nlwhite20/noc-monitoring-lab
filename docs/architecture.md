# NOC Monitoring Lab — Architecture & Design

> Status: **Deployed.** The stack described here is running on the
> `noc-monitoring` VM. Section 7 records where the build differed from the
> original plan and what remains open.

## 1. Purpose

A personally-owned, isolated home-lab environment for practicing NOC-style
service monitoring, alerting, and incident documentation using Uptime Kuma,
Prometheus, Node Exporter, and Grafana on a dedicated Ubuntu Server ARM64 VM.

## 2. VM Specification

| Resource | Value | Rationale |
|---|---|---|
| CPU | 4 vCPU | Comfortable headroom for four lightweight containers plus host/UTM overhead on Apple silicon |
| RAM | 6 GB | Covers Ubuntu Server + Docker + the full stack (~1–2 GB typical usage) with growth room |
| Disk | 60 GB (dynamically allocated qcow2) | Room for Prometheus TSDB growth under a bounded retention window (target 15–30 days) without near-term resizing |
| OS | Ubuntu Server, ARM64 LTS | Native arch for Apple-silicon UTM; matches all container images below |

## 3. Network Design

- **One UTM Shared Network adapter only.** No Bridged adapter, no second NIC.
  Shared Network (NAT) gives the VM outbound internet for package/image pulls
  while keeping it off the home LAN's broadcast domain — reachable only from
  the Mac host by default.
- **DHCP, not static.** The VM keeps its DHCP-assigned address for this phase;
  no Netplan static-IP configuration is done. The current address is recorded
  **privately** (outside this repo) for SSH and dashboard access from the Mac.
  No real IP addresses are committed to Git — documentation uses placeholders
  such as `<LAB_VM_IP>` or `lab-vm-01`.
- No Bridged networking, ever, for this VM.

## 4. Security Model

- No dashboard or service is ever exposed to the public internet.
- No container or host service binds to `0.0.0.0`. Every published port binds
  to `127.0.0.1` on the VM, so the dashboards are reachable from the Mac only
  through an SSH tunnel. Docker-published ports bypass UFW, which is why the
  bind address, not a firewall rule, is the control.
- Prometheus (`9090`) and Node Exporter (`9100`) are **not published** to the
  VM's host network at all — they're reachable only inside the internal
  Docker network, from Grafana/Prometheus respectively.
- Secrets (Grafana admin password, etc.) live in a gitignored `.env`; only a
  variable-name-only `.env.example` is committed.
- UFW is active on the VM (default deny incoming, OpenSSH allowed). Docker
  installation, firewall rules, and any VM configuration change require
  explicit approval per `CLAUDE.md`.
- **Restore point:** instead of a UTM snapshot, the clean baseline is an
  **offline UTM export/copy** of the VM image, taken after each successful,
  approved build phase.

## 5. Monitoring Design

### Components

| Service | Role |
|---|---|
| Node Exporter | Exposes Linux host metrics (CPU, memory, disk, network) from the monitoring VM |
| Prometheus | Scrapes Node Exporter (and itself) on a fixed interval; stores time-series metrics |
| Grafana | Dashboards and alerting on top of Prometheus data |
| Uptime Kuma | Independent black-box availability checks (HTTP/TCP) against the stack's own endpoints and any other localhost service on the VM |

### Topology

- All four services run as Docker Compose services on a single dedicated
  user-defined bridge network (`noc-net`) on the VM, so they resolve each
  other by service name and stay isolated from any other Docker workload.
- Node Exporter reads host metrics via read-only bind mounts of `/proc` and
  `/sys`; no `privileged: true`.

### Ports & Binding

| Service | Port | Exposure |
|---|---|---|
| Grafana | 3000 | Published, bound to `127.0.0.1` on the VM; reached from the Mac through an SSH tunnel |
| Uptime Kuma | 3001 | Published, bound to `127.0.0.1` on the VM; reached from the Mac through an SSH tunnel |
| Prometheus | 9090 | Internal (`noc-net`) only — not published to the host |
| Node Exporter | 9100 | Internal (`noc-net`) only — not published to the host |

### Monitoring Targets

- Node Exporter and Uptime Kuma's own health endpoints, all on the same VM
  (localhost/self-monitoring).
- A second personally-owned lab VM may be added later as an additional
  scrape target / Uptime Kuma check **only after** that VM is explicitly
  created and separately approved, per `CLAUDE.md`.
- No public, employer, school, or third-party hosts are ever in scope.

## 6. ARM64 Compatibility

All planned images publish official multi-arch manifests including
`linux/arm64`:

| Component | Image | ARM64 |
|---|---|---|
| Uptime Kuma | `louislam/uptime-kuma` | ✅ multi-arch since 1.x |
| Prometheus | `prom/prometheus` | ✅ official multi-arch |
| Grafana | `grafana/grafana` (or `grafana-oss`) | ✅ official multi-arch |
| Node Exporter | `prom/node-exporter` | ✅ official multi-arch |

Each pinned tag was checked with
`docker manifest inspect <image>:<tag> | grep arm64` before pulling, and the
local image architecture was checked after the pull.

## 7. Changes from the Plan and Open Items

Changes made during the build:

- Dashboards are reached through an SSH tunnel to `127.0.0.1` on the VM, not
  through a port bound to the VM's Shared-Network address (see
  `docs/deployment.md`).
- Prometheus crash-looped at first because of `--web.enable-lifecycle=false`
  (boolean flags take no value). The flag was removed.

Open items:

- No outage scenario has been executed yet, and no notification channel has
  been verified.
- The Grafana dashboard was built in the UI; its JSON export is not yet in
  this repo.
- Only the stack's own endpoints are monitored. A second lab VM has not been
  added.
