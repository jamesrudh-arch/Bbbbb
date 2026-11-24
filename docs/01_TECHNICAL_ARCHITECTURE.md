# LEVERAGE — Technical Architecture

Godot 4.7.2 · Mobile renderer · GDScript · target iPhone (XOGOT)

---

## 1. Project layout

```
leverage/
├── project.godot              # engine config, autoloads, input map, rendering
├── scenes/
│   ├── boot.tscn              # D'Youngs -> title -> content notice -> menu
│   ├── main_menu.tscn         # New / Continue / Load / Settings / Credits / Quit
│   ├── player.tscn            # CharacterBody3D + rig + systems + camera
│   └── world.tscn             # World root: city, traffic, NPCs, police, HUD
├── scripts/
│   ├── autoload/              # singletons: Game, Audio, Content, Loader, Events, Controls
│   ├── world/                 # world.gd, city_builder.gd, world_streamer.gd
│   ├── character/             # character_rig.gd (shared rig + animation library)
│   ├── player/                # player, camera_rig, combat, driver, interaction
│   ├── npc/                   # actor.gd (pedestrian, hostile, vendor, police on foot)
│   ├── vehicle/               # vehicle.gd (VehicleBody3D: car + bike, player + AI)
│   ├── systems/               # traffic, police, npc_population, interiors,
│   │                          # mission_manager, interaction_system, pickups
│   └── ui/                    # boot.gd, main_menu.gd, hud.gd
├── assets/
│   ├── characters/players/    # 11 rigged GLBs (dequantized)
│   ├── characters/anim/       # animations.glb — 17 shared clips
│   └── models/vehicles/       # 7 Kenney car GLBs + colormap texture
├── audio/                     # 32 WAVs (ambience, music, sfx, ui)
├── tests/                     # test_suite.tscn — 112 assertions
├── shots/                     # rendered screenshots
└── docs/                      # this documentation set
```

## 2. Autoload singletons

All six are registered in `project.godot` and load before any scene.

| Autoload | Script | Responsibility |
|----------|--------|----------------|
| `Content` | `autoload/content.gd` | Pure data: 16 characters, 6 districts, 5 disciplines, missions, shops, interiors, vehicles, radio, weapon definitions. No logic. |
| `Game` | `autoload/game.gd` | Runtime state: money, heat, reputation, trust, discipline, inventory, health, stamina, wanted level, save/load slots, stats, achievements. |
| `Audio` | `autoload/audio_director.gd` | Bus routing, music crossfade, positional SFX, UI sounds, volume settings. |
| `Loader` | `autoload/scene_loader.gd` | Scene transitions with fade; `goto_world(fresh)`. |
| `Events` | `autoload/events.gd` | Global signal bus (crime, combat, mission events, notifications). |
| `Controls` | `autoload/controls.gd` | Authoritative input map; builds touch UI spec; maps touch buttons to actions. |

**Design rule:** `Content` holds data, `Game` holds state, everything else holds
behaviour. No scene script reads a hardcoded table that belongs in `Content`.

## 3. Scene graph at runtime

```
World (Node3D, world.gd)
├── WorldEnvironment          # fog, tonemap, ambient — see §7
├── DirectionalLight3D        # sun/moon, angle driven by time of day
├── Districts (Node3D)
│   └── ash_row (Node3D)      # per district, built once by city_builder.gd
│       ├── Ground            # StaticBody3D + 150x150 collision slab
│       ├── Roads             # asphalt slabs + lane paint + neon strips (tier>=3)
│       ├── Sidewalks
│       ├── Buildings         # each with collision + enterable ground floor
│       └── Props             # lamps, traffic lights, bins, stalls, parked cars
├── Traffic (Node, traffic.gd)      # 16 AI vehicles across districts
├── NPCs   (Node, npc_population.gd)# ~25 pedestrians, 16 named, schedules
├── Police (Node, police.gd)        # wanted-level responder spawning + pursuit
├── Pickups(Node, pickups.gd)
├── Interactables (Node)            # doors, shops, mission markers
├── Player (CharacterBody3D, player.tscn)
│   ├── Visual/Rig (character_rig.gd)    # GLB + AnimationTree
│   ├── CollisionShape3D
│   ├── CameraRig (camera_rig.gd)        # SpringArm3D + Camera3D
│   ├── Combat, Driver, Interaction      # the three player sub-systems
│   └── TouchControls (CanvasLayer)
└── HUD (CanvasLayer, hud.gd)      # money, health, heat, mission, minimap,
                                   # action buttons, phone, map, pause
```

