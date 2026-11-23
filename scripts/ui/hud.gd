extends CanvasLayer

const MAP_VIEW := preload("res://scripts/ui/world_map.gd")
const PHONE_VIEW := preload("res://scripts/ui/phone.gd")
## HUD — touch-first interface for iPhone/XOGOT.
## Layout is anchored in a 1280x720 safe design space (canvas_items stretch), so
## every control keeps its physical size and thumb reach across iPhone sizes.
## Controls: left thumb = analog stick, right thumb = X/Y/A/B diamond, right edge
## = camera/utility, top = status. Nothing overlaps the gameplay focal point.

const GOLD := Color(0.92, 0.74, 0.42)
const GOLD_DIM := Color(0.62, 0.50, 0.30)
const INK := Color(0.055, 0.06, 0.075, 0.88)
const INK_SOFT := Color(0.08, 0.09, 0.11, 0.78)
const TEXT := Color(0.94, 0.92, 0.88)
const TEXT_DIM := Color(0.66, 0.65, 0.62)
const DANGER := Color(0.94, 0.36, 0.30)
const HEALTH := Color(0.85, 0.32, 0.30)
const STAMINA := Color(0.42, 0.76, 0.52)

var world: Node3D
var root: Control

# ---------- status widgets ----------
var district_label: Label
var clock_label: Label
## Vertical inset below the very top of the screen. XOGOT renders its own overlay
## bar across the top; the iPhone status bar/notch occupies the same band. Everything
## in the HUD must start below this or it is unreadable and untappable.
const TOP_INSET := 74.0

var money_label: Label
var mission_title: Label
var mission_obj: Label
var mission_box: PanelContainer
var heat_bar: ProgressBar
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var wanted_pips: Array[ColorRect] = []
var discipline_label: Label
var interact_panel: PanelContainer
var interact_label: Label
var notify_box: VBoxContainer
var dialogue_panel: PanelContainer
var dialogue_name: Label
var dialogue_text: Label
var choice_panel: PanelContainer
var choice_list: VBoxContainer
var compass: Control
var minimap: Control
var indoor_label: Label
var vehicle_panel: PanelContainer
var vehicle_speed: Label
var weapon_label: Label
var ammo_label: Label

# ---------- joystick ----------
var stick_base: Control
var stick_knob: Control
var _stick_active := false
var _stick_id := -1
var _stick_center := Vector2.ZERO
var _stick_vec := Vector2.ZERO

# ---------- buttons ----------
var btn_x: Button
var btn_y: Button
var btn_a: Button
var btn_b: Button
var btn_pause: Button
var btn_map: Button
var btn_phone: Button
var btn_cam: Button

var _offer_callback: Callable
var _offer_panel: PanelContainer
var _dialogue_timer := 0.0
var _menu: Control
var _shop: Control
var _phone: Control
var _mapview: Control

func setup(w: Node3D) -> void:
	world = w
	_build()

func _ready() -> void:
	pass

# ============================================================== construction
func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_status()
	_build_mission()
	_build_right_actions()
	_build_stick()
	_build_combat_buttons()
	_build_prompts()
	_build_compass()
	_build_vehicle_panel()
	_build_menu()
	_build_shop()
	_build_phone()

