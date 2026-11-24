extends Node
## INTERIORS — enterable buildings. Entering hides the city actors near the door
## and builds a small room interior in place (no scene swap, so no load hitch),
## with the vendor counter, furniture, and an exit trigger.

var world: Node3D
var current: Node3D = null
var current_id := ""
var _return_pos := Vector3.ZERO
var _return_yaw := 0.0
var _stash: Array = []

func setup(w: Node3D) -> void:
	world = w

func enter(iid: String, player) -> void:
	if current != null: return
	if not Content.INTERIORS.has(iid): return
	var info: Dictionary = Content.INTERIORS[iid]
	if current_id == iid: return
	current_id = iid
	_return_pos = player.global_position
	_return_yaw = player.camera_rig.yaw
	# Build a room at a far-off but valid location (no streaming cost).
	var room := Node3D.new()
	room.name = "Interior_" + iid
	add_child(room)
	var origin := Vector3(0, -400, 0)  # below the city
	room.global_position = origin
	_build_room(room, info)
	var room_size: Vector2 = info.get("size", Vector2(14, 12))
	player.global_position = origin + Vector3(0, 0.2, room_size.y * 0.30)
	player.camera_rig.yaw = 0.0     # camera sits behind (+Z), looking down -Z into the room
	player.camera_rig.target_node = player
	current = room
	world.hud.set_indoor(true, info["name"])
	Audio.play_at("door", _return_pos, 1.0, -2.0)
	Game.notify(info["name"], info.get("blurb", ""), "district")
	world.player.set_meta("indoor", iid)
	# spawn the vendor behind the counter
	_spawn_vendor(room, origin, info)

func _build_room(room: Node3D, info: Dictionary) -> void:
	var size: Vector2 = info["size"]
	var pal: Dictionary = Content.DISTRICTS.get(info["district"], Content.DISTRICTS["ash_row"])["palette"]
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = pal["ground"].lightened(0.18)
	floor_mat.roughness = 0.7
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = pal["wall"].lightened(0.22)
	wall_mat.roughness = 0.85
	var trim := StandardMaterial3D.new()
	trim.albedo_color = pal["trim"]
	trim.roughness = 0.6

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	room.add_child(body)

	# floor
	var fl := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(size.x, 0.2, size.y)
	fl.mesh = fb
	fl.material_override = floor_mat
	fl.position = Vector3(0, -0.1, 0)
	body.add_child(fl)
	var fshape := CollisionShape3D.new()
	var fbox := BoxShape3D.new()
	fbox.size = Vector3(size.x, 0.2, size.y)
	fshape.shape = fbox
	fshape.position = Vector3(0, -0.1, 0)
	body.add_child(fshape)

	# walls (back + sides), leaving the front open for the entrance
	var walls := [
		[Vector3(size.x, 3.2, 0.3), Vector3(0, 1.6, -size.y * 0.5)],
		[Vector3(0.3, 3.2, size.y), Vector3(-size.x * 0.5, 1.6, 0)],
		[Vector3(0.3, 3.2, size.y), Vector3(size.x * 0.5, 1.6, 0)],
		[Vector3(size.x * 0.3, 3.2, 0.3), Vector3(-size.x * 0.35, 1.6, size.y * 0.5)],
		[Vector3(size.x * 0.3, 3.2, 0.3), Vector3(size.x * 0.35, 1.6, size.y * 0.5)],
	]
	for w in walls:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = w[0]
		mi.mesh = bm
		mi.material_override = wall_mat
		mi.position = w[1]
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = w[0]
		cs.shape = bs
		cs.position = w[1]
		body.add_child(cs)

	# Interior lighting: one omni per room, no sky contributes at y=-400.
	var lamp := OmniLight3D.new()
	lamp.light_energy = 3.2
	lamp.light_color = Color(1.0, 0.92, 0.78)
	lamp.omni_range = maxf(size.x, size.y) * 0.85
	lamp.position = Vector3(0, 2.7, 0)
	body.add_child(lamp)

	# ceiling
	var ce := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(size.x, 0.2, size.y)
	ce.mesh = cb
	ce.material_override = trim
	ce.position = Vector3(0, 3.2, 0)
	body.add_child(ce)

	# counter
	var counter := MeshInstance3D.new()
	var cob := BoxMesh.new()
	cob.size = Vector3(size.x * 0.6, 1.1, 0.8)
	counter.mesh = cob
	counter.material_override = trim
	counter.position = Vector3(0, 0.55, -size.y * 0.32)
	body.add_child(counter)

	# interior lighting: two warm omnis (mobile budget friendly)
	for i in 2:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.86, 0.66)
		l.light_energy = 2.6
		l.omni_range = size.x * 0.8
		l.shadow_enabled = false
		l.position = Vector3(-size.x * 0.2 + i * size.x * 0.4, 2.8, 0)
		room.add_child(l)

	# door mat / exit marker
	var exit := Node3D.new()
	exit.name = "Exit"
	exit.set_meta("interact", true)
	exit.set_meta("kind", "exit")
	exit.position = Vector3(0, 0.1, size.y * 0.5 - 0.6)
	room.add_child(exit)
	var sign_mat := StandardMaterial3D.new()
	sign_mat.albedo_color = Color(0.9, 0.75, 0.3)
	sign_mat.emission_enabled = true
	sign_mat.emission = Color(1.0, 0.8, 0.3)
	sign_mat.emission_energy_multiplier = 1.6
	var sm := MeshInstance3D.new()
	var sq := BoxMesh.new()
	sq.size = Vector3(1.6, 0.08, 0.8)
	sm.mesh = sq
	sm.material_override = sign_mat
	sm.position = Vector3(0, 0.06, 0)
	exit.add_child(sm)

func _spawn_vendor(room: Node3D, origin: Vector3, info: Dictionary) -> void:
	var ACTOR = load("res://scripts/npc/actor.gd")
	var a = ACTOR.new()
	a.setup({"role": "vendor", "faction": "crew", "health": 80.0, "speed": 0.0})
	add_child(a)
	var size: Vector2 = info["size"]
	a.global_position = origin + Vector3(0, 0.2, -size.y * 0.32 - 1.2)
	a.set_meta("interact", true)
	a.set_meta("kind", "shop")
	a.set_meta("vendor", info.get("vendor", "general"))
	a.wander_center = a.global_position
	a.notice_range = 3.0
	# Vendor stays put — replace wander with a fixed idle.
	a.set_physics_process(false)

func enter_exit(_player) -> void:
	if current == null: return
	var p = _player
	p.global_position = _return_pos
	p.camera_rig.yaw = _return_yaw
	p.camera_rig.target_node = p
	p.remove_meta("indoor")
	if current != null:
		for c in current.get_children():
			if c is CharacterBody3D: c.queue_free()
		current.queue_free()
		current = null
	current_id = ""
	world.hud.set_indoor(false, "")
	Audio.play_at("door", _return_pos, 0.9, -2.0)

## Called by interaction when the player uses the exit marker.
func exit(player) -> void:
	enter_exit(player)
