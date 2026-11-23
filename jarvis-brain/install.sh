#!/bin/bash
# Install or update Jarvis's daily project briefing.
# Run from the admin account:  sudo bash ~/jarvis-brain/install.sh
# Safe to rerun.
#
#   /opt/jarvis-brain/                      code + project registry (root-owned)
#   /Users/jarvis/hub/briefings/            output (latest.md, dated copies, refresh.log)
#   /Library/LaunchDaemons/com.pondboys.jarvis-brief.plist   runs as jarvis, 07:25 daily
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
APP=/opt/jarvis-brain
AGENT_USER=jarvis
AGENT_HOME="/Users/$AGENT_USER"
OUT="$AGENT_HOME/hub/briefings"
LABEL=com.pondboys.jarvis-brief
PLIST="/Library/LaunchDaemons/$LABEL.plist"
BOT_ENV="$AGENT_HOME/.jarvis-bot.env"
BOT_LABEL=com.pondboys.jarvis-bot
NODE=/opt/homebrew/opt/node@24/bin/node

say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "This script is for macOS (Jarvis)."
[ "$(id -u)" -eq 0 ] || die "Run it with sudo:  sudo bash $0"
id "$AGENT_USER" >/dev/null 2>&1 || die "User '$AGENT_USER' does not exist."
[ -x "$NODE" ] || die "Node 24 not found at $NODE."
[ -d "$AGENT_HOME/projects" ] || die "No $AGENT_HOME/projects folder. Clone the repos as jarvis first."

say "1. Code -> $APP (root-owned)"
mkdir -p "$APP"
install -m 644 "$SRC/briefing.js" "$SRC/projects.jarvis.json" "$APP/"
install -m 755 "$SRC/refresh-and-brief.sh" "$SRC/unattended-git-signin.sh" "$APP/"
chown -R root:wheel "$APP"
"$NODE" --check "$APP/briefing.js" && echo "Code OK."

say "2. Output folder $OUT"
mkdir -p "$OUT"
chown -R "$AGENT_USER":staff "$AGENT_HOME/hub"

say "3. Daily schedule ($LABEL, 07:25, runs as $AGENT_USER)"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>UserName</key><string>$AGENT_USER</string>
  <key>GroupName</key><string>staff</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$APP/refresh-and-brief.sh</string></array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key><string>$AGENT_HOME</string>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/bin:/bin</string>
    <key>BRIEFING_REGISTRY</key><string>$APP/projects.jarvis.json</string>
    <key>BRIEFING_OUT_DIR</key><string>$OUT</string>
  </dict>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>7</integer><key>Minute</key><integer>25</integer></dict>
  <key>StandardOutPath</key><string>$OUT/run.log</string>
  <key>StandardErrorPath</key><string>$OUT/run.log</string>
</dict>
</plist>
EOF
chown root:wheel "$PLIST"; chmod 644 "$PLIST"
plutil -lint "$PLIST" >/dev/null && echo "Schedule file OK."
launchctl bootout "system/$LABEL" 2>/dev/null || true
launchctl bootstrap system "$PLIST"

say "4. Point the Discord bot at the briefing"
if [ -f "$BOT_ENV" ]; then
  if grep -q '^BRIEFING_FILE=' "$BOT_ENV"; then
    sed -i '' "s#^BRIEFING_FILE=.*#BRIEFING_FILE=$OUT/latest.md#" "$BOT_ENV"
  else
    printf '\nBRIEFING_FILE=%s\n' "$OUT/latest.md" >> "$BOT_ENV"
  fi
  chown "$AGENT_USER":staff "$BOT_ENV"; chmod 600 "$BOT_ENV"
  launchctl kickstart -k "system/$BOT_LABEL" 2>/dev/null && echo "Bot restarted." || echo "Bot not running; start it with its own installer."
else
  echo "Bot settings file not found; skipped."
fi

say "5. First run now"
launchctl kickstart "system/$LABEL"
sleep 20
echo "Refresh results:"; cat "$OUT/refresh.log" 2>/dev/null || echo "(not written yet)"
echo; echo "Needs you:"
awk '/^## Needs you/{f=1;next} /^## /{f=0} f' "$OUT/latest.md" 2>/dev/null || echo "(briefing not written yet; see $OUT/run.log)"
echo
echo "Done. In Discord type:  briefing"
