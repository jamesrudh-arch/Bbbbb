extends Node3D
## Renders one character through several clips in a single grid of viewports,
## so retargeting can be judged across the whole gameplay set at once.

const CLIPS := ["run", "run", "run", "run", "run", "run", "run", "run"]
var _char := "Michelle"
var _seek := 0.42
var _shot := ""

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--char="): _char = a.trim_prefix("--char=")
		elif a.begins_with("--shot="): _shot = a.trim_prefix("--shot=")
		elif a.begins_with("--seek="): _seek = float(a.trim_prefix("--seek="))
	_build()

func _build() -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grid)

	var seeks := [0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95, 1.1]
	for ci in CLIPS.size():
		var clip: String = CLIPS[ci]
		var vp := SubViewport.new()
		vp.size = Vector2i(480, 380)
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.msaa_3d = Viewport.MSAA_4X
		grid.add_child(vp)

		var root := Node3D.new()
		vp.add_child(root)
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.08, 0.085, 0.1)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.55, 0.6, 0.72)
		env.ambient_light_energy = 0.9
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)

		var key := DirectionalLight3D.new()
		key.rotation_degrees = Vector3(-35, 40, 0); key.light_energy = 2.2; key.shadow_enabled = true
		root.add_child(key)
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(-12, -118, 0); fill.light_energy = 0.9
		fill.light_color = Color(0.62, 0.74, 1.0); root.add_child(fill)

		var fl := MeshInstance3D.new()
		var pm := PlaneMesh.new(); pm.size = Vector2(8, 8); fl.mesh = pm
		var mm := StandardMaterial3D.new(); mm.albedo_color = Color(0.15, 0.155, 0.17); mm.roughness = 0.6
		fl.material_override = mm; root.add_child(fl)

		var cam := Camera3D.new(); cam.fov = 36.0
		root.add_child(cam)
		cam.look_at_from_position(Vector3(0.3, 1.15, 2.9), Vector3(0, 0.95, 0), Vector3.UP)

		var base: Node = (load("res://assets/characters/real/%s.glb" % _char) as PackedScene).instantiate()
		root.add_child(base)
		var ap: AnimationPlayer = base.find_children("*","AnimationPlayer",true,false)[0]
		var baked := "res://assets/characters/baked/%s.tres" % _char
		if ResourceLoader.exists(baked):
			ap.add_animation_library("mocap", load(baked))
			if ap.has_animation("mocap/" + clip):
				ap.play("mocap/" + clip)
				ap.seek(seeks[ci] if ci < seeks.size() else _seek, true)
		var lbl := Label.new()
		lbl.text = "%s @%.2f" % [clip, seeks[ci] if ci < seeks.size() else 0.0]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.position = Vector2(10, 6)
		vp.add_child(lbl)

	await get_tree().create_timer(2.2).timeout
	if _shot != "":
		var out := Image.create(480 * 4, 380 * 2, false, Image.FORMAT_RGBA8)
		for i in CLIPS.size():
			var vp: SubViewport = grid.get_child(i)
			var img: Image = vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, Vector2i(480, 380)),
				Vector2i((i % 4) * 480, (i / 4) * 380))
		out.save_png(_shot)
		print("SHOT_SAVED ", _shot)
	get_tree().quit()
