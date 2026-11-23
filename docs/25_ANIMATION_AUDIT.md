# Animation Audit — verified clip quality
*23 Nov 2026*

Measured, not assumed. Every clip in `assets/characters/baked/*.res` was checked
for actual bone travel, because a clip with a promising name can be a near
T-pose. This table is the authority for which clip to call for which action.

## Method

For each clip, the maximum angular travel of any arm bone and any leg bone was
measured across all rotation tracks (`q0.angle_to(qk)` in degrees). A combat
clip whose arms move less than 45° is not a combat clip.

## Results — 53 clips, 45 strong, 8 weak

### Strong (use these)

| Clip | Arms | Notes |
|---|---|---|
| `punch_combo` | **85.2°** | The real striking combo. Use for heavy/primary attacks. |
| `punch_hook` | strong | Wide hook; good for the heavy button. |
| `punch_cross` | strong | Straight cross; good for the light button. |
| `punch_quad` | strong | Four-hit sequence. Finisher. |
| `kick_round` | strong | Roundhouse. Finisher / heavy kick. |
| `kick_mma` | strong | Compact MMA kick. Light kick. |
| `roll` | **143.3°** | Full body roll — dodge. |
| `dodge_roll` | strong | Directional dodge. |
| `aim` / `aim_gun` | **67.9°** | Proper aiming pose. |
| `reload` | **93.4°** | Full reload. |
| `hit_body` | 48.5° | Body impact reaction. |
| `hit_head`, `hit_big` | strong | Head snap / heavy stagger. |
| `die`, `die_back`, `die_front` | strong | Three death directions. |
| `walk` | 53° legs | Walking. Loop. |

### Weak — do not use as action clips

| Clip | Arms | Why |
|---|---|---|
| `punch` | 23.1° | A **windup**, not a strike. Opening frames are near-neutral. |
| `block_start` | 5.3° | Barely a raise. Use `block_idle`. |
| `block_hit` | 25.8° | Weak absorb. Prefer `hit_body`. |
| `kick_fly` | 29.0° | Weak; use `kick_round`. |
| `kick_knee` | 31.0° | Weak; use `kick_mma`. |
| `crouch_aim` | 3.8° | **Static.** Effectively a still pose. |
| `crouch_idle` | 4.1° | **Static.** |
| `cover` | 4.8° | **Static.** |

### Available but not yet used

`sprint`, `run`, `jog`, `crouch_run`, `jump_forward`, `turn`, `talk`, `phone_talk`,
`wave`, `beckon`, `angry`, `drink`, `idle_injured`, `run_injured`, `hit_head_mid`,
`block_idle`, `dodge_left`, `dodge_forward`.

## Consequences for Phase 3 (enemy AI)

If the AI calls `punch` for a light attack, enemies will telegraph and then
barely move — it will read as broken combat, and it is easy to misdiagnose as an
AI bug. **Route light attacks to `punch_cross`, heavy to `punch_hook`, finishers
to `punch_quad` / `kick_round`.** Reserve `punch` for the windup beat before a
heavy strike, which is what it actually is.

## Format change

Baked libraries moved from `.tres` to `.res` (binary). Same 53 clips, same data,
**59% smaller** — 55.5 MB down to 22.6 MB. `character_rig.gd` loads `.res` first
and falls back to `.tres`.
