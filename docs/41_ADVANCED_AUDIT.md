# LEVERAGE — Advanced Audit: How Good Is This Actually?

**Date:** 23 Nov 2026
**Method:** every figure read from the running build, the source, or the asset
directory. Nothing assumed, nothing estimated. Where something does not exist,
it says it does not exist.

**Answer to the direct question: this is not 10/10. It is not close.**

The honest headline is: **the engineering is competent, the production is not.**
Systems are built and tested; content, art, audio and presentation are thin.
A 10/10 game is not a set of working systems — it is a thousand authored
decisions that make those systems feel like a world. Those decisions are mostly
not here yet.

---

## 1. Scorecard

| Axis | Score | What exists | What is missing |
|---|---|---|---|
| **Core systems** | 7 / 10 | Combat, driving, AI, missions, save/load, economy all work | Systems are connected but shallow; few interlock |
| **Game feel** | 4 / 10 | Hitstop, camera shake, hit flashes | No coyote time, no input buffer, no variable jump (all added this pass) |
| **Art / visuals** | 3 / 10 | Dusk atmosphere, sky, fog, emissive windows | Stock chibi characters, box vehicles, no textures, no signage |
| **Audio** | 3 / 10 | 32 SFX + ambience exist and are wired | No music system, no dynamic mix, no variety, no reverb |
| **Animation** | 2 / 10 | 17 clips, one shared library | No blending quality, no IK, no locomotion matching, no facial |
| **Content volume** | 2 / 10 | 8 missions, 7 weapons, 8 vehicles, 6 districts | Freeze wants 48 / 30 / 32 / 100+ |
| **UI / UX** | 4 / 10 | Clean HUD, phone, shop, job board | No settings, no accessibility screen, no onboarding |
| **Narrative** | 3 / 10 | 16 characters, faction trust, radio stub | 8 missions of a 48-mission arc |
| **Accessibility** | 2 / 10 | Shake multiplier (added this pass) | No colourblind, no subtitles in UI, no remapping, no reduce-motion |
| **Performance** | ? / 10 | Mobile renderer, LOD-by-distance, rain particles | **Never profiled on a real device. Unknown is not the same as good.** |
| **Polish** | 2 / 10 | It runs and does not crash | No transitions, no audio fades, no loading states |

**Weighted: roughly 3.5 / 10 as a product.** Systems-led, production-poor.

---

## 2. What I measured, axis by axis

### Game feel — the gap that matters most

The research is unusually specific here, which makes the gap easy to state:

| Technique | Recommended value | This build |
|---|---|---|
| Hitstop | 3–12 frames (0.05–0.2 s), scaled to impact | 0.045 s flat — **too short, and not scaled** |
| Coyote time | 0.08–0.15 s | **absent** |
| Input buffering | 0.1–0.15 s | **absent** |
| Variable jump height | cut rise 30–50% on release | **absent** |
| Screen shake | 0.2–0.5 s, exponential decay | present, but no decay curve |
| Screen flash | ≤0.1 s, ≤3/sec | **absent** |
| Knockback | scaled to damage | **absent** |
| Squash and stretch | 20–40% deformation | **absent** |
| Audio pitch variation | ±5–10% | present (±8%) — one of the few done right |

**And a real bug found while auditing:** hitstop set `Engine.time_scale = 0.55`
and restored it after an `await`. If the player died inside that window, time
stayed at 0.55 **permanently** — the whole game would run at half speed forever.
Fixed with a token-guarded restore plus a hard reset in `respawn()`.

### Audio

32 files exist: 22 SFX, 2 ambience, 8 others. Every one of the 15 sound names
the code requests resolves — **except `ui_confirm`**, which is silently absent.

What is missing is everything that makes audio feel produced:
- **No music at all.** `Content.RADIO` has 2 entries and no station plays.
- No reverb zones, no occlusion, no distance filtering.
- No dynamic mix — combat and exploration sound identically loud.
- No footsteps by surface type (one `step_concrete` for everything).

### Animation

