#!/bin/bash
# Bridges to Brilliance app code on Jarvis (owner request, Nov 26). Run on Jarvis as the admin account:
#   sudo bash setup-bridges.sh key                      -> makes Jarvis's read-only key for the Bridges repo and prints it
#   sudo bash setup-bridges.sh clone <org>/<repo>       -> after the key is added to that repo as a READ-ONLY deploy key
# What Jarvis gets: the app's CODE only (Base44 never exports client data or secrets), at /Users/jarvis/projects/bridges-app.
# Agents work on copies; Jarvis pushes finished work only to jarvis/T<n> branches (enforced twice). Because Base44 syncs GitHub main straight into
# the live app, nothing reaches main except by an owner's own push/merge. Never run the app here against live Base44 data.
set -euo pipefail
J=jarvis; JH=/Users/$J; KEY=$JH/.ssh/bridges_deploy_ed25519; DEST=$JH/projects/bridges-app
as_j() { sudo -u "$J" -H bash -lc "$1"; }
case "${1:-}" in
  key)
    as_j "mkdir -p ~/.ssh && chmod 700 ~/.ssh && { [ -f '$KEY' ] || ssh-keygen -q -t ed25519 -N '' -C 'jarvis-read-only (Bridges)' -f '$KEY'; }"
    echo; echo "Add this as a deploy key on the Bridges repo (Settings > Deploy keys > Add deploy key)."
    echo "Title: Jarvis. Tick 'Allow write access' (Jarvis pushes only jarvis/T<n> branches; founders merge)."; echo
    cat "$KEY.pub"; echo ;;
  clone)
    R="${2:-}"; [[ "$R" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo "usage: $0 clone <org>/<repo>"; exit 1; }
    [ -f "$KEY" ] || { echo "Run '$0 key' first."; exit 1; }
    SSHC="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
    if [ -d "$DEST/.git" ]; then as_j "cd '$DEST' && git fetch -q origin && git merge --ff-only -q origin/HEAD 2>/dev/null || git pull -q --ff-only"
    else as_j "GIT_SSH_COMMAND='$SSHC' git clone -q 'git@github.com:$R.git' '$DEST' && git -C '$DEST' config core.sshCommand '$SSHC'"; fi
    # Second lock (besides Jarvis's own code): git refuses every push except to a jarvis/T<n> branch, never main.
    # Root-owned, so nothing running as the jarvis user can change it; agent copies (worktrees) share it.
    HOOK="$DEST/.git/hooks/pre-push"
    cat > "$HOOK" <<'HK'
#!/bin/sh
# Bridges: Jarvis may only push his own task branches (jarvis/T<n>). main is the live app; founders merge.
while read local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in refs/heads/jarvis/T[0-9]*) ;; *) echo "Refused: Jarvis only pushes jarvis/T<n> branches (tried $remote_ref)." >&2; exit 1 ;; esac
  [ "$local_sha" = 0000000000000000000000000000000000000000 ] && { echo "Refused: Jarvis never deletes remote branches." >&2; exit 1; }
done
exit 0
HK
    chown root:wheel "$HOOK"; chmod 755 "$HOOK"; chown root:wheel "$DEST/.git/hooks"; chmod 755 "$DEST/.git/hooks"
    echo "    push guard installed: only jarvis/T<n> branches, never main"
    as_j "cd '$DEST' && git log --oneline -1 && echo \"files: \$(git ls-files | wc -l)\""
    # Make sure nothing in the copy looks like client data or a secret (Base44 code exports should have none).
    as_j "cd '$DEST' && git ls-files | grep -Ei '\\.(csv|xlsx|sqlite|db)$|(^|/)\\.env' || true" | sed 's/^/    check this file: /'
    echo "Done. In Discord: 'what is in the bridges app?' or 'plan bridges <what you want>'." ;;
  *) echo "usage: $0 key | clone <org>/<repo>"; exit 1 ;;
esac
