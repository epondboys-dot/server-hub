# The Brain ("Jarvis"): hub agent plan (draft 0.2)

Draft started October 29, 2026; updated November 20, 2026. The Brain is named **Jarvis**, after the Mac mini it lives on (hostname `jarvis`, standard macOS user `jarvis`). Phase 0 (read-only daily briefing) and the Phase 1 Discord bot (`jarvis-bot/`) are built; everything after that is planning. Decisions marked **Open** need the owner (PondBoys).

## Where things stand (November 20, 2026)

- **Jarvis (new Mac mini, M5 Pro, 48 GB):** FileVault, firewall with stealth mode, Homebrew, Node 24.22.3, OrbStack, Tailscale (`100.92.13.90`, key expiry off), Ollama 0.40.16 with `qwen3:30b` and `nomic-embed-text`. Standard user `jarvis` created for the agent. SSH key `jarvis` (ed25519).
- **tradingserver (2014 Mac mini, Ubuntu 24.04.5):** on the owner's Tailscale account (`100.111.197.47`, key expiry off), keys-only SSH (Jarvis's key), ufw on. The Trading Desk has **not** moved; owner decisions 5 and 10 still govern that move.
- **Phase 1 bot** written (`jarvis-bot/`): read-only, owner-only, local model. Waiting on the owner to create the Discord application and token.

## How Jarvis talks to you (communication channels)

Rule for every channel: **Jarvis gets its own identity, never the owner's personal accounts.** Only the owner can give it commands; messages from anyone else are information, never instructions. Nothing is sent, deleted or paid without the owner saying yes. Each channel's login lives only on the `jarvis` macOS account, never in a repo.

| Order | Channel | How | Jarvis's own identity | First version |
| --- | --- | --- | --- | --- |
| 1 | **Discord** (main phone channel) | Bot in a private server; outbound connection only | Its own bot token | Built: `status`, `briefing`, questions to the local model, 07:30 morning post. Read-only |
| 2 | **Gmail / Google Drive** | Google sign-in on the `jarvis` account | A new Gmail just for Jarvis | Read what the owner forwards or shares; **draft** replies, never send on its own; only specific shared Drive folders |
| 3 | **iMessage** | Messages app signed in on the `jarvis` macOS account | A separate Apple Account for Jarvis | Alerts to the owner's phone and replies; last, because it needs deep macOS permissions |

## What the Brain is

One always-on agent that knows every project, watches every machine, hands work to the right project agent, and checks with you on your phone before anything risky. It lives on the new Mac mini in PA. Until that machine arrives, a read-only version can run on the Florida PC.

It is a manager, not a do-everything bot. The real work stays with the agents that already know each project (Codex, Claude Code, The Crease worker, the Trading Desk), and each project's own rules still apply.

## How it fits together

```
 You (Galaxy Fold, anywhere)
   |  chat, alerts, tap-to-approve
   v
 Phone channel: Discord (decided October 29)
   |
   v
 THE BRAIN (Mac mini, 24/7)
   - project registry (projects.json)
   - decisions + handoff log
   - permission rules (below)
   - reasoning: Claude API; cheap chores: local Ollama model
   |
   +--> Project agents:  Codex / Claude Code sessions per repo
   +--> Machine checks:  PA PC, 2014 Mac mini, Florida PC (over Tailscale)
   +--> Room sensors:    temperature, humidity, leak
   +--> Trading Desk:    READ-ONLY status, never trades
   +--> The Crease:      job queue status, review requests
   +--> Bridges helper:  sample data only, never client records
```

## What it does, by phase

| Phase | Where it runs | What it can do | Permission level |
| --- | --- | --- | --- |
| 0. Briefings | Florida PC, now | Read each repo's git status, HANDOFF / BUILD_STATUS / CODEX_NEXT files and logs; write a daily briefing of what changed, what's blocked, what's next | Read only |
| 1. Phone channel | Florida PC, then Mac mini | Send the briefing and alerts to your phone; answer questions about any project | Read only |
| 2. Dispatch | Mac mini | Start a project agent on a task you approve, track it, report the result | Approve to start |
| 3. Machine care | Mac mini | Health checks, disk space, backups, restarts of approved services, sensor alerts | Auto for checks; approve for restarts |
| 4. Business assistants | Mac mini | Bridges helper, content engine scheduling, admin chores | Per assistant |

