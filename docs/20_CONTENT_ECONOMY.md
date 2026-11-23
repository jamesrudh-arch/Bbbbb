# LEVERAGE — Content Economy & Replayability
### How the game lasts 40 hours instead of 2
*23 Nov 2026 · design document, prior to implementation*

---

## THE PROBLEM, STATED HONESTLY

Right now the game has:

| Thing | Count | Minutes of play |
|---|---|---|
| Story missions | 12 | ~35 (and 6 are stubs) |
| Side jobs | 3 | ~8 |
| Interiors | 8 | ~10 |
| **Total** | | **~50 minutes of authored content** |

Your brief asks for GTA V, Cyberpunk, RDR2. Those are 50–100 hour games.

You cannot close that gap by writing missions one at a time. **50 hours of hand-authored missions is more content work than every other system in this project combined, multiplied.** The way real open-world games get there is four content engines that *multiply* a modest amount of authored material.

---

## THE FOUR ENGINES

| Engine | What it is | Why it scales |
|---|---|---|
| **1. AUTHORED** | Story missions, cutscenes, set-pieces | Fixed cost, highest quality. Use sparingly for the spine |
| **2. PROCEDURAL** | Contracts, rings, races, bounties — generated from templates × district × faction × complication | **One system → dozens of jobs.** This is the workhorse |
| **3. EMERGENT** | Street events, territory shifts, police escalation, NPC reactions | **Infinite.** Costs nothing per play; the city generates its own stories |
| **4. MASTERY** | Style Rank, fight scoring, build variety, speedrun routes | **Infinite.** Costs nothing per play; players replay content they already beat |

**The design rule: every hour of authored content must be wrapped in a system that multiplies it.**

---

## TARGET CONTENT VOLUME

### Authored (the spine)

| Content | Now | Target | Notes |
|---|---|---|---|
| **Story chapters** | 1 | **12** | Prologue + 11. Each ~40–70 min |
| **Story missions** | 12 | **36** | 3 per chapter: setup, execution, twist |
| **Major cutscenes** | 0 | **18** | Opening, betrayals, reveals, ending |
| **Named characters with full arcs** | 4 | **16** | All 16 cast must have a relationship arc |
| **Factions** | 4 | **6** | +2: a cartel, and the state itself |

**Story length target: 9–11 hours** (GTA V is ~32h main; Mafia: DE is ~15h). 10 hours of story is a serious, complete crime drama — and it is achievable.

### Procedural (the volume)

| System | Now | Target | Playtime |
|---|---|---|---|
| **Faction contracts** | 0 | 6 factions × 8 = **48 jobs** | 6–8 h |
| **Fight rings** | 0 | 7 venues × 5 tiers = **35 fights** | 4–5 h |
| **Street races** | 0 | 7 districts × 3 classes = **21 races** | 2–3 h |
| **Bounty targets** | 0 | **21 named criminals** | 3–4 h |
| **Smuggling runs** | 0 | **12 cargo runs** (Dockside) | 2 h |
| **Heists** | 0 | **6** — one per faction, multi-stage with planning | 4–6 h |

### Emergent (the life)

| System | Target | Playtime |
|---|---|---|
| **Street event types** | **24** distinct events | infinite |
| **Territory control** | 7 districts shift ownership | infinite |
| **Dynamic crime** | Robberies, chases, shootouts happen without you | infinite |
| **NPC schedules** | Every pedestrian has a day | infinite |

### Mastery (the hook)

| System | Target |
|---|---|
| **Style Rank** | D → SSS, pays up to 3.5× |
| **Discipline skill trees** | 5 trees × 8 nodes = 40 unlocks |
| **Weapon upgrades** | 3 tiers × 22 weapons |
| **Vehicle tuning** | engine / tyres / brakes per class |

### Totals

| Play style | Hours |
|---|---|
| Story only, rushing | ~10 |
| Story + a bit of side content | ~18 |
| Story + all factions + rings + races | **~32** |
| 100% completion | **~45** |
| Post-story free play (territory, ranks, mastery) | **unbounded** |

---

## ENGINE 2 IN DETAIL — how procedural content actually works

### A. FACTION CONTRACTS

A contract is generated from **four axes**, not written by hand:

```
TEMPLATE  ×  DISTRICT  ×  FACTION  ×  COMPLICATION
```

