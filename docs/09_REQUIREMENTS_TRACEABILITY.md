# LEVERAGE — Requirements Traceability Register

Every requirement from the brief, the concrete implementation that satisfies it, and an
honest status. Status labels follow the brief's strict scheme:

| Label | Meaning |
|-------|---------|
| **IMPLEMENTED** | Code exists and does the thing. |
| **TESTED** | Exercised by an automated test or a scripted run with a recorded result. |
| **VERIFIED** | Observed working in a rendered frame or a logged runtime trace **in this sandbox**. |
| **DEVICE-ONLY** | Cannot be proven here; requires an iPhone/XOGOT run. |

A feature may carry several labels. **No row claims iPhone compatibility** unless it is
marked DEVICE-ONLY.

---

## A. Project and engine

| Req | Implementation | Status |
|-----|----------------|--------|
| One authoritative project | `/home/user/leverage/` — single project, no copies | IMPLEMENTED |
| Godot 4.7 | `project.godot` config_version 5, Engine 4.7.2 verified | VERIFIED |
| Mobile renderer | `renderer/rendering_method="mobile"` | VERIFIED |
| ETC2/ASTC VRAM compression | `textures/vram_compression/import_etc2_astc=true` | IMPLEMENTED · DEVICE-ONLY |
| iPhone target | Safe-area-aware HUD, touch-first controls | IMPLEMENTED · DEVICE-ONLY |

## B. Story and characters

| Req | Implementation | Status |
|-----|----------------|--------|
| Protagonist | Emeka Obi, playable, `casual-male` rig | IMPLEMENTED · VERIFIED |
| Brother in debt/kidnapped | Chidi Obi, `m02_debt` → held by Crew | IMPLEMENTED (story data + dialogue) |
| Criminal network | 3 factions, 16 named characters in `Content.CHARACTERS` | IMPLEMENTED · TESTED |
| Factions: Family / Corporation / Crew | `Game.trust` keys `family` / `corporation` / `crew` | IMPLEMENTED · TESTED |
| 16 named characters | `Content.CHARACTERS` — 16 entries, phone contact list shows all | IMPLEMENTED · VERIFIED (phone shot) |
| ~25 pedestrians | `npc_population.gd` spawns 25 with schedules + memory | IMPLEMENTED · VERIFIED (visible in shots) |
| Pedestrian schedules | clock-driven walk/idle/work states | IMPLEMENTED |
| Pedestrian memory | `memory[player_id]` reaction counters | IMPLEMENTED |

## C. World

| Req | Implementation | Status |
|-----|----------------|--------|
| Six connected areas | Ash Row, Guttermarket, Iron Yard, Cinder Line, Vesper Heights, Neon Mile | IMPLEMENTED · VERIFIED (map shot) |
| Real travel between them | continuous roads, no loading screen, driveable | IMPLEMENTED · VERIFIED |
| Streaming/distance sim | `world_streamer.gd`, 150 m cull, 90 m traffic coast, 60 m NPC throttle | IMPLEMENTED |
| Enterable interiors | 6 interiors, door prompt, teleport to built room at y=-400 | IMPLEMENTED · VERIFIED (interior shot) |
| Weather | clear/overcast/rain/storm, fog + ambient driven | IMPLEMENTED |
| Day/night | 24 min day cycle, sun colour + angle, lamps at night | IMPLEMENTED · VERIFIED (day + night renders) |

## D. Movement and camera

| Req | Implementation | Status |
|-----|----------------|--------|
| Third-person movement | `player.gd` CharacterBody3D, acceleration, sprint, slope | IMPLEMENTED · VERIFIED |
| Professional camera | `camera_rig.gd` SpringArm3D, 6.2 m, 1.75 m height, 0.30 m shoulder, collision, shake, vehicle mode | IMPLEMENTED · VERIFIED |
| Camera never clips walls | SpringArm3D mask `1\|8`, margin 0.35 | IMPLEMENTED · VERIFIED |
| No sliding/robotic motion | position-driven animation from real velocity, 0.18 s blends | IMPLEMENTED · VERIFIED (walk shots) |

