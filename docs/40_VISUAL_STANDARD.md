# LEVERAGE — Visual Standard

**Date:** 23 Nov 2026
**Commit:** `5c640af`
**Status:** first pass done. The remaining gap is art, not code.

---

## 0. What was wrong, stated plainly

The user's assessment was correct: the scene was flat, generic and childish.
Not subjective — measurable. Six defects, all confirmed by reading the scene
file and rendering a frame:

| # | Defect | Effect on screen |
|---|---|---|
| 1 | `background_mode = 1` | **No sky at all.** The background was a single flat colour fill. |
| 2 | `ambient_light_energy = 1.35` | Ambient light so strong it cancelled every shadow. Nothing had form. |
| 3 | `tonemap_white = 3.2` | Highlights clipped to white; the ground was blown out. |
| 4 | Windows on one face only | Every building read as a flat cardboard cut-out from five of six angles. |
| 5 | Every building the same box | No silhouette variation. A skyline of identical slabs. |
| 6 | `fog_density = 0.006` | No atmospheric depth; objects at 100 m looked as close as objects at 10 m. |

Beneath those: the models are **stock low-poly chibi assets** with oversized
heads and hair, and the vehicles are primitives with wheels.

---

## 1. What the research said (and what it changed)

**Godot renderer feature table** — volumetric fog is **not supported on the
Mobile renderer**. This project targets mobile, so depth/height fog is the only
option available. Any spec calling for volumetric fog is wrong for this
platform and is not attempted.

**Godot lighting guidance** — tonemap should be AgX or Filmic rather than
Linear; ambient energy should sit in **0.3–0.8**, not above 1.0; glow levels
should stay at 4–5 or fewer on mid-range hardware; SDFGI must be off for mobile.

**Art-direction writing on stylisation** — the recurring points across sources:

- *Stylisation is not simplification, it is intentional abstraction.* Detail is
  removed because it dilutes the signal, not because it is hard to make.
- *Contrast is a readability tool.* Foreground must separate from background;
  the eye must be told where to look.
- *Silhouette variation comes before detail.* If the silhouette is a box, no
  texture will save it.
- *A post-process grade is what makes individually-authored assets read as one
  world.* This is why `adjustment_contrast`/`saturation` matter more than any
  single asset.
- *Lighting is the single biggest factor separating amateur from production.*

That last point is why the fix looked nothing like "add more detail". The
detail was never the problem — the light was.

---

## 2. What changed

**Sky.** `background_mode = 2` with a `ProceduralSkyMaterial`: deep blue zenith
into a warm dusk horizon, `sky_curve` 0.14 for a tight gradient band.

**Light.** Ambient dropped from 1.35 to **0.42**, sourced from the sky at 0.85
contribution. The sun was warmed to `(1, 0.86, 0.66)` and raised to 3.1 energy.
Shadows now have value instead of being cancelled.

**Tone.** ACES at white point **6.0**, exposure **1.06**, contrast 1.14 and
saturation 1.22. Glow at 0.85 intensity with a 0.95 HDR threshold, so only the
genuinely bright things — windows, neon — bloom.

**Fog.** Density **0.0035**, `sky_affect = 0.0`. An intermediate attempt at
0.018 washed the entire frame pale lavender and desaturated the sky; that was
caught by rendering and corrected. Depth fog at this density gives distance
separation without greying the image.

**Buildings.** Three footprint classes (narrow tower, slab, wide block), a
recessed dark plinth at ground level, windows on **all four faces**, a cornice
overhang at the roofline, an optional vertical band to break the monolith, and
a setback crown on buildings of five floors or more. This is silhouette
variation first, detail second.

**Camera.** Spring arm 6.2 → 6.8 m, follow height 1.75 → 2.05. DOF far blur was
at 260 m and was blurring the player standing 7 m from the camera; moved to
290 m with a 130 m transition. `_find_clear_spawn()` probes eleven offsets so
the player never spawns pressed against a wall with the camera inside their head.

---

## 3. Verified, not assumed

Both frames rendered at 1170×2532 under Vulkan (Forward Mobile, llvmpipe):

- `shots/visual_before.png` — flat blue fill, no sky, washed grey ground,
  buildings as unlit boxes, camera inside the character
- `shots/visual_after.png` — dusk sky gradient, warm directional sun, readable
  shadows, emissive windows blooming, atmospheric depth toward the horizon,
  character in focus at correct framing

---

## 4. The honest remaining gap

**The art is the problem now, not the renderer.**

- Characters are stock low-poly chibi models: heads roughly a third of total
  height, oversized hair, minimal faces. This is a children's-game silhouette,
  and no lighting change alters that read.
- Vehicles are boxes with cylinder wheels. The tanker's 17 meshes are primitive
  parts, not a modelled truck.
- There is no bespoke texture work anywhere; all materials are flat
  `albedo_color` values.

Closing this needs authored character and vehicle art — modelled, rigged,
textured to a deliberate silhouette language. That is asset production, not
engineering, and it is the single largest remaining problem in the project.

**Next visual steps, in priority order:**

1. Replace the chibi cast with proportioned human models, or commit fully to a
   deliberate stylised silhouette and re-author every character to it. Halfway
   between the two will keep looking wrong.
2. Give the city 6–10 hero buildings and one landmark per district, so each
   district has an identity instead of a density setting.
3. Texture work: even a handful of hand-authored materials (asphalt, concrete,
   corrugated metal, glass) would change the read more than another lighting pass.
4. Signage and graphic layers — this is a Lagos-flavoured city and there is
   currently no writing, no shopfronts, no colour culture on the streets.
