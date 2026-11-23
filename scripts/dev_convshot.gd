extends Node
## Renders a live conversation: the world behind, the dialogue box in front, with
## real content from the authored trees.
func _ready() -> void:
	_go.call_deferred()

func _go() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(2.0).timeout
	# Walk up to a named NPC and put the camera in a talking frame.
	var ngozi = world.npcs.find_named("ngozi")
	if ngozi == null:
		print("[X] ngozi not found"); get_tree().quit(); return
	var p = world.player
	p.global_position = ngozi.global_position + Vector3(0, 0.2, 2.2)
	ngozi.face_toward(p.global_position)
	if p.camera_rig != null and p.camera_rig.camera != null:
		var c: Camera3D = p.camera_rig.camera
		c.global_position = ngozi.global_position + Vector3(1.9, 1.75, 2.6)
		c.look_at(ngozi.global_position + Vector3(0, 1.15, 0))
	await get_tree().create_timer(0.5).timeout

	# Opening line
	# Match what the player sees: conversation takes over the screen.
	world.hud.set_cinematic_mode(true)
	var payload = world.conversations.open_talk("ngozi")
	world.say([payload["start"]])
	await get_tree().create_timer(1.2).timeout
	world.dialogue._body.visible_characters = 999
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/conv_01_line.png")
	print("SHOT_SAVED conv_01_line")

	# Then the four approaches
	var choices := []
	for ch in payload["choices"]:
		choices.append({"tag": ch["tag"], "label": ch["label"]})
	world.dialogue._queue.clear()
	world.ask({"speaker": payload["speaker"], "text": "What do you know about Chidi?"}, choices)
	world.dialogue._body.visible_characters = 999
	world.dialogue._show_choices()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/conv_02_choices.png")
	print("SHOT_SAVED conv_02_choices")

	# And the consequence of picking CHARM
	var r = world.conversations.resolve("ngozi", "CHARM")
	world.dialogue._choice_col.visible = false
	world.say([{"speaker": r["speaker"], "text": r["text"], "color": Color(0.90, 0.56, 0.70)},
			   {"speaker": "", "text": r["closing"], "color": Color(0.72, 0.74, 0.80)}])
	await get_tree().create_timer(0.6).timeout
	world.dialogue._body.visible_characters = 999
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/conv_03_result.png")
	print("SHOT_SAVED conv_03_result")
	get_tree().quit()
