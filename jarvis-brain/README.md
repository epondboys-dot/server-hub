# Jarvis daily project briefing

Installed November 23, 2026. Every morning at 07:25 Jarvis (as the standard user `jarvis`):

1. Fetches the read-only clones in `/Users/jarvis/projects` (ai-daytrading-bot, retro-game-platform, the-crease) and fast-forwards any without local edits. The GitHub token is read-only; nothing is ever pushed.
2. Writes `/Users/jarvis/hub/briefings/latest.md` (plus a dated copy): Git state, open handoffs, latest build status and a "Needs you" list.
3. The Discord bot posts the "Needs you" list in its 07:30 morning post, and answers `briefing` any time.

Nothing here runs project code. The Trading Desk is only read, never started.

## Install (admin account `epondboys`)

From the PA PC (PowerShell):

    scp -r G:\AI-Projects\server-hub\jarvis-brain epondboys@10.10.10.240:~/

On Jarvis:

    sudo bash ~/jarvis-brain/install.sh

## One-time: let the 07:25 refresh sign in to GitHub

The keychain is locked when nobody is logged in as jarvis. Log in to the jarvis account once and run:

    bash /opt/jarvis-brain/unattended-git-signin.sh

Until then, the briefing still runs but says it "could not refresh from GitHub".

## Files

- `briefing.js`: the Phase 0 briefing script; reads `BRIEFING_REGISTRY` and `BRIEFING_OUT_DIR` from the environment.
- `projects.jarvis.json`: which projects Jarvis reports on and where they are.
- `refresh-and-brief.sh`: fetch + briefing, run by launchd as jarvis.
- `unattended-git-signin.sh`: copies the read-only token from jarvis's keychain to `~/.git-credentials` (mode 600) for unattended runs.
- Logs: `/Users/jarvis/hub/briefings/refresh.log` and `run.log`.

The GitHub token expires after 90 days (around February 21, 2027). Make a new read-only one in the jarvis account and rerun the sign-in script.
