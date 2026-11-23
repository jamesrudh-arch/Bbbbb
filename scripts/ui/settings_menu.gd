extends Control
## SETTINGS — accessibility, controls and readability, reachable from the menu
## and from the pause screen. Every control writes straight to PlatformUI and
## saves, so a preference set once survives a restart.

signal closed

var _rows: VBoxContainer

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.05, 0.97)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 40
	scroll.offset_right = -40
	scroll.offset_top = 30
	scroll.offset_bottom = -96
	add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)

	_heading("READABILITY")
	_slider("Subtitle & dialogue size", 80, 140, int(PlatformUI.subtitle_size * 100.0),
		func(v): PlatformUI.subtitle_size = v / 100.0)

	_heading("ACCESSIBILITY")
	_toggle("High-contrast map markers", PlatformUI.high_contrast_blips,
		func(v): PlatformUI.high_contrast_blips = v)
	_toggle("Hold for heavy attack (instead of tap)", PlatformUI.hold_to_heavy,
		func(v): PlatformUI.hold_to_heavy = v)

	_heading("CONTROLS")
	_toggle("Left-handed layout", PlatformUI.one_hand_left,
		func(v): PlatformUI.one_hand_left = v)
	_toggle("Invert camera Y", PlatformUI.camera_invert_y,
		func(v): PlatformUI.camera_invert_y = v)
	_slider("Touch button size", 80, 140, int(PlatformUI.touch_scale * 100.0),
		func(v): PlatformUI.touch_scale = v / 100.0)
	_slider("Camera sensitivity", 50, 200, int(PlatformUI.camera_sensitivity * 100.0),
		func(v): PlatformUI.camera_sensitivity = v / 100.0)

	_heading("DIAGNOSTICS")
	var log_btn := Button.new()
	log_btn.text = "View session log"
	log_btn.custom_minimum_size = Vector2(0, 54)
	log_btn.pressed.connect(_show_log)
	_rows.add_child(log_btn)

	var back := Button.new()
	back.text = tr("BACK")
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.offset_left = 40
	back.offset_top = -78
	back.offset_right = 200
	back.offset_bottom = -22
	back.add_theme_font_size_override("font_size", 17)
	back.pressed.connect(func():
		PlatformUI.save_settings()
		closed.emit()
		queue_free())
	add_child(back)

func _heading(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.94, 0.76, 0.32))
	_rows.add_child(l)

func _toggle(label: String, value: bool, on_change: Callable) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = value
	b.text = _tick(value) + "  " + label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 16)
	b.toggled.connect(func(v):
		b.text = _tick(v) + "  " + label
		on_change.call(v))
	_rows.add_child(b)

func _tick(v: bool) -> String:
	return "■" if v else "□"

func _slider(label: String, lo: int, hi: int, value: int, on_change: Callable) -> void:
	var l := Label.new()
	l.text = "%s  —  %d%%" % [label, value]
	l.add_theme_font_size_override("font_size", 15)
	_rows.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 5
	s.value = value
	s.custom_minimum_size = Vector2(0, 44)
	s.value_changed.connect(func(v):
		l.text = "%s  —  %d%%" % [label, int(v)]
		on_change.call(v))
	_rows.add_child(s)

func _show_log() -> void:
	var ov := ColorRect.new()
	ov.color = Color(0.02, 0.02, 0.03, 0.98)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ov)
	var t := RichTextLabel.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.offset_left = 24
	t.offset_top = 24
	t.offset_right = -24
	t.offset_bottom = -90
	t.text = Crash.read_log()
	t.add_theme_font_size_override("normal_font_size", 12)
	ov.add_child(t)
	var c := Button.new()
	c.text = tr("CLOSE")
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.offset_left = -160
	c.offset_top = -70
	c.offset_right = -24
	c.offset_bottom = -24
	c.pressed.connect(func(): ov.queue_free())
	ov.add_child(c)
