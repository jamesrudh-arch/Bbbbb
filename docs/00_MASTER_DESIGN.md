# LEVERAGE — Master Design Document

> **Tagline:** Everyone has leverage on you.
> **Setting:** Cinder City.
> **Studio:** D'Youngs Games.
> **Engine:** Godot 4.7.2 (Mobile renderer).
> **Primary target:** iPhone via XOGOT.
> **Document version:** 1.0 — 2026-11-23

---

## 1. Pitch

Cinder City raised you, then took everything. Your brother **Chidi Obi** owes ₦4.2m to
the **Neon Mile Crew**, and they have stopped asking nicely. You are **Emeka Obi** — a
brawler with five disciplines, a phone full of people who owe you favours, and a city
that only respects leverage.

LEVERAGE is a third-person open-world crime-action game about debt, family and the
arithmetic of who owns whom. You fight through six connected districts, learn five
distinct martial disciplines, drive and ride through live traffic, build money, heat,
reputation and trust, and decide which of the three factions gets to owe *you*.

## 2. Player fantasy

- **"I can fight anyone, five different ways."** Brawler, Kickboxing, Grappling,
  Drunken and Weapon disciplines have different reach, damage, stamina cost, speed and
  crowd-control. Switching discipline changes how fights feel, not just numbers.
- **"The city notices me."** Heat raises police response. Reputation opens doors.
  Trust unlocks faction work. Pedestrians remember you and talk.
- **"I own the streets."** Steal cars and bikes, drive with real physics, weave through
  traffic that obeys lights and brakes for you.
- **"Everyone has leverage on you — and I'm taking it back."** The story is a chain of
  debts, each faction holding a different note.

## 3. Core pillars

| # | Pillar | How the build expresses it |
|---|--------|---------------------------|
| 1 | **Leverage over violence** | Money, heat, reputation, trust and `leverage` counters all feed dialogue and mission gating. Combat is one tool, not the only one. |
| 2 | **Five real disciplines** | `Game.discipline_stats()` drives reach, damage, speed and stamina per discipline; `combat.gd` reads it live. |
| 3 | **A city that runs without you** | Traffic AI, pedestrian schedules, police patrols and a live event system run whether or not the player is looking. |
| 4 | **Touch-first** | Every control is a thumb-reachable button on a 390×844 iPhone safe area; keyboard/mouse is a development convenience. |
| 5 | **Readable at arm's length** | High-contrast HUD, 15px+ type, distinct silhouettes per district tier, gold accent reserved for money and progression. |

## 4. The five disciplines

| Discipline | Reach | Damage | Speed | Stamina | Identity |
|-----------|-------|--------|-------|---------|----------|
| **Brawler** | 1.9 m | ×1.00 | ×1.00 | ×1.00 | Baseline. Fast jabs, cheap combos, reliable. |
| **Kickboxing** | **2.6 m** | ×1.12 | ×0.95 | ×1.10 | Outranges everything. Kicks land before punches do. |
| **Grappling** | 1.5 m | **×1.55** | ×0.80 | ×1.25 | Throws. Highest single-hit damage, must close distance. |
| **Drunken** | 2.0 m | ×0.85 | ×1.20 | ×0.75 | Unpredictable, cheap, fast. Sways out of the first hit of a combo. |
| **Weapon** | 2.3 m | ×1.35 | ×0.90 | ×1.15 | Requires an equipped weapon; heavy attack becomes a slash. |

Disciplines are learned, not given: `Game.learn_discipline(id)` is called by trainers
and story missions. The HUD always shows the active discipline under the money panel.

## 5. Factions

| Faction | Home turf | Wants | Gives |
|---------|-----------|-------|-------|
| **Obi Family** | Ash Row | The debt cleared, the block protected | Safehouse, Mama Ngozi's kitchen, starting work |
| **Meridian Group** | Vesper Heights, Iron Yard | The docks quiet, the paperwork clean | Corporate jobs, high pay, low heat |
| **Neon Mile Crew** | Cinder Line, Neon Mile, Guttermarket | Chidi's debt paid or Chidi's body | Street work, weapons, no questions |

Trust is tracked per faction (`Game.trust[faction]`) and gates jobs, shop stock and
dialogue. Reputation is a single global number that gates story beats.

## 6. The six districts

| District | Tier | Faction | Character |
|----------|------|---------|-----------|
| **Ash Row** | 1 | Obi Family | Where the blocks raised you. Concrete, cookouts, cousins. |
| **Guttermarket** | 1 | Neon Mile Crew | Fifty stalls deep. Everything has a price, nothing has a receipt. |
| **Iron Yard** | 2 | Meridian Group | Cranes at 3 a.m. Container stacks nobody counted twice. |
| **Cinder Line** | 2 | Neon Mile Crew | The rail that fed the city, now feeding the foundries. |
| **Vesper Heights** | 3 | Meridian Group | Glass and security lights. They sleep well up here. |
| **Neon Mile** | 3 | Neon Mile Crew | Two in the morning and nobody's counting the receipts. |

