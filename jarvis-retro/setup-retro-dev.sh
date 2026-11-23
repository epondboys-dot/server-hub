#!/bin/bash
# Rewind Arcade (retro-game-platform): development and tests on Jarvis. No keys: unit tests use an in-memory
# database (PGlite) and the live store stays on Cloudflare + Supabase, untouched. Owner, November 23, 2026.
# Run from the admin account:  sudo bash ~/jarvis-retro/setup-retro-dev.sh   (safe to rerun)
set -euo pipefail
REPO=/Users/jarvis/projects/retro-game-platform
NODEBIN=/opt/homebrew/opt/node@24/bin
say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "Run with sudo:  sudo bash $0"
[ -d "$REPO/.git" ] || die "No clone at $REPO"
as_jarvis() { sudo -u jarvis -H bash -lc "export PATH=$NODEBIN:/opt/homebrew/bin:/usr/bin:/bin; $1"; }

say "1. Update the read-only clone"
as_jarvis "cd '$REPO' && git fetch --quiet origin && git merge --ff-only --quiet '@{u}' && git log --oneline -1"

say "2. pnpm (via Node's corepack, inside jarvis's home)"
as_jarvis "mkdir -p ~/.local/bin && corepack enable --install-directory ~/.local/bin pnpm && ~/.local/bin/pnpm --version"

say "3. Dependencies"
as_jarvis "cd '$REPO' && ~/.local/bin/pnpm install --frozen-lockfile --reporter=silent && echo installed"

say "4. Playwright WebKit and Chromium browsers (for browser tests)"
as_jarvis "cd '$REPO' && ~/.local/bin/pnpm exec playwright install chromium webkit >/dev/null && echo browsers ready"

say "5. retro-test helper"
mkdir -p /Users/jarvis/bin
cat > /Users/jarvis/bin/retro-test <<EOF
#!/bin/bash
# Run Rewind Arcade checks for the checkout in the current folder (agent worktrees reuse the main clone's packages).
set -e
export PATH="$NODEBIN:/Users/jarvis/.local/bin:/opt/homebrew/bin:\$PATH"
[ -d node_modules ] || ln -s $REPO/node_modules node_modules
case "\${1:-test}" in
  test) exec node --test tests/*.test.js ;;
  build) exec pnpm build ;;
  browser) shift || true; exec pnpm exec playwright test --project=webkit "\$@" ;;
  *) echo "usage: retro-test [test|build|browser]"; exit 2 ;;
esac
EOF
chmod 755 /Users/jarvis/bin/retro-test
chown -R jarvis:staff /Users/jarvis/bin
grep -q 'Users/jarvis/bin' /Users/jarvis/.zprofile 2>/dev/null || echo 'export PATH="/Users/jarvis/bin:$PATH"' >> /Users/jarvis/.zprofile

say "6. Unit tests and a build"
as_jarvis "cd '$REPO' && /Users/jarvis/bin/retro-test test 2>&1 | tail -8 && /Users/jarvis/bin/retro-test build 2>&1 | tail -3"
echo
echo "Done. Jarvis tasks on 'retro' can run retro-test (unit), retro-test build and retro-test browser."
