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
   (Settings > Deploy keys, leave "Allow write access" unchecked), then `sudo bash setup-bridges.sh clone <org>/<repo>`.
4. Discord: "what's in the bridges app?", "plan bridges ...". Agents work on branches in copies and cannot push.

Rules agents get for this project: code only, never run against the live Base44 backend, made-up sample data only, no new
tracking or data collection, scoring kept separate from AI explanations, plain calm wording for neurodivergent users.
