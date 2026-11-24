extends Node
## INTERACTION SYSTEM — resolves what the B button would do right now and draws
## the prompt. Owns the "areas" registry (portals, job boards, enterables).

var world: Node3D
var areas: Array[Node3D] = []
var _prompt_node: Node3D = null
var _prompt_text := ""

const KINDS := {"npc": "Talk", "portal": "Enter", "vehicle": "Drive", "pickup": "Pick up", "job": "Open"}

func setup(w: Node3D) -> void:
	world = w
	_collect_areas()

func _collect_areas() -> void:
	areas.clear()
	if world == null: return
	areas.append_array(world.npcs.named)
	for id in world.districts:
		var d: Node3D = world.districts[id]
		_scan(d)

func _scan(n: Node) -> void:
	# Landmarks carry meta "interact"; vehicles carry "parked".
	if n is Node3D and n.has_meta("interact"):
		areas.append(n)
	for c in n.get_children():
		_scan(c)

func find_nearest(pos: Vector3, max_dist: float) -> Node3D:
	var best: Node3D = null
	var bestd := max_dist
	for a in areas:
		if not is_instance_valid(a): continue
		if a is Node3D:
			var d: float = pos.distance_to(a.global_position)
			if d < bestd:
				bestd = d
				best = a
	# Vehicles are found by scanning the traffic list plus parked ones.
	if world.traffic != null:
		for v in world.traffic.vehicles + world.traffic.police:
			if is_instance_valid(v) and v.can_enter():
				var d: float = pos.distance_to(v.global_position)
				if d < bestd:
					bestd = d
					best = v
	if best == null and world.player != null and world.player.combat != null and world.player.combat.in_combat:
		return null
	return best

func set_prompt(target: Node3D) -> void:
	if world == null or world.hud == null: return
	_prompt_node = target
	if target == null:
		if _prompt_text != "":
			_prompt_text = ""
			world.hud.set_interact_prompt("", "")
		return
	var kind := "interact"
	var label := "Interact"
	if target.has_meta("kind") and target.get_meta("kind") == "npc":
		kind = "npc"
		label = "Talk to " + (target.display_name if target.display_name != "" else "them")
	elif target is VehicleBody3D:
		kind = "vehicle"
		label = "Drive"
	elif target.has_meta("interior"):
		kind = "portal"
		label = "Enter " + Content.INTERIORS.get(str(target.get_meta("interior")), {}).get("name", "building")
	elif target.has_meta("landmark_id"):
		kind = "portal"
		label = "Look around"
	if label != _prompt_text:
		_prompt_text = label
		world.hud.set_interact_prompt(label, kind)

func activate(target: Node3D, player) -> void:
	if target == null: return
	if target.has_meta("kind") and target.get_meta("kind") == "pickup":
		world.pickups.collect(target)
		Audio.play_ui("pickup")
		return
	if target.has_meta("kind") and target.get_meta("kind") == "shop":
		var vendor := str(target.get_meta("vendor", "general"))
		world.hud.open_shop(vendor)
		Audio.play_ui("click")
		return
	if target is VehicleBody3D:
		player.driver.enter(target)
		return
	if target.has_meta("interior"):
		var iid := str(target.get_meta("interior"))
		world.interiors.enter(iid, player)
		return
	if target.has_meta("kind") and target.get_meta("kind") == "npc":
		var data: Dictionary = target.talk()
		world.hud.show_dialogue(data.get("name", ""), data.get("text", ""))
		Audio.play_ui("click")
		world.missions.report_talk(str(data.get("id", "")))
		return
	Audio.play_ui("click")
