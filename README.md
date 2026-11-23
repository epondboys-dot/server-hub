# Server hub

Planning and, later, code for the PA server hub and the Brain (the hub agent).

- `AI-Server-Dev-Hub-Plan.md`: hardware, device roles, costs and setup order. Saved copy of the live doc at https://claude.ai/code/artifact/1fc1d497-c6f6-4c20-8821-c479ee3c28c0, which stays the source of truth.
- `BRAIN_PLAN.md`: what the Brain does, how it's built, permission rules, phases.
- `projects.json`: the project registry the Brain reads.
- `brain/briefing.js`, `Run-Briefing.cmd`, `Schedule-Daily-Briefing.cmd`: Phase 0 daily briefing (read-only).
- `briefings/`: generated briefings; `latest.md` is the newest.
- `jarvis-bot/`: Phase 1 Discord bot for Jarvis (read-only, owner-only, local model). Installs on the Mac mini `jarvis`; see its README.
- `setup/`: machine setup scripts (2014 Mac mini Trading Desk host).
- `reference/`: earlier planning briefs.
