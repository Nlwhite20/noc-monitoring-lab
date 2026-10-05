#!/usr/bin/env bash
# INC-002 v2: start node-exporter. Recovery ALWAYS attempts the start:
# evidence and directory problems are reported but never block it.
source "$(dirname "$0")/common.sh"

fallback=0
cd "$PROJECT_DIR" || { err "cannot cd to $PROJECT_DIR; falling back to 'docker start $CONTAINER'"; fallback=1; }
evidence_ok=1
check_evidence_storage || { err "evidence storage check failed; attempting recovery anyway"; evidence_ok=0; }

if [ "$fallback" -eq 0 ]; then state_before=$(compose_state)
else state_before=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>&1); fi

T=$(stamp)
t_before=$(utc)
if [ "$fallback" -eq 0 ]; then out=$(docker compose start "$SERVICE" 2>&1); docker_rc=$?
else out=$(docker start "$CONTAINER" 2>&1); docker_rc=$?; fi
t_after=$(utc)
if [ "$fallback" -eq 0 ]; then state_after=$(compose_state)
else state_after=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>&1); fi

record="$t_before
$out
docker_exit=$docker_rc
$t_after
state_before=$state_before state_after=$state_after fallback=$fallback"
log "$record"
[ "$state_before" = "running" ] && log "NOTE: $SERVICE was already running; this start was a no-op"

save_rc=1
[ "$evidence_ok" -eq 1 ] && { save_evidence "$EVIDENCE_DIR/$T-restart.txt" "$record"; save_rc=$?; }

[ "$docker_rc" -eq 0 ]          || { err "start failed (exit $docker_rc); collect logs and stop: do not restart other services"; exit 1; }
[ "$state_after" = "running" ]  || { err "after start, state is '$state_after', expected 'running'"; exit 13; }
[ "$save_rc" -eq 0 ]            || { err "$SERVICE IS RUNNING but evidence was NOT saved; copy the output above"; exit 14; }
log "OK: $SERVICE running; evidence in $EVIDENCE_DIR/$T-restart.txt"
