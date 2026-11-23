#!/bin/bash
# Runs as the jarvis user (launchd, 07:25 daily, and once at install).
# 1. Fetch each read-only clone in ~/projects and fast-forward it if it has no local edits.
# 2. Write the daily briefing (briefings/latest.md), which the Discord bot posts at 07:30.
# Read-only toward GitHub: the token cannot push, and this script never commits or pushes.
set -u
PROJECTS="$HOME/projects"
OUT="${BRIEFING_OUT_DIR:-$HOME/hub/briefings}"
NODE=/opt/homebrew/opt/node@24/bin/node
mkdir -p "$OUT"
LOG="$OUT/refresh.log"
export GIT_TERMINAL_PROMPT=0   # never hang waiting for a password

{
  echo "# refresh $(date '+%Y-%m-%d %H:%M')"
  for d in "$PROJECTS"/*/; do
    [ -d "$d/.git" ] || continue
    name=$(basename "$d")
    if ! git -C "$d" fetch --quiet --prune 2>/dev/null; then
      echo "FAIL $name"; continue
    fi
    if [ -n "$(git -C "$d" status --porcelain --untracked-files=no)" ]; then
      echo "SKIP $name (local edits; not fast-forwarded)"; continue
    fi
    if git -C "$d" merge --ff-only --quiet '@{u}' 2>/dev/null; then
      echo "OK   $name $(git -C "$d" rev-parse --short HEAD)"
    else
      echo "SKIP $name (cannot fast-forward)"
    fi
  done
} > "$LOG"

"$NODE" /opt/jarvis-brain/briefing.js
