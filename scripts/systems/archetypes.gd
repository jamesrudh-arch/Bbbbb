extends Node
## ENEMY ARCHETYPES — 24 archetypes x 6 skill tiers.
##
## Design rule from the freeze (docs/22): difficulty changes BEHAVIOUR, never
## health bars. So a tier-6 enforcer is not a tier-1 enforcer with more HP —
## it reacts faster, blocks more, feints, and coordinates. Health barely moves.
##
## Every field here is read by enemy_ai.gd. Nothing in this file is decorative:
## if a value is here, some behaviour consumes it.

const TIER_NAMES := [
	"Raw",        # 1 - never fought anyone who fought back
	"Crew",       # 2 - has been in scraps
	"Enforcer",   # 3 - professional
	"Veteran",    # 4 - reads you
	"Champion",   # 5 - punishes mistakes
	"Legend",     # 6 - no wasted motion
]

## How a tier changes behaviour. Multiplicative, applied by make().
const TIER_MOD := [
	# tier: reaction, block, dodge, feint, aggression, combo, accuracy, coord
	{"reaction": 1.55, "block": 0.05, "dodge": 0.02, "feint": 0.00, "aggression": 0.85, "combo": 0.70, "accuracy": 0.70, "coord": 0.20},
	{"reaction": 1.30, "block": 0.15, "dodge": 0.06, "feint": 0.05, "aggression": 1.00, "combo": 0.85, "accuracy": 0.80, "coord": 0.35},
	{"reaction": 1.10, "block": 0.28, "dodge": 0.12, "feint": 0.12, "aggression": 1.10, "combo": 1.00, "accuracy": 0.88, "coord": 0.55},
	{"reaction": 0.92, "block": 0.40, "dodge": 0.20, "feint": 0.22, "aggression": 1.15, "combo": 1.15, "accuracy": 0.93, "coord": 0.70},
	{"reaction": 0.78, "block": 0.52, "dodge": 0.28, "feint": 0.32, "aggression": 1.25, "combo": 1.30, "accuracy": 0.97, "coord": 0.85},
	{"reaction": 0.66, "block": 0.62, "dodge": 0.35, "feint": 0.42, "aggression": 1.35, "combo": 1.45, "accuracy": 1.00, "coord": 1.00},
]

