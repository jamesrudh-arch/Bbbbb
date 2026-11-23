# LEVERAGE — Test Reports

Every report here is from a command actually run in this workspace. Nothing is projected.

---

## TR-2026-11-23-01 — Automated test suite

**Command**
```bash
Godot --headless --path /home/user/leverage res://tests/test_suite.tscn
```

**Result**
```
PASSED: 112   FAILED: 0   TOTAL: 112
```
**Duration:** ~1.1 s
**Environment:** Godot 4.7.2.stable.official (ed1daf0bf), headless, Linux x86_64.
**Covers:** autoload integrity; content table shape (16 characters, 6 districts, 5
disciplines, 6 missions, shops, interiors, vehicles, weapons); discipline stat
differentiation; economy maths (money, heat→wanted thresholds, trust, reputation);
inventory and weapon rules; save/load round-trip; input-map completeness; control-conflict
rules (B = dodge in combat, B = interact outside); world data consistency.
**Does not cover:** rendering, audio, physics feel, device performance.

---

## TR-2026-11-23-02 — Scripted gameplay tour (12 beats)

**Command**
```bash
GD_TIMEOUT=560 timeout 600 bash /home/user/tools/gdview.sh \
  /home/user/leverage --rendering-driver vulkan res://scenes/_demo.tscn
```

**Output (trimmed)**
```
[DEMO] start, player at (-200.0, -0.000591, -46.0)
[DEMO] walked to (-200.0, -0.000591, -37.82671)
[DEMO] spawned 3 hostiles
[DEMO] in_combat=true targets=3
[DEMO]   enemy hp=19.16
[DEMO] hostiles alive after combo: 3 / 3  player_hp=50.8
[DEMO] entered vehicle=true type=taxi
[DEMO] DRIVING speed=21.0 m/s = 76 km/h contacts=4/4
[DEMO] wanted=3 police units=3
[DEMO] interior current=mama_ngozi
[DEMO] DONE total shots=12
```
**Duration:** ~83 s (includes software-rasterised rendering of 12 frames).
**Result:** PASS. Every beat produced a frame; combat, vehicle entry, driving, police
response and interior entry all functioned.
**Notes:** the 12 frames are in `shots/01..12_*.png`.

---

## TR-2026-11-23-03 — Combat damage resolution

**Setup:** single hostile (80 HP) at 1.45 m, brawler discipline, real input events via
`Input.parse_input_event` (because `Input.action_press` does not produce an
`is_action_just_pressed` edge).

**Result**
```
[D] before: hp=80.0 in_combat=true targets=1 reach=1.9
[D] dist=1.30000305175781
[C] resolving: targets=1 reach=1.9 dmg=9.72
[C]   target dist=1.44589233398438 vs reach=1.9
[C]   HIT
[D] punch 1 -> enemy hp=70.28 is_dead=false
[D] punch 2 -> enemy hp=59.84 is_dead=false
[D] punch 3 -> enemy hp=48.68 is_dead=false
```
**Result:** PASS. Damage lands, combo scaling applies (9.72 → 10.44 → 11.16), HP
decrements correctly.
**Negative result also recorded:** a hostile at 6.84 m produced **zero** damage, which is
correct behaviour (brawler reach 1.9 m), not a bug. Range gating verified.

---

## TR-2026-11-23-04 — Vehicle physics (isolated)

**Setup:** bare 400×400 m floor, no world, no NPCs. Sedan spawned at y = 1.2.

**Result**
```
[H]   child @CollisionShape3D@18 (CollisionShape3D) shape=():<BoxShape3D#-9223372002629253553>
[H]   child @VehicleWheel3D@19 (VehicleWheel3D) wheel   [×4]
[H] settled y=-0.091 contacts=4/4
[H] DRIVE speed=31.1 m/s = 112 km/h
```
**Result:** PASS. Collision shape is a real `BoxShape3D` (not null), all four wheels make
contact, the car accelerates to 112 km/h.
**Regression value:** this test is what proved `shape.shape` was null (D-005). Any future
change to `_setup_body()` should re-run this.

---

## TR-2026-11-23-05 — Firearms

**Setup:** pistol equipped, 24 rounds, hostile at 7 m, four fire inputs at 0.6 s spacing.

**Result**
```
[GUN] equipped=pistol ammo={ "pistol": 24, "smg": 0, "shotgun": 0 }
[GUN] enemy hp before=80.0 dist=7.0
[GUN] shot 1 enemy hp=58.0 ammo=23
[GUN] shot 2 enemy hp=58.0 ammo=23
[GUN] shot 3 enemy hp=36.0 ammo=22
[GUN] shot 4 enemy hp=36.0 ammo=22
```
**Result:** PASS. 22 damage per shot, ammo decremented once per accepted shot, and shots
2 and 4 were correctly rejected by the fire-rate cooldown (`1/speed`).

---

## TR-2026-11-23-06 — Opening flow capture

**Command**
```bash
GD_TIMEOUT=280 bash /home/user/tools/gdview.sh /home/user/leverage \
  --rendering-driver vulkan res://scenes/boot.tscn \
  -- --openflow --out=/home/user/leverage/shots --wait 18
```
**Result**
```
SHOT_SAVED .../open_01_studio.png stage=0
SHOT_SAVED .../open_02_title.png  stage=1
SHOT_SAVED .../open_03_notice.png stage=2
```
All three stages captured and visually inspected: studio card, title with skyline and
tagline, content notice.

---

## TR-2026-11-23-07 — Main menu render

**Result:** PASS after D-009 fix. `shots/open_04_menu.png` shows the night skyline, gold
LEVERAGE logotype, tagline, six menu items within the frame, and save-slot status text.

---

## TR-2026-11-23-08 — Script error sweep

**Command**
```bash
bash /home/user/tools/syntax_check.sh
```
**Result:** `REAL ERRORS: 0`
**Note:** the checker filters true false positives — `--check-only` has no autoloads, so
"Identifier not found: Game/Audio/Loader/Content/Events/Controls" and "Failed to compile
depended scripts" are ignored. Everything else is reported.

---

## Not tested — and labelled as such

| Item | Why not | Label |
|------|---------|-------|
| Audio audibility / mix | no ALSA device in sandbox; dummy driver | DEVICE-ONLY |
| iPhone frame rate | software rasteriser only (llvmpipe) | DEVICE-ONLY |
| Safe-area insets | no device; `get_display_safe_area()` returns full screen | DEVICE-ONLY |
| Touch feel / latency | no touch device | DEVICE-ONLY |
| Save→quit→relaunch→continue | not run as a single integration flow | OPEN (D-107) |
| Motorcycle handling | bike is procedural; driving not separately verified | OPEN |
| All 6 story missions | 4 lack scripted set-pieces | OPEN (D-101) |