# ---------------------------------------------------------------- helpers
func _panel(bg: Color = INK, radius: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.92, 0.74, 0.42, 0.18)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _label(text: String, size: int = 15, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _bar(color: Color, height: float = 10.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = 100.0
	b.value = 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(220, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.10, 0.12, 0.85)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.corner_radius_top_left = 3
	fg.corner_radius_top_right = 3
	fg.corner_radius_bottom_left = 3
	fg.corner_radius_bottom_right = 3
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

func _btn(text: String, size: int = 15) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	var n := StyleBoxFlat.new()
	n.bg_color = INK_SOFT
	n.corner_radius_top_left = 10
	n.corner_radius_top_right = 10
	n.corner_radius_bottom_left = 10
	n.corner_radius_bottom_right = 10
	n.content_margin_left = 16
	n.content_margin_right = 16
	n.content_margin_top = 10
	n.content_margin_bottom = 10
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.16, 0.14, 0.10, 0.95)
	h.border_width_left = 1
	h.border_width_top = 1
	h.border_width_right = 1
	h.border_width_bottom = 1
	h.border_color = GOLD_DIM
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	return b

# ---------------------------------------------------------------- status
func _build_status() -> void:
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(20, TOP_INSET)
	top_left.add_theme_constant_override("separation", 8)
	root.add_child(top_left)

	var dist_panel := _panel()
	top_left.add_child(dist_panel)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 0)
	dist_panel.add_child(dv)
	district_label = _label("ASH ROW", 21, GOLD)
	dv.add_child(district_label)
	clock_label = _label("16:30 · CLEAR · 18°", 12, TEXT_DIM)
	dv.add_child(clock_label)

	# health / stamina bars
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 4)
	bars.custom_minimum_size = Vector2(220, 0)
	top_left.add_child(bars)
	health_bar = _bar(HEALTH)
	bars.add_child(health_bar)
	stamina_bar = _bar(STAMINA)
	stamina_bar.custom_minimum_size = Vector2(220, 7)
	bars.add_child(stamina_bar)

	# wanted pips
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	top_left.add_child(pips)
	wanted_pips.clear()
	for i in 4:
		var r := ColorRect.new()
		r.color = Color(0.25, 0.22, 0.20, 0.9)
		r.custom_minimum_size = Vector2(26, 5)
		pips.add_child(r)
		wanted_pips.append(r)

	# top right: money + heat + weapon
	var top_right := VBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-286, TOP_INSET)
	top_right.custom_minimum_size = Vector2(256, 0)
	top_right.add_theme_constant_override("separation", 8)
	root.add_child(top_right)

	var money_panel := _panel()
	top_right.add_child(money_panel)
	var mh := VBoxContainer.new()
	mh.add_theme_constant_override("separation", 0)
	money_panel.add_child(mh)
	money_label = _label("₦120", 26, Color(0.86, 0.94, 0.80))
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mh.add_child(money_label)
	discipline_label = _label("BRAWLER", 11, GOLD_DIM)
	discipline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mh.add_child(discipline_label)

	var heat_panel := _panel()
	top_right.add_child(heat_panel)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	heat_panel.add_child(hv)
	var hl := _label("HEAT", 10, TEXT_DIM)
	hv.add_child(hl)
	heat_bar = _bar(DANGER, 8)
	heat_bar.max_value = 100.0
	heat_bar.value = 0.0
	heat_bar.custom_minimum_size = Vector2(228, 8)
	hv.add_child(heat_bar)

	# Gear line sits inside the money panel so nothing floats mid-screen.
	var gear_row := HBoxContainer.new()
	gear_row.add_theme_constant_override("separation", 8)
	mh.add_child(gear_row)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_row.add_child(sp2)
	weapon_label = _label("FISTS", 11, TEXT_DIM)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gear_row.add_child(weapon_label)
	ammo_label = _label("", 11, GOLD_DIM)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gear_row.add_child(ammo_label)

# ---------------------------------------------------------------- mission
func _build_mission() -> void:
	mission_box = _panel()
	mission_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mission_box.position = Vector2(-190, TOP_INSET)
	mission_box.custom_minimum_size = Vector2(380, 0)
	root.add_child(mission_box)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 2)
	mission_box.add_child(mv)
	mission_title = _label("HOMECOMING", 16, GOLD)
	mv.add_child(mission_title)
	mission_obj = _label("Walk to Mama Ngozi's Kitchen", 13, TEXT)
	mission_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mv.add_child(mission_obj)

# ---------------------------------------------------------------- compass
func _build_compass() -> void:
	compass = Control.new()
	compass.set_anchors_preset(Control.PRESET_CENTER_TOP)
	compass.position = Vector2(-170, TOP_INSET + 82.0)
	compass.custom_minimum_size = Vector2(340, 26)
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(compass)
	compass.draw.connect(_draw_compass)

