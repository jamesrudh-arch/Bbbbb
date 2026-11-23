extends Node
## Captures the entire opening chain end to end: studio -> title -> notice ->
## departure, then the cinematic's four shots.
func _ready():
	var boot_scene: PackedScene = load("res://scenes/boot.tscn")
	var boot = boot_scene.instantiate()
	add_child(boot)
	await get_tree().create_timer(4.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/flow_01_studio.png")
	print("SHOT studio")
	boot._show_stage(1)
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/flow_02_title.png")
	print("SHOT title")
	boot._show_stage(2)
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/flow_03_notice.png")
	print("SHOT notice")
	get_tree().quit()
