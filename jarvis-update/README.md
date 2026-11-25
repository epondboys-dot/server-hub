# Self-updates

| What | How it updates | When |
|---|---|---|
| Jarvis bot, knowledge job, this updater | root updater installs newest `server-hub` main, waits 45 s, rolls back if the bot didn't stay up; a commit that failed is skipped until a newer one arrives | `update` in Discord, nightly 03:15 when idle; 04:20 fallback restarts Jarvis if he's down |
| X3 bot | newest `x3-discord-admin-ai` main, packages refreshed, tests must pass, then restart | with every hub update |
| Claude Code, Codex, Ollama, Node 24 (Jarvis) | Homebrew upgrade as the admin account | `update tools`, nightly when idle |
| PA PC worker | the PC fetches `pa-pc-worker/jarvis-worker.ps1` from GitHub itself (Jarvis only asks), syntax check, old copy kept as `.prev` | after each Jarvis update, nightly |
| PA PC Claude Code / Codex | `claude update`, `npm i -g @openai/codex@latest` | nightly, `update everything` |
| Trading desk (tradingserver) | bundle of `ai-daytrading-bot` main, fast-forward only; refuses on hard-off or local edits; rolls back if the service doesn't stay up | only `update desk` + `confirm update desk` |
| Agent repos (retro, crease, trading, x3 copies) | fast-forwarded before every plan | always |

Not automatic (on purpose): macOS/Windows/Ubuntu system updates, Ollama models, the desk's forced-command script, the PA PC worker's SSH key setup.

Trust: code only comes from GitHub `main`. Anyone who can push to `server-hub` main can change what runs as root on Jarvis, so keep that repo's write access to the owner. Jarvis's own agents can't push (read-only token).

Files: `/usr/local/libexec/pondboys/hub-update.sh`, log `/Library/Logs/hub-update.log`, result `/usr/local/var/pondboys/update-result.txt`, requests `/Users/jarvis/hub/update/queue/`.
If an update fails, say `fix the hub update` in Discord: an agent reads the logs and plans a fix on `server-hub` (lands after you push it).
