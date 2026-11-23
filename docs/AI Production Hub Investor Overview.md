# AI Production Hub: Investor Overview

Oct 30, 2026 · @PondBoys

A small, owned AI and computing hub will let one founder build and run a portfolio of digital products with AI agents, at a fixed and predictable cost, while the price of renting computing and AI keeps climbing. About $5,300 of hardware and security, plus about $370 a month to run, supports five projects: a lacrosse video game, an indie browser-game platform, a lacrosse highlight content engine, an AI trading research desk, and Bridges to Brilliance, a nonprofit career-exploration assessment. The founder stays in control through phone approvals, and every agent works inside fenced-off networks with strict limits.

**Status, October 30, 2026:** the plan is complete and costed; the hub hardware has not been bought yet. The first stage of the AI manager (a daily project briefing) already runs on the founder's current PC.

## Why now: computing and AI are getting more expensive

AI data centers are buying up the world's memory, storage and chips, and the cost is reaching everyone who rents computing or buys hardware.

- **Memory and storage:** TrendForce forecast [contract DRAM prices up 58% to 63% and NAND flash up 70% to 75% in a single quarter](https://www.trendforce.com/presscenter/news/20260331-12995.html) (Q2 2026), as suppliers shift capacity to AI servers. A basket of twelve consumer RAM kits tracked by ComputerBase cost [311% more in July 2026 than in September 2025](https://www.pcgameshardware.de/SSD-Hardware-255552/Specials/SSD-Preise-2026-Preis-pro-Terabyte-Kaufberatung-1553743/).
- **Rented cloud computing:** AWS raised prices on its [GPU capacity blocks by about 15% on January 4, 2026](https://www.webpronews.com/aws-hikes-gpu-ec2-prices-15-for-ai-workloads-amid-shortages/), citing AI-driven demand.
- **Hardware:** Apple raised [Mac and iPad prices by $100 to $500 on June 25, 2026](https://www.tomshardware.com/laptops/macbooks/ram-crisis-bites-apple-as-unprecedented-mac-and-ipad-price-rises-arrive-cheapest-macbook-pro-price-hiked-by-usd400-to-usd1-999), saying it had never seen component costs rise this fast and this high.
- **AI tools:** heavy-use plans now run [$100 to $200 a month](https://chudi.dev/blog/claude-pro-vs-max), and usage limits on cheaper plans cap how much work an AI agent can do in a day.

**What the hub changes:** owned hardware turns a rising, usage-based bill into a fixed one. Routine AI work (summaries, monitoring, testing, first drafts) will run on local models at near-zero cost per use, with paid AI services reserved for the work that needs them. Buying now locks in capacity before further increases; if prices fall instead, the cost is having paid somewhat more for hardware than a later buyer would.

## What it is and how it works

The hub is planned as a small set of machines in a sensor-monitored basement room in West Chester, Pennsylvania, run by an AI manager ("the brain") that the founder directs from a phone or a remote workstation in Florida.

| Part | Role |
| --- | --- |
| New Mac mini (M5 Pro) | Runs the brain, local AI models and the Bridges development copy around the clock |
| Upgraded Windows PC (20-core CPU, 64 GB RAM) | Builds and tests the video game; renders highlight videos |
| Dedicated Linux machine | Runs the AI Trading Desk in complete isolation; the only machine allowed to handle real money |
| Cloud services (Cloudflare, Supabase, Google Cloud) | Serve anything public, so customers never touch the home network |
| Founder's phone and Florida workstation | Approvals, alerts and hands-on creative work |

**The brain is a manager, not a do-everything bot.** It knows every project, writes a daily briefing of what changed and what's blocked, hands coding tasks to specialist AI agents, watches machine health and room sensors, and reports through Discord. It is being built in stages; the first stage, the daily briefing, already works on the founder's current PC.

**The founder stays in charge.** Reading and testing are automatic. Merging code, restarting services and changing schedules need a tap of approval on the phone. Publishing, public deployments, spending and deleting data need approval plus a written summary first. Some actions, like touching financial accounts or reading passwords, will be blocked in code entirely.

**Security is designed in from the start.** The hub gets its own internet line, separate from the household's. Each sensitive job sits on its own walled-off network, AI agents can reach only approved websites, no agent can read stored credentials, and the founder can cut the hub's internet from the phone.

## What it powers

Five projects share the hub. The four software projects are built by the founder with AI coding agents, using automated test suites and written handoffs between agents; Bridges to Brilliance is a nonprofit with four founders. Percentages and dates are estimates as of October 30, 2026.

| Product | What it is | Done | Estimated launch | How it earns |
| --- | --- | --- | --- | --- |
| The Crease | Lacrosse highlight content engine: turns raw game footage into finished highlight clips, reviewed on a phone and published to social platforms | About 80%; 542 automated tests passing | Mid-December 2026 to January 2027 | To be set by the founder |
| Rewind Arcade | Indie browser-game platform: players walk a retro "neighborhood store" and play games in the browser; creators upload games that are reviewed and published | About 55%; private test site live with accounts and the full creator workflow built | Summer 2027 | Subscriptions (planned milestone M6) |
| Sixes Lacrosse | Lacrosse video game in Unreal Engine 5, men's and women's, with online multiplayer planned | About 18% of full scope (22% of a trimmed first release); 129 automated tests passing | Late 2027 to late 2028 for a first release; later for all modes | Paid game on Steam |
| AI Trading Desk | AI-assisted trading research desk: tests strategies across crypto and stock markets with realistic costs, then runs paper trials. Paper trading only; live trading is locked in the software | About 85% to paper-trading complete; about 50% to real-money ready | Paper-complete January to February 2027; real money not before spring 2027, only by the founder's decision and only if a strategy shows an edge | Trading returns on the founder's own account, if a strategy proves out. So far no tested strategy beats simply holding a diversified ETF basket; the strategies' strength is losing less in crashes |
| Bridges to Brilliance | Nonprofit (501(c)(3), Pennsylvania) assessment that helps people, particularly neurodiverse people, explore employment interests, comfortable work environments and support needs, with AI-written explanations and recommendations | Live: website and assessment app running, first test groups starting | Already live; marketing to follow | Free assessment by design, leading to paid services the organization is building. As a nonprofit it is funded by donations, grants and program revenue, not investment |

**How the work is split:** the hub runs the heavy and always-on jobs: game builds and test matches, the video render worker, automated testing across browsers and devices, and the brain. Public services run in the cloud.

**How the hub serves the Trading Desk and Bridges:** the Trading Desk gets its own isolated machine and network, reachable by the brain only to read status. Bridges keeps its live app and client records on its hosted platform; the hub runs a development copy with sample data only, plus the AI features, with the long-term goal of retiring Bridges' hosting subscriptions once the hub can safely host the website, app and a Bridges assistant itself.

## Economics

The hub costs about $5,300 up front and about $4,415 to run in its first year, roughly $370 a month, covering all five projects. Figures include Pennsylvania's 6% sales tax and West Chester electricity rates.

**One-time:**

| Item | Cost (USD) |
| --- | --- |
| Hub hardware: new Mac mini, PC upgrades, storage, backup drive, battery backup, sensors, network, monitors | About 4,870 |
| Security: firewall router, network switch upgrade, two hardware security keys, a door lock for the hub room | About 370 to 465 |
| **Total** | **About 5,240 to 5,335** |

**Year one, middle estimate:**

| Category | Per year (USD) | What's in it |
| --- | --- | --- |
| Infrastructure | 1,085 | Electricity for all machines running 24/7 (about 1,160 kWh), off-site backup, the hub's own internet line, security tools, hardware reserve |
| AI | 630 | The founder's current AI subscriptions ($40 a month) and a capped budget for the brain's AI model |
| Product cloud services | 790 | Supabase databases, Cloudflare, video rendering and publishing services |
| Operations | 1,910 | A planned dedicated control-phone line, and travel between the founder's Florida base and the Pennsylvania hub |
| **Total** | **4,415** | Range 2,060 to 8,820 |

- **Electricity is small:** all machines together average about 130 watts, about $230 a year at 18 to 22 cents per kWh.
- **The biggest variable is travel,** not computing. Local technicians handle emergencies so trips can be planned.
- **AI spending is deliberately capped.** The founder currently spends $40 a month on AI subscriptions; upgrading one plan (about $960 more a year) could pull the two larger launches forward by a few months.
- **Not included:** the control phone itself (about $1,640), art and animation assets for the game, and legal and company-formation costs for the platform.

## Risks and how they're handled

| Risk | How it's handled |
| --- | --- |
| Solo founder: progress depends on one person | AI agents share the build work and leave written handoffs; the software projects live on GitHub with automated tests, so work can be picked up by others |
| Home-hosted hardware can fail or lose power | Planned: battery backup, a second internet line, auto-restart after outages, temperature, humidity and leak alerts, versioned off-site backups, local technicians on call; anything public runs in the cloud |
| AI agents acting beyond their remit | Approval tiers enforced on the phone, actions blocked in code, walled-off networks, approved-sites-only internet, no readable credentials |
| Launch estimates slip | Estimates are ranges and shared openly; the game's scope can be trimmed to a smaller first release with modes added later |
| Hardware prices keep rising | Buying now locks in current prices; the plan reuses existing machines wherever they're good enough |
| Platform legal readiness | Name clearance, company formation, lawyer-finished terms and a registered copyright agent are required before the platform's pilot |
| Game art and animation are a large unknown | About a quarter of the game's remaining work; buying or licensing assets is being weighed against building them |
| Trading losses | Paper trading only until the founder decides otherwise; live trading locked in software; risk limits, a stop latch and an emergency off switch; keys rotated and the old bot retired before any real money; real money only on its own isolated machine |
| Sensitive client data at Bridges | Client records stay on Bridges' hosted platform; the hub works only with sample data; assessment scoring is kept separate from AI explanations; self-hosting waits until there is technical and security help |

## What investment would accelerate

The hub is sized to the founder's own hardware budget of about $5,000. Outside capital would mainly buy speed. The specific ask and terms are set by the founder.

| Use of funds | What it changes | Approximate cost (USD) |
| --- | --- | --- |
| Higher-tier AI plans | Raises the usage limits on the AI agents; pulls the platform and game launches forward by a few months | About 960 to 1,920 a year |
| Game art and animation | Buys or licenses the largest remaining piece of the game, about a quarter of its work | To be scoped |
| Platform legal and company formation | Clears the platform's path to its invite-only pilot and public launch | To be scoped with counsel |
| Production databases and hosting | Backups and always-on service for the platform and content engine | About 500 a year |
| Contract help (QA, art, online infrastructure) | Adds people where AI agents are weakest | To be scoped |

## Sources

- [TrendForce: 2Q26 DRAM and NAND contract price forecast](https://www.trendforce.com/presscenter/news/20260331-12995.html)
- [PC Games Hardware: SSD and RAM prices 2026 (ComputerBase basket figure)](https://www.pcgameshardware.de/SSD-Hardware-255552/Specials/SSD-Preise-2026-Preis-pro-Terabyte-Kaufberatung-1553743/)
- [WebProNews: AWS raises GPU EC2 prices about 15%](https://www.webpronews.com/aws-hikes-gpu-ec2-prices-15-for-ai-workloads-amid-shortages/)
- [Tom's Hardware: Apple raises Mac and iPad prices](https://www.tomshardware.com/laptops/macbooks/ram-crisis-bites-apple-as-unprecedented-mac-and-ipad-price-rises-arrive-cheapest-macbook-pro-price-hiked-by-usd400-to-usd1-999)
- [chudi.dev: Claude Pro vs Max pricing](https://chudi.dev/blog/claude-pro-vs-max)
- [ElectricityRates.com: PECO June 2026 rate](https://electricityrates.com/resources/peco-june-2026-rate-increase/)
- Hardware, running-cost and timeline figures: the founder's AI Server & Dev Hub Plan, October 30, 2026
