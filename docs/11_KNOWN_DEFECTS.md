# LEVERAGE — Known Defects

Open defects first, then resolved ones kept for the record (so nobody reintroduces them).

Date: 2026-11-23

---

## OPEN

### D-101 — Four of six story missions lack bespoke set-pieces
**Severity:** High (feature completeness, not crash)
**Detail:** `m01_tutorial` and `m02_debt` are fully playable. `m03_block`, `m04_offer`,
`m05_chain`, `m06_settlement` exist as mission data with objectives, rewards and state
tracking, and can be started and completed by objective checks, but their scripted
scenarios (custom NPC placement, choreographed sequences, bespoke dialogue scenes) are
not built.
**Workaround:** none.
**Status:** OPEN — documented honestly in the traceability register.

### D-102 — Audio unverifiable in sandbox
**Severity:** Medium
**Detail:** the sandbox has no ALSA device; Godot falls back to the dummy audio driver, so
no sound is actually produced or measured. All 32 WAVs import correctly and every call
site is wired, but audibility, mix balance and latency are unproven.
**Workaround:** none here.
**Status:** OPEN · DEVICE-ONLY.

### D-103 — iPhone performance unmeasured
**Severity:** Medium
**Detail:** all rendering verification used llvmpipe (software Vulkan) at 1280×720. This
proves the scene graph, shaders and materials are valid, not that an iPhone sustains an
acceptable frame rate. Draw-call and triangle budgets are design targets, not measurements
from device.
**Status:** OPEN · DEVICE-ONLY.

### D-104 — Safe-area insets untested
**Severity:** Medium
**Detail:** the HUD queries `DisplayServer.get_display_safe_area()`, but with no iPhone the
returned rect is the full screen. Notch/corner avoidance is implemented but unproven.
**Status:** OPEN · DEVICE-ONLY.

### D-105 — Traffic AI is per-district, not city-wide
**Severity:** Low
**Detail:** vehicles follow each district's waypoint graph. A car that reaches a district
boundary turns or despawns rather than continuing into the neighbouring district. Player
driving is unaffected (it is continuous).
**Status:** OPEN.

### D-106 — Motorcycle has no GLB
**Severity:** Low
**Detail:** the bike is procedurally built from primitives. It reads as a motorcycle at
gameplay distance but has no rider pose blend (the rider model sits in a default idle).
**Status:** OPEN.

### D-107 — Save/load not exercised end-to-end in-world
**Severity:** Low
**Detail:** the round-trip is unit-tested (serialise → deserialise → compare) and the slot
metadata is read by the menu, but a full "save at position X, quit, relaunch, continue"
cycle has not been run as an integration test.
**Status:** OPEN.

---

## RESOLVED (keep — do not reintroduce)

### D-001 — Player sub-systems never received `setup()`
**Symptom:** combat scanned nothing (`targets=0`), `driver.enter()` always returned
`false`, interaction prompts never appeared.
**Root cause:** `@onready` timing; `setup()` was called before the parent chain was valid,
or not at all for an instanced player.
**Fix:** `call_deferred("_wire_systems")` in `player.gd`. See TDR-011.

### D-002 — World rendered as a giant black blob
**Symptom:** everything 3D was black; HUD rendered correctly over it.
**Root cause:** `ambient_light_source = 3` (SKY) with `background_mode = 1` (COLOR) and no
sky resource → pure black ambient.
**Fix:** `ambient_light_source = 2` (COLOR). See TDR-005.

### D-003 — Characters moonwalked
**Symptom:** the player ran away from the camera while visibly facing it.
**Root cause:** UAC rigs face +Z; Godot forward is −Z.
**Fix:** `model.rotation.y = PI`. See TDR-009.

### D-004 — Every character had a black featureless head
**Symptom:** faces rendered as a black blob; outfits invisible.
**Root cause:** UAC source materials are authored near-black (skin linear ≈0.013).
**Fix:** `_tint_materials()` palette re-tint. See TDR-010.

### D-005 — Traffic vehicles had no collision shape and no wheels
**Symptom:** vehicles hovered then fell through the world (`y = −3.5`, then `−13 m/s`);
`_setup_body()` produced only a `Visual` node.
**Root cause chain (three separate faults):**
1. A stray block of dead code after `return mi` in `_prim()` swallowed the entire
   collision + wheel section of `_setup_body()`.
