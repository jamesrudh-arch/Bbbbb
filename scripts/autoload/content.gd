extends Node
## CONTENT — the authoritative data layer for LEVERAGE.
## Every district, character, mission, discipline, weapon, vehicle, shop and
## radio report lives here so gameplay code never hard-codes content.
## Contract reference: tests/test_suite.gd asserts the shape of these tables.

# ============================================================ DISTRICTS
# Six connected areas on a 3x2 grid. Grid coordinates feed a fixed 160 m pitch
# so the city is a single continuous 480 x 320 m landmass, not six mini-levels.
const DISTRICTS := {
	"ash_row": {
		"name": "Ash Row", "grid": [0, 0], "tier": 1,
		"tagline": "Where the blocks raised you. Concrete, cookouts, and cousins.",
		"palette": {"sky": Color(0.42, 0.38, 0.34), "ground": Color(0.30, 0.27, 0.24),
			"wall": Color(0.55, 0.48, 0.40), "trim": Color(0.72, 0.55, 0.32),
			"accent": Color(0.95, 0.62, 0.24)},
		"faction": "family", "density": 0.9, "height": [2, 5],
		"landmarks": ["mama_ngozi", "sunday_barber", "block_14"],
		"music": "explore", "population": 9,
	},
	"guttermarket": {
		"name": "Guttermarket", "grid": [1, 0], "tier": 1,
		"tagline": "Fifty stalls deep. Everything has a price, nothing has a receipt.",
		"palette": {"sky": Color(0.36, 0.34, 0.33), "ground": Color(0.26, 0.24, 0.22),
			"wall": Color(0.48, 0.42, 0.36), "trim": Color(0.70, 0.48, 0.26),
			"accent": Color(0.98, 0.72, 0.30)},
		"faction": "crew", "density": 1.0, "height": [1, 4],
		"landmarks": ["stall_row", "pawn_shop", "cold_room"],
		"music": "explore", "population": 10,
	},
	"iron_yard": {
		"name": "Iron Yard", "grid": [2, 0], "tier": 2,
		"tagline": "Cranes at 3 a.m. Container stacks nobody counted twice.",
		"palette": {"sky": Color(0.33, 0.36, 0.40), "ground": Color(0.22, 0.24, 0.26),
			"wall": Color(0.40, 0.44, 0.48), "trim": Color(0.52, 0.58, 0.62),
			"accent": Color(0.60, 0.78, 0.92)},
		"faction": "corporation", "density": 0.55, "height": [2, 6],
		"landmarks": ["garage", "weigh_station", "crane_four"],
		"music": "tension", "population": 7,
	},
	"cinder_line": {
		"name": "Cinder Line", "grid": [0, 1], "tier": 2,
		"tagline": "The rail that fed the city, now feeding the foundries.",
		"palette": {"sky": Color(0.40, 0.30, 0.27), "ground": Color(0.26, 0.21, 0.19),
			"wall": Color(0.44, 0.33, 0.29), "trim": Color(0.62, 0.36, 0.22),
			"accent": Color(0.96, 0.50, 0.24)},
		"faction": "crew", "density": 0.65, "height": [3, 6],
		"landmarks": ["foundry", "rail_platform", "slag_pit"],
		"music": "tension", "population": 8,
	},
	"vesper_heights": {
		"name": "Vesper Heights", "grid": [1, 1], "tier": 3,
		"tagline": "Glass and security lights. They sleep well up here.",
		"palette": {"sky": Color(0.30, 0.34, 0.46), "ground": Color(0.20, 0.22, 0.28),
			"wall": Color(0.38, 0.42, 0.52), "trim": Color(0.72, 0.76, 0.86),
			"accent": Color(0.62, 0.84, 1.0)},
		"faction": "corporation", "density": 0.8, "height": [5, 10],
		"landmarks": ["glass_tower", "corporate_club", "helipad"],
		"music": "explore", "population": 9,
	},
	"neon_mile": {
		"name": "Neon Mile", "grid": [2, 1], "tier": 3,
		"tagline": "Two in the morning and nobody's counting the receipts.",
		"palette": {"sky": Color(0.22, 0.18, 0.32), "ground": Color(0.16, 0.14, 0.22),
			"wall": Color(0.28, 0.22, 0.36), "trim": Color(0.98, 0.34, 0.72),
			"accent": Color(1.0, 0.36, 0.78)},
		"faction": "crew", "density": 1.0, "height": [3, 8],
		"landmarks": ["velvet_room", "chop_house", "arcade"],
		"music": "tension", "population": 11,
	},
}

