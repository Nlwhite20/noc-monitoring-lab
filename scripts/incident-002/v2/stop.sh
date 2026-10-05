#!/usr/bin/env bash
# INC-002 v2: stop node-exporter, recording UTC timestamps, the real docker
# exit code and the resulting state. Refuses to stop anything unless evidence
# storage works and the service is currently running.
source "$(dirname "$0")/common.sh"

cd "$PROJECT_DIR" || { err "cannot cd to $PROJECT_DIR; nothing stopped"; exit 10; }
check_evidence_storage || { err "evidence storage check failed; nothing stopped"; exit 11; }

state_before=$(compose_state); ps_rc=$?
if [ "$ps_rc" -ne 0 ] || [ "$state_before" != "running" ]; then
  err "precheck: $SERVICE state is '$state_before' (docker exit $ps_rc), expected 'running'; nothing stopped"
  exit 12
fi

T=$(stamp)
t_before=$(utc)
out=$(docker compose stop "$SERVICE" 2>&1); docker_rc=$?
t_after=$(utc)
state_after=$(compose_state)

record="$t_before
$out
docker_exit=$docker_rc
$t_after
state_before=$state_before state_after=$state_after"
log "$record"

save_evidence "$EVIDENCE_DIR/$T-inject-stop.txt" "$record"; save_rc=$?

[ "$docker_rc" -eq 0 ]          || { err "docker compose stop failed (exit $docker_rc)"; exit 1; }
[ "$state_after" = "exited" ]   || { err "after stop, state is '$state_after', expected 'exited'"; exit 13; }
[ "$save_rc" -eq 0 ]            || { err "$SERVICE IS STOPPED but evidence was NOT saved; copy the output above"; exit 14; }
log "OK: $SERVICE stopped; evidence in $EVIDENCE_DIR/$T-inject-stop.txt"
