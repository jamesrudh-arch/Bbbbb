extends Node
## GAME — authoritative runtime state + persistence + progression.
## Everything a save slot needs is serialised here. Systems read and write this
## autoload; nothing else owns player state.

signal player_died
signal player_damaged(amount: float, health: float)
signal heat_changed(heat: float)
signal wanted_changed(level: int)
signal money_changed(money: int, delta: int)
signal xp_changed(xp: int, level: int)
signal discipline_changed(id: String)
signal mission_started(id: String)
signal mission_completed(id: String)
signal mission_objective_changed(index: int, objective: Dictionary)
signal inventory_changed
signal trust_changed(faction: String, value: int)
signal notified(title: String, body: String, kind: String)

const SLOT_COUNT := 3
const SAVE_DIR := "user://saves"

# ---------------- player ----------------
var player_health: float = 100.0
var player_max_health: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var money: int = 120
var xp: int = 0
var level: int = 1

# ---------------- world clock ----------------
var hour: float = 16.5
var day: int = 1
var weather: String = "clear"
var temperature: int = 18

# ---------------- position ----------------
var spawn_point: String = "apartment"
var current_district: String = "ash_row"

# ---------------- heat / wanted ----------------
var heat: float = 0.0
var wanted: int = 0

# ---------------- combat / gear ----------------
var ammo: Dictionary = {"pistol": 0, "smg": 0, "shotgun": 0}
var weapons: Array = ["fists"]
var armor: String = "none"
var owned_weapons: Array = ["fists"]
var owned_armor: Array = ["none"]
var equipped_weapon: String = "fists"
var equipped_armor: String = "none"
var active_discipline: String = "brawler"
var unlocked_disciplines: Array = ["brawler"]

# ---------------- social ----------------
var relationships: Dictionary = {}
var trust: Dictionary = {"family": 60, "corporation": 0, "crew": 20, "police": 10}
var drinks: int = 0

# ---------------- progress ----------------
var flags: Dictionary = {}
var collectibles: Array = []
var completed_missions: Array = []
var completed_jobs: Array = []
var reputation: Dictionary = {}
var achievements: Array = []
var stats: Dictionary = {"fights_won": 0, "fights_lost": 0, "distance_walked": 0.0,
	"distance_driven": 0.0, "money_earned": 0, "money_spent": 0, "missions_done": 0,
	"npcs_talked": 0, "vehicles_stolen": 0}
var play_time: float = 0.0
var save_loaded_from: int = -1
var radio_station: String = "city"
var known_radio: Array = ["r1", "r2", "r3"]

# ---------------- mission ----------------
var mission: Dictionary = {}

# --- phone state ---------------------------------------------------------
var call_log: Array = []        # [{from, id, answered, at}]
var missed_calls: Array = []    # [call_id]
var messages: Dictionary = {}   # cid -> [{text, read, at}]
var current_call := ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")

func _process(delta: float) -> void:
	play_time += delta
	# Heat decays slowly; wanted level follows heat thresholds.
	if heat > 0.0:
		heat = maxf(0.0, heat - delta * 0.35)
		heat_changed.emit(heat)
	var new_wanted := 0
	if heat >= 12.0: new_wanted = 1
	if heat >= 30.0: new_wanted = 2
	if heat >= 55.0: new_wanted = 3
	if heat >= 80.0: new_wanted = 4
	if new_wanted != wanted:
		wanted = new_wanted
		wanted_changed.emit(wanted)
		if wanted >= 4: unlock_achievement("wanted_max")

# =========================================================== money / xp
func add_money(delta: int) -> void:
	if delta == 0: return
	money = maxi(0, money + delta)
	if delta > 0:
		stats["money_earned"] = int(stats.get("money_earned", 0)) + delta
	else:
		stats["money_spent"] = int(stats.get("money_spent", 0)) + absi(delta)
		if int(stats["money_spent"]) >= 5000: unlock_achievement("shopper")
	money_changed.emit(money, delta)
	if delta > 0:
		notify("+₦%d" % delta, "", "money")

func spend(cost: int) -> bool:
	if money < cost: return false
	add_money(-cost)
	return true

func add_xp(amount: int) -> void:
	xp += amount
	var new_level := 1 + int(xp / 400)
	if new_level != level:
		level = new_level
		player_max_health = 100.0 + (level - 1) * 8.0
		notify("Level %d" % level, "Max health increased", "level")
	xp_changed.emit(xp, level)

