extends Control
## MAIN MENU — New Game / Continue / Load / Settings / Credits / Quit, over a
## procedurally drawn Cinder City skyline using each district's palette.

const GOLD := Color(0.92, 0.74, 0.42)
const GOLD_DIM := Color(0.62, 0.50, 0.30)
const TEXT := Color(0.94, 0.92, 0.88)
const TEXT_DIM := Color(0.66, 0.65, 0.62)

var _skyline: Control
var _menu_box: VBoxContainer
var _panel_root: Control
var _status: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_menu()
	Audio.play_ui("confirm")
	if OS.get_cmdline_user_args().has("--menuflow"):
		_auto_capture()

func _auto_capture() -> void:
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("/home/user/leverage/shots/open_04_menu.png")
		print("SHOT_SAVED menu")
	get_tree().quit()

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.048, 0.058)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var haze := Control.new()      # was ColorRect -> default white covered the scene
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.20, 0.10, 0.10, 0.55), Color(0.04, 0.05, 0.07, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_LINEAR
	gt.fill_from = Vector2(0.5, 1.0)
	gt.fill_to = Vector2(0.5, 0.45)
	var hz := TextureRect.new()
	hz.texture = gt
	hz.stretch_mode = TextureRect.STRETCH_SCALE
	hz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hz.set_anchors_preset(Control.PRESET_FULL_RECT)
	haze.add_child(hz)
	haze.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haze)
	_skyline = Control.new()
	_skyline.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Insert BELOW the haze and menu, and stretch with the window.
	add_child(_skyline)
	move_child(_skyline, 1)   # above the opaque base, below haze + menu
	_skyline.draw.connect(_draw_skyline)
	print("[MM] skyline size=", _skyline.size, " vp=", get_viewport_rect().size)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_skyline):
		_skyline.queue_redraw()

func _draw_skyline() -> void:
	var vp := _skyline.size
	if vp.x <= 0.0: return
	var rng := RandomNumberGenerator.new()
	rng.seed = 9182
	# opaque base so the skyline reads as night, never as a white default canvas
	_skyline.draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.035, 0.038, 0.048))
	for layer in 3:
		var base_y := vp.y * (0.58 + layer * 0.15)
		var col := Color(0.05 + layer * 0.022, 0.055 + layer * 0.022, 0.075 + layer * 0.022)
		var x := 0.0
		while x < vp.x:
			var bw := rng.randf_range(30, 96)
			var bh := rng.randf_range(60, 300) * (1.0 - layer * 0.2)
			_skyline.draw_rect(Rect2(x, base_y - bh, bw, bh + 400), col)
			if layer == 0:
				for wy in range(int(bh / 20)):
					for wx in range(int(bw / 18)):
						if rng.randf() > 0.42: continue
						var wc := Color(1.0, 0.88, 0.58, rng.randf_range(0.20, 0.75))
						_skyline.draw_rect(Rect2(x + 5 + wx * 18, base_y - bh + 10 + wy * 20, 4, 6), wc)
			x += bw + rng.randf_range(4, 16)

func _build_menu() -> void:
	var left := VBoxContainer.new()
	left.position = Vector2(84, 96)
	left.custom_minimum_size = Vector2(480, 0)
	left.add_theme_constant_override("separation", 6)
	add_child(left)

	var title := Label.new()
	title.text = tr("LEVERAGE")
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.60))
	left.add_child(title)

	var tag := Label.new()
	tag.text = tr("EVERYONE HAS LEVERAGE ON YOU.")
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", TEXT_DIM)
	left.add_child(tag)

	var rule := ColorRect.new()
	rule.color = Color(0.92, 0.74, 0.42, 0.45)
	rule.custom_minimum_size = Vector2(460, 2)
	left.add_child(rule)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	left.add_child(spacer)

	_menu_box = VBoxContainer.new()
	_menu_box.custom_minimum_size = Vector2(460, 0)
	_menu_box.add_theme_constant_override("separation", 7)
	left.add_child(_menu_box)
	_refresh_menu()

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", TEXT_DIM)
	_status.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_status.position = Vector2(84, -54)
	add_child(_status)
	_refresh_status()

var _panel_root_ref: Control

