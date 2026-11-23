# Phase 3 — Enemy Archetypes & AI
*23 Nov 2026*

## What shipped

**25 archetypes × 6 skill tiers = 150 variants** (`scripts/systems/archetypes.gd`).
The freeze said 24; bosses are additive and enemy count is explicitly uncapped,
so the roster is 22 regular fighters + 3 bosses.

**A real state machine** (`scripts/systems/enemy_ai.gd`), replacing the previous
pursue-and-swing:

```
IDLE -> ALERT -> APPROACH -> (PRESS | SPACE | RETREAT) -> WINDUP -> STRIKE
                                                        -> RECOVER -> PRESS
anything -> STAGGER -> RECOVER
low health (per archetype) -> FLEE
calls_backup -> CALL -> backup arrives
```

## The design rules this enforces

1. **Difficulty is behaviour, not health.** Health grows only **+18%** from tier 1
   to tier 6 (measured: 1.17x). What actually changes is reaction time (2.35x
   faster), block chance (5% → 62%), dodge (2% → 35%), feints (0% → 42%) and
   crew coordination (0.2 → 1.0). A tier 6 thug is not a sponge — it is a
   fighter who punishes you.

2. **Every attack telegraphs.** `reaction` is the windup in seconds and it is
   always > 0.2 s. With no voice acting and a phone speaker, the visible windup
   is the entire fairness mechanism. A tier 1 lookout gives you 0.85 s; a tier 6
   champion gives you 0.36 s. Same read, less time.

3. **Archetypes fight differently.** An enforcer closes and grapples with an
   0.82 s windup and unblockable timing. A sniper holds 30 m and relocates. A
   riot shield cannot be hit from the front. A lookout runs to raise the alarm —
   stopping him quietly is a different fight from stopping a thug.

## Bugs this phase found and fixed

| Bug | Consequence |
|---|---|
| `notify_attacked()` hardcoded **6.5 damage** | Every enemy in the game hit identically. A dock hauler hit as hard as a lookout. |
| `_t` advanced before `_set_state` reset it | States could not satisfy their own exit conditions. |
| **Enemies stood at 2.6 m against a 2.0 m reach forever** | The classic "enemy stares at you" bug. Fixed with a committed lunge. |
| `_separation()` uncapped | Crewmates shoved each other out of attack range. Capped to 0.55 m. |
| Civilians turned the rig, AI turned the body | A hostile could face you while its mesh faced elsewhere. Unified. |
| `set_motion()` called every frame | Restarted the idle clip constantly, pinning the mesh toward its bind pose. Now only reacts to change. |

## Verified, not assumed

- **150/150 variants** build with every behaviour field present.
- Live 4-enemy fight: **4/4 close, wind up, strike, recover.** Two also use
  `SPACE` to circle — crew coordination working.
- Animation binding instrumented: mesh is skinned across **49 bones** (7,325 verts),
  all 50 tracks bound, arm swings 20.7° across the idle loop.
- `shots/fight_01.png` shows the crew engaging in the real world with HUD live.

## Known limits

- The `Soldier` model's idle stance is wide-armed. It reads oddly at rest but it
  is the source model, not a rigging error. Replacing the placeholder cast
  (item 7 in docs/23) removes it.
- Enemies do not yet use cover geometry — `uses_cover` is read but the world has
  no cover points authored. Phase 6/9 work.
- Ranged archetypes (`gunner`, `shotgun`, `sniper`) position correctly but fire
  through `_do_strike` as melee-flavoured hits. Projectile/line-of-fire is Phase 9.