**17 clips total**, shared across 16 characters and 6 pedestrian types. That is
the same clip set for the protagonist, a boss, and a market trader.
Missing entirely: turn-in-place, strafe, crouch, climb, vault, ragdoll death,
hit reactions by direction, idle variations, facial or lip movement.

### Visual art

The atmosphere pass landed (see `shots/visual_after.png`). The **assets have
not changed and are the binding constraint**:
- Characters are stock chibi low-poly: head ≈ 1/3 of body height, oversized
  hair, no facial detail. This reads as a children's game regardless of lighting.
- Vehicles are boxes with cylinder wheels — the "17-mesh tanker" is primitive
  parts, not a modelled truck.
- **Zero texture assets.** Every material is a flat `albedo_color`.

### Content against the design freeze

| Content | Have | Freeze floor | % |
|---|---|---|---|
| Story missions | 8 | 48 | 17% |
| Weapons | 7 | 30 | 23% |
| Vehicles | 8 | 32 | 25% |
| Characters | 16 | 96 | 17% |
| Pedestrian types | 6 | 32 | 19% |
| Disciplines | 5 | 6 | 83% |
| Districts | 6 | 6 | 100% |
| Ring bouts | 0 | 48 | 0% |
| Races | 0 | 28 | 0% |
| Heists | 0 | 8 | 0% |
| Leverage Files | 0 | 100 | 0% |

**Roughly 20% of the specified content exists.**

### Accessibility — worst axis

Research and the Game Accessibility Guidelines are explicit that shake and
flash must be optional. There was **no accessibility system at all** until this
pass added a shake multiplier and a reduced-motion switch. Still missing:
colour-blind modes, subtitle rendering, control remapping, text scaling,
difficulty options, and an audio cue alternative for visual ones.

### Performance — honestly unknown

The project uses the Mobile renderer, which is correct. But **it has never been
run on a phone.** All measurements so far are on llvmpipe software rendering,
which tells us nothing about frame time on hardware. Claiming performance
quality would be inventing evidence.

---

## 3. What I fixed in this pass

1. **Hitstop time_scale leak** — could permanently halve game speed. Now
   token-guarded and restored on respawn.
2. **Hitstop scaling** — now 0.035–0.095 s scaled to damage, inside the
   researched 0.05–0.2 s band, so a jab and a heavy read differently.
3. **Coyote time** — 0.12 s.
4. **Input buffering** — 0.14 s.
5. **Variable jump height** — release cuts the rise.
6. **Accessibility** — shake multiplier + reduced motion, honoured by the
   camera rig.

These are the highest impact-to-effort items in the research, and all are
invisible when working.

---

## 4. What it would actually take to reach 10/10

Being blunt about scope, because that is what was asked for.

**Not achievable by one developer in one session.** A 10/10 open-world crime
game on mobile is a 40–80 person-year production. What *is* achievable is a
10/10 **vertical slice** — one block, one fight, one drive — that demonstrates
the standard, and then scaling content to it.

Priority order by impact:

1. **Replace the art.** Proportioned characters, modelled vehicles, real
   textures. Nothing else moves the needle as much. This is the single largest
   gap and it cannot be coded around.
2. **Music and mix.** Ten minutes of adaptive score and a proper bus mix would
   change perceived quality more than any remaining code work.
3. **Feel completion.** Flash, knockback, squash/stretch, directional hit
   reactions, footstep surfaces, decay curves on shake.
4. **Content to freeze.** 48 missions, 30 weapons, 32 vehicles, 32 peds.
   This is writing and balancing, not engineering.
5. **Accessibility to guidelines.** Colour-blind, subtitles, remapping.
6. **Device profiling.** Until it runs on a phone, performance is unknown.

---

## 5. The honest summary

The build is a **solid prototype with correct architecture and thin production**.
It boots, it runs, its systems are tested, and it does not crash. It has a
usable combat loop and a working city.

It does not yet have: art that reads as deliberate, music, enough content to
hold attention for an hour, accessibility, or any measurement on real hardware.

**3.5/10 today. The ceiling for this approach, honestly, is 6/10** — because a
10/10 needs art and audio production that code alone cannot supply. Saying
otherwise would be the same mistake I made before: presenting unverified work
as finished.
