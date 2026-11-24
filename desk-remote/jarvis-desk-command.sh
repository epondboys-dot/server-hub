#!/bin/bash
# tradingserver: the ONLY things Jarvis's desk key can run (owner decisions 12 and 13).
# Installed as an SSH forced command, so whatever Jarvis asks for, this script decides:
#   status   read-only summary          pause    paper entries off        resume   paper entries on
#   stop     full Stop (keeps running)  start    start the desk service   restart  restart the desk service
# Never: clear hard-off, reset, change limits or keys, real money. Hard-off blocks start/restart.
# Every request is logged to ~/trading-desk-runtime/jarvis-commands.log.
set -u
REPO="$HOME/trading-bot"
RUNTIME="$HOME/trading-desk-runtime"
LOG="$RUNTIME/jarvis-commands.log"
export WORKBENCH_RUNTIME_DIR="$RUNTIME" PATH="/usr/bin:/bin:/usr/local/bin" XDG_RUNTIME_DIR="/run/user/$(id -u)"
REQ="${SSH_ORIGINAL_COMMAND:-}"
log() { printf '%s %s\n' "$(date -Is)" "$*" >> "$LOG" 2>/dev/null || true; }
desk() { node linux/desk-linux.js "$1" --runtime "$RUNTIME" 2>&1 | grep -v -i 'ExperimentalWarning\|trace-warnings'; return "${PIPESTATUS[0]}"; }
hardoff() { [ -e "$RUNTIME/HARD_OFF.json" ]; }
log "request: ${REQ:-<none>}"
cd "$REPO" || { echo "desk code not found"; exit 1; }
case "$REQ" in
  status)  desk summary ;;
  pause)   desk pause ;;
  resume)  desk resume ;;
  stop)    desk stop-trading ;;
  start|restart)
    if hardoff; then log "refused: hard-off latched"; echo "REFUSED: hard-off is latched. Only the owner clears it, at tradingserver."; exit 3; fi
    systemctl --user "$REQ" trading-desk.service; rc=$?
    sleep 12; desk summary; log "$REQ exit $rc"; exit $rc ;;
  *)
    log "refused: not allowed"; echo "REFUSED: this key can only run status, pause, resume, stop, start or restart."; exit 2 ;;
esac
