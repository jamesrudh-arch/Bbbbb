# LEVERAGE — Scale, Difficulty, Multiplayer & Onboarding
### Response to the direction brief, 23 Nov 2026

---

## 1. RAISING THE CEILING — everything ×1.5–2

The previous document set targets. This raises them, and adds the systems that *generate* difficulty rather than just adding more of the same.

| Content | Previous | **Now** |
|---|---|---|
| Story chapters | 12 | **16** |
| Story missions | 36 | **48** |
| Faction contracts | 48 | **72** |
| Fight ring venues | 7 | **8** (7 + hidden final) |
| Ring tiers per venue | 5 | **6** |
| Ring bouts total | 35 | **48** |
| Street races | 21 | **28** |
| Bounty targets | 21 | **28** |
| Heists | 6 | **8** |
| Street event types | 24 | **36** |
| Leverage Files | 70 | **100** |
| Enemy archetypes | 12 | **16** |
| Weapons | 22 | **30** |
| Vehicles | 24 | **32** |
| Interiors | 26 | **34** |
| Pedestrian roles | 18 | **24** |
| Factions | 6 | **7** |
| Disciplines | 5 | **6** (add **Silat**) |
| Safehouses | 7 | **8** |

**Revised target: 45–60 hours to completion. Unbounded after.**

The two additions that matter most:
- **Chapter 0 "Ash"** — a fully playable prologue set 6 years before. Teaches everything in-world, no tutorial text.
- **New Game+** — carry weapons and disciplines into a harder city where factions remember you.

---

## 2. DIFFICULTY THAT ASCENDS WITH THE PLAYER

The brief asks for difficulty that rises as the player advances. Not a menu slider — a **world that grows teeth**.

### The five axes

| Axis | How it scales | Player-visible |
|---|---|---|
| **District heat** | Each district has a danger tier 1–5 that rises as you work there | More police, more armed opposition, higher value targets |
| **Faction pressure** | Pissing off a faction raises *their* archetype quality against you | Elites instead of rookies in their territory |
| **Notoriety** | Global reputation level unlocks tougher contracts | Contract difficulty bands |
| **Story escalation** | Chapters 1–16 step up enemy quality, weapons, tactics | Auto — the story carries it |
| **Adaptive skill** | Tracks your Style Rank average and death rate | Invisible, gentle. Raises aggression, not stats |

### The critical rule
**Difficulty changes behaviour, not health bars.** A hard enemy is *smarter* — flanks, calls help, reloads behind cover, retreats when hurt. Never a bullet sponge. This is what separates Sifu from a bad action game.

### Enemy skill tiers (each archetype has all 6)
1. **Rookie** — panics, 0.9s reaction, misses
2. **Street** — 0.6s, basic combos, blocks sometimes
3. **Veteran** — 0.4s, uses cover, reloads in cover
4. **Hardened** — 0.3s, flanks, breaks grabs
5. **Elite** — 0.2s, calls help, retreats when losing
6. **Named** — unique moveset, dialogue, a name you remember

---

## 3. MULTIPLAYER — the honest answer

You asked for players to join in, or fight each other. **I can build it, and here is exactly how — but you need one fact first.**

### The fact
Godot's own high-level multiplayer needs an external service to relay traffic between phones (a relay server or a hosted lobby). There is no free, reliable, zero-setup peer-to-peer path between two iPhones. **That means multiplayer requires a backend you own** — a small server, plus a domain. It is not a code problem, it is an infrastructure and cost problem.

### What I can build without that
These work **with no server at all** — one device, no network:

| Mode | What it is | Value |
|---|---|---|
| **Ghost Records** | Your best fight runs replay as a visible rival ghost you race against | High, zero cost |
| **Fight Ring Leaderboards (local)** | Personal bests per venue, per style rank | Medium |
| **Hot-seat Duels** | Pass the phone — two fighters, split-screen style bouts | Medium, cheap |
| **Time Attack** | Races/contracts against your own best time and score | High, zero cost |

### What requires a server
| Mode | Requirement |
|---|---|
| **Co-op contracts** (2 players, one city) | Relay server, ~$5–15/mo |
| **1v1 PvP duels** (fight ring, locked arena) | Relay server |
| **Shared city presence** | Relay server + state sync |

### My recommendation
**Split-screen local duels ship first** (real multiplayer feel, no server, no cost, works on one iPhone). Then a **relay server for 1v1 duel mode only** — the smallest possible networked surface. Do **not** attempt open-world co-op: syncing traffic, police, crowds and NPCs across two devices is a different order of engineering and would consume the entire project.

**A note on the App Store:** online multiplayer with player-to-player communication can trigger Apple's user-generated-content requirements (reporting, blocking, moderation). A duel mode with no text chat avoids this almost entirely. That's another reason duels-first is correct.

---

## 4. THE MAP — GTA-style navigation

You're right that this is the difference between "I don't know where I'm going" and feeling oriented from minute one.

### What exists
A full-screen map with districts, landmarks, route-following, live player arrow, fog of war. **That part is real and works.**

### What's missing — and this is the big one
**There is no minimap during gameplay.** The variable is declared in `hud.gd` and nothing ever fills it. A `route` accessor exists too, but the HUD never draws it.

### What to build

**A. The live minimap** (top-left, always on)
- Circular, top-down, follows the player
- Roads, blocks, water (Dockside)
- Player arrow rotating with facing
- **Live blips:** mission marker (gold), safehouse (blue), shop (green), ring venue (red), bounty (orange), police (blue flashing), phone call source (cyan)
- Automatically rotates with camera heading
- Zoom in when on foot, out when driving fast

