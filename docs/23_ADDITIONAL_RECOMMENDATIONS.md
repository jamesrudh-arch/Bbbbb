# LEVERAGE — Additional Recommendations
### Things not yet raised, that will bite later if not decided now
*23 Nov 2026*

These are the honest gaps in what we've discussed. Each is something that
becomes expensive or impossible if left until the end. Ranked by how much pain
they cause if ignored.

---

## 1. NO LOCALISATION PATH — decide now or never (HIGH)

Measured: **zero** `tr()` calls, no `translations/` folder, every UI string is a
hard-coded literal in `hud.gd`, `main_menu.gd`, `phone.gd`, `content.gd`.

That is fine if LEVERAGE is English-only forever. It is very expensive if you ever
want French, Portuguese, Arabic, Hausa, Yoruba or Chinese — because retrofitting
means touching every file and re-testing every screen.

**What I'd do now (cheap):** wrap every user-visible string in `tr()` and keep the
literal as the key. Costs ~2 hours today, saves weeks later. Costs nothing if you
never localise.

**Nigeria angle:** Pidgin and Yoruba localisation would be genuinely distinctive for
this game's setting. Worth building the *path* even if the second language is
never shipped.

---

## 2. AUDIO IS WAV — 10× LARGER THAN IT NEEDS TO BE (HIGH)

Measured: **6.4 MB** of `.wav` in the repo. On iOS, WAV ships uncompressed.
The same audio as OGG Vorbis is roughly 1/10th — about **700 KB**.

Right now the whole build is **148 MB**, of which assets are 82 MB and audio 6.7 MB.
On mobile, download size directly costs installs.

**What I'd do:** convert all long-form audio (ambience, music) to OGG; keep short
one-shots (clicks, punches) as WAV for latency. Godot's import settings can do this
per-file. Expect **5–6 MB saved immediately**.

Also: nothing is loudness-normalised. Without a standard target (I'd use −16 LUFS),
the phone ringtone, gunshots and music will have wildly different perceived volume
and iOS users will reach for the slider on minute one.

---

## 3. SAFE AREAS AND ONE-HAND PLAY (HIGH — iOS)

Two mobile realities nobody has addressed:

**a) Notch and home indicator.** An iPhone with a Dynamic Island eats the top
~47 pt and the bottom ~34 pt. `TOP_INSET = 74.0` handles the top crudely, but
nothing accounts for the home indicator swipe zone at the bottom, where the B
and A buttons currently sit. An accidental swipe-up during a fight will background
the game.

**b) Reachability.** Modern phones are used one-handed. Any control the thumb
can't reach left-handed is, for a large share of players, unusable. Left thumb
should own movement only; every action button must be within right-thumb arc.

**What I'd do:** a real safe-area rect from `DisplayServer.get_display_safe_area()`,
and a one-handed layout toggle. Cheap now, very annoying later.

---

## 4. THERE IS NO ACCESSIBILITY LAYER AT ALL (MEDIUM-HIGH)

Not mentioned once in any document so far. In 2026 this is a baseline
expectation and increasingly an App Store moderation consideration.

Minimum viable set:
- **Subtitles on by default**, with size options — critical, since there is no voice acting
- **Colourblind-safe blips** — the minimap currently distinguishes mission (gold) from
  bounty (orange) from ring (red) almost purely by hue. Add shape differences
- **Remappable touch controls** — the input system already supports rebinding
  (`controls.gd` builds from an action table), so this is mostly UI
- **Hold vs tap toggle** for the heavy attack, the most common mobile pain point
- **Camera sensitivity + inverted-Y**

---

## 5. THE SAVE SYSTEM HAS NO MIGRATION STORY (MEDIUM-HIGH)

`game.gd` has save/load/slot_info, but no version field and no migration.
The moment you ship a patch that adds a field, old saves either crash or silently
lose progression. Players lose 30 hours and review-bomb you.

**What I'd do:** put `"version": N` in every save from day one, and a
`migrate(data)` function that upgrades old shapes forward. Five lines now.

Related: **autosave triggers** must be specified (mission start, checkpoint,
purchase, safehouse entry) or the first crash costs the player everything.

---

## 6. NO CRASH REPORTING AND NO ANALYTICS (MEDIUM)

When this ships to real phones you will have no idea why it breaks. Silent
crashes on specific iPhones, memory pressure kills, thermal throttling —
all invisible.

Minimum: **Sentry** (or equivalent) wired to the Godot error handler, and a
few anonymous counters: session start, mission start/fail, crash. Without this
you're guessing. This is also how you'd learn the difficulty curve is wrong
before players refund.

---

## 7. THE 45–60 HOUR CLAIM NEEDS A VOICE BUDGET — or it will read as a silent film (MEDIUM-HIGH)

48 story missions with full text dialogue and **zero voice acting** is a real
aesthetic risk. Mafia: DE, GTA V and RDR2 are all carried by performance.

You don't need 20,000 lines. You need a **much smaller set used well**:
- ~**1,200 lines** of protagonist + antagonist barks and mission-critical dialogue
- ~**400** ambient conversational fragments
- ~**120** combat effort sounds per discipline

