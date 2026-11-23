extends Node
## TRAFFIC — AI vehicles driving the district road graphs, plus police units.

const VEHICLE := preload("res://scripts/vehicle/vehicle.gd")

var world: Node3D
var vehicles: Array = []
var police: Array = []

func setup(w: Node3D, districts: Dictionary) -> void:
	world = w
	var kinds := ["sedan", "hatchback", "taxi", "van"]
	for district in Content.DISTRICTS:
		if not districts.has(district): continue
		var n := 3 if int(Content.DISTRICTS[district]["tier"]) >= 2 else 2
		for i in n:
			var kind: String = kinds[randi() % kinds.size()]
			_spawn(kind, districts[district].global_position, district, false)
	# Two patrol cars live in the high-tier districts.
	for district in ["vesper_heights", "neon_mile"]:
		if districts.has(district):
			_spawn("police", districts[district].global_position, district, true)

func _spawn(kind: String, center: Vector3, district: String, is_cop: bool) -> void:
	var v := VEHICLE.new()
	v.configure(kind)
	v.is_police = is_cop
	v.name = ("Police_" if is_cop else "Traffic_") + str(vehicles.size() + police.size())
	add_child(v)
	var nodes: Array = world.builder.drive_graph.get(district, [])
	var start := center
	if not nodes.is_empty():
		start = center + nodes[randi() % nodes.size()]
	# Roads are 12 m wide and centred on +/-BLOCK, so a spawn on the graph is already
	# on tarmac. 2.0 m clearance clears the chassis before the wheels settle.
	v.global_position = start + Vector3(0, 2.0, 0)
	v.rotation.y = randf() * TAU
	v.set_meta("district_origin", center)
	v.patrol_center = center
	v.ai_controlled = true
	v.ai_target = center + (nodes[randi() % maxi(1, nodes.size())] if not nodes.is_empty() else Vector3.ZERO)
	v.set_meta("district_center", center)
	if is_cop:
		police.append(v)
	else:
		vehicles.append(v)
