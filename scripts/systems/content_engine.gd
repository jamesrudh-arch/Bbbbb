extends Node
## CONTENT ENGINE — generates the repeatable layer of Cinder City.
##
## Hand-writing 72 contracts, 28 bounties and 36 street events as literal data
## would be 136 near-identical dicts that no one could balance. Instead these are
## generated from templates that carry the design intent, then seeded so a given
## save always sees the same jobs in the same places.
##
## What makes a generated job feel authored:
##   1. Every template names a real landmark in a real district.
##   2. The target is a real named character or a real archetype from
##      archetypes.gd, so the enemy you fight matches the flavour text.
##   3. Difficulty comes from the district tier, which already exists.
##   4. Payment scales with distance, risk and the faction you are helping.
##
## Deterministic: same save seed + same job index = same job, always. This is
## what stops a contract board re-rolling until the player finds an easy one.

const CONTRACT_TARGET := 72
const BOUNTY_TARGET := 28
const EVENT_TARGET := 36

## Contract templates. Each produces one job per eligible district.
const CONTRACT_KINDS := {
	"shakedown": {
		"verb": "Collect from",
		"objective": "intimidate",
		"flavour": "They owe. You're the reason they remember.",
		"pay": [280, 620], "risk": 1, "archetype": "street_thug",
	},
	"escort": {
		"verb": "Escort",
		"objective": "escort",
		"flavour": "Keep them breathing until the handover.",
		"pay": [340, 700], "risk": 2, "archetype": "knife_runner",
	},
	"retrieve": {
		"verb": "Recover",
		"objective": "collect",
		"flavour": "It was never theirs. Bring it back.",
		"pay": [260, 540], "risk": 1, "archetype": "crew_soldier",
	},
	"clear": {
		"verb": "Clear out",
		"objective": "fight",
		"flavour": "The room needs to be empty by morning.",
		"pay": [420, 880], "risk": 3, "archetype": "enforcer",
	},
	"tail": {
		"verb": "Follow",
		"objective": "tail",
		"flavour": "Don't be seen. Learn the route.",
		"pay": [300, 560], "risk": 2, "archetype": "corporate_sec",
	},
	"deliver": {
		"verb": "Deliver to",
		"objective": "deliver",
		"flavour": "No names. No questions. No stops.",
		"pay": [240, 480], "risk": 2, "archetype": "razor_kid",
	},
	"defend": {
		"verb": "Hold",
		"objective": "defend",
		"flavour": "They're coming back for it. Be there.",
		"pay": [460, 900], "risk": 4, "archetype": "dock_hauler",
	},
}

## Bounty targets. Named individuals with a face, a reason and a tier.
const BOUNTY_GIVEN_NAMES := [
	"Ade Bankole", "Femi Ojo", "Ruth Onu", "Segun Ayo", "Ifeoma Nwosu",
	"Dele Balogun", "Hauwa Sani", "Emeka Obi", "Tolu Ajayi", "Nkechi Eze",
	"Yusuf Bello", "Chiamaka Duru", "Bode Ogundipe", "Zainab Lawal",
	"Obinna Uche", "Funke Adebayo", "Musa Danjuma", "Ada Okonkwo",
	"Kayode Salami", "Amina Yusuf", "Chidi Nnamdi", "Bisi Alade",
	"Tunde Bakare", "Halima Bello", "Nnamdi Okafor", "Sade Williams",
	"Emeka Nwankwo", "Grace Adeleke",
]

const BOUNTY_CHARGES := [
	"skipped bail on a firearms charge",
	"testified against the wrong people",
	"ran a protection racket on three blocks",
	"dropped a witness in broad daylight",
	"owes Meridian and everyone knows it",
	"kept a ledger that was not theirs",
	"put a hole in a Dockside container",
	"walked out of a deal with the Mile's money",
]

## Street events. These fire in the world without the player accepting anything.
const EVENT_KINDS := {
	"mugging":   {"weight": 3, "text": "Someone's being robbed", "archetype": "razor_kid"},
	"chase":     {"weight": 2, "text": "A runner's bolting", "archetype": "knife_runner"},
	"deal":      {"weight": 2, "text": "A handoff is happening", "archetype": "crew_soldier"},
	"shakedown": {"weight": 2, "text": "Someone's being shaken down", "archetype": "street_thug"},
	"accident":  {"weight": 1, "text": "Someone's down in the street", "archetype": ""},
	"raid":      {"weight": 1, "text": "Meridian's clearing a block", "archetype": "corporate_sec"},
	"race":      {"weight": 1, "text": "Street race starting", "archetype": ""},
	"fire":      {"weight": 1, "text": "Something's burning", "archetype": ""},
}

