# Phase 8 — Split-Screen Duels
*23 Nov 2026*

## Scope, as locked

1v1 only. **Zero server cost** — the user's explicit constraint. Local split-screen,
no relay, no monthly bill, no player communication (which would also trigger App
Store UGC moderation requirements).

## What shipped

**`scripts/systems/duel.gd`** — best of three, 60-second rounds.

- Both fighters are **full `Player` instances** with real combat, rig and camera.
  Nothing about the duel uses a simplified model: a duel is the real fight, seen
  twice. Disciplines behave exactly as they do in the story.
- **Style Rank breaks a draw.** This is the rule the freeze named, and it is the
  only reason style has a mechanical stake in the duel. On a timeout or double KO,
  the fighter with the higher style score takes the round; if style is within 1.0,
  it falls back to remaining health, then alternates rather than allowing a null
  round.
- **Ring-out concedes the round.** Without bounds, a player ahead on the clock
  could simply run.
- Duel state is written to `Game.stats` and never overwrites the player's story
  progression or their chosen discipline.

**`scripts/systems/split_view.gd`** — two SubViewports, top and bottom.

Top/bottom rather than left/right: on a phone in landscape a horizontal split
gives each player a tall letterbox, while a horizontal divider keeps a usable
wide view for both. The divider carries the round timer and score, so the seam
becomes useful rather than wasted.

**`scripts/ui/duel_select.gd`** — both players choose on one screen. Anything
requiring passing the phone back and forth for more than a moment kills the mode.

## The sixth discipline

The design freeze specifies **six** disciplines. Content had five. **Silat** —
angular footwork, joint locks off the counter, best counter-window in the game,
weak if you attack first — is now implemented rather than merely promised.

## Bugs found

| Bug | Consequence |
|---|---|
| **`Player` had no `health` field at all** | Health lived only on the `Game` singleton. Two fighters shared one pool, so **neither could be knocked out** and a duel could never end. Now per-instance, mirrored from `Game` during story play and independent in a duel. |
| `_end_round` re-entered every frame | A KO'd fighter stays KO'd, so round-end was called continuously and its countdown reset each frame. The duel froze in `round_end` forever. |
| `get_animation("")` in the rig binding check | Runtime error on every rig build. |
| Two tests hardcoded "5 disciplines" | They were correct before Silat; they now assert the spec's six. |

## Verified

- Full lifecycle: countdown → fight → KO → round 2 → KO → 2–0 → teardown.
  Split view disengages, fighter two is freed, `duels_fought` increments.
- Split geometry: containers anchored **0.00–0.50** and **0.50–1.00**, both
  cameras correctly parented to their own viewports, score and timer labels live.
- Two fighters spawn opposed, 8.4 m apart, holding different disciplines.

## NOT verified — and this matters

**The composite split-screen frame was never rendered.** Under llvmpipe, adding a
second full `Player` instance to the scene makes rendering stall beyond a 7-minute
timeout. Two live SubViewports each running a full city view plus two skinned
characters is simply more than software rasterisation can produce.

I am not going to claim the split screen *looks* right. What is verified is that
it is **structurally correct**: the viewports, cameras, anchors and overlay are
all built as designed. Whether it runs at an acceptable frame rate on an iPhone is
an open question requiring a real device — and this is now the strongest argument
yet for the device test pass recommended in `docs/23`.

Performance is the risk here, not correctness.
