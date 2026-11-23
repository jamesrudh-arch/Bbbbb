extends Node
## Renders the new UI surfaces to shots/ so they are verified, not assumed.

var _frame := 0
var _stage := 0
var _out_dir := "/home/user/leverage/shots"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--out="):
			_out_dir = a.substr(6)
	_go.call_deferred()

func _go() -> void:
	await get_tree().process_frame
	# ---- 1. Settings menu
	var s = load("res://scripts/ui/settings_menu.gd").new()
	add_child(s)
	await _wait(30)
	await _shot("ui_01_settings")
	s.queue_free()
	await _wait(4)

	# ---- 2. Dialogue box with a branching choice
	var d = load("res://scripts/ui/dialogue_box.gd").new()
	add_child(d)
	d.play([
		{"speaker": "CHIDI", "text": "They took me off the street, Marcus. No mask, no warning. Just a van and a hand over my mouth.",
		 "color": Color(0.62, 0.82, 0.92)},
		{"speaker": "MARCUS", "text": "Then somebody saw it. Somebody on that corner knows a face.", "color": Color(0.94, 0.76, 0.32)},
	])
	await _wait(50)
	await _shot("ui_02_dialogue")
	# force full reveal then show choices
	d._body.visible_characters = 999
	d._queue.clear()
	d.ask({"speaker": "MARCUS", "text": "Who was driving the van?", "color": Color(0.94, 0.76, 0.32)},
		[{"tag": "ASK", "label": "Tell me what you saw."},
		 {"tag": "THREATEN", "label": "Somebody talks or somebody bleeds."},
		 {"tag": "LIE", "label": "Police are already on their way."},
		 {"tag": "CHARM", "label": "I grew up on this corner too."}])
	await _wait(20)
	d._body.visible_characters = 999
	d._show_choices()
	await _wait(20)
	await _shot("ui_03_choices")
	get_tree().quit()

func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, name]
	img.save_png(path)
	print("SHOT_SAVED ", path)
