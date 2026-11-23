# Bridges to Brilliance — Self-Hosting Infrastructure Planning

*Context brief for continuing this conversation in another chat.*

---

## Background

Bridges to Brilliance currently runs on managed platforms:
- **App (BridgeMetric)** — built on Base44, handles client assessments, results, staff dashboard, validation flow. System of record for client data (assessment results, doctor's notes — HIPAA-adjacent).
- **Website** — Hostinger Website Builder.
- **AI features** — the app's AI Resume Builder and personalized recommendation generation call out to an LLM API (likely Claude/Anthropic) on a per-use basis.

The question under discussion: whether/how to move toward self-hosted infrastructure (own server, Mac mini, etc.) instead of paid managed subscriptions — specifically to reduce API costs on the AI-powered features inside the app.

## Stated priorities (from elicitation)

- **Driver:** all three — cost, data control/privacy, and capability (wanting local AI agents doing more).
- **Who maintains it:** solo right now, self-taught; plans to hire technical help as the org grows.
- **Timeframe:** next few months, actively exploring feasibility.
- **First target:** the AI-powered features inside the app specifically (Resume Builder / recommendations), not the whole app.
- **Hardware budget:** no fixed budget yet.

## Key distinction established

Two different layers, two different risk levels:
1. **The core app** (client records, auth, assessment logic, validation) — should **stay on Base44** for now. Self-hosting this means taking on full compliance/security/uptime responsibility solo, which is high risk given real client health-adjacent data.
2. **The AI-powered features inside it** (Resume Builder, recommendations) — these call an external LLM API per use, and are the layer that could realistically be swapped to a self-hosted/local model without touching the rest of the app (Base44 backend functions can call custom endpoints).

## Three infrastructure tiers considered

| Tier | Price | Use case | Uptime risk | Verdict |
|---|---|---|---|---|
| **Mac Mini Sandbox** | $600–$900 | Internal-only testing, no client data. M4 chip, 16–32GB RAM runs 7B–14B models. | High (home power/internet, no redundancy) | **Recommended first step** — lowest risk way to learn |
| **Cloud GPU VPS** | $0.30–$1.50/hr as used | Testing at closer-to-production scale; rented GPU (RTX 4090, A10 class) | Low (datacenter power/network) | Good next step if quality/volume justify it |
| **Owned GPU Server** | $2,000–$4,000+ | Real production inference at volume; PC/Mac Studio w/ RTX 4090+ | High unless colocated (needs UPS, backup internet) | Not yet — too much commitment before the need is validated |

## Recommended phased plan

1. **Pull real usage numbers** — from the Base44 usage/billing dashboard and/or the Anthropic Console (console.anthropic.com → Usage tab) to establish actual cost-per-call and volume for the AI features.
2. **Buy a Mac Mini, install Ollama**, run an open model (e.g. Llama 3.1 8B) against sample resume-builder-style prompts — using test data, not real client data — and compare output quality against current Claude output.
3. **Compare cost-per-call**: local (near-zero marginal cost) vs. API (real $ per call) at actual current volume. At low volume, the API is very likely still cheaper once hardware cost and personal time are factored in.
4. **Only if quality holds up and volume grows**, consider repointing the specific AI feature (not the whole app) to a self-hosted endpoint. Keep the core assessment/client-record app on Base44 throughout.

## Open items / next steps

- [ ] Get Base44 usage/billing export or screenshot
- [ ] Get Anthropic Console usage numbers (if applicable)
- [ ] Once numbers are in hand, run real cost comparison against the three tiers above
- [ ] Revisit self-hosting the core app only after hiring technical/compliance help

## Cautions raised (worth keeping in mind)

- A cheaper local model quietly underperforming on tone/nuance is a real risk for a neurodivergent client base's resume/recommendation output — don't trade quality for cost lightly.
- Self-hosting the actual client-data system of record significantly increases compliance/liability burden — hold off until there's dedicated technical/security capacity.
- A Mac Mini or home server is fine for internal/non-sensitive experimentation, not for anything client-facing in production (no redundant power/internet, no failover).