Phase 0 needs no new hardware, so it can start now and become the base for everything after.

## Permission tiers

| Tier | Examples | Rule |
| --- | --- | --- |
| Read | git status, logs, briefings, sensor readings | Automatic |
| Safe actions | Run tests, write notes and briefings, open a draft branch | Automatic, reported afterward |
| Shared changes | Merge or push code, restart a service, change a schedule | Tap-to-approve on the phone |
| High stakes | Publish content, deploy anything public, spend money, delete data | Tap-to-approve plus a written summary first |
| Never | Place trades, clear a Trading Desk hard-off, expose the desk beyond `tailscale serve`, touch Bridges client records, read or move credentials | Blocked in code, not just in instructions |

## Rules the Brain inherits from existing projects

- **Trading Desk** (`ai-daytrading-bot/AGENTS.md`, `docs/OWNER_DECISIONS.md`): simulation only, no funded account, no order paths, loopback plus `tailscale serve` only, never reset the owner runtime or clear `HARD_OFF.json`. The Brain may read status and relay alerts; nothing more.
- **Retro Game Platform** (`AGENTS.md`, `BUILD_PLAN.md`): one milestone at a time; public deployment and payments need your explicit authorization.
- **The Crease**: already human-in-the-loop, with Discord used for mobile review and a restricted `crease-mcp` server. The Brain should use that server rather than reach into the database.
- **Bridges**: live app and client records stay on Base44; the Brain works only on local copies with sample data.
- **All repos**: several agents share them. `git pull --ff-only` before work, never overwrite someone else's uncommitted changes, leave a handoff note.

## Security notes found while planning

- `ai-daytrading-bot` has plaintext key files in the working folder (`etrade APIkey.txt`, `owner passkey update code.txt`). They should move into a password manager or the OS keychain before any agent, including the Brain, gets broad file access on this machine. The owner decision to rotate keys before real money still stands.
- The Brain gets its own accounts and tokens with the smallest access that works, never your personal logins.
- **Network fences (updated November 2026, lean plan):** the separate Verizon line was cut. The hub sits behind its own UniFi Cloud Gateway Ultra on the Xfinity line (double NAT, no open ports, Tailscale for remote access), with firewall rules keeping the hub and Trading Desk networks away from the family network. The text below is the original October 30 Plan AA, kept for reference.
- **Network fences (Plan AA, October 30, superseded):** the Brain lives on the hub's own internet line (Verizon 5G Home), never the family's Xfinity line. Its segment reaches only approved sites; Tailscale rules let it read the Trading Desk's status page and nothing else in that segment. The Bridges assistant and each business entity's assistant run as separate macOS users with their own containers and tokens. Full details: the Security segment in `AI-Server-Dev-Hub-Plan.md`.

## Project registry (first pass)

See `projects.json`. Each entry: repo, machine and folder, the rules file agents must read, the status file the Brain reads for briefings, and what the Brain may do there.

## Open decisions

1. **Brain model and budget:** decide when building the desk (Phase 2). Phase 0 uses no AI calls; the Phase 1 bot uses only the local Ollama model on Jarvis (no paid API).
2. **Which agents it dispatches to:** Codex, Claude Code, or both.
3. **Name:** decided November 20: **Jarvis**.
4. **Knee project:** include it in the registry or leave it out.

## Phase 0: built October 29, 2026

- `brain/briefing.js` (Node.js, no extra packages) reads `projects.json`, checks each project's Git state and status files, flags credential-looking files by name only, and writes `briefings/YYYY-MM-DD.md` plus `briefings/latest.md`.
- Strictly read-only: Git runs with `--no-optional-locks` and only read commands; it never writes inside a project folder or opens a credential file.
- Uncommitted counts ignore line-ending-only differences, so the same repo reads the same on Windows and Linux.
- **Run it:** double-click `Run-Briefing.cmd`. **Every morning at 7:30:** run `Schedule-Daily-Briefing.cmd` once.
- **Discord (start of Phase 1):** create a webhook in a private Discord channel (channel settings, Integrations, Webhooks), then in a terminal run `setx BRIEFING_DISCORD_WEBHOOK "<the webhook URL>"`. The "Needs you" summary then posts there each run. Keep the URL out of every repo: anyone with it can post to that channel.
