# AI Server & Dev Hub Plan

Oct 14, 2026 · @PondBoys

## Summary

**The theme:** PA is the hosting, build and server site, with a dev desk for when you're there. Florida is your main remote-in workstation, strong enough to work locally, and upgraded over time with parts freed by this plan.

The whole setup lands at about $4,870 including PA's 6% sales or use tax: a new Mac mini for AI and Bridges work, upgrades to the existing PC for game builds, and reused older devices for everything else.

- **Two main machines.** A new Mac mini (M5 Pro, 48 GB) runs local AI and Bridges development. The existing PC (i5-12400F, B660 board) gets more RAM, a 20-core CPU and more storage for UE5 builds.
- **Free jobs for old devices.** The 2014 Mac mini is the Trading Desk's home on Linux, and the only machine for any real-money testing. The MacBook Air, iPad and Surface take supporting roles.
- **Public services go to the cloud later.** The mini-games platform and multiplayer servers run on a cheap cloud server once they launch, keeping strangers off the home network.
- **Bridges' live app stays hosted.** Client records stay on Base44 until there is technical and security help. The Mac mini runs the local copy and testing.
- **The basement is mostly a remote station.** Two monitors now, a third later. No AC or dehumidifier unless the new sensors say otherwise.

## Device roles

Each machine gets one clear job, so a problem on one can't reach the others. The Trading Desk gets its own physical box, the 2014 Mac mini, because it holds broker keys.

| Device | OS | Job | Runs 24/7 |
| --- | --- | --- | --- |
| Florida PC (Ryzen 5 3600, GTX 1660 Super) | Windows | Main remote workstation: hands-on UE5 editor work, and remote access into the PA machines over Tailscale with no ports open to the internet | No |
| New Mac mini (M5 Pro, 48 GB) | macOS | Local AI models, Bridges local copy and testing, AI coding, business assistant, content engine | Yes |
| PA PC (upgraded) | Windows 11 | UE5 builds and packaging, game source control, Docker projects; dev desk with the RTX 3050 when you're there; mostly reached remotely from Florida | Yes |
| 2014 Mac mini | Linux (wiped) | Trading Desk's home: paper trials, and the only machine for any real-money testing; nothing open to the internet | Yes |
| Cloud server (later) | Linux | Mini-games platform and multiplayer servers once public | Yes |
| 2015 MacBook Air | macOS | Dev and testing laptop | No |
| 2020 iPad | iPadOS | Assessment station and staff dashboard | No |
| Original Surface Pro | Windows | Admin, remote access and recovery testing | No |
| Old iPads | iOS | Retire, or offline reference screens | No |

The 2014 Mac mini no longer gets macOS security updates, which is why it gets Linux before it holds any keys. The Surface stays off 24/7 duty because Surfaces left plugged in constantly are known for swollen batteries.

## Future Phone: mobile command center

A Galaxy Z Fold becomes the remote control you carry everywhere. The boss agent that manages the hub runs on the new Mac mini; the phone is where you talk to it, see alerts and approve what it does.

**How the agents stack:**

- **Hub agent, on the Mac mini, running 24/7.** Directs the other agents (builds, Bridges, content engine, monitoring) and watches the PA machines.
- **The phone, with you.** Chat with the hub agent, get alerts, tap to approve risky actions, and remote into any machine over Tailscale.
- **Why the agent doesn't live on the phone.** Phones sleep, lose signal, run out of battery and get lost. If the phone ran everything, losing it would take control and keys with it.

**Guardrails:**

- Trades, deletions, publishing and spending need a tap-to-approve on the phone.
- No broker keys or server passwords stored on the phone.
- Strong lock with biometrics, Tailscale device approval, and Samsung Find set up for remote wipe.

**Phone prices:**