**B. The GPS route on the *road*, not just the map**
- A **glowing gold line painted on the asphalt** along the route
- **Turn arrows** appear early — 30 m before a junction
- **Distance counter** in the HUD: `412 m · 1m 20s`
- Route **recalculates** when you leave it (off-route detection within 12 m)
- Route respects vehicle: cars take main roads, on foot may cut through

**C. Waypoints**
- Tap anywhere on the map → sets a custom waypoint
- Multiple simultaneous markers (mission + waypoint + shop)
- Clear all via long-press

**D. The "you don't know your way around" fix**
Three onboarding layers:
1. **Chapter 0 teaches the city by walking it** — Ngozi's kitchen is 90 m away, and the minimap shows exactly how
2. **Street name banners** appear at district entry (already partially there)
3. **Landmarks are visible from the street** — a crane, a tower, a neon sign. You learn a city by its silhouettes, not its map

---

## 5. THE OPENING — intro + immediate gameplay

Your note: *"it should have a little gameplay at the beginning, not just direct to the game."*

### The first ten minutes, revised

| Time | Beat |
|---|---|
| **0:00** | Black. Rain on zinc. A radio: *"…body found near the rail platform. Police are not releasing a name."* |
| **0:08** | **D'YOUNGS GAMES** — the 3D mark assembles from ash, a gold sweep crosses it |
| **0:14** | **LEVERAGE** — title, ash drifting, *EVERYBODY HAS SOMETHING ON YOU* beneath |
| **0:22** | **Content notice** — one line, dignified, dismissible (maturity/terms, App Store requirement) |
| **0:26** | **CINEMATIC (60 s)** — Cinder City at dawn. A bus. Marcus's hands. A folded letter. ₦120. Nine days of missed calls. Real camera direction: slow dolly, rack focus |
| **1:30** | **CUT TO PLAYABLE.** He steps off the bus. No UI clutter. One prompt: *Walk.* |
| **1:45** | **Movement taught by doing** — walk a block, the camera swings, the city breathes |
| **2:20** | Ngozi's kitchen. Steam, warm light, a plate. She tells him about Chidi |
| **3:20** | **FIRST FIGHT** — two men burning his brother's ledger pages behind the bar |
| **3:30** | **Combat taught in the fight itself** — punch, heavy, kick, dodge. No tutorial boxes |
| **4:30** | Style Rank appears and names you: *"D — DEAD WEIGHT"* |
| **5:00** | **The phone rings.** Answer / decline. Real ringtone |
| **6:00** | **Sirens** — first heat, first chase on foot |
| **7:30** | Escape. Rain starts. Neon on wet asphalt |
| **8:30** | **Free roam unlocked.** Full map opens. Six districts lit, two fogged |
| **10:00** | **Chidi's captors call.** Chapter 1. |

Nobody puts it down at ten minutes.

---

## 6. NPCS THAT ACTUALLY CONVERSE

This is the system that makes a city feel populated instead of decorated.

### What exists
25 wanderers. They cannot talk, react, or hold a conversation.

### The conversation system

**A. Ambient barks** (contextual one-liners, positional audio)
- Greetings by relationship and district
- Reactions to: seeing a gun, being bumped, noticing you're hurt, seeing you fight, watching you drive badly
- Street vendors call out their goods; market traders haggle with each other
- 8–12 lines per pedestrian archetype, voiced or shown as subtitles

**B. Full conversations** (branching, for 16 named characters)
- A dialogue panel: speaker portrait, name, text
- 2–4 response options, each with a **tag** — `[Ask]` `[Threaten]` `[Lie]` `[Charm]` `[Leave]`
- Tags matter: `[Threaten]` raises fear and drops trust; `[Charm]` can flip a hostile NPC to neutral. Some options are locked by weapon, faction standing, or a Leverage File
- Every named character has: a **greeting**, **3 conversation topics** that open as the story progresses, and **reactive lines** about recent events

**C. Pedestrian-to-pedestrian conversation**
Walking NPCs pause to talk to each other — two-person conversations with mouths moving and gestures. This alone doubles the perceived life of a street.

**D. Reactions that matter**
- Witness a crime → calls police after 8s, becomes a `witness` you can intimidate
- Gunfire → panic radius 25 m, screaming, fleeing to doors
- You sprint past → sidestep
- Bump them → stumble, dust off, curse
- Police pursuit → street clears, shutters drop

---

## 7. WHAT THIS ALL MEANS FOR THE BUILD ORDER

Multiplayer is not a v1.0 item. It is a v1.1 with a server. The rest is core.

| Order | Work |
|---|---|
| **1** | **The opening** (logo → title → cinematic → playable) — the first thing anyone sees |
| **2** | **Minimap + on-road GPS** — the thing that fixes "I don't know where I'm going" |
| **3** | **Enemy archetypes + AI** — the wall between prototype and game |
| **4** | **Feel** (hit stop, Style Rank) |
| **5** | **NPC conversation + barks** |
| **6** | Contracts, rings, races — the content engines |
| **7** | Ascending difficulty tuning |
| **8** | Local split-screen duels |
| **9** | Relay server, 1v1 PvP |

---

## DECISIONS NEEDED

1. **Multiplayer** — is local split-screen duels (no server, ships this year) enough for v1, or must it be online from the start? If online: I need a server and a domain, and it changes the schedule substantially.
2. **Server budget** — if online: roughly $5–15/month for a small relay. Confirm.
3. **New discipline** — I propose **Silat** as the 6th (Southeast Asian, flows into throws and joint locks, distinct from the other five). Yes or a different one?
4. **Content ceiling** — the ×1.5–2 raise above means roughly 45–60 hours. Confirm that's the target, because it sets every prior.
