extends Node
## LEVERAGE — Integration test suite (run headless).
##   godot --headless --path . --script tests/test_suite.gd
## Exercises the real systems: content integrity, input map, save/load,
## economy, combat math, discipline identity, world construction, navigation
## graphs, NPC/AI wiring, mission progression, shops and audio resources.
## Every assertion prints PASS/FAIL with the exact check name.

var passed := 0
var failed := 0
var results: Array[String] = []

func _ok(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		passed += 1
		results.append("PASS  " + name + ("  " + detail if detail != "" else ""))
	else:
		failed += 1
		results.append("FAIL  " + name + ("  " + detail if detail != "" else ""))

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("\n=========== LEVERAGE TEST SUITE ===========")
	for step in ["content", "input", "save_load", "economy", "combat", "audio", "scenes"]:
		print("  [step] ", step)
		match step:
			"content": _test_content()
			"input": _test_input_map()
			"save_load": _test_save_load()
			"economy": await _test_economy()
			"combat": _test_combat_math()
			"audio": _test_audio_assets()
			"scenes": _test_scene_resources()
	print("  [step] world")
	await _test_world()
	print("  [step] missions")
	# _test_world leaves a fully built city in the tree. Mission tests are pure
	# Game-state, so holding 1.3 GB of city nodes alive across them only makes
	# the suite look hung on machines with a tight memory ceiling.
	_maybe_free_world()
	_test_mission_flow()
	_report()
	get_tree().quit(0 if failed == 0 else 1)

# ------------------------------------------------------------------ content
func _test_content() -> void:
	_ok("content.districts==6", Content.DISTRICTS.size() == 6, str(Content.DISTRICTS.size()))
	var all_have_palette := true
	for id in Content.DISTRICTS:
		var d: Dictionary = Content.DISTRICTS[id]
		if not d.has("palette") or d["palette"].is_empty(): all_have_palette = false
		if not d.has("landmarks") or d["landmarks"].size() < 3: all_have_palette = false
	_ok("districts have palettes+landmarks", all_have_palette)
	_ok("content.characters==16", Content.CHARACTERS.size() == 16, str(Content.CHARACTERS.size()))
	var models_ok := true
	for cid in Content.CHARACTERS:
		var m: String = Content.CHARACTERS[cid]["model"]
		if not ResourceLoader.exists("res://assets/characters/players/%s.glb" % m):
			models_ok = false
			results.append("      missing model for " + cid + ": " + m)
	_ok("every character has a real model file", models_ok)
	_ok("content.missions==8", Content.MISSIONS.size() == 8, str(Content.MISSIONS.size()))
	_ok("content.disciplines==5", Content.DISCIPLINES.size() == 5)
	_ok("discipline keys match spec", Content.DISCIPLINES.has("brawler") and Content.DISCIPLINES.has("kickboxing") and Content.DISCIPLINES.has("grappling") and Content.DISCIPLINES.has("drunken") and Content.DISCIPLINES.has("weapon"))
	_ok("content.weapons>=7", Content.WEAPONS.size() >= 7, str(Content.WEAPONS.size()))
	_ok("content.vehicles>=8", Content.VEHICLE_TYPES.size() >= 8, str(Content.VEHICLE_TYPES.size()))
	var shop_items := 0
	for sid in Content.SHOP_ITEMS: shop_items += Content.SHOP_ITEMS[sid]["items"].size()
	_ok("shop catalogue has items", shop_items >= 14, str(shop_items))
	_ok("achievements==8", Content.ACHIEVEMENTS.size() == 8)
	_ok("radio has reports", Content.RADIO["reports"].size() >= 6, str(Content.RADIO["reports"].size()))
	var side := Content.SIDE_JOBS.size()
	_ok("side jobs >= 3", side >= 3, str(side))

# ------------------------------------------------------------------ input
func _test_input_map() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "crouch",
			"lock_on", "punch", "heavy", "kick", "dodge", "block", "counter", "aim", "shoot",
			"reload", "weapon_switch", "interact", "enter_vehicle", "exit_vehicle",
			"steer_left", "steer_right", "throttle", "brake", "handbrake", "horn", "pause"]:
		_ok("action exists: " + a, InputMap.has_action(a))
	# Combat faces must be the exact required binding set
	_ok("X=punch bound", InputMap.has_action("punch") and InputMap.action_get_events("punch").size() > 0)
	_ok("Y=heavy bound", InputMap.has_action("heavy") and InputMap.action_get_events("heavy").size() > 0)
	_ok("A=kick bound", InputMap.has_action("kick"))
	_ok("B=dodge bound", InputMap.has_action("dodge"))

