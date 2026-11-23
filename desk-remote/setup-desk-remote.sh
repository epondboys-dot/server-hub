#!/bin/bash
# Owner decision 12: Jarvis may start the Trading Desk on tradingserver, only after an owner approves in Discord.
# Run on Jarvis from the admin account:  sudo bash ~/desk-remote/setup-desk-remote.sh   (safe to rerun)
#  1. makes a dedicated SSH key for the jarvis user (no passphrase, only for this)
#  2. installs the forced-command script on tradingserver and adds the key there, locked to that script
#     (no shell, no port forwarding, no file copy). Uses your own admin key to reach tradingserver once.
#  3. tests 'status' through the restricted key and confirms anything else is refused
set -euo pipefail
ADMIN="${SUDO_USER:-epondboys}"
TS="${TRADING_SSH_HOST:-100.111.197.47}"
HERE="$(cd "$(dirname "$0")" && pwd)"
KEY=/Users/jarvis/.ssh/jarvis_desk_ed25519
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "Run with sudo:  sudo bash $0"

echo "=== 1. Key for the jarvis user"
mkdir -p /Users/jarvis/.ssh; chmod 700 /Users/jarvis/.ssh; chown jarvis:staff /Users/jarvis/.ssh
[ -f "$KEY" ] || sudo -u jarvis ssh-keygen -q -t ed25519 -N "" -C "jarvis-desk-start" -f "$KEY"
chown jarvis:staff "$KEY" "$KEY.pub"; chmod 600 "$KEY"
PUB=$(cat "$KEY.pub")

echo "=== 2. Install on tradingserver (as $ADMIN, using your normal key)"
sudo -u "$ADMIN" scp -q "$HERE/jarvis-desk-command.sh" "epondboys@$TS:~/jarvis-desk-command.sh"
sudo -u "$ADMIN" ssh "epondboys@$TS" "chmod 755 ~/jarvis-desk-command.sh && mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -v 'jarvis-desk-start' ~/.ssh/authorized_keys > ~/.ssh/ak.tmp; echo 'restrict,command=\"/home/epondboys/jarvis-desk-command.sh\" $PUB' >> ~/.ssh/ak.tmp && mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys && echo installed"

echo "=== 3. Test as the jarvis user"
# Accept tradingserver's host key for jarvis from the admin's known_hosts (already verified by fingerprint earlier).
sudo -u "$ADMIN" ssh-keygen -F "$TS" | grep -v '^#' > /Users/jarvis/.ssh/known_hosts || true
chown jarvis:staff /Users/jarvis/.ssh/known_hosts; chmod 644 /Users/jarvis/.ssh/known_hosts
sudo -u jarvis ssh -i "$KEY" -o BatchMode=yes -o IdentitiesOnly=yes "epondboys@$TS" status | head -20
echo "--- a disallowed command must be refused:"
sudo -u jarvis ssh -i "$KEY" -o BatchMode=yes -o IdentitiesOnly=yes "epondboys@$TS" "rm -rf /tmp/x" || true
echo
echo "Done. Add to /Users/jarvis/.jarvis-bot.env:  DESK_SSH_HOST=$TS   (the bot installer does this), then rerun it."
