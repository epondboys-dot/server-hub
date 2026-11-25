#!/bin/bash
# X3 Digital HQ Discord admin bot on Jarvis (moved from the PA PC, Nov 25, 2026). New hub keys (option B), never the PA PC's.
# Run from the admin account:  sudo bash ~/jarvis-x3/setup-x3-bot.sh      (safe to rerun)
#  1. jarvis's read-only clone of epondboys-dot/x3-discord-admin-ai in /Users/jarvis/projects
#  2. a Python 3.12 virtual environment owned by jarvis, and the unit tests
#  3. the settings file /Users/jarvis/.x3-bot.env (mode 600, filled in by the owner at the keyboard, never in chat)
#  4. a LaunchDaemon com.pondboys.x3-bot that runs as jarvis, starts at boot and restarts if it stops
# The bot does not start until the settings file has real values. Stop the PA PC copy before it starts (one token, one bot).
set -euo pipefail
REPO=/Users/jarvis/projects/x3-discord-admin-ai
ENVF=/Users/jarvis/.x3-bot.env
DATA=/Users/jarvis/hub/x3-data
PLIST=/Library/LaunchDaemons/com.pondboys.x3-bot.plist
PY=/opt/homebrew/opt/python@3.12/bin/python3.12
say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "Run with sudo:  sudo bash $0"
[ -x "$PY" ] || die "python3.12 missing (run the Crease setup first, or: brew install python@3.12)"
as_jarvis() { sudo -u jarvis -H bash -lc "$1"; }

say "1. Code"
if [ -d "$REPO/.git" ]; then as_jarvis "cd '$REPO' && git fetch --quiet origin && git merge --ff-only --quiet origin/main && git log --oneline -1"
else as_jarvis "git clone --quiet https://github.com/epondboys-dot/x3-discord-admin-ai.git '$REPO' && git -C '$REPO' log --oneline -1" \
  || die "Clone failed. If the GitHub read-only key only covers selected repos, add x3-discord-admin-ai to it (GitHub > Settings > Developer settings > Fine-grained tokens) and rerun."; fi

say "2. Python environment and tests"
as_jarvis "cd '$REPO' && { [ -x .venv/bin/python ] || '$PY' -m venv .venv; } && .venv/bin/python -m pip install --quiet --upgrade pip && .venv/bin/python -m pip install --quiet -r requirements.txt"
as_jarvis "cd '$REPO' && .venv/bin/python -m unittest discover -s tests -q 2>&1 | tail -3"

say "3. Settings file"
mkdir -p "$DATA"; chown jarvis:staff "$DATA"; chmod 700 "$DATA"
if [ ! -f "$ENVF" ]; then
  cat > "$ENVF" <<EOF
# X3 Digital HQ bot on Jarvis. Fill in at the keyboard; never paste these into chat or photograph this file.
DISCORD_TOKEN=REPLACE_WITH_NEW_X3_BOT_TOKEN
GUILD_ID=REPLACE_WITH_X3_SERVER_ID
OWNER_ID=REPLACE_WITH_YOUR_DISCORD_USER_ID
AUTHORIZED_USER_IDS=
GEMINI_API_KEY=REPLACE_WITH_NEW_HUB_GEMINI_KEY
LOG_LEVEL=INFO
LOG_FILE=$DATA/x3-bot.log
AUDIT_ENABLED=true
AUDIT_DB_PATH=$DATA/audit.db
EOF
  echo "    created $ENVF with placeholders"
else echo "    kept your existing $ENVF"; fi
chown jarvis:staff "$ENVF"; chmod 600 "$ENVF"
ln -sfn "$ENVF" "$REPO/.env"; chown -h jarvis:staff "$REPO/.env"

say "4. Start-at-boot service"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.pondboys.x3-bot</string>
  <key>UserName</key><string>jarvis</string>
  <key>WorkingDirectory</key><string>$REPO</string>
  <key>ProgramArguments</key><array><string>$REPO/.venv/bin/python</string><string>run_bot.py</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ThrottleInterval</key><integer>30</integer>
  <key>StandardOutPath</key><string>$DATA/x3-bot.out.log</string>
  <key>StandardErrorPath</key><string>$DATA/x3-bot.out.log</string>
</dict></plist>
EOF
chown root:wheel "$PLIST"; chmod 644 "$PLIST"
if grep -q REPLACE_WITH "$ENVF"; then
  echo "    Not started: fill in $ENVF first (sudo nano $ENVF), then rerun this script."
else
  launchctl bootout system/com.pondboys.x3-bot 2>/dev/null || true
  launchctl bootstrap system "$PLIST"; sleep 8
  launchctl print system/com.pondboys.x3-bot | grep -E "state =|pid =" || true
  tail -5 "$DATA/x3-bot.out.log" 2>/dev/null || true
fi
echo; echo "Done. Stop it any time:  sudo launchctl bootout system/com.pondboys.x3-bot"