func _refresh_menu() -> void:
	for c in _menu_box.get_children(): c.queue_free()
	var items := []
	items.append(["NEW GAME", func(): _new_game()])
	if _any_save():
		items.append(["CONTINUE", func(): _continue_game()])
	items.append(["LOAD GAME", func(): _show_slots(false)])
	items.append(["SETTINGS", func(): _show_settings()])
	items.append(["CREDITS", func(): _show_credits()])
	items.append(["QUIT", func(): get_tree().quit()])
	for it in items:
		var b := _menu_button(it[0])
		var cb: Callable = it[1]
		b.pressed.connect(func():
			Audio.play_ui("click")
			cb.call()
		)
		_menu_box.add_child(b)

func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	b.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	b.add_theme_color_override("font_focus_color", TEXT)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.055, 0.06, 0.072, 0.92)
	n.corner_radius_top_left = 8
	n.corner_radius_top_right = 8
	n.corner_radius_bottom_left = 8
	n.corner_radius_bottom_right = 8
	n.content_margin_left = 20
	n.content_margin_right = 20
	n.content_margin_top = 9
	n.content_margin_bottom = 9
	n.border_width_left = 2
	n.border_color = Color(0.92, 0.74, 0.42, 0.22)
	b.add_theme_stylebox_override("normal", n)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.76, 0.60, 0.34, 1.0)
	h.corner_radius_top_left = 8
	h.corner_radius_top_right = 8
	h.corner_radius_bottom_left = 8
	h.corner_radius_bottom_right = 8
	h.content_margin_left = 20
	h.content_margin_right = 20
	h.content_margin_top = 9
	h.content_margin_bottom = 9
	h.border_width_left = 2
	h.border_color = Color(1.0, 0.88, 0.62, 0.9)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	return b

func _any_save() -> bool:
	for i in Game.SLOT_COUNT:
		if not Game.slot_info(i).is_empty(): return true
	return false

func _refresh_status() -> void:
	if _status == null: return
	var s := "Cinder City · Godot %s · Mobile renderer" % Engine.get_version_info()["string"]
	var latest := -1
	for i in Game.SLOT_COUNT:
		var info := Game.slot_info(i)
		if not info.is_empty():
			if latest < 0 or str(info["saved_at"]) > str(Game.slot_info(latest).get("saved_at", "")):
				latest = i
	if latest >= 0:
		var info2 := Game.slot_info(latest)
		s += "\nLast save: slot %d · %s · %s" % [latest + 1, info2["district"], _money(int(info2["money"]))]
	_status.text = s

func _money(n: int) -> String:
	return "₦" + str(n)

func _new_game() -> void:
	Game.reset_new_game()
	Loader.goto_world(true)

func _continue_game() -> void:
	var latest := -1
	for i in Game.SLOT_COUNT:
		var info := Game.slot_info(i)
		if info.is_empty(): continue
		if latest < 0 or str(info["saved_at"]) > str(Game.slot_info(latest).get("saved_at", "")):
			latest = i
	if latest >= 0 and Game.load_game(latest):
		Loader.goto_world(false)

func _show_slots(save_mode: bool) -> void:
	_clear_panel()
	var p := _panel(Vector2(-300, -240), Vector2(600, 480))
	_panel_root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var h := Label.new()
	h.text = tr("LOAD GAME") if not save_mode else "SAVE GAME"
	h.add_theme_font_size_override("font_size", 22)
	h.add_theme_color_override("font_color", GOLD)
	v.add_child(h)
	for i in Game.SLOT_COUNT:
		var info := Game.slot_info(i)
		var b := _menu_button("")
		if info.is_empty():
			b.text = tr("SLOT %d — empty") % (i + 1)
			b.disabled = save_mode == false
		else:
			b.text = tr("SLOT %d — %s  ·  %s  ·  %s") % [i + 1, info["saved_at"], info["district"], _money(int(info["money"]))]
		var slot := i
		b.pressed.connect(func():
			if save_mode:
				Game.save_game(slot)
				_show_slots(true)
			else:
				if Game.load_game(slot):
					Loader.goto_world(false)
		)
		v.add_child(b)
	if save_mode:
		var hint := Label.new()
		hint.text = tr("Saving in the world is also available from the pause menu.")
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", TEXT_DIM)
		v.add_child(hint)
	var back := _menu_button("BACK")
	back.pressed.connect(func(): _clear_panel())
	v.add_child(back)