const DISTRICT_ORDER := ["ash_row", "guttermarket", "iron_yard", "cinder_line", "vesper_heights", "neon_mile"]

## Landmarks that can be entered. Each becomes a portal + interior scene.
const INTERIORS := {
	"mama_ngozi": {"district": "ash_row", "name": "Mama Ngozi's Kitchen", "kind": "kitchen",
		"blurb": "Rice, stew, and the only honest ledger in Ash Row.",
		"vendor": "food", "size": Vector2(9, 7)},
	"sunday_barber": {"district": "ash_row", "name": "Sunday's Barbershop", "kind": "barber",
		"blurb": "Cuts, gossip, and a back room that isn't a barbershop.",
		"vendor": "wardrobe", "size": Vector2(8, 6)},
	"pawn_shop": {"district": "guttermarket", "name": "Eze's Pawn", "kind": "pawn",
		"blurb": "He'll buy your watch. He'll tell you who sold it first.",
		"vendor": "weapons", "size": Vector2(9, 7)},
	"garage": {"district": "iron_yard", "name": "Tunde's Garage", "kind": "garage",
		"blurb": "Three bays, one lift, no questions.",
		"vendor": "vehicles", "size": Vector2(14, 10)},
	"velvet_room": {"district": "neon_mile", "name": "The Velvet Room", "kind": "club",
		"blurb": "They card at the door. The door takes cash.",
		"vendor": "drinks", "size": Vector2(13, 9)},
	"chop_house": {"district": "neon_mile", "name": "Chop House", "kind": "kitchen",
		"blurb": "Street food with a queue that moves.",
		"vendor": "food", "size": Vector2(8, 6)},
	"corporate_club": {"district": "vesper_heights", "name": "Meridian Club", "kind": "club",
		"blurb": "Members only. Leverage counts as a membership.",
		"vendor": "drinks", "size": Vector2(14, 10)},
	"sunday_market": {"district": "guttermarket", "name": "Sunday Market", "kind": "market",
		"blurb": "Everything legal, half of it isn't.",
		"vendor": "general", "size": Vector2(16, 12)},
}