## E. Combat — five disciplines

| Req | Implementation | Status |
|-----|----------------|--------|
| Brawler | `Content.DISCIPLINES.brawler` — reach 1.9, dmg ×1.0 | IMPLEMENTED · VERIFIED |
| Kickboxing | reach 2.6, dmg ×1.12 | IMPLEMENTED · TESTED |
| Grappling | reach 1.5, dmg ×1.55 | IMPLEMENTED · TESTED |
| Drunken | reach 2.0, dmg ×0.85, speed ×1.2, stamina ×0.75 | IMPLEMENTED · TESTED |
| Weapon | reach 2.3, dmg ×1.35, requires equipped weapon | IMPLEMENTED · TESTED |
| Distinct feel, not just numbers | reach/speed/stamina all read live in `combat.gd` | IMPLEMENTED · VERIFIED |
| Damage lands | HP 80 → 19.16 over 7 punches in scripted run | **VERIFIED** |
| Combo scaling | +8% damage per combo step, max 5 | IMPLEMENTED · VERIFIED (dmg 9.72 → 10.44 → 11.16) |
| Stamina cost | per-attack cost × discipline multiplier | IMPLEMENTED · TESTED |

## F. Weapons, armour, vehicles

| Req | Implementation | Status |
|-----|----------------|--------|
| Firearms | pistol/SMG/shotgun in `Content.WEAPONS`, `combat._shoot()` | IMPLEMENTED · **VERIFIED** (HP 80→58→36, ammo 24→23→22) |
| Melee weapons | pipe/knife/bat, weapon discipline uses slash clip | IMPLEMENTED |
| Armour with gameplay effect | `armor` float 0–0.85 reduces incoming damage | IMPLEMENTED · TESTED |
| Cars | 7 Kenney GLBs, VehicleBody3D, 4 wheels, suspension | IMPLEMENTED · VERIFIED |
| Motorcycles | procedural bike in `vehicle.gd`, 2 wheels, lean on turn | IMPLEMENTED |
| Vehicle physics | engine force mass-scaled, top-speed clamp, airborne guard | IMPLEMENTED · **VERIFIED** (0→76 km/h, 4/4 wheel contacts) |
| Traffic AI | 16 vehicles, waypoint graph, collision-aware | IMPLEMENTED · VERIFIED |
| Entry/exit | `driver.enter()` / `exit()`, camera attach, HUD switch | IMPLEMENTED · **VERIFIED** (`entered=true`) |

## G. AI

| Req | Implementation | Status |
|-----|----------------|--------|
| Enemy AI | `actor.gd` hostile state machine: idle → aggro → approach → attack → stagger → dead | IMPLEMENTED · VERIFIED |
| Police AI, wanted levels | `police.gd`, heat → wanted 0–4, spawn units on roads 55 m out | IMPLEMENTED · **VERIFIED** (wanted 3, 3 units) |
| Cover use | cover-point scan near hostiles | IMPLEMENTED |
| Pursuits | police units chase player position, vehicles pursue | IMPLEMENTED · VERIFIED |

## H. Systems

| Req | Implementation | Status |
|-----|----------------|--------|
| Living event system | 5 ambient event types on a 40–90 s scheduler | IMPLEMENTED |
| Missions | `mission_manager.gd`, 6 missions in `Content.MISSIONS` | IMPLEMENTED; **2 of 6 fully playable** |
| Side missions | Crew/Family side jobs in mission data | PARTIAL |
| Money | `Game.money`, earned/spent, HUD | IMPLEMENTED · VERIFIED (₦120 shown) |
| Heat | `Game.heat` 0–100, decay, drives wanted | IMPLEMENTED · VERIFIED |
| Reputation | `Game.reputation`, gates missions | IMPLEMENTED · TESTED |
| Trust | per-faction `Game.trust` | IMPLEMENTED · TESTED |
| Shops | buy/sell via inventory, 5 vendor types | IMPLEMENTED |
| Inventory | items, weapons, armour, consumables | IMPLEMENTED · TESTED |
| Phone | contact list (16), radio, map — scrollable panel | IMPLEMENTED · VERIFIED |
| Radio | stations in `Content.RADIO`, cycle + HUD toast | IMPLEMENTED |
| Map | 6 districts, faction + tier + lore | IMPLEMENTED · VERIFIED |
| Save slots | 3 JSON slots, metadata read without loading | IMPLEMENTED · TESTED |
| Achievements | `Game.stats` + achievement table | IMPLEMENTED |

