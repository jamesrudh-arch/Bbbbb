# LEVERAGE — World Design Document

Cinder City · six connected districts · 150×150 m per district

---

## 1. Structure

Cinder City is a 2×3 grid of districts, each a 150×150 m cell on a **40 m block pitch**.
Districts share road corridors at their edges, so a player can drive or walk from Ash Row
to Neon Mile with no loading screen and no invisible wall.

```
                ┌──────────────┬──────────────┬──────────────┐
   north  z-    │  IRON YARD   │ VESPER       │  NEON MILE   │
                │  tier 2      │ HEIGHTS      │  tier 3      │
                │  Meridian    │ tier 3       │  Neon Mile   │
                ├──────────────┼──────────────┼──────────────┤
                │  CINDER LINE │ GUTTERMARKET │  ASH ROW     │
                │  tier 2      │ tier 1       │  tier 1      │
                │  Neon Mile   │ Neon Mile    │  Obi Family  │
                └──────────────┴──────────────┴──────────────┘
   south  z+                     player starts here ↑ (Ash Row)
```

District origin for Ash Row is `(-160, 0, -80)`; each cell offsets by ±150 m on the grid.

## 2. District briefs

### Ash Row — tier 1 — Obi Family
*"Where the blocks raised you. Concrete, cookouts, and cousins."*

The player's home. Low-rise concrete walk-ups with balconies, a barber's chair on the
pavement, a football goal chalked on a wall. **Mama Ngozi's Kitchen** is enterable and is
the tutorial's destination. Spawn point: `(-40, 0.35, 34)` facing down the long street.

Landmarks: Mama Ngozi's (enterable), the stairwell where the debt was called in, the
pawn shop where you can sell anything.

### Guttermarket — tier 1 — Neon Mile Crew
*"Fifty stalls deep. Everything has a price, nothing has a receipt."*

Dense market rows, awnings in ochre and ochre-red, hanging bulbs, crowd density higher
than anywhere else. Enterable: the fence's back room (weapons), the electronics stall
(phones, SIMs, trackers).

### Iron Yard — tier 2 — Meridian Group
*"Cranes at 3 a.m. Container stacks nobody counted twice."*

Port and container yard. Cranes silhouette against the fog, floodlights are cold, huge
open spaces between stacks give vehicle chases room. Enterable: the dock office (paper
leverage — manifests), the union hall.

### Cinder Line — tier 2 — Neon Mile Crew
*"The rail that fed the city, now feeding the foundries."*

Rail sidings, a foundry with fire glow, soot-dark walls. The line runs east-west and is
the fastest route across the map if you can get past the Crew checkpoints.

### Vesper Heights — tier 3 — Meridian Group
*"Glass and security lights. They sleep well up here."*

The only district with glass towers, clean paving, security lighting and low pedestrian
density. The temperature shift from the rest of the map is the point: money is cold here.
Enterable: the Meridian lobby (where you can be *seen* asking), the rooftop bar.

### Neon Mile — tier 3 — Neon Mile Crew
*"Two in the morning and nobody's counting the receipts."*

The nightlife strip. Neon signs at 6/13/20 m on the building faces, wet-looking asphalt,
club queues, the Crew's clubhouse. This is where Chidi is held.

## 3. Typical district anatomy

Each 150×150 cell is built by `city_builder.gd`:

```
Ground          150×150 slab, collision at y=0, top face y=0.04
Roads           cross streets at ±40 m from centre, 12 m wide, asphalt
Lane paint      centre dashes every 18 m, emissive warm white at 0.25
Neon (tier≥3)   emissive strips at y=6/13/20 on the far building face
Sidewalks       lit kerbs, 2 m wide, along every road edge
Buildings       8–14 per district; ground floors of key ones are enterable
Props           street lamps, traffic lights (red/amber/green), bins, stalls, parked cars
Traffic         16 vehicles on the district's road graph
Pedestrians     ~4 named + ~7 unnamed per district, with schedules
```

## 4. Travel

- **On foot:** continuous; the player collision capsule crosses district boundaries freely.
- **By vehicle:** road corridors connect all six cells. Traffic AI uses a per-district
  waypoint graph seeded from road centrelines, so cars follow lanes rather than
  cutting across blocks.
- **Fast travel:** the map screen lists all six districts with their faction and tier.
  Fast travel is available once the district has been visited at least once, costs money
  scaled by tier, and is refused while wanted ≥ 2 (the police are watching the roads).

## 5. Interiors

Enterable via a B prompt at a door. Interiors are built as single rooms at `y = -400`
(below the city) so entering and leaving is a teleport with no scene change and no
streaming cost.

| Interior | District | Vendor | Purpose |
|----------|----------|--------|---------|
| Mama Ngozi's Kitchen | Ash Row | food | Heal, tutorial target, story |
| The Fitting Room | Guttermarket | wardrobe | Buy outfits (damage resist variants) |
| Back Room | Guttermarket | weapons | Buy melee, armour, ammo |
| Dock Office | Iron Yard | — | Story: manifests |
| Meridian Lobby | Vesper Heights | — | Story: the corporation's offer |
| The Underline | Neon Mile | — | Story: where Chidi is held |

Every interior has: floor, four walls with a doorway, a ceiling, an omni light at 2.7 m,
a counter with a vendor behind it, a shelf row, and an exit trigger. Entering hides the
city HUD district name and shows `INSIDE · <name>`.

## 6. Time of day and weather

- A full day is 24 in-game hours = 24 real minutes (1 h = 1 min).
- The clock drives sun colour and angle, ambient energy, fog density and lamp on/off.
- Weather states: **clear** (default), **overcast**, **rain**, **storm**. Rain raises fog
  and lowers ambient; storms add lightning flashes (a brief ambient spike, no extra
  lights).
- Weather and time are shown in the HUD top-left (e.g. `16:39 · CLEAR · 31°`).

## 7. Living events

`Events` + `world.gd` schedule ambient incidents every 40–90 s:

- A street argument that escalates into a fight you can break up or join.
- A police stop on a pedestrian.
- A car break-in (a Crew member working a parked car).
- A market dispute over a stall.
- A street race invitation in Cinder Line / Neon Mile.

Each has a location, a duration, an outcome in money/reputation/heat, and a chance to
spawn hostiles. The system is deliberately small (five event types) and complete rather
than broad and half-wired.

## 8. Points of interest

- **Shops:** weapons, wardrobe, food, electronics, pawn. Buy/sell with inventory.
- **Trainer:** one per discipline, spread across districts; teaches at a price plus a
  trust requirement.
- **Mission givers:** Emeka's family, the Crew lieutenant, the Meridian fixer.
- **Safehouses:** one; sleeping advances time and restores health, and is refused while
  wanted ≥ 2.

## 9. World rules (enforced)

1. The player is never further than 40 m from a road centreline — every destination is
   reachable by car.
2. No building block is wider than 30 m, so the camera never loses the player behind a
   single mass.
3. Every district has at least two enterable doors and one shop.
4. Traffic never spawns within 25 m of the player's view direction.
5. NPCs never spawn inside geometry — spawn points are validated against the road graph.
