extends Node
## Can the touch joystick drive the player? Drive hud._stick_input exactly as the
## OS would deliver touches, and confirm the player moves. This is the iPhone path.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	Game.reset_new_game()
	Game.start_mission("homecoming")
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud = w.hud
	var sb: Control = hud.stick_base
	print("T stick rect=", sb.get_global_rect())
	var before: Vector3 = w.player.global_position
	# press at the stick centre, then drag up (forward)
	var c: Vector2 = sb.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.index = 0; down.position = c; down.pressed = true
	hud._stick_input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 0; drag.position = c + Vector2(0, -62); drag.relative = Vector2(0, -62)
	hud._stick_input(drag)
	print("T move_forward strength=", snappedf(Input.get_action_strength("move_forward"), 0.01))
	for i in 90:
		await get_tree().process_frame
	var after: Vector3 = w.player.global_position
	print("T player moved=", snappedf(before.distance_to(after), 0.01), " m")
	var up := InputEventScreenTouch.new()
	up.index = 0; up.position = c; up.pressed = false
	hud._stick_input(up)
	print("T after release move_forward=", Input.get_action_strength("move_forward"))
	# and the combat diamond: press X and see if a punch action fires
	var punch_before := Input.get_action_strength("punch")
	if hud.btn_x != null:
		hud.btn_x.button_down.emit()
		print("T punch action after button=", snappedf(Input.get_action_strength("punch"), 0.01))
		hud.btn_x.button_up.emit()
	print("T done")
	get_tree().quit()