## 4. Player sub-system wiring (important)

`player.gd` owns three sub-nodes. Each needs a reference to the player and, for
interaction, the world's interactable list. Because `@onready` timing differs between
an instanced world and a directly-run player scene, wiring is **deferred one frame**:

```gdscript
func _ready() -> void:
    call_deferred("_wire_systems")

func _wire_systems() -> void:
    combat.setup(self)
    driver.setup(self)
    interaction.setup(self, world.interactables)
```

**Do not remove this.** Without it, `combat.targets` is always empty (no scanning),
`driver.enter()` returns false, and interaction prompts never appear. This was a real
bug that cost a full day; see `docs/11_KNOWN_DEFECTS.md` D-001.

## 5. Physics layers

| Bit | Layer | Used by |
|-----|-------|---------|
| 1 | `world` | ground, buildings, props, vehicles |
| 2 | `player` | player capsule |
| 3 | `npc` | pedestrian/hostile capsules |
| 4 | `vehicle` | VehicleBody3D |
| 5 | `interact` | interaction trigger areas |
| 6 | `pickup` | pickup areas |

Camera `SpringArm3D` collides with `1 | 8` so it never pushes through walls but also
never jitters on NPCs.

## 6. Animation

`character_rig.gd` is the single place characters are constructed.

1. Load `assets/characters/players/<name>.glb`, scale by `scale_factor`, lift by
   `1.0 * scale_factor` (the source rigs are origin-centred, the world is floor-origin).
2. Rotate `model.rotation.y = PI` — the source characters are authored facing **+Z**,
   Godot's forward is **−Z**. Without this every character moonwalks.
3. Build an `AnimationLibrary` from `assets/characters/anim/animations.glb` **once per
   process** and cache it to `user://anim_lib_cache.res` (263 KB). Rebuilding it per NPC
   was the single biggest construction cost.
4. Attach an `AnimationPlayer` + `AnimationTree`; the tree path must be resolved *after*
   the node enters the tree.
5. `play(clip, speed)` blends between locomotion and action clips with a 0.18 s crossfade.

Available clips (17): Death, Defeat, Idle, Jump, PickUp, Punch, RecieveHit, Roll, Run,
Run_Carry, Shoot_OneHanded, SitDown, StandUp, SwordSlash, Victory, Walk, Walk_Carry.

⚠️ **Delete `user://anim_lib_cache.res` if you change animation clips** or the old
library will be reused.

## 7. Rendering — Mobile renderer constraints

Verified against the official renderer documentation
(`https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html`).

**Supported on Mobile:** glow, decals, depth-of-field, PCSS soft shadows, up to 8
omni/spot lights per mesh (256 per view), 8 directional lights, fog.

**Not supported on Mobile:** SSAO, SSR, SSIL, SDFGI, VoxelGI, volumetric fog,
subsurface scattering, TAA, FSR2.

**Consequences baked into this project:**

- Shadows use 4 splits, `max_distance = 80`, `bias 0.06`, `normal_bias 1.6`, blur 1.2.
- `CameraAttributes` DOF has the **near plane off** and a far plane of 280 m at amount
  0.03 — close-range DOF on Mobile smeared the player at 4–5 m, which is exactly the
  third-person camera distance.
