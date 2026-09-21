# Network & Architecture Diagram

> Status: **Deployed.** Reflects the running stack on the `noc-monitoring` VM.
> Uses placeholder addresses only; no real host or network details are recorded
> in this repo.

## Mac to VM access path

Grafana and Uptime Kuma are published on the VM's loopback address only. The Mac
reaches them through an SSH tunnel, so no dashboard port is open on the VM's
network interface.

```mermaid
flowchart LR
    subgraph Mac["Mac host (Apple silicon, 32 GB unified memory)"]
        Browser["Browser: localhost:3000 and localhost:3001"]
        SSHc["SSH client with port forwards 3000 and 3001"]
        Browser --> SSHc
    end

    Net["UTM Shared Network (NAT, DHCP)"]

    subgraph VM["noc-monitoring: Ubuntu Server ARM64 VM<br/>4 vCPU / 6 GB RAM / 60 GB disk"]
        direction TB
        SSHd["sshd :22 (UFW allows OpenSSH only)"]
        Loop["VM loopback 127.0.0.1"]
        Grafana["Grafana :3000"]
        Kuma["Uptime Kuma :3001"]
        SSHd --> Loop
        Loop --> Grafana
        Loop --> Kuma
    end

    SSHc -->|"SSH (VM address recorded privately, not in Git)"| Net
    Net --> SSHd
```

No Bridged adapter exists. The VM is not reachable from the wider home LAN. Docker
published ports bypass UFW, so the safeguard is the `127.0.0.1` bind address in
`docker-compose.yml`, not a firewall rule.

## Docker Compose network (inside the VM)

```mermaid
flowchart TB
    subgraph noc-net["Docker network: noc-net (internal bridge)"]
        NodeExp["node-exporter :9100"]
        Prom["prometheus :9090"]
        Grafana["grafana :3000"]
        Kuma["uptime-kuma :3001"]

        Prom -->|scrape| NodeExp
        Prom -->|scrape self| Prom
        Grafana -->|query| Prom
        Kuma -->|HTTP check| Grafana
        Kuma -->|HTTP check| Prom
        Kuma -->|HTTP check| NodeExp
    end

    Loopback["VM loopback 127.0.0.1"]
    Loopback -->|"published :3000"| Grafana
    Loopback -->|"published :3001"| Kuma
```

Prometheus and Node Exporter are **not** published to the VM. They are reachable
only inside `noc-net`: Prometheus by Grafana and Uptime Kuma, Node Exporter by
Prometheus and Uptime Kuma.

## Known limitation

Node Exporter runs on the bridge network, so its network-interface metrics describe
the container, not the VM. CPU, memory and disk metrics are unaffected. Use
`network_mode: host` if network panels are added later.
