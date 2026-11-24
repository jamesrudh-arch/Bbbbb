# 43 — Street batches: crowd, load-order stall, and what is still missing

Continues `42_STREET_BATCHES.md`. Everything here was run and measured.

## Performance, measured end to end

| Stage | Frame rate | Notes |
|---|---|---|
| Before any street work | 137 fps | empty plane with scattered props |
| Authored streets, first pass | **1 fps** | 2,300 StaticBody3D + ~1,000 chassis decorations |
| One body per row instead of per building | 58 fps | 2 bodies + 18 shapes per street |
| Chassis decorations cut | **133 fps** | joint spacing 1.8 → 2.6 m, patches −45%, cracks −54% |
| Plus street crowd | 127 fps | 6 figures per street, streamed |

City load: **3.0–3.4 s**, 29,204–30,492 nodes, tests **112/112**.

## The load-order stall — found the hard way

Building all four streets of all six districts *with their crowds* during world
load produced a scene that **never completed its first frame**. Not slow:
stuck. Measured directly:

- 29,204 nodes without street crowds → first frames in **3.4 s**, fine.
- 30,492 nodes with street crowds → first frame **never returns**.

36 skinned figures in isolation run at ~1 ms/frame, so the cost is not the
figures themselves but their presence during world construction. They are now
created by `world_streamer` the first time a district becomes visible, which
restores load time and keeps crowds in the streets.

**Process failure worth recording.** Finding this took most of a session
because several profiling switches I wrote were not actually taking effect in
the scene I was measuring — I compared 6-district runs against "streets off"
runs where the switch was never read, and drew wrong conclusions about the
renderer, then physics, then cables, then label counts. The lesson: **before
trusting a profiling switch, verify it changes the number it is supposed to
change.** One `print` of the node count would have settled it in a minute.

## Street crowd

- `populate_people()` places 4–6 figures per street: traders facing the road,
  others walking, density tuned per street type.
- Each figure gets randomised skin, shirt and trouser colours — the crowd is not
  a row of clones.
- Grounding is **measured through the skeleton**, not the mesh AABB. A skinned
  AABB reports the bind pose, so the obvious approach leaves people hovering.
  Figures are 1.84 m with feet on the kerb and cast a contact shadow.
- **Known limitation: they stand in the bind pose.** No idle animation is
  applied to street people yet; the full actors use the shared animation
  library, but these static figures do not. They read as people at gameplay
  distance but obviously stiff up close.

## Bugs fixed this session

1. **Skinned meshes were being destroyed by the static bake.** `bake_static`
   merged and freed them, so every person vanished. Skinned meshes are now
   excluded from the bake.
2. **People were 2.0 m tall and floating 1 m up** — the kit ignored both the
   model's authoring height and its centre origin.
3. **People rendered dark** — the kit never applied per-figure material tinting;
   figures now get the same skin/shirt/pants treatment as the game's characters.
4. **Facing** — UAC rigs are authored +Z; the kit now turns them.
5. `_cable()` normalised a zero-length delta.
6. `actor.gd` allocated a `MeshInstance3D`, never added it, then freed it.
7. Street geometry had **zero collision** (found earlier, still the worst defect
   of the phase: the player could walk through every building).

## What is still short of 10/10

Being blunt, because that is the standard that was set:

- **Street people do not animate.** Static bind pose. This is the most visible
  remaining gap.
- **No material texture anywhere.** All flat colour. Top-tier stylised work has
  albedo variation at minimum.
- **No time-of-day art direction.** One fixed sun; NIGHTLIFE does not actually
  look like night.
- **Roofscape still thin**; shopfront interiors are a single dim plane.
- **No wet road, litter, or drainage beyond a gutter strip.**
- **Mobile performance is still unmeasured on a phone.** The 127 fps figure is
  headless on server CPU with no GPU work.

Honest estimate: **6/10** for a stylised mobile city street. Up from 3/10 at
the start of this phase, and short of the target.

## Next, in priority order

1. Make street people animate (shared animation library + idle clip), or reduce
   their count and accept static figures only at distance.
2. Time-of-day art direction — night lighting for NIGHTLIFE alone would change
   how half the city reads.
3. Albedo variation / texture atlasing on facades and road.
4. Measure on a real phone (frame time, memory, thermal).