# =========================================================== heat
func add_heat(amount: float) -> void:
	heat = clampf(heat + amount, 0.0, 100.0)
	heat_changed.emit(heat)

func clear_heat() -> void:
	heat = 0.0
	wanted = 0
	heat_changed.emit(heat)
	wanted_changed.emit(0)

# =========================================================== flags
## Record an incoming/outgoing message for a contact.
func push_message(cid: String, text: String) -> void:
	if not messages.has(cid):
		messages[cid] = []
	messages[cid].append({"text": text, "read": false, "at": hour})
	messages_updated.emit()

signal messages_updated

## Mark a thread read.
func read_messages(cid: String) -> void:
	if not messages.has(cid):
		return
	for m in messages[cid]:
		m["read"] = true
	messages_updated.emit()

func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value

func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))

# =========================================================== inventory
func buy_item(item: Dictionary) -> bool:
	var price := int(item.get("price", 0))
	if money < price:
		notify("Can't afford it", "You need ₦%d more" % (price - money), "error")
		return false
	var effect: String = item.get("effect", "")
	# Weapon / armour need to be purchasable even at 0 price.
	if effect.begins_with("heal:"):
		var amount := float(effect.split(":")[1])
		player_health = minf(player_max_health, player_health + amount)
		notify(item.get("name", "Food"), "+%d health" % int(amount), "heal")
	elif effect.begins_with("drunk:"):
		var n := int(effect.split(":")[1])
		drinks = clampi(drinks + n, 0, 3)
		notify("Drunken stance", "Sway %d/3" % drinks, "heal")
	elif effect.begins_with("weapon:"):
		var wid := effect.split(":")[1]
		if not owned_weapons.has(wid): owned_weapons.append(wid)
		equip_weapon(wid)
	elif effect.begins_with("armor:"):
		var aid := effect.split(":")[1]
		if not owned_armor.has(aid): owned_armor.append(aid)
		equip_armor(aid)
	elif effect.begins_with("ammo:"):
		var ps := effect.split(":")
		ammo[ps[1]] = int(ammo.get(ps[1], 0)) + int(ps[2])
		notify("Ammunition", "+%s rounds" % ps[2], "ammo")
	elif effect.begins_with("vehicle:"):
		var vid := effect.split(":")[1]
		set_flag("owns_vehicle_" + vid)
		notify("Vehicle owned", Content.VEHICLE_TYPES[vid]["name"], "level")
	elif effect.begins_with("credit:"):
		set_flag("phone_credit")
		notify("Phone credit", "Radio requests unlocked", "level")
	elif effect.begins_with("hint:"):
		set_flag("fragment_hint")
		notify("Tip received", "A fragment is marked on your map", "level")
	elif effect.begins_with("cosmetic:"):
		set_flag("cosmetic_" + effect.split(":")[1])
		add_heat(-8.0)
		notify("New look", "Heat reduced", "heal")
	add_money(-price)
	inventory_changed.emit()
	return true

func equip_weapon(wid: String) -> void:
	if not owned_weapons.has(wid): return
	equipped_weapon = wid
	if Content.WEAPONS.has(wid) and Content.WEAPONS[wid]["kind"] == "gun":
		if int(ammo.get(wid, 0)) == 0:
			ammo[wid] = int(Content.WEAPONS[wid]["reserve"])
	unlock_discipline("weapon")
	inventory_changed.emit()

func equip_armor(aid: String) -> void:
	if not owned_armor.has(aid): return
	equipped_armor = aid
	inventory_changed.emit()

func armor_protection() -> float:
	return float(Content.ARMOR.get(equipped_armor, {"protect": 0.0}).get("protect", 0.0))

func consume_ammo(wid: String, n: int = 1) -> bool:
	if int(ammo.get(wid, 0)) < n:
		notify("Out of ammo", "Reload or switch weapons", "error")
		return false
	ammo[wid] = int(ammo[wid]) - n
	inventory_changed.emit()
	return true

# =========================================================== disciplines
func unlock_discipline(id: String) -> void:
	if not Content.DISCIPLINES.has(id): return
	if unlocked_disciplines.has(id): return
	unlocked_disciplines.append(id)
	discipline_changed.emit(id)
	notify("Discipline unlocked", Content.DISCIPLINES[id]["name"], "level")
	if unlocked_disciplines.size() >= 5:
		unlock_achievement("stylist")

