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
install -m 644 "$SRC/discord-bot.js" "$SRC/tasks.js" "$SRC/desk.js" "$SRC/knowledge.js" "$SRC/package.json" "$APP/"
install -m 644 "$SRC/jarvis-bot.env.example" "$APP/"
( cd "$APP" && PATH="$(dirname "$NODE"):$PATH" "$NPM" install --omit=dev --no-audit --no-fund --loglevel=error )
# Version stamp (the updater compares it with GitHub) and the PA PC worker script the bot hands out.
VERSION="${HUB_VERSION:-$(git -c safe.directory='*' -C "$SRC/.." rev-parse HEAD 2>/dev/null || echo manual)}"
echo "$VERSION" > "$APP/VERSION"
mkdir -p "$APP/worker"; [ -f "$SRC/../pa-pc-worker/jarvis-worker.ps1" ] && install -m 644 "$SRC/../pa-pc-worker/jarvis-worker.ps1" "$APP/worker/"
chown -R root:wheel "$APP"
chmod -R go-w "$APP"
"$NODE" --check "$APP/discord-bot.js" && "$NODE" --check "$APP/tasks.js" && "$NODE" --check "$APP/desk.js" && "$NODE" --check "$APP/knowledge.js" && echo "Code OK."

say "2. Settings file $ENV_FILE"
if [ ! -f "$ENV_FILE" ]; then
  install -m 600 -o "$AGENT_USER" -g staff "$SRC/jarvis-bot.env.example" "$ENV_FILE"
  echo "Created from the template. Fill in the token and your Discord ID next."
else
  chown "$AGENT_USER":staff "$ENV_FILE"; chmod 600 "$ENV_FILE"
  echo "Kept your existing settings (permissions re-checked)."
  if ! grep -q '^DESK_SSH_HOST=' "$ENV_FILE"; then printf '\nDESK_SSH_HOST=100.111.197.47\n' >> "$ENV_FILE"; echo "Added DESK_SSH_HOST."; fi
  if ! grep -q '^CLAUDE_CODE_OAUTH_TOKEN=' "$ENV_FILE"; then
    printf '\n# Agent tasks: as jarvis run  claude setup-token  and paste the token here\nCLAUDE_CODE_OAUTH_TOKEN=\n' >> "$ENV_FILE"
    echo "Added a CLAUDE_CODE_OAUTH_TOKEN= line for agent tasks."
  fi
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

say "4b. Knowledge base: nightly learning at 02:30 (com.pondboys.jarvis-learn, runs as $AGENT_USER, local only)"
# Make sure every project Jarvis should learn has a read-only clone (skipped quietly if the GitHub key can't read it).
for r in server-hub x3-discord-admin-ai; do
  [ -d "$AGENT_HOME/projects/$r/.git" ] || sudo -u "$AGENT_USER" -H bash -lc "GIT_TERMINAL_PROMPT=0 git clone --quiet https://github.com/epondboys-dot/$r.git '$AGENT_HOME/projects/$r'" \
    && echo "    projects/$r ready" || echo "    projects/$r: could not clone (add it to the read-only GitHub key)"
done
LEARN_PLIST=/Library/LaunchDaemons/com.pondboys.jarvis-learn.plist
cat > "$LEARN_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.pondboys.jarvis-learn</string>
  <key>UserName</key><string>$AGENT_USER</string>
  <key>ProgramArguments</key><array><string>$NODE</string><string>$APP/knowledge.js</string><string>learn</string></array>
  <key>WorkingDirectory</key><string>$APP</string>
  <key>StartCalendarInterval</key><dict><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
  <key>StandardOutPath</key><string>$LOG_DIR/jarvis-learn.log</string>
  <key>StandardErrorPath</key><string>$LOG_DIR/jarvis-learn.log</string>
</dict></plist>
EOF
chown root:wheel "$LEARN_PLIST"; chmod 644 "$LEARN_PLIST"; plutil -lint "$LEARN_PLIST" >/dev/null
launchctl bootout system/com.pondboys.jarvis-learn 2>/dev/null || true
launchctl bootstrap system "$LEARN_PLIST" && echo "    nightly learning scheduled (first run tonight, or send 'learn' in Discord)"

say "4d. Test helpers for agents (installed with every update)"
if [ -f "$SRC/../jarvis-retro/retro-test" ] && [ -d "$AGENT_HOME/projects/retro-game-platform" ]; then
  install -d -o "$AGENT_USER" -g staff "$AGENT_HOME/bin"
  install -m 755 -o "$AGENT_USER" -g staff "$SRC/../jarvis-retro/retro-test" "$AGENT_HOME/bin/retro-test" && echo "    retro-test (with time limits)"
fi

say "4c. Self-updates (com.pondboys.hub-update, root): Jarvis asks for them when idle; nightly fallback 04:20"
LIB=/usr/local/libexec/pondboys; mkdir -p "$LIB" /usr/local/var/pondboys
if [ -f "$SRC/../jarvis-update/hub-update.sh" ]; then
  cp "$SRC/../jarvis-update/hub-update.sh" "$LIB/.hub-update.new" && chmod 755 "$LIB/.hub-update.new" && chown root:wheel "$LIB/.hub-update.new" && mv "$LIB/.hub-update.new" "$LIB/hub-update.sh"
fi
# The admin account that runs Homebrew and holds the SSH key for tradingserver (whoever ran this with sudo).
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ] && [ "$SUDO_USER" != "$AGENT_USER" ]; then
  TS_HOST="$(grep -E '^DESK_SSH_HOST=' "$ENV_FILE" 2>/dev/null | cut -d= -f2)"
  printf 'ADMIN_USER=%s\nTRADING_HOST=%s\n' "$SUDO_USER" "${TS_HOST:-100.111.197.47}" > "$LIB/updater.conf"
fi
chown -R root:wheel "$LIB"; chmod 644 "$LIB/updater.conf" 2>/dev/null || true
install -d -m 700 -o "$AGENT_USER" -g staff "$AGENT_HOME/hub/update" "$AGENT_HOME/hub/update/queue"
UPD_PLIST=/Library/LaunchDaemons/com.pondboys.hub-update.plist
cat > "$UPD_PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.pondboys.hub-update</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$LIB/hub-update.sh</string></array>
  <key>QueueDirectories</key><array><string>$AGENT_HOME/hub/update/queue</string></array>
  <key>StartCalendarInterval</key><dict><key>Hour</key><integer>4</integer><key>Minute</key><integer>20</integer></dict>
  <key>StandardOutPath</key><string>/Library/Logs/hub-update.log</string>
  <key>StandardErrorPath</key><string>/Library/Logs/hub-update.log</string>
</dict></plist>
PLISTEOF
chown root:wheel "$UPD_PLIST"; chmod 644 "$UPD_PLIST"; plutil -lint "$UPD_PLIST" >/dev/null
if [ -z "${HUB_UPDATER:-}" ]; then  # never reload the updater from inside its own run
  launchctl bootout system/com.pondboys.hub-update 2>/dev/null || true
  launchctl bootstrap system "$UPD_PLIST" && echo "    self-updates on (version ${VERSION:0:7}); admin account: $(grep ADMIN_USER "$LIB/updater.conf" 2>/dev/null | cut -d= -f2)"
fi

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
