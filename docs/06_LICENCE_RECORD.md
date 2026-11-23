# LEVERAGE — Asset Licence Record

Date: 2026-11-23 · Project: LEVERAGE (D'Youngs Games) · Engine: Godot 4.7.2

---

## 1. Summary

| Asset group | Source | Licence | Commercial use | Attribution required | Redistribution of raw assets |
|-------------|--------|---------|----------------|---------------------|----------------------------|
| Characters (11 GLB) | Quaternius / misty-3d UAC pack | **CC0 1.0** | Yes | No | Yes |
| Animations (1 GLB, 17 clips) | Quaternius / misty-3d UAC pack | **CC0 1.0** | Yes | No | Yes |
| Vehicles (7 GLB + colormap) | Kenney Car Kit | **CC0 1.0** | Yes | No | Yes |
| Architecture reference | Kenney City Kits (Suburban/Commercial/Roads) | **CC0 1.0** | Yes | No | N/A (not shipped as meshes) |
| Audio (32 WAV) | Synthesized in-project by `tools/gen_audio.py` | **Original work, owned outright** | Yes | No | Yes |
| Fonts | Godot default theme fonts | Godot Engine licence (MIT) | Yes | No | N/A |
| Engine | Godot Engine 4.7.2 | **MIT** | Yes | No (see Godot licence text) | N/A |
| Code | Written for this project | **Original work** | Yes | No | N/A |
| Normalisation tooling | glTF Transform / meshoptimizer | MIT / Apache-2.0 | Yes | No | N/A |

**Net position:** every third-party asset in the shipped game is CC0 or MIT. There is no
attribution obligation anywhere in the build, although credits are given in-game as a
courtesy. The audio is original, so there are no sample licences to track.

## 2. Quaternius / misty-3d Universal Animated Character pack

- **Licence:** CC0 1.0 Universal (public domain dedication).
- **Source:** `https://github.com/misty-org/misty-3d` → `src/assets/characters/*.glb`
  (a redistributor of the Quaternius UAC pack).
- **What was taken:** 11 humanoid character GLBs and the shared `animations.glb` clip
  library.
- **Modifications:** dequantized with glTF Transform (meshopt/KHR_mesh_quantization
  removed); materials re-tinted at runtime; scaled 0.92; yaw-corrected 180°.
- **Obligations:** none. Recorded here for provenance.

## 3. Kenney Car Kit

- **Licence:** CC0 1.0 Universal.
- **Source:** `https://kenney.nl/assets/car-kit`.
- **What was taken:** 7 vehicle GLBs and the shared colormap texture.
- **Modifications:** dequantized; scaled 1.25×; lifted to floor-origin; emissive
  headlight/tail-light quads added procedurally.
- **Obligations:** none.

## 4. Kenney City Kits (Suburban / Commercial / Roads)

- **Licence:** CC0 1.0.
- **What was taken:** used as visual reference for building proportions, storefront
  cadence and street furniture density. The packs are downloaded into
  `/home/user/assets_raw/kenney_x/` (outside the shipped project) but **no meshes from
  these packs are shipped**; the city is generated procedurally in `city_builder.gd`.
- **Obligations:** none.

## 5. Audio

- **Authorship:** all 32 WAV files were generated from scratch by this project's own
  synthesiser script (`tools/gen_audio.py`), using additive/subtractive synthesis,
  noise shaping and simple physical-modelling approximations.
- **Third-party samples used:** **none.**
- **Licence:** original work, owned by the project author. No attribution required, no
  royalties, no restrictions on commercial distribution.

## 6. Godot Engine

- **Licence:** MIT. Full text is distributed with the engine binary and must accompany any
  binary redistribution of the game.
- **Version:** 4.7.2.stable.official (`ed1daf0bf`).

## 7. Fonts

- **Source:** bundled with Godot's default theme (Open Sans derivative under the Godot
  Engine MIT licence). No additional font files are included in this project.

## 8. Code

- All GDScript in `scripts/`, all test code in `tests/`, and all tooling in `tools/` was
  written for this project. No code was copied, cloned or imported from any other
  LEVERAGE implementation or from any third-party game project.

## 9. Compliance statement

The shipped project contains **zero** assets under a licence that requires attribution,
share-alike, non-commercial restriction, or per-title royalty. It can be distributed
commercially on the App Store without any additional licensing step, subject only to
including the Godot Engine MIT licence text with the binary.

## 10. What is *not* covered

- Apple's App Store terms, the XOGOT runtime terms, and Apple developer programme terms
  are outside this record and must be reviewed separately before submission.
- Character likenesses are fictional; no real person's likeness is used.
