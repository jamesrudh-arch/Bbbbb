extends Node3D
## Live AI proof: spawns a real crew against a real player and reports what the
## state machine actually did. A fight that never leaves "approach" is a fight
## that does not exist, however correct the code looks.

var world: Node3D
var _t := 0.0
var _seen := {}

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(1.2).timeout
	var player = world.player
	print("[F] player=", player != null, " pos=", player.global_position if player else "nil")

	var center: Vector3 = player.global_position
	var ids := ["street_thug", "knife_runner", "enforcer", "corner_lookout"]
	var i := 0
	for id in ids:
		var a = load("res://scripts/npc/actor.gd").new()
		# setup() must run before the node enters the tree: it assigns the
		# "hostile" group, and group membership is fixed at _ready().
		a.setup({
			"role": "thug", "name": id, "faction": "railhead",
			"hostile": true, "health": 60.0,
		})
		a.fight_data = Archetypes.make(id, 4)
		a.hostile = true
		a.notice_range = 40.0
		world.add_child(a)
		var ang := TAU * float(i) / float(ids.size())
		a.global_position = center + Vector3(cos(ang) * 6.0, 0.1, sin(ang) * 6.0)
		i += 1
	await get_tree().create_timer(1.0).timeout

	# Put the camera behind the player so this renders as the player sees it.
	var cam: Camera3D = world.get("camera_rig").get_node_or_null("Camera3D") if world.get("camera_rig") else null

	var actors: Array = get_tree().get_nodes_in_group("hostile")
	print("[F] spawned hostiles=", actors.size())
	for a in actors:
		print("[F]   ", a.display_name, " hp=%.0f ai=" % a.health, a.ai != null,
			" data=", a.fight_data.get("id", "?"))

	# Watch the fight for 8 seconds and record every state each AI entered.
	for step in 200:
		await get_tree().process_frame
		for a in actors:
			if a.ai != null and not a.is_dead:
				var k = a.ai.state
				if not _seen.has(a.display_name):
					_seen[a.display_name] = {}
				_seen[a.display_name][k] = int(_seen[a.display_name].get(k, 0)) + 1

	print("\n[F] ===== STATES OBSERVED =====")
	var struck := 0
	for n in _seen:
		var keys: Array = _seen[n].keys()
		print("[F] ", n, ": ", ", ".join(keys))
		if _seen[n].has("strike") or _seen[n].has("windup"):
			struck += 1
	print("[F] actors that reached a strike: ", struck, "/", _seen.size())
	var engaged := 0
	for n in _seen:
		if _seen[n].has("press") or _seen[n].has("windup") or _seen[n].has("strike"):
			engaged += 1
	print("[F] actors that closed to fighting range: ", engaged, "/", _seen.size())
	# Close the camera on the fight so the render shows the enemies, not the HUD.
	var cr = world.get("camera_rig")
	if cr != null and cr.get("camera") != null:
		var p2 = world.player.global_position
		cr.camera.global_position = p2 + Vector3(4.5, 2.6, 5.5)
		cr.camera.look_at(p2 + Vector3(0, 1.0, 0))
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/fight_01.png")
	print("SHOT_SAVED /home/user/leverage/shots/fight_01.png")
	get_tree().quit()