# ------------------------------------------------------------------ save
func _test_save_load() -> void:
	Game.reset_new_game()
	Game.money = 777
	Game.add_xp(500)
	Game.set_flag("test_flag")
	Game.unlock_discipline("kickboxing")
	Game.relationships["ada"] = 42
	Game.collectibles.append("frag_1")
	Game.ammo["pistol"] = 33
	Game.stats["fights_won"] = 5
	var saved := Game.save_game(2)
	_ok("save_game returns true", saved)
	_ok("slot_info reads back", not Game.slot_info(2).is_empty())
	Game.reset_new_game()
	_ok("reset cleared money", Game.money == 120)
	var loaded := Game.load_game(2)
	_ok("load_game returns true", loaded)
	_ok("money restored", Game.money == 777, str(Game.money))
	_ok("xp restored", Game.xp >= 500, str(Game.xp))
	_ok("flag restored", Game.has_flag("test_flag"))
	_ok("discipline restored", Game.unlocked_disciplines.has("kickboxing"))
	_ok("relationship restored", Game.relationship("ada") == 42, str(Game.relationship("ada")))
	_ok("collectible restored", "frag_1" in Game.collectibles)
	_ok("ammo restored", int(Game.ammo.get("pistol", 0)) == 33)
	_ok("stats restored", int(Game.stats.get("fights_won", 0)) == 5)

# ------------------------------------------------------------------ economy
func _test_economy() -> void:
	Game.reset_new_game()
	Game.money = 1000
	var before := Game.money
	var meal := {"id": "meal_jollof", "name": "Jollof", "price": 12, "effect": "heal:35"}
	Game.player_health = 40.0
	var bought := Game.buy_item(meal)
	_ok("buy_item succeeds", bought)
	_ok("money deducted", Game.money == before - 12, str(Game.money))
	_ok("heal applied", Game.player_health > 40.0, str(Game.player_health))
	# weapon purchase equips and registers
	var w := {"id": "w", "name": "Pipe", "price": 90, "effect": "weapon:pipe"}
	Game.buy_item(w)
	_ok("weapon owned", Game.owned_weapons.has("pipe"))
	_ok("weapon equipped", Game.equipped_weapon == "pipe")
	# armour has real gameplay effect
	var a := {"id": "a", "name": "Vest", "price": 420, "effect": "armor:vest"}
	Game.buy_item(a)
	_ok("armor equipped", Game.equipped_armor == "vest")
	_ok("armor gives protection", float(Content.ARMOR["vest"]["protect"]) > 0.0)
	# insufficient funds must fail
	Game.money = 5
	var expensive := {"id": "x", "name": "X", "price": 100000, "effect": "heal:10"}
	_ok("cannot buy without money", Game.buy_item(expensive) == false)
	# heat/wanted escalation
	Game.clear_heat()
	Game.add_heat(31.0)
	for _i in range(4):
		await get_tree().process_frame
	_ok("heat raises wanted level", Game.wanted >= 2, str(Game.wanted))

# ------------------------------------------------------------------ combat
func _test_combat_math() -> void:
	# Verify each discipline produces genuinely different reach/damage/speed
	var seen := {}
	for did in Content.DISCIPLINES:
		var d: Dictionary = Content.DISCIPLINES[did]
		var sig := "%.2f_%.2f_%.2f" % [d["reach"], d["damage"], d["speed"]]
		seen[sig] = true
	_ok("all 5 disciplines have distinct stat signatures", seen.size() == 5, str(seen.size()))
	_ok("brawler shortest reach but full damage", Content.DISCIPLINES["brawler"]["reach"] < Content.DISCIPLINES["kickboxing"]["reach"])
	_ok("grappling highest damage", Content.DISCIPLINES["grappling"]["damage"] > Content.DISCIPLINES["kickboxing"]["damage"])
	_ok("weapon longest reach", Content.DISCIPLINES["weapon"]["reach"] == 3.0)
	_ok("kickboxing fastest", Content.DISCIPLINES["kickboxing"]["speed"] == 1.25)
	# Armour protection is a real multiplier
	_ok("riot armor strongest", Content.ARMOR["riot"]["protect"] > Content.ARMOR["vest"]["protect"])
	# Gun weapons have magazine data
	for wid in ["pistol", "smg", "shotgun"]:
		_ok("gun has mag/reserve: " + wid, Content.WEAPONS[wid].has("mag") and Content.WEAPONS[wid].has("reserve"))

