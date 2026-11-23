extends Node
## CONVERSATION — the systems behind every spoken line in Cinder City.
##
## With no voice acting, dialogue is the story. This owns three layers:
##
##   BARKS    one-line reactions that fire on their own: ambient chatter,
##            witness reactions, panic, and street calls. These keep the city
##            feeling inhabited without the player ever pressing anything.
##   TALKS    the branching conversation with the 16 named cast. Four approaches
##            — ASK / THREATEN / LIE / CHARM — each opening different outcomes
##            based on faction trust, not just picking a line.
##   WITNESS  NPCs who saw something react to it, and remember.
##
## Design rule from the freeze: the four tags are not cosmetic. THREATEN works on
## people who fear you and backfires on people who outrank you. LIE works until
## someone contradicts it. CHARM depends on faction trust. ASK is always safe and
## always slowest.

signal conversation_started(npc_id)
signal conversation_ended(npc_id, outcome)
signal bark_spoken(speaker, text)

const TAG_COLORS := {
	"ASK": Color(0.94, 0.76, 0.32),
	"THREATEN": Color(0.85, 0.32, 0.28),
	"LIE": Color(0.62, 0.44, 0.82),
	"CHARM": Color(0.90, 0.56, 0.70),
}

## Ambient lines by district mood. Short, overheard, never plot-critical.
const AMBIENT := {
	"ash_row": [
		"Power's been out three nights running.",
		"They say the Obi boy got taken. Not robbed. Taken.",
		"Don't stand under the lamps, they flicker and then they're gone.",
		"Meridian owns the building. Meridian owns the water. Meridian owns us.",
	],
	"railhead": [
		"Freight's late. Freight's always late.",
		"You carrying? Don't answer that.",
		"Railhead doesn't ask where the cargo came from.",
	],
	"neon_mile": [
		"Two hundred a bottle and it tastes like a radiator.",
		"Simone's dancers don't talk to strangers. Try anyway.",
		"The lights never go off here. That's the whole idea.",
	],
	"iron_yard": [
		"Container nine's been sealed for a month. Nobody manifests a month.",
		"Watch the cranes. They don't look down.",
	],
	"vesper_heights": [
		"Lovely evening. Did you know the patrol changes at nine?",
		"No, I don't know who lives in the towers. I just clean them.",
	],
	"guttermarket": [
		"Fresh fish! Fresh yesterday, fresh today, don't ask tomorrow.",
		"Anything you need, anything at all. Cash.",
		"Market closes at dusk. After dusk it doesn't close, it just gets quiet.",
	],
	"dockside": [
		"Water's got bodies in it. Always has.",
		"Don't take the far pier at night. Take it in daylight, and even then don't.",
	],
}

## Reactions to seeing violence. Escalating in intensity with heat.
const WITNESS := {
	"calm": ["None of my business.", "I didn't see anything.", "Okay. Okay."],
	"shock": ["He's down! Someone call someone!", "Jesus — he just —", "Move, move, get back!"],
	"panic": ["RUN! He's got a — just RUN!", "Get inside! GET INSIDE!", "Not me, not me, not me—"],
}

