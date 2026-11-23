extends Node3D
## Captures the phone in its three key states for visual verification.
func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.trim_prefix("--mode=")
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	for i in 20: await get_tree().process_frame
	await get_tree().create_timer(1.8).timeout
	var hud = w.hud
	var out := _mode
	Game.hour = 21.0
	match out:
		"ring":
			hud.ring_phone("ngozi_checkin")
		"home":
			hud._phone.visible = true
			hud._phone_dev.show_home()
		"convo":
			hud._phone.visible = true
			hud._phone_dev._play_conversation(Content.CALLS["chidi_warning"]["lines"], "Chidi")
	# give the UI a couple of frames to lay out
	for i in 10: await get_tree().process_frame
	await get_tree().create_timer(0.7).timeout
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/phone_%s.png" % out)
	print("SHOT_SAVED ", out)
	get_tree().quit()

var _mode := "ring"
