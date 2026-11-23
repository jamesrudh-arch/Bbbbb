# CINDERFALL — Vision & Engagement Plan
### D'Youngs Games · Development direction document
*Written 23 Nov 2026. This is a decision document, not a task list. Nothing in it is coded yet.*

---

## PART 0 — The honest audit

You asked if the game is "set, 10/10". Here is the real answer, measured against the code, not against a checklist.

### The numbers

| Thing | Reality |
|---|---|
| Total game code | **8,066 lines** across 39 scripts |
| Trees | **Zero.** No tree code exists anywhere in the project |
| Crowd | **25 pedestrians** that wander and nothing else. No fear, no reaction, no witnesses |
| Enemy AI | **3 states** — idle, wander, chase. No cover, no flanking, no reloading, no retreat |
| Combat | **239 lines.** 5 discipline names exist; the disciplines are mostly one shared code path |
| Police | **92 lines.** Spawns units near you at a heat threshold |
| Traffic | **46 lines** |
| Missions | **146-line manager**, 12 mission definitions. Several objective types are stubs |
| Vehicles | **7 Kenney models, ~2,000 triangles each.** Placeholder grade |
| Characters | **3 hero-quality models** for a cast of 16 |

### Verdict per thing you named

| Your item | Working? | Truth |
|---|---|---|
| **Player** | ✅ Mostly | Moves, sprints, crouches, dodges, jumps, drives, fights. This is genuinely solid and worth keeping |
| **Enemies** | ⚠️ Barely | They walk at you and swing. They do not fight *you*. No tactics, no personality, no danger |
| **Missions** | ⚠️ Half | 12 written. Reading one aloud takes 20 seconds; *playing* one takes 4 minutes because most objectives resolve to "walk to a point" |
| **Crowd** | ❌ **No** | It is set dressing. It cannot react to anything |
| **Trees** | ❌ **Zero** | They do not exist. Not badly made — absent |
| **Houses** | ⚠️ | Block-shaped buildings with windows and shopfronts. Recognisable, not believable. 8 enterable interiors exist and work |
| **Is it a 10/10 game?** | ❌ **No** | It is a **working prototype with good bones.** Roughly 30% of a vertical slice. The *systems skeleton* is real; the *game* is not there |

### What is actually good — protect this

I am not going to pretend it is all broken, because it isn't, and I'd be lying to you:

- **Movement and camera** feel right. Third-person framing is correct, acceleration is smooth.
- **The city generator** is genuinely well built — a real street grid, block system, batching (17,087 → 7,474 objects), PBR materials.
- **The phone** works end to end. Rings, answers, conversations, messages, missed calls, scheduling.
- **The map** is real. Zoom, route-following, player position, fog.
- **8 enterable interiors** with vendors, lights, buying.
- **Character animation** is real Mixamo-quality motion, retargeted properly.

That is a foundation most projects never reach. **It is not a game yet.**

### The thing nobody has said out loud

A checklist of features is not engagement. You can build every bullet in your spec document and still have something people put down after nine minutes. What people can't resist is **feel** — how a punch lands, how the music hits when the rank climbs, how the world reacts when you do something insane.

This document is about *that*.

---

## PART 1 — Identity

### 1.1 The studio: D'Youngs Games

There is currently no logo. There is no intro. The game starts at a menu.

**The mark:** a monogram **D·Y** cut from one piece of dark gunmetal, with a gold bevel inlaid along the cut. Two clean forms that interlock — the D's bowl cradling the Y's stem. It reads as a stamp, a seal, a hallmark. Something a city would put on its currency.

**The reveal (4.2 seconds):**
1. Black. A single low sub-bass note.
2. Ash particles drift in and *converge* into the monogram silhouette.
3. The metal resolves — a warm gold light-sweep travels across the bevel, left to right.
4. "D'YOUNGS GAMES" typesets beneath in wide-tracked uppercase.
5. Dust falls away. Cut to title.

Built as real 3D geometry in Godot with a PBR gold material — not a flat PNG. It will animate in-engine, and it is the first thing every player sees.

### 1.2 The game name

