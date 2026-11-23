#!/bin/bash
# The Crease: development and tests on Jarvis (no keys, no cloud). Owner, November 23, 2026.
# Run from the admin account:  sudo bash ~/jarvis-crease/setup-crease-dev.sh   (safe to rerun)
#  1. Python 3.12 and FFmpeg (Homebrew, installed as the admin user)
#  2. jarvis's read-only clone switched to the working branch codex/atomic-render-queue
#  3. a Python 3.12 virtual environment with the dev extras, owned by jarvis
#  4. ~jarvis/bin/crease-test: runs pytest/ruff/mypy for whatever checkout it is run in (agent worktrees too)
#  5. one full test run
set -euo pipefail
ADMIN="${SUDO_USER:-epondboys}"
REPO=/Users/jarvis/projects/the-crease
BRANCH=codex/atomic-render-queue
BREW=/opt/homebrew/bin/brew

say() { printf '\n=== %s\n' "$*"; }
die() { printf '\nSTOP: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "Run with sudo:  sudo bash $0"
[ -d "$REPO/.git" ] || die "No clone at $REPO"
as_jarvis() { sudo -u jarvis -H bash -lc "$1"; }

say "1. Python 3.12 and FFmpeg"
sudo -u "$ADMIN" -H "$BREW" install python@3.12 ffmpeg
PY=/opt/homebrew/opt/python@3.12/bin/python3.12
[ -x "$PY" ] || die "python3.12 not found at $PY"
/opt/homebrew/bin/ffprobe -version | head -1

say "2. Clone on $BRANCH"
as_jarvis "cd '$REPO' && git fetch --quiet origin && (git switch '$BRANCH' 2>/dev/null || git switch -c '$BRANCH' --track 'origin/$BRANCH') && git merge --ff-only --quiet '@{u}' && git log --oneline -1"

say "3. Virtual environment (jarvis)"
as_jarvis "cd '$REPO' && [ -x .venv/bin/python ] || '$PY' -m venv .venv; .venv/bin/python -m pip install --quiet --upgrade pip && .venv/bin/python -m pip install --quiet -e '.[dev,vision]'"

say "4. crease-test helper"
mkdir -p /Users/jarvis/bin
cat > /Users/jarvis/bin/crease-test <<'EOF'
#!/bin/bash
# Run The Crease checks for the checkout in the current folder, with the shared virtual environment.
# PYTHONPATH=src makes an agent worktree test its own code, not the main clone's.
set -e
VENV=/Users/jarvis/projects/the-crease/.venv
export PATH="/opt/homebrew/bin:$PATH" PYTHONPATH="$PWD/src"
case "${1:-test}" in
  test) shift || true; exec "$VENV/bin/python" -m pytest -q "$@" ;;
  lint) exec "$VENV/bin/python" -m ruff check . ;;
  types) exec "$VENV/bin/python" -m mypy src ;;
  *) echo "usage: crease-test [test|lint|types] [pytest args]"; exit 2 ;;
esac
EOF
chmod 755 /Users/jarvis/bin/crease-test
chown -R jarvis:staff /Users/jarvis/bin
grep -q 'Users/jarvis/bin' /Users/jarvis/.zprofile 2>/dev/null || echo 'export PATH="/Users/jarvis/bin:$PATH"' >> /Users/jarvis/.zprofile
chown jarvis:staff /Users/jarvis/.zprofile

say "5. Full test run (a few minutes)"
as_jarvis "cd '$REPO' && /Users/jarvis/bin/crease-test test 2>&1 | tail -5"
echo
echo "Done. Jarvis tasks on 'crease' can now run its tests with crease-test."
