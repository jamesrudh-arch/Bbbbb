# Statement of Third-Party Asset Use
**LEVERAGE** — D'Youngs Games — 23 November 2026

This is an explicit, dated statement of how third-party assets are used in this
project. It exists because a list of URLs is not a licence record: if a publisher,
platform reviewer or lawyer ever asks, this document answers the question
"what exactly are you using, and under what terms?"

Each entry records the source, the licence, the modification made, and the
commercial-use position.

---

## 1. Character models — three.js examples

| Asset | Source | Licence | Tris | Modification |
|---|---|---|---|---|
| `Soldier.glb` | mrdoob/three.js `examples/models/gltf/` | MIT | 11,376 | Retargeted to the project skeleton; materials replaced with project shaders |
| `Michelle.glb` | mrdoob/three.js `examples/models/gltf/` | MIT | 28,106 | Same; used as a base for civilian and contact characters |
| `Xbot.glb` | mrdoob/three.js `examples/models/gltf/` | MIT | 49,112 | Same; used as a base for hostile archetypes |

**Commercial use:** permitted. MIT requires the copyright notice and permission
notice be included in all copies or substantial portions of the software.
The MIT notice for three.js is retained in `docs/06_LICENCE_RECORD.md`.

**Note on the state of these assets:** all three are placeholder-grade for a
shipping title. They are correct in proportion and rigging, and they animate, but
they are not final character art. Replacing them with commissioned work does not
create a licensing problem — the MIT terms impose no restriction on the project
that supersedes them.

---

## 2. Animations — Mixamo

| Source | Count | Format |
|---|---|---|
| Mixamo (Adobe) | 65 clips | Retargeted GLB, baked to `assets/characters/real/animlib/` |

**Commercial use:** permitted under the Mixamo terms of use for projects that are
not redistributing the animation as a standalone asset. The clips are embedded in
the game binary, which is the permitted case.

**Modification:** retargeted from `mixamorig:` naming to the project skeleton and
baked. Baked derivatives are covered by the same terms.

---

## 3. Vehicles

| Asset | Source | Licence |
|---|---|---|
| 7 vehicle models | Kenney Car Kit | CC0 (public domain) |

**Commercial use:** permitted without restriction. CC0 imposes no conditions.

**Status:** placeholder. These are low-poly kit models and do not meet the
project's realism bar for final art. See `docs/23_ADDITIONAL_RECOMMENDATIONS.md`
item 7.

---

## 4. Textures — Poly Haven

| Source | Licence | Usage |
|---|---|---|
| `dl.polyhaven.org` 1K JPG sets | CC0 | Ground, wall and trim surfaces in `city_builder.gd` |

**Commercial use:** permitted without restriction. CC0.

---

## 5. Audio

| Source | Licence |
|---|---|
| Procedurally generated in-project | Owned outright |

All WAV files in `audio/` were generated for this project. No third-party samples
are embedded. There is therefore no sample-clearing burden.

---

## 6. Engine

| Component | Licence |
|---|---|
| Godot Engine 4.7.2 | MIT |

**Commercial use:** permitted. The Godot MIT notice must be reproduced in the
game's credits or an accompanying licence file. **This is a shipping requirement
and is not yet implemented** — a credits screen does not currently exist.

---

## 7. Outstanding obligations before ship

- [ ] Godot Engine MIT notice reproduced in credits (required)
- [ ] three.js MIT notice reproduced in credits (required)
- [ ] Mixamo attribution if the Adobe terms require it in-product (verify at ship)
- [ ] Replace placeholder character and vehicle art, or accept placeholder status
      in the store description
- [ ] No third-party music is used; if a composer is engaged later, their
      agreement must be added here

---

## 8. What this document is not

It is not a warranty of title. It is a good-faith record of the assets in the
repository as of the date above, compiled from the sources actually present in
the project's own files. It should be reviewed by counsel before commercial
release, and updated whenever an asset is added or replaced.