**Current: LEVERAGE.** Problems: it is a common English word; it is a 2008 television series; it says nothing about this world or this city; it does not sound like a place you want to spend forty hours.

**Requirements for a world-class title:** one word (or two), reads on a box, sounds like a place, hints at the story, survives being said out loud in a trailer.

| Candidate | Why it works | Risk |
|---|---|---|
| **CINDERFALL** ⭐ | The city is Cinder City. The city is built on ash and burning. One word, cinematic, grand. Reads like a AAA title. Gives the world a name. | — |
| **CINDER CITY** | Place-first, instantly understood, GTA-style. | Slightly plain |
| **THE LEDGER** | The torn ledger is the story's spine. Crime-thriller, film-like, elegant. | Less memorable in a store |
| **LEVERAGE: CINDER CITY** | Keeps your name, adds the world. | Keeps the generic problem |

**My recommendation: CINDERFALL.** — *"CINDERFALL — A Cinder City Story."* The city has a name, the game has a name, and the two reinforce each other forever.

### 1.3 The city: Cinder City

A fictional West African metropolis. Ash-grey concrete, gold light, red dust after rain, zinc roofs, generators that stutter at 7pm, a rail line that cuts the city in half.

**District naming fix required:** the district *Cinder Line* collides with *Cinder City*. Rename to **RAILHEAD**.

| District | Role | Architecture | Light & sound | Landmark | Signature |
|---|---|---|---|---|---|
| **Ash Row** | Home. Family. Poverty with dignity | Low walk-ups, zinc roofs, laundry lines, painted walls faded to bone | Warm sodium, radio, chickens, arguing | Ngozi's Kitchen | Safest place. Cops here know your mother |
| **Guttermarket** | Commerce. Chaos. Everything for sale | Dense stalls, awnings, tarpaulin, open drains, hanging goods | Daylight through cloth; hawkers, haggling, generators | The Long Table | Crowd density 3×. Pickpockets. Best place to vanish |
| **Iron Yard** | Industry. Muscle. Dead ends | Sheds, containers, cranes, rust, chain-link, gravel | Cold mercury light, machinery hum, sparks | The Foundry | Crafting, weapon mods, arena fights |
| **Railhead** | Transit. Transit crime. Leaving | Station halls, freight yards, signal towers, sleepers | Green signal light, horns, rain on steel | Platform 4 | Fast travel + smuggling runs |
| **Vesper Heights** | Money. Power. The people who own you | Towers, glass, private roads, clean pavement, manicured green | Blue-white, quiet, distant sirens, glass doors | The Vesper Tower | Heists. Security. The story's endgame |
| **Neon Mile** | Night. Pleasure. Danger | Clubs, hotels, neon signage, wet asphalt, valet stands | Magenta/amber neon, bass bleed, laughter | The Velvet Room | Nightlife, gambling, highest heat |

---

## PART 2 — Why nobody will put it down

Four loops, nested. Each one feeds the next. This is the difference between a feature list and an addiction.

### LOOP 1 — The second (feel)

Every single interaction must feel expensive.

**Punching:** For every hit that lands —
- **Hit stop.** The game freezes for 60–120 ms, scaled to damage. Heavy hits freeze longer.
- **Camera.** Impulse shake, amplitude 0.15, decaying over 0.4 s. Heavy hits punch the FOV out by 4° and snap it back.
- **Impact.** Spark burst + dust + blood mist, in the direction of the blow.
- **Sound.** Three layers, always: the whoosh, the impact thud, the bone crack.
- **The enemy reacts.** Recoil displacement, hit-reaction animation, stagger meter fills.

**The rule:** if a player hits someone and the screen does not acknowledge it, the game has failed at that moment regardless of everything else.

### LOOP 2 — The fight (the hook)

**THE STYLE RANK.** This is the single most important addition in this document.

A rank meter lives top-right, always visible in combat. It climbs as you fight and decays if you stall.

```
D  DEAD WEIGHT     → start
C  CORNER BOY
B  BAD INTENTION
A  SERIOUS
S  SOVEREIGN
SS NO WITNESSES
SSS CINDER SAINT   → gold, screen edges burn, music gains a choir
```

