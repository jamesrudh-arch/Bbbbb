# LEVERAGE — Art Direction Guide

---

## 1. One-line direction

**A West-African-inflected brutalist city at dusk: warm dust and sodium light down in the
blocks, cold glass and security white up in the towers, and gold reserved for money.**

## 2. Why this and not "generic crime game"

The default open-world crime palette is desaturated blue-grey with neon pink. It reads as
immediately generic, and it erases the place. Cinder City is deliberately keyed to a
West African city at the end of the dry season, where the sun is low and orange, dust sits
in the air, painted concrete is the dominant material, and the only genuinely cool light
is the security lighting that comes with money.

Three rules follow, and they are enforced in code:

1. **No muddy grey.** Every surface is warm neutral, cool neutral, or an accent. The
   asphalt is `(0.20, 0.205, 0.225)` — cool but never black. Ground is `0.45` value.
2. **Tier controls temperature.** Tier 1–2 districts are warm and dusty; tier 3 districts
   are cold and glassy. You can tell where you are from a screenshot with the HUD covered.
3. **Gold means money.** `Color(0.92, 0.74, 0.42)` appears only on currency, progression,
   the LEVERAGE wordmark and the active mission. Nothing else is gold.

## 3. District palette

| District | Tier | Wall base | Ground | Accent | Light character |
|----------|------|-----------|--------|--------|-----------------|
| Ash Row | 1 | 0.42 warm ochre concrete | 0.45 dust | 0.72 amber | Sodium, low, hot |
| Guttermarket | 1 | 0.38 umber | 0.42 | 0.80 warm red | Stall bulbs, crowded |
| Iron Yard | 2 | 0.30 industrial | 0.34 | 0.55 steel blue | Cold floodlights |
| Cinder Line | 2 | 0.26 soot | 0.30 | 0.70 ember | Fire glow, rail haze |
| Vesper Heights | 3 | 0.20 glass slate | 0.38 | 0.62 cyan-white | Security white, contrast |
| Neon Mile | 3 | 0.16 night panel | 0.24 | neon magenta/cyan | Neon strips at 6/13/20 m |

Neon strips are physical boxes at **y = 6, 13, 20 m** on the building faces at `z = -66` —
they sit in the air where signage would be, not painted on the floor.

## 4. Lighting

- **Sun:** one `DirectionalLight3D`. Colour ramps from `(1.0, 0.86, 0.68)` at dawn to
  `(1.0, 0.96, 0.90)` at noon to `(0.86, 0.52, 0.34)` at dusk, then a cool
  `(0.42, 0.50, 0.78)` moon at ×1.25 energy. Angle is driven by the world clock.
- **Ambient:** `ambient_light_source = 2` (COLOR), `(0.60, 0.66, 0.80)` at energy 1.35
  by day, lerped to 1.6 at night. **Never SKY** — with a COLOR background and no sky
  resource it produces pure black and the world appears as a black blob.
- **Fog:** `0.0022` density by day, denser and warmer at dusk (`0.004`) for the dust.
- **Street lamps:** unshadowed omni lights, range 12 m, energy 1.6, warm `(1.0, 0.82, 0.55)`.
  Distance-faded so only the nearest ~40 are lit.
- **Shadows:** 4 splits, max distance 80 m, PSSM 4 splits, bias 0.06, normal bias 1.6,
  blur 1.2. Mobile has no SSAO, so a soft directional shadow plus darker ground albedo
  under buildings does the grounding work.

## 5. Characters

- Source: Quaternius / misty-3d Universal Animated Character rigs, 11 variants
  (casual male/female, casual-bald, casual2, casual3, suit, worker).
- **The source materials are authored near-black** (skin base colour linear 0.013), which
  renders as a featureless black blob. `character_rig.gd::_tint_materials()` re-tints
  every surface into the Cinder City palette on construction:
  - Skin: 5 variants from warm mid-brown to deep brown.
  - Shirt: 6 variants (navy, oxblood, forest, ochre, charcoal, plum).
  - Pants: near-black denim tinted 18% toward the shirt so outfits read as outfits.
  - Hair: near-black to warm umber.
  - Face: skin lightened 35% so eyes and features read at distance.
- Scale: 0.92 of source, giving a 1.95–2.0 m silhouette that reads correctly against
  2.0 m doorways and 1.45 m car roofs.
- Every character faces **−Z** after a `PI` yaw correction; the source faces +Z.

## 6. UI / HUD

- **Palette:** background `#0B0C10`, panel `#15171C` at 92% alpha, text `#F0EBE0`,
  dim text `#A8A69E`, gold `#EBBE6B`, health `#C4453A`, stamina `#6FA96B`, heat
  `#E08A3C` → `#C4453A` as it fills, wanted star gold.
- **Type:** Godot default sans. 26 px for primary numbers, 17 px for menu items,
  13 px for secondary, 11 px for labels. Minimum on-screen text is 11 px at 1280 wide,
  which is ≥ 22 px on a 3× iPhone.
- **Layout:** safe-area aware. Top-left district + clock + weather + health/stamina;
  top-centre mission title + objective + progress; top-right money + discipline + heat;
  bottom-left virtual stick; bottom-right X/Y/A/B diamond; action column down the right
  edge; speedometer replaces the action column while driving.
- **Button diamond** is deliberately colour-coded and labelled with the **literal
  letter**, not an icon: **X** oxblood, **Y** ochre, **A** forest, **B** slate blue.
  A player should never have to guess which button is punch.

## 7. Vehicles

- Kenney Car Kit GLBs, scaled **1.25×** (1.8× made cars 2.25 m tall against a 2.0 m
  character — visibly wrong). Kenney cars are centre-origin, so they lift by
  `0.33 * scale` to put tyres on the road.
- The motorcycle has **no GLB**; it is built procedurally in `vehicle.gd` from boxes and
  cylinders — frame, tank, seat, forks, handlebar, two wheels — in oxblood and gunmetal.
- Headlights are emissive quads plus one forward `SpotLight3D`; tail lights are emissive
  quads. No shadow-casting headlights (Mobile budget).

## 8. Effects

- **Combat:** a short white flash quad on hit, screen shake via `camera_rig.shake()`,
  hit-stop of 0.06 s on heavy hits, and a stagger animation.
- **Rain:** particle-based, plus a lower fog density and darker ambient.
- **Neon:** emissive materials at energy 2–3, no bloom-heavy HDR values (Mobile glow is
  cheap but over-blooming destroys the flat graphic look).

## 9. Screenshot composition rules (used for the delivered shots)

1. Camera height 1.75 m, spring length 6.2 m, 0.30 m right shoulder offset.
2. Spawn points sit on **road centrelines**, not sidewalks, so the first frame has a
   street vista down the block rather than a wall.
3. Every delivered shot must show: the player silhouette readable, at least two depth
   planes (foreground road, midground buildings, background fog), and no UI overlap.

## 10. What to avoid

- Purple/pink "cyberpunk" as the default night look — Neon Mile is magenta and cyan but
  only in one district, at tier 3, as signage.
- High-frequency detail on buildings. The graphic language is flat boxes, repeated
  windows, hard shadow edges.
- Photoreal textures. There are none in the project; everything is flat-shaded
  `StandardMaterial3D` with tuned albedo/roughness/metallic.
- Close-range depth of field (it smears the third-person player at Mobile quality).
