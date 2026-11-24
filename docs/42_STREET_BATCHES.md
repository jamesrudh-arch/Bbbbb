# 42 — Streets as authored batches, assembled into a city

Implements the directive: build streets **in batches by type**, then **combine
them into a city**. Everything below was run and measured, not assumed.

## What changed structurally

Before: each district scattered props on a bare plane. There was no street —
only objects at coordinates.

After: a street is an authored unit with its own ground, frontage, furniture and
overhead grid, built in six distinct types, then instanced across districts.

### The street kit (`scripts/world/street_kit.gd`)

| Component | What it builds |
|---|---|
| `chassis()` | asphalt, kerbs, paving with joints, gutters, road patches, cracks, lane paint, market kerb markings |
| `shophouse()` | inset ground floor with oversailing upper storeys (real arcade shadow), shopfront void with door leaf, fitted signboard, awning below the sign, recessed windows with lintel and sill, balconies with laundry, cornice, parapet, water tanks, AC units. Collision on the mass. |
| `shophouse_row()` | per-type paint and accent palettes, varied widths and storey counts, depth capped at `MAX_DEPTH` |
| `power_lines()` | poles, catenary conductors, cross-street spans, drops into buildings |
| `populate_street()` | type-specific street furniture and vehicles |
| `build_street()` | assembles all of the above |

### The six batches

| Type | Character |
|---|---|
| MARKET | densest trade, stalls on both kerbs every 6–9 m, kiosks, two danfo, market kerb paint |
| TRANSIT | danfo corridor, buses nose to tail every 9–13 m, sparse stalls |
| RESIDENTIAL | quiet, clutter and parked okada only, fewer storeys |
| INDUSTRIAL | utility clutter, one wall sign, one okada, darker paint set |
| CORPORATE | nearly no street trade, one sign and one danfo, tallest buildings, cool palette |
| NIGHTLIFE | stalls and okada through the night, saturated magenta/cyan accents |

Verified visually: each type reads differently from the others at the player
camera. See `shots/` renders.

## The batching problem, and why it mattered

A first pass at an authored street produced **2,080 mesh instances**. At a
38 m footprint on a 76 m pitch that is roughly 50,000 draw calls for a city —
unshippable, and not fixable "later".

Two fixes, in order of impact:

1. **Material cache** (`_mat`, `_emissive`, `_glass` keyed on exact parameters,
   colours quantised by `_q()`). Every helper call had been constructing a new
   `StandardMaterial3D`, so nothing could ever merge. This alone took a street
   from **2,111 distinct material objects to 106**.
2. **`bake_static()`** merges all static geometry per material with `SurfaceTool`.

Result: **2,080 meshes → 106 meshes per street**, a 95% reduction.

`get_street()` then bakes once per type/variant and **duplicates from a
library**, so districts instance streets rather than rebuilding them.

## Measured results

| Metric | Value |
|---|---|
| Build + bake, one street | ~50 ms |
| Build + bake, all six types | 371 ms |
| Full city load (`world.tscn`) | 3.8 s |
| Node count, full city | 31,016 |
| Headless frame rate | 110 fps |
| Tests | 112 / 112 |

## Bugs found and fixed during verification

Every one of these was found by running the thing, not by reading it.

1. **Street geometry had zero collision.** `bodies=0 shapes=0`. The player could
   walk through every building and fall through the road. This is the single
   worst defect found in this phase — the city did not exist as a physical place.
2. **Props were all placed on one kerb, in the roadway.** Street trading belongs
   on the pavement; both kerbs now see trade.
3. **Shophouse rows started at `-half`**, putting the frontage half a street out
   of register with the chassis and props.
4. **The parapet projected up to 4 m out over the street** — the floating slabs
   visible in the early renders.
5. **`_cable()` normalised a zero-length delta**, producing NaN transforms.
6. **`actor.gd` allocated a `MeshInstance3D`, never added it to the tree, then
   called `queue_free()` on it.** Dead code, removed.
7. **Z-fighting on sills, lintels and cornices** — pushed proud of the wall plane
   with real thickness.
8. **`_mat()` on a material object** (`shade_mat.darkened()`) — colours are
   computed before being wrapped.

## Honest assessment against the 10/10 target

This is a large advance and it is still **not 10/10**.

What is now genuinely good: the street reads as Lagos. Continuous shophouse
frontage, arcade shadows, signage hierarchy, awnings, cables overhead, danfo
with painted slogans, trade on the pavement. Composition and silhouette are the
work of an authored street, not scattered props.

What is still short:

- **No people in the street shots.** Pedestrians exist as a system but are not
  composed into these renders, and street life is most of what makes Lagos read.
- **No material texture.** Every surface is flat colour. Top-tier work uses
  albedo variation at minimum; there is none.
- **Roofscape is thin.** Flat roofs with a few tanks; real blocks have far more
  rooftop clutter.
- **Shopfront interiors are a single dim plane.**
- **No wet-road response, no litter, no drainage detail** beyond the gutter strip.
- **Lighting is one fixed sun.** No time-of-day art direction, no night life even
  in NIGHTLIFE.
- **Performance on an actual phone is still unmeasured.** The 110 fps figure is
  headless on a server CPU with no GPU work; it is not a mobile result.

Estimated visual standard: **roughly 6/10** for a stylised mobile city, up from
the 3/10 recorded in `41_ADVANCED_AUDIT.md`. The systems below the art remain as
that document describes.