# ============================================================ CAST
# 16 named characters. `role` drives AI behaviour, `model` maps to a rigged GLB.
const CHARACTERS := {
	"emeka": {"name": "Emeka Obi", "model": "casual-male", "role": "protagonist",
		"faction": "family", "home": "ash_row", "color": Color(0.85, 0.55, 0.25),
		"bio": "Thirty-one. Came home to a debt with his brother's name on it."},
	"chidi": {"name": "Chidi Obi", "model": "casual2-male", "role": "brother",
		"faction": "family", "home": "ash_row", "color": Color(0.70, 0.45, 0.30),
		"bio": "Younger. Borrowed ₦4.2 million from the wrong ledger and vanished."},
	"ngozi": {"name": "Mama Ngozi", "model": "casual-female", "role": "mentor",
		"faction": "family", "home": "ash_row", "color": Color(0.95, 0.72, 0.35),
		"bio": "Runs the kitchen. Runs Ash Row. Knows which one matters more."},
	"tunde": {"name": "Tunde Bello", "model": "worker-male", "role": "mechanic",
		"faction": "crew", "home": "iron_yard", "color": Color(0.55, 0.60, 0.68),
		"bio": "Keeps the city moving for cash and keeps the cash moving for nobody."},
	"eze": {"name": "Eze Nwosu", "model": "suit-male", "role": "fence",
		"faction": "crew", "home": "guttermarket", "color": Color(0.72, 0.60, 0.32),
		"bio": "Pawnbroker. Information broker. Same counter."},
	"sunday": {"name": "Sunday Adeleke", "model": "casual3-male", "role": "barber",
		"faction": "family", "home": "ash_row", "color": Color(0.60, 0.70, 0.85),
		"bio": "Cut hair for half of Ash Row. Remembers all of their business."},
	"ada": {"name": "Ada Okonkwo", "model": "casual2-female", "role": "journalist",
		"faction": "none", "home": "vesper_heights", "color": Color(0.50, 0.78, 0.85),
		"bio": "Chronicle reporter. Chasing the ledger because someone sent her a page of it."},
	"kola": {"name": "Kola Jaiyeola", "model": "suit-male", "role": "enforcer",
		"faction": "crew", "home": "neon_mile", "color": Color(0.85, 0.30, 0.45),
		"bio": "Collector for the Mile. Polite right up until he isn't."},
	"okafor": {"name": "Victor Okafor", "model": "suit-male", "role": "executive",
		"faction": "corporation", "home": "vesper_heights", "color": Color(0.42, 0.58, 0.88),
		"bio": "Meridian's recovery director. Calls kidnapping 'asset relocation'."},
	"nyame": {"name": "Sergeant Nyame", "model": "worker-female", "role": "police",
		"faction": "police", "home": "vesper_heights", "color": Color(0.30, 0.45, 0.85),
		"bio": "Twelve years on the force. Knows exactly which calls get answered."},
	"ibrahim": {"name": "Detective Ibrahim", "model": "casual-bald", "role": "police",
		"faction": "police", "home": "guttermarket", "color": Color(0.45, 0.52, 0.72),
		"bio": "Took the Obi file when nobody else would. It's costing him."},
	"amaka": {"name": "Amaka Obi", "model": "casual3-female", "role": "mother",
		"faction": "family", "home": "ash_row", "color": Color(0.90, 0.62, 0.62),
		"bio": "Raised two boys on one salary. Recognises a lie in a text message."},
	"bimpe": {"name": "Bimpe Osei", "model": "casual2-female", "role": "fixer",
		"faction": "crew", "home": "neon_mile", "color": Color(0.82, 0.44, 0.72),
		"bio": "Arranges things. Never the thing itself — the arrangement."},
	"gideon": {"name": "Gideon Marsh", "model": "suit-male", "role": "corporate_fixer",
		"faction": "corporation", "home": "vesper_heights", "color": Color(0.66, 0.72, 0.80),
		"bio": "Meridian legal. Drafts the paper that makes a kidnapping lawful."},
	"osaze": {"name": "Osaze 'Oz' Iyamu", "model": "casual-male", "role": "informant",
		"faction": "crew", "home": "cinder_line", "color": Color(0.58, 0.74, 0.52),
		"bio": "Sells rumours by the yard. Most of them are even true."},
	"mara": {"name": "Mara Silva", "model": "casual-female", "role": "crew_boss",
		"faction": "crew", "home": "neon_mile", "color": Color(0.92, 0.36, 0.50),
		"bio": "Runs Neon Mile. Runs it the way a ledger runs a bank."},
}

# ~25 pedestrians: archetype templates, named at runtime.
const PEDESTRIANS := {
	"market_trader": {"models": ["casual-female", "casual2-female", "worker-female"], "districts": ["guttermarket"], "role": "trader"},
	"worker": {"models": ["worker-male", "worker-female"], "districts": ["iron_yard", "cinder_line"], "role": "worker"},
	"office_drone": {"models": ["suit-male", "suit-female"], "districts": ["vesper_heights"], "role": "office"},
	"clubber": {"models": ["casual3-male", "casual3-female", "casual2-male"], "districts": ["neon_mile"], "role": "reveller"},
	"neighbour": {"models": ["casual-male", "casual-female", "casual-bald"], "districts": ["ash_row"], "role": "neighbour"},
	"courier": {"models": ["casual2-male", "casual-bald"], "districts": ["guttermarket", "iron_yard", "vesper_heights"], "role": "courier"},
}

# ============================================================ FACTIONS
const FACTIONS := {
	"family": {"name": "Obi Family", "color": Color(0.95, 0.62, 0.24),
		"desc": "The block. Loyalty without paperwork.", "trust_start": 60},
	"corporation": {"name": "Meridian Group", "color": Color(0.42, 0.58, 0.88),
		"desc": "Legitimate on paper. Predatory in practice.", "trust_start": 0},
	"crew": {"name": "Neon Mile Crew", "color": Color(0.92, 0.36, 0.50),
		"desc": "Loose network, tight ledger.", "trust_start": 20},
	"police": {"name": "Cinder City PD", "color": Color(0.30, 0.45, 0.85),
		"desc": "Underfunded. Overworked. Selectively honest.", "trust_start": 10},
}