## Named-character conversation trees. Each node:
##   asks:  what Marcus says first
##   choices: 4 tagged approaches
##   responses: per tag -> {speaker, text, trust, outcome, then}
##   default: after the branch resolves
const TREES := {
	"ngozi": {
		"entry": "family",
		"start": "You're thinner than when you left. Sit down. Don't tell me you're fine.",
		"choices": [
			{"tag": "ASK", "label": "What do you know about Chidi?"},
			{"tag": "CHARM", "label": "You always fed me before you yelled at me."},
			{"tag": "THREATEN", "label": "Somebody in this block talks or this block burns."},
			{"tag": "LIE", "label": "I've already got a name. I just need you to confirm it."},
		],
		"responses": {
			"ASK": {"speaker": "NGOZI", "text": "He came by at two in the morning and wouldn't look at me. He said he signed something. Papers he didn't read.", "trust": 4, "outcome": "lead"},
			"CHARM": {"speaker": "NGOZI", "text": "Don't you use that voice on me, boy. ...Sit. He was scared of a car. A grey car that came back three times.", "trust": 8, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "NGOZI", "text": "You'd burn the block that raised you? Get out of my kitchen before I find a spoon.", "trust": -12, "outcome": "burned"},
			"LIE": {"speaker": "NGOZI", "text": "You're lying to me. You've got your father's liar's face. I don't know anything and now I won't say it.", "trust": -6, "outcome": "closed"},
		},
		"default": "Go careful, Marcus. The people who took him aren't angry. That's what scares me.",
	},
	"chidi": {
		"entry": "family",
		"start": "Marcus. I know. I know what I did. I just need one more week.",
		"choices": [
			{"tag": "ASK", "label": "What did you sign?"},
			{"tag": "THREATEN", "label": "You got taken because you're careless. Say that out loud."},
			{"tag": "CHARM", "label": "I'm not angry. I'm here. Talk to me."},
			{"tag": "LIE", "label": "Nobody has to know. Just tell me who and it disappears."},
		],
		"responses": {
			"ASK": {"speaker": "CHIDI", "text": "A transfer. Meridian called it a voluntary transfer of labour. I was drunk and they had a pen.", "trust": 5, "outcome": "lead"},
			"THREATEN": {"speaker": "CHIDI", "text": "You sound like Dad. You sound exactly like Dad.", "trust": -10, "outcome": "burned"},
			"CHARM": {"speaker": "CHIDI", "text": "...There's a man at Vesper. Okafor. He said my name like he'd read it somewhere.", "trust": 10, "outcome": "lead_strong"},
			"LIE": {"speaker": "CHIDI", "text": "Don't do that. Don't make it easy for me to hide behind you.", "trust": 2, "outcome": "lead"},
		},
		"default": "I'm not asking you to save me. I'm asking you not to disappear too.",
	},
	"tunde": {
		"entry": "crew",
		"start": "Bring it to the garage. If it rolls, I'll make it roll faster.",
		"choices": [
			{"tag": "ASK", "label": "What do you hear on the radios?"},
			{"tag": "CHARM", "label": "Remember when we were kids and you never once ratted me out?"},
			{"tag": "THREATEN", "label": "I'm not asking as a friend."},
			{"tag": "LIE", "label": "The cops already rolled through. They said your name."},
		],
		"responses": {
			"ASK": {"speaker": "TUNDE", "text": "Grey sedan, no plate, three nights running on Ash Row. Somebody's watching somebody.", "trust": 4, "outcome": "lead"},
			"CHARM": {"speaker": "TUNDE", "text": "And I still won't. Look — three nights, grey sedan. Don't make me say it twice, my chest hurts.", "trust": 9, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "TUNDE", "text": "Oh, we're doing that now? Fine. Then I don't know you and that car don't exist.", "trust": -11, "outcome": "burned"},
			"LIE": {"speaker": "TUNDE", "text": "Cops don't say names, they say paperwork. You're getting worse at this.", "trust": -5, "outcome": "closed"},
		},
		"default": "Bring me something worth fixing, not another problem.",
	},
	"eze": {
		"entry": "crew",
		"start": "Everyone comes through this counter eventually. You're late.",
		"choices": [
			{"tag": "ASK", "label": "What's the going rate for information?"},
			{"tag": "CHARM", "label": "I've been buying from you since I was fifteen."},
			{"tag": "THREATEN", "label": "Your ledger, or your fingers."},
			{"tag": "LIE", "label": "Meridian sent me to audit you."},
		],
		"responses": {
			"ASK": {"speaker": "EZE", "text": "Rate depends who's asking. For you? A favour and a hundred. The favour first.", "trust": 3, "outcome": "deal"},
			"CHARM": {"speaker": "EZE", "text": "Fifteen and never once short. Fine. Meridian's been buying off this street one name at a time.", "trust": 7, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "EZE", "text": "Touch this counter and every trader in Guttermarket knows your face by morning.", "trust": -14, "outcome": "burned"},
			"LIE": {"speaker": "EZE", "text": "Meridian audits with auditors. They'd have sent a man in a better coat.", "trust": -4, "outcome": "closed"},
		},
		"default": "Favour first. Then we talk.",
	},
	"sunday": {
		"entry": "family",
		"start": "Heard your brother's name in the chair last week. Didn't like the way it was said.",
		"choices": [
			{"tag": "ASK", "label": "Who said it, and to who?"},
			{"tag": "CHARM", "label": "You cut hair for everyone. You must be sick of secrets."},
			{"tag": "THREATEN", "label": "I can make this chair a very unpleasant place."},
			{"tag": "LIE", "label": "He's home. Safe. I'm here about something else."},
		],
		"responses": {
			"ASK": {"speaker": "SUNDAY", "text": "A man with a folder. Corporate haircut, corporate shoes. He said 'asset' like it was a surname.", "trust": 5, "outcome": "lead"},
			"CHARM": {"speaker": "SUNDAY", "text": "Sick enough to talk to you. Folder man comes back Friday. Sit in the chair next Friday and you'll meet him.", "trust": 8, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "SUNDAY", "text": "In my chair? My chair? Out. Now. And don't come back for the funeral either.", "trust": -15, "outcome": "burned"},
			"LIE": {"speaker": "SUNDAY", "text": "Then why are you standing like a man at a graveside?", "trust": -3, "outcome": "closed"},
		},
		"default": "Friday. Folder man. Don't bring a knife to a conversation, or do, I'm not your mother.",
	},
	"ada": {
		"entry": "corporation",
		"start": "Whatever your brother signed, Meridian filed it as a voluntary transfer. That's not normal.",
		"choices": [
			{"tag": "ASK", "label": "Why do you care what's normal?"},
			{"tag": "CHARM", "label": "You're the only honest person I've met all week."},
			{"tag": "THREATEN", "label": "You filed it. That makes you part of it."},
			{"tag": "LIE", "label": "I'm management. You're going to forget this conversation."},
		],
		"responses": {
			"ASK": {"speaker": "ADA", "text": "Because I type the forms, and I'd rather not type my own name into one. Voluntary transfers don't happen at two in the morning.", "trust": 6, "outcome": "lead"},
			"CHARM": {"speaker": "ADA", "text": "Flattery. Fine. There's a copy. There's always a copy. Vesper archive, sub-level, and I never told you.", "trust": 9, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "ADA", "text": "Then we're both part of it and I'll be the one with a lawyer.", "trust": -10, "outcome": "burned"},
			"LIE": {"speaker": "ADA", "text": "Management doesn't use the service elevator. Try again somewhere with fewer cameras.", "trust": -5, "outcome": "closed"},
		},
		"default": "Be careful. The paperwork is clean. That's the whole point of paperwork.",
	},
	"okafor": {
		"entry": "corporation",
		"start": "Mr Adeyemi. Your brother is an asset now. Assets don't leave.",
		"choices": [
			{"tag": "ASK", "label": "What is he an asset of?"},
			{"tag": "THREATEN", "label": "You'll want security in the room before you finish that sentence."},
			{"tag": "CHARM", "label": "You've done this before. I can hear it."},
			{"tag": "LIE", "label": "I'm not here for him. I'm here to sell you the district."},
		],
		"responses": {
			"ASK": {"speaker": "OKAFOR", "text": "Labour. Debt. Collateral. Pick the word that helps you sleep and use it.", "trust": -2, "outcome": "defiant"},
			"THREATEN": {"speaker": "OKAFOR", "text": "There's a door behind me with four people behind it. Do finish your sentence.", "trust": -8, "outcome": "burned"},
			"CHARM": {"speaker": "OKAFOR", "text": "...Seventeen years. Yes. You're the first one who noticed.", "trust": 4, "outcome": "crack"},
			"LIE": {"speaker": "OKAFOR", "text": "Ash Row isn't worth a coffee. You're a bad liar with a good face. Sit down anyway.", "trust": 1, "outcome": "intrigued"},
		},
		"default": "Make an appointment. Make it worth my time.",
	},
	"nyame": {
		"entry": "police",
		"start": "I can help you, or I can write you down. Choose faster than last time.",
		"choices": [
			{"tag": "ASK", "label": "What do you actually want from me?"},
			{"tag": "CHARM", "label": "You've got a bad job and a worse boss. Same as me."},
			{"tag": "THREATEN", "label": "Write me down. See what happens to the paperwork."},
			{"tag": "LIE", "label": "I've got a statement to make about a grey sedan."},
		],
		"responses": {
			"ASK": {"speaker": "NYAME", "text": "I want Meridian off my ledgers. They keep filing cases I'm told to lose. Bring me proof and I'll lose nothing.", "trust": 6, "outcome": "lead_strong"},
			"CHARM": {"speaker": "NYAME", "text": "Don't. Don't make me like you, it complicates everything. Grey sedan's a Meridian fleet plate. There. Now we're even.", "trust": 8, "outcome": "lead"},
			"THREATEN": {"speaker": "NYAME", "text": "Bold. Stupid, but bold. I'll write you down and I'll enjoy the typing.", "trust": -12, "outcome": "burned"},
			"LIE": {"speaker": "NYAME", "text": "Statements are for witnesses. You're not dressed like a witness.", "trust": -2, "outcome": "closed"},
		},
		"default": "Stay useful and I'll stay out of your way.",
	},
	"ibrahim": {
		"entry": "crew",
		"start": "I've had your family's file for three months. Today it started making sense.",
		"choices": [
			{"tag": "ASK", "label": "Three months. Who ordered the file?"},
			{"tag": "CHARM", "label": "A file that old means you were waiting for someone to ask."},
			{"tag": "THREATEN", "label": "Files burn. People who keep them burn faster."},
			{"tag": "LIE", "label": "Meridian wants the file back. Hand it over."},
		],
		"responses": {
			"ASK": {"speaker": "IBRAHIM", "text": "Nobody ordered it. That's the interesting part. It arrived. Files don't arrive.", "trust": 6, "outcome": "lead"},
			"CHARM": {"speaker": "IBRAHIM", "text": "Three months of waiting and one good question. Your father's name is on the transfer too. Older one.", "trust": 10, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "IBRAHIM", "text": "Then I'll make copies. I'm a records man, it's all I know how to do.", "trust": -9, "outcome": "burned"},
			"LIE": {"speaker": "IBRAHIM", "text": "Meridian doesn't ask. They requisition. You're not Meridian.", "trust": -3, "outcome": "closed"},
		},
		"default": "Read it somewhere I can't see you reading it.",
	},
	"kola": {
		"entry": "crew",
		"start": "You got a week before this stops being a conversation.",
		"choices": [
			{"tag": "ASK", "label": "A week until what?"},
			{"tag": "THREATEN", "label": "Say the number. I'll pay it in teeth."},
			{"tag": "CHARM", "label": "You and me grew up under the same broken lamp."},
			{"tag": "LIE", "label": "The debt's cleared. Check with Eze."},
		],
		"responses": {
			"ASK": {"speaker": "KOLA", "text": "Until the people I answer to stop asking nicely. And they don't ask nicely.", "trust": 3, "outcome": "lead"},
			"THREATEN": {"speaker": "KOLA", "text": "Teeth. Sure. And then six people come looking, and they don't ask first either.", "trust": -10, "outcome": "burned"},
			"CHARM": {"speaker": "KOLA", "text": "...Same lamp. God. Fine. The debt's Meridian's, not mine. I'm just the one they send.", "trust": 9, "outcome": "lead_strong"},
			"LIE": {"speaker": "KOLA", "text": "Eze doesn't clear debts, he collects them. Try again.", "trust": -5, "outcome": "closed"},
		},
		"default": "A week. Don't spend it all on this.",
	},
	"bimpe": {
		"entry": "crew",
		"start": "Tell me what needs arranging. I'll tell you what it costs.",
		"choices": [
			{"tag": "ASK", "label": "Can you arrange a meeting?"},
			{"tag": "CHARM", "label": "You're the only one in this city who returns calls."},
			{"tag": "THREATEN", "label": "You'll arrange it for free."},
			{"tag": "LIE", "label": "Meridian's paying triple for the same favour."},
		],
		"responses": {
			"ASK": {"speaker": "BIMPE", "text": "A meeting I can do. Neutral ground, Dockside, Tuesday. It costs a favour I'll call in badly.", "trust": 5, "outcome": "deal"},
			"CHARM": {"speaker": "BIMPE", "text": "Flattery gets you Tuesday and a warning: whoever you're meeting already knows you asked.", "trust": 8, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "BIMPE", "text": "Free is a word people die over in this city. No.", "trust": -11, "outcome": "burned"},
			"LIE": {"speaker": "BIMPE", "text": "Meridian doesn't pay triple. Meridian pays never and calls it a favour.", "trust": -4, "outcome": "closed"},
		},
		"default": "Tuesday. Dockside. Bring the favour.",
	},
	"mara": {
		"entry": "crew",
		"start": "Neon Mile runs on paper and loyalty. Guess which one I check.",
		"choices": [
			{"tag": "ASK", "label": "What does the paper say about my brother?"},
			{"tag": "CHARM", "label": "You've been holding this club together for years. Nobody says it."},
			{"tag": "THREATEN", "label": "Your dancers leave with me or your club closes."},
			{"tag": "LIE", "label": "The Mile's been sold. I'm the buyer."},
		],
		"responses": {
			"ASK": {"speaker": "MARA", "text": "It says a grey car parked outside for two hours and no one thought that was strange. Paper's honest. People aren't.", "trust": 5, "outcome": "lead"},
			"CHARM": {"speaker": "MARA", "text": "Nobody says it. You said it. Two hours, grey car, and a name on the guest list that shouldn't be: Okafor.", "trust": 9, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "MARA", "text": "My dancers would leave with you and then they'd leave you. Bar's closed to you.", "trust": -13, "outcome": "burned"},
			"LIE": {"speaker": "MARA", "text": "Then where's the contract? Nobody buys the Mile with their hands in their pockets.", "trust": -5, "outcome": "closed"},
		},
		"default": "Two hours. Grey car. Okafor. Now get out of my club sober.",
	},
	"osaze": {
		"entry": "crew",
		"start": "The container at Iron Yard was never manifested. Somebody paid to unsee it.",
		"choices": [
			{"tag": "ASK", "label": "Who paid?"},
			{"tag": "CHARM", "label": "You've been sitting on this for months. You wanted to tell someone."},
			{"tag": "THREATEN", "label": "Open the container or I open you."},
			{"tag": "LIE", "label": "Customs already knows. I'm here to warn you."},
		],
		"responses": {
			"ASK": {"speaker": "OSAZE", "text": "Payment came from a Meridian account with a sister company's stamp. Same stamp on your brother's transfer.", "trust": 7, "outcome": "lead_strong"},
			"CHARM": {"speaker": "OSAZE", "text": "Months. Months I've sat on it. Container nine. Go at night, go with someone, and don't take it personally.", "trust": 9, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "OSAZE", "text": "Open it? You couldn't open it with a crane and a prayer. And now I'm not telling you why.", "trust": -12, "outcome": "burned"},
			"LIE": {"speaker": "OSAZE", "text": "Customs doesn't warn. Customs fines. You're not customs.", "trust": -4, "outcome": "closed"},
		},
		"default": "Container nine. Whatever you're imagining, it's heavier.",
	},
	"gideon": {
		"entry": "corporation",
		"start": "The paperwork is clean. That's the whole point of paperwork.",
		"choices": [
			{"tag": "ASK", "label": "Clean for who?"},
			{"tag": "CHARM", "label": "You know it's not clean. I can see it on you."},
			{"tag": "THREATEN", "label": "Your signature is on it. That's all I need."},
			{"tag": "LIE", "label": "I'm from audit. Sign or I escalate."},
		],
		"responses": {
			"ASK": {"speaker": "GIDEON", "text": "For the shareholders. For the city. For everyone who'd rather not read page nine.", "trust": 3, "outcome": "lead"},
			"CHARM": {"speaker": "GIDEON", "text": "I sleep four hours. My wife thinks I'm having an affair. Page nine. Voluntary transfer. My signature. There.", "trust": 10, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "GIDEON", "text": "Then you'll need a lawyer with a cleaner signature than mine. I have several.", "trust": -9, "outcome": "burned"},
			"LIE": {"speaker": "GIDEON", "text": "Audit has a badge. Audit has a terrible coffee in their hand. You have neither.", "trust": -4, "outcome": "closed"},
		},
		"default": "Page nine. Don't come back with questions I'll have to answer.",
	},
	"amaka": {
		"entry": "family",
		"start": "I don't want the money back. I want him back.",
		"choices": [
			{"tag": "ASK", "label": "Who took him?"},
			{"tag": "CHARM", "label": "I'll find him. You don't have to be strong in front of me."},
			{"tag": "THREATEN", "label": "If you're hiding something, I'll find that too."},
			{"tag": "LIE", "label": "He's safe. He's under my protection."},
		],
		"responses": {
			"ASK": {"speaker": "AMAKA", "text": "Three men and a grey car. One of them apologised. That's the part I can't sleep on. He apologised.", "trust": 8, "outcome": "lead_strong"},
			"CHARM": {"speaker": "AMAKA", "text": "Then find him and I'll cry when he's in the room. He apologised, Marcus. The one who took him apologised.", "trust": 10, "outcome": "lead_strong"},
			"THREATEN": {"speaker": "AMAKA", "text": "Hiding? Hiding? Get out of my house.", "trust": -15, "outcome": "burned"},
			"LIE": {"speaker": "AMAKA", "text": "Don't. Don't you dare lie to me about my son.", "trust": -8, "outcome": "closed"},
		},
		"default": "He apologised. Find out why a man apologises for what he's allowed to do.",
	},
}