func _draw_compass() -> void:
	if world == null or world.player == null: return
	var w := 340.0
	var yaw: float = world.player.camera_rig.yaw
	var cx := w * 0.5
	compass.draw_rect(Rect2(0, 10, w, 3), Color(0.1, 0.1, 0.12, 0.55))
	var dirs := [["N", 0.0], ["E", PI * 0.5], ["S", PI], ["W", -PI * 0.5]]
	for d in dirs:
		var rel: float = wrapf(d[1] - yaw, -PI, PI)
		if absf(rel) > 1.2: continue
		var x := cx + rel * 120.0
		compass.draw_line(Vector2(x, 6), Vector2(x, 16), GOLD if absf(rel) < 0.1 else GOLD_DIM, 2.0)
		var font := ThemeDB.fallback_font
		compass.draw_string(font, Vector2(x - 4, 26), d[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			GOLD if absf(rel) < 0.1 else TEXT_DIM)
	# objective marker
	var obj = Game.current_objective()
	if not obj.is_empty() and world.missions != null:
		var target: String = str(obj.get("target", ""))
		var pos: Vector3 = world.missions._target_position(target)
		if pos != Vector3.INF:
			var to: Vector3 = pos - world.player.global_position
			var ang := atan2(to.x, to.z)
			var rel2: float = wrapf(ang - yaw, -PI, PI)
			if absf(rel2) < 1.2:
				var mx := cx + rel2 * 120.0
				compass.draw_circle(Vector2(mx, 12), 4.0, GOLD)
			else:
				var ex := 8.0 if rel2 < 0 else w - 8.0
				compass.draw_circle(Vector2(ex, 12), 5.0, GOLD)
				var font2 := ThemeDB.fallback_font
				compass.draw_string(font2, Vector2(ex - 3, 26), "»" if rel2 > 0 else "«",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)

# ---------------------------------------------------------------- joystick
func _build_stick() -> void:
	stick_base = Control.new()
	stick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick_base.position = Vector2(52, -252)
	stick_base.custom_minimum_size = Vector2(190, 190)
	stick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(stick_base)
	stick_base.draw.connect(_draw_stick)
	stick_base.gui_input.connect(_stick_input)

	stick_knob = Control.new()
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_base.add_child(stick_knob)
	stick_knob.draw.connect(func():
		stick_knob.draw_circle(Vector2(38, 38), 36.0, Color(0.85, 0.68, 0.40, 0.85))
		stick_knob.draw_circle(Vector2(38, 38), 30.0, Color(0.95, 0.80, 0.55, 0.95))
	)
	stick_knob.position = Vector2(57, 57)

func _draw_stick() -> void:
	stick_base.draw_circle(Vector2(95, 95), 92.0, Color(0.06, 0.07, 0.09, 0.42))
	stick_base.draw_arc(Vector2(95, 95), 92.0, 0, TAU, 48, Color(0.92, 0.74, 0.42, 0.20), 2.0)
	stick_base.draw_circle(Vector2(95, 95), 40.0, Color(0.1, 0.11, 0.13, 0.30))

func _stick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _stick_id < 0:
			_stick_id = event.index
			_stick_center = event.position - stick_base.global_position - Vector2(95, 95)
			_stick_active = true
		elif not event.pressed and event.index == _stick_id:
			_stick_id = -1
			_stick_active = false
			_stick_vec = Vector2.ZERO
			stick_knob.position = Vector2(57, 57)
			_release_move()
	elif event is InputEventScreenDrag and event.index == _stick_id:
		var rel: Vector2 = event.position - stick_base.global_position - Vector2(95, 95)
		var v := rel / 62.0
		if v.length() > 1.0: v = v.normalized()
		_stick_vec = v
		stick_knob.position = Vector2(95, 95) + v * 62.0 - Vector2(38, 38)
		_apply_move(v)

func _apply_move(v: Vector2) -> void:
	Input.action_release("move_left"); Input.action_release("move_right")
	Input.action_release("move_forward"); Input.action_release("move_back")
	if v.x < -0.22: Input.action_press("move_left", -v.x)
	if v.x > 0.22: Input.action_press("move_right", v.x)
	if v.y < -0.22: Input.action_press("move_forward", -v.y)
	if v.y > 0.22: Input.action_press("move_back", v.y)
	if v.length() > 0.88: Input.action_press("sprint", 1.0)
	else: Input.action_release("sprint")

func _release_move() -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back", "sprint"]:
		Input.action_release(a)

# ---------------------------------------------------------------- combat buttons
func _build_combat_buttons() -> void:
	# The required diamond: X punch (top-left), Y heavy (top-right),
	# A kick (bottom-right), B dodge/interact (bottom-left).
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.position = Vector2(-352, -300)
	anchor.custom_minimum_size = Vector2(330, 285)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(anchor)

	btn_x = _action_button("X", Color(0.62, 0.30, 0.24), Vector2(6, 62))
	btn_y = _action_button("Y", Color(0.62, 0.52, 0.22), Vector2(126, 24))
	btn_a = _action_button("A", Color(0.24, 0.44, 0.30), Vector2(176, 152))
	btn_b = _action_button("B", Color(0.24, 0.34, 0.56), Vector2(56, 168))
	for b in [btn_x, btn_y, btn_a, btn_b]:
		anchor.add_child(b)

func _action_button(label_text: String, tint: Color, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = label_text
	b.position = pos
	b.custom_minimum_size = Vector2(96, 96)
	b.size = Vector2(96, 96)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(tint.r, tint.g, tint.b, 0.72)
	n.corner_radius_top_left = 48
	n.corner_radius_top_right = 48
	n.corner_radius_bottom_left = 48
	n.corner_radius_bottom_right = 48
	n.border_width_left = 2
	n.border_width_top = 2
	n.border_width_right = 2
	n.border_width_bottom = 2
	n.border_color = Color(tint.r + 0.25, tint.g + 0.25, tint.b + 0.25, 0.9)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(tint.r + 0.12, tint.g + 0.12, tint.b + 0.12, 0.92)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	# Touch press/release maps onto the same InputMap actions the keyboard uses.
	# IMPORTANT: Input.action_press() does NOT emit is_action_just_pressed edges in
	# Godot 4, so combat.gd (which only listens for just_pressed) never saw touch
	# input. parse_input_event() drives the real pipeline and does produce the edge.
	b.button_down.connect(func(): _fire_action(_action_for(label_text)))
	return b

## Dispatch a one-frame action press through the real input pipeline.
func _fire_action(action: String) -> void:
	if action.is_empty(): return
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	# Hold for a fixed short window before releasing. A deferred release could flush
	# in the same frame as the press, meaning is_action_just_pressed() was never
	# observed and the attack silently did nothing.
	_release_after(action, 0.06)

func _release_after(action: String, secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)

func _action_for(face: String) -> String:
	# B doubles as interact outside combat (see interaction.gd) — but the raw
	# button press must dispatch to both systems, so it presses "dodge" while a
	# fight is live and "interact" otherwise.
	if face == "X": return "punch"
	if face == "Y": return "heavy"
	if face == "A": return "kick"
	if face == "B":
		if world != null and world.player != null and world.player.combat != null \
				and world.player.combat.in_combat:
			return "dodge"
		return "interact"
	return "punch"

# ---------------------------------------------------------------- right actions
func _build_right_actions() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	col.position = Vector2(-286, 200)
	col.add_theme_constant_override("separation", 10)
	root.add_child(col)

	btn_pause = _round_btn("||", Color(0.16, 0.17, 0.20), func(): toggle_menu())
	col.add_child(btn_pause)
	btn_map = _round_btn("MAP", Color(0.16, 0.17, 0.20), func(): toggle_map())
	col.add_child(btn_map)
	btn_phone = _round_btn("TEL", Color(0.16, 0.17, 0.20), func(): toggle_phone())
	col.add_child(btn_phone)
	btn_cam = _round_btn("CAM", Color(0.16, 0.17, 0.20), func(): _cycle_camera())
	col.add_child(btn_cam)

func _round_btn(text: String, tint: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	# Pill geometry: wide enough for a 3-letter label, still thumb-sized (>=54pt).
	var w: float = 74.0 if text.length() > 1 else 54.0
	b.custom_minimum_size = Vector2(w, 54)
	b.size = Vector2(w, 54)
	b.add_theme_font_size_override("font_size", 15 if text.length() > 1 else 22)
	b.add_theme_color_override("font_color", Color(0.9, 0.88, 0.84))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(tint.r, tint.g, tint.b, 0.70)
	var r: float = 27.0
	n.corner_radius_top_left = r
	n.corner_radius_top_right = r
	n.corner_radius_bottom_left = r
	n.corner_radius_bottom_right = r
	n.border_width_left = 1
	n.border_width_top = 1
	n.border_width_right = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.92, 0.74, 0.42, 0.28)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.pressed.connect(func():
		Audio.play_ui("click")
		cb.call()
	)
	return b

func _cycle_camera() -> void:
	if world == null: return
	var rig = world.player.camera_rig
	rig.yaw += PI * 0.5

# ---------------------------------------------------------------- prompts
func _build_prompts() -> void:
	interact_panel = _panel(Color(0.05, 0.06, 0.07, 0.82))
	interact_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interact_panel.position = Vector2(-150, -170)
	interact_panel.custom_minimum_size = Vector2(300, 0)
	interact_panel.visible = false
	root.add_child(interact_panel)
	interact_label = _label("Talk", 15, GOLD)
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_panel.add_child(interact_label)

	# notifications stack (right of the stick)
	notify_box = VBoxContainer.new()
	notify_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	notify_box.position = Vector2(300, -300)
	notify_box.custom_minimum_size = Vector2(360, 0)
	notify_box.add_theme_constant_override("separation", 6)
	root.add_child(notify_box)

	# dialogue
	dialogue_panel = _panel(Color(0.045, 0.05, 0.062, 0.95), 16)
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-330, -128)
	dialogue_panel.custom_minimum_size = Vector2(660, 0)
	dialogue_panel.visible = false
	root.add_child(dialogue_panel)
	var dvv := VBoxContainer.new()
	dvv.add_theme_constant_override("separation", 4)
	dialogue_panel.add_child(dvv)
	dialogue_name = _label("MAMA NGOZI", 15, GOLD)
	dvv.add_child(dialogue_name)
	dialogue_text = _label("", 14, TEXT)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dvv.add_child(dialogue_text)

	# choices
	choice_panel = _panel(Color(0.045, 0.05, 0.062, 0.96), 16)
	choice_panel.set_anchors_preset(Control.PRESET_CENTER)
	choice_panel.position = Vector2(-300, -170)
	choice_panel.custom_minimum_size = Vector2(600, 0)
	choice_panel.visible = false
	root.add_child(choice_panel)
	choice_list = VBoxContainer.new()
	choice_list.add_theme_constant_override("separation", 8)
	choice_panel.add_child(choice_list)

	# mission offer
	_offer_panel = _panel(Color(0.06, 0.07, 0.085, 0.95), 16)
	_offer_panel.set_anchors_preset(Control.PRESET_CENTER)
	_offer_panel.position = Vector2(-230, 60)
	_offer_panel.custom_minimum_size = Vector2(460, 0)
	_offer_panel.visible = false
	root.add_child(_offer_panel)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 8)
	_offer_panel.add_child(ov)
	var otitle := _label("NEW JOB AVAILABLE", 12, GOLD_DIM)
	ov.add_child(otitle)
	var obody := _label("", 15, TEXT)
	obody.name = "Body"
	ov.add_child(obody)
	var obuttons := HBoxContainer.new()
	obuttons.add_theme_constant_override("separation", 10)
	ov.add_child(obuttons)
	var accept := _btn("ACCEPT", 14)
	accept.pressed.connect(func(): _accept_offer())
	obuttons.add_child(accept)
	var later := _btn("LATER", 14)
	later.pressed.connect(func(): _offer_panel.visible = false)
	obuttons.add_child(later)

	indoor_label = _label("", 12, GOLD_DIM)
	indoor_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	indoor_label.position = Vector2(-260, -40)
	root.add_child(indoor_label)