func set_discipline(id: String) -> void:
	if unlocked_disciplines.has(id):
		active_discipline = id
		discipline_changed.emit(id)

func discipline_stats() -> Dictionary:
	var d: Dictionary = Content.DISCIPLINES.get(active_discipline, Content.DISCIPLINES["brawler"])
	var armor_speed := float(Content.ARMOR.get(equipped_armor, {"speed": 1.0}).get("speed", 1.0))
	return {
		"reach": d["reach"], "damage": d["damage"], "speed": d["speed"] * armor_speed,
		"stamina": d["stamina"],
	}

# =========================================================== social
func relationship(cid: String) -> int:
	return int(relationships.get(cid, 0))

func add_relationship(cid: String, delta: int) -> void:
	relationships[cid] = clampi(relationship(cid) + delta, -100, 100)

func add_trust(faction: String, delta: int) -> void:
	if not trust.has(faction): trust[faction] = 0
	trust[faction] = clampi(int(trust[faction]) + delta, -100, 100)
	trust_changed.emit(faction, int(trust[faction]))

func faction_trust(faction: String) -> int:
	return int(trust.get(faction, 0))

# =========================================================== health
func damage(amount: float, _source: String = "") -> void:
	var mitigated := amount * (1.0 - armor_protection())
	player_health = maxf(0.0, player_health - mitigated)
	player_damaged.emit(mitigated, player_health)
	if player_health <= 0.0:
		_on_player_death()

func heal(amount: float) -> void:
	player_health = minf(player_max_health, player_health + amount)

func _on_player_death() -> void:
	stats["fights_lost"] = int(stats.get("fights_lost", 0)) + 1
	player_died.emit()

func respawn() -> void:
	player_health = player_max_health
	stamina = max_stamina
	heat = maxf(0.0, heat * 0.5)
	money = int(money * 0.9)
	player_died.emit()  # HUD + world listen and reposition

# =========================================================== notifications
func notify(title: String, body: String = "", kind: String = "info") -> void:
	notified.emit(title, body, kind)

# =========================================================== achievements
func unlock_achievement(id: String) -> void:
	if achievements.has(id): return
	if not Content.ACHIEVEMENTS.has(id): return
	achievements.append(id)
	var a: Dictionary = Content.ACHIEVEMENTS[id]
	add_xp(int(a["xp"]))
	notify("Achievement", a["name"], "achievement")

# =========================================================== missions
func start_mission(id: String, mission_data: Dictionary = {}) -> void:
	var data: Dictionary = mission_data if not mission_data.is_empty() else Content.MISSIONS.get(id, {})
	if data.is_empty(): return
	mission = {
		"id": id, "data": data, "index": 0, "progress": 0,
		"title": data.get("title", id), "started_at": play_time,
	}
	mission_started.emit(id)
	var objs: Array = data.get("objectives", [])
	if not objs.is_empty():
		mission_objective_changed.emit(0, objs[0])

func start_mission_from_job(job_id: String, job: Dictionary) -> void:
	var data := {
		"title": job.get("name", job_id), "district": job.get("district", "ash_row"),
		"objectives": job.get("objectives", []), "reward": job.get("reward", {}),
		"job_id": job_id,
	}
	mission = {"id": "job_" + job_id, "data": data, "index": 0, "progress": 0,
		"title": data["title"], "job": job_id, "started_at": play_time}
	mission_started.emit(mission["id"])
	var objs: Array = data.get("objectives", [])
	if not objs.is_empty():
		mission_objective_changed.emit(0, objs[0])

func current_objective() -> Dictionary:
	if mission.is_empty(): return {}
	var objs: Array = mission["data"].get("objectives", [])
	var i := int(mission.get("index", 0))
	return objs[i] if i < objs.size() else {}

func objective_index() -> int:
	return int(mission.get("index", 0))

func add_mission_progress(n: int = 1) -> void:
	if mission.is_empty(): return
	var obj := current_objective()
	if obj.is_empty(): return
	mission["progress"] = int(mission.get("progress", 0)) + n
	var need := int(obj.get("count", 1))
	if int(mission["progress"]) >= need:
		advance_mission()

func advance_mission() -> void:
	if mission.is_empty(): return
	mission["index"] = int(mission.get("index", 0)) + 1
	mission["progress"] = 0
	var objs: Array = mission["data"].get("objectives", [])
	if int(mission["index"]) >= objs.size():
		_complete_mission()
	else:
		mission_objective_changed.emit(int(mission["index"]), objs[int(mission["index"])])

