extends Control
## JOB BOARD — where generated contracts and bounties become playable.
##
## Reached from the phone. Deliberately not infinite-scrolling: a phone screen
## shows about five jobs and that is the right number to choose between. The rest
## are one flick away, grouped by district so the player can reason about
## distance and risk together.

signal job_chosen(job: Dictionary)
signal closed

var world: Node3D = null
var _tabs: HBoxContainer
var _list: VBoxContainer
var _tab := "contracts"
var _district := ""

const TAB_CONTRACTS := "contracts"
const TAB_BOUNTIES := "bounties"

func setup(w: Node3D) -> void:
	world = w
	_district = Game.current_district
	_build()

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.05, 0.985)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var head := Label.new()
	head.text = "WORK IN %s" % _district.replace("_", " ").to_upper()
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.94, 0.76, 0.32))
	head.position = Vector2(32, 26)
	add_child(head)

	_tabs = HBoxContainer.new()
	_tabs.position = Vector2(32, 62)
	_tabs.add_theme_constant_override("separation", 10)
	add_child(_tabs)
	for pair in [[TAB_CONTRACTS, "CONTRACTS"], [TAB_BOUNTIES, "BOUNTIES"]]:
		var b := Button.new()
		b.text = str(pair[1])
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(150, 46)
		b.add_theme_font_size_override("font_size", 14)
		var tab_id: String = str(pair[0])
		b.pressed.connect(func():
			_tab = tab_id
			_refresh())
		b.button_pressed = (_tab == tab_id)
		_tabs.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 32
	scroll.offset_right = -32
	scroll.offset_top = 124
	scroll.offset_bottom = -96
	add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var back := Button.new()
	back.text = tr("BACK")
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = 32
	back.offset_top = -76
	back.offset_right = 200
	back.offset_bottom = -22
	back.pressed.connect(func():
		closed.emit()
		queue_free())
	add_child(back)

	_refresh()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	if world == null or world.content_engine == null:
		return
	var engine = world.content_engine
	if _tab == TAB_CONTRACTS:
		for job in engine.contracts_in(_district):
			_list.add_child(_row(job))
		if _list.get_child_count() == 0:
			_list.add_child(_empty("No contracts here today."))
	else:
		for job in engine.bounties_in(_district):
			_list.add_child(_row(job))
		if _list.get_child_count() == 0:
			_list.add_child(_empty("Nobody worth chasing here."))

func _row(job: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.078, 0.092, 0.96)
	sb.border_width_left = 3
	sb.border_color = _tier_color(int(job.get("tier", 1)))
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(0, 76)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)

	var title := Label.new()
	title.text = str(job.get("title", job.get("name", "Job")))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.94, 0.95, 0.97))
	col.add_child(title)

	var sub := Label.new()
	var flavour := str(job.get("flavour", job.get("charge", "")))
	sub.text = flavour
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.66, 0.69, 0.75))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)

	var meta := Label.new()
	var risk := int(job.get("tier", 1))
	meta.text = "%s   risk %s   %s" % [
		_money(int(job.get("reward", {}).get("money", 0))),
		"●".repeat(risk),
		"CAPTURE" if true == job.get("alive_required", false) else "",
	]
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.94, 0.76, 0.32))
	col.add_child(meta)

	var take := Button.new()
	take.text = "TAKE"
	take.custom_minimum_size = Vector2(96, 54)
	take.add_theme_font_size_override("font_size", 15)
	take.pressed.connect(func():
		job_chosen.emit(job)
		closed.emit()
		queue_free())
	row.add_child(take)
	return panel

func _empty(text: String) -> Control:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.55, 0.58, 0.63))
	return l

func _tier_color(tier: int) -> Color:
	if tier >= 5: return Color(0.92, 0.32, 0.36)
	if tier >= 4: return Color(0.94, 0.62, 0.26)
	if tier >= 3: return Color(0.92, 0.78, 0.32)
	if tier >= 2: return Color(0.52, 0.72, 0.90)
	return Color(0.55, 0.66, 0.58)

func _money(v: int) -> String:
	return "₦%s" % _commas(v)

func _commas(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out