- Ambient uses `ambient_light_source = 2` (**COLOR**), not SKY. With
  `background_mode = 1` (COLOR) and no sky, source SKY yielded **pure black ambient**
  and a giant black blob over the world. This is the single most destructive visual bug
  this project hit; see `docs/11_KNOWN_DEFECTS.md` D-002.
- No SSAO/SSR is used anywhere; contact shading is faked with a soft shadow + darker
  ground albedo under buildings.

## 8. Streaming and distance simulation

`world_streamer.gd` + `world.gd`:

- The city is built **once** at world load (six districts, ~1 second).
- Districts further than 150 m from the player have `Traffic`, `NPCs` and `Props`
  sub-nodes hidden and their NPC `_physics_process` disabled (process-mode toggle, not
  free). This keeps the node count low without rebuild cost.
- Traffic vehicles beyond 90 m stop steering and coast (distance sim).
- NPCs beyond 60 m switch to a 0.33 s tick.

## 9. Save/load

Slots are JSON in `user://slot_<n>.json` via `Game.save_game(slot)`:

```json
{
  "saved_at": "2026-11-23T09:14:22",
  "district": "Ash Row",
  "position": [-200.0, 0.35, -46.0],
  "money": 120,
  "heat": 12.0,
  "reputation": 0,
  "trust": {"family": 10, "corporation": 0, "crew": -5},
  "disciplines": ["brawler"],
  "inventory": {...},
  "mission_id": "m02_homecoming",
  "mission_step": 2
}
```

Three slots. The menu reads slot metadata without loading the world.

## 10. Performance budget (Mobile, iPhone-class)

| Metric | Budget | Notes |
|--------|--------|-------|
| Draw calls | < 900 | District meshes are merged per material where possible |
| Triangles | < 900k | Characters 2–4k tris each; buildings are boxes |
| Lights per view | < 64 | Lamps are unshadowed omnis with distance fade |
| Physics bodies | < 220 | 16 traffic + 8 parked + 25 NPCs + props |
| Script time | < 6 ms | NPC AI ticks at 3 Hz when distant |

`world.gd` exposes a quality scaler that drops shadow distance and NPC population when
the frame time exceeds 22 ms for 2 seconds.

## 11. Testing

`tests/test_suite.tscn` runs **112 assertions** headless in ~1.1 s:

```bash
Godot --headless --path /home/user/leverage res://tests/test_suite.tscn
# PASSED: 112   FAILED: 0   TOTAL: 112
```

Coverage: autoload integrity, content table shape (characters/districts/disciplines/
missions/shops/interiors), discipline stat differentiation, economy maths (money, heat,
wanted thresholds, trust), inventory and weapon rules, save/load round-trip, input map
completeness, control-conflict rules (B = dodge in combat, interact outside), and world
data consistency.

## 12. Rendering verification pipeline

The game is verified by rendering real frames, not by asserting that assets exist:

```bash
GD_TIMEOUT=280 bash /home/user/tools/gdview.sh /home/user/leverage \
  --rendering-driver vulkan res://scenes/world.tscn \
  -- --shot /home/user/leverage/shots/x.png --wait 60
```

`gdview.sh` starts Godot under Xvfb `:97` with `--rendering-driver vulkan`
(llvmpipe), waits, captures the viewport, and writes a PNG. The `--shot` handler lives in
`world.gd` (`_handle_shot_args`) and uses `get_viewport().get_texture().get_image()`
after two `process_frame` awaits.

## 13. Known architectural limits

- City geometry is generated at load, not authored per-district in the editor. This keeps
  the project one-file-per-system but means district tweaks are code changes.
- Interiors are built at `y = -400` (below the city) rather than as separate scenes, to
  avoid a scene change; they are single rooms, not multi-room buildings.
- Traffic uses waypoint graphs per district, not a global navmesh, so long cross-district
  drives follow road centrelines rather than turning at every junction.
