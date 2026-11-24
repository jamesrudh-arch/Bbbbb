extends Node
## DISTRICT SHOT — render a built district so the art can be judged, with the
## sky and light set to match a specific hour of the day.
##
## This exists because the street harness renders a hand-placed street with its
## own fixed daylight, which cannot show whether night lighting, texture
## variation or the animated crowd actually read. This builds a real district
## through the real builder and streams in its crowd and light pools the way the
## streamer does, then photographs it.
##
##   DIST=neon_mile HOUR=22 SHOTS="name:x,y,z|lx,ly,lz;..." godot res://tests/districtshot.tscn
##   SHOT_PREFIX=/home/user/shots/night

var t := 0.0
var idx := 0
var done := false
var shots: Array = []
var prefix := "/home/user/shot"
var cams: Array = []

func _ready() -> void:
	var dist_id := OS.get_environment("DIST")
	if dist_id == "":
		dist_id = "neon_mile"
	var hour := float(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 21.0
	var pp := OS.get_environment("SHOT_PREFIX")
	if pp != "":
		prefix = pp
	var spec := OS.get_environment("SHOTS")
	if spec == "":
		# The road centre lines are at z = +-38 and x = +-38 (76 m pitch); a
		# camera anywhere else is inside a shopfront.
		spec = "street:6,1.7,38|-30,1.6,38"
	for chunk in spec.split(";"):
		var parts: PackedStringArray = chunk.split("|")
		var head: PackedStringArray = parts[0].split(":")
		var p: PackedStringArray = head[1].split(",")
		var l: PackedStringArray = parts[1].split(",")
		shots.append([head[0], Vector3(float(p[0]), float(p[1]), float(p[2])),
			Vector3(float(l[0]), float(l[1]), float(l[2]))])

	# ---- build the district for real
	var city = load("res://scripts/world/city_builder.gd").new()
	add_child(city)
	var d: Node3D = city.build_district(dist_id)
	add_child(d)
	# Free everything a shot cannot see: the GUI process has a memory ceiling
	# and a full district plus a framebuffer is past it. SHOT_KEEP=streets keeps
	# only the street geometry, which is what these shots are for.
	if OS.get_environment("SHOT_KEEP") == "streets":
		for c in d.get_children():
			var nm := str(c.name)
			if not (nm.begins_with("Street") or nm == "Sidewalks" or nm == "Roads" or nm == "AnimatedCrowd" or nm == "Landmarks"):
				c.free()
	# crowd + night pools, exactly as the streamer would on first sight
	city._spawn_street_people(d, dist_id)
	var sn = load("res://scripts/world/street_night.gd").new()
	sn.name = "StreetNight"
	d.add_child(sn)
	sn.build(d, Vector3.ZERO, 70.0, int(hash(dist_id)))

	# ---- sky and light at that hour
	var SN = load("res://scripts/world/street_night.gd")
	var night: float = SN.factor_for_hour(hour)
	var daylight: float = 1.0 - night
	sn.set_night(night)

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
	e2.ambient_light_sky_contribution = 1.0
	e2.ambient_light_energy = lerpf(0.95, 0.55, night)
	e2.tonemap_mode = Environment.TONE_MAPPER_ACES
	e2.tonemap_white = 4.0
	e2.glow_enabled = true
	e2.glow_intensity = lerpf(0.45, 0.95, night)
	e2.glow_bloom = 0.10
	# SSAO and 4-split sun shadows cost a lot of framebuffer memory; the shot
	# only needs to answer 'does the art read', so both are optional.
	e2.ssao_enabled = OS.get_environment("SHOT_SSAO") != ""
	e2.ssao_intensity = 1.2
	e2.ssao_radius = 1.4
	e2.fog_enabled = true
	e2.fog_light_color = Color(0.72, 0.68, 0.62).lerp(Color(0.06, 0.075, 0.11), night)
	e2.fog_density = lerpf(0.0035, 0.010, night)
	e2.fog_sky_affect = 0.2
	env.environment = e2
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 48, 0)
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 2.3 * daylight
	sun.visible = daylight > 0.05
	sun.shadow_enabled = OS.get_environment("SHOT_SHADOWS") != ""
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 110.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.6
	sun.shadow_blur = 1.6
	sun.light_angular_distance = 1.6
	add_child(sun)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, -130, 0)
	moon.light_color = Color(0.62, 0.70, 0.92)
	moon.light_energy = 0.45 * night
	moon.visible = night > 0.05
	add_child(moon)

	# ---- cameras
	for s2 in shots:
		var c := Camera3D.new()
		c.position = d.global_position + s2[1]
		add_child(c)
		c.look_at(d.global_position + s2[2], Vector3.UP)
		c.fov = 68.0
		c.far = 500.0
		cams.append(c)
	cams[0].current = true
	print("SHOT ready ", shots.size(), " cams district=", dist_id, " hour=", hour, " night=", night)

func _process(d):
	t += d
	if t > 1.8 + idx * 0.9 and not done:
		if idx < cams.size():
			var img := get_viewport().get_texture().get_image()
			if img:
				var path: String = prefix + "_" + str(shots[idx][0]) + ".png"
				img.save_png(path)
				print("SHOT ", path)
			idx += 1
			if idx < cams.size():
				cams[idx].current = true
			if idx >= cams.size():
				done = true
	if done and t > 1.8 + idx * 0.9 + 0.6:
		get_tree().quit()
