#!/usr/bin/env bash
cd ~/noc-monitoring-lab || exit 1
T=$(date -u +%Y%m%dT%H%M%SZ); E=~/evidence/incident-002; P=${1:-detect}
echo "== $P observed $T"
docker compose ps -a node-exporter --format '{{.Name}} {{.State}} {{.Status}}' | tee $E/$T-$P-ps.txt
docker compose exec -T prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=up' | tee $E/$T-$P-q1-up.txt | python3 -c 'import sys,json;[print("Q1",r["metric"]["job"],r["value"][1]) for r in json.load(sys.stdin)["data"]["result"]]'
docker compose exec -T prometheus wget -qO- 'http://localhost:9090/api/v1/targets?state=active' | python3 -c 'import sys,json; [print("Q2",t["labels"]["job"], t["health"], t["lastScrape"], t["lastError"] or "-") for t in json.load(sys.stdin)["data"]["activeTargets"]]' | tee $E/$T-$P-q2-targets.txt
docker compose exec -T prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=up%5B15m%5D' | python3 -c 'import sys,json,datetime as d; [print(r["metric"]["job"], d.datetime.fromtimestamp(float(t),d.timezone.utc).isoformat(timespec="milliseconds"), v) for r in json.load(sys.stdin)["data"]["result"] for t,v in r["values"]]' | tee $E/$T-$P-q3-samples.txt | awk '$1=="node-exporter"' | tail -4