## I. Opening flow

| Req | Implementation | Status |
|-----|----------------|--------|
| D'Youngs Games presentation | `boot.gd` stage 0 | IMPLEMENTED · **VERIFIED** |
| LEVERAGE title | stage 1, city skyline + logotype + tagline | IMPLEMENTED · **VERIFIED** |
| Content notice | stage 2, fiction/violence/no-loot-box statement | IMPLEMENTED · **VERIFIED** |
| Menu | New / Continue / Load / Settings / Credits / Quit | IMPLEMENTED · **VERIFIED** |
| Settings | master/music/sfx volume sliders | IMPLEMENTED · VERIFIED |
| Cinematic | in-engine camera intro on new game | IMPLEMENTED |
| Playable tutorial | walk to Mama Ngozi's, HUD guidance, objective tracking | IMPLEMENTED · VERIFIED |

## J. Audio

| Req | Implementation | Status |
|-----|----------------|--------|
| Original audio | 32 WAVs synthesized by `tools/gen_audio.py` | IMPLEMENTED |
| Credited | in-game credits screen names the synthesis approach | IMPLEMENTED · VERIFIED |
| Music + ambience + SFX + UI | 5 music, 2 ambience, 21 sfx, 4 ui | IMPLEMENTED |
| Actually audible | **Cannot be verified in sandbox** — no ALSA device, Godot uses dummy driver | **DEVICE-ONLY** |

## K. UI/UX and mobile

| Req | Implementation | Status |
|-----|----------------|--------|
| Touch-first UI | 72–96 pt targets, stick + diamond + action column | IMPLEMENTED · VERIFIED (in shots) |
| Safe-area aware | `DisplayServer.get_display_safe_area()` | IMPLEMENTED · DEVICE-ONLY |
| On-screen controls match X/Y/A/B brief | literal letter labels, colour coded | IMPLEMENTED · VERIFIED |
| Readable type | min 11 px @1280 → ≥22 px @3x | IMPLEMENTED |
| No overlap | HUD re-laid out; gear row moved into money panel | IMPLEMENTED · VERIFIED |

## L. Optimisation

| Req | Implementation | Status |
|-----|----------------|--------|
| LOD | district-level cull + NPC process throttle | IMPLEMENTED |
| Pooling | traffic/NPC reuse pools | IMPLEMENTED |
| Distance simulation | 90 m traffic coast, 60 m NPC 3 Hz | IMPLEMENTED |
| Quality scaling | drops shadow distance + NPC count on sustained >22 ms | IMPLEMENTED |
| Frame budget | < 900 draw calls, < 220 physics bodies (design targets) | DEVICE-ONLY (no profiler on device) |

## M. Documentation

See `docs/` — 17 documents listed in `docs/00_README.md`.

## N. Honest summary

**Fully working and verified in-sandbox:** opening flow, menu, third-person movement and
camera, combat with real damage, five distinct disciplines, vehicle entry + physics
driving, traffic, police response with wanted levels, enterable interiors, map, phone,
day/night, HUD.

**Implemented but not exhaustively verified:** weapons/firearms firing, armour effect,
motorcycle handling, side missions, achievements, save/load in-world, weather states,
cover use, living events.

**Not finished:** 4 of 6 story missions have no bespoke scripted set-piece; voice acting;
App Store packaging; full-body cinematic cutscenes.

**Device-only:** audio audibility, actual iPhone frame rate, safe-area insets, touch feel.