func _build_vehicle_panel() -> void:
	vehicle_panel = _panel()
	vehicle_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	vehicle_panel.position = Vector2(-560, -110)
	vehicle_panel.custom_minimum_size = Vector2(170, 0)
	vehicle_panel.visible = false
	root.add_child(vehicle_panel)
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 0)
	vehicle_panel.add_child(vv)
	vehicle_speed = _label("0", 32, GOLD)
	vehicle_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vv.add_child(vehicle_speed)
	var kmh := _label("km/h", 11, TEXT_DIM)
	kmh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vv.add_child(kmh)

# ---------------------------------------------------------------- public API
func set_district(name: String) -> void:
	if district_label: district_label.text = name.to_upper()

func set_clock(hour: float, weather: String, temp: int) -> void:
	if clock_label == null: return
	var h := int(hour)
	var m := int((hour - float(h)) * 60.0)
	clock_label.text = "%02d:%02d · %s · %d°" % [h, m, weather.to_upper(), temp]

func set_interact_prompt(text: String, _kind: String) -> void:
	if interact_panel == null: return
	interact_panel.visible = text != ""
	if text != "": interact_label.text = text

func show_dialogue(npc_name: String, text: String) -> void:
	if dialogue_panel == null: return
	dialogue_panel.visible = true
	dialogue_name.text = npc_name.to_upper()
	dialogue_text.text = text
	_dialogue_timer = 7.0