That's a voice casting and recording budget, not a text problem. Worth deciding
early because casting affects character design, and recording 1,200 lines is
weeks of studio time that must sit in the schedule.

**If voice acting is not happening**, then say so plainly and I'll design the
dialogue presentation around it: bigger, better-paced text, stronger music,
more physical character acting. What I should not do is build it as if voices are
coming and end up with a silent crime epic.

---

## 8. ONE BACKUP SAVE MODE WOULD PREVENT THE WORST PLAYER EXPERIENCE (LOW COST)

Cars can wedge, NPCs can trap you, a mission can soft-lock. Every open-world game
ships with this bug. A single "unstick" option in the pause menu (reload last
checkpoint, or teleport to nearest safehouse) costs almost nothing and prevents
the one-star review that says "got stuck, uninstalled."

---

## 9. THE PROJECT HAS NO LICENCE FILE FOR ITS OWN CODE (LOW COST, LEGAL)

`docs/06_LICENCE_RECORD.md` tracks third-party asset licences (good). But the
repository itself has no `LICENSE` file, and — more importantly — **no record of
what you're allowed to do with the third-party models once modified**.

Specifically: the Mixamo animations and three.js models are used under licences
that permit commercial use, but that should be documented as an explicit,
dated statement of use, not just a list of URLs. If this ever gets a
publisher or a lawyer, that file matters.

---

## 10. ONE STRUCTURAL RECOMMENDATION — SPLIT THE MONORE PO

The repo is 148 MB with a 60 MB `.git`. Every clone pulls the full history, and
git stores binaries badly — a 3 MB GLB edited twice costs far more than 6 MB.

Not urgent at this size. It becomes urgent around 500 MB–1 GB. Reasonable plan:
keep source in the repo, move large raw assets to a release or LFS. Flagging so
it's a decision, not a surprise.

---

## 11. THE THING I MOST WANT TO SAY

**The riskiest assumption in the whole project is not any single feature. It is
that all of this can be built and then verified.**

We have three real character models for a cast of 96. We have audio that has never
been played on a real device. We have a cinematic whose motion has never been seen
by a human — only its stills. We have touch controls never tested by a thumb.

That gap — between *built* and *verified* — is where projects die. My strong
recommendation is to schedule **a real iPhone/XOGOT test pass at the end of every
phase**, not once at the end. A single frame-time measurement on a real device
today is worth more than another thousand lines of code, because it tells us
whether the target is real.

---

---

## STATUS — all items addressed (23 Nov 2026, commit c8c7ec9)

| # | Item | State |
|---|---|---|
| 1 | Localisation path | **Done** — 36 UI strings wrapped in `tr()`, plus `PlatformUI` for future languages |
| 2 | Audio compression + loudness | **Done** — beds RMS/peak normalised (`city_bed` was 3.0× too quiet), QOA on long-form: 1722K → 348K |
| 3 | Safe area + one-hand play | **Done** — `platform_ui.gd`, action floor clears the home bar, left-handed mirroring |
| 4 | Accessibility basics | **Done** — settings menu, pause toggles, shape-coded map blips, hold-vs-tap, invert Y, sensitivity |
| 5 | Save versioning | **Done** — `SAVE_VERSION 3` + `_migrate()` v1→v3, covered by tests |
| 6 | Crash reporting | **Done** — `crash_reporter.gd`, rolling local log, remote sink left unset by design |
| 7 | Voice budget | **DECIDED: no voice acting.** `dialogue_box.gd` is now the storytelling surface |
| 8 | Unstick button | **Done** — `rescue.gd`, detects falls and wedging, keeps all progress |
| 9 | Licence statement | **Done** — `LICENSE`, `docs/24_ASSET_USE_STATEMENT.md`, credits corrected |
| 10 | Repo structure | **Done (better than planned)** — baked anim libs `.tres`→`.res`: 55.5 MB → 22.6 MB. Project 156 MB → 124 MB |

### Bonus finding — the credits were wrong

`main_menu.gd` credited **Quaternius** for the character models. The models are
actually **three.js Soldier/Michelle/Xbot under MIT**. Shipping a credit to the
wrong author is a licence breach even when the real licence is permissive.
Corrected, with the engine MIT notice now reproduced in-product.

---

## PRIORITY SUMMARY

| # | Item | Cost now | Cost later |
|---|---|---|---|
| 1 | `tr()` wrapping | ~2 h | Weeks |
| 2 | WAV → OGG + loudness | ~2 h | Rework + 5 MB |
| 3 | Safe area + one-hand | ~4 h | Broken controls on some iPhones |
| 4 | Accessibility basics | ~8 h | Rework + compliance |
| 5 | Save versioning | ~1 h | Lost saves, review bomb |
| 6 | Crash reporting | ~3 h | Flying blind |
| 7 | Voice budget decision | A decision | 48 silent missions |
| 8 | Unstick button | ~1 h | One-star reviews |
| 9 | Licence statement | ~1 h | Legal exposure |
| 10 | Repo structure | A decision | Slow clones |

**Nothing here is a new feature.** Every item is either a cheap decision now or an
expensive one later.