2. After removing it, `shape.shape = box` was missing — a `CollisionShape3D` with a null
   shape is silently non-colliding, so the car still fell through.
3. `configure()` ran before the node entered the tree, so the default vehicle type was
   built.
**Fix:** rewrote `_setup_body()` cleanly, added `_ensure_built()`/`_built` guard so
building happens in `_ready()` or after `configure()` when already in the tree, and
assigned `shape.shape`. Verified: 8 children (Visual, shape, 4 wheels, light, audio), car
settles at `y = −0.09` with **4/4 wheels in contact**.

### D-006 — Punches did zero damage
**Symptom:** 7 punches on a hostile at 1.3 m left HP at 80/80.
**Root cause:** `_attack()` called `player.forward_offset()`, which does not exist on the
player, throwing before the damage block. Two further faults were hidden behind it: the
`_apply_hit` armour read used a null-coalescing pattern that misbehaved on a float, and
`set_prompt()` was being called with a `String` where a `Node3D` was expected.
**Fix:** removed the bad call, rewrote the armour read, corrected `set_prompt(null)`.
Verified: HP 80 → 70.28 → 59.84 → 48.68 over three punches at 1.45 m with combo scaling.

### D-007 — Player died instantly in melee
**Symptom:** `player_hp = 0.0` after a short three-hostile fight.
**Root cause:** three attackers at ~9 damage per 1.0–1.6 s against 100 HP, with no
invulnerability window and no mitigation.
**Fix:** attack cooldown 1.7–2.6 s, base damage 6.5 ± variance, armour mitigation clamped
0–0.85. Verified: `player_hp = 50.8` after the same encounter.

### D-008 — Player car hit 427 km/h
**Symptom:** driving test reported 427 km/h with 0/4 wheel contacts.
**Root cause:** engine force applied while airborne, accumulating without friction.
**Fix:** ground-contact gate + tapered thrust + hard velocity clamp. See TDR-008.
Verified: 76 km/h with 4/4 contacts.

### D-009 — Main menu rendered as a white screen
**Symptom:** the menu background was solid white with unreadable gold-on-white text.
**Root cause:** `haze` was created as a `ColorRect` (whose default `color` is **white**)
and added full-rect without ever assigning `.color`, painting an opaque white sheet over
the whole scene. A second fault: the skyline `Control` was added *after* the menu, so even
once visible it would have drawn over the buttons.
**Fix:** `haze` is now a plain `Control`; skyline moved to child index 1 (above the base
`ColorRect`, below haze and menu); skyline fills the viewport on `NOTIFICATION_RESIZED`.
Verified in `shots/open_04_menu.png`.

### D-010 — Interior showed the player floating in sky
**Symptom:** entering Mama Ngozi's put the player in front of an open doorway against
empty sky.
**Root cause:** the player was placed at `+4.5 z` (outside the doorway) with the camera
facing out, and the room had no interior light (sun/sky contribute nothing at y = −400).
**Fix:** position derived from the room's own `size`, camera yaw set so the view looks into
the room, and an `OmniLight3D` at 2.7 m. Verified in `shots/10_interior.png` (lit room,
counter, vendor visible).

### D-011 — 16 phone contacts overflowed the panel
**Symptom:** the contact list ran off the bottom of the phone panel.
**Fix:** contacts live in a fixed-height `ScrollContainer` (320 px) above the RADIO and
PUT AWAY buttons.

### D-012 — Traffic engine force gave 141 m/s
**Root cause:** flat ×4.2/mass multiplier.
**Fix:** mass-scaled proportional controller clamped to 1.5 × mass, with a top-speed brake.

### D-013 — Test scenes took 120 s and sometimes hung
**Root cause A:** every diagnostic spawned a full six-district world with 25 NPCs to test
one object. **Root cause B:** a runtime error inside `_ready()` aborted the coroutine
before `get_tree().quit()`, so the process never exited and hit the command timeout.
**Fix:** isolate physics tests on a bare floor; wrap `_ready()` bodies so a failure still
quits; never `await RenderingServer.frame_post_draw` before shaders have compiled under
llvmpipe (it can stall indefinitely).
