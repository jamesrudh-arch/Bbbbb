# LEVERAGE — Control Map

**Status of this document:** authoritative. The code in `scripts/autoload/controls.gd`
and the input map in `project.godot` must match this table exactly; `tests/test_suite.gd`
asserts that they do.

---

## 1. Mandatory combat assignment (from the brief — not negotiable)

| Button | Action | Notes |
|--------|--------|-------|
| **X** | Punch | Light, fast, cheap. Starts combos. |
| **Y** | Heavy attack | Slow, expensive, breaks guard. |
| **A** | Kick | Longer reach than punch; discipline-dependent. |
| **B** | **Dodge** (in combat) | Rolls in the current movement direction. Invulnerable 0.32 s. |
| **B** | **Contextual interaction** (outside combat) | Enter vehicle, open door, talk, pick up. |

### Why B is not a conflict

`combat.gd::_read_input()` returns immediately when `in_combat == false`:

```gdscript
func _read_input() -> void:
    if not in_combat:
        _blocking = false
        return
    ...
    elif Input.is_action_just_pressed("dodge"): _dodge()
```

`interaction.gd` only scans for nearby interactables and only consumes B when
`in_combat == false`. At every instant exactly one of the two handlers acts on B. There
is no frame where both fire, and there is no modifier button. This is asserted by
`tests/test_suite.gd` (control-conflict group).

## 2. Full mapping

### On foot — combat

| Action | Touch | Keyboard | Godot action |
|--------|-------|----------|--------------|
| Punch | X | X | `punch` |
| Heavy | Y | Y | `heavy` |
| Kick | A | A | `kick` |
| Dodge | B | B | `dodge` |
| Block | hold shield | L | `block` |
| Shoot | fire button | Mouse 1 | `shoot` |
| Reload | R | R | `reload` |
| Switch weapon | T | T | `weapon_switch` |

### On foot — movement

| Action | Touch | Keyboard | Godot action |
|--------|-------|----------|--------------|
| Move | virtual stick (bottom left) | WASD / arrows | `move_forward`, `move_back`, `move_left`, `move_right` |
| Sprint | stick fully out | Shift | `sprint` |
| Camera | drag anywhere / right thumb area | Mouse | `look_left/right/up/down` |
| Jump | — | Space | `jump` |

### World interaction

| Action | Touch | Keyboard | Godot action |
|--------|-------|----------|--------------|
| Interact (enter car, door, talk) | B | B | `interact` |
| Phone | top-right icon | P | `phone` |
| Map | top-right icon | M | `map` |
| Pause | top-right icon | Esc | `pause` |
| Radio next station | phone → RADIO | N | `radio_next` |

### Driving / riding

| Action | Touch | Keyboard | Godot action |
|--------|-------|----------|--------------|
| Throttle | right pedal | W / up | `throttle` |
| Brake / reverse | left pedal | S / down | `brake` |
| Steer left | left region of pedal cluster | A / left | `steer_left` |
| Steer right | right region | D / right | `steer_right` |
| Handbrake | HB | Space | `handbrake` |
| Horn | HORN | H | `horn` |
| Exit vehicle | EXIT | B | `exit_vehicle` |
| Camera look | drag | Mouse | `look_*` |

While driving, the combat button diamond is replaced by the pedal cluster and the
speedometer (km/h) appears above the B button position.

## 3. Touch layout (iPhone safe area)

```
┌──────────────────────────────────────────┐
│ DISTRICT/CLOCK     MISSION        MONEY  │
│ HP/STAMINA         OBJECTIVE      DISC.  │
│ (top-left)         PROGRESS       HEAT   │
│                                          │
│                    ┌──┐                  │
│                    │PH│ ← phone/map/pause│
│ vpad               └──┘                  │
│ (bottom-left)         ┌──┐               │
│                       │X │              │
│                    ┌──┼──┼──┐           │
│                    │A │  │Y │           │
│                    └──┼──┼──┘           │
│                       │B │              │
│                       └──┘  (bottom-right)
└──────────────────────────────────────────┘
```

- Minimum touch target: **64×64 pt**, actual buttons 72–96 pt.
- The stick is 150 pt with a 60 pt knob and a deadzone ring drawn on the base.
- All buttons are `MOUSE_FILTER_STOP` inside a `CanvasLayer` at layer 10 so no gameplay
  click leaks through.
- There is no control in the iPhone notch/rounded-corner region; the HUD root respects
  `DisplayServer.get_display_safe_area()`.

## 4. Keyboard preview (development)

Keyboard/mouse input exists for development and desktop verification. It is a superset of
the touch map and never introduces an action that touch cannot perform. The only
desktop-only convenience is `Space = jump`, which is also exposed as a touch button when
the player is on a surface marked `climbable`.

## 5. Input map location

`project.godot` → `[input]` section. Each action has a `deadzone` and at least one event.
`controls.gd` documents the same table at runtime and exposes
`Controls.describe(action)` for the in-game controls screen and for tests.
