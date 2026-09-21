# NOC Monitoring Lab — Operations Guide

> Status: **Operations guide** for the deployed stack. The outage scenarios in
> `docs/outage-scenarios/` have not been executed yet.

## 1. Verification

Health is confirmed by:

- `docker compose ps` — all four services `Up`/`healthy`
- `curl` each service's health endpoint from inside the VM
- Open an SSH tunnel from the Mac
  (`ssh -L 3000:127.0.0.1:3000 -L 3001:127.0.0.1:3001 <user>@<LAB_VM_IP>`),
  then load Grafana and Uptime Kuma at `http://localhost:3000` and
  `http://localhost:3001`
- Prometheus **Targets** page shows Node Exporter (and Prometheus itself) as
  `UP`
- Grafana's Prometheus datasource passes its built-in connection test
- Uptime Kuma shows all configured checks green

## 2. Troubleshooting Runbook (general)

| Symptom | Check |
|---|---|
| Container won't start | `docker compose logs <service>` |
| Prometheus in a restart loop | `docker compose logs --tail=50 prometheus`; validate the config with `docker compose run --rm --no-deps prometheus promtool check config /etc/prometheus/prometheus.yml` |
| Service unreachable from Mac | Confirm the SSH tunnel is open and the VM's DHCP address has not changed; on the VM, `ss -ltn` should show ports 3000 and 3001 on `127.0.0.1` only |
| Prometheus target `down` | `docker network inspect noc-net`; confirm the target container is running and on the same network |
| Grafana datasource fails | Confirm Prometheus service name/port in the datasource URL matches `docker-compose.yml` |
| High resource use on VM | `docker stats`, `htop` |
| Config change didn't apply | Confirm the container was recreated (`docker compose up -d`) after editing mounted config files |

## 3. Rollback

1. `docker compose down` (without `-v`, so named volumes/data are preserved).
2. `git checkout` the previous known-good `docker-compose.yml` / config files.
3. `docker compose up -d` to redeploy the prior configuration.
4. If the VM itself is in a bad state (not just a container config), restore
   from the most recent **offline UTM export/copy** (see Backup below) rather
   than attempting in-place repair.

## 4. Backup

- **Config files:** already version-controlled in this Git repo.
- **Volume data** (Prometheus TSDB, Grafana DB, Uptime Kuma DB): back up via a
  throwaway `alpine` container that tars each named volume to a local
  `backup/` path (gitignored) before any risky change:
  ```
  docker run --rm -v <volume_name>:/data -v $(pwd)/backup:/backup \
    alpine tar czf /backup/<volume_name>-<date>.tar.gz -C /data .
  ```
  (Illustrative — to be run only in an approved execution phase.)
- **Whole-VM restore point:** an **offline UTM export/copy** of the VM image,
  taken after each successful, approved build phase. This replaces
  snapshot-based recovery for this project — restoring means importing the
  saved copy in UTM, not rolling back a snapshot.

## 5. Cleanup

- `docker compose down -v` performs a full teardown including volumes — this
  is **destructive** and requires explicit approval per `CLAUDE.md` before
  ever being run.
- `docker system prune` (images/volumes) likewise requires explicit approval.
- Deleting a UTM export/copy restore point requires explicit approval.

## 6. GitHub-Safe Evidence Plan

- **Never commit:** `.env`, credentials, real IP addresses/hostnames, raw
  logs, packet captures, VM disk images (`.gitignore` already covers these).
- **Screenshots:** sanitize before saving to `screenshots/` — crop or redact
  any real IP, hostname, or MAC address; use placeholders like `10.x.x.x` or
  `lab-vm-01` in any accompanying text.
- **Evidence write-ups:** stored in `evidence/`, following the skill's
  guidance to build an alert timeline first and separate *observed* facts
  from *assumed* causes.
- **Runbooks:** stored in `docs/runbooks/` and `docs/outage-scenarios/`,
  written so they're safe to publish as portfolio evidence without exposing
  any real network detail.