func _complete_mission() -> void:
	var id: String = mission["id"]
	var data: Dictionary = mission["data"]
	var reward: Dictionary = data.get("reward", {})
	if reward.has("money"): add_money(int(reward["money"]))
	if reward.has("xp"): add_xp(int(reward["xp"]))
	if reward.has("discipline"): unlock_discipline(reward["discipline"])
	for f in reward.get("trust", {}):
		add_trust(f, int(reward["trust"][f]))
	for s in data.get("sets", []): set_flag(s)
	if data.has("job_id"):
		if not completed_jobs.has(data["job_id"]): completed_jobs.append(data["job_id"])
	else:
		if not completed_missions.has(id): completed_missions.append(id)
		stats["missions_done"] = int(stats.get("missions_done", 0)) + 1
	mission_completed.emit(id)
	notify("Mission complete", data.get("title", id), "mission")
	mission = {}

func abandon_mission() -> void:
	if mission.is_empty(): return
	mission = {}
	notify("Mission abandoned", "", "info")

func mission_available(mid: String) -> bool:
	if completed_missions.has(mid): return false
	var m: Dictionary = Content.MISSIONS.get(mid, {})
	if m.is_empty(): return false
	# Chapter 1 always available; later chapters gate on prior completion flags.
	var ch := int(m.get("chapter", 1))
	if ch <= 1: return true
	var flags_needed: Array = []
	for other_id in Content.MISSIONS:
		if int(Content.MISSIONS[other_id]["chapter"]) == ch - 1:
			for s in Content.MISSIONS[other_id].get("sets", []):
				flags_needed.append(s)
	for f in flags_needed:
		if has_flag(f): return true
	return false

func next_available_mission() -> String:
	for id in Content.mission_order():
		if mission_available(id): return id
	return ""

# =========================================================== collectibles
func collect_fragment(fid: String) -> bool:
	if collectibles.has(fid): return false
	collectibles.append(fid)
	unlock_achievement("fragment_1")
	if collectibles.size() >= 12: unlock_achievement("fragment_all")
	add_xp(25)
	notify("Ledger fragment", "%d / 12" % collectibles.size(), "collect")
	return true

# =========================================================== SAVE / LOAD
func _slot_path(slot: int) -> String:
	return "%s/slot_%d.save" % [SAVE_DIR, slot]

func save_game(slot: int) -> bool:
	var d := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"play_time": play_time,
		"money": money, "xp": xp, "level": level,
		"player_health": player_health, "player_max_health": player_max_health,
		"hour": hour, "day": day, "weather": weather,
		"spawn_point": spawn_point, "current_district": current_district,
		"heat": heat, "wanted": wanted,
		"ammo": ammo, "weapons": weapons, "armor": armor,
		"owned_weapons": owned_weapons, "owned_armor": owned_armor,
		"equipped_weapon": equipped_weapon, "equipped_armor": equipped_armor,
		"active_discipline": active_discipline, "unlocked_disciplines": unlocked_disciplines,
		"relationships": relationships, "trust": trust, "drinks": drinks,
		"flags": flags, "collectibles": collectibles,
		"completed_missions": completed_missions, "completed_jobs": completed_jobs,
		"achievements": achievements, "stats": stats,
		"radio_station": radio_station, "known_radio": known_radio,
	}
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	notify("Saved", "Slot %d" % (slot + 1), "save")
	return true

func slot_info(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path): return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY: return {}
	return {
		"exists": true, "saved_at": parsed.get("saved_at", ""),
		"money": parsed.get("money", 0), "level": parsed.get("level", 1),
		"district": Content.district_name(parsed.get("current_district", "ash_row")),
		"play_time": parsed.get("play_time", 0.0),
		"missions": (parsed.get("completed_missions", []) as Array).size(),
	}

## Current save schema. Bump this whenever the shape changes and add a step to
## _migrate() so old saves are upgraded forward instead of losing progress.
const SAVE_VERSION := 3

