extends Control
## DUEL SELECT — pick two fighters and their disciplines, then fight.
##
## Deliberately one screen with no scrolling: both players choose on the same
## phone, so anything that requires handing the device back and forth for more
## than a moment kills the mode. Two columns, one tap each, fight.

signal fight_requested(p1_discipline: String, p2_discipline: String)
signal closed

var _sel := ["brawler", "kickboxing"]
var _list: Array = []
var _labels := {}

const P1_COLOR := Color(0.94, 0.76, 0.32)
const P2_COLOR := Color(0.45, 0.68, 0.92)

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
	bg.color = Color(0.035, 0.04, 0.05, 0.99)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var title := Label.new()
	title.text = "DUEL"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", P1_COLOR)
	title.position = Vector2(32, 24)
	add_child(title)

	var sub := Label.new()
	sub.text = "Best of three. Sixty seconds a round. Style breaks a draw."
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.62, 0.66, 0.72))
	sub.position = Vector2(32, 58)
	add_child(sub)

	var cols := HBoxContainer.new()
	cols.position = Vector2(32, 96)
	cols.add_theme_constant_override("separation", 22)
	add_child(cols)

	var engine = null
	var discs: Array = []
	if get_tree().current_scene != null and get_tree().current_scene.get("duel") != null:
		engine = get_tree().current_scene.duel
		discs = engine.discipline_list()
	if discs.is_empty():
		for k in ["brawler", "kickboxing", "grappling", "drunken", "weapon", "silat"]:
			discs.append({"key": k, "name": str(k).capitalize(), "desc": "", "identity": ""})

	cols.add_child(_column(0, "PLAYER ONE", P1_COLOR, discs))
	cols.add_child(_column(1, "PLAYER TWO", P2_COLOR, discs))

	var fight := Button.new()
	fight.text = "FIGHT"
	fight.anchor_top = 1.0
	fight.anchor_bottom = 1.0
	fight.anchor_left = 0.5
	fight.anchor_right = 0.5
	fight.offset_left = -120
	fight.offset_right = 120
	fight.offset_top = -84
	fight.offset_bottom = -20
	fight.add_theme_font_size_override("font_size", 22)
	fight.add_theme_color_override("font_color", Color(0.05, 0.05, 0.06))
	var sb := StyleBoxFlat.new()
	sb.bg_color = P1_COLOR
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	fight.add_theme_stylebox_override("normal", sb)
	fight.pressed.connect(func():
		Audio.play_ui("confirm")
		fight_requested.emit(_sel[0], _sel[1]))
	add_child(fight)

	var back := Button.new()
	back.text = tr("BACK")
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = 32
	back.offset_top = -76
	back.offset_right = 160
	back.offset_bottom = -22
	back.pressed.connect(func():
		closed.emit()
		queue_free())
	add_child(back)

func _column(idx: int, label_text: String, col: Color, discs: Array) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(280, 0)
	v.add_theme_constant_override("separation", 6)

	var head := Label.new()
	head.text = label_text
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", col)
	v.add_child(head)

	for d in discs:
		var b := Button.new()
		b.text = str(d.get("name", d.get("key", "")))
		b.toggle_mode = true
		b.button_pressed = (str(d.get("key", "")) == _sel[idx])
		b.custom_minimum_size = Vector2(0, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		var key := str(d.get("key", ""))
		var desc := str(d.get("identity", ""))
		b.tooltip_text = desc
		b.pressed.connect(func():
			_sel[idx] = key
			_refresh_column(idx, col))
		_labels["%d_%s" % [idx, key]] = b
		v.add_child(b)

	var note := Label.new()
	note.name = "Note%d" % idx
	note.text = ""
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.60, 0.63, 0.69))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(280, 46)
	v.add_child(note)

	var info := Label.new()
	info.name = "Info%d" % idx
	info.text = ""
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.72, 0.75, 0.80))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(280, 40)
	v.add_child(info)

	_refresh_column(idx, col)
	return v

func _refresh_column(idx: int, _col: Color) -> void:
	for key in _labels:
		var k := str(key)
		if not k.begins_with("%d_" % idx):
			continue
		var btn: Button = _labels[key]
		btn.button_pressed = k.ends_with("_" + _sel[idx])

	# Show the chosen style's identity so the choice is informed, not cosmetic.
	var engine = null
	var scene := get_tree().current_scene
	if scene != null and scene.get("duel") != null:
		engine = scene.duel
	if engine == null:
		return
	var identity := ""
	for d in engine.discipline_list():
		if str(d.get("key", "")) == _sel[idx]:
			identity = str(d.get("identity", ""))
			break
	var col_node: Control = null
	for c in get_children():
		if c is HBoxContainer and c.get_child_count() > idx:
			col_node = c.get_child(idx)
	if col_node != null:
		var info := col_node.get_node_or_null("Info%d" % idx)
		if info != null:
			info.text = identity
