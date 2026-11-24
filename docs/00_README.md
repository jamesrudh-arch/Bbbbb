# LEVERAGE — Documentation

**Everyone has leverage on you.**

A third-person open-world crime-action game set in Cinder City.
Built in Godot 4.7.2 (Mobile renderer), targeting iPhone via XOGOT.

D'Youngs Games · 2026

---

## Read in this order

| # | Document | What it answers |
|---|----------|-----------------|
| 00 | `00_README.md` (this file) | What is this project and where do I start |
| 00 | `00_MASTER_DESIGN.md` | What the game is, the pillars, the disciplines, the economy, the story spine |
| 01 | `01_TECHNICAL_ARCHITECTURE.md` | How it is built: autoloads, scene graph, physics layers, animation, rendering constraints, save format |
| 02 | `02_ART_DIRECTION.md` | Why it looks like this: palette, lighting, characters, UI, vehicles |
| 03 | `03_WORLD_DESIGN.md` | Cinder City: six districts, travel, interiors, weather, events |
| 04 | `04_CHARACTERS_AND_STORY.md` | Emeka, Chidi, the 16 named cast, factions, story beats |
| 05 | `05_CONTROL_MAP.md` | Every control, touch and keyboard, and why B is not a conflict |
| 06 | `06_LICENCE_RECORD.md` | What is licensed, from where, with what obligations |
| 07 | `07_ASSET_REGISTER.md` | Every asset, its status (imported / in use / verified) |
| 08 | `08_DECISION_LOG.md` | 17 technical decisions with doc sources, including what was reversed |
| 09 | `09_REQUIREMENTS_TRACEABILITY.md` | **The honest scorecard** — every brief requirement with its status |
| 10 | `10_BUILD_RUN_AND_XOGOT.md` | How to run it, render a frame, and put it on an iPhone |
| 11 | `11_KNOWN_DEFECTS.md` | Open defects, and the 13 resolved ones worth remembering |
| 12 | `12_DEVELOPMENT_STATE.md` | Where the project is right now and the exact next action |
| 13 | `13_TEST_REPORTS.md` | Eight test reports with real commands and real output |
| 14 | `14_CHANGELOG.md` | Version history |
| 15 | `15_SCREENSHOT_INDEX.md` | Every delivered frame and what it proves |

---

## The 60-second version

**What works and has been seen working:** the full opening flow (studio card → title →
content notice → menu), third-person movement and camera, combat with five distinct
disciplines that deal real damage, vehicle entry and physics driving at road speeds,
traffic, police response with a four-level wanted system, enterable interiors, the map and
phone, day/night, and a touch HUD built around X / Y / A / B.

**Test status:** 112 automated assertions pass, zero script errors, and 16 rendered frames
captured from the running game.

**What is not finished:** four of the six story missions have data and objectives but no
bespoke scripted set-pieces. Audio cannot be heard in this environment (no audio device),
and iPhone performance, safe-area insets and touch feel are unverified — they are marked
DEVICE-ONLY and are not claimed.

**Assets:** all third-party assets are CC0 (Quaternius characters and animations, Kenney
vehicles); all 32 audio files are original synthesis; no asset in the game requires
attribution.

## Project layout

```
leverage/
├── project.godot
├── scenes/      boot, main_menu, player, world
├── scripts/     30 GDScript files (~6,000 lines) across autoload/world/character/
│                player/npc/vehicle/systems/ui
├── assets/      19 GLB + 1 texture
├── audio/       32 WAV (all original)
├── tests/       112 assertions
├── shots/       16 delivered frames
└── docs/        this set
```

## Quick commands

```bash
# play
/home/user/tools/Godot_v4.7.2-stable_linux.x86_64 --path /home/user/leverage

# test
/home/user/tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path /home/user/leverage \
  res://tests/test_suite.tscn          # PASSED: 112  FAILED: 0

# render a frame
GD_TIMEOUT=280 bash /home/user/tools/gdview.sh /home/user/leverage \
  --rendering-driver vulkan res://scenes/world.tscn \
  -- --shot /home/user/leverage/shots/check.png --wait 60
```
