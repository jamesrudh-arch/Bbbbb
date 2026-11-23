extends Node
func _ready() -> void:
	_go.call_deferred()

func _go() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(1.8).timeout
	Game.current_district = "railhead"
	var board = load("res://scripts/ui/job_board.gd").new()
	world.hud.add_child(board)
	board.setup(world)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/jobs_01_contracts.png")
	print("SHOT_SAVED contracts")
	board._tab = "bounties"
	board._refresh()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/jobs_02_bounties.png")
	print("SHOT_SAVED bounties")
	get_tree().quit()
