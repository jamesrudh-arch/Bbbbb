# LEVERAGE — state of the game

**Date:** 2026-11-23 · **Engine:** Godot 4.4.1 (the version Xogot ships) · **Target:** iPhone via Xogot

---

## Where things stand

Six commits sit on `work/`, ready to push. Everything below was **run**, not assumed.

| Harness | Result | What it proves |
|---|---|---|
| `tests/test_suite.tscn` | **112 / 112** | Every system behaves |
| `tests/completeness.tscn` | **10 / 10** | A player can actually *reach* the content |
| `tests/playthrough.tscn` | **14 / 14** | Launch → menu → world → mission complete → reward → save → job |
| `tests/touchproof.tscn` | **pass** | The iPhone stick moves the player, X punches |
| `tests/worldproof.tscn` | 21,014 nodes, 6 districts, 4.0 s | The world builds |
| `tests/soak.tscn` | 3,600 frames, **144.8 fps**, 0 errors | A minute of real play |

Script errors across every run: **0**.

---

## What was broken, and what it cost

Every one of these was found by running the game, not by reading it.

### The world would not load at all

A district cost **350 MB**. Six districts needed more than the build container's
memory, so the world scene was killed before it could produce a frame.

The cause was subtle: each *street variant* is a separately baked mesh source of
about 196,000 vertices, and a source cannot be freed while a duplicate of it is
alive. The layout asked for **four variants per district** — 786k vertices of
near-identical street, because a variant only changes the RNG seed that places
shop units on a fixed chassis.

Crossings now reuse source 0 (duplicates share the source's mesh data, so they
cost transforms only), and the second variant is spent on the street that faces
the player rather than the one closing the block behind him.

**350 MB → 242 MB per district.** The world now builds in 4 seconds.

### Content that existed but no player could reach

| Defect | Effect |
|---|---|
| `activate()` had no pickup dispatch | 12 ledger fragments were uncollectable |
| `activate()` had no shop dispatch | every vendor was mute; the shop UI was unreachable |
| vendors tagged `kind="vendor"` | every handler checks `kind="shop"` |
| 3 side jobs, no entry point | the jobs board didn't exist; the work was invisible |
| `latest_save_slot()` compared slot *numbers* | a week-old slot 2 beat a minute-old autosave; CONTINUE loaded the wrong game |
| `_any_save()` ignored the autosave | a player whose only progress was autosaved saw no CONTINUE |
| content notice shown every launch | repeat players were stopped by a wall of text |

### A silent hard freeze

`_spawn_fragments()` chose its district by `placed % size` and then `continue`d
when that district had no nav nodes — **without advancing `placed`**. One district
with an empty nav graph spun the loop forever: no error, no frame, no clue. It
now advances.

### A crash per figure per frame

`street_crowd._animate()` indexed `get_animation_list()[0]` on an empty library.
That happens when a rig loads before its clips are cached, and it fired once per
crowd figure per frame — the error spam alone cost frames, and no figure animated.
It falls back to a static figure now.

### Leaks

- Baked street sources left the tree and were never freed → freed with the kit.
- `bake_static()` detached originals then `queue_free()`d them, leaving the node
  parentless until end of frame → `free()`.
- The audio director declared a 10-slot 3D player pool and never used it;
  `play_at()` allocated a node per footstep and leaked playback at teardown.
- Music and ambience loop forever and were still playing at exit.

**2,492 exit warnings → 1.**

> The "4,144 leaked nodes" figure is a measurement artifact. It is exactly the
> retained street-baking cache (766 nodes × 6 districts), which is *correct* to
> hold during play. Freeing the world the way a real session ends drops orphans
> **4,144 → 13**. The old soak test called `quit()` with the world still standing
> and blamed the game for its own measurement.

---

## Xogot / iPhone conformance

Verified against `docs.xogot.com`, not assumed:

- **Feature tag 4.4** — a project tagged 4.7 will not open in Xogot.
- **Mobile renderer**, `import_etc2_astc` and `import_s3tc_bptc` both on.
- **`scale_mode="fractional"`** — Xogot's default "Auto" zoom/stretches older projects.
- **Stretch `canvas_items` + `expand`** — keeps the 16:9 frame, reveals more world on tall screens.
- **Safe area** — the HUD reads `get_display_safe_area()` so the stick clears the home indicator.
- **Touch → action contract** — the on-screen stick issues the same action names as the gamepad map, so Xogot's Virtual Controller and the touch HUD converge on one path. Proven: drag → `move_forward` at 1.0 → player moved 4.67 m.

---

## Honest scope note

The **15 side jobs** and **~13 missions** in earlier notes came from the *other*
lineage in this repository (`origin/main`, 128 scripts, 209 tests). **This branch
has 3 side jobs.** The jobs board offers all 3 — that is the real number, and it
is what the tests check.

---

## Pushed

`main` and `xogot-iphone-street-work` both stand at **`143fea8`**.

Verified by cloning `main` fresh and running the suite from that clone:
**112/112**, import clean, and `rebuild_all.py` is a pure no-op on the pushed
tree (21 applied, 0 failed, no code changes — run twice to prove it).

The previous `main` is not destroyed. It is preserved twice over:

- branch `legacy-main-2026-11` → `836bbe4` (128 scripts, 209 tests)
- tag `archive/main-before-xogot` → `836bbe4`

Delete those when you are satisfied this lineage is the game, and the old one is
gone for good.

**`rebuild_all.py` is the important file.** It reproduces the entire fixed state
from a clean `9417821` checkout and asserts every edit landed. The workspace
reverted tracked files twice during this work; anything not in that script can
be lost again. It is idempotent — running it on an already-fixed tree changes
nothing.