## Upgrade an older save in place. Each step is additive and idempotent.
func _migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	if v < 2:
		# v1 had no phone state; give it empty defaults.
		if not d.has("call_log"): d["call_log"] = []
		if not d.has("missed_calls"): d["missed_calls"] = []
		if not d.has("messages"): d["messages"] = {}
		v = 2
	if v < 3:
		# v3 adds reputation, achievements and play statistics.
		if not d.has("reputation"): d["reputation"] = {}
		if not d.has("achievements"): d["achievements"] = []
		if not d.has("stats"): d["stats"] = {}
		v = 3
	d["version"] = v
	return d

func load_game(slot: int) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path): return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY: return false
	var d: Dictionary = _migrate(parsed)
	money = int(d.get("money", 120))
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	player_health = float(d.get("player_health", 100.0))
	player_max_health = float(d.get("player_max_health", 100.0))
	hour = float(d.get("hour", 16.5))
	day = int(d.get("day", 1))
	weather = str(d.get("weather", "clear"))
	spawn_point = str(d.get("spawn_point", "apartment"))
	current_district = str(d.get("current_district", "ash_row"))
	heat = float(d.get("heat", 0.0))
	wanted = int(d.get("wanted", 0))
	ammo = d.get("ammo", {"pistol": 0, "smg": 0, "shotgun": 0})
	weapons = d.get("weapons", ["fists"])
	armor = str(d.get("armor", "none"))
	owned_weapons = d.get("owned_weapons", ["fists"])
	owned_armor = d.get("owned_armor", ["none"])
	equipped_weapon = str(d.get("equipped_weapon", "fists"))
	equipped_armor = str(d.get("equipped_armor", "none"))
	active_discipline = str(d.get("active_discipline", "brawler"))
	unlocked_disciplines = d.get("unlocked_disciplines", ["brawler"])
	relationships = d.get("relationships", {})
	trust = d.get("trust", {"family": 60, "corporation": 0, "crew": 20, "police": 10})
	reputation = d.get("reputation", {})
	achievements = d.get("achievements", [])
	stats = d.get("stats", {})
	drinks = int(d.get("drinks", 0))
	flags = d.get("flags", {})
	collectibles = d.get("collectibles", [])
	completed_missions = d.get("completed_missions", [])
	completed_jobs = d.get("completed_jobs", [])
	achievements = d.get("achievements", [])
	stats = d.get("stats", stats)
	radio_station = str(d.get("radio_station", "city"))
	known_radio = d.get("known_radio", ["r1", "r2", "r3"])
	save_loaded_from = slot
	# JSON gives us floats/strings; normalise the array-of-string fields.
	weapons = _as_strings(weapons)
	owned_weapons = _as_strings(owned_weapons)
	owned_armor = _as_strings(owned_armor)
	unlocked_disciplines = _as_strings(unlocked_disciplines)
	collectibles = _as_strings(collectibles)
	completed_missions = _as_strings(completed_missions)
	completed_jobs = _as_strings(completed_jobs)
	achievements = _as_strings(achievements)
	known_radio = _as_strings(known_radio)
	money_changed.emit(money, 0)
	notify("Loaded", "Slot %d" % (slot + 1), "save")
	return true

func _as_strings(arr: Array) -> Array:
	var out := []
	for v in arr: out.append(str(v))
	return out

func reset_new_game() -> void:
	player_health = 100.0
	player_max_health = 100.0
	stamina = max_stamina
	money = 120
	xp = 0
	level = 1
	hour = 16.5
	day = 1
	weather = "clear"
	spawn_point = "apartment"
	current_district = "ash_row"
	heat = 0.0
	wanted = 0
	ammo = {"pistol": 0, "smg": 0, "shotgun": 0}
	weapons = ["fists"]
	armor = "none"
	owned_weapons = ["fists"]
	owned_armor = ["none"]
	equipped_weapon = "fists"
	equipped_armor = "none"
	active_discipline = "brawler"
	unlocked_disciplines = ["brawler"]
	relationships = {}
	trust = {"family": 60, "corporation": 0, "crew": 20, "police": 10}
	drinks = 0
	flags = {}
	collectibles = []
	completed_missions = []
	completed_jobs = []
	achievements = []
	stats = {"fights_won": 0, "fights_lost": 0, "distance_walked": 0.0,
		"distance_driven": 0.0, "money_earned": 0, "money_spent": 0, "missions_done": 0,
		"npcs_talked": 0, "vehicles_stolen": 0}
	play_time = 0.0
	save_loaded_from = -1
	radio_station = "city"
	known_radio = ["r1", "r2", "r3"]
	mission = {}
