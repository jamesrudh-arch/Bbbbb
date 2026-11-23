# LEVERAGE — Asset Register

Every asset in the project, what it is, where it came from, and what it is used for.
Licence details are in `docs/06_LICENCE_RECORD.md`.

**Verification status legend**
- **IMPORTED** — file exists in the project and imports without error.
- **IN USE** — referenced by a scene or script at runtime.
- **VERIFIED** — seen rendering or heard playing in a rendered frame / recorded test run.
- **DEVICE-ONLY** — cannot be verified in the sandbox; must be checked on an iPhone.

---

## 1. Characters (11 GLB, rigged + skinned)

Source: **Quaternius / misty-3d Universal Animated Character** pack (CC0).
All are **dequantized** from meshopt/KHR-compressed originals via
`tools/gt/convert.mjs` because Godot's GLB importer silently returns `valid=false` for
meshopt-quantized files.

| File | Used as | Status |
|------|---------|--------|
| `assets/characters/players/casual-male.glb` | Emeka (player), Victor, Obinna, hostiles | IMPORTED · IN USE · VERIFIED |
| `casual-female.glb` | Mama Ngozi, Hauwa | IMPORTED · IN USE · VERIFIED |
| `casual-bald.glb` | Sunday Adeleke | IMPORTED · IN USE · VERIFIED |
| `casual2-male.glb` | Chidi, Tunde | IMPORTED · IN USE · VERIFIED |
| `casual2-female.glb` | pedestrians | IMPORTED · IN USE · VERIFIED |
| `casual3-male.glb` | Femi Ojo | IMPORTED · IN USE · VERIFIED |
| `casual3-female.glb` | Amaka | IMPORTED · IN USE · VERIFIED |
| `suit-male.glb` | Eze Nwosu, Detective Ibrahim | IMPORTED · IN USE · VERIFIED |
| `suit-female.glb` | Ada, Bisi | IMPORTED · IN USE · VERIFIED |
| `worker-male.glb` | Kola, Sergeant Nyame | IMPORTED · IN USE · VERIFIED |
| `worker-female.glb` | pedestrians | IMPORTED · IN USE · VERIFIED |

**Art-direction note:** the source materials are authored near-black; every character is
re-tinted into the Cinder City palette at construction by
`character_rig.gd::_tint_materials()`.

## 2. Animation (1 GLB, 17 clips)

| File | Contents | Status |
|------|----------|--------|
| `assets/characters/anim/animations.glb` | Death, Defeat, Idle, Jump, PickUp, Punch, RecieveHit, Roll, Run, Run_Carry, Shoot_OneHanded, SitDown, StandUp, SwordSlash, Victory, Walk, Walk_Carry | IMPORTED · IN USE · VERIFIED |

Cached to `user://anim_lib_cache.res` at first run. **Delete the cache if clips change.**

## 3. Vehicles (7 GLB)

Source: **Kenney Car Kit** (CC0). Dequantized. Scaled 1.25×, lifted `0.33 × scale`.

| File | Used as | Status |
|------|---------|--------|
| `sedan.glb` | civilian sedan, player-car capable | IMPORTED · IN USE · VERIFIED |
| `hatchback-sports.glb` | civilian, fast | IMPORTED · IN USE · VERIFIED |
| `sedan-sports.glb` (aliased as `muscle.glb`) | muscle car | IMPORTED · IN USE · VERIFIED |
| `van.glb` | van | IMPORTED · IN USE · VERIFIED |
| `taxi.glb` | taxi | IMPORTED · IN USE · VERIFIED |
| `police.glb` | police cruiser | IMPORTED · IN USE · VERIFIED |
| `truck.glb` | truck | IMPORTED · IN USE · VERIFIED |
| `Textures/colormap.png` | shared vehicle colormap | IMPORTED · IN USE · VERIFIED |
| *(none)* | **motorcycle** — built procedurally in `vehicle.gd` from boxes and cylinders | N/A (procedural) |

## 4. Architecture and props

Source: **Kenney City Kit Suburban / Commercial / Roads** (CC0) — geometry language is
reproduced procedurally in `city_builder.gd` (boxes, repeated window quads, emissive
strips) rather than instancing the kits' meshes, to keep draw calls under the Mobile
budget. The kits were used as the **reference for proportion and detail density**; see
`docs/08_DECISION_LOG.md` TDR-004.

| Element | Built by | Status |
|---------|----------|--------|
| Ground slabs | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Roads, lane paint | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Sidewalks, kerbs | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Buildings (8–14 per district) | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Street lamps | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Traffic lights | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Neon strips (tier 3) | `city_builder.gd` | IMPLEMENTED · VERIFIED |
| Interiors (6 rooms) | `interiors.gd` | IMPLEMENTED · VERIFIED |
| Pickups | `pickups.gd` | IMPLEMENTED · IN USE |

## 5. Audio (32 WAV)

**All audio is synthesized from first principles** by `tools/gen_audio.py`. No
third-party samples. Therefore the game carries **no audio licensing obligations**.

| Category | Files |
|----------|-------|
| Ambience (2) | `city_bed`, `rain` |
| Music (4) | `explore`, `tension`, `stinger_alert`, `stinger_complete`, `stinger_mission` |
| SFX combat (9) | `punch_swing`, `punch_hit`, `kick_hit`, `heavy_hit`, `block`, `dodge`, `stagger`, `down`, `explosion` |
| SFX guns (4) | `gun_pistol`, `gun_smg`, `gun_shotgun`, `reload` |
| SFX world (7) | `engine_start`, `engine_loop`, `horn`, `door`, `money`, `pickup`, `step_concrete`, `step_gravel` |
| UI (4) | `click`, `confirm`, `back`, `error` |

Status: IMPORTED · IN USE. **Audio output cannot be verified in the sandbox** (no ALSA
device; Godot falls back to the dummy driver) → playback is **DEVICE-ONLY**.

## 6. Fonts

Godot default theme fonts (open licence, bundled with the engine). No external font files
in the project.

## 7. Generated at runtime (no files)

| Element | Where |
|---------|-------|
| Skyline backdrop (menu/title) | `main_menu.gd::_draw_skyline()`, `boot.gd` |
| Character colour variants | `character_rig.gd::_tint_materials()` |
| Vehicle headlight/tail-light quads | `vehicle.gd::_setup_body()` |
| Motorcycle geometry | `vehicle.gd::_build_fallback_body()` |
| Road/neon/window materials | `city_builder.gd` |

## 8. Screenshots

`shots/` contains rendered frames produced by the verification pipeline. They are
deliverables, not assets. See `docs/15_SCREENSHOT_INDEX.md`.