# ============================================================ DISCIPLINES
# Five combat styles with real mechanical differences (reach, damage, speed,
# stamina cost, armour interaction). Not cosmetic renames.
const DISCIPLINES := {
	"brawler": {
		"name": "Brawler", "reach": 1.9, "damage": 1.0, "speed": 1.0, "stamina": 1.0,
		"desc": "Straight hands. Short reach, honest damage, no wasted motion.",
		"heavy": "Overhand right that rocks them back", "kick": "Low stomp to the knee",
		"identity": "Balanced baseline — every other style trades off against it.",
		"unlock": "",
	},
	"kickboxing": {
		"name": "Kickboxing", "reach": 2.6, "damage": 0.82, "speed": 1.25, "stamina": 0.85,
		"desc": "Long range, fast combinations, weak against armour.",
		"heavy": "Switch kick to the head", "kick": "Teep that creates space",
		"identity": "Wins at range. Loses if the fight gets inside 1.5 m.",
		"unlock": "gutter_tavern",
	},
	"grappling": {
		"name": "Grappling", "reach": 1.4, "damage": 1.4, "speed": 0.72, "stamina": 1.3,
		"desc": "Clinch, throw, ground damage. Armour does nothing on the floor.",
		"heavy": "Slam takedown", "kick": "Knee from the clinch",
		"identity": "Highest damage in the game; must survive the approach.",
		"unlock": "iron_debt",
	},
	"drunken": {
		"name": "Drunken Fist", "reach": 2.1, "damage": 0.9, "speed": 0.95, "stamina": 0.9,
		"desc": "Unpredictable sway. Dodges cost less and break enemy timing.",
		"heavy": "Spinning elbow out of a stagger", "kick": "Sweeping trip",
		"identity": "Cheapest dodges, best counter windows, lowest raw damage.",
		"unlock": "velvet_room",
	},
	"weapon": {
		"name": "Weapon", "reach": 3.0, "damage": 1.6, "speed": 0.85, "stamina": 1.1,
		"desc": "Anything with weight. Range and damage, but loud and slow.",
		"heavy": "Two-handed overhead", "kick": "Boot to push them off",
		"identity": "Highest reach and damage; heavy heat penalty when seen.",
		"unlock": "",
	},
}

# ============================================================ WEAPONS
const WEAPONS := {
	"fists": {"name": "Bare Hands", "kind": "melee", "damage": 8.0, "reach": 1.9, "speed": 1.0, "price": 0},
	"pipe": {"name": "Steel Pipe", "kind": "melee", "damage": 17.0, "reach": 2.6, "speed": 0.9, "price": 90},
	"machete": {"name": "Machete", "kind": "melee", "damage": 24.0, "reach": 2.4, "speed": 1.05, "price": 340},
	"baton": {"name": "Collapsible Baton", "kind": "melee", "damage": 14.0, "reach": 2.2, "speed": 1.2, "price": 210},
	"pistol": {"name": "Locally Made Pistol", "kind": "gun", "damage": 22.0, "reach": 30.0, "speed": 1.0,
		"price": 900, "mag": 8, "reserve": 40, "noise": 55.0},
	"smg": {"name": "Compact SMG", "kind": "gun", "damage": 14.0, "reach": 24.0, "speed": 1.6,
		"price": 2400, "mag": 25, "reserve": 100, "noise": 45.0},
	"shotgun": {"name": "Sawed-Off", "kind": "gun", "damage": 46.0, "reach": 12.0, "speed": 0.7,
		"price": 3100, "mag": 2, "reserve": 20, "noise": 70.0},
}

# ============================================================ ARMOUR
const ARMOR := {
	"none": {"name": "Street Clothes", "protect": 0.0, "price": 0, "speed": 1.0},
	"padded": {"name": "Padded Jacket", "protect": 0.15, "price": 220, "speed": 1.0},
	"vest": {"name": "Ballistic Vest", "protect": 0.30, "price": 420, "speed": 0.96},
	"riot": {"name": "Surplus Riot Plate", "protect": 0.48, "price": 1100, "speed": 0.88},
}