func show_choices(title: String, choices: Array, cb: Callable) -> void:
	if choice_panel == null: return
	for c in choice_list.get_children(): c.queue_free()
	var t := _label(title.to_upper(), 13, GOLD)
	choice_list.add_child(t)
	for c in choices:
		var b := _btn(str(c.get("text", "Choose")), 14)
		b.pressed.connect(func():
			Audio.play_ui("confirm")
			cb.call(c)
		)
		choice_list.add_child(b)
	choice_panel.visible = true

func hide_choices() -> void:
	if choice_panel: choice_panel.visible = false

func offer_mission(title: String, cb: Callable) -> void:
	if _offer_panel == null or _offer_panel.visible: return
	var body := _offer_panel.find_child("Body", true, false)
	if body: body.text = title
	_offer_callback = cb
	_offer_panel.visible = true

func _accept_offer() -> void:
	_offer_panel.visible = false
	if _offer_callback.is_valid(): _offer_callback.call()

func set_indoor(inside: bool, name: String) -> void:
	if indoor_label: indoor_label.text = ("INSIDE · " + name) if inside else ""

func hud_enter_vehicle(_v) -> void:
	if vehicle_panel: vehicle_panel.visible = true
	if btn_pause: btn_pause.visible = false
	# Driving swaps the diamond for throttle/brake: hide combat faces.
	for b in [btn_x, btn_y, btn_a]:
		if b: b.visible = false

