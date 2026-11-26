#!/bin/bash
# Hub updater for Jarvis (runs as root, installed by jarvis-bot/install.sh to /usr/local/libexec/pondboys/).
# launchd starts it when the Jarvis bot drops a request into /Users/jarvis/hub/update/queue/ (the bot only does that
# when no agent job is running), and every night at 04:20 as a fallback in case the bot itself is down.
# Requests (one word each): hub    newest server-hub main -> Jarvis bot, knowledge, learn job, X3 bot
#                           tools  upgrade Claude Code, Codex, Ollama and Node 24 (Homebrew, as the admin account)
#                           desk   newest ai-daytrading-bot main -> tradingserver (owner confirms in Discord first)
# Code only ever comes from GitHub main through Jarvis's read-only clones. Every step checks itself and rolls back:
# if the bot does not stay up on new code, the previous copy goes back. Results: /usr/local/var/pondboys/update-result.txt
set -uo pipefail
J=jarvis; JH=/Users/$J; Q=$JH/hub/update/queue
LIB=/usr/local/libexec/pondboys; CONF=$LIB/updater.conf
OUTD=/usr/local/var/pondboys; RESULT=$OUTD/update-result.txt
APP=/opt/jarvis-bot; LABEL=com.pondboys.jarvis-bot; NODE=/opt/homebrew/opt/node@24/bin/node
ADMIN_USER=""; TRADING_HOST=100.111.197.47
[ -f "$CONF" ] && . "$CONF"
mkdir -p "$OUTD"; exec >>/Library/Logs/hub-update.log 2>&1
echo; echo "=== $(date '+%F %T') hub-update"

bot_running() { launchctl print "system/$LABEL" 2>/dev/null | awk '/state = /{s=$3} /pid = /{p=$3} END{ if (s=="running") print p }'; }

