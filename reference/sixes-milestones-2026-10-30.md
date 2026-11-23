# Sixes Lacrosse: milestones to a paid launch (as of October 30, 2026)

Provided by the owner (PondBoys) on October 30, 2026. Estimates, not measurements.

**Stated v1 scope:** Play/Exhibition plus Franchise, Ultimate Team and My Player; online multiplayer required; men's and women's; team control with player switching. Street/Box mode is deferred to after launch.
**Team:** solo developer with AI coding agents (Codex and Claude). Unreal Engine 5.8. 129 automated tests, all passing.

| # | Milestone | Share of total work (est.) | Done (est.) | Status |
|---|---|---|---|---|
| M0 | Workflow reset and plan | 1% | 100% | Done |
| M1 | Exhibition setup (pick teams, server spawns 12 players, start/restart, minimal match screen) | 3% | 100% | Done (Oct 23) |
| M2 | Playable possession loop (draw, live play, pass, shoot, score, saves, restarts, result, shot-clock rules, AI both ways, both disciplines) | 10% | ~75% | Works in automated full matches; still off in the normal menu. Open: out-of-bounds, stoppages, end of a missed shot's flight, real-controller test, turning it on |
| M3 | Online play (2+ real clients, prediction/smoothing, lobby, matchmaking, disconnect handling) | 14% | ~10% | All new code is server-controlled, but nothing tested over a real network yet |
| - | Online services (accounts, hosted servers, ranked, live-service backend) | 4% | 0% | Not started |
| M4 | Presentation and feel: animation, real player/stick/arena art, camera, audio/commentary, broadcast presentation, controller tuning | 25% | ~10% | Early: animation plans, film study, handedness spec; placeholder art |
| - | Gameplay depth: full rules (penalties, crease, stoppages), AI tactics and difficulty, ratings and balance | 8% | ~25% | Shot-clock rules and field dimensions done; prototype AI; placeholder tuning |
| - | Menus and front end: settings, save data, tutorial, accessibility | 5% | ~5% | Minimal match screen only |
| - | Content: teams, rosters, uniforms; real-player licensing decision | 4% | ~15% | Roster data and ratings exist; licensing undecided |
| M5a | Franchise/Dynasty mode | 6% | ~5% | Ratings/aging partly designed |
| M5b | Ultimate Team (card economy, online, rewards) | 8% | 0% | Not started |
| M5c | My Player/Career | 5% | 0% | Not started |
| - | Release: packaging, QA, performance, crash reporting, anti-cheat, age rating, Steam store page, legal, pricing | 7% | ~3% | Build and test automation exists; no store work yet |

**Weighted total: about 18% done** (likely range 12% to 22%). Cut to Exhibition plus online (modes after launch): about 22% to 23% of the smaller launch.

**Biggest unknowns:** art and animation sourcing (buy or license versus build), online infrastructure cost and complexity, whether Ultimate Team stays in v1, real-player licensing.
