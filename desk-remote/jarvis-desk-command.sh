#!/bin/bash
# tradingserver: the ONLY thing Jarvis's desk key can run (owner decision 12, November 23, 2026).
# Installed as an SSH forced command, so whatever Jarvis asks for, this script decides:
#   status  -> read-only desk status
#   start   -> start the desk the normal way (linux/start-trading-desk.sh): it comes up Stopped/frozen, entries disabled.
#              Refused while hard-off is latched or a desk already runs. Never --accept-startup-freeze (that stays an owner
#              decision at the keyboard), never reset, never enable entries, never clear hard-off.
# Anything else is refused. Every request is logged to ~/trading-desk-runtime/jarvis-commands.log.
set -u
REPO="$HOME/trading-bot"
RUNTIME="$HOME/trading-desk-runtime"
LOG="$RUNTIME/jarvis-commands.log"
export WORKBENCH_RUNTIME_DIR="$RUNTIME" PATH="/usr/bin:/bin:/usr/local/bin"
REQ="${SSH_ORIGINAL_COMMAND:-}"
log() { printf '%s %s\n' "$(date -Is)" "$*" >> "$LOG" 2>/dev/null || true; }
log "request: ${REQ:-<none>}"
cd "$REPO" || { echo "desk code not found"; exit 1; }
case "$REQ" in
  status)
    exec node linux/desk-linux.js status --runtime "$RUNTIME" ;;
  start)
    if [ -e "$RUNTIME/HARD_OFF.json" ]; then log "refused: hard-off latched"; echo "REFUSED: hard-off is latched. Only the owner clears it, at tradingserver."; exit 3; fi
    if node -e 'process.exit(require("./control-center/linux-process-identity").linuxDeskProcessPresent()?0:1)' 2>/dev/null; then
      log "refused: desk already running"; echo "REFUSED: a desk process is already running (or one could not be identified). Nothing was started."; exit 4; fi
    log "starting"
    bash linux/start-trading-desk.sh; rc=$?
    log "start exit $rc"; exit $rc ;;
  *)
    log "refused: not allowed"; echo "REFUSED: this key can only run 'status' or 'start'."; exit 2 ;;
esac