# ============================================================ VEHICLES
const VEHICLE_TYPES := {
	"sedan": {"name": "Sedan", "model": "sedan", "seats": 4, "top_speed": 31.0, "accel": 14.0,
		"handling": 1.0, "mass": 1200.0, "price": 0},
	"hatchback": {"name": "Hatchback", "model": "hatchback-sports", "seats": 4, "top_speed": 28.0,
		"accel": 13.0, "handling": 1.15, "mass": 1050.0, "price": 0},
	"van": {"name": "Panel Van", "model": "van", "seats": 5, "top_speed": 25.0, "accel": 10.0,
		"handling": 0.82, "mass": 1900.0, "price": 0},
	"taxi": {"name": "Taxi", "model": "taxi", "seats": 4, "top_speed": 30.0, "accel": 14.0,
		"handling": 1.0, "mass": 1180.0, "price": 0},
	"police": {"name": "Patrol Car", "model": "police", "seats": 4, "top_speed": 36.0, "accel": 17.0,
		"handling": 1.1, "mass": 1350.0, "price": 0},
	"truck": {"name": "Box Truck", "model": "truck", "seats": 3, "top_speed": 22.0, "accel": 8.0,
		"handling": 0.72, "mass": 2600.0, "price": 0},
	"muscle": {"name": "Muscle Coupe", "model": "muscle", "seats": 2, "top_speed": 40.0, "accel": 20.0,
		"handling": 1.05, "mass": 1400.0, "price": 14000},
	"bike": {"name": "Street Motorcycle", "model": "motorcycle", "seats": 2, "top_speed": 38.0,
		"accel": 22.0, "handling": 1.35, "mass": 220.0, "price": 6800, "two_wheel": true},
}

