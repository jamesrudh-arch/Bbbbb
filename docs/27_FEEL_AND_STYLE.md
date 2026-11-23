# Phase 4 — Feel & Style Rank
*23 Nov 2026*

## The problem with the old feel

Three things were wrong, and all three are the kind of thing that makes a game
feel cheap without anyone being able to say why:

1. **Hit-stop was global and racy.** `combat.gd` set `Engine.time_scale = 0.55`,
   waited, then set it back to `1.0`. Two overlapping hits meant the second
   reset landed while the first freeze still ran. A hit during a scripted
   slow-motion cancelled the slow-motion. And a hit-stop running when the pause
   menu opened left the game ticking at 0.06x behind the menu.
2. **Shake was linear.** `shake_clamp(damage * 0.05, 0.15, 0.8)` then a linear
   fade. A linear fade on a camera reads as a wobble, not a jolt.
3. **The attack animations were the wrong ones.** Every attack played `punch` or
   `slash`. Per the animation audit (`docs/25`), `punch` has **23 degrees** of
   arm travel — it is a windup. The player's attacks were the weakest clips in
   the library.

## What shipped

**`scripts/systems/impact.gd`** — owns time.
- Hit-stop at three lengths: light 45 ms, heavy 75 ms, finisher 110 ms.
- Counts overlapping requests and never lets a shorter freeze cut a longer one.
- Remembers the time scale it found and restores exactly that, so slow-motion
  and hit-stop coexist.
- `suspend()`/`resume()` so pausing cannot be undone by a hit resolving.
- Shake uses `amount²`, so it decays faster than linear — a jolt, not a wobble.

**`scripts/systems/style_rank.gd`** — D → C → B → A → S → SS.
- Scores hits, dodges, counters and finishers.
- **Variety is the core mechanic.** Repeating the same attack pays
  `1.0 - repeat × 0.30`, floored at 8%. Each *new* attack in a fight pays 1.55x.
- Counters pay 2.2x.
- Bleeds 5/s at C up to 36/s at SS, after a 2.6 s grace.
- **Getting hit above rank A resets the grade to D.**
- Rank fades out of combat so a stale SS never carries into the next fight.

**`scripts/ui/style_meter.gd`** — one letter, one bar, left side under health.
Deliberately not a number: the player must never have to read it mid-fight.

## Verified

- `tests`: 168 checks. Two of them exist specifically to stop the system becoming
  decoration:
  - **"mashing does NOT reach SS"** — 40 identical attacks cannot climb past the
    variety ceiling.
  - **"variety out-scores mashing"** — the same 40 hits spread across the kit
    rank higher.
- `shots/style_ranks.png` — all six ranks render distinctly and legibly.
- `shots/hud_style.png` — live in-world. Found and fixed a real layout bug here:
  the meter was drawn on top of the minimap because `TOP_INSET + 96` landed
  inside the 156 px map.

## Attack clips corrected

The player now uses the audited strong clips:

| Input | Before | Now | Arms |
|---|---|---|---|
| Light | `punch` | `punch_cross` | strong |
| Heavy | `punch` | `punch_hook` | strong |
| Kick | `punch` | `kick_mma` | strong |
| Combo ≥ 4 | `punch` | `punch_quad` | strong |

Weapon discipline keeps `kick_round` for kicks and heavy.

## Still open

- No impact *frame* (the one-frame white flash). It needs a post-process pass and
  the mobile renderer's cost has not been measured on a device.
- Rumble is not wired — Godot mobile haptics are device-only and unverifiable here.
- Style rank is not yet used to break duel ties (Phase 8).
