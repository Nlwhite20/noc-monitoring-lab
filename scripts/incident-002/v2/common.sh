# Shared helpers for the INC-002 v2 scripts. Sourced by them; not run directly.
#
# Exit codes used by the v2 scripts:
#   0  success
#   1  the docker command itself failed (its real exit code is recorded)
#   10 cannot change into the project directory
#   11 evidence storage check failed before any action
#   12 precheck failed (service not in the expected state; nothing changed)
#   13 docker reported success but the service is not in the expected state
#   14 the action happened but its evidence could not be saved

set -u
set -o pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/noc-monitoring-lab}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$HOME/evidence/incident-002}"
SERVICE="${SERVICE:-node-exporter}"
CONTAINER="${CONTAINER:-noc-node-exporter}"

utc()   { date -u +%FT%TZ; }
stamp() { date -u +%Y%m%dT%H%M%SZ; }
log()   { printf '%s\n' "$*"; }
err()   { printf 'ERROR: %s\n' "$*" >&2; }

# Succeeds only if a probe file can be written, read back and removed.
check_evidence_storage() {
  local probe="$EVIDENCE_DIR/.write-probe.$$"
  [ -d "$EVIDENCE_DIR" ] || { err "evidence directory missing: $EVIDENCE_DIR"; return 1; }
  { printf 'probe\n' > "$probe"; } 2>/dev/null || { err "cannot write to $EVIDENCE_DIR"; return 1; }
  [ "$(cat "$probe" 2>/dev/null)" = "probe" ] || { err "cannot read back $probe"; rm -f "$probe"; return 1; }
  rm -f "$probe" || { err "cannot remove $probe"; return 1; }
}

# save_evidence FILE CONTENT: write, then read back and compare.
save_evidence() {
  local f="$1" content="$2"
  { printf '%s\n' "$content" > "$f"; } 2>/dev/null || { err "evidence write failed: $f"; return 1; }
  [ "$(cat "$f" 2>/dev/null)" = "$content" ] || { err "evidence verify failed: $f"; return 1; }
}

# compose_state: prints the service state (running, exited, ...) or fails.
compose_state() { docker compose ps -a --format '{{.State}}' "$SERVICE" 2>&1; }