# ============================================================ MISSIONS
# Main story: 5 chapters. Each objective is typed so systems can drive it.
# types: reach | talk | collect | fight | escape | choice | drive | steal
const MISSIONS := {
	"homecoming": {
		"title": "Homecoming", "district": "ash_row", "chapter": 1,
		"brief": "You're back. Mama Ngozi is holding a plate and a problem.",
		"objectives": [
			{"type": "reach", "target": "mama_ngozi", "text": "Walk to Mama Ngozi's Kitchen"},
			{"type": "talk", "target": "ngozi", "text": "Talk to Mama Ngozi"},
			{"type": "collect", "target": "ledger_page", "count": 3, "text": "Recover the torn ledger pages"},
			{"type": "talk", "target": "ngozi", "text": "Bring the pages back to Ngozi"},
		],
		"reward": {"money": 850, "xp": 120, "trust": {"family": 10}},
		"sets": ["homecoming_done"], "unlocks": ["short_count"],
	},
	"short_count": {
		"title": "Short Count", "district": "guttermarket", "chapter": 1,
		"brief": "Chidi borrowed ₦4.2m. The Mile sent Kola to collect it from you instead.",
		"objectives": [
			{"type": "reach", "target": "stall_row", "text": "Go to the Guttermarket stalls"},
			{"type": "fight", "target": "kola", "count": 1, "text": "Survive Kola's collectors"},
			{"type": "talk", "target": "eze", "text": "Ask Eze who signed the note"},
			{"type": "escape", "text": "Lose the attention and get to Neon Mile"},
		],
		"reward": {"money": 1400, "xp": 200, "trust": {"crew": -10, "family": 15}},
		"sets": ["short_count_done"], "unlocks": ["iron_debt"],
	},
	"iron_debt": {
		"title": "Iron Debt", "district": "iron_yard", "chapter": 2,
		"brief": "The trail runs through a container that was never manifested.",
		"objectives": [
			{"type": "reach", "target": "garage", "text": "Meet Tunde at the garage"},
			{"type": "talk", "target": "tunde", "text": "Talk to Tunde"},
			{"type": "steal", "target": "crane_four", "text": "Get the manifest from Crane Four"},
			{"type": "drive", "text": "Drive the manifest out of Iron Yard"},
		],
		"reward": {"money": 2200, "xp": 320, "trust": {"crew": 10}},
		"sets": ["iron_debt_done"], "unlocks": ["glass_ledger"],
	},
	"glass_ledger": {
		"title": "Glass Ledger", "district": "vesper_heights", "chapter": 3,
		"brief": "Meridian keeps the real books in a tower with a name on it.",
		"objectives": [
			{"type": "reach", "target": "glass_tower", "text": "Reach Meridian Tower"},
			{"type": "talk", "target": "ada", "text": "Meet Ada in the lobby"},
			{"type": "collect", "target": "ledger_page", "count": 4, "text": "Recover the Meridian ledger pages"},
			{"type": "escape", "text": "Get out before security locks the floor"},
		],
		"reward": {"money": 3400, "xp": 450, "trust": {"corporation": -25}},
		"sets": ["glass_ledger_done"], "unlocks": ["ash_fall"],
	},
	"ash_fall": {
		"title": "Ash Fall", "district": "neon_mile", "chapter": 4,
		"brief": "Chidi is alive. He's also worth more to Meridian alive than you are.",
		"objectives": [
			{"type": "reach", "target": "velvet_room", "text": "Go to the Velvet Room"},
			{"type": "talk", "target": "mara", "text": "Deal with Mara"},
			{"type": "fight", "target": "okafor", "count": 1, "text": "Take the recovery team"},
			{"type": "choice", "text": "Decide who gets the ledger"},
		],
		"choices": [
			{"id": "burn_it", "text": "Burn the ledger. Nobody gets leverage.",
			 "flag": "burned_ledger", "money": 0, "xp": 600, "trust": {"family": 20, "corporation": -40}},
			{"id": "take_deal", "text": "Sell it to Meridian. Take the money.",
			 "flag": "chose_corp", "money": 2500, "xp": 250, "trust": {"corporation": 25, "family": -25}},
			{"id": "give_ada", "text": "Give it to Ada. Let the city read it.",
			 "flag": "gave_ada", "money": 500, "xp": 500, "trust": {"family": 10, "crew": 15}},
		],
		"reward": {"money": 0, "xp": 0},
		"sets": ["ash_fall_done"], "unlocks": ["cinder_final"],
	},
	"cinder_final": {
		"title": "Cinder", "district": "cinder_line", "chapter": 5,
		"brief": "Chidi's in the foundry. Okafor's people are already inside.",
		"objectives": [
			{"type": "reach", "target": "foundry", "text": "Get to the foundry floor"},
			{"type": "fight", "target": "enforcers", "count": 4, "text": "Clear the foundry"},
			{"type": "talk", "target": "chidi", "text": "Get Chidi out"},
			{"type": "escape", "text": "Get out of Cinder Line"},
		],
		"reward": {"money": 6000, "xp": 900, "trust": {"family": 30}},
		"sets": ["cinder_done", "story_complete"], "unlocks": [],
	},
	# Two shorter beats that sit between chapters
	"sunday_visit": {
		"title": "Sunday Service", "district": "ash_row", "chapter": 1,
		"brief": "Sunday heard something about Chidi. He'll only say it in the chair.",
		"objectives": [
			{"type": "reach", "target": "sunday_barber", "text": "Go to Sunday's Barbershop"},
			{"type": "talk", "target": "sunday", "text": "Sit in the chair"},
		],
		"reward": {"money": 300, "xp": 80, "trust": {"family": 5}},
		"sets": ["sunday_done"], "unlocks": [],
	},
	"night_shift": {
		"title": "Night Shift", "district": "cinder_line", "chapter": 2,
		"brief": "Oz will talk, but only where nobody can hear him over the rail.",
		"objectives": [
			{"type": "reach", "target": "rail_platform", "text": "Meet Oz at the rail platform"},
			{"type": "talk", "target": "osaze", "text": "Talk to Oz"},
			{"type": "escape", "text": "Leave before the patrol circles back"},
		],
		"reward": {"money": 700, "xp": 150, "trust": {"crew": 5}},
		"sets": ["night_shift_done"], "unlocks": [],
	},
}