var world: Node3D = null
var _rng := RandomNumberGenerator.new()
var _bark_cooldown := 0.0
var _last_ambient := ""
var _conversations_had := {}
var _witnessed := {}

func setup(w: Node3D) -> void:
	world = w
	_rng.randomize()

func has_tree(npc_id: String) -> bool:
	return TREES.has(npc_id)

func tree_for(npc_id: String) -> Dictionary:
	return TREES.get(npc_id, {})

# ------------------------------------------------------------------ barks
## Ambient chatter near a position. Fires from npc_population on a timer.
func ambient_bark(pos: Vector3, district: String) -> void:
	if _bark_cooldown > 0.0 or world == null:
		return
	var lines: Array = AMBIENT.get(district, [])
	if lines.is_empty():
		return
	var line: String = str(lines[_rng.randi() % lines.size()])
	if line == _last_ambient and lines.size() > 1:
		return
	_last_ambient = line
	_bark_cooldown = 7.0
	var name: String = str(world.nearest_actor_name(pos, 9.0)) if world.has_method("nearest_actor_name") else ""
	bark_spoken.emit(name, line)
	if world.hud != null and world.hud.has_method("show_bark"):
		world.hud.show_bark(name, line, pos)

## Reaction to violence in view. Escalates with city heat.
func witness_bark(pos: Vector3) -> void:
	var tier := "calm"
	if Game.heat > 55.0:
		tier = "panic"
	elif Game.heat > 20.0:
		tier = "shock"
	var lines: Array = WITNESS[tier]
	var line: String = str(lines[_rng.randi() % lines.size()])
	bark_spoken.emit("", line)
	if world != null and world.hud != null and world.hud.has_method("show_bark"):
		world.hud.show_bark("", line, pos)