func hud_exit_vehicle() -> void:
	if vehicle_panel: vehicle_panel.visible = false
	if btn_pause: btn_pause.visible = true
	for b in [btn_x, btn_y, btn_a]:
		if b: b.visible = true

func notify(title: String, body: String = "", kind: String = "info") -> void:
	if notify_box == null: return
	var p := _panel(Color(0.06, 0.07, 0.085, 0.86), 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var color := GOLD
	if kind == "error": color = DANGER
	elif kind == "money": color = Color(0.70, 0.92, 0.66)
	elif kind == "heal": color = Color(0.62, 0.90, 0.66)
	var t := _label(title, 14, color)
	v.add_child(t)
	if body != "":
		var b := _label(body, 12, TEXT_DIM)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(b)
	notify_box.add_child(p)
	if notify_box.get_child_count() > 4:
		notify_box.get_child(0).queue_free()
	var tw := create_tween()
	tw.tween_interval(4.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)

# ---------------------------------------------------------------- menus
func _build_menu() -> void:
	_menu = _fullscreen_overlay()
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-160, -180)
	center.custom_minimum_size = Vector2(320, 0)
	center.add_theme_constant_override("separation", 10)
	_menu.add_child(center)
	var title := _label("PAUSED", 30, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	for pair in [
		["RESUME", func(): toggle_menu()],
		["SAVE GAME", func(): Game.save_game(0); toggle_menu()],
		["LOAD GAME", func(): Game.load_game(0); toggle_menu()],
		["SETTINGS", func(): world.hud_show_settings()],
		["MISSION LOG", func(): world.hud_show_log()],
		["QUIT TO MENU", func(): Loader.goto_menu()],
	]:
		var b := _btn(pair[0], 15)
		b.pressed.connect(func():
			Audio.play_ui("click")
			pair[1].call()
		)
		center.add_child(b)

func _fullscreen_overlay() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.045, 0.90)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)
	root.add_child(c)
	return c

func toggle_menu() -> void:
	if _menu == null: return
	_menu.visible = not _menu.visible
	get_tree().paused = _menu.visible