- **Templates (8):** Retrieve · Eliminate · Escort · Sabotage · Extort · Steal · Rescue · Deliver
- **Districts (7):** changes route, crowd density, police response, escape options
- **Factions (6):** changes target type, dialogue, opposition archetype, payout, reputation
- **Complications (12):** the target is armed · police are watching · rival crew already there · time limit · no weapons · witness clause · the package is a person · double cross

**8 × 7 × 6 × 12 = 4,032 distinct configurations.** Curated and gated by faction standing, this yields ~48 hand-picked-feeling jobs from one system.

**The trick that makes it not feel generated:** every contract gets a *written one-line brief* and a named target drawn from the cast. "Kola wants the Saturday Ledger back before his mother sees it" reads authored even when the mission geometry is assembled.

### B. FIGHT RINGS — the combat replay engine

Seven venues, one per district, each with a distinct crowd and ruleset:

| Venue | District | Rules |
|---|---|---|
| The Basement | Ash Row | Straight hands. No weapons |
| The Long Table | Guttermarket | Weapons allowed (pipes, bats) |
| Crucible | Iron Yard | No rules. 3 on 1 |
| Platform 4 | Railhead | Time limit — 90 seconds |
| The Glass Room | Vesper Heights | Disciples only. No damage taken = bonus |
| Velvet Pit | Neon Mile | Crowd bets. Style Rank doubles points |
| The Docks | Dockside | Environmental kills give 3× |

Each venue: **5 tiers** of escalating opponent quality (Rookie → Elite), a **named champion** at tier 5 who has a unique fighting style, and a **purse**. Winning all 7 champions unlocks an eighth, hidden venue.

**35 fights, each 60–120 seconds, all replayed for rank.** This is the single cheapest source of hours in the game, and it directly serves the Sifu/Sleeping Dogs reference.

### C. STREET RACES

7 districts × 3 classes (car, bike, street) = **21 races**. Routes generated from the existing road graph — which already exists and works. Rivals have names, vehicles and personalities. Winning unlocks vehicle parts.

### D. BOUNTIES

21 named criminals across 7 districts — 3 per district, escalating. Not procedurally generated positions: **each is a small authored encounter** with a briefing from a contact, a hideout, a personality trait, and a choice (kill, capture, or let walk for information). Sourced from a "LEVERAGE FILE" briefing on the phone.

---

## ENGINE 3 IN DETAIL — the city generates stories

### STREET EVENTS (24 types)
Randomised but context-aware. They fire near the player, respect district and time, and never repeat within 20 minutes:

Robbery in progress · mugging · car theft · police checkpoint · rival gang shake-down ·
street fight · someone calling for help · a body · a deal going wrong · a pursuit passing through ·
a fire · a broken-down car needing help · a pickpocket · a drunk starting trouble ·
an argument turning violent · a courier dropping a package · a hit being carried out · a chase on foot ·
protesters · a lost child · a dogfight · a street preacher · a deal being offered · a suspicious van

Each has **at least two resolutions** — intervene, ignore, exploit. Intervening has consequences (police heat if you fight, faction trust if you help the wrong side).

### TERRITORY CONTROL
Each of the 7 districts has a controlling faction. Control shifts based on:
- Contracts you complete (your employer gains)
- Fights you win in a ring
- Bounties removed
- Story events

**The city map visibly changes.** A district under Iron Yard control gets more workers and fewer police. Under the corporation, more security and clean streets. This is infinite content: the board keeps moving, and the player can push it.

### NPC SCHEDULES
Every pedestrian archetype has an hour-by-hour day:
- 06:00–09:00 commute · 09:00–17:00 at a workplace interior · 17:00–20:00 shops/food · 20:00–02:00 entertainment (district dependent) · 02:00–06:00 sparse

With reactions already specified (panic at gunfire, witness reporting, sidestep, shelter from rain), a district becomes a living thing at almost no authoring cost per hour.

---

## ENGINE 4 IN DETAIL — MASTERY

### THE LEVERAGE FILES ⭐ (the thematic collectible)

The game is called LEVERAGE. So the collectible should *be* leverage.

**70 files across the city** — inside apartments, on desks, in glove boxes, behind bars, in police evidence. Each is a **secret about a named person**:

> *"SUNDAY — hides a second family in Dockside. Pays their rent in cash."*
> *"ADEYEMI — the brother's debt is signed with a name he doesn't recognise."*
> *"OKAFOR — the corporation paid a police captain's mortgage in 2019."*

**Three uses, all real:**
1. **Blackmail** — reduce heat instantly, once per file
2. **Trade** — sell to a faction for money and standing
3. **Unlock** — some files open doors: shortcuts, safehouse access, a new contract