func _process(delta: float) -> void:
	_bark_cooldown = maxf(0.0, _bark_cooldown - delta)

# ------------------------------------------------------------------ talks
## Build the dialogue payload for a named NPC. Returns lines for the box plus
## the choice list, with tags already coloured.
func open_talk(npc_id: String) -> Dictionary:
	var tree: Dictionary = TREES.get(npc_id, {})
	if tree.is_empty():
		return {}
	var speaker: String = Content.character_name(npc_id).to_upper()
	var start := {"speaker": speaker, "text": str(tree.get("start", ""))}
	var choices: Array = []
	for c in tree.get("choices", []):
		var tag := str(c.get("tag", "ASK")).to_upper()
		choices.append({
			"tag": tag,
			"label": str(c.get("label", "")),
			"color": TAG_COLORS.get(tag, TAG_COLORS["ASK"]),
		})
	conversation_started.emit(npc_id)
	return {
		"id": npc_id, "speaker": speaker,
		"start": start, "choices": choices, "tree": tree,
	}

## Resolve a chosen tag. Trust moves by faction standing, not just by the tag:
## threatening someone who already outranks you costs far more than threatening
## a frightened lookout.
func resolve(npc_id: String, tag: String) -> Dictionary:
	var tree: Dictionary = TREES.get(npc_id, {})
	var resp: Dictionary = tree.get("responses", {}).get(tag.to_upper(), {})
	if resp.is_empty():
		conversation_ended.emit(npc_id, "none")
		return {}

	var trust: float = float(resp.get("trust", 0))
	var outcome := str(resp.get("outcome", "neutral"))

	# Faction standing modulates the consequence.
	var faction := str(Content.CHARACTERS.get(npc_id, {}).get("faction", "family"))
	var standing: float = float(Game.trust.get(faction, 30))
	if tag.to_upper() == "THREATEN" and standing < 25.0:
		trust -= 8.0            # threatening someone who owes you nothing reads as a bluff
		outcome = "burned"
	elif tag.to_upper() == "CHARM" and standing > 55.0:
		trust += 4.0            # warmth lands harder when they already trust you

	Game.add_relationship(npc_id, int(round(trust)))
	Game.trust[faction] = clampf(float(Game.trust.get(faction, 30)) + trust * 0.35, -100.0, 100.0)
	_conversations_had[npc_id] = int(_conversations_had.get(npc_id, 0)) + 1
	conversation_ended.emit(npc_id, outcome)
	Events.record("conversation", {"id": npc_id, "tag": tag, "outcome": outcome})

	return {
		"speaker": str(resp.get("speaker", "")),
		"text": str(resp.get("text", "")),
		"outcome": outcome,
		"trust": trust,
		"closing": str(tree.get("default", "")),
	}

func times_talked(npc_id: String) -> int:
	return int(_conversations_had.get(npc_id, 0))
