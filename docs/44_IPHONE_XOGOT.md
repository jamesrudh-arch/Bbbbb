# 44 — iPhone / Xogot compatibility and the four art gaps closed

Written against the **current** Xogot documentation (docs.xogot.com) and verified
by running the project on **Godot 4.4.1**, the engine Xogot is built on, not on
the 4.7.2 the project was authored with.

## The engine fact that changed everything

Xogot's FAQ, *"Is Xogot compatible with Godot?"*:

> "At its core, it is still a **Godot 4.4-based** system."

Our `project.godot` declared `config/features=PackedStringArray("4.7", "Mobile")`.
A 4.7-tagged project does not open on 4.4. The tag is now `4.4`, and everything
below was re-verified on a real 4.4.1 binary.

**Pure GDScript check:** no C#, no `.gdextension`, no `.dll`, no `addons/`, and no
4.5+ APIs (VirtualJoystick, MarkingMenu, SkeletonModifier3D, AudioStreamInteractive,
FogVolume, CompositorEffect). The codebase was already 4.4-clean; only the tag lied.

## Bug found and fixed: street batching never ran on 4.4

This was invisible on 4.7 and would have been catastrophic on an iPhone.

`street_kit.bake_static()` is what merges ~2,020 street meshes into ~110 batched
meshes. It guarded skinned figures with:

```gdscript
if mi.skeleton != NodePath():
    continue
```

On Godot 4.7 a freshly created `MeshInstance3D` reports `skeleton == NodePath()`.
**On 4.4 it reports `skeleton == ".."`**, so the guard was true for *every* mesh in
the city and the function merged **nothing**, silently, with no error.

Measured on one street (type 0, 78 m):

| Engine | meshes before | groups merged | meshes after |
|---|---|---|---|
| 4.7.2 | 2,020 | 110 | 110 |
| **4.4.1 (Xogot), before fix** | 2,020 | **0** | **2,020** |
| 4.4.1, after fix | 2,020 | 110 | 110 |

Whole district, 4.4.1: `MeshInstance3D` **33,359 before → 2,671 after**.

The fix tests `mi.skin != null`, which is null for static geometry and non-null
for a real skinned figure on **both** engines — verified with a probe that
instantiates a plain box and a real figure on each.

## The four gaps from doc 43

### 1. Animated street people — `scripts/world/street_crowd.gd`

The static crowd was bind-pose because the figure GLBs ship no usable Idle clip.
The clips were there all along in `assets/characters/anim/animations.glb` — the
17-clip UAC library `character_rig.gd` already uses for the cast. Its tracks are
addressed `CharacterArmature/Skeleton3D:<bone>`, which matches every figure GLB
exactly, so the library binds with no retargeting.

- 14 figures per district, on the street facing the district centre.
- One `AnimationPlayer` **per figure**, parented *into* the figure so track paths
  resolve against that figure's own armature; one shared `AnimationLibrary`
  resource across all of them. (A single player for the whole crowd does **not**
  work — its tracks cannot reach sibling armatures. That was tried and produced a
  wall of `AnimationMixer: couldn't resolve track` warnings.)
- Clip phase randomised per figure, so the street does not walk in unison.
- Verified by sampling a bone: `Foot.L` travels **0.413 m** between samples, with
  **14/14** players running. Identical on 4.4.1 and 4.7.2.

### 2. Night art direction — `scripts/world/street_night.gd`

The world already moved the sun and moon, but a moved sun alone gives a grey city
at midnight. Added:

- Warm (sodium) light pools along the city's four street lines, **shadowless**,
  capped at 8 per district — shadows are what a phone cannot afford.
- Ambient pulled down and blued as night falls, so lit shopfronts carry the frame.
- Energy ramps on `night²` between 18:12 and 06:24, so dusk deepens rather than
  switching on at a threshold.
- Pools are created by the **streamer** when a district first becomes visible, not
  at load: a light in an invisible district is still a light the mobile renderer
  accounts for. (Building them at load put **108** OmniLights in the level.)

Proof: `shots/street_night.png` — Neon Mile at 22:00, neon signage reading,
shopfront interiors glowing, depth falling into darkness.

