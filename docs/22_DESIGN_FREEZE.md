# LEVERAGE — DESIGN FREEZE
### Everything locked before the first line of code. 23 Nov 2026

---

## STATUS: DESIGN COMPLETE

All direction documents are written. Below is the single authoritative summary.
Anything not listed here is out of scope for v1.

---

## 1. IDENTITY — LOCKED

| Item | Decision |
|---|---|
| Game name | **LEVERAGE** |
| Tagline | *EVERYBODY HAS SOMETHING ON YOU.* |
| Studio | **D'Youngs Games** |
| Studio mark | D·Y monogram, gunmetal + gold inlay, animated in 3D from ash |
| Protagonist | **Marcus Adeyemi** |
| Inciting incident | Brother **Chidi** kidnapped. Marcus pays a debt he didn't create |
| City | **Cinder City** |
| Tone | Quiet world, loud combat. Grim city, operatic fighting |

---

## 2. THE CAST — EXPANDED, NOT CAPPED

You said the numbers shouldn't be limited to what the brief listed. **They aren't.** Here is the full population:

| Tier | Count | Who they are |
|---|---|---|
| **Core story cast** | **16** | Marcus, Chidi, Ngozi, Tunde, Eze, Sunday, Ada, Kola, Okafor, Mara, Sade, Bello, Ifeoma, Femi, Nkem, The Broker. Full arcs, portraits, branching dialogue |
| **Faction lieutenants** | **14** | 2 per faction. Each with a name, a face, a territory, a dialogue tree |
| **Ring champions** | **8** | One per venue. Unique movesets, entrance lines, defeat lines |
| **Bounty targets** | **28** | Named criminals. Each a small authored encounter with a choice |
| **Contract contacts** | **12** | Phone voices who hand out work |
| **Vendors & shopkeepers** | **18** | Every interior has one, with personality |
| **TOTAL NAMED CHARACTERS** | **96** | Every one with a portrait, a name, and something to say |

### Enemies — not one type, not twelve

| Layer | Count |
|---|---|
| **Archetypes** | **24** (was 12) |
| **Skill tiers** | **6** — Rookie · Street · Veteran · Hardened · Elite · Named |
| **Enemy variants** | **24 × 6 = 144** distinct behaviours |
| **Faction rosters** | 7 factions × ~8 archetypes each, overlaps differ |

The 24 archetypes: Rookie · Brawler · Boxer · Kickboxer · Wrestler · Knife · Bat · Pipe · Armed Guard · Shooter · Sniper · Bulwark · Runner · Grenadier · Chemist · Enforcer · Sapper · Watcher · Bruiser · Duelist · Gunner · Beast · Warden · Elite.

### The crowd

| Layer | Count |
|---|---|
| **Pedestrian archetypes** | **32** (was 24) |
| **Outfit variants** | 6 per archetype = **192 visual combinations** |
| **Schedules** | Every archetype has an hour-by-hour day |
| **Conversations** | Ped-to-ped chats, ambient barks, reactions |

---

## 3. CONTENT — FINAL NUMBERS

| Content | Count | Hours |
|---|---|---|
| Story chapters | **16** (incl. Chapter 0 prologue) | — |
| Story missions | **48** | ~12 |
| Faction contracts | **72** | ~9 |
| Fight ring bouts | **48** (8 venues × 6 tiers) | ~6 |
| Street races | **28** | ~3 |
| Bounties | **28** | ~4 |
| Heists | **8** | ~6 |
| Street event types | **36** | infinite |
| Leverage Files | **100** | ~3 |
| Interiors | **34** | — |
| Safehouses | **8** | — |
| Weapons | **30** | — |
| Vehicles | **32** | — |
| Disciplines | **6** (Brawler · Kickboxing · Grappling · Drunken · Weapon · **Silat**) | — |

**Total: 45–60 hours to completion. Unbounded after the credits.**

---

## 4. MULTIPLAYER — LOCKED: 1v1, no server

**Decision: 1v1 only, for now, and no money spent.**

| Mode | Ships | Server |
|---|---|---|
| **Local split-screen 1v1 duels** | ✅ v1 | ❌ none needed |
| **Ghost Records** — race your own best fight replay | ✅ v1 | ❌ none needed |
| **Time Attack** — your best times and scores | ✅ v1 | ❌ none needed |
| Online PvP | ⏸ later | requires relay (~$5–15/mo) |

**Why this is the right call:** real two-player fighting, zero infrastructure cost, no App Store moderation burden, and it can ship with everything else.

**Duel rules:** both players choose a discipline and a fighter from the named cast. Locked arena per venue. Best of 3 rounds. Style Rank scores each round and decides a tie. No chat, no text — eliminates the UGC problem entirely.

---

## 5. NAVIGATION — LOCKED

| Element | Spec |
|---|---|
| **Minimap** | Live, circular, top-left, rotates with camera, zooms out when driving |
| **Blips** | Mission (gold) · safehouse (blue) · shop (green) · ring (red) · bounty (orange) · police (blue flashing) · phone (cyan) · player arrow (white) |
| **On-road GPS** | Gold line painted on the asphalt, turn arrows 30 m early, distance + ETA |
| **Recalculation** | Within 12 m of leaving the route |
| **Waypoints** | Tap map to set; multiple simultaneous markers |
| **Fog of war** | Districts reveal as discovered |
| **Orientation** | Chapter 0 teaches the city on foot; street-name banners; visible landmarks |

---

## 6. DIFFICULTY — LOCKED

Five ascending axes: district heat · faction pressure · notoriety · story escalation · invisible adaptive.
Six enemy skill tiers.
**Rule: difficulty changes behaviour, never health bars. No bullet sponges.**

---

## 7. ONBOARDING — LOCKED

0:00 radio → 0:08 D'Youngs logo → 0:14 LEVERAGE title → 0:26 cinematic (60s) →
**1:30 playable** → 3:20 first fight (combat taught inside the fight) → 4:30 Style Rank →
5:00 phone rings → 6:00 first pursuit → 8:30 free roam → 10:00 Chapter 1.

---

## 8. BUILD ORDER — LOCKED

| Phase | Work | Why here |
|---|---|---|
| **1** | Opening sequence (logo, title, cinematic, into playable) | First impression, every session |
| **2** | Minimap + on-road GPS | Fixes navigation completely |
| **3** | 24 enemy archetypes + full AI state machine | The wall between prototype and game |
| **4** | Feel: hit stop, camera impulse, impact FX, **Style Rank** | Makes combat feel expensive |
| **5** | NPC conversation, barks, ped-to-ped | Makes the city alive |
| **6** | Content engines: contracts, rings, races | The 30-hour multiplier |
| **7** | Ascending difficulty tuning | Depth |
| **8** | Split-screen 1v1 duels | Multiplayer promise delivered |
| **9** | Vehicles, cinematics, police, iPhone pass | Completion |

---

## 9. WHAT IS NOT IN SCOPE FOR V1

Explicitly cut, deliberately:

- Open-world online co-op (different order of engineering)
- Planes or aircraft
- Full citywide water/boat traffic (one smuggling boat only)
- Property empire / passive business income
- Breakpoint-grade weapon customisation (3 tiers per weapon instead)
- Destructible world geometry
- Voice acting for all dialogue (text dialogue + barks + music)

---

## 10. READY TO BUILD

Nothing further is needed from you except **the token**.

Once I have it:
1. Push all commits to `jamesrudh-arch/Bbbbb`
2. Begin **Phase 1 — the opening sequence**

No further questions. No further approval needed per step.