func _build_shop() -> void:
	_shop = _fullscreen_overlay()
	var p := _panel(Color(0.045, 0.05, 0.062, 0.98), 18)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-360, -260)
	p.custom_minimum_size = Vector2(720, 520)
	_shop.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	shop_title = _label("SHOP", 24, GOLD)
	v.add_child(shop_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(690, 380)
	v.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.custom_minimum_size = Vector2(680, 0)
	shop_list.add_theme_constant_override("separation", 6)
	scroll.add_child(shop_list)
	var close := _btn("CLOSE", 15)
	close.pressed.connect(func(): _shop.visible = false)
	v.add_child(close)

var shop_title: Label
var shop_list: VBoxContainer

func open_shop(vendor_id: String) -> void:
	if _shop == null: return
	var data: Dictionary = Content.SHOP_ITEMS.get(vendor_id, Content.SHOP_ITEMS["general"])
	shop_title.text = data["title"].to_upper()
	for c in shop_list.get_children(): c.queue_free()
	for item in data["items"]:
		var row := _panel(Color(0.08, 0.085, 0.10, 0.9), 10)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(440, 0)
		h.add_child(info)
		var nm := _label(str(item["name"]), 15, TEXT)
		info.add_child(nm)
		var ds := _label(str(item.get("desc", "")), 12, TEXT_DIM)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(ds)
		var pr := _label("₦" + str(item["price"]), 15, Color(0.86, 0.94, 0.80))
		h.add_child(pr)
		var buy := _btn("BUY", 13)
		var it: Dictionary = item
		buy.pressed.connect(func():
			if Game.buy_item(it):
				Audio.play_ui("confirm")
				open_shop(vendor_id)
		)
		h.add_child(buy)
		shop_list.add_child(row)
	_shop.visible = true

func _build_phone() -> void:
	_phone = _fullscreen_overlay()
	var p := PHONE_VIEW.new()
	p.name = "PhoneDevice"
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phone.add_child(p)
	p.setup(self, world)
	_phone_dev = p
	_phone.visible = false

var _phone_dev = null

func toggle_phone() -> void:
	if _phone == null: return
	_phone.visible = not _phone.visible
	if _phone.visible and _phone_dev != null:
		_phone_dev.show_home()

## Route an incoming call to the phone device.
func ring_phone(call_id: String) -> void:
	if _phone_dev == null: return
	_phone.visible = true
	_phone_dev.ring(call_id)

## Non-blocking one-line notice in the corner.
func show_toast(text: String) -> void:
	notify(text, "info")

func _contact_line(bio: String) -> String:
	return bio

func _cycle_radio() -> void:
	var stations: Array = Content.RADIO["stations"]
	var i := 0
	for k in stations.size():
		if stations[k]["id"] == Game.radio_station: i = k
		i = i
	i = (i + 1) % stations.size()
	Game.radio_station = stations[i]["id"]
	var rep: Array = Content.RADIO["reports"]
	if not rep.is_empty() and Game.radio_station != "none":
		var r: Dictionary = rep[randi() % rep.size()]
		show_dialogue(stations[i]["name"], r["title"] + " — " + r["text"])
	else:
		show_dialogue(stations[i]["name"], stations[i]["desc"])

## Opens the interactive world map. The previous implementation was a static grid
## of district cards with no city, no player and no routing — this hands off to
## scripts/ui/world_map.gd, which draws the real layout from CityBuilder.
func toggle_map() -> void:
	if world == null: return
	if _mapview != null and _mapview.visible:
		_mapview.visible = false
		return
	if _mapview == null:
		_mapview = _fullscreen_overlay()
		var m := MAP_VIEW.new()
		m.name = "WorldMap"
		m.set_anchors_preset(Control.PRESET_FULL_RECT)
		_mapview.add_child(m)
		m.setup(self, world)
	_mapview.visible = true

## Returns the destination the player picked on the map, if any.
func map_destination() -> String:
	if _mapview == null: return ""
	var m = _mapview.get_node_or_null("WorldMap")
	return m.destination_name() if m != null else ""

## Route waypoints in world space, for the HUD minimap / objective arrow.
func map_route() -> Array:
	if _mapview == null: return []
	var m = _mapview.get_node_or_null("WorldMap")
	return m._route if m != null else []

func hud_show_settings() -> void:
	if world == null: return
	var overlay := _fullscreen_overlay()
	var p := _panel(Color(0.045, 0.05, 0.062, 0.98), 18)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-260, -220)
	p.custom_minimum_size = Vector2(520, 440)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_label("SETTINGS", 22, GOLD))
	for pair in [["Master", "master_volume"], ["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := _label(pair[0], 14, TEXT)
		lbl.custom_minimum_size = Vector2(90, 0)
		row.add_child(lbl)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(Audio.get(pair[1]))
		slider.custom_minimum_size = Vector2(280, 26)
		var prop: String = pair[1]
		slider.value_changed.connect(func(val):
			Audio.set(prop, val)
			Audio.apply_volume()
		)
		row.add_child(slider)
		v.add_child(row)
	var back := _btn("BACK", 14)
	back.pressed.connect(func(): overlay.queue_free())
	v.add_child(back)

func hud_show_log() -> void:
	var overlay := _fullscreen_overlay()
	var p := _panel(Color(0.045, 0.05, 0.062, 0.98), 18)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-320, -250)
	p.custom_minimum_size = Vector2(640, 500)
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(_label("MISSION LOG", 22, GOLD))
	v.add_child(_label("Completed: %d" % Game.completed_missions.size(), 13, TEXT_DIM))
	for id in Game.completed_missions:
		var m: Dictionary = Content.MISSIONS.get(id, {})
		v.add_child(_label("✓ " + str(m.get("title", id)), 13, Color(0.6, 0.85, 0.6)))
	var next := Game.next_available_mission()
	if next != "":
		var m2: Dictionary = Content.MISSIONS[next]
		v.add_child(_label("NEXT: " + str(m2["title"]), 14, GOLD))
		var b := _label(str(m2.get("brief", "")), 12, TEXT_DIM)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(600, 0)
		v.add_child(b)
	var close := _btn("CLOSE", 14)
	close.pressed.connect(func(): overlay.queue_free())
	v.add_child(close)

# ---------------------------------------------------------------- update
func _process(delta: float) -> void:
	if world == null: return
	if health_bar:
		health_bar.value = lerpf(health_bar.value, Game.player_health, delta * 8.0)
	if stamina_bar:
		stamina_bar.value = Game.stamina
	if heat_bar:
		heat_bar.value = Game.heat
	if money_label:
		money_label.text = "₦" + _thousands(Game.money)
	if discipline_label:
		discipline_label.text = str(Content.DISCIPLINES.get(Game.active_discipline, {}).get("name", "")).to_upper()
	if weapon_label:
		weapon_label.text = str(Content.WEAPONS.get(Game.equipped_weapon, {}).get("name", "Fists")).to_upper()
	if ammo_label:
		var w: Dictionary = Content.WEAPONS.get(Game.equipped_weapon, {})
		if w.get("kind", "") == "gun":
			ammo_label.text = "%d / %d" % [int(Game.ammo.get(Game.equipped_weapon, 0)), int(w.get("reserve", 0))]
		else:
			ammo_label.text = ""
	for i in wanted_pips.size():
		var active := i < Game.wanted
		wanted_pips[i].color = DANGER if active else Color(0.25, 0.22, 0.20, 0.9)
	if mission_title:
		if Game.mission.is_empty():
			mission_box.visible = false
		else:
			mission_box.visible = true
			mission_title.text = str(Game.mission.get("title", "")).to_upper()
			var obj := Game.current_objective()
			var need := int(obj.get("count", 0))
			var prog := int(Game.mission.get("progress", 0))
			var txt := str(obj.get("text", ""))
			if need > 1: txt += "  (%d/%d)" % [prog, need]
			mission_obj.text = txt
	if compass: compass.queue_redraw()
	if dialogue_panel and dialogue_panel.visible:
		_dialogue_timer -= delta
		if _dialogue_timer <= 0.0: dialogue_panel.visible = false
	if vehicle_panel and vehicle_panel.visible and world.player.vehicle != null:
		vehicle_speed.text = str(int(world.player.vehicle.linear_velocity.length() * 3.6))
	# Keep the touch diamond readable: combat faces dim outside combat.
	if world.player.combat != null:
		var fighting: bool = world.player.combat.in_combat
		btn_b.text = "B" if fighting else "B"
		btn_b.modulate.a = 1.0 if fighting else 0.86

func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0: out = "," + out
	return ("-" if n < 0 else "") + out

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_menu()
		get_viewport().set_input_as_handled()
