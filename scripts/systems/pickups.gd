extends Node
## PICKUPS — the 12 ledger fragments hidden across Cinder City, plus ammo/money
## drops. Fragments are physical objects with a beacon glow so they read at night.

var world: Node3D
var pickups: Array = []

const FRAGMENT_COUNT := 12

func setup(w: Node3D) -> void:
	world = w
	_spawn_fragments()

func _spawn_fragments() -> void:
	var placed := 0
	var districts: Array = Content.DISTRICT_ORDER.duplicate()
	while placed < FRAGMENT_COUNT:
		var district: String = districts[placed % districts.size()]
		var center: Vector3 = world.builder.district_center(district)
		var nodes: Array = world.builder.nav_nodes.get(district, [])
		if nodes.is_empty(): continue
		var offset: Vector3 = nodes[randi() % nodes.size()]
		var pos: Vector3 = center + offset + Vector3(randf_range(-3, 3), 0.9, randf_range(-3, 3))
		_create_fragment("frag_%d" % (placed + 1), pos)
		placed += 1

func _create_fragment(fid: String, pos: Vector3) -> void:
	var node := Node3D.new()
	node.name = "Frag_" + fid
	node.set_meta("interact", true)
	node.set_meta("kind", "pickup")
	node.set_meta("fragment_id", fid)
	node.position = pos
	add_child(node)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.86, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.82, 0.35)
	mat.emission_energy_multiplier = 2.8
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.7)
	mi.mesh = q
	mi.material_override = mat
	node.add_child(mi)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.86, 0.5)
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.shadow_enabled = false
	node.add_child(light)

	# Bob + spin so it reads as collectible from a distance.
	var tw := create_tween().set_loops()
	tw.tween_property(mi, "position:y", 0.18, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mi, "position:y", -0.05, 1.1).set_trans(Tween.TRANS_SINE)
	var tw2 := create_tween().set_loops()
	tw2.tween_property(node, "rotation:y", TAU, 3.0).from(0.0)
	pickups.append({"id": fid, "node": node, "kind": "fragment"})

## Interaction calls this.
func collect(node: Node3D) -> void:
	var fid := str(node.get_meta("fragment_id", ""))
	if fid == "": return
	if not Game.collect_fragment(fid): return
	Audio.play_at("pickup", node.global_position, 1.0, 2.0)
	for p in pickups:
		if p["node"] == node:
			pickups.erase(p)
			break
	node.queue_free()
	if Game.mission.is_empty(): return
	var obj := Game.current_objective()
	if str(obj.get("type", "")) == "collect":
		Game.add_mission_progress(1)

func nearest(pos: Vector3) -> Node3D:
	var best: Node3D = null
	var bestd := 2.6
	for p in pickups:
		var n: Node3D = p["node"]
		if not is_instance_valid(n): continue
		var d: float = pos.distance_to(n.global_position)
		if d < bestd:
			bestd = d
			best = n
	return best