**It climbs** for *variety*, not repetition: switch disciplines mid-combo, perfect dodge (within 0.18 s of being hit), counter, finisher, environmental kill, taunt.
**It falls** 1 rank after 6 seconds without a hit; **2 ranks instantly** when you get hit.
**It pays.** Rank at mission end multiplies the payout: D = 1.0×, C = 1.3×, B = 1.6×, A = 2.0×, S = 2.6×, SS = 3.0×, SSS = 3.5×.

Why this works: it converts every fight from "something in the way" into **a performance you are being scored on**. Players will replay fights they already won just to get the SSS. That is the loop that keeps a game installed.

### LOOP 3 — The job (the hour)

Every job pays in **three currencies**, not one:
- **Money** — buys weapons, clothes, cars, safehouses
- **Reputation** — six factions, each with a standing. Faction A stops selling to you if you keep working for faction B
- **Heat** — police attention. Never fully resets. It colours the next hour

Every job therefore has **a consequence**, not just a reward. That is what makes a choice feel real.

### LOOP 4 — The world (the week)

Things happen **without you**: calls from contacts, police patrols that change with heat, weather, market days, a body found near the platform on the radio, a district that goes quiet after a shooting. The city needs you to believe it runs while you are not looking.

---

## PART 2B — The first ten minutes

This is the most important script in the game. It decides whether anyone is still playing at minute eleven.

| Time | What happens |
|---|---|
| **0:00** | Black. Rain on zinc. A radio newsreader: *"…the body found near the rail platform. Police are not releasing a name."* |
| **0:08** | **D'YOUNGS GAMES** — 3D logo assembles from ash |
| **0:14** | **CINDERFALL** — title, ash drifting across the letterforms |
| **0:22** | Cinematic. A bus pulls into Ash Row at dawn. Emeka's hands. A folded letter. ₦120 in his pocket. Twenty seconds of no dialogue — just the city breathing |
| **1:10** | **CUT TO PLAYABLE.** He steps off. No UI clutter. One prompt: *Walk.* |
| **1:40** | Ngozi's kitchen. Warm light, steam, a plate. She gives him the problem: Chidi owes ₦4.2 million |
| **2:30** | First objective: three torn ledger pages. One is being burned behind the bar by two men |
| **3:20** | **FIRST FIGHT.** Taught through the fight itself — punch, heavy, kick, dodge. The rank meter appears and names you: *"D — DEAD WEIGHT"* |
| **4:30** | You win. Music swells. Graded *"B — BAD INTENTION"*. Money bursts from the body |
| **5:00** | **The phone rings.** Real ringtone. ANSWER / DECLINE |
| **6:00** | Sirens — you just fought in the street. First heat. First chase, on foot, over zinc roofs |
| **7:30** | You lose them. Rain starts. Neon on wet asphalt |
| **8:30** | **Free roam unlocked.** Map opens, six districts — one is fogged |
| **10:00** | Chidi calls. Chapter 2 is waiting. |

Nobody stops at minute ten.

---

## PART 2C — Combat: the DMC × Mortal Kombat × Arkham fusion

**The killer feature: disciplines are stances you switch mid-combo.** Not classes you pick at a menu — you *flow* between them in a single string. That is Devil May Cry's weapon-switching, applied to hand-to-hand.

| Discipline | Identity | Why you switch to it |
|---|---|---|
| **Brawler** | Heavy, grounded, brutal | Breaks guards, high damage, slow |
| **Kickboxing** | Fast, range, footwork | Keeps distance, launches, best for groups |
| **Grappling** | Throws, joint locks, control | Beats armoured enemies; environment kills |
| **Drunken** | Unpredictable, evasive, humiliating | Perfect dodges; counters that reverse damage |
| **Weapon** | Reach, lethality, risk | Disarms, executes; slower recovery |

