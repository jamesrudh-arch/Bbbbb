# LEVERAGE — Technical Decision Log

Each decision records the problem, the options considered, the choice, the reason, and
the official documentation source. Decisions marked **REVERSED** record an approach that
was tried and abandoned — do not retry them.

---

## TDR-001 — Engine: Godot 4.7.2, Mobile renderer

**Choice:** Godot 4.7.2-stable (`ed1daf0bf`), `renderer/rendering_method="mobile"`,
forward Mobile pipeline (Vulkan on desktop, Metal on iOS via XOGOT).

**Why:** The brief specifies Godot 4.7 and an iPhone target. The Mobile renderer is the
only pipeline that runs acceptably on iOS; Forward+ is desktop-class and the Compatibility
renderer loses the glow and DOF this art direction uses.

**Source:** Godot rendering docs —
`https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html`
(confirmed under "Mobile": glow, decals, DOF, PCSS supported; SSAO, SSR, SSIL, SDFGI,
VoxelGI, volumetric fog, SSS, TAA, FSR2 **not** supported).

**Consequences recorded:** shadow settings, DOF limits and the ambient-source rule in
`docs/01_TECHNICAL_ARCHITECTURE.md` §7 all derive from this decision.

---

## TDR-002 — City is generated in code, not authored as scenes

**Choice:** `city_builder.gd` builds all six districts procedurally at world load.

**Options considered:**
1. Hand-author six `.tscn` districts in the editor. Best art control, huge scene files,
   slow iteration, and every tweak is a scene diff.
2. Import a Kenney city kit and instance hundreds of meshes. Simple, but blows the
   Mobile draw-call budget and the kits' proportions did not match a 150 m cell.
3. Generate from data with per-district palettes. **Chosen.**

**Why:** one source of truth for layout (`Content.DISTRICTS`), instant global changes
(tier palettes, road pitch), a trivial draw-call budget, and reproducible builds.

**Trade-off accepted:** district art changes are code changes, and there is no visual
level editor workflow.

---

## TDR-003 — Characters sourced from the UAC pack, dequantized

**Choice:** 11 rigged humanoid GLBs from the Quaternius/misty-3d Universal Animated
Character pack, run through glTF Transform to strip meshopt/KHR quantization.

**Why dequantize:** Godot's GLB importer returns `valid=false` **silently** for
meshopt-quantized files — the scene loads with no mesh and no error. This cost real time
to diagnose; the dequantize step is mandatory for this asset family.

**Tooling:** `tools/gt/convert.mjs` (glTF Transform). `node_modules/` is not persisted,
so `npm install` inside `tools/gt` must be re-run before reconverting.

---

## TDR-004 — Kenney city kits used as reference, not as shipped meshes

**Choice:** download and study the Kenney City Kits, then reproduce their proportion and
detail-density language procedurally; ship no kit meshes.

**Why:** draw-call and triangle budget on Mobile, plus a consistent flat-shaded look.
Recorded honestly in the asset register as "reference, not shipped".

---

## TDR-005 — Ambient light source must be COLOR, not SKY

**Choice:** `ambient_light_source = 2` (AmbientSource.COLOR) with `ambient_light_color`
tuned per time of day.

**Why:** `ambient_light_source = 3` (SKY) with `background_mode = 1` (COLOR) and no sky
resource set yields **pure black ambient light**. Symptom: the entire world renders as a
giant black blob with correctly-lit HUD on top. Diagnosed by elimination after several
false starts. **Do not set SKY here.**

**Source:** Godot Environment docs —
`https://docs.godotengine.org/en/stable/classes/class_environment.html`

---

## TDR-006 — CameraAttributes DOF: far plane only

**Choice:** DOF `far_enabled = true`, `far_distance = 280`, `amount = 0.03`,
`near_enabled = false`.

**Why:** close-range DOF on Mobile both costs frame time and smeared the player, who sits
4–5 m from the camera in a third-person setup. Pushing the far plane out keeps the
distance haze without touching the character.

---

## TDR-007 — Vehicle chassis: single box, raised wheel bodies

**Choice:** one `BoxShape3D` for the chassis at `y = 0.72`, four `VehicleWheel3D` at
`y = 0.34`, wheel radius 0.34, rest length 0.24, stiffness 44.

**Why:** multiple chassis boxes made the car catch on kerbs; wheels placed lower than the
box made the box rest on the road and stall the car. The car must hang from the wheels,
not sit on its chassis.

**Critical bug class:** a `CollisionShape3D` whose `shape` is never assigned is
**silently non-colliding**. The car then falls through the world forever. Always assert
`shape.shape != null` when building physics bodies procedurally.

