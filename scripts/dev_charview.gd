extends Node3D
## Renders several realistic characters side by side with a Mixamo clip.

var _shot := ""
var _anim := "idle"
var _chars: Array = ["Michelle"]

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var s: String = a
		if s.begins_with("--shot="): _shot = s.trim_prefix("--shot=")
		elif s.begins_with("--anim="): _anim = s.trim_prefix("--anim=")
		elif s.begins_with("--chars="): _chars = Array(s.trim_prefix("--chars=").split(","))
	_build()

func _build() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.075, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.56, 0.68)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 42, 0)
	key.light_energy = 2.4
	key.light_color = Color(1.0, 0.94, 0.86)
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-14, -120, 0)
	fill.light_energy = 0.8
	fill.light_color = Color(0.62, 0.74, 1.0)
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-6, 178, 0)
	rim.light_energy = 1.6
	rim.light_color = Color(0.8, 0.88, 1.0)
	add_child(rim)

	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(30, 30)
	floor_mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.13, 0.135, 0.15); m.roughness = 0.6
	floor_mi.material_override = m
	add_child(floor_mi)

	var cam := Camera3D.new()
	cam.fov = 34.0
	add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.25, 3.4), Vector3(0, 1.0, 0), Vector3.UP)

	var x := -1.9
	for ch in _chars:
		var base: Node = (load("res://assets/characters/real/%s.glb" % ch) as PackedScene).instantiate()
		add_child(base)
		base.position = Vector3(x, 0, 0)
		x += 1.9
		var ap: AnimationPlayer = base.find_children("*","AnimationPlayer",true,false)[0]
		var baked := "res://assets/characters/baked/%s.tres" % ch
		if ResourceLoader.exists(baked):
			ap.add_animation_library("mocap", load(baked))
			if ap.has_animation("mocap/" + _anim):
				ap.play("mocap/" + _anim)
				ap.seek(0.35, true)
				print("[CV] ", ch, " -> mocap/", _anim)
			else:
				print("[CV] ", ch, " missing clip")
		else:
			print("[CV] ", ch, " NO BAKED")
	await get_tree().create_timer(1.4).timeout
	if _shot != "":
		get_viewport().get_texture().get_image().save_png(_shot)
		print("SHOT_SAVED ", _shot)
	get_tree().quit()
