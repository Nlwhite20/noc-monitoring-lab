#!/usr/bin/env bash
# INC-002 v2: record node-exporter state and Prometheus evidence.
# A DOWN target is a finding, not a script failure. A failed query, a
# response that does not parse, or an evidence write that fails IS a script
# failure: every check still runs, and the script exits 1 listing them.
source "$(dirname "$0")/common.sh"

label="${1:-detect}"
cd "$PROJECT_DIR" || { err "cannot cd to $PROJECT_DIR"; exit 10; }
check_evidence_storage || { err "evidence storage check failed; nothing recorded"; exit 11; }

T=$(stamp); E="$EVIDENCE_DIR/$T-$label"
failures=()
fail() { failures+=("$1"); err "$1"; }
prom() { docker compose exec -T prometheus wget -qO- "http://localhost:9090$1" 2>&1; }

# Parsers exit non-zero on invalid JSON, status != success, or an empty result.
P_Q1='import sys,json
try: d=json.load(sys.stdin)
except ValueError as e: sys.exit("invalid JSON: %s" % e)
r=d.get("data",{}).get("result",[])
if d.get("status")!="success" or not r: sys.exit("not success or empty result")
for x in r: print("Q1", x["metric"]["job"], x["value"][1])'
P_Q2='import sys,json
try: d=json.load(sys.stdin)
except ValueError as e: sys.exit("invalid JSON: %s" % e)
t=d.get("data",{}).get("activeTargets",[])
if d.get("status")!="success" or not t: sys.exit("not success or no active targets")
for x in t: print("Q2", x["labels"]["job"], x["health"], x["lastScrape"], x["lastError"] or "-")'
P_Q3='import sys,json,datetime as dt
try: d=json.load(sys.stdin)
except ValueError as e: sys.exit("invalid JSON: %s" % e)
r=d.get("data",{}).get("result",[])
if d.get("status")!="success" or not r: sys.exit("not success or empty result")
for x in r:
    for ts,v in x["values"]:
        print(x["metric"]["job"], dt.datetime.fromtimestamp(float(ts),dt.timezone.utc).isoformat(timespec="milliseconds"), v)'

log "== $label observed $(utc) ($T)"

# 1. Container state
ps_out=$(docker compose ps -a --format '{{.Name}} {{.State}} {{.Status}}' "$SERVICE" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && [ -n "$ps_out" ]; then log "$ps_out"; else fail "ps: docker exit $rc: $ps_out"; fi
save_evidence "$E-ps.txt" "$ps_out" || fail "ps: evidence write"

# 2-4. Prometheus queries: save the raw response first (it is evidence even if
# it is an error), then parse it.
run_query() {  # name path parser outfile [quiet]
  local name="$1" path="$2" parser="$3" out="$4" quiet="${5:-}" raw rc parsed
  raw=$(prom "$path"); rc=$?
  save_evidence "$E-$name-raw.json" "$raw" || fail "$name: raw evidence write"
  [ "$rc" -eq 0 ] || { fail "$name: query exit $rc: ${raw:0:200}"; return; }
  parsed=$(printf '%s' "$raw" | python3 -c "$parser" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || { fail "$name: parse failed: ${parsed:0:200}"; return; }
  save_evidence "$out" "$parsed" || fail "$name: parsed evidence write"
  [ -n "$quiet" ] || printf '%s\n' "$parsed"
}

run_query q1 '/api/v1/query?query=up' "$P_Q1" "$E-q1-up.txt"
run_query q2 '/api/v1/targets?state=active' "$P_Q2" "$E-q2-targets.txt"
run_query q3 '/api/v1/query?query=up%5B15m%5D' "$P_Q3" "$E-q3-samples.txt" quiet
[ -s "$E-q3-samples.txt" ] && awk -v s="$SERVICE" '$1==s' "$E-q3-samples.txt" | tail -4

if [ "${#failures[@]}" -gt 0 ]; then
  err "detect.sh: ${#failures[@]} check(s) failed; this observation is incomplete:"
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi
log "OK: all checks recorded under $E-*"
