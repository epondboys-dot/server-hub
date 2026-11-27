#!/bin/bash
# Give a Bridges founder their own remote workspace on Jarvis (run on Jarvis as the admin account, once per founder):
#   sudo bash add-founder.sh <short-name> "<Full Name>"
# What they get: a standard (non-admin) Mac account with its own copy of the Bridges code and nothing else.
# What they can't see: Jarvis's projects (trading desk, Sixes, X3, ...), other accounts, settings files, keys.
# Remote access is SSH over Tailscale only, and only for accounts in the bridges group (plus the admin).
# Before inviting founders to the tailnet, change the desk phone rule from "all members" to the owner (see README).
set -euo pipefail
NAME="${1:-}"; FULL="${2:-}"
[[ "$NAME" =~ ^[a-z][a-z0-9]{1,15}$ ]] && [ -n "$FULL" ] || { echo 'usage: sudo bash add-founder.sh <short-name, lowercase> "<Full Name>"'; exit 1; }
[ "$(id -u)" = 0 ] || { echo "Run with sudo."; exit 1; }
ADMIN="${SUDO_USER:-}"; [ -n "$ADMIN" ] && [ "$ADMIN" != root ] || { echo "Run with sudo from the admin account."; exit 1; }
U="btb-$NAME"

echo "=== 1. Lock down everyone's home folder (others can't list or read them)"
for h in /Users/*; do
  u=$(basename "$h"); [ "$u" = Shared ] || [ "$u" = Guest ] && continue
  id "$u" >/dev/null 2>&1 && chmod 700 "$h" && echo "    $h -> private"
done

echo "=== 2. Bridges group"
dseditgroup -o read bridges >/dev/null 2>&1 || dseditgroup -o create -r "Bridges to Brilliance founders" bridges
echo "=== 3. Account $U (standard, not admin). Type a temporary password for $FULL; they change it at first sign-in."
if ! id "$U" >/dev/null 2>&1; then
  sysadminctl -addUser "$U" -fullName "$FULL (Bridges)" -password - -home "/Users/$U" >/dev/null
  createhomedir -c -u "$U" >/dev/null
  pwpolicy -u "$U" -setpolicy "newPasswordRequired=1" >/dev/null 2>&1 || true
fi
dseditgroup -o edit -a "$U" -t user bridges
chmod 700 "/Users/$U"

echo "=== 4. Remote Login (SSH): only the admin and the bridges group"
dseditgroup -o read com.apple.access_ssh >/dev/null 2>&1 || dseditgroup -o create -q com.apple.access_ssh
dseditgroup -o edit -a "$ADMIN" -t user com.apple.access_ssh
dseditgroup -o edit -a bridges -t group com.apple.access_ssh
systemsetup -getremotelogin 2>/dev/null | grep -q On || systemsetup -f -setremotelogin on >/dev/null
echo "    SSH allowed for: $ADMIN and group bridges"

echo "=== 5. Their own copy of the Bridges code (read from the nonprofit repo with their own GitHub account later)"
SRC=/Users/jarvis/projects/bridges-app
if [ -d "$SRC/.git" ]; then
  R=$(git -c safe.directory='*' -C "$SRC" remote get-url origin)
  sudo -u "$U" -H git clone -q --no-hardlinks "file://$SRC" "/Users/$U/bridges-app" && sudo -u "$U" -H git -C "/Users/$U/bridges-app" remote set-url origin "$(echo "$R" | sed 's#^git@github.com:#https://github.com/#')"
  echo "    /Users/$U/bridges-app (origin = the nonprofit repo; they sign in with their own GitHub account to push)"
else echo "    Bridges code isn't on Jarvis yet (setup-bridges.sh clone first); skipped."; fi

echo
echo "Done. $FULL connects with:  ssh $U@<Jarvis's Tailscale name>   (after you invite them to the tailnet)"