## The 24. `style` drives which animation set and spacing the AI uses:
##   brawler  - closes to fist range, chains, blocks
##   grappler - wants very close, heavy, slow windup, high damage
##   blade    - fast, mobile, strikes and resets
##   gunner   - holds distance, seeks cover, bursts
##   shotgun  - rushes to short range, huge burst, long recover
##   shield   - advances behind cover, low damage, very high block
##   thrower  - keeps distance, lobs, retreats
##   assassin - flanks, ambushes, disengages when hurt
const ARCHETYPES := {
	# ---------------------------------------------------------- street tier
	"corner_lookout": {
		"name": "Lookout", "faction": "railhead", "style": "brawler",
		"health": 42.0, "damage": 4.5, "speed": 1.55, "range": 1.9,
		"calls_backup": true, "flees_below": 0.45,
		"notes": "Runs to raise the alarm. Killing him quietly prevents the wave.",
	},
	"street_thug": {
		"name": "Thug", "faction": "railhead", "style": "brawler",
		"health": 58.0, "damage": 6.5, "speed": 1.30, "range": 2.0,
	},
	"bottle_thug": {
		"name": "Bottle Hand", "faction": "railhead", "style": "thrower",
		"health": 50.0, "damage": 7.5, "speed": 1.35, "range": 9.0,
		"keeps_distance": 7.0, "telegraph": 0.62,
	},
	"knife_runner": {
		"name": "Runner", "faction": "railhead", "style": "blade",
		"health": 46.0, "damage": 8.0, "speed": 1.85, "range": 1.6,
		"combo_max": 3, "telegraph": 0.34,
	},
	"razor_kid": {
		"name": "Razor Kid", "faction": "railhead", "style": "blade",
		"health": 40.0, "damage": 6.0, "speed": 2.05, "range": 1.5,
		"dodge_bonus": 0.20, "combo_max": 4, "telegraph": 0.28,
	},
	"crew_soldier": {
		"name": "Crew Soldier", "faction": "railhead", "style": "brawler",
		"health": 74.0, "damage": 8.0, "speed": 1.42, "range": 2.1,
		"combo_max": 3,
	},
	"debt_collector": {
		"name": "Collector", "faction": "railhead", "style": "brawler",
		"health": 82.0, "damage": 9.0, "speed": 1.28, "range": 2.2,
		"combo_max": 3, "punishes_heal": true,
	},
	"enforcer": {
		"name": "Enforcer", "faction": "railhead", "style": "grappler",
		"health": 115.0, "damage": 13.0, "speed": 1.05, "range": 2.4,
		"telegraph": 0.82, "unblockable": true, "armor": 0.25,
	},
	"dock_hauler": {
		"name": "Hauler", "faction": "railhead", "style": "grappler",
		"health": 140.0, "damage": 16.0, "speed": 0.92, "range": 2.6,
		"telegraph": 0.95, "unblockable": true,
	},
	"chemist": {
		"name": "Chemist", "faction": "railhead", "style": "thrower",
		"health": 52.0, "damage": 5.0, "speed": 1.25, "range": 10.0,
		"keeps_distance": 8.5, "area_denial": true, "telegraph": 0.75,
	},
	"molotov": {
		"name": "Firestarter", "faction": "railhead", "style": "thrower",
		"health": 55.0, "damage": 11.0, "speed": 1.30, "range": 11.0,
		"keeps_distance": 9.0, "telegraph": 0.9,
	},
	# ------------------------------------------------------- ring tier
	"ring_fighter": {
		"name": "Ring Fighter", "faction": "ring", "style": "brawler",
		"health": 90.0, "damage": 10.0, "speed": 1.50, "range": 2.1,
		"combo_max": 4, "feints": true,
		"notes": "Fights on rhythm. Punishes panic-mashing.",
	},
	"ring_champion": {
		"name": "Champion", "faction": "ring", "style": "brawler",
		"health": 130.0, "damage": 12.0, "speed": 1.62, "range": 2.2,
		"combo_max": 5, "feints": true, "armor": 0.15,
		"notes": "Bout climax. Reads your dodge timing.",
	},
	"assassin": {
		"name": "Cleaner", "faction": "ring", "style": "assassin",
		"health": 62.0, "damage": 18.0, "speed": 1.95, "range": 1.7,
		"backstab": 2.2, "flees_below": 0.30, "telegraph": 0.30,
	},
	"fixer_bodyguard": {
		"name": "Bodyguard", "faction": "ring", "style": "shield",
		"health": 125.0, "damage": 9.0, "speed": 1.30, "range": 2.0,
		"protects": true, "block_bonus": 0.25,
	},
	# ---------------------------------------------------------- corporate
	"corporate_sec": {
		"name": "Corporate Security", "faction": "corporation", "style": "gunner",
		"health": 85.0, "damage": 9.0, "speed": 1.40, "range": 16.0,
		"keeps_distance": 12.0, "uses_cover": true, "telegraph": 0.5,
	},
	"armored_guard": {
		"name": "Armored Guard", "faction": "corporation", "style": "gunner",
		"health": 150.0, "damage": 7.0, "speed": 0.95, "range": 14.0,
		"armor": 0.45, "uses_cover": true, "telegraph": 0.6,
	},
	"riot_shield": {
		"name": "Riot Shield", "faction": "corporation", "style": "shield",
		"health": 165.0, "damage": 8.0, "speed": 1.05, "range": 2.0,
		"block_bonus": 0.45, "armor": 0.20,
		"notes": "Cannot be punched through the front. Get behind him.",
	},
	"shotgun_breacher": {
		"name": "Breacher", "faction": "corporation", "style": "shotgun",
		"health": 95.0, "damage": 22.0, "speed": 1.55, "range": 4.5,
		"telegraph": 0.7, "recover": 1.4,
	},
	"smg_driver": {
		"name": "Suppressor", "faction": "corporation", "style": "gunner",
		"health": 78.0, "damage": 5.5, "speed": 1.50, "range": 15.0,
		"keeps_distance": 11.0, "burst": 5, "uses_cover": true,
	},
	"sniper_roof": {
		"name": "Rooftop Shooter", "faction": "corporation", "style": "gunner",
		"health": 60.0, "damage": 26.0, "speed": 1.10, "range": 45.0,
		"keeps_distance": 30.0, "telegraph": 1.4, "relocates": true,
	},
	"bomb_tech": {
		"name": "Tech", "faction": "corporation", "style": "thrower",
		"health": 70.0, "damage": 14.0, "speed": 1.35, "range": 12.0,
		"keeps_distance": 9.0, "area_denial": true, "telegraph": 1.0,
	},
	# ------------------------------------------------------------- special
	"lieutenant": {
		"name": "Lieutenant", "faction": "railhead", "style": "brawler",
		"health": 220.0, "damage": 15.0, "speed": 1.40, "range": 2.4,
		"combo_max": 5, "feints": true, "armor": 0.30, "calls_backup": true,
		"is_boss": true,
	},
	"boss_ring": {
		"name": "Ring Champion", "faction": "ring", "style": "brawler",
		"health": 300.0, "damage": 17.0, "speed": 1.55, "range": 2.5,
		"combo_max": 6, "feints": true, "armor": 0.25, "is_boss": true,
		"phases": [1.0, 0.6, 0.3],
		"notes": "Three phases; each phase changes behaviour, not health.",
	},
	"boss_corporate": {
		"name": "Director", "faction": "corporation", "style": "gunner",
		"health": 340.0, "damage": 14.0, "speed": 1.45, "range": 18.0,
		"keeps_distance": 13.0, "uses_cover": true, "armor": 0.35, "is_boss": true,
		"phases": [1.0, 0.65, 0.35],
	},
}

