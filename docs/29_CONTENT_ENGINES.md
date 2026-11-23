# Phase 6 — Content Engines
*23 Nov 2026*

## The problem

Eight hand-written story missions and three side jobs. The freeze calls for
72 contracts, 28 bounties and 36 street events. Writing those as 136 literal
dicts would be unmaintainable and unbalanced, and none of them would reference
the districts, archetypes or landmarks that already exist.

## What shipped

**`scripts/systems/content_engine.gd`** generates the repeatable layer from
templates that carry design intent:

| Kind | Contracts at 72 | Behaviour |
|---|---|---|
| shakedown | ✔ | intimidate a target |
| escort | ✔ | keep someone alive to the handover |
| retrieve | ✔ | recover goods |
| clear | ✔ | empty a location by force |
| tail | ✔ | follow without being seen |
| deliver | ✔ | make the drop |
| defend | ✔ | hold a point against waves |

- **72 contracts, 28 bounties, 36 street events** — measured, not estimated.
- Bounties name a real target, carry a real charge, and spawn a **real
  archetype** at a real tier from `archetypes.gd`. One in four is a capture.
- Events are weighted (mugging most common, fire rarest) and gated so a tier-6
  event never fires on a tier-1 player.
- **Deterministic from a save seed.** Same save, same board — you cannot re-roll
  until you find an easy contract.

**New objective types** in `mission_manager.gd`: `intimidate`, `escort`, `tail`,
`deliver`, `defend`, `survive`, `bounty`. Each has real failure conditions —
an escort that dies fails the mission; a tail blown by getting too close fails.

**Conversation outcomes now gate missions.** An objective can require
`needs_outcome: "lead_strong"`, so the difference between threatening and
charming someone is now a plot consequence, not just a trust number.

**`scripts/ui/job_board.gd`** — reachable from the phone. Tabs for contracts and
bounties, risk shown as dots, pay shown in naira, coloured border by tier.

## Bugs found

| Bug | Consequence |
|---|---|
| **`bool()` does not exist in GDScript** | It was used in **9 files** and threw at runtime every time. Accessibility settings, vehicle flags, save flags and the block check in combat all silently evaluated false. Settings never persisted. This is the single highest-impact bug found in the whole project so far. |
| Filler cloned one district | `ash_row` got 35 of 72 contracts and six districts shared the rest. |
| **Every district was tier 1–3** | The difficulty ceiling of the entire game was tier 3 of 6. The freeze requires escalation; now tiers run 1,1,2,3,4,5,6. |
| Duplicate board titles | "Deliver to Foundry" listed twice. Visible in the first screenshot. |
| Districts had only 3 landmarks | 14 jobs in Railhead across 3 names. Added six named sub-locations per district. |

## Verified

- 72 / 28 / 36 generated against targets, every run.
- Pay scales with risk: **₦393 average at tier ≤2, ₦674 at tier ≥5**.
- Contract kinds spread across all seven types.
- Bounties: 0 invalid archetypes.
- Same seed reproduces the identical board.
- `shots/jobs_01_contracts.png` — the live board.

## Still open

- Story missions remain the 8 hand-written ones. The engine generates the
  *repeatable* layer; the 48-mission chapter structure still needs authoring, and
  that is a writing task, not a systems task.
- Street events are generated and selectable but nothing spawns them in the world
  yet — that is the spawn director, deferred to Phase 7 tuning.
- The "II" suffix on a tenth job in one district is functional but plain. It only
  appears because 14 jobs share 9 place names.
