extends Control
## BOOT — D'Youngs Games presentation -> LEVERAGE title -> content notice -> menu.
## Implemented as an explicit stage machine (stage 0..3) rather than a chain of
## awaits: each stage owns its own timer and a single advance() transition.

const NOTICE_FILE := "user://notice_seen.save"
const STUDIO_LOGO := preload("res://scripts/ui/studio_logo.gd")
const STAGE_DURATION := [0.0, 2.8, 0.0, 0.0]  # 0 = driven by the 3D logo signal

var _stage := 0
var _timer := 0.0
var _accum := 0.0
var _fading := false
var _stage_root: Control
var _skip_hint: Label
var _notice_panel: Control
var _studio_logo: Node3D

func _ready() -> void:
	_stage_root = Control.new()
	_stage_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_stage_root)
	_show_stage(0)
	# Capture mode: `--openflow` walks studio -> title -> notice and screenshots each.
	if OS.get_cmdline_user_args().has("--openflow"):
		_auto_capture()

func _auto_capture() -> void:
	var out_dir := "user://"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
	var names := ["open_01_studio", "open_02_title", "open_03_notice"]
	var waits := [3.9, 0.9, 0.9]   # the studio mark needs its full 3.5 s reveal
	for i in 3:
		_show_stage(i)
		await get_tree().create_timer(waits[i]).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		if img != null:
			var path: String = out_dir.path_join(names[i] + ".png")
			img.save_png(path)
			print("SHOT_SAVED ", path, " stage=", _stage)
	get_tree().quit()

func _show_stage(stage: int) -> void:
	for c in _stage_root.get_children():
		c.queue_free()
	_timer = 0.0
	_stage = stage
	match stage:
		0: _build_studio()
		1: _build_title()
		2: _build_notice()
		3: _depart()

func _build_studio() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.014, 0.016, 0.021)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_root.add_child(bg)

	# Real 3D: the mark is extruded geometry with a metallic material.
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_root.add_child(svc)

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)

	var logo: Node3D = STUDIO_LOGO.new()
	vp.add_child(logo)
	logo.finished.connect(func(): _advance())
	_studio_logo = logo

func _build_title() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.037, 0.045)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_root.add_child(bg)
	var skyline := Control.new()
	skyline.set_anchors_preset(Control.PRESET_FULL_RECT)
	skyline.draw.connect(func(): _draw_skyline(skyline))
	_stage_root.add_child(skyline)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-450, -110)
	center.custom_minimum_size = Vector2(900, 0)
	center.add_theme_constant_override("separation", 4)
	_stage_root.add_child(center)
	var title := Label.new()
	title.text = tr("LEVERAGE")
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.60))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var tag := Label.new()
	tag.text = tr("EVERYBODY HAS SOMETHING ON YOU.")
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color(0.62, 0.60, 0.56))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(tag)
	var tw := create_tween()
	center.modulate.a = 0.0
	tw.tween_property(center, "modulate:a", 1.0, 0.9)

func _draw_skyline(c: Control) -> void:
	var vp := c.size
	if vp.x <= 0: return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for layer in 3:
		var base_y := vp.y * (0.62 + layer * 0.12)
		var col := Color(0.055 + layer * 0.02, 0.06 + layer * 0.02, 0.08 + layer * 0.02)
		var x := 0.0
		while x < vp.x:
			var bw := rng.randf_range(36, 92)
			var bh := rng.randf_range(70, 260) * (1.0 - layer * 0.15)
			c.draw_rect(Rect2(x, base_y - bh, bw, bh + 200), col)
			if layer == 0:
				for wy in range(int(bh / 22)):
					for wx in range(int(bw / 20)):
						if rng.randf() > 0.45: continue
						var wc := Color(1.0, 0.86, 0.55, rng.randf_range(0.25, 0.8))
						c.draw_rect(Rect2(x + 6 + wx * 20, base_y - bh + 12 + wy * 22, 5, 7), wc)
			x += bw + rng.randf_range(6, 18)

func _build_notice() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.032, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_root.add_child(bg)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.065, 0.078, 0.98)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.92, 0.74, 0.42, 0.22)
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-360, -220)
	p.custom_minimum_size = Vector2(720, 0)
	_stage_root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var h := Label.new()
	h.text = tr("CONTENT NOTICE")
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(0.92, 0.74, 0.42))
	v.add_child(h)
	var body := Label.new()
	body.text = "LEVERAGE is a work of fiction set in the invented city of Cinder City.\n\n" \
		+ "It contains depictions of street violence, crime, and organised intimidation. " \
		+ "There is no graphic gore and no sexual content.\n\n" \
		+ "All characters, factions, businesses and events are fictional. Any resemblance " \
		+ "to real people or organisations is coincidental.\n\n" \
		+ "The game contains no loot boxes, no gambling mechanics and no in-app purchases."
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.85, 0.84, 0.80))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(650, 0)
	v.add_child(body)
	var accept := Button.new()
	accept.text = tr("I UNDERSTAND")
	accept.add_theme_font_size_override("font_size", 16)
	accept.pressed.connect(func(): _save_notice(); _advance())
	v.add_child(accept)
	var tw := create_tween()
	p.modulate.a = 0.0
	tw.tween_property(p, "modulate:a", 1.0, 0.4)

func _save_notice() -> void:
	var f := FileAccess.open(NOTICE_FILE, FileAccess.WRITE)
	if f:
		f.store_string("seen")
		f.close()

func _depart() -> void:
	# A first-run session goes straight into the opening cinematic; returning
	# players who have already seen it land on the menu instead.
	if SaveFlags.opening_seen():
		Loader.goto_scene("res://scenes/main_menu.tscn", 0.4)
	else:
		Loader.goto_scene("res://scenes/opening.tscn", 0.4)

func _advance() -> void:
	if _fading: return
	_fading = true
	if _stage == 1:
		_show_stage(2)
		_fading = false
		return
	_show_stage(mini(_stage + 1, 3))
	_fading = false

func _process(delta: float) -> void:
	if _stage >= 2 or _fading: return
	var dur := float(STAGE_DURATION[_stage])
	if dur <= 0.0:
		return          # stage owns its own timing (e.g. the 3D logo signal)
	_accum += delta
	if _accum >= dur:
		_accum = 0.0
		_show_stage(_stage + 1)

func _unhandled_input(event: InputEvent) -> void:
	if _stage >= 2: return
	if event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		_advance()
	elif event is InputEventMouseButton and event.pressed:
		_advance()