const SIDE_JOBS := {
	"gutter_tavern": {
		"name": "Tavern Trouble", "district": "guttermarket", "vendor": "eze",
		"brief": "Someone's shaking down Eze's stalls. He'd like it to stop.",
		"objectives": [
			{"type": "reach", "target": "stall_row", "text": "Get to the stall row"},
			{"type": "fight", "target": "thugs", "count": 3, "text": "Clear the shakedown crew"},
		],
		"reward": {"money": 480, "xp": 90, "discipline": "kickboxing"},
		"repeatable": true,
	},
	"mile_delivery": {
		"name": "Mile Delivery", "district": "neon_mile", "vendor": "bimpe",
		"brief": "A package needs to cross the city without being looked at.",
		"objectives": [
			{"type": "reach", "target": "velvet_room", "text": "Collect the package"},
			{"type": "drive", "text": "Deliver it to Iron Yard"},
		],
		"reward": {"money": 900, "xp": 140},
		"repeatable": true,
	},
	"yard_clear": {
		"name": "Yard Clear", "district": "iron_yard", "vendor": "tunde",
		"brief": "Tunde's lift is blocked. The blockers are people.",
		"objectives": [
			{"type": "reach", "target": "garage", "text": "Reach the garage"},
			{"type": "fight", "target": "thugs", "count": 2, "text": "Remove the blockage"},
			{"type": "drive", "text": "Test the car you just earned"},
		],
		"reward": {"money": 1200, "xp": 180, "discipline": "grappling"},
		"repeatable": true,
	},
}

# ============================================================ SHOPS
const SHOP_ITEMS := {
	"food": {"title": "Food & Drink", "items": [
		{"id": "jollof", "name": "Jollof Plate", "price": 8, "effect": "heal:35", "desc": "Ngozi's. Restores health."},
		{"id": "suya", "name": "Suya Wrap", "price": 12, "effect": "heal:50", "desc": "Restores more health."},
		{"id": "water", "name": "Bottled Water", "price": 3, "effect": "heal:12", "desc": "Cheap, quick."},
	]},
	"drinks": {"title": "Bar", "items": [
		{"id": "beer", "name": "Cold Beer", "price": 10, "effect": "drunk:1", "desc": "Drunken stance sharpens."},
		{"id": "palm_wine", "name": "Palm Wine", "price": 16, "effect": "drunk:2", "desc": "Stronger sway, cheaper dodges."},
	]},
	"weapons": {"title": "Eze's Counter", "items": [
		{"id": "pipe", "name": "Steel Pipe", "price": 90, "effect": "weapon:pipe", "desc": "Reachable, heavy enough."},
		{"id": "baton", "name": "Collapsible Baton", "price": 210, "effect": "weapon:baton", "desc": "Fast, discreet."},
		{"id": "machete", "name": "Machete", "price": 340, "effect": "weapon:machete", "desc": "Serious damage."},
		{"id": "pistol", "name": "Locally Made Pistol", "price": 900, "effect": "weapon:pistol", "desc": "Loud. Effective."},
		{"id": "smg", "name": "Compact SMG", "price": 2400, "effect": "weapon:smg", "desc": "Suppression."},
		{"id": "shotgun", "name": "Sawed-Off", "price": 3100, "effect": "weapon:shotgun", "desc": "Closes arguments."},
		{"id": "vt_vest", "name": "Ballistic Vest", "price": 420, "effect": "armor:vest", "desc": "-30% damage taken."},
		{"id": "rt_plate", "name": "Riot Plate", "price": 1100, "effect": "armor:riot", "desc": "-48% damage, slower."},
		{"id": "ammo_pistol", "name": "Pistol Ammo x24", "price": 60, "effect": "ammo:pistol:24", "desc": "Restock."},
		{"id": "ammo_smg", "name": "SMG Ammo x50", "price": 140, "effect": "ammo:smg:50", "desc": "Restock."},
	]},
	"general": {"title": "Market Stalls", "items": [
		{"id": "padded", "name": "Padded Jacket", "price": 220, "effect": "armor:padded", "desc": "-15% damage."},
		{"id": "phone_credit", "name": "Phone Credit", "price": 20, "effect": "credit:1", "desc": "Unlocks radio requests."},
		{"id": "fragment_hint", "name": "Collector's Tip", "price": 150, "effect": "hint:1", "desc": "Marks a fragment on the map."},
	]},
	"server_wheel": {"title": "Clothing", "items": [
		{"id": "fit_barber", "name": "Fresh Fade", "price": 40, "effect": "cosmetic:barber", "desc": "Look sharp, lose heat."},
		{"id": "fit_street", "name": "Street Fit", "price": 260, "effect": "cosmetic:street", "desc": "Blend into Ash Row."},
	]},
	"vehicles": {"title": "Tunde's Lot", "items": [
		{"id": "bike", "name": "Street Motorcycle", "price": 6800, "effect": "vehicle:bike", "desc": "Fastest way through traffic."},
		{"id": "muscle", "name": "Muscle Coupe", "price": 14000, "effect": "vehicle:muscle", "desc": "Loud, fast, expensive."},
	]},
}