# Read and clear the queue (only plain files, only lowercase words).
modes=""
if [ -d "$Q" ]; then
  for f in "$Q"/*; do [ -f "$f" ] && [ ! -L "$f" ] || continue; modes="$modes $(head -c 60 "$f" | tr -c 'a-z\n' ' ')"; rm -f "$f"; done
fi
if [ -z "${modes// /}" ]; then
  # Nightly fallback: only act if the bot is not running (otherwise the bot schedules updates itself).
  [ -n "$(bot_running)" ] && { echo "bot running; nothing queued"; exit 0; }
  modes="hub"; FALLBACK=1; echo "bot is not running: trying a hub update to bring it back"
fi
echo "requested:$modes"

report=(); ok=1
note() { echo "$*"; report+=("$*"); }
bad() { echo "FAILED: $*"; report+=("FAILED: $*"); ok=0; }
as_j() { sudo -u "$J" -H bash -lc "$1"; }
g() { git -c safe.directory='*' "$@"; }

update_hub() {
  local SRC=$JH/projects/server-hub
  [ -d "$SRC/.git" ] || as_j "git clone -q https://github.com/epondboys-dot/server-hub.git '$SRC'" || { bad "can't clone server-hub"; return; }
  as_j "cd '$SRC' && GIT_TERMINAL_PROMPT=0 git fetch -q origin && git checkout -q main && git merge --ff-only -q origin/main" || { bad "can't update the server-hub copy from GitHub"; return; }
  local NEW; NEW=$(g -C "$SRC" rev-parse origin/main); local OLD; OLD=$(cat "$APP/VERSION" 2>/dev/null || echo none)
  if [ "$NEW" = "$OLD" ]; then note "Jarvis code already current (${NEW:0:7})."; else
    local BAD; BAD=$(cat "$OUTD/bad-hub-version" 2>/dev/null || true)
    if [ "$NEW" = "$BAD" ]; then bad "${NEW:0:7} failed before and was rolled back; waiting for a newer commit"; return; fi
    local ST; ST=$(mktemp -d /tmp/hubsrc.XXXXXX)
    g clone -q --no-hardlinks "file://$SRC" "$ST/sh" && g -C "$ST/sh" checkout -q "$NEW" || { bad "can't stage ${NEW:0:7}"; rm -rf "$ST"; return; }
    for f in "$ST"/sh/jarvis-bot/*.js; do "$NODE" --check "$f" || { bad "syntax error in $(basename "$f") at ${NEW:0:7}; nothing installed"; rm -rf "$ST"; return; }; done
    bash -n "$ST/sh/jarvis-bot/install.sh" && bash -n "$ST/sh/jarvis-update/hub-update.sh" || { bad "installer syntax error at ${NEW:0:7}; nothing installed"; rm -rf "$ST"; return; }
    rm -rf "$APP.prev"; [ -d "$APP" ] && cp -Rp "$APP" "$APP.prev"
    if HUB_UPDATER=1 HUB_VERSION="$NEW" bash "$ST/sh/jarvis-bot/install.sh"; then
      sleep 20; local p1; p1=$(bot_running); sleep 25; local p2; p2=$(bot_running)
      if [ -n "$p1" ] && [ "$p1" = "$p2" ]; then
        note "Jarvis updated ${OLD:0:7} -> ${NEW:0:7}:"; while read -r l; do note "  - $l"; done < <(g -C "$SRC" log --format='%s' "${OLD}..${NEW}" 2>/dev/null | head -8 | cut -c1-120)
        rm -f "$OUTD/bad-hub-version"
      else
        bad "the bot did not stay up on ${NEW:0:7}; restoring the previous version"
        if [ -d "$APP.prev" ]; then rm -rf "$APP"; mv "$APP.prev" "$APP"; fi
        echo "$NEW" > "$OUTD/bad-hub-version"
        launchctl bootout "system/$LABEL" 2>/dev/null; launchctl bootstrap system "/Library/LaunchDaemons/$LABEL.plist"
      fi
    else
      bad "installer stopped at ${NEW:0:7}; restoring the previous version"
      if [ -d "$APP.prev" ]; then rm -rf "$APP"; mv "$APP.prev" "$APP"; fi
      echo "$NEW" > "$OUTD/bad-hub-version"
      launchctl bootout "system/$LABEL" 2>/dev/null; launchctl bootstrap system "/Library/LaunchDaemons/$LABEL.plist"
    fi
    rm -rf "$ST"
  fi
  # X3 bot: newer code -> refresh its packages and restart it (only if it is installed).
  local X=$JH/projects/x3-discord-admin-ai
  if [ -f /Library/LaunchDaemons/com.pondboys.x3-bot.plist ] && [ -d "$X/.git" ]; then
    as_j "cd '$X' && GIT_TERMINAL_PROMPT=0 git fetch -q origin && git merge --ff-only -q origin/main" || bad "can't update the X3 copy"
    local XN; XN=$(g -C "$X" rev-parse HEAD); local XO; XO=$(cat "$OUTD/x3-version" 2>/dev/null || true)
    if [ "$XN" != "$XO" ]; then
      [ -f "$X/requirements.txt" ] && { as_j "cd '$X' && .venv/bin/pip install -q -r requirements.txt" || bad "X3 package install"; }
      if as_j "cd '$X' && .venv/bin/python -m unittest discover -s tests >/dev/null 2>&1"; then
        launchctl kickstart -k system/com.pondboys.x3-bot && echo "$XN" > "$OUTD/x3-version" && note "X3 bot updated to ${XN:0:7} and restarted."
      else bad "X3 tests fail at ${XN:0:7}; X3 bot left on the old run"; fi
    fi
  fi
  # This updater itself (atomic swap; the running copy finishes on the old file).
  if [ -f "$SRC/jarvis-update/hub-update.sh" ] && bash -n "$SRC/jarvis-update/hub-update.sh"; then
    cp "$SRC/jarvis-update/hub-update.sh" "$LIB/.hub-update.new" && chmod 755 "$LIB/.hub-update.new" && chown root:wheel "$LIB/.hub-update.new" && mv "$LIB/.hub-update.new" "$LIB/hub-update.sh"
  fi
}

update_tools() {
  [ -n "$ADMIN_USER" ] || { bad "tools: no admin account recorded (rerun jarvis-bot/install.sh once with sudo)"; return; }
  local B=/opt/homebrew/bin/brew
  sudo -u "$ADMIN_USER" -H "$B" update -q >/dev/null 2>&1
  local changed=()
  for p in claude-code codex ollama node@24; do
    for kind in --formula --cask; do
      sudo -u "$ADMIN_USER" -H "$B" list $kind "$p" >/dev/null 2>&1 || continue
      if sudo -u "$ADMIN_USER" -H "$B" outdated $kind -q "$p" 2>/dev/null | grep -q .; then
        sudo -u "$ADMIN_USER" -H "$B" upgrade $kind -q "$p" >/dev/null 2>&1 && changed+=("$p") || bad "upgrading $p"
      fi
    done
  done
  local v; v="Claude Code $(/opt/homebrew/bin/claude --version 2>/dev/null | head -1 | awk '{print $1}'), Codex $(/opt/homebrew/bin/codex --version 2>/dev/null | awk '{print $NF}')"
  if [ ${#changed[@]} -gt 0 ]; then note "Tools upgraded: ${changed[*]} ($v)."; else note "Tools already current ($v)."; fi
  [[ " ${changed[*]} " == *" node@24 "* ]] && launchctl kickstart -k "system/$LABEL"
}

update_desk() {
  [ -n "$ADMIN_USER" ] || { bad "desk: no admin account recorded"; return; }
  local R=$JH/projects/ai-daytrading-bot
  as_j "cd '$R' && GIT_TERMINAL_PROMPT=0 git fetch -q origin && git checkout -q main && git merge --ff-only -q origin/main" || { bad "can't update the trading-bot copy from GitHub"; return; }
  local BUN=/tmp/desk-update.bundle; rm -f "$BUN"
  g -C "$R" bundle create "$BUN" main >/dev/null 2>&1 || { bad "can't bundle the desk code"; return; }
  chown "$ADMIN_USER" "$BUN"
  sudo -u "$ADMIN_USER" -H scp -q -o BatchMode=yes "$BUN" "epondboys@$TRADING_HOST:/tmp/desk-update.bundle" || { bad "can't reach tradingserver"; return; }
  local out
  out=$(sudo -u "$ADMIN_USER" -H ssh -o BatchMode=yes "epondboys@$TRADING_HOST" 'bash -s' <<'EOS'
set -u; export XDG_RUNTIME_DIR=/run/user/$(id -u)
R=~/trading-bot; RT=~/trading-desk-runtime
[ -e "$RT/HARD_OFF.json" ] && { echo "REFUSED: hard-off is latched; nothing changed. Only you clear it, at tradingserver."; exit 3; }
cd "$R" || exit 9
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "REFUSED: tradingserver has local code changes; nothing changed."; exit 4; }
OLD=$(git rev-parse HEAD)
git fetch -q /tmp/desk-update.bundle main:refs/jarvis/incoming && git merge --ff-only -q refs/jarvis/incoming || { echo "REFUSED: not a fast-forward from what tradingserver runs; nothing changed."; exit 5; }
NEW=$(git rev-parse HEAD); rm -f /tmp/desk-update.bundle
[ "$OLD" = "$NEW" ] && { echo "Desk already current ($(git log -1 --format='%h %s' | cut -c1-90))."; exit 0; }
if ! git diff --quiet "$OLD" "$NEW" -- package.json package-lock.json; then npm ci --omit=dev --no-audit --no-fund --loglevel=error || { git reset -q --hard "$OLD"; echo "ROLLED BACK: npm install failed"; exit 6; }; fi
for f in $(git diff --name-only "$OLD" "$NEW" -- '*.js'); do [ -f "$f" ] && { node --check "$f" || { git reset -q --hard "$OLD"; echo "ROLLED BACK: syntax error in $f"; exit 6; }; }; done
systemctl --user restart trading-desk.service; sleep 20
if systemctl --user is-active -q trading-desk.service; then
  systemctl --user restart trading-desk-gateway.service 2>/dev/null
  echo "Desk updated $(git rev-parse --short "$OLD") -> $(git rev-parse --short "$NEW"), version $(node -p "require('./control-center/package.json').version" 2>/dev/null): $(git log -1 --format=%s | cut -c1-90)"
else
  git reset -q --hard "$OLD"; systemctl --user restart trading-desk.service
  echo "ROLLED BACK: the desk did not stay up on the new code; it is back on $(git rev-parse --short "$OLD")."; exit 7
fi
EOS
)
  local rc=$?; rm -f "$BUN"
  if [ $rc -eq 0 ]; then note "$out"; else bad "$out"; fi
}

for m in $(echo "$modes" | tr ' ' '\n' | awk 'NF && !seen[$0]++'); do
  case "$m" in hub) update_hub ;; tools) update_tools ;; desk) update_desk ;; *) echo "ignored request '$m'" ;; esac
done
if [ -n "${FALLBACK:-}" ] && [ -z "$(bot_running)" ]; then
  launchctl bootout "system/$LABEL" 2>/dev/null; launchctl bootstrap system "/Library/LaunchDaemons/$LABEL.plist"; sleep 15
  if [ -n "$(bot_running)" ]; then note "Jarvis was down overnight; restarted him."; else bad "Jarvis is down and would not restart; see ~jarvis/Library/Logs/jarvis-bot.log"; fi
fi
{ echo "id $(date +%s)"; echo "ok $ok"; printf '%s\n' "${report[@]}"; } > "$RESULT.tmp" && chmod 644 "$RESULT.tmp" && mv "$RESULT.tmp" "$RESULT"
# Wake the bot so it posts the result (if it is up and the hub update didn't already restart it).
echo "done ok=$ok"