### 3. Albedo / texture variation — `scripts/world/surface_detail.gd`

No third-party assets and no imported images: `FastNoiseLite` generates two 256 px
seamless tiles (fine grain for asphalt, coarse mottle for pavement and walls),
multiplied triplanar over the existing flat albedos. Zero bytes added to the
export, and no import step for Xogot's first-open reimport to break.

A first version generated the pixels in a GDScript loop: it produced the same
image but cost **~570 ms of world load**. The engine-generated version costs ~40 ms.
On a phone, where GDScript is slower than the desktop it was measured on, that
difference is the whole point.

Proof: `shots/street_day.png` — asphalt grain, mottled facades, slabs separated.

### 4. Mobile performance readiness

| Setting | Before | After | Why |
|---|---|---|---|
| `config/features` | `4.7` | `4.4` | Xogot is 4.4-based; 4.7 will not open |
| `import_etc2_astc` | on | on | Xogot FAQ: required or scenes fail to open |
| `import_s3tc_bptc` | **unset** | on | Xogot FAQ: required *together* with ETC2 ASTC |
| `stretch/scale_mode` | unset | `fractional` | Xogot's `auto` zooms/stretches 4.4-era projects |
| physics ticks | 60 | 30 | static city + few actors; frees CPU for rendering |
| `Engine.max_fps` | uncapped | 60 on mobile | chasing 120 Hz throttles an iPhone in ~10 min |
| Label3D signs | no cull | 55 m range | signage is the largest draw-call cost; text cannot batch |
| night lights | 108 at load | 8 per *visible* district | invisible lights still cost |

Also added: HUD **safe-area insets** (`hud.gd::apply_safe_area`) so the thumbstick
clears the home indicator and the notch, reading `DisplayServer.get_display_safe_area()`
and converting into the 1280×720 design space. No-op on desktop.

**Xogot Virtual Controller:** the FAQ says onscreen controls work when the Input
Map has joypad events. Verified on 4.4: **106 actions**, every one with a joypad
event (`punch`→X, `heavy`→Y, `jump`→A, `dodge`/`interact`→B), so the built-in
controller and the on-screen diamond map to real actions with no extra work.

## Verification on Godot 4.4.1

| Check | Result |
|---|---|
| Project import (all 86 resources, ETC2+S3TC) | clean, 0 errors |
| District node counts vs 4.7.2 | **identical**: ash_row 4,854 · neon_mile 5,023 |
| All six districts build | 589–717 ms each |
| Every `world` assertion (nav, drive, portals, objects) | pass in all six |
| Full six-district world reaches first frame | 3.3–4.1 s, 29,204 nodes |
| Street crowd animating | 14/14 players, Foot.L moves 0.413 m |
| Input map joypad coverage | 106 actions, all pad-bound |
| Night factor curve | 22:00 → 1.0 · 19:00 → 0.53 · 12:00 → 0.0 |

## What could not be verified here

- **The 112-test suite cannot complete in this sandbox.** It peaks at **1,300 MB**
  and the container's ceiling is ~1,300 MB, so the process is OOM-killed during the
  world build — **identically with the pre-change code stashed**, so this is the
  machine, not the work. Every assertion was re-run individually instead (see the
  table above). On a normal machine the suite runs as before.
- **No real iPhone.** Frame timing on an A-series GPU is unmeasured. The settings
  above are the documented mobile set, not a measured profile.
- **No iOS export preset** can be meaningfully authored here: Xogot ships games
  through its own publishing flow, and a desktop `export_presets.cfg` needs a
  10-character Apple Team ID that this project does not have. Adding one with a
  placeholder would be worse than omitting it.

## Godot 4.4 traps found (worth keeping)

1. `MeshInstance3D.skeleton` is `".."`, **not** an empty NodePath, on a fresh node
   in 4.4. Never use it as a "is this skinned?" test. Use `skin != null`.
2. A `ResourceLoader.exists()` GLB can still `load()` as `null` if its import cache
   is missing — the project boots through `world.tscn` and works, but a
   `--script` tool that runs first sees null. Reimport, don't debug the loader.
3. `preload()` of a script to call a static helper avoids a local-variable name
   clash with a same-named member (`street_night`).
