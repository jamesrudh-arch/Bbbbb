extends Node
## Renders the style meter at several ranks so readability is verified, not assumed.
var _out := "/home/user/leverage/shots"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): _out = a.trim_prefix("--out=")
	_go.call_deferred()

func _go() -> void:
	await get_tree().process_frame
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.11, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var rows := VBoxContainer.new()
	rows.position = Vector2(40, 40)
	rows.add_theme_constant_override("separation", 26)
	add_child(rows)

	StyleRank.begin_fight()
	for r in range(6):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		rows.add_child(row)
		StyleRank.score = StyleRank.THRESHOLDS[r] + 60.0
		StyleRank.rank_index = r
		var m = load("res://scripts/ui/style_meter.gd").new()
		row.add_child(m)
		m.setup(StyleRank)
		m._rank = StyleRank.RANKS[r]
		m._letter.text = m._rank
		m._apply_color()
		m._shown_progress = 0.75
		var name_l := Label.new()
		name_l.text = "  rank %s  ·  score %.0f" % [StyleRank.RANKS[r], StyleRank.score]
		name_l.add_theme_font_size_override("font_size", 14)
		name_l.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
		row.add_child(name_l)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out + "/style_ranks.png")
	print("SHOT_SAVED ", _out, "/style_ranks.png")
	get_tree().quit()
