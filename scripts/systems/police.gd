extends Node
## POLICE — wanted-level response.
## Level 0: patrols cruise. 1: one unit diverts. 2: two units. 3: units + foot
## officers. 4: heavy response and a helicopter shadow (visual only, mobile).
## Police abandon pursuit when heat falls and the player is out of sight.

var world: Node3D
var units: Array = []
var foot: Array = []
var _spawn_timer := 0.0
var _deployed := 0

func setup(w: Node3D, _districts: Dictionary) -> void:
	world = w
	Game.wanted_changed.connect(_on_wanted)

func _on_wanted(level: int) -> void:
	if level <= 0:
		_stand_down()
		return
	if level == 1:
		Audio.play_stinger("alert")
		Game.notify("Police alerted", "One unit responding", "heat")
	var want := clampi(level + 1, 1, 4)
	if _deployed < want:
		_spawn_unit()
		if level >= 3: _spawn_foot()
		Audio.play_stinger("alert")

func _spawn_unit() -> void:
	if world == null or world.player == null: return
	var VEHICLE = load("res://scripts/vehicle/vehicle.gd")
	var v = VEHICLE.new()
	v.configure("police")
	v.is_police = true
	v.name = "Responder_" + str(_deployed)
	add_child(v)
	var p: Vector3 = world.player.global_position
	var ang := randf() * TAU
	# Responders arrive from ~60 m out, snapped onto a real road: pick the closest
	# drive node in the player's district rather than a random offset in the void.
	var district: String = world.district_of(p)
	var nodes: Array = world.builder.drive_graph.get(district, [])
	var spawn_pt := p + Vector3(cos(ang) * 55.0, 0, sin(ang) * 55.0)
	if not nodes.is_empty():
		var dc: Vector3 = world.builder.district_center(district)
		var best: Vector3 = dc + nodes[0]
		var bestd := 1e9
		for n in nodes:
			var cand: Vector3 = dc + n
			var dd: float = cand.distance_to(p)
			if absf(dd - 55.0) < absf(bestd - 55.0):
				bestd = dd
				best = cand
		spawn_pt = best
	v.global_position = spawn_pt + Vector3(0, 2.0, 0)
	v.rotation.y = ang + PI
	v.set_meta("district_origin", p)
	v.patrol_center = p
	v.ai_controlled = true
	units.append(v)
	_deployed += 1

func _spawn_foot() -> void:
	if world == null or world.player == null: return
	var p: Vector3 = world.player.global_position
	var squad: Array = world.npcs.spawn_squad(p + Vector3(randf_range(-14, 14), 0.3, randf_range(-14, 14)), 2, 95.0, 10.0)
	for a in squad:
		a.faction = "police"
		foot.append(a)

func _stand_down() -> void:
	for u in units:
		if is_instance_valid(u): u.queue_free()
	for f in foot:
		if is_instance_valid(f): f.queue_free()
	units.clear()
	foot.clear()
	_deployed = 0

func _process(delta: float) -> void:
	# Purge dead units so the list stays cheap.
	units = units.filter(func(u): return is_instance_valid(u))
	foot = foot.filter(func(f): return is_instance_valid(f) and not f.is_dead)
	if Game.wanted == 0 and _deployed > 0:
		_stand_down()
	# Officers give up if the player is far and heat is low.
	if Game.wanted > 0 and world != null and world.player != null:
		_spawn_timer += delta
		if _spawn_timer > 18.0 and _deployed < Game.wanted + 1:
			_spawn_timer = 0.0
			_spawn_unit()
