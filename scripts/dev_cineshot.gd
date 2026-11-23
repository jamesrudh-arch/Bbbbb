extends Node3D
## Captures the opening cinematic at fixed beats for visual verification.
var _cine: Node3D
func _ready():
	var w := 1280
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	c.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(vp)
	_cine = load("res://scripts/ui/opening_cinematic.gd").new()
	vp.add_child(_cine)
	await get_tree().process_frame
	await get_tree().create_timer(4.0).timeout
	print("[CINE] shot=", _cine._shot)
	await get_tree().create_timer(3.2).timeout
	print("[CINE] shot=", _cine._shot)
	await get_tree().create_timer(6.5).timeout
	print("[CINE] shot=", _cine._shot)
	await get_tree().create_timer(5.0).timeout
	print("[CINE] shot=", _cine._shot)
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/home/user/leverage/shots/cine_04_chair.png")
	print("SHOT_SAVED chair")
	get_tree().quit()
