#!/usr/bin/env bash
cd ~/noc-monitoring-lab || exit 1
T=$(date -u +%Y%m%dT%H%M%SZ)
{ date -u +%FT%TZ; docker compose start node-exporter; echo "exit=$?"; date -u +%FT%TZ; } 2>&1 | tee ~/evidence/incident-002/$T-restart.txt
