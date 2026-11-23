# LEVERAGE — Characters & Story

> **Tagline:** Everyone has leverage on you.
> **Logline:** Your brother owes the wrong people ₦4.2 million. You have six days and a
> phone full of people who owe you favours — and every one of them wants something first.

---

## 1. Protagonist

### Emeka Obi — "the fixer who fixes with his hands"
- **Age:** 29. **From:** Ash Row, Cinder City.
- **Wants:** Chidi back, alive.
- **Needs:** To learn that being owed is not the same as being loved.
- **Voice:** Dry, short sentences. Deflects with jokes when frightened. Never threatens;
  just describes what will happen.
- **Combat identity:** Starts as a **Brawler**. Learns Kickboxing from **Tunde Bello**,
  Grappling from **Kola Jaiyeola**, Drunken from **Sunday Adeleke**, Weapon from the Back
  Room fence.
- **Model:** `casual-male` (dequantized GLB), navy shirt, dark denim, 0.92 scale.

### Chidi Obi — the brother
- **Age:** 23. **From:** Ash Row.
- **Wants:** To be taken seriously.
- **Needs:** To stop borrowing to prove he's somebody.
- **The debt:** ₦4.2m to the Neon Mile Crew, borrowed against a delivery that never
  arrived because Chidi was robbed — or because he sold it himself. The story lets the
  player discover which.
- **Status:** Held by the Crew from mission 02 onwards. Seen in person in the finale.
- **Model:** `casual2-male`, ochre shirt.

## 2. Antagonists and factions

### Neon Mile Crew — the creditor
Street organisation running the Mile, Guttermarket and the Line. Structure: a
lieutenant for every hustle, a captain for every lieutenant, and a top nobody has met.

- **Adaeze Okonkwo "Ada"** — Crew captain. Calm, immaculate, genuinely likes Chidi, which
  is worse. Wants ₦4.2m *or* Emeka's name on a contract.
- **Victor Okafor** — Crew lieutenant, the one who took Chidi. Enjoys fear. Short fuse.
- **Amaka Obi** — Emeka's aunt, runs a stall in Guttermarket, is *on the Crew's books*.
  The first leverage the player finds is against their own family.
- **Sergeant Nyame** — police sergeant on the Crew's payroll. Wanted-system antagonist:
  he escalates response when the player pushes the Crew.

### Meridian Group — the alternative
Logistics corporation with a legal front and an illegal supply chain. Will clear the debt
for one job. The job is the point: they are acquiring the player.

- **Eze Nwosu** — Meridian fixer. Polite, precise, never raises his voice. Uses first
  names, remembers birthdays.
- **Detective Ibrahim** — the one honest cop. Wants the Crew, will use the player to get
  them, and will not protect the player afterwards.

### Obi Family — the people you defend
Not an organisation; a block. Its strength is that it will show up for you and its
weakness is that it cannot pay.

- **Mama Ngozi** — runs the kitchen. Fed Emeka and Chidi as children. Story anchor,
  tutorial destination, healer.
- **Sunday Adeleke** — Drunken master, ex-boxer, drinks to keep the hands still. Teaches
  the cheapest discipline and the fastest.
- **Kola Jaiyeola** — Grappling trainer, runs a gym above the barbershop. Charges in
  favours, not cash.
- **Tunde Bello** — Kickboxing trainer, fights in the Line on Thursdays. Proud, broke,
  and the best teacher in the city.

### Player-adjacent
- **Ada Okonkwo** (Crew) — also a potential ally if trust is high enough.
- **Amaka Obi** — aunt, stall-holder, Crew debtor.
- **Sergeant Nyame** — corrupt, dangerous, blackmail-able.
- **Detective Ibrahim** — honest, useful, will not save you.

## 3. Full named cast (16)

| # | Name | Faction | Role | Model |
---|------|---------|------|-------|
1 | Emeka Obi | Family | **Protagonist** | casual-male |
2 | Chidi Obi | Family | Brother, held | casual2-male |
3 | Mama Ngozi | Family | Kitchen, healer | casual-female |
4 | Amaka Obi | Family (Crew debtor) | Aunt, Guttermarket | casual3-female |
5 | Sunday Adeleke | Family | Drunken trainer | casual-bald |
6 | Kola Jaiyeola | Family | Grappling trainer | worker-male |
7 | Tunde Bello | Family | Kickboxing trainer | casual2-male |
8 | Adaeze Okonkwo "Ada" | Crew | Captain, antagonist/ally | suit-female |
9 | Victor Okafor | Crew | Lieutenant, took Chidi | casual-male |
10 | Sergeant Nyame | Police (Crew-paid) | Corrupt sergeant | worker-male |
11 | Detective Ibrahim | Police | Honest detective | suit-male |
12 | Eze Nwosu | Corporation | Meridian fixer | suit-male |
13 | Bisi Adeyemi | Corporation | Meridian lawyer | suit-female |
14 | Femi Ojo | Crew | Market fence (weapons) | casual3-male |
15 | Hauwa Sani | Family | Wardrobe vendor | casual-female |
16 | Obinna Eze | Crew | Line enforcer | casual-male |

Each has: id, display name, faction, role, model, bio (used by the phone contact list),
and an optional `leverage` string used by dialogue when the player holds dirt on them.

## 4. Crowd (~25 pedestrians)

Beyond the 16 named characters, `npc_population.gd` spawns ~25 pedestrians from the same
11-model pool with random skin/shirt variants. They have:

- **Schedules:** walk → idle → enter → work → exit → walk, keyed to the world clock.
- **Memory:** `memory[player_id]` counters for "saw you fight", "you bumped me",
  "you helped me". Memory changes their greeting and whether they flee when you raise
  heat nearby.
- **Reactions:** flee from gunfire, rubberneck at fights (within 18 m), call the police
  if they witness a crime with a 4 s delay, which is what actually triggers heat.

## 5. Story beats (as implemented / as designed)

| # | Mission id | Title | Status |
|---|-----------|-------|--------|
| 1 | `m01_tutorial` | Homecoming — walk to Mama Ngozi's | **Implemented & playable** |
| 2 | `m02_debt` | The Note — learn the debt, first fight | **Implemented & playable** |
| 3 | `m03_block` | Working the Block — paid jobs | Objectives implemented; dialogue stubbed |
| 4 | `m04_offer` | Meridian's Offer — the corporation's favour | Data + trigger implemented; cinematic stubbed |
| 5 | `m05_chain` | The Chain — collect leverage across districts | Data implemented; missions not individually scripted |
| 6 | `m06_settlement` | Settlement — rescue Chidi | Data implemented; finale not scripted |

Honest statement: **two of six story missions are fully playable end-to-end**. The other
four exist as mission data with objectives and rewards, and can be started and tracked,
but their bespoke scripted set-pieces are not built. See
`docs/12_DEVELOPMENT_STATE.md`.

## 6. Themes

- **Debt as a relationship.** Every faction holds a different note on the player. Clearing
  one creates another. The economy and the story are the same system.
- **Family as leverage.** The player's aunt is on the creditor's books. The first thing
  you can use is the first thing that can be used against you.
- **Clean money.** Meridian's offer is the morally cheap route and the story does not
  pretend otherwise: it is easier, and it costs more.
- **Violence as a bad tool that works.** Combat is fast, satisfying and always raises
  heat. The game never rewards restraint mechanically, and the story notices.

## 7. Dialogue rules

- Maximum 2 lines per dialogue node, 90 characters per line.
- Emeka never says "I'll kill you". He says what will happen.
- Antagonists are polite. Politeness is the threat.
- No exposition about the city that a resident would not say out loud.
