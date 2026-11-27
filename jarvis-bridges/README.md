# Bridges to Brilliance on Jarvis (development copy, code only)

Plan ("Bridges guardrails" in the hub plan, Nov 23): the live BridgeMetric app and every client record stay on Base44 (and the
site on Hostinger) until Bridges has technical and security help. Jarvis holds the code only, in a GitHub repo the nonprofit
controls, for AI coding work, review and sample-data testing.

1. Nonprofit GitHub: sign in to GitHub as the Bridges account (bridges.to.brilliance01@gmail.com), create a free
   organization for Bridges, and invite your own GitHub account as a member. Bridges owns it; people can come and go.
2. Base44 (app owner, Builder plan or higher): open the app, Code tab, GitHub, connect, pick the Bridges organization.
   Base44 creates a private repo with the app's code. No client data or secrets are exported.
   Base44 keeps GitHub main and the live app in sync both ways: anything merged to main goes live.
3. On Jarvis: `sudo bash setup-bridges.sh key`, add the printed key to the repo as a read-only deploy key
   (Settings > Deploy keys, tick "Allow write access"; first enable deploy keys in the org: Settings > Member privileges > Deploy keys), then `sudo bash setup-bridges.sh clone <org>/<repo>`.
4. Discord: "what's in the bridges app?", "plan bridges ...". Agents work on branches in copies and cannot push.

Rules agents get for this project: code only, never run against the live Base44 backend, made-up sample data only, no new
tracking or data collection, scoring kept separate from AI explanations, plain calm wording for neurodivergent users.

## Founders' remote access (when they need it)

The four founders work on the code through the nonprofit's GitHub organization from their own computers; that needs
nothing on Jarvis. If a founder also needs to work *on Jarvis* (for example to use the local AI for Bridges tests):

1. Tailscale: apply `jarvis-ollama/tailscale-policy.hujson` (owner-only servers and desk page; already safe to apply now),
   then add the founder's Tailscale login to `group:bridges` and invite them to the tailnet.
2. On Jarvis: `sudo bash add-founder.sh <name> "<Full Name>"`. It makes every home folder private, creates a standard
   account `btb-<name>` in the `bridges` group with its own copy of the Bridges code, and allows SSH only for the admin
   and that group. Founders never see Jarvis's other projects, the trading desk, settings files or keys.
3. They connect with `ssh btb-<name>@jarvis` over Tailscale and push with their own GitHub accounts.

Still owner-only: Jarvis in Discord (agents, desk, updates). A Bridges-only Discord channel for founders can come later.

## How agent work reaches the app (Nov 27)

Agent finishes a Bridges task -> Jarvis pushes it to branch `jarvis/T<n>` on the nonprofit repo and posts a review link ->
a founder reviews and merges on GitHub -> Base44 syncs main into the live app. Jarvis never pushes main: his code only
pushes jarvis/T<n>, and a root-owned pre-push hook in the clone refuses anything else. Apply for GitHub for Nonprofits
(free Team plan for verified 501(c)(3)s) to also lock main on GitHub itself (required review before merge).