Each district is a 150×150 m playable cell with a 40 m block pitch: two cross streets,
sidewalks, buildings with enterable ground floors, street lamps, traffic lights, parked
cars, pedestrians and faction NPCs. Districts connect by real roads — you can drive from
Ash Row to Neon Mile without a loading screen.

## 7. Controls (authoritative)

Combat buttons are **fixed by the brief** and are identical on touch and keyboard:

| Action | Touch | Keyboard | Mapping (Godot action) |
|--------|-------|----------|------------------------|
| Punch | **X** | X | `punch` |
| Heavy attack | **Y** | Y | `heavy` |
| Kick | **A** | A | `kick` |
| Dodge | **B** | B | `dodge` |
| **Contextual interaction** (outside combat) | **B** | B | `interact` |
| Block | hold L | L | `block` |
| Shoot | RT | Mouse 1 | `shoot` |
| Reload | R | R | `reload` |
| Switch weapon | T | T | `weapon_switch` |
| Move | left stick | WASD | `move_*` |
| Camera | right stick / drag | Mouse | `look_*` |
| Sprint | stick fully deflected | Shift | `sprint` |
| Throttle / brake | pedals (in car) | W / S | `throttle`, `brake` |
| Steer | + pedals (in car) | A / D | `steer_left`, `steer_right` |
| Handbrake | HB button | Space | `handbrake` |
| Enter/exit vehicle | B near a car | B | `interact` |
| Horn | HORN | H | `horn` |
| Phone | top-right icon | P | `phone` |
| Map | top-right icon | M | `map` |
| Pause | top-right icon | Esc | `pause` |

**B has exactly one meaning at any instant:** in combat it is *dodge*; outside combat it
is *interact*. `combat.gd` returns early when `in_combat == false`, so the two never
conflict. This is enforced in code, not by convention.

## 8. Progression economy

- **Money (₦)** — earned from missions, side jobs, pickups and selling. Spent in shops.
- **Heat (0–100)** — raised by crime, decayed slowly by time. Drives wanted level:
  - 0–14: no interest
  - 15–34: wanted 1 — patrol response
  - 35–59: wanted 2 — two units, active pursuit
  - 60–84: wanted 3 — three units, roadblocks
  - 85+: wanted 4 — heavy response
- **Reputation** — global respect; unlocks story missions and better pay.
- **Trust** — per faction; unlocks jobs and shop stock.
- **Leverage** — per-character counters that unlock blackmail/intimidation dialogue.

## 9. Story spine

1. **Homecoming** — walk to Mama Ngozi's kitchen. Learn the debt exists.
2. **The Note** — Chidi has been taken by the Neon Mile Crew. You need ₦4.2m, or Chidi's
   location.
3. **Working the Block** — first paid jobs in Ash Row and Guttermarket.
4. **Meridian's Offer** — the corporation will clear the debt for a favour you shouldn't do.
5. **The Chain** — every faction holds a different note; you collect leverage.
6. **Settlement** — the finale depends on which leverage you hold and who you trusted.

The tutorial (02) is playable end-to-end. Missions 03–06 exist as data in
`Content.MISSIONS` with objectives, rewards and state machine; see
`docs/12_DEVELOPMENT_STATE.md` for exactly which are wired vs data-only.

## 10. Art direction summary

See `docs/02_ART_DIRECTION.md`. In brief: **West-African-inflected brutalist city at
dusk** — warm dust haze in the low tiers, cold security lighting in the high tiers,
gold (₦, LEVERAGE) reserved for money and progression, and a strict "no muddy grey"
rule: every surface is either warm neutral, cool neutral, or an accent.

## 11. Audio direction

All 32 audio files are **synthesized from first principles** in `tools/gen_audio.py` —
no third-party samples, so the game carries no sample licensing obligations. Ambience
beds, music loops, stingers, punches, kicks, gunshots, engines, footsteps and UI all come
from this generator. See `docs/07_ASSET_REGISTER.md`.

## 12. Out of scope for v1.0

Explicitly **not** built, and not claimed anywhere:
- Online multiplayer.
- Voice acting.
- Full-body cinematic mo-cap cutscenes (in-engine camera cinematics only).
- A motorcycle GLB (the bike is procedurally built in `vehicle.gd`).
- App Store submission packaging.
