extends Node
## SPLIT VIEW — two cameras, one screen, top and bottom halves.
##
## Top/bottom rather than left/right: on a phone held in landscape, a horizontal
## split gives each player a tall narrow letterbox, while a horizontal divider
## keeps a usable wide view for both. The divider is also where the round timer
## and score sit, so the seam becomes useful.

signal layout_changed(active: bool)

const DIVIDER := 6.0

var world: Node3D = null
var active := false

var _sub_top: SubViewportContainer
var _sub_bottom: SubViewportContainer
var _vp_top: SubViewport
var _vp_bottom: SubViewport
var _cam_top: Camera3D
var _cam_bottom: Camera3D
var _layer: CanvasLayer
var _divider: ColorRect
var _score_label: Label
var _timer_label: Label
var _p1: Node3D = null
var _p2: Node3D = null

func setup(w: Node3D) -> void:
	world = w

## Build the two viewports and route each fighter's camera into one of them.
func engage(fighter_a: Node3D, fighter_b: Node3D) -> void:
	if active:
		return
	_p1 = fighter_a
	_p2 = fighter_b
	_layer = CanvasLayer.new()
	_layer.layer = 20
	world.add_child(_layer)

	var full := Rect2(Vector2.ZERO, (world.get_viewport().get_visible_rect().size))

	_sub_top = SubViewportContainer.new()
	_sub_top.stretch = true
	_sub_top.anchor_right = 1.0
	_sub_top.anchor_bottom = 0.5
	_sub_top.offset_bottom = -DIVIDER * 0.5
	_layer.add_child(_sub_top)

	_sub_bottom = SubViewportContainer.new()
	_sub_bottom.stretch = true
	_sub_bottom.anchor_right = 1.0
	_sub_bottom.anchor_top = 0.5
	_sub_bottom.anchor_bottom = 1.0
	_sub_bottom.offset_top = DIVIDER * 0.5
	_layer.add_child(_sub_bottom)

	_vp_top = SubViewport.new()
	_vp_top.own_world_3d = false          # share the city's physics and lighting
	_vp_top.handle_input_locally = false
	_vp_top.size = Vector2i(full.size.x, full.size.y * 0.5)
	_sub_top.add_child(_vp_top)

	_vp_bottom = SubViewport.new()
	_vp_bottom.own_world_3d = false
	_vp_bottom.handle_input_locally = false
	_vp_bottom.size = Vector2i(full.size.x, full.size.y * 0.5)
	_sub_bottom.add_child(_vp_bottom)

	# Cameras move into the viewports. The rigs keep driving them, so the camera
	# behaviour is identical to solo play.
	_cam_top = _detach_camera(_p1)
	if _cam_top != null:
		_vp_top.add_child(_cam_top)
	_cam_bottom = _detach_camera(_p2)
	if _cam_bottom != null:
		_vp_bottom.add_child(_cam_bottom)

	_build_overlay()
	active = true
	layout_changed.emit(true)

## Reparent a fighter's camera without disturbing its spring arm transform.
func _detach_camera(fighter: Node3D) -> Camera3D:
	if fighter == null or not is_instance_valid(fighter):
		return null
	var rig = fighter.get("camera_rig")
	if rig == null:
		return null
	var cam: Camera3D = rig.get("camera")
	if cam == null:
		return null
	var arm: Node = cam.get_parent()
	if arm != null:
		arm.remove_child(cam)
	cam.top_level = true      # driven by the rig's transform math, not the viewport tree
	return cam

func _build_overlay() -> void:
	_divider = ColorRect.new()
	_divider.color = Color(0.02, 0.02, 0.03, 1.0)
	_divider.anchor_right = 1.0
	_divider.anchor_top = 0.5
	_divider.anchor_bottom = 0.5
	_divider.offset_top = -DIVIDER * 0.5
	_divider.offset_bottom = DIVIDER * 0.5
	_layer.add_child(_divider)

	_score_label = Label.new()
	_score_label.text = "0  ·  0"
	_score_label.add_theme_font_size_override("font_size", 15)
	_score_label.add_theme_color_override("font_color", Color(0.94, 0.76, 0.32))
	_score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_score_label.add_theme_constant_override("outline_size", 6)
	_score_label.anchor_left = 0.5
	_score_label.anchor_right = 0.5
	_score_label.anchor_top = 0.5
	_score_label.anchor_bottom = 0.5
	_score_label.offset_left = -24
	_score_label.offset_top = -12
	_layer.add_child(_score_label)

	_timer_label = Label.new()
	_timer_label.text = "60"
	_timer_label.add_theme_font_size_override("font_size", 15)
	_timer_label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))
	_timer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_timer_label.add_theme_constant_override("outline_size", 6)
	_timer_label.anchor_left = 0.5
	_timer_label.anchor_right = 0.5
	_timer_label.anchor_top = 0.5
	_timer_label.anchor_bottom = 0.5
	_timer_label.offset_left = 26
	_timer_label.offset_top = -12
	_layer.add_child(_timer_label)

func update_score(score: Array) -> void:
	if _score_label != null:
		_score_label.text = "%d  ·  %d" % [int(score[0]), int(score[1])]

func update_timer(seconds: float) -> void:
	if _timer_label != null:
		_timer_label.text = str(maxi(0, int(ceil(seconds))))

## Tear the split down and restore the story camera.
func disengage() -> void:
	if not active:
		return
	active = false
	if _p1 != null and is_instance_valid(_p1):
		_reattach_camera(_p1, _cam_top)
	if _p2 != null and is_instance_valid(_p2):
		_reattach_camera(_p2, _cam_bottom)
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
		_layer = null
	layout_changed.emit(false)

func _reattach_camera(fighter: Node3D, cam: Camera3D) -> void:
	if cam == null or not is_instance_valid(cam):
		return
	var rig = fighter.get("camera_rig")
	if rig == null:
		return
	var arm: Node = rig.get_node_or_null("SpringArm3D")
	if arm == null:
		return
	if cam.get_parent() != null:
		cam.get_parent().remove_child(cam)
	cam.top_level = false
	arm.add_child(cam)
	cam.transform = Transform3D.IDENTITY
