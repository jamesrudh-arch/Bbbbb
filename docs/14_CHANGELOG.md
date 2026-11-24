# LEVERAGE — Changelog

All notable changes to this project, newest first.

---

## v0.9.0 — 2026-11-23 — "Playable and legible"

The build where the game actually became a working third-person game rather than a scene
that renders.

### Fixed
- **Vehicles had no collision and no wheels** — three compounding faults in
  `vehicle.gd::_setup_body()`: dead code after `_prim()`'s `return` swallowed the physics
  section; `shape.shape` was never assigned (a null shape is silently non-colliding); and
  `configure()` ran before the node was in the tree. Restructured with `_built` /
  `_ensure_built()`. Verified: 8 children, car settles at y = −0.09, **4/4 wheels in
  contact**.
- **Punches did zero damage** — `_attack()` called a non-existent
  `player.forward_offset()` and threw before the damage block. Also repaired the armour
  read and a `set_prompt()` type error. Verified: HP 80 → 19.16 over a 7-punch combo.
- **Player died instantly** — enemy DPS was lethal; cooldowns to 1.7–2.6 s, base damage to
  6.5, armour mitigation clamped. Verified: 50.8 HP after a 3-on-1.
- **Car hit 427 km/h** — engine force applied while airborne. Now gated on wheel contact,
  tapered near top speed, hard-clamped to 1.15× top. Verified: 76 km/h, 4/4 contacts.
- **`driver.enter()` always false** — camera rig was being reparented into the vehicle and
  the HUD was being called on the wrong node. Camera now stays on the player and follows
  the vehicle; HUD resolved through the world.
- **Characters moonwalked** — UAC rigs face +Z. `model.rotation.y = PI`.
- **Characters had black featureless heads** — source materials are near-black. Added
  `_tint_materials()` with 5 skin and 6 shirt variants keyed on source material name.
- **Main menu was a white screen** — `haze` was a `ColorRect` (default colour white) added
  full-rect without a colour; skyline also drew over the menu. Fixed both, plus resize
  handling and a compacted layout that fits 720p.
- **Interiors showed sky** — player spawned outside the doorway with the camera facing out,
  and the room was unlit. Now positioned from room size, camera faces in, ceiling omni
  added.
- **Phone contact list overflowed** — 16 contacts now in a 320 px `ScrollContainer`.
- **Police responder spawn** — snapped to the nearest road node 55 m out instead of
  spawning inside geometry. Typed `var best: Vector3` (GDScript cannot infer `:=` on
  Variant).
- **`set_prompt("")`** → `set_prompt(null)`.

### Added
- `--openflow` capture mode in `boot.gd` (studio/title/notice frames).
- `--menuflow` capture mode in `main_menu.gd`.
- `vehicle.wheel_contacts()` for grounded physics checks.
- Open-road vehicle selection in the scripted tour (raycast clearance scoring).
- Full documentation set (17 documents).

### Verified in this release
- Scripted 12-beat gameplay tour: spawn → walk → combat (3 hostiles) → punch → dodge →
  enter vehicle → drive 76 km/h → exit → heat 45 → **wanted 3 with 3 police units** →
  interior → map → phone.
- Firearms: pistol 80 → 58 → 36 HP, ammo 24 → 23 → 22.
- 112/112 tests, 0 script errors.

---

## v0.8.0 — 2026-11-22 — "It renders"

- Fixed the black-blob world: `ambient_light_source` 3 (SKY) → 2 (COLOR).
- Camera: follow height 1.75 m, spring 6.2 m, 0.30 m shoulder offset, DOF far-only.
- Shadows: 4 splits, 80 m, bias 0.06, normal bias 1.6.
- Vehicles scaled 1.25× and lifted `0.33 × scale` (Kenney cars are centre-origin).
- Characters scaled 0.92 (1.95–2.0 m silhouette).
- Asphalt/sidewalk/ground albedo tuned; daylight fog 0.0022; neon strips moved to y = 6/13/20.
- Spawn points rewritten to road centrelines for a street vista on first frame.
- HUD: weapon/ammo moved into the money panel to remove a top-right overlap.

---

## v0.7.0 — 2026-11-21 — "Systems"

- Six autoloads finalised: Content, Game, Audio, Loader, Events, Controls.
- City generator: six districts on a 40 m block pitch, per-district palettes,
  tier-driven neon.
- Traffic (16), NPCs (25 with schedules + memory), police (wanted 0–4), interiors (6),
  pickups, mission manager, interaction system.
- Combat with five disciplines, combo scaling, stamina, armour, firearms.
- Vehicles: 7 Kenney GLBs + procedural motorcycle, 4-wheel suspension, player and AI
  driving.
- HUD: district/clock/weather, health/stamina, mission tracker, money/discipline/heat,
  virtual stick, X/Y/A/B diamond, action column, speedometer, map, phone, pause.

---

## v0.6.0 — 2026-11-20 — "Opening flow"

- `boot.gd`: D'Youngs Games presentation → LEVERAGE title (procedural skyline, gold
  logotype, tagline) → content notice → menu.
- `main_menu.gd`: New Game, Continue, Load Game (3 slots), Settings (3 volume buses),
  Credits, Quit.

---

## v0.5.0 — 2026-11-19 — "Assets"

- 11 UAC character GLBs dequantized (meshopt/KHR removed — Godot silently rejects
  quantized GLBs with `valid=false`).
- `animations.glb` processed into a shared 17-clip library, cached to
  `user://anim_lib_cache.res`.
- 7 Kenney vehicle GLBs dequantized.
- 32 audio files synthesized from first principles (`tools/gen_audio.py`).

---

## v0.1.0 — 2026-11-18 — "Foundation"

- Project created: Godot 4.7.2, Mobile renderer, ETC2/ASTC.
- Test harness (`test_suite.tscn`), verification pipeline (`gdview.sh` + Xvfb),
  syntax checker.
- Input map with the brief's fixed X/Y/A/B assignment.
