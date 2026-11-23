extends Node
## Renders the live HUD in-world with the style meter engaged, to check the
## meter sits correctly next to health and stays readable over the city.
func _ready() -> void:
	_go.call_deferred()

func _go() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(1.6).timeout
	# Drive the meter to a mid rank so the meter has something to show.
	StyleRank.begin_fight()
	for i in 14:
		StyleRank.on_hit(["punch_cross","punch_hook","kick_mma","kick_round"][i % 4], 9.0)
	print("[H] rank=", StyleRank.rank_name(), " score=%.0f" % StyleRank.score)
	print("[H] hud style_meter=", world.hud.style_meter != null)
	if world.hud.style_meter != null:
		print("[H] meter pos=", world.hud.style_meter.position, " size=", world.hud.style_meter.size)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/hud_style.png")
	print("SHOT_SAVED")
	get_tree().quit()
