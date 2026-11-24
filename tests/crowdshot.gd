extends Node
## CROWSHOT — render the animated crowd on its own, with nothing else in the
## scene. The district shot cannot afford both a full district and 14 skinned
## figures inside the render process's memory budget, and the crowd is the thing
## that needs judging, so it gets a bare set: a road, a kerb, and people.
##
##   HOUR=13 SHOT_PREFIX=/home/user/shots/crowd godot res://tests/crowdshot.tscn

var t := 0.0
var shot_taken := false
var prefix := "/home/user/crowd"
var cams: Array = []
var idx := 0

func _ready() -> void:
	var pp := OS.get_environment("SHOT_PREFIX")
	if pp != "":
		prefix = pp
	var hour := float(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 13.0
	var SN = load("res://scripts/world/street_night.gd")
	var night: float = SN.factor_for_hour(hour)
	var daylight: float = 1.0 - night

	# ---- ground: road plus two kerbs, enough to read scale
	var road := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(80, 0.1, 14)
	road.mesh = rb
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.20, 0.205, 0.225)
	rm.roughness = 0.82
	var SD = load("res://scripts/world/surface_detail.gd")
	rm.albedo_texture = SD.grain()
	rm.uv1_triplanar = true
	rm.uv1_scale = Vector3.ONE * 0.55
	road.material_override = rm
	road.position = Vector3(0, 0, -8)
	add_child(road)
	for side in [-1.0, 1.0]:
		var walk := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(80, 0.24, 3.2)
		walk.mesh = wb
		var wm := StandardMaterial3D.new()
		wm.albedo_color = Color(0.54, 0.50, 0.44)
		wm.roughness = 0.9
		wm.albedo_texture = SD.mottle()
		wm.uv1_triplanar = true
		wm.uv1_scale = Vector3.ONE * 0.18
		walk.material_override = wm
		walk.position = Vector3(0, 0.12, -8 + side * 8.6)
		add_child(walk)

	# ---- the crowd, exactly as the game builds it
	var crowd = load("res://scripts/world/street_crowd.gd").new()
	crowd.name = "Crowd"
	add_child(crowd)
	crowd.build(Vector3(-26, 0.0, -16.6), Vector3(1, 0, 0), 52.0, 10, 424242)

	# ---- light
	var env := WorldEnvironment.new()
	var e2 := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.16, 0.32, 0.66).lerp(Color(0.02, 0.03, 0.08), night)
	sm.sky_horizon_color = Color(0.80, 0.72, 0.60).lerp(Color(0.10, 0.09, 0.16), night)
	sm.ground_bottom_color = Color(0.12, 0.11, 0.10).lerp(Color(0.02, 0.02, 0.03), night)
	sm.ground_horizon_color = Color(0.66, 0.60, 0.50).lerp(Color(0.08, 0.07, 0.12), night)
	sky.sky_material = sm
	e2.sky = sky
	e2.background_mode = Environment.BG_SKY
	e2.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e2.ambient_light_energy = lerpf(0.95, 0.55, night)
	e2.tonemap_mode = Environment.TONE_MAPPER_ACES
	e2.tonemap_white = 4.0
	e2.fog_enabled = false
	env.environment = e2
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 48, 0)
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 2.3 * daylight
	sun.visible = daylight > 0.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.6
	add_child(sun)

	# Frame the crowd from where it actually is, not from a guess: print the
	# centroid and the extremes, then stand off it.
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for f in crowd.get_children():
		if f is Node3D:
			var wpp: Vector3 = (f as Node3D).global_position
			lo = Vector3(minf(lo.x, wpp.x), minf(lo.y, wpp.y), minf(lo.z, wpp.z))
			hi = Vector3(maxf(hi.x, wpp.x), maxf(hi.y, wpp.y), maxf(hi.z, wpp.z))
	print("SHOT crowd_bounds lo=", lo, " hi=", hi)
	var mid := (lo + hi) * 0.5
	var span: float = maxf(hi.x - lo.x, 4.0)
	var cam_positions := [
		mid + Vector3(-span * 0.55, 1.15, 5.5),
		mid + Vector3(-span * 0.30, 1.0, -5.0),
	]
	for pos in cam_positions:
		var c := Camera3D.new()
		c.position = pos
		add_child(c)
		c.look_at(Vector3(mid.x, 0.95, mid.z), Vector3.UP)
		c.fov = 58.0
		c.far = 400.0
		cams.append(c)
	cams[0].current = true
	print("SHOT ready crowd=", crowd.count(), " hour=", hour)

func _process(d):
	t += d
	if t > 1.6 + idx * 0.8 and idx < cams.size():
		var img := get_viewport().get_texture().get_image()
		if img:
			var path: String = prefix + "_" + str(idx) + ".png"
			img.save_png(path)
			print("SHOT ", path)
		idx += 1
		if idx < cams.size():
			cams[idx].current = true
	elif idx >= cams.size() and t > 1.6 + idx * 0.8 + 0.5:
		get_tree().quit()
