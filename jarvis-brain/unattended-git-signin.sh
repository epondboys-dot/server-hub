#!/bin/bash
# One time, run as jarvis while logged in at the Mac's login screen (not through sudo):
#   bash ~/jarvis-brain/unattended-git-signin.sh   (copy the folder to jarvis first, or run it from /opt/jarvis-brain)
#
# Why: the 07:25 refresh runs when nobody is logged in as jarvis, and then jarvis's keychain
# is locked, so Git can't read the GitHub token from it. This copies the token from the
# keychain into ~/.git-credentials (readable only by jarvis; the disk is encrypted by FileVault).
# The token is never printed. Git tries the keychain first and this file second.
set -euo pipefail
[ "$(id -un)" = jarvis ] || { echo "Run this as the jarvis user."; exit 1; }
CRED="$HOME/.git-credentials"
umask 077
printf 'protocol=https\nhost=github.com\n\n' | git credential fill | git credential-store --file "$CRED" store
chmod 600 "$CRED"
git config --global --unset-all credential.helper 2>/dev/null || true
git config --global --add credential.helper osxkeychain
git config --global --add credential.helper "store --file $CRED"
if grep -q 'github.com' "$CRED"; then echo "Done. Unattended refresh can sign in to GitHub (read-only token)."; else echo "Nothing saved. Is the token in the keychain? Try a git fetch in ~/projects first."; fi
