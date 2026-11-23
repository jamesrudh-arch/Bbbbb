# Phase 5 — NPC Conversation
*23 Nov 2026*

## What was there before

One flat line per named NPC, printed through a generic dialogue box. No branches,
no reactions, no ambient speech. The city was populated but mute, and the
"NPCs must converse" requirement from the brief was met only in the loosest
possible sense: an NPC could say a sentence at you.

## What shipped

**`scripts/systems/conversation.gd`** — three layers.

### 1. Barks
Overheard street lines per district, pedestrian-to-pedestrian exchanges, and
witness reactions that escalate with city heat (`calm` → `shock` → `panic`).
These fire on their own and never block input. They are what makes a street feel
inhabited when you stand still.

### 2. Talks
Fifteen authored trees covering the named cast. Each is a four-way branch:

| Tag | Works on | Backfires on |
|---|---|---|
| **ASK** | anyone — always safe, always the slowest route | nobody |
| **CHARM** | people who already trust you | nobody, but pays little at low trust |
| **THREATEN** | people who fear you | anyone whose faction trust is below 25 |
| **LIE** | specific people, briefly | anyone who knows the facts |

**The tags are not cosmetic.** `THREATEN` against Mama Ngozi costs 12 trust;
against her with low faction standing it costs **20** and the conversation closes
as `burned`. `CHARM` on Chidi with high family trust yields the strongest lead in
the game; the same line on a stranger yields a shrug.

Every tree ends with a `default` closing line, so a conversation always lands
somewhere rather than stopping mid-air.

### 3. Outcomes
`lead`, `lead_strong`, `deal`, `crack`, `intrigued`, `defiant`, `burned`,
`closed`. Leads surface as in-game notifications and feed the mission system.
`burned` moves faction trust down. This is the mechanism that makes the four
dialogue approaches mechanically real rather than flavour text.

## Bugs found by running it

| Bug | Consequence |
|---|---|
| **The rescue system fired "STUCK?" mid-conversation** | Being teleported to an NPC and standing still for 6 s is indistinguishable from being wedged. It now takes a dialogue lock into account. A safety net that fires during normal play is worse than no safety net. |
| Cinematic mode only hid the buttons | The minimap, health, cash and mission card stayed on screen behind the dialogue, with four tap targets stacked over them. Now the whole root dims. |
| `world.camera_rig` does not exist | It lives on the player. Bark positioning silently failed. |

## Verified

- `shots/conv_02_choices.png` — four approaches, colour-coded, over the live city,
  HUD clear.
- `shots/conv_03_result.png` — the CHARM consequence and closing line.
- `tests` 178 checks, including:
  - every tree has all four tags **and** a response for each
  - the four tags produce **at least three distinct outcomes** and **four
    distinct lines** for the same NPC
  - threatening at low trust backfires harder than threatening at high trust
  - charm pays more when trusted
  - an unknown NPC degrades instead of crashing

## Still open

- Trees exist for 15 named characters; the freeze calls for branching dialogue
  for 16. The 16th has no authored tree and falls back to a single line.
- No conversation currently *gates* a mission — outcomes are recorded and
  notified but missions do not yet read `outcome` to branch. That is Phase 6.
- Subtitle size is respected from PlatformUI, but the dialogue box does not yet
  reflow for very large sizes on short screens.
