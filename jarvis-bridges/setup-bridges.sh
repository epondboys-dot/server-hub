#!/bin/bash
# Bridges to Brilliance app code on Jarvis (owner request, Nov 26). Run on Jarvis as the admin account:
#   sudo bash setup-bridges.sh key                      -> makes Jarvis's read-only key for the Bridges repo and prints it
#   sudo bash setup-bridges.sh clone <org>/<repo>       -> after the key is added to that repo as a READ-ONLY deploy key
# What Jarvis gets: the app's CODE only (Base44 never exports client data or secrets), at /Users/jarvis/projects/bridges-app.
# Agents can read it and work on copies; they cannot push (read-only key). Because Base44 syncs GitHub main straight into
# the live app, nothing reaches main except by an owner's own push/merge. Never run the app here against live Base44 data.
set -euo pipefail
J=jarvis; JH=/Users/$J; KEY=$JH/.ssh/bridges_deploy_ed25519; DEST=$JH/projects/bridges-app
as_j() { sudo -u "$J" -H bash -lc "$1"; }
case "${1:-}" in
  key)
    as_j "mkdir -p ~/.ssh && chmod 700 ~/.ssh && { [ -f '$KEY' ] || ssh-keygen -q -t ed25519 -N '' -C 'jarvis-read-only (Bridges)' -f '$KEY'; }"
    echo; echo "Add this as a deploy key on the Bridges repo (Settings > Deploy keys > Add deploy key)."
    echo "Title: Jarvis read-only.  Leave 'Allow write access' UNCHECKED."; echo
    cat "$KEY.pub"; echo ;;
  clone)
    R="${2:-}"; [[ "$R" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "usage: $0 clone <org>/<repo>"; exit 1; }
    [ -f "$KEY" ] || { echo "Run '$0 key' first."; exit 1; }
    SSHC="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
    if [ -d "$DEST/.git" ]; then as_j "cd '$DEST' && git fetch -q origin && git merge --ff-only -q origin/HEAD 2>/dev/null || git pull -q --ff-only"
    else as_j "GIT_SSH_COMMAND='$SSHC' git clone -q 'git@github.com:$R.git' '$DEST' && git -C '$DEST' config core.sshCommand '$SSHC'"; fi
    as_j "cd '$DEST' && git log --oneline -1 && echo \"files: \$(git ls-files | wc -l)\""
    # Make sure nothing in the copy looks like client data or a secret (Base44 code exports should have none).
    as_j "cd '$DEST' && git ls-files | grep -Ei '\\.(csv|xlsx|sqlite|db)$|(^|/)\\.env' || true" | sed 's/^/    check this file: /'
    echo "Done. In Discord: 'what is in the bridges app?' or 'plan bridges <what you want>'." ;;
  *) echo "usage: $0 key | clone <org>/<repo>"; exit 1 ;;
esac
