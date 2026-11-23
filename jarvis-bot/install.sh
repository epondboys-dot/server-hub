#!/bin/bash
# Install or update the Jarvis Discord bot on the Mac mini "jarvis".
# Run from the admin account:  sudo bash ~/jarvis-bot/install.sh
# Safe to rerun. It never prints or copies the bot token.
#
# Layout:
#   /opt/jarvis-bot/                      code (owned by root: the bot cannot edit itself)
#   /Users/jarvis/.jarvis-bot.env         settings + token (owned by jarvis, mode 600)
#   /Users/jarvis/Library/Logs/jarvis-bot.log
#   /Library/LaunchDaemons/com.pondboys.jarvis-bot.plist   runs as user "jarvis", starts at boot
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
APP=/opt/jarvis-bot
AGENT_USER=jarvis
AGENT_HOME="/Users/$AGENT_USER"
ENV_FILE="$AGENT_HOME/.jarvis-bot.env"
LOG_DIR="$AGENT_HOME/Library/Logs"
LABEL=com.pondboys.jarvis-bot
PLIST="/Library/LaunchDaemons/$LABEL.plist"
NODE=/opt/homebrew/opt/node@24/bin/node
NPM=/opt/homebrew/opt/node@24/bin/npm

say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "This script is for macOS (Jarvis)."
[ "$(id -u)" -eq 0 ] || die "Run it with sudo:  sudo bash $0"
id "$AGENT_USER" >/dev/null 2>&1 || die "User '$AGENT_USER' does not exist. Create it in System Settings > Users & Groups (Standard)."
[ -x "$NODE" ] || die "Node 24 not found at $NODE. Run: brew install node@24"
dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -qw "$AGENT_USER" \
  && die "'$AGENT_USER' is an admin account. Make it Standard first (Users & Groups)."

say "1. Code -> $APP (root-owned)"
mkdir -p "$APP"
install -m 644 "$SRC/discord-bot.js" "$SRC/package.json" "$APP/"
install -m 644 "$SRC/jarvis-bot.env.example" "$APP/"
( cd "$APP" && PATH="$(dirname "$NODE"):$PATH" "$NPM" install --omit=dev --no-audit --no-fund --loglevel=error )
chown -R root:wheel "$APP"
chmod -R go-w "$APP"
"$NODE" --check "$APP/discord-bot.js" && echo "Code OK."

say "2. Settings file $ENV_FILE"
if [ ! -f "$ENV_FILE" ]; then
  install -m 600 -o "$AGENT_USER" -g staff "$SRC/jarvis-bot.env.example" "$ENV_FILE"
  echo "Created from the template. Fill in the token and your Discord ID next."
else
  chown "$AGENT_USER":staff "$ENV_FILE"; chmod 600 "$ENV_FILE"
  echo "Kept your existing settings (permissions re-checked)."
fi

say "3. Log folder"
mkdir -p "$LOG_DIR"
chown "$AGENT_USER":staff "$LOG_DIR"

say "4. Start-at-boot service ($LABEL, runs as $AGENT_USER)"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>UserName</key><string>$AGENT_USER</string>
  <key>GroupName</key><string>staff</string>
  <key>ProgramArguments</key>
  <array>
    <string>$NODE</string>
    <string>$APP/discord-bot.js</string>
    <string>--env</string>
    <string>$ENV_FILE</string>
  </array>
  <key>WorkingDirectory</key><string>$APP</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ThrottleInterval</key><integer>30</integer>
  <key>StandardOutPath</key><string>$LOG_DIR/jarvis-bot.log</string>
  <key>StandardErrorPath</key><string>$LOG_DIR/jarvis-bot.log</string>
</dict>
</plist>
EOF
chown root:wheel "$PLIST"; chmod 644 "$PLIST"
plutil -lint "$PLIST" >/dev/null && echo "Service file OK."

say "5. Start"
launchctl bootout "system/$LABEL" 2>/dev/null || true
if grep -Eq '^DISCORD_BOT_TOKEN=paste|^DISCORD_BOT_TOKEN=$' "$ENV_FILE" || ! grep -Eq '^OWNER_DISCORD_ID=[0-9]{17,20}(,[0-9]{17,20})*$' "$ENV_FILE"; then
  echo "Not started: the token or your Discord ID is not filled in yet."
  echo "Edit it with:   sudo nano $ENV_FILE"
  echo "Then rerun:     sudo bash $0"
  exit 0
fi
launchctl bootstrap system "$PLIST"
sleep 5
echo "Last log lines:"
tail -n 5 "$LOG_DIR/jarvis-bot.log" 2>/dev/null || true
echo
echo "Done. In Discord, message Jarvis:  help"
echo "Stop it any time:  sudo launchctl bootout system/$LABEL"
