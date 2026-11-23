#!/bin/bash
# Put the Trading Desk on tradingserver (2014 Mac mini, Ubuntu). Owner decisions 10-12.
# Run ON tradingserver as epondboys:   bash ~/hub-move/install-desk-on-tradingserver.sh
# It gets the code, copies the runtime with the verified backup tool, checks it and runs the doctor.
# It never starts the desk: the owner starts it afterwards, watching. Safe to rerun until the desk has started.
set -euo pipefail

SRC="${1:-$HOME/hub-move/TradingDesk-runtime-2026-11-23}"
REPO="$HOME/trading-bot"
RUNTIME="$HOME/trading-desk-runtime"
NEED="0.4.138"

say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\nNothing after this point was done.\n' "$*" >&2; exit 1; }

[ "$(uname)" = Linux ] || die "Run this on tradingserver (Ubuntu)."
[ "$(id -u)" -ne 0 ] || die "Run as epondboys, not with sudo."
[ -d "$SRC" ] || die "Runtime backup not found at $SRC"

say "1. Node"
node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>24||(a===24&&b>=19)?0:1)' \
  || die "Node 24.19 or newer is needed (found $(node -v 2>/dev/null || echo none)). Rerun the server setup script."
echo "Node $(node -v)"

say "2. Code (read-only GitHub token; it is asked for once and saved for this account only)"
git config --global credential.helper store
chmod 600 "$HOME/.git-credentials" 2>/dev/null || true
if [ ! -d "$REPO/.git" ]; then
  echo "Username: epondboys-dot    Password: paste the read-only token (nothing shows while you paste)"
  git clone https://github.com/epondboys-dot/ai-daytrading-bot.git "$REPO"
fi
chmod 600 "$HOME/.git-credentials" 2>/dev/null || true
git -C "$REPO" pull --ff-only
VERSION=$(node -p 'require(process.argv[1]).version' "$REPO/control-center/package.json")
echo "Desk code version $VERSION"
node -e 'const v=s=>s.split(".").map(Number),[a,b]=[v(process.argv[1]),v(process.argv[2])];process.exit(a[0]>b[0]||a[0]===b[0]&&(a[1]>b[1]||a[1]===b[1]&&a[2]>=b[2])?0:1)' "$VERSION" "$NEED" \
  || die "Code is older than $NEED; pull again."

say "3. Runtime -> $RUNTIME"
if [ -e "$RUNTIME" ]; then
  if [ -d "$RUNTIME" ] && [ -z "$(ls -A "$RUNTIME")" ]; then rmdir "$RUNTIME"
  elif [ -f "$RUNTIME/backup-manifest.json" ] || [ -f "$RUNTIME/workbench.json" ]; then
    echo "A runtime is already here; leaving it untouched (never overwritten)."
  else die "$RUNTIME exists and is not empty. Inspect it; nothing was overwritten."; fi
fi
if [ ! -e "$RUNTIME" ]; then
  ( cd "$REPO" && node control-center/backup-runtime.js "$SRC" "$RUNTIME" --with-logs >/dev/null )
  echo "Copied."
fi
chmod 700 "$RUNTIME"; [ -f "$RUNTIME/config.env" ] && chmod 600 "$RUNTIME/config.env"

say "4. Verify the copy"
( cd "$REPO" && node control-center/verify-runtime-backup.js "$RUNTIME" | grep -E '"consistent"' ) || die "Verification failed. Do not start; tell Claude."

say "5. Doctor (read-only)"
grep -q 'WORKBENCH_RUNTIME_DIR' "$HOME/.profile" || echo "export WORKBENCH_RUNTIME_DIR=\"$RUNTIME\"" >> "$HOME/.profile"
( cd "$REPO" && WORKBENCH_RUNTIME_DIR="$RUNTIME" node control-center/desk-doctor.js ) || true

cat <<EOF

=== Ready. The desk was NOT started.
Start it yourself, with Claude watching:
  cd ~/trading-bot && WORKBENCH_RUNTIME_DIR=$RUNTIME linux/start-trading-desk.sh --accept-startup-freeze
(--accept-startup-freeze only because the doctor shows the last run did not end cleanly.)
It comes up Stopped and frozen for your review, with entries disabled.
Afterwards: record the move in docs/OWNER_DECISIONS.md, and delete ~/hub-move from this machine.
EOF
