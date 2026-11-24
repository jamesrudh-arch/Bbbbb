# LEVERAGE — Screenshot Index

All frames in `shots/` were rendered by this project's own verification pipeline
(`tools/gdview.sh` + Xvfb + Vulkan/llvmpipe) on 2026-11-23. None are mockups, concept art
or AI-generated images: each is a capture of the running game.

---

## Opening flow

| File | Shows | Verified |
|------|-------|----------|
| `open_01_studio.png` | D'Youngs Games presentation card | ✅ |
| `open_02_title.png` | LEVERAGE title: night skyline, gold logotype, "Everyone has leverage on you." | ✅ |
| `open_03_notice.png` | Content notice: fiction, violence warning, no loot boxes / no gambling / no IAP | ✅ |
| `open_04_menu.png` | Main menu: skyline backdrop, 6 items, save-slot status | ✅ |

## Gameplay tour — Ash Row

| File | Shows | Verified |
|------|-------|----------|
| `01_spawn.png` | Player standing on the road, facing away from camera; district HUD "ASH ROW", mission tracker "HOMECOMING", money ₦120, HEAT, touch controls | ✅ |
| `02_walking.png` | Mid-walk up the street; buildings receding, parked car, traffic light, pedestrian | ✅ |
| `03_combat_engaged.png` | Three hostiles engaged in the street; visible character faces, skin tones and outfits | ✅ |
| `04_punching.png` | Player mid-punch next to a hostile; health bar dropping, heat bar visible | ✅ |
| `05_dodge.png` | Dodge/evade frame | ✅ |
| `09_wanted_police.png` | Fight aftermath with heat bar deep in the red; combatants in the street | ✅ |

## Vehicles

| File | Shows | Verified |
|------|-------|----------|
| `06_vehicle_entered.png` | Player seated in a vehicle, speedometer HUD replacing the action column | ✅ |
| `07_driving.png` | Third-person driving: taxi down a street at **78 km/h**, pedestrians, traffic lights, city receding — 4/4 wheel contacts logged | ✅ |
| `08_exited_vehicle.png` | Player back on foot after exiting | ✅ |

## Interior and UI

| File | Shows | Verified |
|------|-------|----------|
| `10_interior.png` | Inside Mama Ngozi's Kitchen: lit room, ceiling, counter, vendor NPC, "INSIDE · Mama Ngozi's Kitchen" label | ✅ |
| `11_map.png` | Cinder City map: all six districts with faction control, tier and lore text | ✅ |
| `12_phone.png` | Phone panel: LEVERAGE OS, contact list of the named cast, Radio and Map entry points | ✅ |

---

## What these frames prove

- The Mobile rendering path works with the world's materials, lights and fog.
- Characters load, are skinned, are re-tinted, face the correct direction and animate.
- The HUD lays out without overlap at 1280×720 (scales to iPhone landscape).
- Combat produces real HP loss on screen and in the log.
- Vehicles have collision, wheels and suspension, and drive.
- Interiors are enterable and lit.
- The map and phone screens render with real content from `Content`.
- The opening flow is complete from studio card to menu.

## What they do **not** prove

- Frame rate on an iPhone (these are software-rasterised frames).
- Audio (the sandbox has no audio device).
- Touch ergonomics or safe-area insets.
- That the motorcycle handles well.
- Anything about App Store readiness.

## District hero shots (2026-11-23, final pass)

| File | Shows | Verified |
|------|-------|----------|
| `final_night_neon.png` | **Neon Mile at 22:20.** Magenta signage on tower faces, lit windows, street lamps, a taxi at the junction, cool blue night ambient. The district's whole identity in one frame. | ✅ |
| `final_golden_vesper.png` | **Vesper Heights at 18:58.** Cold glass towers, security-white window grids, wide clean paving. HUD correctly reads VESPER HEIGHTS — the tier-3 "money is cold here" read. | ✅ |
| `final_night_ironyard.png` | **Iron Yard at 21:10.** Industrial night, lit window grids against dark masses, distant traffic. HUD correctly reads IRON YARD. | ✅ |

## Older exploratory renders

`r1..r8.png`, `night.png`, `night2.png`, `world_day.png` are earlier diagnostic frames kept
for the record; they show the progression from a black-blob world to the current look.
`day.png` / `menu.png` `.import` stubs are leftovers from a removed asset and can be
deleted.