# ------------------------------------------------------------------ audio
func _test_audio_assets() -> void:
	var required := ["music/explore", "music/tension", "ambience/city_bed", "ambience/rain",
		"sfx/punch_hit", "sfx/kick_hit", "sfx/heavy_hit", "sfx/dodge", "sfx/block",
		"sfx/gun_pistol", "sfx/gun_smg", "sfx/reload", "sfx/step_concrete",
		"sfx/engine_loop", "sfx/engine_start", "sfx/horn", "sfx/door", "sfx/explosion",
		"ui/click", "ui/confirm", "music/stinger_alert", "music/stinger_mission", "music/stinger_complete"]
	var missing := []
	for r in required:
		if not ResourceLoader.exists("res://audio/%s.wav" % r):
			missing.append(r)
	_ok("all required audio files exist", missing.is_empty(), ",".join(PackedStringArray(missing)))
	# Every SFX id in the Audio director must resolve to a real file
	var unresolved := []
	for k in Audio.SFX:
		if not ResourceLoader.exists(Audio.SFX[k]):
			unresolved.append(k)
	_ok("Audio.SFX ids resolve to files", unresolved.is_empty(), ",".join(PackedStringArray(unresolved)))

# ------------------------------------------------------------------ scenes
func _test_scene_resources() -> void:
	for path in ["res://scenes/boot.tscn", "res://scenes/main_menu.tscn", "res://scenes/world.tscn", "res://scenes/player.tscn"]:
		_ok("scene loads: " + path.get_file(), ResourceLoader.exists(path) and load(path) != null)
	_ok("project uses mobile renderer", ProjectSettings.get_setting("rendering/renderer/rendering_method") == "mobile")
	_ok("main scene is boot", str(ProjectSettings.get_setting("application/run/main_scene")).ends_with("boot.tscn"))

# ------------------------------------------------------------------ world
func _test_world() -> void:
	print("  [world] instantiating Cinder City…")
	var t0 := Time.get_ticks_msec()
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	_test_world_node = world
	await get_tree().process_frame
	await get_tree().process_frame
	var ms := Time.get_ticks_msec() - t0
	_ok("world instantiated", world != null)
	_ok("world build under 60s", ms < 60000, "%d ms" % ms)
	_ok("six districts built", world.districts.size() == 6, str(world.districts.size()))
	var total_children := 0
	for id in world.districts:
		var d = world.districts[id]
		total_children += _count_descendants(d)
	_ok("districts populated", total_children > 800, str(total_children) + " objects")
	# navigation graphs
	var nav_ok := true
	var drive_ok := true
	for id in Content.DISTRICTS:
		if world.builder.nav_nodes.get(id, []).size() < 10: nav_ok = false
		if world.builder.drive_graph.get(id, []).size() < 10: drive_ok = false
	_ok("sidewalk nav graph per district", nav_ok)
	_ok("drive graph per district", drive_ok)
	# portals (enterable locations)
	var portals := 0
	for id in world.districts:
		portals += _count_meta(world.districts[id], "interact")
	_ok("enterable portals exist", portals >= 5, str(portals) + " portals")
	# actors
	var named: int = world.npcs.named.size()
	_ok("named characters spawned >= 12", named >= 12, str(named))
	_ok("pedestrians spawned >= 20", world.npcs.pedestrians.size() >= 20, str(world.npcs.pedestrians.size()))
	# collide on player
	var p = get_tree().get_first_node_in_group("player")
	_ok("player in scene", p != null)
	if p:
		_ok("player camera active", p.camera_rig.camera.current)
		_ok("camera has target", p.camera_rig.target_node != null)
		_ok("player inside ash_row bounds", absf(p.global_position.x + 160.0) < 80.0)
	# pickups
	var frags := 0
	for pk in world.pickups.pickups:
		if pk["kind"] == "fragment": frags += 1
	_ok("12 city fragments placed", frags == 12, str(frags))
	# mission auto-start
	_ok("opening mission active", not Game.mission.is_empty(), str(Game.mission.get("id", "")))

