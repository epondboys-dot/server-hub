#!/bin/bash
# Run Ollama as a background service on Jarvis, so the local AI works no matter who is logged in.
# Run from the admin account:  sudo bash ~/jarvis-ollama/install.sh     (safe to rerun)
#
#   Service: /Library/LaunchDaemons/com.pondboys.ollama.plist  (runs as the standard user jarvis)
#   Models:  /Users/Shared/ollama/models  (moved from /Users/epondboys/.ollama/models, no re-download)
#   Listens: 127.0.0.1:11434 only (never the network)
#   Log:     /Users/jarvis/Library/Logs/ollama.log
set -euo pipefail

LABEL=com.pondboys.ollama
PLIST="/Library/LaunchDaemons/$LABEL.plist"
AGENT_USER=jarvis
ADMIN_HOME=/Users/epondboys
MODELS_OLD="$ADMIN_HOME/.ollama/models"
MODELS=/Users/Shared/ollama/models
LOG=/Users/$AGENT_USER/Library/Logs/ollama.log

say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "This script is for macOS (Jarvis)."
[ "$(id -u)" -eq 0 ] || die "Run it with sudo:  sudo bash $0"
id "$AGENT_USER" >/dev/null 2>&1 || die "User '$AGENT_USER' does not exist."

BIN=""
for c in /Applications/Ollama.app/Contents/Resources/ollama /usr/local/bin/ollama /opt/homebrew/bin/ollama; do
  [ -x "$c" ] && { BIN="$c"; break; }
done
[ -n "$BIN" ] || die "Could not find the ollama program. Is Ollama installed in Applications?"
echo "Using $BIN"

say "1. Stop the Ollama app (the service replaces it)"
pkill -x Ollama 2>/dev/null || true
pkill -f "ollama serve" 2>/dev/null || true
launchctl bootout "system/$LABEL" 2>/dev/null || true
sleep 3

say "2. Models -> $MODELS"
mkdir -p "$(dirname "$MODELS")"
if [ -d "$MODELS_OLD" ] && [ ! -d "$MODELS" ]; then
  mv "$MODELS_OLD" "$MODELS"
  echo "Moved the downloaded models (no re-download)."
elif [ -d "$MODELS" ]; then
  echo "Models already in place."
else
  mkdir -p "$MODELS"; echo "No models found yet; pull them after install."
fi
chown -R "$AGENT_USER":staff /Users/Shared/ollama
chmod 750 /Users/Shared/ollama
mkdir -p "$(dirname "$LOG")"; chown "$AGENT_USER":staff "$(dirname "$LOG")"

say "3. Service file ($LABEL, runs as $AGENT_USER, 127.0.0.1 only)"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>UserName</key><string>$AGENT_USER</string>
  <key>GroupName</key><string>staff</string>
  <key>ProgramArguments</key>
  <array><string>$BIN</string><string>serve</string></array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key><string>/Users/$AGENT_USER</string>
    <key>OLLAMA_HOST</key><string>127.0.0.1:11434</string>
    <key>OLLAMA_MODELS</key><string>$MODELS</string>
    <key>OLLAMA_KEEP_ALIVE</key><string>30m</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>15</integer>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF
chown root:wheel "$PLIST"; chmod 644 "$PLIST"
plutil -lint "$PLIST" >/dev/null && echo "Service file OK."

say "4. Start"
launchctl bootstrap system "$PLIST"
for i in $(seq 1 20); do
  curl -s -m 2 http://127.0.0.1:11434/api/tags >/dev/null && break
  sleep 1
done
if curl -s -m 3 http://127.0.0.1:11434/api/tags >/dev/null; then
  echo "Ollama is answering on 127.0.0.1:11434. Models:"
  "$BIN" list || true
else
  echo "Ollama did not answer yet. Last log lines:"; tail -n 15 "$LOG" 2>/dev/null || true
  exit 1
fi

say "5. Restart the Discord bot so it reconnects"
launchctl kickstart -k system/com.pondboys.jarvis-bot 2>/dev/null && echo "Bot restarted." || echo "Bot service not found; skipped."

echo
echo "Done. Last step (by hand): System Settings > General > Login Items, remove Ollama,"
echo "and don't open the Ollama app again (the service now does its job)."
echo "Stop the service:  sudo launchctl bootout system/$LABEL"
