extends Node
## Does the streamer's per-district work actually materialise the crowd and the
## night pools? The full six-district world is past this container's memory, so
## this builds two real districts and runs the streamer's own code path over them
## with the minimal duck-typed world it requires (.player, .builder, .night_factor).

class WorldStub extends Node3D:
	var player: Node3D
	var builder: Node
	var night_factor := 0.0

func _ready() -> void:
	var builder = load("res://scripts/world/city_builder.gd").new()
	add_child(builder)
	var stub: Node3D = WorldStub.new()
	stub.name = "WorldStub"
	add_child(stub)
	stub.builder = builder
	var p := Node3D.new()
	p.name = "PlayerStand"
	p.position = Vector3.ZERO
	add_child(p)
	stub.player = p

	var streamer = load("res://scripts/world/world_streamer.gd").new()
	streamer.name = "WS"
	add_child(streamer)
	var districts := {}
	for id in ["ash_row", "guttermarket"]:
		var d: Node3D = builder.build_district(id)
		add_child(d)
		districts[id] = d
	streamer.world = stub
	streamer.districts = districts
	_run.call_deferred(districts)

func _run(districts: Dictionary) -> void:
	for i in 150:
		await get_tree().process_frame
	var crowds := 0
	var figures := 0
	var pools := 0
	var people_meta := 0
	var night_meta := 0
	for id in districts:
		var d: Node3D = districts[id]
		var c = d.get_node_or_null("AnimatedCrowd")
		if c != null:
			crowds += 1
			figures += c.count()
		if d.get_node_or_null("StreetNight") != null:
			pools += 1
		if d.has_meta("people_spawned"): people_meta += 1
		if d.has_meta("night_built"): night_meta += 1
	print("V crowds=", crowds, " figures=", figures, " night_pools=", pools,
		" people_meta=", people_meta, " night_meta=", night_meta)
	get_tree().quit()
