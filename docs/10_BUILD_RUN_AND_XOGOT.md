# LEVERAGE — Build, Run & iPhone/XOGOT Verification Guide

---

## 1. Requirements

| Item | Version used | Notes |
|------|--------------|-------|
| Godot | **4.7.2-stable** (`ed1daf0bf`) | Must be 4.x; project uses Godot 4 API throughout |
| Renderer | Mobile (`renderer/rendering_method="mobile"`) | Do not switch to Forward+ for iOS |
| OS (dev) | Linux x86_64 | Windows/macOS work identically |
| iPhone | Any A14+ device | GPU-heavy scenes are Neon Mile at night |
| XOGOT | Current release | Wraps Godot 4 projects for iOS |

## 2. Run on desktop (development)

```bash
cd /home/user/leverage
/home/user/tools/Godot_v4.7.2-stable_linux.x86_64 --path .
```

The game opens at the boot scene: D'Youngs Games → LEVERAGE title → content notice →
main menu → New Game → world.

**Headless test suite (fast sanity check):**
```bash
/home/user/tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  res://tests/test_suite.tscn
# expect: PASSED: 112   FAILED: 0   TOTAL: 112
```

**Script error sweep:**
```bash
bash /home/user/tools/syntax_check.sh
# expect: REAL ERRORS: 0
```

## 3. Render a screenshot (no display required)

This is the verification path used throughout this project — it proves the scene actually
draws, not just that files exist.

```bash
GD_TIMEOUT=280 timeout 320 bash /home/user/tools/gdview.sh \
  /home/user/leverage --rendering-driver vulkan res://scenes/world.tscn \
  -- --shot /home/user/leverage/shots/check.png --wait 60
```

Options passed after `--`:
- `--shot <absolute path>` — where to write the PNG
- `--wait <seconds>` — how long to let the world settle before capturing
- `--district <id>` — start in a specific district
- `--hour <float>` — set the world clock (e.g. `--hour 21.5` for night)

Grep the output for `SHOT_SAVED`. If the first attempt times out (llvmpipe shader
compilation is slow), **retry once** — it usually succeeds on the second run.

## 4. Build for iPhone via XOGOT

> **Status: DEVICE-ONLY.** No step in this section has been executed in this workspace.
> There is no Mac, no Xcode, no iPhone, and no XOGOT runtime here. Everything below is the
> documented procedure, not a verified result.

### 4.1 Export presets

The project is Mobile-rendering and already configured for ETC2/ASTC
(`textures/vram_compression/import_etc2_astc=true`), which is the required texture format
for iOS.

In Godot:
1. **Project → Export → Add… → iOS**.
2. Set a reverse-DNS bundle identifier (e.g. `games.dyoungs.leverage`).
3. Set the app name to `LEVERAGE`.
4. Icons: provide 1024×1024, 180×180, 120×120, 87×87, 80×80, 60×60, 58×58, 40×40, 29×29
   (Xcode asset catalogue).
5. Orientation: **landscape only** (the HUD is laid out for landscape).
6. In **Rendering → Textures**, confirm ETC2/ASTC is selected.
7. Export the `.ipa`/Xcode project.

### 4.2 XOGOT path

XOGOT runs Godot projects on iOS. Two supported routes:

- **XOGOT-ready project folder** — copy the project directory (excluding
  `.godot/` import caches and `node_modules/`) onto the device via XOGOT's project
  browser and open it there.
- **Exported project** — place the exported `.pck` with the XOGOT runtime and launch.

Either way, verify on device:
1. The game reaches the main menu (proves project settings, autoloads and fonts load).
2. **Audio plays.** This is the single most important device check, because audio is the
   one system that could not be verified at all in the sandbox.
3. HUD respects the notch and rounded corners (safe-area insets).
4. Touch targets are reachable with thumbs in landscape.
5. Frame rate in **Neon Mile at night** with wanted level raised — the heaviest scene
   (neon emissive strips, most NPCs, police units, vehicle headlights).
6. A vehicle can be entered and driven with the pedal cluster.

### 4.3 Known device risks

| Risk | Mitigation already in code | Needs device confirmation |
|------|---------------------------|---------------------------|
| Draw-call budget | procedural city, merged materials, 150 m district cull | Yes |
| Light count | unshadowed omnis, distance fade, ≤64 in view | Yes |
| Thermal throttling | quality scaler drops shadow distance + NPC count on sustained >22 ms | Yes |
| Safe area | `DisplayServer.get_display_safe_area()` | Yes |
| Touch latency | buttons are plain `Button` nodes, no per-frame hit testing | Yes |
| Audio buses | master/music/sfx/UI buses configured | Yes |

## 5. Controls on device

Landscape orientation. Left thumb = stick. Right thumb = **X** (punch), **Y** (heavy),
**A** (kick), **B** (dodge / interact). While driving, the diamond is replaced by
throttle, brake, steer and handbrake.

## 6. Project layout for export

Exclude from any package:
- `.godot/` (import cache, rebuilt on open)
- `tools/gt/node_modules/` (not part of the game)
- `shots/` (deliverable screenshots, not runtime assets)
- `docs/` (optional; no runtime dependency)

Include:
- `project.godot`, `scenes/`, `scripts/`, `assets/`, `audio/`, `tests/` (tests are tiny and
  useful for on-device sanity runs).

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| World renders as a black blob | `ambient_light_source` set to SKY with a COLOR background | Set it to COLOR (2) |
| Characters face backwards | model yaw correction missing | `model.rotation.y = PI` |
| Characters are black silhouettes | source materials untouched | `_tint_materials()` must run |
| Cars fall through the world | `CollisionShape3D.shape` is null | assert `shape.shape != null` |
| Car won't move | engine force applied while airborne, or chassis box below the wheels | ground-contact gate; chassis box above axle line |
| Combat scans nothing | sub-systems not wired | `call_deferred("_wire_systems")` |
| Menu is white | a `ColorRect` added full-rect without a colour (default is white) | set `.color` or use a plain `Control` |
| Animations are wrong after editing clips | stale cache | delete `user://anim_lib_cache.res` |
| Imported character GLB has no mesh | meshopt/KHR-quantized GLB | dequantize with `tools/gt/convert.mjs` |
| Render job times out | llvmpipe compiling shaders | retry once; increase `--wait` |
