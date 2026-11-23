# Phase 7 — Difficulty & Spawn Director
*23 Nov 2026*

## The five axes

`scripts/systems/difficulty.gd` combines five ascending signals into a single
1..6 **threat level** that enemy AI, spawners and street events read.

| Axis | Weight | What moves it |
|---|---|---|
| **District heat** | 0.40 | Where you are. Fixed by authored district tier. |
| **Notoriety** | 0.20 | Kills, jobs completed, bosses beaten. |
| **Faction pressure** | 0.18 | How far below zero your standings have gone. Police hunting counts double. |
| **Story escalation** | 0.14 | Which chapter you have reached. Authored, deterministic. |
| **Adaptive** | 0.08 | How you are actually performing. Invisible, bounded to ±1 level. |

## The rule the whole file obeys

**Nothing here multiplies a health pool.** The only health scaling in the game is
the tier system in `archetypes.gd`, which is capped at **1.15x from tier 1 to
tier 6** — and there is a test asserting it stays under 1.30x.

What difficulty actually changes: how fast enemies react (2.35x faster at tier 6),
how often they block (5% → 62%), whether they feint (0% → 42%), and whether the
crew coordinates (0.2 → 1.0). A hard fight is a fight against better fighters,
not against bigger numbers.

## The adaptive axis, and why it is small

It is weight 0.08, bounded to ±1 threat level, and never applies to boss
encounters. It moves when:

- you lose fights repeatedly → lower threat
- you die repeatedly → lower threat
- you win fights repeatedly → higher threat

It exists to stop the game being boring when you are cruising and impossible when
you are drowning — not to force every fight to the wire.

## The bug this phase found

**Notoriety had no mechanical effect in the starting districts.**

`threat_level()` computed `max(district_tier, lift)`. In a tier-1 district the
district term is 0, so even a fully notorious player could only reach `lift` — and
the district floor of 1 hid the result entirely. Ash Row stayed threat 1 forever
no matter how many people you had beaten.

That is the district where a player spends their first hours, so the entire
notoriety system was invisible for the part of the game where it mattered most.
Fixed by making the non-district axes **additive above the district floor**,
capped at +2 so Vesper Heights remains the hardest place in the city.

Verified: rookie in Ash Row = threat 1, notorious in Ash Row = threat 2.

## Spawn director

`scripts/systems/spawn_director.gd` puts generated content into the world:

- **Street events** every 26–52 s: mugging, shakedown, chase, deal, raid,
  accident, race, fire.
- Never spawns closer than 18 m or further than 85 m — close enough to see,
  far enough not to be an ambush from nowhere.
- Ground-checks every candidate spot with a physics ray.
- **Victims flee, criminals engage, raids bring a squad** scaled by threat.
- Police respond to sustained heat, arriving from the district edge.
- Despawns anything 220 m away and caps live criminals at 9.

Verified live: a Railhead event spawned, adding 2 actors to the world.

## Verified

- Threat ascends 1 → 6 across the seven districts.
- Notoriety lifts a starting district by one level.
- Adaptive stays inside ±1.0 and reverses direction with performance.
- Health ratio tier 1 → 6 is **1.15x**.
- Squads scale with threat and never exceed 6.
- `tests` 200/0.

## Still open

- Street events are attention-costly on mobile: each spawns real skinned actors.
  Nine live criminals is a guess, not a measurement — it needs a device profile.
- `race` and `fire` events fire a notification only; they have no gameplay yet.
- The adaptive axis has no persistence across sessions; it resets on load.