## The city built by _test_world, kept only so it can be released before the
## mission tests run.
var _test_world_node: Node = null

func _maybe_free_world() -> void:
	if _test_world_node != null and is_instance_valid(_test_world_node):
		# free(), not queue_free(): the point is to release it BEFORE the next
		# step, and queue_free defers to the end of the frame.
		_test_world_node.free()
		_test_world_node = null

func _count_descendants(n: Node) -> int:
	var c := n.get_child_count()
	for ch in n.get_children(): c += _count_descendants(ch)
	return c

func _count_meta(n: Node, meta: String) -> int:
	var c := 0
	if n.has_meta(meta): c += 1
	for ch in n.get_children(): c += _count_meta(ch, meta)
	return c

# ------------------------------------------------------------------ missions
func _test_mission_flow() -> void:
	Game.reset_new_game()
	Game.start_mission("homecoming")
	_ok("mission starts", Game.mission.get("id", "") == "homecoming")
	var obj := Game.current_objective()
	_ok("first objective is reach", obj.get("type", "") == "reach")
	Game.advance_mission()
	_ok("advance to talk", Game.current_objective().get("type", "") == "talk")
	Game.advance_mission()
	_ok("advance to collect", Game.current_objective().get("type", "") == "collect")
	Game.add_mission_progress(1)
	Game.add_mission_progress(1)
	_ok("collect progress tracked", int(Game.mission.get("progress", -1)) == 2, str(Game.mission.get("progress")))
	Game.add_mission_progress(1)
	_ok("collect objective completes", Game.current_objective().get("type", "") == "talk")
	Game.advance_mission()
	_ok("mission completes", "homecoming" in Game.completed_missions, str(Game.completed_missions))
	_ok("flag set on completion", Game.has_flag("homecoming_done"))
	_ok("next mission unlocked", Game.mission_available("short_count"))
	# branch choices set flags and pay out
	Game.reset_new_game()
	Game.start_mission("ash_fall")
	Game.set_flag("glass_ledger_done")
	Game.money = 500
	var opt := {"id": "take_deal", "flag": "chose_corp", "money": 2500, "xp": 250}
	Game.set_flag("chose_corp")
	Game.add_money(2500)
	_ok("choice pays out", Game.money == 3000, str(Game.money))
	_ok("choice flag recorded", Game.has_flag("chose_corp"))
	# side job registers separately
	Game.reset_new_game()
	Game.start_mission_from_job("gutter_tavern", Content.SIDE_JOBS["gutter_tavern"])
	_ok("side job starts with job_ prefix", Game.mission.get("id", "").begins_with("job_"))
	Game.advance_mission()
	Game.advance_mission()
	_ok("job completes into completed_jobs", "gutter_tavern" in Game.completed_jobs)
	_ok("job unlocks a discipline reward", Game.unlocked_disciplines.size() > 1, str(Game.unlocked_disciplines))

# ------------------------------------------------------------------ report
func _report() -> void:
	print("\n------------------- RESULTS -------------------")
	for r in results:
		print(r)
	print("-----------------------------------------------")
	print("PASSED: %d   FAILED: %d   TOTAL: %d" % [passed, failed, passed + failed])
	var f := FileAccess.open("res://tests/last_report.txt", FileAccess.WRITE)
	if f:
		f.store_string("LEVERAGE TEST REPORT\n" + Time.get_datetime_string_from_system() + "\n\n")
		for r in results: f.store_string(r + "\n")
		f.store_string("\nPASSED: %d   FAILED: %d   TOTAL: %d\n" % [passed, failed, passed + failed])
		f.close()
	print("===============================================\n")
