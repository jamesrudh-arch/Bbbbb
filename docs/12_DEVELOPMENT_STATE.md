# LEVERAGE — Development State

**Last updated:** 2026-11-23 (final pass)
**Stage:** Playable vertical slice + full opening flow + complete documentation set.
**Verified:** 112/112 tests, 0 script errors, 19 rendered frames.
**Next exact action:** see §7.

---

## 1. Where the project is

| Area | State |
|------|-------|
| Opening flow (studio → title → notice → menu) | **DONE**, verified in rendered frames |
| Main menu (6 items, settings, credits, slots) | **DONE**, verified |
| World (6 districts, roads, buildings, props) | **DONE**, verified |
| Third-person movement + camera | **DONE**, verified |
| Combat (5 disciplines, damage, combos, stamina) | **DONE**, verified with real damage |
| Vehicles (7 cars + procedural bike, physics, AI) | **DONE**, verified driving |
| Enterable interiors (6) | **DONE**, verified lit interior render |
| Police + wanted levels | **DONE**, verified (wanted 3 → 3 units) |
| HUD, map, phone, radio | **DONE**, verified |
| Day/night, weather | **DONE** |
| Save/load | Implemented, unit-tested; in-world cycle not integration-tested |
| Story missions | 2 of 6 fully scripted |
| Audio | 32 original WAVs wired; unverifiable in sandbox |
| Documentation | **DONE** (this set) |

## 2. Tests

```
$ Godot --headless --path /home/user/leverage res://tests/test_suite.tscn
PASSED: 112   FAILED: 0   TOTAL: 112
```
Runtime ≈ 1.1 s. Zero `SCRIPT ERROR` lines under `tools/syntax_check.sh`
(`REAL ERRORS: 0`).

## 3. Verification runs (real commands, real results)

**Scripted gameplay tour** (12 beats: spawn → walk → combat → punch → dodge → enter
vehicle → drive → exit → heat/police → interior → map → phone):

```
[DEMO] start, player at (-200.0, -0.000591, -46.0)
[DEMO] in_combat=true targets=3
[DEMO]   enemy hp=19.16
[DEMO] hostiles alive after combo: 3 / 3  player_hp=50.8
[DEMO] entered vehicle=true type=taxi
[DEMO] DRIVING speed=21.0 m/s = 76 km/h contacts=4/4
[DEMO] wanted=3 police units=3
[DEMO] interior current=mama_ngozi
[DEMO] DONE total shots=12
```

**Vehicle physics isolation test** (bare floor):
```
[H] settled y=-0.091 contacts=4/4
[H] DRIVE speed=31.1 m/s = 112 km/h
```

**Combat damage test** (1.45 m, brawler):
```
[C] resolving: targets=1 reach=1.9 dmg=9.72
[C]   target dist=1.44589233398438 vs reach=1.9
[C]   HIT
[D] punch 1 -> enemy hp=70.28
[D] punch 2 -> enemy hp=59.84
[D] punch 3 -> enemy hp=48.68
```

## 4. Files modified in the most recent pass

```
scripts/vehicle/vehicle.gd            rewritten _setup_body; shape.shape fix; grounded
                                      engine force; wheel_contacts(); velocity clamp;
                                      removed dead code after _prim()'s return
scripts/player/driver.gd              camera rig kept on player (no reparent); HUD
                                      accessed via world, not player; grounded guards
scripts/player/combat.gd              removed player.forward_offset(); armour read
                                      rewritten; damage rebalance
scripts/player/interaction.gd         set_prompt(null) instead of ""
scripts/npc/actor.gd                  attack cooldown 1.7-2.6 s
scripts/character/character_rig.gd    model.rotation.y = PI; _tint_materials() palette
scripts/systems/interiors.gd          spawn from room size; ceiling omni light
scripts/systems/police.gd             road-snapped responder spawn (typed var best)
scripts/ui/main_menu.gd               haze ColorRect->Control; skyline z-order + resize;
                                      compact layout; --menuflow capture
scripts/ui/boot.gd                    --openflow capture mode
scripts/ui/hud.gd                     phone contact ScrollContainer
scripts/world/world.gd                _dev_args() for --hour/--district; initial HUD
                                      district label on spawn
scripts/dev_screenshot.gd             NEW (renamed from deleted _shot.gd) — proper
                                      documented offscreen capture tool, still wired
                                      into world.tscn as ShotHarness
scenes/_demo.tscn, scripts/_demo.gd   REMOVED after verification (temp harness)
scripts/_dbg*.gd, scenes/_dbg*.tscn   REMOVED (temp diagnostics)
scripts/_gun.gd, scenes/_gun.tscn     REMOVED after firearms verification
```

## 5. Known blockers

None blocking. Remaining gaps are scope (D-101 story missions) and environment limits
(D-102 audio, D-103 iPhone perf, D-104 safe area). See `docs/11_KNOWN_DEFECTS.md`.

## 6. If you are resuming this project

1. `cd /home/user/leverage`
2. Run the tests: `Godot --headless --path . res://tests/test_suite.tscn` → expect 112/0.
3. Check scripts: `bash /home/user/tools/syntax_check.sh` → expect `REAL ERRORS: 0`.
4. Render a frame to confirm visuals still look right:
   ```
   GD_TIMEOUT=280 bash /home/user/tools/gdview.sh /home/user/leverage \
     --rendering-driver vulkan res://scenes/world.tscn \
     -- --shot /home/user/leverage/shots/check.png --wait 60
   ```
5. If the animation library looks wrong after changing clips, delete
   `user://anim_lib_cache.res`.

## 7. Exact next action

**Highest-value remaining work, in order:**

1. **Script `m03_block`** — the next story mission after `m02_debt`. Add a bespoke
   sequence in `mission_manager.gd` (three paid jobs in Ash Row / Guttermarket with
   placed NPCs and dialogue), then `m04_offer`.
2. **Integration-test save/load** — write a run that positions the player, saves to slot 0,
   reloads the scene, loads slot 0, and asserts position/money/heat restored (D-107).
3. ~~Verify firearms~~ — **DONE**: pistol 80→58→36 HP, ammo 24→23→22 (TR-05).
4. **iPhone pass** — install via XOGOT, measure frame time in Neon Mile at night (the
   heaviest scene), verify safe-area insets and touch targets, record results in
   `docs/13_TEST_REPORTS.md`.
