extends Control
## STYLE METER — one letter, one bar. Readable with a thumb over the screen.
##
## Deliberately placed under the health bar on the left, not near the action
## buttons: the player already looks there for health, and mid-fight nobody reads
## a new corner of the screen. The letter is large; the bar is thin.

var style: Node = null

var _letter: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _label: Label
var _rank := "D"
var _shown_progress := 0.0
var _pulse := 0.0
var _flash := 0.0

const COLORS := {
	"D": Color(0.62, 0.64, 0.68),
	"C": Color(0.55, 0.78, 0.55),
	"B": Color(0.45, 0.68, 0.92),
	"A": Color(0.94, 0.76, 0.32),
	"S": Color(0.96, 0.52, 0.24),
	"SS": Color(0.98, 0.32, 0.42),
}

func setup(p_style: Node) -> void:
	style = p_style
	style.rank_changed.connect(_on_rank_changed)
	style.score_changed.connect(_on_score_changed)
	style.rank_lost.connect(_on_rank_lost)
	_rank = style.rank_name()
	_apply_color()
	_letter.text = _rank

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(210, 62)

	_letter = Label.new()
	_letter.add_theme_font_size_override("font_size", 44)
	_letter.add_theme_color_override("font_color", COLORS["D"])
	_letter.position = Vector2(0, -8)
	_letter.custom_minimum_size = Vector2(70, 54)
	add_child(_letter)

	_label = Label.new()
	_label.text = "STYLE"
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(0.62, 0.65, 0.70, 0.75))
	_label.position = Vector2(4, 44)
	add_child(_label)

	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.09, 0.10, 0.12, 0.85)
	_bar_bg.position = Vector2(72, 22)
	_bar_bg.size = Vector2(132, 7)
	add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = COLORS["D"]
	_bar_fill.position = Vector2(72, 22)
	_bar_fill.size = Vector2(0, 7)
	add_child(_bar_fill)

func _on_rank_changed(new_rank: String, old_rank: String) -> void:
	_rank = new_rank
	_letter.text = new_rank
	_apply_color()
	var went_up := COLORS.has(new_rank) and COLORS.has(old_rank)
	# Anything climbing is loud; anything falling is quiet. Reward the climb.
	var old_i := ["D","C","B","A","S","SS"].find(old_rank)
	var new_i := ["D","C","B","A","S","SS"].find(new_rank)
	if new_i > old_i:
		_pulse = 1.0
		_flash = 0.0
		if Audio.has_method("play_ui"):
			Audio.play_ui("confirm")
	else:
		if Audio.has_method("play_ui"):
			Audio.play_ui("back")

func _on_score_changed(_score: float, _maximum: float) -> void:
	pass

func _on_rank_lost(reason: String) -> void:
	_flash = 0.35

func _apply_color() -> void:
	var c: Color = COLORS.get(_rank, COLORS["D"])
	_letter.add_theme_color_override("font_color", c)
	_bar_fill.color = c

func _process(delta: float) -> void:
	if style == null:
		return
	var target: float = style.progress()
	_shown_progress = lerpf(_shown_progress, target, minf(1.0, delta * 9.0))
	_bar_fill.size = Vector2(maxf(0.0, 132.0 * _shown_progress), 7.0)
	_pulse = maxf(0.0, _pulse - delta * 3.0)
	_flash = maxf(0.0, _flash - delta * 2.0)
	var s := 1.0 + _pulse * 0.35
	_letter.scale = Vector2(s, s)
	_letter.pivot_offset = Vector2(20, 30)
	if _flash > 0.0:
		_letter.modulate = Color(1.0, 0.45, 0.45, 1.0)
	else:
		_letter.modulate = Color(1, 1, 1, 1)
	# Dim the whole meter when there is no fight to rate.
	modulate.a = 1.0 if style.in_fight else 0.34