const DEFAULT := {
	"name": "Thug", "faction": "railhead", "style": "brawler",
	"health": 60.0, "damage": 6.5, "speed": 1.3, "range": 2.0,
}

func get_archetype(id: String) -> Dictionary:
	return ARCHETYPES.get(id, DEFAULT)

func has_archetype(id: String) -> bool:
	return ARCHETYPES.has(id)

func all_ids() -> Array:
	return ARCHETYPES.keys()

func ids_for_faction(faction: String) -> Array:
	var out := []
	for k in ARCHETYPES:
		if ARCHETYPES[k]["faction"] == faction:
			out.append(k)
	return out

## Build a concrete fighter from archetype + tier (1..6).
## Health moves only slightly with tier: the difficulty lives in behaviour.
func make(id: String, tier: int = 1) -> Dictionary:
	var a: Dictionary = get_archetype(id).duplicate(true)
	tier = clampi(tier, 1, 6)
	var m: Dictionary = TIER_MOD[tier - 1]

	a["id"] = id
	a["tier"] = tier
	a["tier_name"] = TIER_NAMES[tier - 1]

	# Behaviour axes — this is where the difficulty actually comes from.
	a["reaction"] = float(a.get("telegraph", 0.55)) * float(m["reaction"])
	a["block_chance"] = clampf(float(a.get("block_bonus", 0.0)) + float(m["block"]), 0.0, 0.92)
	a["dodge_chance"] = clampf(float(a.get("dodge_bonus", 0.0)) + float(m["dodge"]), 0.0, 0.80)
	a["feint_chance"] = clampf(float(m["feint"]), 0.0, 0.75)
	a["aggression"] = float(m["aggression"])
	a["combo_max"] = maxi(1, int(round(float(a.get("combo_max", 2)) * float(m["combo"]))))
	a["accuracy"] = float(m["accuracy"])
	a["coordination"] = float(m["coord"])

	# Health: only +18% across the whole tier range. No bullet sponges.
	a["health"] = float(a.get("health", 60.0)) * (1.0 + 0.03 * float(tier - 1))
	a["damage"] = float(a.get("damage", 6.5)) * (1.0 + 0.05 * float(tier - 1))
	return a

## A crew suited to a district tier (1..6). Used by spawners and street events.
func roster_for(district_tier: int, count: int, faction: String = "railhead") -> Array:
	var pool := ids_for_faction(faction)
	if pool.is_empty():
		pool = all_ids()
	var out := []
	for i in count:
		var id: String = str(pool[randi() % pool.size()])
		# District tier sets the floor; one in five is a tier above.
		var t := district_tier
		if randf() < 0.2:
			t = mini(6, t + 1)
		out.append(make(id, t))
	return out
