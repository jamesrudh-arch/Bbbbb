extends Node
## Is the content actually reachable? Not "does the code exist" - can a player
## reach it. Every check runs against the real world.
var ok := 0
var bad := 0

func _c(name: String, cond: bool, detail := "") -> void:
	if cond:
		ok += 1; print("C  ok   ", name, (" — " + detail if detail else ""))
	else:
		bad += 1; print("C  FAIL ", name, (" — " + detail if detail else ""))

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	Game.reset_new_game()
	Game.start_mission("homecoming")
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame

	# ---- fragments: collect through the interaction system, as a player does
	var frags: int = w.pickups.pickups.size()
	_c("fragments spawned", frags == 12, str(frags))
	if frags > 0:
		var n0: int = Game.collectibles.size()
		var node = w.pickups.pickups[0].get("node")
		w.interactables.activate(node, w.player)
		await get_tree().process_frame
		_c("fragment collectable by interact", Game.collectibles.size() == n0 + 1,
			"%d -> %d" % [n0, Game.collectibles.size()])
	# a collect objective advances - but only while it IS the current objective.
	# Collecting during a talk objective is expected to be banked, not counted.
	var got := 0
	for i in Game.mission["data"]["objectives"].size():
		if str(Game.mission["data"]["objectives"][i].get("type", "")) == "collect":
			got = i
			break
	Game.mission["index"] = got
	Game.mission["progress"] = 0
	var before_idx := got
	for p in w.pickups.pickups.duplicate():
		w.interactables.activate(p.get("node"), w.player)
		await get_tree().process_frame
		if Game.objective_index() != before_idx: break
	_c("collect objective advances from fragments", Game.objective_index() > before_idx,
		"index %d -> %d" % [before_idx, Game.objective_index()])

	# ---- jobs: all 15 written jobs are offered and startable
	var offered: Array = w.hud._available_jobs()
	_c("jobs on the board", offered.size() > 0, str(offered.size()) + " of " + str(Content.SIDE_JOBS.size()))
	var started := 0
	var bad_job := ""
	for jid in offered:
		Game.mission = {}
		Game.start_mission_from_job(str(jid), Content.SIDE_JOBS[jid])
		if str(Game.mission.get("job", "")) == str(jid): started += 1
		else: bad_job = str(jid)
	_c("every offered job starts", started == offered.size(), "%d/%d%s" % [started, offered.size(), (" bad=" + bad_job) if bad_job != "" else ""])
	# running a job removes it from the board
	if offered.size() > 0:
		var running := str(offered[0])
		Game.mission = {}
		Game.start_mission_from_job(running, Content.SIDE_JOBS[running])
		_c("running job leaves the board", not w.hud._available_jobs().has(running))
	Game.mission = {}

	# ---- shops: open in a real interior, and money actually moves
	Game.add_money(5000)
	var money0 := Game.money
	var entered := false
	for iid in Content.INTERIORS:
		var info: Dictionary = Content.INTERIORS[iid]
		if info.get("vendor", "") == "": continue
		w.interiors.enter(str(iid), w.player)
		entered = true
		await get_tree().process_frame
		# find the vendor inside
		var vendor: Node3D = null
		for n in w.interiors.find_children("*", "CharacterBody3D", true, false):
			if n.has_meta("kind") and str(n.get_meta("kind")) == "shop":
				vendor = n; break
		if vendor == null:
			_c("vendor exists in " + str(iid), false); break
		w.interactables.activate(vendor, w.player)
		_c("shop opens from vendor", w.hud._shop.visible, str(iid))
		# buy the first affordable thing
		var vid := str(vendor.get_meta("vendor", "general"))
		var items: Array = Content.SHOP_ITEMS.get(vid, {}).get("items", [])
		var bought := false
		for it in items:
			if Game.money >= int(it.get("price", 999999)):
				var r = Game.buy_item(it)
				bought = r != false
				break
		_c("vendor sells", Game.money < money0, "%d -> %d" % [money0, Game.money])
		w.interiors.exit(w.player)
		await get_tree().process_frame
		break
	_c("an interior with a vendor was enterable", entered)

	# ---- autosave
	Game.autosave()
	_c("autosave written", Game.latest_save_slot() == Game.AUTOSAVE_SLOT,
		"latest=" + str(Game.latest_save_slot()))

	print("C ---- %d ok, %d failed ----" % [ok, bad])
	get_tree().quit(1 if bad > 0 else 0)