| Model | Price (USD) | With 6% PA tax | Financed 36 months on Verizon |
| --- | --- | --- | --- |
| [Galaxy Z Fold 8, wide, 256 GB](https://www.sammobile.com/news/galaxy-z-fold-8-usa-prices-official-here-is-what-you-will-pay/) | 1,899 | 2,013 | about 56 a month |
| [Galaxy Z Fold 8 Ultra, 256 GB](https://www.sammobile.com/news/samsung-galaxy-z-fold-8-ultra-prices/) | 2,099 | 2,225 | about 62 a month |

**Current deal:** Best Buy had the [Galaxy Z Fold 8 at $1,549.99](https://idevice.com/versus/galaxy-z-fold8-vs-pixel-11-pro-fold) on October 11, about $1,640 with tax. Buy it unlocked and bring it to Verizon as the new line. Alternatives at full price: the [Pixel 11 Pro Fold at $1,899 and the iPhone Duo at $1,999](https://www.bloomberglinea.com/estilo-de-vida/iphone-duo-galaxy-z-fold-8-y-pixel-fold-cual-tiene-menor-precio-en-2026/).

**Service options:**

**Decided:** a dedicated second phone, separate from your personal phone. The recommended setup is a new line on your existing Verizon family plan at the Plus tier, for 5G Ultra Wideband and hotspot backup, at the cheapest monthly cost of the options below.

| Option | Per month (USD) | Notes |
| --- | --- | --- |
| Add a line to your Verizon family plan (5+ lines) | [about 30 to 55](https://www.upphone.com/cell-phone-plans/verizon/verizon-unlimited-ultimate/5-lines/) | Cheapest; Welcome tier at the low end, Ultimate at the high end. One-time activation fee, about 35 to 45 est. |
| New single-line Verizon plan | [55 to 85](https://www.droid-life.com/2026/05/08/verizons-best-unlimited-plan/) | Welcome 55, Plus 70, Ultimate 85 |
| Put it on your current line | 0 extra | Not used: the Fold is a dedicated second phone |

Pick Plus or Ultimate if you want hotspot data, which doubles as backup internet for a laptop while traveling; Welcome has none. Taxes and fees come on top of every plan price.

**Budget effect:** the phone sits outside the $5K core. Paid outright it brings the upfront total to about $6,900 to $7,100. Financed, the upfront total stays about $4,870 and the phone adds about $86 to $117 a month (line plus device payment) on the family plan.

## Shopping list

Everything comes to about $4,595 before tax and about $4,870 with PA's 6% tax. Bought in Delaware, you pay about $4,595 at the register and set aside about $276 for PA use tax, due with your PA income tax return. Prices marked est. are estimates; the rest are recent listings. Memory and storage prices are volatile in 2026, so buy RAM and SSDs when a deal appears.

| Item | Group | Price (USD) |
| --- | --- | --- |
| [Mac mini M5 Pro, 48 GB, 512 GB](https://aiindigo.com/hardware/apple-mac-mini-m5-pro-64gb) | AI machine | 2,299 |
| [64 GB DDR4 RAM (2x32)](https://datacenterdisk.com/ram/ddr4/64gb) | PC upgrade | 412 |
| [i7-14700F ($330)](https://www.walmart.com/c/kp/intel-processor-gen) (or [14700K at Micro Center](https://slickdeals.net/f/19868634-micro-center-intel-core-i7-14700k-3-4ghz-cpu-star-wars-galactic-racer-tomb-raider-legacy-of-atlantis-pc-games-270-free-store-pickup-269-99), $270, cheaper; cap its power in the BIOS) | PC upgrade | 270 |
| [4 TB NVMe SSD](https://capitalandcompute.net/ssd-prices/) | PC upgrade | 479 |
| Battery backup (UPS), 1500VA | Power | 250 est. |
| [4 TB hard drive for local backups](https://www.maxmybuild.com/storage/prices) | Backup | 190 est. |
| Wi-Fi temperature and humidity sensors (2) | Room | 50 est. |
| Water leak sensor | Room | 25 est. |
| 2.5 Gb network switch, 5 to 8 ports | Network | 60 est. |
| HDMI dummy plug for the headless Mac mini | Network | 10 est. |
| 27-inch 1440p monitors (2) | Desk | 500 est. |
| Keyboard and mouse | Desk | 50 est. |
| **Subtotal** |  | **4,595** |
| PA sales or use tax (6%) |  | 276 |
| **Total** |  | **4,871** |

**Left out on purpose:** an AC unit, a dehumidifier, a KVM switch, a new cable run and a Windows Pro upgrade. The basement stays cool and dry, the router cable already exists, and Windows Home runs Docker fine now that the trading bot has its own box.

**Swaps:**

- **Third monitor (+$265 with tax).** It pushes the total to about $5,135.
- **Mac mini with 64 GB (+$424 with tax).** Runs 32B models with more room and stretches to 70B. Pairs with dropping to one monitor to stay near $5K.

**Po****ssible ****Moving parts to Florida:**

- **The 16 GB of DDR4 can move.** The PA upgrade frees it, and it fits the Florida PC's AM4 board.
- **The RTX 3050** stays in PA. It runs the PA dev desk, including UE5 editor work when you're there.
- **Florida only gets freed parts. Nothing in this budget goes to Florida directly**.
- **The i5-12400F can't move.** It doesn't fit an AM4 board; it becomes the heart of the optional third machine below.
- **A real Florida upgrade later:** a drop-in Ryzen 7 5700X3D for gaming or a 16-core Ryzen 9 5950X for builds, plus a GPU with more video memory. That's outside this $5K.

**Buying in Delaware:** Delaware has no sales tax, so you pay nothing at the register. PA still charges its 6% use tax on things bought in Delaware and brought into PA, and you report it on your PA income tax return; the [PA Department of Revenue](https://www.revenue.pa.gov/TaxTypes/SUT/UseTax/Pages/Use%20Tax%20for%20Individuals.aspx) uses this exact case as an example. So the total above stays the same either way. Buy wherever the price is best: the 14700K deal is at a PA Micro Center, and Apple and Best Buy have stores near ILG.

### Optional mini travel machine (later)

The old i5-12400F plus the 16 GB of DDR4 the PA upgrade frees can become a small mini-ITX box, about the size of a shoebox. It can travel between PA and Florida as a portable workstation and setup helper, or live in Florida as a second machine next to the Florida PC. Its parts can't go inside the Florida PC itself: that board takes AMD chips. It adds about $470 to $630 with tax, so it sits outside the $5K core and comes after the main setup.

| Part | Price (USD) |
| --- | --- |
| i5-12400F (from the PA PC) | 0 |
| 16 GB DDR4 (from the PA PC) | 0 |
| [H610 DDR4 mini-ITX motherboard](https://www.walmart.com/ip/Socket-LGA1700-Intel-H610-DDR4-SATA3-USB3-2-M-2-Mini-ITX-Motherboard/5233065921) | 75 to 140 |
| [1 TB NVMe boot drive](https://capitalandcompute.net/ssd-prices/) | 150 est. |
| Low-profile graphics card, e.g. GT 1030 (the 12400F has no built-in graphics) | 60 to 80 est. |
| Mini-ITX case, travel-friendly | 70 to 100 est. |
| SFX power supply (skip if the case includes one) | 90 est. |
| Low-profile CPU cooler (free if the boxed cooler fits the case) | 0 to 35 est. |
| **Subtotal** | **445 to 595** |
| With 6% PA tax | 470 to 630 |

For travel, carry it on the plane rather than checking it, and keep the drive encrypted, since it may hold project code and keys.

**Where the freed 16 GB of DDR4 goes, two options:**

| Option | Florida PC | Mini box | Mini box cost with tax |
| --- | --- | --- | --- |
| A: RAM goes to the mini box | Keeps its current RAM | Uses the freed 16 GB | 470 to 630 |
| B: RAM goes to Florida | Adds the freed 16 GB | Needs its own 16 GB DDR4 kit (about $70 to $100) | 545 to 735 |

- **Option A** is cheapest and makes sense if the Florida PC already has enough RAM, or if the mini box comes first.
- **Option B** makes sense if Florida is short on RAM. The MSI Tomahawk has four slots, but mixing kits can be finicky: check Florida's current RAM size and speed first, and match 16 GB to what's there. New [16 GB DDR4 kits](https://datacenterdisk.com/ram/ddr4) start around $71.
- **Either way, decide when the PA RAM upgrade happens.** Until then the 16 GB stays in the PA PC.

**What the mini box adds to the plan:**

Its best use is in Florida as a second-location backup: today the only copy outside PA is the cloud backup, and a box in another state protects against fire, theft or a long outage at either house. It's a modest machine (6 cores, basic graphics), so it isn't for AI or heavy game work.

| Use | In PA | In Florida | Traveling |
| --- | --- | --- | --- |
| Second-location backup and Git mirror | No, same house | Yes, the top pick | No |
| Standby trading-desk box if the 2014 Mac mini dies | Yes | Yes | No |
| Second UE5 build machine for parallel builds | Yes | Slower over the network | No |
| Test server for the mini-games and multiplayer before cloud launch | Yes, on its own network | Yes | No |
| Monitoring hub: uptime alerts, sensor dashboard, Tailscale gateway | Yes | Yes | No |
| Second test client for multiplayer and Bridges web app testing | Yes | Yes | Yes |
| Setup helper with installers, offline backups and tools between sites | No | No | Yes |
| Demo machine for Bridges web app presentations | No | No | Yes |

- **Standby trading bot:** keep it in paper mode and switch it live only if the main bot box fails. Two live bots on one account could double up orders.
- **Test server in PA:** keep it off the network the trading bot and Bridges copies use, since game testers will connect to it.

## Room setup

The basement works as-is: it stays cool and dry, already has a wired line to the router, and the PC sits on granite or tile rather than carpet. Total heat output is roughly 400 W at full load, about 1,400 BTU/hr, less than a space heater on low.

- **Placement.** Machines on desks, PC on its stone or tile base with the front and bottom air intakes clear. Keep them away from the sump pump, water heater and laundry.
- **Sensors.** One temperature and humidity sensor at the desk, one near the PC exhaust, and the leak sensor on the floor under the desks. Set phone alerts at 80°F and 60% humidity.
- **When to add cooling or a dehumidifier.** Only if the sensors regularly cross those alert lines.
- **Power.** The UPS covers the PC, both Mac minis, the modem and router, and the switch. The trading bot is useless if the internet drops with the power.
- **Network.** Router cable into the switch; the PC, new Mac mini and 2014 Mac mini all wired to it. No Wi-Fi for the machines.
- **Desk.** Both monitors plug into the PC; the RTX 3050 drives them. Plug the new Mac mini into one monitor's second input so you can switch to it when you're downstairs. Day to day, reach everything remotely from upstairs.

## Bridges guardrails

The live BridgeMetric app and its client records stay on Base44, and the website stays on Hostinger, until Bridges has technical and security help. The records are health-adjacent, and a home server would make you solely responsible for uptime, backups and any breach.

**Runs on the Mac mini:**

- The local copy of the website and app, in separate development and testing versions
- AI explanation and recommendation features, tested on sample data only
- AI coding work on development copies, reviewed before anything reaches the live app
- Nonprofit documents and reports

**Rules that carry over from the earlier Bridges plan:**

- Keep assessment scoring separate from AI-generated explanations.
- Keep the source in a Git repository the nonprofit controls.
- Compare local model output against current Claude output before switching any feature; a weaker model can quietly hurt tone for a neurodivergent client base.
- Check what code and data Base44 lets you export. Anything tied to its backend may need rebuilding.

## Security segment (Plan AA)

The hub gets its own internet line and its own walled-off networks, so no agent can reach your family's devices, and each sensitive job (Trading Desk, Bridges assistant, business entities) is fenced off from the others. Xfinity stays the family's line; a Verizon 5G Home line becomes the hub's line and backup. Added October 30.

### The two lines

- **Xfinity (existing): the family line.** Family devices stay exactly as they are. The hub never touches it.
- **Verizon 5G Home (new): the hub line.** A different kind of connection, so it doesn't share Xfinity's outages, and it doubles as backup. With the Fold's Plus line on your Verizon plan, it may cost [about $35 to $45 a month](https://www.compareinternethub.com/?p=37196). Check availability at the PA address first.
- **Trade-off:** 5G Home uploads slower than Xfinity. Large uploads (Sixes builds to GitHub, The Crease's renders to R2) take longer; that's the price of keeping the hub off the family line.
- **How they connect:** Xfinity's gateway goes into bridge mode and both lines plug into one firewall router, which sends family traffic out Xfinity and hub traffic out 5G Home.

### Walled-off networks

A firewall router ([UniFi Cloud Gateway Ultra, about $129](https://ifeeltech.com/blog/unifi-cloud-gateway-ultra-review)) and a switch that supports separate networks (VLANs) split the house into segments. Nothing crosses between segments unless a rule allows it.

| Segment | What's on it | Internet | Can reach |
| --- | --- | --- | --- |
| Family | Everyone's phones, computers, TVs | Xfinity, unrestricted | Nothing in the hub |
| Trading Desk | 2014 Mac mini only | 5G Home, broker and market-data sites only | Nothing; the brain reads its status page through Tailscale, read-only |
| Hub and AI | New Mac mini (brain, local AI, content engine), PA PC | 5G Home, approved sites only (GitHub, AI services, your cloud accounts) | Trading Desk status page only |
| Bridges assistant | Bridges work, isolated from the other agents | 5G Home, Bridges-approved sites only | Nothing else |
| Business entities | Assistants for your other ventures, one fenced-off area each | 5G Home, each entity's approved sites only | Nothing else |
| Sensors | Temperature, humidity, leak sensors | Vendor's cloud only | Nothing |
| Guest | Your local techs' laptops when they visit | Internet only | Nothing |

**One machine, several fences:** network segments separate machines, not apps. The Bridges assistant and each business entity's assistant run on the new Mac mini, so each gets its own macOS user, its own container, its own tokens and an outbound firewall rule set. If Bridges ever handles real client data, it moves to its own small machine on its own segment.

### Rules for the AI itself

- **Approved-sites-only internet** for every agent segment, enforced at the router with DNS filtering. A blocked connection is logged and reported in the daily briefing.
- **Tailscale is the one path across segments,** so its access rules allow only named connections (the brain to the desk's status page; you to every machine) and deny everything else. Your family's devices never join Tailscale.
- **No credentials agents can read.** Keys live in a password manager; each agent gets its own narrow, revocable token. The plaintext key files in the Trading Desk folder go first.
- **Hardware security keys** (two, one as a spare) for GitHub, Google, the broker and the password manager.
- **Network off-switch:** cutting the hub's internet from the UniFi app on your phone, alongside the Trading Desk's own hard-off.
- **Disk encryption on every hub machine:** FileVault on the Macs, and device encryption on the PA PC (full BitLocker needs Windows Pro).
- **Backups the hub can't erase:** versioned off-site backups, so a misbehaving agent or ransomware can't delete the history.

### Security costs

| Item | One-time (USD) | Per year (USD) |
| --- | --- | --- |
| Firewall router (UniFi Cloud Gateway Ultra) | 129 | 0 |
| VLAN-capable 2.5 Gb switch, replacing the plain switch | 60 to 100 more than planned est. | 0 |
| Two hardware security keys | 110 est. | 0 |
| Door lock for the hub room | 50 to 100 est. | 0 |
| Verizon 5G Home, hub line | 0 | 420 to 540 |
| Password manager and DNS filtering | 0 | 10 to 80 est. |
| **Total** | **about 350 to 440 (plus 6% PA tax)** | **about 430 to 620** |

The one-time cost brings the core purchase to about $5,240 to $5,335 with tax, about $240 to $335 over the $5,000 budget; starting with one monitor (about $265 less with tax) brings it to roughly $5,000. The yearly costs are added to the year-one table below.

## Build sprint: Nov 6 to Nov 23, 2026

Goal: the PA desk fully built and tested by **Monday, Nov 23**. This section updates the shopping list above with today's decisions.

### What changed

- **Mac mini:** bought from B&H instead of Apple. Apple Mac mini (M5 Pro 18-core), B&H # APMMM5P40, MFR # Z1UD0007L, **$2,499**. Expected availability Nov 16 with free 2-day shipping, so it arrives around Nov 18–19. Apple's own date was Nov 27 or later. Before checking out, confirm it's **48 GB** and use a West Chester ZIP (19380/19382), not 33904. The listing says "Coming Soon", so the date could slip.
- **CPU cooler added, $35–60.** The i7-14700K needs a stronger cooler than the 12400F's stock one.
- **BIOS update first.** The B660 DS3H needs a BIOS update for 14th-gen chips. Do it with the 12400F still installed, before the swap.
- **Flight: done and paid. Nov 12, one way, $145.72.**

### Updated one-time cost

| Item | Cost |
| --- | --- |
| Original plan with security and lock, tax included | $5,240–5,335 |
| Mac mini +$200 (with 6% tax) | +$212 |
| CPU cooler (with tax) | +$37–64 |
| Flight Nov 12, one way | +$145.72 |
| **New total** | **$5,635–5,757** |
| Funding: stock sales plus cash | $5,407 |
| **Gap** | **$228–350 short** |

**Closing the gap:** buy one monitor less (about $265 with tax). That brings it to roughly even, at most about $85 short. The return flight isn't in this total yet.

### Funding: stock sales

Sell everything by **Mon Nov 9**. Trades settle the next business day; allow 1–3 more days for the bank transfer, so cash arrives around Nov 12.

| List | Stocks | Value | Gain/loss |
| --- | --- | --- | --- |
| Draft list | Spotify, Etsy, Qualcomm, Nike, Twin Peaks | $2,748.96 | +$1,081.44 |
| Add-on | Netflix, Ferrari, CVS, Disney, Coeur Mining | $2,639.37 | −$327.83 |
| **Total** |  | **$5,388.33** (+$18.55 cash) | **+$753.61** |

- **Kept:** Amazon, Nvidia, Google, NetEase.
- **Taxes:** all sales fall in the 2026 tax year, so the Netflix and Nike losses offset the Spotify gain. Pennsylvania only lets losses offset gains in the same year. Set aside $25–200 for tax, depending on your bracket and how long you've held each stock.
- **Twin Peaks:** in bankruptcy and worth about $0. Sell it or have the broker remove it as worthless before Dec 31.
- **Wash-sale rule:** don't rebuy Nike or Netflix within 30 days.
- Check the Spotify and Etsy purchase dates in case one is close to its one-year mark.

### Day-by-day

| When | What |
| --- | --- |
| Fri Nov 6 | Start the stock sales. Check out at B&H. Order Verizon 5G Home. |
| Mon Nov 9 | Sales done. Order the UniFi gateway and HDMI dummy plug. Set price alerts for the 64 GB DDR4 and 4 TB NVMe. Set up the password manager. |
| Thu Nov 12 | **Fly to PA.** Cash is in your bank. |
| Fri Nov 13–Sat Nov 14 | Micro Center: i7-14700K and cooler. Door lock and sensors if early deals show up. Update the BIOS, then swap the CPU. Keep the current 16 GB RAM and drive for now. |
| Sun Nov 15 | Windows, stress test, 3050 connected. Install the door lock. |
| Mon Nov 16–Wed Nov 18 | Verizon line live. Gateway and network segments, Tailscale, approved-sites DNS. The Mac mini arrives around Nov 18–19: FileVault, Ollama, the brain. |
| Thu Nov 19–Fri Nov 20 | Black Friday sale opens. Buy the 64 GB DDR4, 4 TB NVMe, monitors, battery backup (UPS), backup drive, keyboard and mouse, and switch, with in-store pickup. Fri: install the RAM and NVMe, put Windows on the new drive (or clone the old one) and set up backups. |
| Sat Nov 21 | Monitors, desk, cables, sensors. |
| Sun Nov 22 | Full test from the Florida PC and the phone: every machine reachable, brain briefing runs, backups and lock work. |
| **Mon Nov 23** | **Done.** |

If the Mac mini slips past Nov 23, finish everything else on schedule and add it the week after Thanksgiving.

### Holiday deal addendum

This covers only the smaller gear. The Mac mini, CPU, RAM and NVMe keep their own timing. Best Buy's 2026 schedule:

- **Early Black Friday deals:** started Nov 6, with new deals every Friday (next batch Nov 13).
- **Black Friday Doorbusters:** Nov 19–28.
- **Cyber Sunday and Monday:** Nov 29–30, followed by Cyber Week deals Dec 1–6.

Amazon and others usually match on the big items. The prices below are typical Black Friday discounts, not live listings.

| Item | Plan price | Typical holiday price | Est. savings | Buy window |
| --- | --- | --- | --- | --- |
| 27" 1440p monitors (2) | $500 | $300–400 | $100–200 | Nov 19–20 |
| Battery backup (UPS), 1500VA | $250 | $170–200 | $50–80 | Nov 19–20 |
| 4 TB backup hard drive | $190 | $120–150 | $40–70 | Nov 19–20 |
| Smart door lock | $50–100 | 20–40% off | $15–40 | Nov 13 |
| Keyboard and mouse | $50 | $30–35 | $15–20 | Nov 19–20 |
| Hardware keys (2) | in the security plan | Cyber Monday sale | $10–25 | Nov 30 |
| Temperature and leak sensors | $75 | 15–30% off | $10–25 | Nov 13 or 19 |
| 2.5 Gb network switch | $60 | $45–50 | $10–15 | Nov 19 |
| CPU cooler | $35–60 | small discounts | $5–15 | Nov 13, Micro Center |
| UniFi Cloud Gateway Ultra | $129 | rarely discounted | $0–15 | Now (needed by Nov 16) |
| HDMI dummy plug | $10 | — | $0 | Now |
| **Total** |  |  | **$255–505 (about $270–535 with tax)** |  |

**Effect on the budget:** the sprint was $228–350 short. These savings cover most or all of that, so the second monitor may stay in.

#### Two timing options

**Option A: keep the Nov 23 finish (recommended).**

- **Savings:** about $255–505.
- **Schedule changes:**
  - The gateway and dummy plug get bought now.
  - The cooler, lock and sensors get bought Nov 13.
  - The desk gear (monitors, UPS, backup drive, keyboard and mouse, switch) gets bought Nov 19–20 from the main sale, with in-store pickup near West Chester, ready for desk day on Nov 21.
  - Hardware keys wait for Cyber Monday. Use a phone authenticator app until they arrive.

**Option B: core by Nov 23, desk extras on Black Friday or Cyber Monday.**

- **What gets done by Nov 23:** the machines, network, security and brain. The hub runs headless and is reached remotely, so it doesn't need monitors to work.
- **What moves:** monitors, keyboard and mouse wait for Nov 27–30, shipped to the PA house. Set them up on the next visit or with a local tech.
- **The UPS still comes Nov 19–20,** before the hub starts running 24/7.
- **Extra savings over Option A:** maybe $25–75, from the deepest doorbusters and Cyber Monday bundles.
- **The cost:** no finished desk until the next visit.

**Bottom line:** most of the savings come from buying in the Nov 19–20 window, which already fits the sprint. Pushing the whole plan later saves little more. Moving only the monitors and keyboard to Black Friday is the one shift that might be worth it, and only if a finished desk on Nov 23 doesn't matter.

**Price drops:** if something bought before Nov 19 drops in price during the sale, ask Best Buy about a price match. The rules vary by event, so check at purchase.

#### Bigger items: Mac mini and PC upgrades

| Item | Plan price | Likely holiday savings | Decision |
| --- | --- | --- | --- |
| Mac mini M5 Pro, B&H | $2,499 | $0–100 | **Buy now.** A new "Coming Soon" model is rarely discounted, and getting it on time is worth more. Check B&H's "Available Savings" link at checkout. |
| i7-14700K, Micro Center | $270 | $10–30 | **Buy Nov 13.** $270 is already a sale price. |
| 64 GB DDR4 RAM | $412 | $40–70 | **Buy Nov 19–20** and install Nov 20. Memory prices rose in 2026, so buy earlier if a price alert hits a good price. |
| 4 TB NVMe SSD | $479 | $70–120 | **Buy Nov 19–20** and install Nov 20. Storage drives are one of the most reliable Black Friday categories. |
| **Total** |  | **$120–320** |  |

**All holiday savings combined** (accessories plus the bigger items): about **$375–825**. That covers the sprint's $228–350 gap with room left over, likely enough to keep both monitors or pay for the return flight. The day-by-day schedule above now reflects this: CPU swap Nov 13–14, RAM and NVMe install Nov 20.

## Budget addendum: lean version

An alternative to the sprint above, with four limits:

- **No Verizon 5G Home line.** The hub runs on the existing Xfinity line.
- **Security comes from the UniFi gateway's firewall** instead of a second line.
- **Netflix and Ferrari are not sold.**
- **No monitors.** The hub runs headless and is used remotely.

### Funding without Netflix and Ferrari

| Sell | Value | Gain |
| --- | --- | --- |
| Draft list: Spotify, Etsy, Qualcomm, Nike, Twin Peaks | $2,748.96 | +$1,081.44 |
| CVS, Disney, Coeur Mining | $1,100.01 | +$33.44 |
| Cash | $18.55 |  |
| **Funding, Option 1** | **$3,867.52** | **+$1,114.88** |
| Optional: NetEase and Google too | +$803.93 | +$256.47 |
| **Funding, Option 2** | **$4,671.45** | **+$1,371.35** |

- **Kept:** Amazon, Nvidia, Netflix and Ferrari in both options, plus NetEase and Google in Option 1.
- **Tax:** without the Netflix loss to offset, the gain is larger. Estimated tax is $34–280 for Option 1 and $42–344 for Option 2. The low end is PA tax only; the high end is short-term federal plus PA.

### Security through the gateway, on Xfinity

- **Wiring:** the Xfinity gateway stays exactly as it is, with family Wi-Fi unchanged. The UniFi Cloud Gateway Ultra plugs into an Xfinity LAN port. Every hub machine is wired into the UniFi gateway or the VLAN switch behind it, never into Xfinity directly.
- **Walled-off networks on the UniFi side:**
  - hub/AI (Mac mini, PA PC)
  - Trading Desk (2014 Mac mini)
  - Bridges assistant
  - business entities
  - management

  Anything not explicitly allowed between them is blocked.
- **Family protection:** a firewall rule blocks every hub network from reaching the Xfinity home network. The AI can't see or touch family devices. Family devices can't reach the hub either, because it sits behind the UniFi gateway.
- **Approved-sites-only DNS on each network.** For example, the Trading Desk can only reach the broker and its data APIs.
- **No open ports.** Remote access goes through Tailscale with tight access rules. Public hosting (the Bridges site, the arcade) goes through a Cloudflare Tunnel later. Sixes multiplayer servers get their own port plan when multiplayer is ready.
- **Bandwidth limits on the hub networks,** so builds and uploads don't slow the family's internet.
- **Sensors** stay on Xfinity's guest Wi-Fi. They only need the internet, and there's no UniFi Wi-Fi access point in this version.
- **What's lost compared with Plan AA:** there's no second line as a backup during an Xfinity outage, and the hub shares the family's bandwidth. Adding a UniFi access point and putting Xfinity into bridge mode can come later if wanted.

### Lean shopping list

Deal prices assume Black Friday timing, as in the holiday addendum. Totals include 6% PA tax.

| Group | Items | List price | With holiday deals |
| --- | --- | --- | --- |
| **Core** (by Nov 23) | Mac mini $2,499; i7-14700K; cooler; UniFi gateway; VLAN switch; door lock; HDMI dummy plug; keyboard and mouse; 64 GB DDR4 | $3,842 | $3,652–3,758 |
| Flight Nov 12, one way |  | $145.72 | $145.72 |
| **Extras** (Option 2, Nov 19–20) | Battery backup (UPS), 4 TB backup drive, 4 TB NVMe | $974 | $688–805 |
| **Later** (December or after) | Sensors, two hardware keys | $196 | $143–175 |
| Removed | Monitors (−$530), Verizon 5G Home (−$420–540 a year) |  |  |

### What each option buys

|  | Option 1: no extra sales | Option 2: also sell NetEase and Google |
| --- | --- | --- |
| Funding | $3,867.52 | $4,671.45 |
| Bought by Nov 23 | Core plus flight: $3,797–3,903 | Core, extras and flight: $4,485–4,708 |
| Left over or short | About +$70 to −$35 | About +$185 to −$37 |
| Deferred | UPS, backup drive, NVMe, sensors, keys (about $830–980) | Sensors and keys only (about $145–175) |
| Trade-off | Starts without a battery backup or local backups. Run on the existing drive, keep code backed up to GitHub, and don't run the Trading Desk 24/7 until the UPS arrives. | Uses more of the portfolio, but the hub launches complete except for sensors and keys. |

**Recommendation:** Option 2 if the Black Friday prices come through. Otherwise Option 1, adding the extras from income in December.

### Lean day-by-day

| When | What |
| --- | --- |
| Fri Nov 6 | Sell the draft list plus CVS, Disney and Coeur (and NetEase and Google for Option 2). Check out the Mac mini at B&H. No Verizon order. |
| Mon Nov 9 | Sales done. Order the UniFi gateway, VLAN switch and HDMI dummy plug. Set price alerts for the RAM, NVMe, UPS and backup drive. Set up the password manager. |
| Thu Nov 12 | Fly to PA. Cash is in your bank. |
| Fri Nov 13–Sat Nov 14 | Micro Center: i7-14700K and cooler, plus the RAM if the price is good. Buy the door lock. Update the BIOS, then swap the CPU. Use a TV or a borrowed screen for setup. |
| Sun Nov 15 | Windows and stress test. Install the door lock. Wire the UniFi gateway behind Xfinity and create the networks and firewall rules. |
| Mon Nov 16–Wed Nov 18 | Tailscale and its access rules, approved-sites DNS, bandwidth limits. The Mac mini arrives around Nov 18–19: FileVault, Ollama, the brain. |
| Thu Nov 19–Fri Nov 20 | Black Friday sale: RAM if not bought yet, plus the UPS, backup drive and NVMe for Option 2. Install them Friday and set up backups. |
| Sat Nov 21 | Cables and tidy-up. Put in the dummy plug and switch every machine to headless, remote-only use. |
| Sun Nov 22 | Full test from the Florida PC and the phone. Also check that a hub machine **cannot** reach a family device, and that the Trading Desk can reach only its approved sites. |
| **Mon Nov 23** | **Done.** Sensors and hardware keys come in December, or on Cyber Monday if there's money left. Monitors are optional, any time later. |

### Funded: $4,294 (sold Nov 9)

- **Stocks sold Nov 9:** **$4,294** in cash purchasing power at E\*TRADE. The trades settled Nov 10. Banks don't move transfers on Veterans Day (Nov 11), so the withdrawal should arrive around **Nov 12–13**. Pay the card off when the cash lands.
- **Mac mini: ✅ ordered Nov 11** from Apple, not B&H. M5 Pro (18-core CPU, 20-core GPU), 48 GB, 512 GB, 2.5 Gb Ethernet. $2,499, about $2,657 with tax and $8 express delivery, on a card. Arrives about Nov 18–20 in West Chester. Cancel the B&H cart order if one was placed.
- **AppleCare+ reminder:** decide before the shopping list is finished. It can be added within 60 days of purchase (by about Jan 10, 2027). It's worth it for a machine running 24/7 if the desk leftover allows.
- **Twin Peaks (22 shares, about $0):** not sold. A sell order costs $6.95 and there's no buyer. Ask E\*TRADE to remove it as a worthless security, or claim the loss at tax time.
- **Flight: ✅ done and out of the way.** Nov 12, one way, $145.72, already paid.
- **Tax set-aside:** about $35–345, due April 2027. Pay it from income, not from this money.

| Buy | When | Est. cost with tax |
| --- | --- | --- |
| Core: Mac mini, i7-14700K, cooler, 64 GB DDR4, UniFi gateway, VLAN switch, door lock, HDMI dummy plug, keyboard and mouse | Nov 9–20 | $3,652–3,758 |
| Battery backup (UPS) and 4 TB backup drive | Nov 19–20 | $307–371 |
| Room prep supplies (only what you don't already have) | Nov 12–13 | $50–110 |
| **Left over** |  | **About $55–285** |
| Deferred: 4 TB NVMe, sensors, hardware keys | December, or Cyber Monday if money is left | $525–610 |

This assumes the flight was paid separately. If it came out of the $4,294, subtract $146 from what's left over.

### Room prep checklist (do Nov 12–13, before the hardware)

Do the dusty work first. Give the dust a few hours to settle before any machine is opened or set up.

**Clean**

- [ ] Dust the fan blades and both vents. Vacuum the vent grilles.
- [ ] Dust the ceiling joists, pipes and ductwork above the desk area. That dust falls onto the machines later.
- [ ] Vacuum the floor, ideally with a HEPA vacuum, and wipe down the desk surfaces.
- [ ] If the vents are part of the house's heating and cooling system, check the furnace filter and replace it if it's dirty.
- [ ] Clear clutter and cardboard from around the desk area. Move paint, gas cans and anything flammable well away.

**Air and water**

- [ ] Check whether each vent supplies air or returns it. Don't place a machine where it blows directly into a vent or pulls from one.
- [ ] Aim the fan to move air across the room, not straight into a machine's intake.
- [ ] Look for moisture: water stains, white powdery residue on the walls, a musty smell, or pipes that drip or sweat overhead. Nothing should sit under a pipe.
- [ ] Find the sump pump, water heater and main water shutoff. Keep the gear away from all three.
- [ ] Get a humidity baseline with a $10–15 hygrometer, since the sensors are deferred. Above 60% means plan on a dehumidifier.
- [ ] Keep the PC raised off the floor on its stone or tile base.

**Power**

- [ ] Find which breaker feeds the desk outlets and label it.
- [ ] Check that the circuit isn't shared with the sump pump, a freezer, a dehumidifier or the laundry.
- [ ] Test the outlets with a $10 outlet tester. They must be grounded three-prong outlets.
- [ ] Plan for the UPS to plug straight into the wall, with no power strips chained together.

**Network**

- [ ] Find the existing cable from the Xfinity gateway, check that it works, and measure the run to the desk.
- [ ] Get short Cat6 patch cables, 5 or 6 of them: Xfinity to the UniFi gateway, UniFi to the switch, and one each for the PC, the new Mac mini and the 2014 Mac mini.
- [ ] Check that Xfinity's guest Wi-Fi reaches the basement (for the sensors later) and that your phone has signal there (for sign-in codes).

**Door**

- [ ] Before buying the lock, measure the door's thickness and the backset (2¾" or 2⅜"), and note whether it already has a deadbolt hole.

**Build kit**

- [ ] Phillips #2 screwdriver and a magnetic parts tray or cup
- [ ] Isopropyl alcohol (90% or higher) and lint-free cloths, to clean the old thermal paste off when removing the 12400F's cooler
- [ ] An electric duster or canned air, for the room and the PC's insides
- [ ] Velcro cable ties
- [ ] A good work light or headlamp
- [ ] A TV or borrowed screen plus an HDMI cable, for first setup, since there are no monitors in this version
- [ ] Work on a hard surface and touch the metal case before handling parts, to discharge static

**Safety**

- [ ] Check that a smoke detector nearby works.
- [ ] Keep a small ABC fire extinguisher (about $30) near the desk.
- [ ] Look for mouse droppings. Mice chew cables, so set traps if you see signs.

**Before and after**

- [ ] Take photos of the room before and after setup, and measure the desk space.

**Supplies to buy, if you don't have them:** outlet tester ($10), hygrometer ($12), Cat6 patch cables ($15–25), isopropyl and cloths ($8), electric duster or canned air ($10–40), velcro ties ($10), fire extinguisher ($30). About **$50–110**, depending on what's already in the house.

## Setup order

Start with the free steps this week; each later phase starts when its parts arrive.

1. **Free steps, now**
   - Wipe the 2014 Mac mini, install Linux, and get the Trading Desk running there in paper mode once its scripts have Linux versions.
   - Pull Bridges usage numbers from the Base44 dashboard and the Anthropic Console.
   - Check what Base44 lets you export.
2. **PC upgrades**
   - Update the BIOS to the latest version first. The current one is from July 2023 and predates 14th-gen support and Intel's stability fix.
   - Install the RAM, then the CPU (cap power in the BIOS if it's the K chip), then the 4 TB drive.
   - Set up Docker Desktop, Git and the UE5 build setup.
3. **Room**
   - Place the sensors and leak sensor, set the alerts, and put the UPS and switch in.
   - Watch temperatures for a week with the PC under build load.
4. **New Mac mini**
   - Install Ollama and test models on sample data against current Claude output.
   - Set up the Bridges development and testing copies.
   - Turn on backups: Time Machine to the 4 TB drive plus encrypted off-site backup.
5. **Desk**
   - Monitors, keyboard and mouse.
6. **Later**
   - Cloud server when the mini-games platform or multiplayer goes public.
   - Real-money testing only by your explicit decision, only on the 2014 Mac mini, after a few weeks of clean paper trials there.
   - Third monitor, or more Mac memory, as budget allows.

## Finishing the four projects

Most of what's left on all four projects can happen now on the Florida PC; the PA desk takes over the 24/7 and heavy work once it's built. Based on the October 30 project updates.

**First, this week: get every project safely onto GitHub.** The PA machines build from GitHub, and today work sits on single drives.

- [ ] Sixes: commit the newest work and push the 17 commits on `codex/exhibition-roster-adapters`.
- [ ] The Crease: push `integration/2026-10-27` and open the PR.
- [ ] Trading Desk: settle which copy is real (OneDrive at 0.4.133, or `D:\AI-Projects` at 0.4.85) and make `D:\AI-Projects` the home again.
- [ ] Trading Desk: move `etrade APIkey.txt` and `owner passkey update code.txt` into a password manager.

| Project | Before the desk (Florida PC, now) | When the PA desk is built | Your decisions | Done when |
| --- | --- | --- | --- | --- |
| The Crease | Windows install, tests and database upgrade; push and PR; acceptance checklist; real-footage test | Render worker moves to the PA PC, running 24/7; the brain relays alerts and review requests on Discord | Cloud spending cap; TikTok direct or only through Buffer; number of Buffer channels | First real highlight posts through Buffer to a private channel, then public |
| Rewind Arcade | Supabase secret key, then Enable-Creator-Uploads; tester and reviewer roles; first creator run with Robert's game | Firefox, Android and touch tests run on the PA PC; the brain tracks the M5 pilot checklist | Supabase Pro (recommended before the pilot); Workers paid after the preview load test; the 7 M5 pilot questions; legal steps | M4 closed with one real creator published; M5 invite-only pilot started |
| Sixes | Finish Milestone 2 rules and AI: missed-shot timing, out of bounds and whistles, goalie ball polish, AI tactics; real-controller testing on your pad | PA PC builds and packages from GitHub and hosts a dedicated server; you test online from Florida over Tailscale | When to turn the possession loop on in the menu | Milestone 2 complete, including the online test |
| Trading Desk | Restart to load 0.4.133 and run the desk tests; set FORWARD\_TRIALS\_DIR; add the Gmail app password; Linux versions of the desk's scripts | Desk moves to its home on the 2014 Mac mini (Linux), loopback-only with Tailscale; the brain reads status and relays alerts | Whether to start the ETF dip-buying and ETH breakout paper trials | Paper trials running 24/7 on the 2014 Mac mini with alerts reaching your phone |

**The Trading Desk's home is the 2014 Mac mini on Linux.** Any real-money testing happens only there. Its scripts are Windows-only today (`.bat` and `.ps1`), so Linux versions of the start, restart, hard-off and test scripts are part of the desk's finishing touches before it moves. Until then, paper trading continues where it runs now. The OneDrive copy question gets settled when all the projects move into their real homes.

**Order once the hardware arrives:** PA PC upgrades first (Sixes builds and The Crease worker need it), then the Trading Desk move, then the new Mac mini with the brain's Phase 1 to 3 taking over the checklists above.

## Progress and launch estimates

The Crease is closest to launch and the Sixes game is furthest. These are judgment calls from the October 30 updates, assuming your current AI plan ($20 Claude plus $20 ChatGPT) and the PA desk running within about two months. They depend most on how fast you work through the steps only you can do.

| Project | Done | Finish line | Estimated launch | What sets the pace |
| --- | --- | --- | --- | --- |
| The Crease | About 80% | First public highlight posts through Buffer | Mid-December 2026 to January 2027 | Your live-account steps and the real-footage test; the 24/7 render worker waits for the PA PC |
| Trading Desk | About 85% to paper-complete; about 50% to real-money ready | Paper trials 24/7 on the 2014 Mac mini; real money only by your decision | Paper-complete January to February 2027; real money not before spring 2027, and only if a strategy shows an edge | Linux versions of the scripts, weeks of clean paper trials, key rotation and retiring the old bot; so far no strategy beats holding an ETF basket |
| Rewind Arcade | About 55% | Public launch (M7) | Summer 2027 | Invite-only pilot (M5) and subscriptions (M6) not started; legal steps (name, company, lawyer-finished terms, copyright agent) run alongside |
| Sixes game | About 18% (12% to 22%) of the full v1; about 22% of an Exhibition-plus-online v1 | Paid launch on Steam | Exhibition plus online only: late 2027 to late 2028. All modes: mid-2028 to 2029 | Art and animation are about a quarter of all the work and still placeholder; online play is barely tested; buying or licensing art is the biggest swing |

**How the percentages were judged:**

- **The Crease:** all code built and 542 tests passing; what's left is setup, live tests and two decisions.
- **Trading Desk:** the desk itself is in finishing touches; real-money readiness also needs the Linux move, paper-trial evidence and the security steps.
- **Rewind Arcade:** M0 to M2 done and M3 and M4 nearly done, out of eight milestones; M3 and M4 were the largest.
- **Sixes:** from your October 30 milestone list (saved at server-hub/reference/sixes-milestones-2026-10-30.md), weighted by each milestone's share of the work. The game has gained about 18 points since summer, roughly 4 to 5 a month. At that pace an Exhibition-plus-online launch (about 63 points left) takes 12 to 24 months, and the full v1 with Franchise, Ultimate Team and My Player (about 82 points left) takes 18 to 36 months. Art, animation and online work are slower per point than the systems code done so far, which is why the ranges run long. Cutting v1 to Exhibition plus online, with the modes added after launch, and buying or licensing animation and art are the two biggest ways to pull the date in; asset purchases are not yet in the cost table.

**What the $40 AI plan means:** both plans have usage limits that reset every few hours and weekly, so long build sessions stop until they reset. That mainly slows the big build jobs: Rewind Arcade's subscriptions milestone and the Sixes game. The Crease and the Trading Desk are now limited by your own steps, not AI time. Moving one plan up a tier ([Claude Max starts at $100 a month](https://chudi.dev/blog/claude-pro-vs-max); [ChatGPT Pro has a $100 tier with five times Plus's Codex use](https://www.macrumors.com/2026/04/09/openai-pro-subscription-tiers/)) could pull the Rewind Arcade and Sixes dates in by a few months. That adds about $960 a year, already inside the high column of the year-one cost table.

## AI plans and agents

How money saved on the desk and the network goes toward better AI, and which agent does which job. Prices are from the plan pages as of Nov 10, 2026.

### Money available for AI upgrades

| Source | Amount |
| --- | --- |
| Desk leftover (known after Nov 23) | $55–285, one time |
| No Verizon 5G Home line (lean version) | $35–45 a month |
| Local AI on the Mac mini (Ollama) | Free. It takes simple tasks off the paid plans |
| Later: dropping Hostinger and Base44 | Bridges' savings, not personal money; stays with Bridges |

### The agent lineup

| Agent or tool | Job | Runs on | Cost |
| --- | --- | --- | --- |
| **The brain** (hub manager) | Daily briefing, project status, routing work to the right agent, approvals over Discord | New Mac mini | Its model gets picked at Phase 1: local first, with Claude for hard calls |
| **Claude Code** (Claude Pro or Max) | Main coding agent: Sixes, Rewind Arcade, the Trading Desk, the brain itself | Florida PC and PA machines | $20 a month, or $17 billed annually; Max from $100 |
| **ChatGPT Plus / Codex** | Second opinion on code, image creation for The Crease | Florida PC | $20 a month |
| **Local models (Ollama)** | Private or bulk work: summaries, sorting, drafting, the Bridges assistant's first pass, anything that shouldn't leave the house | New Mac mini (48 GB) | Free |
| **Perplexity** (new) | Research agent: cited web answers and current news | Sonar API called by the brain, or the Perplexity app | API pay-as-you-go, or Pro at $20 a month ($17 annual) |
| **The Crease content engine** | Lacrosse content drafts, clips, scheduling | PA PC | Uses the plans above |
| **Trading Desk agents** | Paper trading, market research, nightly reports | 2014 Mac mini (Linux) | Market data from the broker; news through Perplexity |
| **Bridges assistant** | Nonprofit admin help, kept in its own walled-off network | New Mac mini | Local first, plus Claude when needed |

**Rules that apply to every agent:**

- Every agent works under the brain's permission tiers: read, safe, approve, high-stakes, never.
- Money, public posts and anything touching real trading always need your approval.
- Each agent stays inside its own network segment.

### Mac mini software stack

Everything here is free and runs locally. Ollama is the engine; these are the pieces around it.

| Tool | What it does |
| --- | --- |
| **Ollama** | Runs the local models |
| **Local models** | 48 GB fits a mix: a mid-size model (about 30B) as the brain's main thinker, a small fast model (about 8B) for sorting and summaries, and an embedding model for search |
| **Open WebUI** | A private chat window for the local models, opened from the phone or the Florida PC over Tailscale |
| **Memory and search store** (a vector database such as Qdrant, or Open WebUI's built-in one) | Lets the brain and the Bridges assistant search project docs, notes and Bridges files without sending them to the cloud |
| **Whisper**, local speech-to-text | Transcripts and captions for The Crease; voice notes to the brain through Discord |
| **Docker** (or OrbStack, lighter on a Mac) | Runs each service in its own container: Open WebUI, the search store, the local Bridges copy |
| **Supabase, local** | Database for the Bridges dev copy |
| **MCP connectors** | The standard way to hand agents tools (GitHub, files, Discord, Perplexity) under the brain's permission tiers |
| **Claude Code** | Also runs here, not only on the Florida PC, so long coding jobs can run overnight |
| **Discord bot** | The brain's phone channel (Phase 1) |
| **Tailscale; Time Machine plus Backblaze** | Remote access; backups |
| *Optional later:* **n8n** | Visual automation wiring. Add it only if the brain's own scripts get messy |

### Agent landscape (as of Nov 2026)

The other agents worth knowing, grouped by goal, with a verdict for this hub. Prices change often and some plans were renamed in 2026, so recheck before paying.

**Coding**

| Agent | What it is | Price | Verdict |
| --- | --- | --- | --- |
| **Claude Code** | Terminal and IDE agent; strongest on large, multi-file work | With Claude Pro; Max $100–200 | **Core.** The Max trial is in the upgrade path |
| **OpenAI Codex** | Sandboxed coding agent | Included with ChatGPT Plus | **Keep** while you have Plus: a free second opinion |
| **Cursor** | VS Code-based editor with AI built in, good for visual edit-and-review | Free Hobby tier; paid plans from about $20 | **Try the free tier.** Don't pay for both Cursor and Claude Max: they overlap |
| **GitHub Copilot** | Completions plus lighter agent work in most editors | Free tier; Pro $10 | **Optional.** The cheapest add-on if you want inline completions |
| **Devin / Devin Desktop** (formerly Windsurf) | Autonomous: hand it a scoped ticket and review the result | Free; Pro $20 | **Later**, once the brain hands out tickets (Phase 3) |
| **Aider / Cline** | Open-source coding agents that can run on **local Ollama models** | Free with local models | **Add.** They offload simple coding to the Mac mini at no cost |
| **Replit Agent** | Builds and deploys apps from a prompt | From $20 | **Skip.** Base44 already covers fast app building for Bridges |

**Game development (Sixes)**

- **Unreal Engine MCP.** Official from Epic in UE 5.8, experimental. Lets Claude work inside the editor: Blueprints, levels, assets.
- **What hands-on testing found:** it's slow (5–15 minutes per step), it can break player controls, and it uses a lot of Claude usage.
- **Verdict:** try it for greyboxing and Blueprint chores once Sixes is on 5.8, ideally with Max. Keep Sixes' core systems hand-checked.

**Research and knowledge**

- **Perplexity Sonar API:** live, cited research. Already added above.
- **Claude and ChatGPT deep research:** included in the current plans.
- **NotebookLM** (free): good for Bridges grant documents and program research.

**Content (The Crease)**

- **ChatGPT images:** already included.
- **Whisper (local):** captions and transcripts.
- **Worth evaluating later:** an AI video editor, AI voice, and short-form clip tools. Price them when The Crease's posting schedule is set.

**Personal agent frameworks (for the brain)**

- **OpenClaw:** an open-source, self-hosted personal agent that connects to Discord and other chat apps, and is commonly run on a Mac mini. It could jump-start brain Phase 1 instead of building everything from scratch.
- **Security caveat:** it acts with broad permissions and can be tricked by malicious web content. If tried, run it in a container on its own network segment, behind the brain's permission tiers, with read-only access first.
- **OpenHands:** an open-source autonomous coding agent, a local alternative to Devin.
- **n8n:** optional automation wiring, listed above.

**Trading Desk:** no AI agent gets real-money trading power. AI is for research, paper trading and reports only.

**Bottom line:** keep Claude (with the Max trial) plus local models as the core. Add the free pieces: Aider or Cline on Ollama, and Cursor's free tier if you like a visual editor. Evaluate OpenClaw carefully as a head start for the brain. Use Unreal MCP for Sixes chores once on 5.8.

### Where Perplexity fits

Perplexity is built for search with sources, and it connects to other agents through its **Sonar API**, so the brain can call it like any other tool.

- **Best uses here:**
  - **The Crease:** lacrosse news, scores and recruiting stories, with sources to cite.
  - **Trading Desk:** a morning news and earnings scan for the paper portfolio.
  - **Bridges:** grant and program research.
  - **The brain:** answering any "what's true right now" question in the daily briefing.
- **Two ways to pay:**
  - **Sonar API, pay as you go (recommended to start).** About $1 per million tokens for Sonar, plus about $5 per 1,000 searches. A few hundred searches a month comes to roughly **$2–10 a month**, and only the agents use it.
  - **Perplexity Pro, $20 a month ($17 annual).** Worth it only if you want it yourself for daily research or its built-in agent ("Computer"). Pro doesn't include API credits, so the agents would still be billed separately.
- **Perplexity Max at $200 a month** isn't worth it for this setup.

### Upgrade path

| Step | When | What | Monthly AI cost |
| --- | --- | --- | --- |
| 1 | Now to Nov 23 | No changes. Every dollar goes to the desk. | $40 |
| 2 | Dec 2026 | Add the Perplexity Sonar API to the brain (Phase 1). Try **Claude Max ($100)** for one month during The Crease launch push and the brain's Phase 1. | $40 + $100 − $20 (pause Plus if possible) + $2–10 ≈ **$122–130** for the trial month |
| 3a | Jan 2027, if Max sped things up | Keep Max. Drop ChatGPT Plus unless The Crease needs its images. | **$102–130** |
| 3b | Jan 2027, if it didn't | Back to Claude Pro, billed **annually ($200, paid from the desk leftover)**. Keep ChatGPT Plus. | **About $39–47** |

**Don't buy Claude Pro annual before trying Max.** It locks in the smaller plan for a year.

**Year-one effect:**

| Path | Cost per year |
| --- | --- |
| Max only, plus the Perplexity API | About $1,225–1,320, versus $480 today |
| After the Verizon savings ($420–540 a year) | About **$205–420 more** than the current plan |
| Path 3b | Roughly break-even with today, and the Verizon savings come out ahead |

AI prices change often. Recheck them before each step.

## Growing the hub: streamlining and brain roadmap

The long-term goal is a private, local AI hub that can take on new entities over time: Bridges, The Crease, Rewind Arcade, Sixes, the Trading Desk, and whatever comes next. As projects start earning, the hub should grow with them. This section is a running list. Add to it as better ways turn up.

### Streamlining: set up once, reuse for every entity

1. **One registry as the source of truth.** `projects.json` in server-hub already lists the projects. Extend it to list every entity, machine, agent, network segment and budget line, so the brain reads one file to know the whole hub.
2. **An "entity kit" template.** A new entity gets the same starter pack:
   - its own network segment
   - a Docker setup
   - a Discord channel
   - a section in the search store
   - a permission profile
   - a cost line

   Adding an entity becomes an afternoon, not a project.
3. **Setup as code.** Keep the Docker files, firewall notes and install scripts in the server-hub repo. A rebuild, or moving parts to Florida, then means rerunning scripts instead of starting over.
4. **One AI gateway.** Every agent sends requests through one local router (a LiteLLM-style proxy). The brain decides local model vs. Claude vs. Perplexity for each task and logs the spend **per entity**.
5. **One code home per project.** Fix the two-copies problem: GitHub is the single source, and every machine pulls from it.
6. **One alert channel.** Builds, backups, uptime, sensors and spend all report to Discord, sorted by entity.

### Brain roadmap: more power, in steps

| Phase | When | The brain can… | Permission level |
| --- | --- | --- | --- |
| 0 ✅ | Done | Write a read-only daily briefing | Read |
| 1 | Dec 2026 | Talk two-way on Discord; run tests, check git status, restart a service | Read + safe |
| 2 | Early 2027 | Remember: search all project docs and notes, research with Perplexity, take voice notes through Whisper | Read + safe |
| 3 | 2027 | Delegate: hand coding tasks to Claude Code or the local models, open pull requests for you to approve on Discord, track AI spend per entity | Approve |
| 4 | 2027 | Operate: watch uptime, backups and sensors; fix safe issues itself; send weekly reports per entity | Safe + approve |
| 5 | As entities grow | Manage: each entity gets its own sub-agent behind its own wall, with the brain as manager, and new entities spun up from the entity kit | High-stakes needs you |

**Rules that hold at every phase:**

- **Never:** moving money, real-money trades, or posting publicly without your approval.
- A full log of every action the brain takes.
- A one-command kill switch.
- Each entity's data stays behind its own wall.

### Growing the hardware as projects earn

- **First revenue:** bring back a second internet line as a backup when public hosting starts to matter (Verizon 5G Home or similar).
- **Bigger local models:** a Mac Studio with 96–128 GB, or a second Mac mini sharing the load.
- **More storage:** a NAS for media from The Crease and Rewind Arcade, and for backups.
- **Paying for upgrades:** buy each one through the entity that needs it, and record it in that entity's books (as with the Mac mini and Bridges), so each project shows its real costs and profit.

## Monthly costs and open decisions

Running costs come to roughly $60 to $145 a month at first, mostly your existing AI subscriptions, plus travel between Florida and PA and the cloud server once public services launch. The AI figure is your actual spend; the rest are estimates.

| Cost | Per month (USD) | Starts |
| --- | --- | --- |
| Electricity, machines running 24/7 mostly idle | 15 to 30 | Now |
| Encrypted off-site backup | 5 to 15 | With the Mac mini |
| Cloud server for public games | 5 to 20 | At public launch |
| AI subscriptions, current | 40 to 100 (peaked at 120 in two months since March 2026) | Already running |
| Hostinger (website) and Base44 (app) subscriptions | Paid by Bridges, not this budget | Already running; goes away once self-hosted |
| Travel RSW to PHL or ILG for hands-on work (est. 150 to 600 per round trip) | 25 to 150 averaged (300 to 1,800 a year after setup) | 1 to 2 trips during setup, then 2 to 3 a year |

**Bridges subscriptions are a long-term saving.** Bridges pays for Hostinger and Base44 today. Once the Mac mini can host the website, the app, and the Bridges brain and assistant itself, those subscriptions can be canceled. That switch waits until Bridges has the technical and security help described in Bridges guardrails, so plan on paying both for now.

**Travel stays planned, not urgent.** The travel estimate covers a round-trip flight from Fort Myers (RSW) plus bags and getting to and from the airports. The low end is a budget fare: Frontier has listed RSW to PHL one-way from $44, and Avelo flies RSW nonstop to Wilmington (ILG), which is closer to West Chester and among Avelo's cheapest airports. The high end is a mainstream fare: Southwest has shown $199 to $280 one-way, and American $421 to $539 round trip. Booking a few weeks ahead keeps trips near the low end. Your local techs handle emergencies (a stuck machine, a loose cable, a tripped breaker), so trips can wait for planned work like hardware upgrades. Three free settings cut emergencies further:

- Set the PC's BIOS to power back on after a power loss.
- Turn on "Start up automatically after a power failure" on the new Mac mini.
- Set the 2014 Mac mini to boot back into Linux and restart the desk with its own restart script; it starts frozen after an unclean shutdown, by design.

A short runbook for the techs (what to check, what never to touch, who to call) would make their visits faster.

### Year one running cost (West Chester, PA)

Running and managing the setup and the four projects for a year costs about $4,775 in the middle case, roughly $400 a month, with a range of $2,060 to $8,820. Travel and AI subscriptions are the biggest pieces; the projects' cloud services add about $790; electricity for everything 24/7 is about $230. One-time purchases (about $4,870 core, about $1,640 for the Fold) are not included. Updated October 30 from the four project updates.

| Cost | Low | Middle | High | Notes |
| --- | --- | --- | --- | --- |
| Electricity, all machines 24/7 | 140 | 230 | 405 | About 130 W average (PC 90 W, Mac mini 15 W, 2014 Mac mini 8 W, switch, UPS losses), about 1,160 kWh a year at 18 to 22 cents per kWh all-in |
| Off-site backup | 100 | 150 | 200 | Backblaze-style backup, about $99 a year per computer |
| AI subscriptions (already paying) | 480 | 840 | 1,440 | Your $40 to $100 a month; high end assumes $120 every month |
| Brain AI model (from Phase 2) | 0 | 150 | 600 | Not chosen yet; middle assumes a $25 a month cap for half the year |
| Fold phone line, Verizon family plan | 360 | 510 | 660 | $30 to $55 a month; add about $670 a year if the phone is financed |
| Travel RSW to PHL or ILG | 450 | 1,400 | 3,000 | 3 to 5 round trips in year one, $150 to $600 each |
| Supabase (Rewind Arcade and The Crease) | 0 | 420 | 420 | [Pro is $25 a month per organization](https://selfhost.dev/supabase-pricing-explained/), covering one project; a second project adds about $10. Free plan has no backups and pauses after 7 days unused |
| Rewind Arcade: Cloudflare Workers paid | 0 | 60 | 60 | About $5 a month, only if the preview load test needs it |
| The Crease: cloud services | 0 | 310 | 865 | Buffer ([free up to 3 channels, then $5 to $6 per channel a month](https://napoleoncat.com/blog/buffer-pricing/)), Cloud Run renders (up to your spending cap), OpenAI, and R2 storage ([10 GB free, then $0.015 per GB](https://developers.cloudflare.com/r2/pricing/)) |
| Hardware reserve | 100 | 175 | 250 | UPS battery, drives, fans, cables |
| Hub internet line (Verizon 5G Home) | 420 | 480 | 540 | Security segment: the hub's own line and backup, $35 to $45 a month with the Verizon line discount |
| Password manager and DNS filtering | 10 | 50 | 80 | Security segment |
| Local tech help | 0 | 0 | 300 | Placeholder; depends on what your techs charge |
| **Total** | **2,060** | **4,775** | **8,820** |  |

- **New spending versus what you already pay:** the AI subscriptions are already in your budget. Without them, the new yearly cost is about $3,935 in the middle case.
- **The projects' cloud services replace the old "cloud server for public games" line.** Rewind Arcade already runs on Cloudflare and Supabase, so no separate game server is needed. Sixes online testing runs on the PA PC.
- **The Crease's real number depends on two decisions you owe:** the cloud spending cap and the number of Buffer channels. The high column assumes about a $20 a month render cap, 5 Buffer channels and $20 a month of OpenAI use.
- **Trading Desk: $0 for now.** Paper trading on free market data; Gmail alerts are free. Paid data or account fees would come only with a live-trading decision.
- **Not counted:** your home internet (already paid), Tailscale and Discord (free tiers), and Hostinger and Base44 (paid by Bridges).
- **Electricity rate:** PECO's default supply price is [11.572 cents per kWh from June through November 2026](https://electricityrates.com/resources/peco-june-2026-rate-increase/); delivery charges add more on top. The all-in PECO average was [16.16 cents in 2024](https://www.electricchoice.com/electricity-prices-by-state/pennsylvania/philadelphia/), so 18 to 22 cents is the estimate for 2026.

**Open decisions:**

- [ ] Mac mini with 48 GB or 64 GB
- [ ] Two monitors now or three
- [ ] Who buys and owns the new Mac mini: decided. You buy it personally (the 6% sales tax in the total applies), and it gets recorded in Bridges' books later. Keep the receipt, ask Bridges' CFO whether it goes in as a donated asset or a reimbursement, and run personal projects under a separate macOS user so Bridges' files stay apart.
- [ ] How much RAM the 2014 Mac mini has (8 GB or more is enough for the desk)

### Sources

- [Mac mini M5 Pro configurations and prices (refurb.me)](https://www.refurb.me/stats/mac-mini/mac-mini-m5-pro-late-2026)
- [Mac mini M5 Pro 64 GB model fit (aiindigo)](https://aiindigo.com/hardware/apple-mac-mini-m5-pro-64gb)
- [64 GB DDR4 prices (DataCenterDisk)](https://datacenterdisk.com/ram/ddr4/64gb)
- [Intel 14th gen prices (Walmart)](https://www.walmart.com/c/kp/intel-processor-gen)
- [Micro Center i7-14700K deal (Slickdeals)](https://slickdeals.net/f/19868634-micro-center-intel-core-i7-14700k-3-4ghz-cpu-star-wars-galactic-racer-tomb-raider-legacy-of-atlantis-pc-games-270-free-store-pickup-269-99)
- [SSD prices 2026 (Capital and Compute)](https://capitalandcompute.net/ssd-prices/)
- [SSD and hard drive prices (MaxMyBuild)](https://www.maxmybuild.com/storage/prices)