var world: Node3D = null
var _contracts: Array = []
var _bounties: Array = []
var _events: Array = []
var _generated := false

func setup(w: Node3D) -> void:
	world = w
	generate()

func generate(seed_value: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	# Seeded from the save so the same playthrough sees the same board.
	rng.seed = seed_value if seed_value != 0 else hash(str(Game.completed_missions.size()) + ":" + str(Game.xp))
	_contracts = _gen_contracts(rng)
	_bounties = _gen_bounties(rng)
	_events = _gen_events(rng)
	_generated = true

func contracts() -> Array: return _contracts
func bounties() -> Array: return _bounties
func events() -> Array: return _events
func is_generated() -> bool: return _generated

# --------------------------------------------------------------- contracts
func _gen_contracts(rng: RandomNumberGenerator) -> Array:
	var out := []
	var kinds: Array = CONTRACT_KINDS.keys()
	var districts: Array = Content.DISTRICTS.keys()

	# Guarantee coverage: every district gets at least one of each kind that fits
	# its tier, so no district feels empty of work.
	var i := 0
	var used_titles := {}
	for district in districts:
		var d: Dictionary = Content.DISTRICTS[district]
		var tier: int = int(d.get("tier", 1))
		var lm_pool: Array = d.get("landmarks", []).duplicate()
		lm_pool.shuffle()
		var lm_idx := 0
		for kind in kinds:
			if out.size() >= CONTRACT_TARGET:
				break
			var k: Dictionary = CONTRACT_KINDS[kind]
			# High-risk work does not appear in tier 1 districts.
			if int(k["risk"]) > tier + 1:
				continue
			var lm: Array = d.get("landmarks", [])
			if lm.is_empty():
				continue
			# Cycle named sub-locations rather than sampling the three authored
			# landmarks with replacement, so the board reads like a city.
			var places := _places_for(district)
			var place := str(places[lm_idx % places.size()])
			lm_idx += 1
			var pay_lo: int = int(k["pay"][0])
			var pay_hi: int = int(k["pay"][1])
			var pay := int(round(lerpf(float(pay_lo), float(pay_hi), float(tier) / 6.0)))
			pay = int(pay * rng.randf_range(0.9, 1.1))
			var title := "%s %s" % [k["verb"], place]
			# Disambiguate collisions with a district qualifier rather than
			# showing the same job twice on the board.
			if used_titles.has(title):
				title = "%s %s (%s)" % [k["verb"], place, district.replace("_", " ").capitalize()]
			used_titles[title] = true
			out.append({
				"id": "contract_%02d" % i,
				"kind": kind,
				"title": title,
				"district": district,
				"tier": tier,
				"place": place,
				"objective": k["objective"],
				"flavour": k["flavour"],
				"archetype": k["archetype"],
				"reward": {"money": pay, "xp": 40 + tier * 18},
				"repeatable": true,
			})
			i += 1
	# Fill any shortfall by recycling the existing pool round-robin, so the extra
	# work stays spread across every district instead of cloning whichever
	# district happened to sort first.
	var template_pool := out.duplicate(true)
	var fill_i := 0
	while out.size() < CONTRACT_TARGET and not template_pool.is_empty():
		var base: Dictionary = template_pool[fill_i % template_pool.size()].duplicate(true)
		fill_i += 1
		base["id"] = "contract_%02d" % out.size()
		base["reward"] = {
			"money": int(round(float(base["reward"]["money"]) * 1.15)),
			"xp": int(base["reward"]["xp"]) + 10,
		}
		var t2 := str(base["title"])
		if used_titles.has(t2):
			t2 = "%s II" % t2
		used_titles[t2] = true
		base["title"] = t2
		out.append(base)
	return out.slice(0, CONTRACT_TARGET)

## Districts expose only three authored landmarks each, so generated jobs all
## collided on the same handful of names. These street-level sub-locations give
## the board places that read like a city while leaving the authored landmarks
## intact for missions and navigation.
const SUBLOCATIONS := {
	"ash_row": ["Block 14 Stairwell", "Back Door", "Barbershop Chair", "Underpass", "Kerosene Alley", "Laundry Roof"],
	"guttermarket": ["Stall Row", "Cold Room", "Pawn Counter", "Gutter Steps", "The Awnings", "Back Gate"],
	"iron_yard": ["Garage Bay 3", "Weigh Station", "Crane Four", "Scrap Meadow", "Cutting Shed", "Container Row"],
	"railhead": ["Foundry Floor", "Rail Platform B", "Slag Pit", "Switch House", "Loading Dock", "Signal Hut"],
	"vesper_heights": ["Tower Lobby", "Club Bar", "Helipad", "Service Elevator", "The Terrace", "Sub-level Archive"],
	"dockside": ["Crane Yard", "Fish Market", "Warehouse Nine", "Pier Four", "Net Lofts", "Customs Shed"],
	"neon_mile": ["Velvet Room", "Chop House", "Arcade Mezzanine", "Backstage", "The Marquee", "Alley Bar"],
}

func _places_for(district: String) -> Array:
	var out: Array = []
	out.append_array(SUBLOCATIONS.get(district, []))
	for lm in Content.DISTRICTS.get(district, {}).get("landmarks", []):
		out.append(_title_from(str(lm)))
	return out

func _title_from(place: String) -> String:
	return place.replace("_", " ").capitalize()

# ---------------------------------------------------------------- bounties
func _gen_bounties(rng: RandomNumberGenerator) -> Array:
	var out := []
	var arch_ids: Array = Archetypes.all_ids()
	var districts: Array = Content.DISTRICTS.keys()
	for i in mini(BOUNTY_TARGET, BOUNTY_GIVEN_NAMES.size()):
		var district := str(districts[i % districts.size()])
		var tier: int = mini(6, int(Content.DISTRICTS[district].get("tier", 1)) + 1)
		# Bounty targets escalate: later bounties are tougher.
		tier = clampi(tier + i / 9, 1, 6)
		var arch := ""
		# Prefer a combat archetype that matches the district's faction.
		var pool: Array = Archetypes.ids_for_faction(str(Content.DISTRICTS[district].get("faction", "family")))
		if pool.is_empty():
			pool = arch_ids
		arch = str(pool[rng.randi() % pool.size()])
		var pay := int(600 + tier * 340 + rng.randf_range(0.0, 260.0))
		out.append({
			"id": "bounty_%02d" % i,
			"name": BOUNTY_GIVEN_NAMES[i],
			"district": district,
			"tier": tier,
			"archetype": arch,
			"charge": BOUNTY_CHARGES[i % BOUNTY_CHARGES.size()],
			"title": "Bounty: %s" % BOUNTY_GIVEN_NAMES[i],
			"reward": {"money": pay, "xp": 90 + tier * 30},
			"alive_required": i % 4 == 0,   # one in four is a capture, not a kill
		})
	return out

# ------------------------------------------------------------------ events
func _gen_events(rng: RandomNumberGenerator) -> Array:
	var out := []
	var kinds: Array = []
	for k in EVENT_KINDS:
		for n in int(EVENT_KINDS[k]["weight"]):
			kinds.append(k)
	var districts: Array = Content.DISTRICTS.keys()
	for i in EVENT_TARGET:
		var kind := str(kinds[rng.randi() % kinds.size()])
		var district := str(districts[i % districts.size()])
		var d: Dictionary = Content.DISTRICTS[district]
		var lm: Array = d.get("landmarks", [])
		var place := str(lm[rng.randi() % lm.size()]) if not lm.is_empty() else district
		out.append({
			"id": "event_%02d" % i,
			"kind": kind,
			"district": district,
			"place": place,
			"text": str(EVENT_KINDS[kind]["text"]),
			"archetype": str(EVENT_KINDS[kind]["archetype"]),
			"cooldown": 120.0 + rng.randf_range(0.0, 90.0),
		})
	return out

## Pick the next street event that fits where the player is and what they can
## handle. Returns {} when nothing fits this moment.
func pick_event(district: String, player_tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var candidates := []
	for e in _events:
		if str(e["district"]) != district:
			continue
		var et: int = int(Content.DISTRICTS.get(district, {}).get("tier", 1))
		# Never throw a tier-6 event at a tier-1 player.
		if et > player_tier + 1:
			continue
		candidates.append(e)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi() % candidates.size()]

## Contracts available in a district, cheapest first — a readable board.
func contracts_in(district: String) -> Array:
	var out := []
	for c in _contracts:
		if str(c["district"]) == district:
			out.append(c)
	out.sort_custom(func(a, b): return int(a["reward"]["money"]) < int(b["reward"]["money"]))
	return out

func bounties_in(district: String) -> Array:
	var out := []
	for b in _bounties:
		if str(b["district"]) == district:
			out.append(b)
	return out
