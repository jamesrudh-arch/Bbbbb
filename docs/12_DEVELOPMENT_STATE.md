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

## 6b. Latest session — phone system (DONE) + push blocked

**Completed and committed locally (`01503ab`):**

- `scripts/systems/phone_system.gd` — story-state call scheduler. Triggers read
  `Game.hour`, `Game.wanted`, and story flags. Calls are gated by a 45 s gap, a
  6 s quiet window after combat ends, and a `_fired` map so `once` calls never repeat.
  Messages deliver as the in-game clock passes their scheduled hour.
- `scripts/ui/phone.gd` — four screens (HOME, CALL_SCREEN, THREADS, CONVO),
  pulsing incoming-call avatar with ANSWER/DECLINE, call history, unread badges,
  read/unread thread state, timestamps.
- `scripts/autoload/game.gd` — added `call_log`, `missed_calls`, `messages`,
  `current_call`, `push_message()`, `read_messages()`, `messages_updated` signal.
- `scripts/autoload/audio_director.gd` — `play_ringtone()` loops
  `audio/ui/ringtone.wav` (2.68 s two-tone trill, generated); `stop_stinger()`.
- `scripts/ui/hud.gd` — old contact-list phone deleted, replaced by `PHONE_VIEW`;
  new `ring_phone(call_id)` and `show_toast(text)`.

**Verified by runtime probe (headless):** ring → answer → 5-line conversation →
flag set → messages delivered (`chidi=1`, `ngozi=2`) → decline records 1 missed
call → threads screen opens. All 7 output lines clean.

**Verified visually (`shots/phone_ring.png`, `phone_home.png`, `phone_convo.png`):**
incoming call card with gold avatar and red/green buttons; home screen with
CALLS / MESSAGES / RADIO; conversation with speaker name and CONTINUE.
Fixed during this pass: `_clear()` used `queue_free()` only, so the previous
screen rendered one extra frame on top of the new one — now `remove_child()`
first. Added an opaque glass bed so the world no longer shows through the device.

**Tests:** `PASSED: 112  FAILED: 0`. **Syntax:** `REAL ERRORS: 0`.

**PUSH BLOCKED.** Four commits are local; `origin` is still at `c18871e`.
`git push` returns `could not read Username for 'https://github.com'`. The PAT
used earlier was scrubbed from the remote and was never revoked, so it must not
be reused. **A fresh token is required to push.** Local commits:
`f76bdfb`, `69fc8d8`, `13b0532`, `01503ab`.

## 7. Exact next action

**In order:**

1. **Push** — needs a fresh GitHub token for `jamesrudh-arch/Bbbbb`. All four commits
   are staged and clean; `git push origin HEAD` once credentials are supplied.
2. **Trigger phone calls from story beats.** `PhoneSystem` works but nothing calls
   `hud.ring_phone()` from `mission_manager` yet. Add a `ring_phone` step on mission
   start/completion so the 7 written call scripts actually fire in play.
3. **Mission 3 (`m03_block`)** — dependent systems now exist for it: phone (calls),
   map (routing), combat (5 disciplines). Author the bespoke sequence.
4. **Vehicles** — still Kenney placeholders (~2k tris). This is the biggest single
   deviation from the "realistic" criterion and needs a proper source.
5. **District differentiation** — six districts still share one palette family.
6. **Integration-test save/load** (D-107).
7. **iPhone pass** — XOGOT install, frame timing in Neon Mile at night, safe-area
   insets, touch targets. Record in `docs/13_TEST_REPORTS.md`.