This single system carries the game's thesis: *everybody has something on you.* It gives exploration purpose, ties collectibles to story, and gives the player a resource that feels like power.

---

## UPGRADES TO WHAT ALREADY EXISTS

Not just new content — the existing systems need depth to carry 40 hours.

| System | Current | Upgrade |
|---|---|---|
| **Weapons** | 7 | **22** — pistols, SMGs, shotguns, rifles, melee, throwables, each with 3 upgrade tiers |
| **Vehicles** | 8 types | **24** — sedans, muscle, sports, SUVs, vans, trucks, bikes, boats (Dockside), each with handling and damage |
| **Interiors** | 8 | **26** — add foundry, police station, hotel, club back-rooms, apartment blocks, warehouses, market halls |
| **Pedestrian roles** | 6 | **18** — each with dress, schedule, and reaction profile |
| **Enemy archetypes** | 1 | **12** — see below |
| **Safehouses** | 0 | **7** — one per district, purchasable, upgradable (weapon locker, wardrobe, garage, rest bonus) |
| **Disciplines** | 5 (one code path) | **5 real trees × 8 nodes** |

### The 12 enemy archetypes

The brief demands varied enemies. One body with one script is the current state. Twelve archetypes, each with distinct silhouette, behaviour and counter-play:

| Archetype | Behaviour | Counter |
|---|---|---|
| **Rookie** | Panics, misses | Anything |
| **Brawler** | Charges, grapples | Kickboxing range |
| **Boxer** | Guard-heavy, counters | Grappling breaks guard |
| **Kickboxer** | Long range, kicks | Close in fast |
| **Wrestler** | Shoot for takedowns | Weapon reach |
| **Knife** | Fast, bleeding damage | Weapon discipline |
| **Bat** | Heavy swing, telegraph | Dodge + punish |
| **Armed guard** | Arms, fires from cover | Flank, disarm |
| **Shooter** | Cover, suppress, reload | Environment, angle |
| **Sniper** | Long range, single shot | Get close fast |
| **Bulwark** | Armoured, ignores light hits | Grapple + throws |
| **Elite** | Flanks, calls help, retreats when hurt | Everything |

Each faction draws from a different subset — the corporation uses guards and snipers, the crew uses brawlers and knife-work, the docks use wrestlers.

---

## WHAT I WOULD *NOT* BUILD

Scope discipline is what separates shipping from not shipping. Cuts, with reasons:

| Cut | Why |
|---|---|
| **Boats as a full system** | Dockside needs *a* boat route; a full water traffic sim is a whole sub-game. One smuggling boat, no citywide water sim |
| **Planes / aircraft** | Brief doesn't require it. Enormous cost |
| **Property empire / business ownership** | Passive income is a spreadsheet, not fun. Safehouses deliver the same ownership feeling cheaper |
| **Full weapon customisation (Breakpoint-grade)** | 3 tiers per weapon gives 90% of the feeling at 10% of the cost |
| **Dynamic weather damage to the city** | Already have weather; destruction of the world is a physics budget killer |
| **Voice acting for all dialogue** | Not feasible at this target. Text dialogue + a small set of barks and grunts + music does the emotional work |

---

## BUILD ORDER FOR CONTENT

The engines multiply, so build them in dependency order:

| Phase | Builds | Unlocks |
|---|---|---|
| **A** | Enemy archetypes + AI state machine | Fight rings, bounties, all combat content |
| **B** | Style Rank + discipline trees | Mastery replay of everything |
| **C** | Contract generator + fight rings + races | ~30 hours of procedural content |
| **D** | Street events + territory + schedules | Emergent life |
| **E** | Story chapters 2–12 | The spine |
| **F** | Safehouses, leverage files, economy depth | Progression |
| **G** | Bounties, heists, smuggling | Late-game goals |

**Phase C is the pivot.** Everything after it inherits 30 hours of play from four systems.

---

## THE HONEST CAVEAT

Nine to eleven hours of authored story plus six heists plus 48 contracts is a **large** amount of work — realistically many times what has been built so far. That is not a reason to shrink the ambition; your brief is explicit about it. It is a reason to build **C first** (the multiplier) rather than chasing story missions one at a time.

The right sequence is not "write mission 3, then mission 4." It is:
**make enemies worth fighting → make fighting worth repeating → give the city things to generate → then spend the authored mission budget on the moments that deserve it.**
