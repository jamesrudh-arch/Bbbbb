extends Control
## DIALOGUE BOX — the primary storytelling surface.
##
## LEVERAGE ships with no voice acting, so this is not a subtitle track bolted on
## after the fact: it is how the story is told. It is built to be read comfortably
## on a phone held at arm's length, at a glance, mid-motion:
##   * short lines, large type, generous line height
##   * one speaker at a time, name in the accent colour
##   * a deliberate beat between lines so the eye can reset
##   * branching choices as four large tap targets, tagged [ASK] [THREATEN] ...
##   * tap anywhere to advance, or auto-advance if the player is driving
##
## Because there is no performance to carry the scene, pacing does the work:
## text appears on a beat, holds longer for long lines, and the camera holds.

signal line_finished
signal choice_made(index: int)

const LINE_HOLD_PER_CHAR := 0.038   # seconds of read time per character
const LINE_MIN_HOLD := 1.5
const LINE_MAX_HOLD := 7.0

var _panel: PanelContainer
var _name_label: Label
var _body: RichTextLabel
var _hint: Label
var _choice_col: VBoxContainer
var _queue: Array = []          # [{speaker, text, color}]
var _choices: Array = []
var _typing := 0.0
var _hold := 0.0
var _full_text := ""
var _active := false
var _auto := false

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.045, 0.055, 0.90)
	sb.border_width_top = 2
	sb.border_color = Color(0.92, 0.74, 0.32, 0.55)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 16
	sb.content_margin_bottom = 18
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.offset_top = -196.0
	_panel.offset_bottom = -26.0
	_panel.offset_left = 22.0
	_panel.offset_right = -22.0
	add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color(0.94, 0.76, 0.32))
	col.add_child(_name_label)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.fit_content = true
	_body.scroll_active = false
	_body.add_theme_font_size_override("normal_font_size", 21)
	_body.add_theme_color_override("default_color", Color(0.93, 0.94, 0.96))
	_body.add_theme_constant_override("line_separation", 7)
	_body.custom_minimum_size = Vector2(0, 76)
	col.add_child(_body)

	_hint = Label.new()
	_hint.text = "tap to continue"
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.62, 0.66, 0.72, 0.8))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)

	_choice_col = VBoxContainer.new()
	_choice_col.add_theme_constant_override("separation", 10)
	_choice_col.anchor_left = 0.0
	_choice_col.anchor_right = 1.0
	_choice_col.anchor_top = 1.0
	_choice_col.anchor_bottom = 1.0
	_choice_col.offset_left = 22.0
	_choice_col.offset_right = -22.0
	_choice_col.offset_top = -520.0
	_choice_col.offset_bottom = -212.0
	_choice_col.visible = false
	add_child(_choice_col)

	_panel.visible = false
	_apply_scale()

func _apply_scale() -> void:
	# Respect the player's subtitle size preference.
	var f := clampf(PlatformUI.subtitle_size, 0.8, 1.4)
	_body.add_theme_font_size_override("normal_font_size", int(21 * f))
	_name_label.add_theme_font_size_override("font_size", int(15 * f))
	_panel.offset_top = -190.0 * f

## Queue a run of lines. Each entry: {speaker, text, color}
func play(lines: Array) -> void:
	_queue = lines.duplicate()
	_choices = []
	_active = true
	_panel.visible = true
	_apply_scale()
	_next_line()

func ask(question: Dictionary, choices: Array) -> void:
	## choices: [{label, tag, id}] — tag is ASK / THREATEN / LIE / CHARM
	_queue = [question]
	_choices = choices
	_active = true
	_panel.visible = true
	_next_line()

func _next_line() -> void:
	if _queue.is_empty():
		_finish()
		return
	var line: Dictionary = _queue.pop_front()
	_name_label.text = str(line.get("speaker", ""))
	_name_label.add_theme_color_override("font_color", line.get("color", Color(0.94, 0.76, 0.32)))
	_full_text = str(line.get("text", ""))
	_body.text = _full_text
	typing_start()

func typing_start() -> void:
	_typing = 0.0
	_hold = clampf(_full_text.length() * LINE_HOLD_PER_CHAR, LINE_MIN_HOLD, LINE_MAX_HOLD)
	_body.visible_characters = 0

func _process(delta: float) -> void:
	if not _active:
		return
	# Typewriter is deliberately slow enough to read, and tap skips to full.
	if _body.visible_characters < _full_text.length():
		_body.visible_characters = mini(_full_text.length(),
			_body.visible_characters + int(delta * 62.0))

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)
	if not tapped:
		return
	if _body.visible_characters < _full_text.length():
		_body.visible_characters = _full_text.length()   # first tap: reveal
	elif not _choices.is_empty():
		_show_choices()                                  # second tap: offer branches
	elif not _queue.is_empty():
		_next_line()
	else:
		_finish()

func _show_choices() -> void:
	_choice_col.visible = true
	for c in _choice_col.get_children():
		c.queue_free()
	var i := 0
	for ch in _choices:
		var b := Button.new()
		b.text = "[%s]  %s" % [str(ch.get("tag", "ASK")).to_upper(), str(ch.get("label", ""))]
		b.custom_minimum_size = Vector2(0, 62)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", int(17 * clampf(PlatformUI.subtitle_size, 0.8, 1.4)))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.08, 0.10, 0.92)
		sb.border_width_left = 3
		sb.border_color = _tag_color(str(ch.get("tag", "ASK")))
		sb.content_margin_left = 16
		b.add_theme_stylebox_override("normal", sb)
		var idx := i
		b.pressed.connect(func():
			_choice_col.visible = false
			_choices = []
			_active = false
			_panel.visible = false
			choice_made.emit(idx))
		_choice_col.add_child(b)
		i += 1
	if _body.visible_characters >= _full_text.length():
		pass

func _tag_color(tag: String) -> Color:
	match tag.to_upper():
		"THREATEN": return Color(0.85, 0.32, 0.28)
		"LIE":      return Color(0.62, 0.44, 0.82)
		"CHARM":    return Color(0.90, 0.56, 0.70)
		_:          return Color(0.94, 0.76, 0.32)

func _finish() -> void:
	_active = false
	_panel.visible = false
	_choice_col.visible = false
	line_finished.emit()

func is_active() -> bool:
	return _active