# ============================================================ RADIO
const RADIO := {
	"stations": [
		{"id": "city", "name": "93.7 Cinder FM", "desc": "Talk, traffic, and the occasional body count."},
		{"id": "mile", "name": "Neon Mile Radio", "desc": "Bass you can feel through the seat."},
		{"id": "none", "name": "Radio Off", "desc": "Silence is also a choice."},
	],
	"reports": [
		{"id": "r1", "title": "Meridian denies container find", "text": "Meridian Group has denied any knowledge of the container found unmanifested at Iron Yard on Tuesday."},
		{"id": "r2", "title": "Body found near rail platform", "text": "Police have confirmed a body found near the Cinder Line rail platform. They are not releasing a name."},
		{"id": "r3", "title": "Guttermarket fire ruled accidental", "text": "The fire that destroyed eleven stalls in Guttermarket has been ruled accidental. Traders are disputing it."},
		{"id": "r4", "title": "Obi file reassigned", "text": "The missing persons file for Chidi Obi has been reassigned to Detective Ibrahim after three months unassigned."},
		{"id": "r5", "title": "Heatwave warning", "text": "Temperatures expected to reach 34 degrees through the weekend. Residents are advised to stay indoors."},
		{"id": "r6", "title": "Mile shooting: no arrests", "text": "Police say no arrests have been made in relation to the shooting outside the Velvet Room last Friday."},
		{"id": "r7", "title": "Meridian stock slides", "text": "Meridian shares fell 4.1 percent after the Chronicle published details of an internal audit memo."},
		{"id": "r8", "title": "Foundry to cut shifts", "text": "The Cinder Line foundry will cut overnight shifts from next month, citing demand."},
	],
}

# Flat index of reports by id (kept alongside `reports` for callers that iterate).
# See RADIO.reports for the ordered list.

# ============================================================ ACHIEVEMENTS
const ACHIEVEMENTS := {
	"first_blood": {"name": "First Blood", "desc": "Win your first street fight.", "xp": 50},
	"homecoming": {"name": "Homecoming", "desc": "Complete chapter one.", "xp": 100},
	"fragment_1": {"name": "Paper Trail", "desc": "Find your first ledger fragment.", "xp": 40},
	"fragment_all": {"name": "The Whole Story", "desc": "Collect all 12 fragments.", "xp": 300},
	"stylist": {"name": "Stylist", "desc": "Unlock all five combat disciplines.", "xp": 250},
	"wanted_max": {"name": "Public Enemy", "desc": "Reach wanted level 4.", "xp": 200},
	"shopper": {"name": "Local Economy", "desc": "Spend ₦5,000 in shops.", "xp": 100},
	"driver": {"name": "Wheelman", "desc": "Drive 5,000 m.", "xp": 120},
}

# ============================================================ HELPERS
func district_center(id: String) -> Vector3:
	var g: Array = DISTRICTS[id]["grid"]
	return Vector3((float(g[0]) - 1.0) * 160.0, 0.0, (float(g[1]) - 0.5) * 160.0)

func district_name(id: String) -> String:
	return DISTRICTS.get(id, {}).get("name", id.capitalize())

func mission_order() -> Array:
	var out := []
	for id in MISSIONS: out.append(id)
	out.sort_custom(func(a, b): return MISSIONS[a]["chapter"] < MISSIONS[b]["chapter"])
	return out

func character_name(id: String) -> String:
	return CHARACTERS.get(id, {}).get("name", id.capitalize())

func ped_worst_model(role: String) -> String:
	var p: Dictionary = PEDESTRIANS.get(role, PEDESTRIANS["neighbour"])
	return p["models"][0]