func _show_settings() -> void:
	_clear_panel()
	var p := _panel(Vector2(-280, -230), Vector2(560, 460))
	_panel_root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var h := Label.new()
	h.text = tr("SETTINGS")
	h.add_theme_font_size_override("font_size", 22)
	h.add_theme_color_override("font_color", GOLD)
	v.add_child(h)
	for pair in [["Master volume", "master_volume"], ["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var l := Label.new()
		l.text = pair[0]
		l.custom_minimum_size = Vector2(140, 0)
		l.add_theme_color_override("font_color", TEXT)
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(Audio.get(pair[1]))
		sl.custom_minimum_size = Vector2(300, 26)
		var prop: String = pair[1]
		sl.value_changed.connect(func(val):
			Audio.set(prop, val)
			Audio.apply_volume()
		)
		row.add_child(sl)
		v.add_child(row)
	var info := Label.new()
	info.text = "Renderer: Mobile (Vulkan / Metal)\nTarget: iPhone via XOGOT\nResolution scales automatically to protect frame rate."
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", TEXT_DIM)
	v.add_child(info)
	var back := _menu_button("BACK")
	back.pressed.connect(func(): _clear_panel())
	v.add_child(back)

func _show_credits() -> void:
	_clear_panel()
	var p := _panel(Vector2(-380, -270), Vector2(760, 560))
	_panel_root.add_child(p)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 480)
	p.add_child(scroll)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(700, 0)
	v.add_theme_constant_override("separation", 8)
	scroll.add_child(v)
	var credits := """
LEVERAGE
"Everybody has something on you."

A D'Youngs Games production. Built in Godot 4.7.2.

DESIGN & CODE
Game design, systems programming, procedural world generation,
UI, AI and all gameplay code are original to LEVERAGE.
Copyright (c) 2026 D'Youngs Games. All rights reserved.

CHARACTER MODELS
Soldier, Michelle and Xbot from the three.js examples collection.
Copyright (c) 2010-2026 three.js authors. MIT Licence.
Retargeted and re-materialled for this project.

ANIMATION
Motion capture clips from Mixamo (Adobe), retargeted from the
mixamorig skeleton and baked to the project rig.

VEHICLES & PROPS
Kenney Car Kit. CC0 public domain.

SURFACES
Poly Haven 1K texture sets. CC0 public domain.

AUDIO
Every sound effect, music loop and ambience bed was synthesized
from first principles for this project (tools/gen_audio.py).
No third-party samples are used, so the audio set carries no
licensing obligations.

FONTS
Godot default theme fonts (open licence).

TOOLS
Godot Engine 4.7.2 - MIT Licence.
Copyright (c) 2014-2026 Juan Linietsky, Ariel Manzur and the
Godot Engine contributors.
glTF Transform + meshoptimizer for asset normalisation.

ENGINE NOTICE
Permission is hereby granted, free of charge, to any person
obtaining a copy of the Godot Engine software and associated
documentation files, to deal in the Software without
restriction, subject to inclusion of this notice.

SPECIAL THANKS
Everyone who ever said "just ship it".

(c) 2026 D'Youngs Games.
"""
	var l := Label.new()
	l.text = credits
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(690, 0)
	v.add_child(l)
	# Back button lives outside the scroll so it is always reachable.
	var back2 := _menu_button(tr("BACK"))
	back2.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	back2.position = Vector2(-260, -90)
	back2.custom_minimum_size = Vector2(200, 0)
	_panel_root.add_child(back2)
	back2.pressed.connect(func(): _clear_panel())

func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = pos
	p.custom_minimum_size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.045, 0.05, 0.062, 0.97)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.92, 0.74, 0.42, 0.24)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _clear_panel() -> void:
	if _panel_root != null and is_instance_valid(_panel_root):
		_panel_root.queue_free()
	_panel_root = null
	_panel_root = Control.new()
	_panel_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_root)
	# keep menu interactive under the overlay
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)

func _process(_d: float) -> void:
	# Background music on the menu (soft, from the same synthetic bed).
	pass
