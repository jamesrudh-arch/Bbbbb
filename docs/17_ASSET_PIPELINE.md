# Asset & Animation Pipeline

## Realistic character source
`assets/characters/real/` holds three rigged humans on the **Mixamo `mixamorig_*`
skeleton**: `Michelle.glb` (28k tris, PBR diffuse/normal/glossiness, female),
`Soldier.glb` (11k tris, PBR, male, armoured), `Xbot.glb` (49k tris, untextured
male mannequin — placeholder only).

Licensing: `Soldier`/`Michelle`/`Xbot` ship with three.js (MIT). The animation
library comes from Mixamo, **free for commercial use** under Adobe's terms.

## Animation library
`assets/characters/animlib/` — 60 Mixamo clip GLBs. Each contains one animation
named `mixamo_com` and its own `RootNode` rig. `scripts/character/anim_library.gd`
maps file base name -> semantic clip name (see its `CLIPS` dict).

## The retargeting problem (solved, with a known limitation)
Mixamo clips store **absolute** bone orientations. Character GLBs bake their own
rest orientation — `Soldier`'s hips rest is a 180 deg flip, the clip rigs' is
identity. Copying clip values straight onto a character therefore tips the body
over. Three approaches were tried:

1. **Local delta** `char_rest_local * (ref_rest_local^-1 * clip_local)` — correct
   for `idle`, `walk`, `punch`, `kick_*`, `hit`, `block*`, `die`.
2. **Direct local copy** — wrong for every character whose rest differs.
3. **Global conjugation** `A(b) = char_rest_global(b) * ref_rest_global(b)^-1` —
   correct for the same set as (1); folding appeared on clips with heavy root motion.

**Implementation:** `scripts/dev_bake_anims.gd` samples each clip at 30 fps and
writes a fully-baked `AnimationLibrary` per character to
`assets/characters/baked/<Char>.tres`. Runtime cost is zero (no retargeting on the
device), which matters for iPhone. Re-bake with:

```
godot --headless --path . res://scenes/dev_bake_anims.tscn -- --char=Michelle
```

**Known limitation:** the reference rest is now re-read per clip (fixing clips
authored against a different rest), and the hips keep the character rest so the
body cannot tip. `Run` and `Jog_Forward` still fold at the waist because those
specific clips carry large hip rotation that no rest-space delta reproduces
faithfully. Those two are therefore **not used**: running is `walk` played at
1.55x with a forward lean applied at runtime, which is the standard speed-scaled
locomotion trick and reads correctly at gameplay distance.

## Verification
`scenes/dev_clipsheet.tscn` renders eight clips in a 4x2 grid of own-world
SubViewports and writes a contact sheet — this is how the clip set was judged, and
it should be re-run after any change to the baker.