---

## TDR-008 — Engine force is mass-scaled, and only applied when grounded

**Choice:**
```gdscript
var grounded := wheel_contacts() > 0
engine_force = throttle * mass * accel * 0.5 * clampf(1.0 - speed/top, 0.12, 1.0)
```
plus a hard `limit_length(top * 1.15)` safety clamp.

**Why:** a flat multiplier produced 141 m/s traffic and a 427 km/h player car — because
engine force was being applied **while airborne**, accumulating speed with no friction.
Gating on wheel contact and clamping velocity fixed both.

**REVERSED:** do not reintroduce a flat `engine_force` multiplier, and do not apply
engine force without a ground-contact check.

---

## TDR-009 — Character facing: rotate models PI

**Choice:** `model.rotation.y = PI` in `character_rig.gd`.

**Why:** the UAC rigs are authored facing **+Z**; Godot's forward is **−Z**. Without the
correction every character moonwalks — the walk animation plays forward while the model
faces backwards. This was visible in the first renders as the player facing the camera
while walking away from it.

---

## TDR-010 — Character materials re-tinted at construction

**Choice:** `_tint_materials()` replaces surface materials with palette-driven
`StandardMaterial3D`s keyed on the source material name (Skin / Face / Shirt / Pants /
Belt / Hair).

**Why:** the UAC source materials have near-black base colours (skin linear ≈0.013),
which renders as a featureless black head. Re-tinting is what makes characters readable
and gives the cast distinct outfits without new assets.

---

## TDR-011 — Deferred sub-system wiring

**Choice:** `player.gd` calls `_wire_systems()` via `call_deferred` in `_ready()`, which
calls `combat.setup(self)`, `driver.setup(self)`, `interaction.setup(self, interactables)`.

**Why:** `@onready` resolves before a world-instanced player has a valid parent chain in
all cases. Without deferred wiring, `combat.targets` stayed empty (no scanning),
`driver.enter()` always returned false, and interaction prompts never appeared — three
separate-looking bugs with one root cause.

**REVERSED:** do not call `setup()` directly from `_ready()`.

---

## TDR-012 — Interiors at y = −400

**Choice:** build each interior room at `(0, −400, 0)` and teleport the player into it.

**Why:** avoids a scene change (which would destroy world state) and avoids streaming cost.
The distance also guarantees the city's distance-culling never fights the interior.

**Trade-off:** interiors are single rooms, not multi-room buildings, and the world floor
must not be within fall distance (it is 400 m away).

---

## TDR-013 — Animation library cached to disk

**Choice:** build the shared `AnimationLibrary` once per process and persist it to
`user://anim_lib_cache.res` (263 KB).

**Why:** rebuilding 17 clips for every NPC was the dominant construction cost and made
test scenes take 2 minutes to start.

**Operational note:** delete the cache after changing clips.

---

## TDR-014 — Screenshot verification over asset assertions

**Choice:** verify visuals by rendering actual frames under Xvfb with the Vulkan driver
and inspecting the PNGs, never by asserting that a file exists.

**Why:** the brief explicitly forbids presenting imported assets as proof they render. The
black-blob ambient bug, the moonwalking bug, the missing collision shape, the white menu
wash and the black-headed characters were **all** invisible to tests and obvious in a
frame.

**Implementation:** `tools/gdview.sh` + the `--shot` handler in `world.gd`, and dedicated
`--openflow` / `--menuflow` capture modes in `boot.gd` / `main_menu.gd`.

---

## TDR-015 — Test suite runs headless, 112 assertions

**Choice:** `tests/test_suite.tscn`, pure data/state assertions, no rendering.

**Why:** sub-second feedback (1.1 s) on the things that *can* be asserted — content table
shape, economy maths, discipline differentiation, input-map completeness, save round-trip,
control-conflict rules. Rendering correctness is covered by TDR-014 instead.

---

## TDR-016 — Input: literal-letter touch buttons

**Choice:** the four combat buttons are labelled **X Y A B** with colour coding, not
icons.

**Why:** the brief fixes these letters. A player transferring from a controller must see
the same glyph on screen. Icons would require a legend, which is a failure at thumb
distance on an iPhone.

---

## TDR-017 — Save format: JSON in user://

**Choice:** three JSON slots, schema in `docs/01_TECHNICAL_ARCHITECTURE.md` §9.

**Why:** readable, diffable, versionable by field presence, trivially testable round-trip,
and no binary format migration burden at this stage.

**Trade-off:** no integrity checking; a hand-edited save can set any value. Acceptable for
a single-player game.