**Layered on top:**
- **Launchers + air juggling** — knock an enemy up, keep them in the air with a 4-hit string. DMC's signature.
- **Finishers** — when an enemy is stunned, one button starts a 2-second cinematic execution with a camera swing. Mortal Kombat's payoff, without the gore rating problem.
- **Parry window** — 0.18 s. Landing it flashes the screen white, freezes, and refunds stamina. Skill expression.
- **Counter chains** — parry → throw → strike, chaining across multiple enemies. Arkham's freeflow, but earned.
- **Enemy design forces switching:** armoured (needs grapple), fast (needs kickboxing), armed (needs weapon or disarm), shielded (needs kicking from behind).

### Enemy AI — the full specification

The current 3 states are the single biggest gameplay failure. Enemies must *fight you*.

**States:** idle · patrol · alert · investigate · spot · approach · **flank** · **cover** · aim · fire · **reload** · suppress · charge · grapple · stagger · **retreat** · injured · **call help** · downed · flee

**Squad roles** (assigned on spawn, broadcast to each other):
- **Leader** — hangs back, calls reinforcements, directs
- **Bruiser** — closes distance, grapples, takes hits
- **Shooter** — uses cover, aims, reloads, suppresses while others move
- **Runner** — flanks, cuts off escape, punishes backing into corners

**Skill tiers** (visible in how they carry themselves):
- **Rookie** — 0.9 s reaction, misses, panic-fires
- **Veteran** — 0.4 s, uses cover, reloads in cover
- **Elite** — 0.2 s, flanks, breaks grapples, calls help when hurt, retreats when losing

**They must also do this:** limp when injured, drop weapons when disarmed, surrender when last one standing, flee when outmatched. **No enemy should ever stand still waiting to be hit.**

---

## PART 2D — The world reacts

### Crowd
25 wanderers is set dressing. What is required:

- **Routines by hour** — commuting at 7, market at noon, drinking at 9, almost empty at 3am
- **Idle life** — phone calls, haggling, sitting on stoops, carrying loads on their heads
- **Reactions:** gunshot → 25 m panic radius, screaming, fleeing to nearest door · seeing a crime → becomes a **witness**, calls police after 8 s · player sprinting → sidestep · collision → stumble, curse, dust themselves off · police pursuit → street clears, shutters come down · rain → crowd moves under awnings

### Trees
Currently non-existent. Required: real trunks with bark PBR and noise displacement, recursive branching (depth 3), leaf cards with a **wind vertex shader**. Three species per district (palm in Ash Row, ficus in Vesper, scrub in Iron Yard). Wind amplitude tied to weather — calm, gusting, storm.

### Interiors
The 8 existing interiors are the right idea at the wrong scale. Required: 20+, with distinct characters (a barbershop that is not a barbershop, a foundry floor, a club's back room, a police station you should not be in).

---

## PART 3 — Build order

Eight phases. Each ends with something you can watch or play, not a status report.

| # | Phase | Delivers |
|---|---|---|
| **0** | **Identity** | Studio logo (3D, animated), game title card, name lock |
| **1** | **Feel** | Hit stop, camera impulses, impact FX, audio layering, **Style Rank** |
| **2** | **Enemies** | Full AI state machine, squad roles, skill tiers, cover, flanks, call-help |
| **3** | **First 10 minutes** | The hook script above, playable start to finish |
| **4** | **World** | Trees, crowd simulation, weather, day/night, district differentiation |
| **5** | **Vehicles** | Real models, handling, damage, entry/exit, engine audio, gears |
| **6** | **Missions** | All 6 main + side jobs with real objectives, checkpoints, choices |
| **7** | **Police & endgame** | Witness → report → pursuit → roadblock → arrest → escape |
| **8** | **Polish** | Menus, settings, save/load, performance, iPhone pass |

---

## PART 4 — Decisions I need from you

Before I write a line of code:

1. **The game name.** CINDERFALL (recommended) · CINDER CITY · THE LEDGER · keep LEVERAGE
2. **The district rename.** Cinder Line → RAILHEAD. Yes or no.
3. **The studio logo direction.** I have rendered concepts — pick the one that feels like you.
4. **Tone.** How far into the dark? *Mafia* cold and quiet, or *Devil May Cry* loud and stylish? My recommendation: **quiet world, loud combat.** The city is grim; the fighting is operatic. That contrast is the identity.
