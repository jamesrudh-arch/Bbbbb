extends Control
## OPENING — hosts the cinematic in a SubViewport, then hands control to play.
## This is the bridge between the title and the first playable frame.

const CINE := preload("res://scripts/ui/opening_cinematic.gd")

var _vp: SubViewport
var _fade: ColorRect
var _skip: Label

func _ready() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = false
	_vp.size = Vector2i(1280, 720)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(_vp)

	var cine: Node3D = CINE.new()
	_vp.add_child(cine)
	cine.finished.connect(_on_cinematic_done)

	_skip = Label.new()
	_skip.text = tr("TAP TO SKIP")
	_skip.add_theme_font_size_override("font_size", 13)
	_skip.add_theme_color_override("font_color", Color(0.55, 0.58, 0.64, 0.75))
	_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip.position = Vector2(-140, -48)
	add_child(_skip)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if pressed:
		_on_cinematic_done()

func _on_cinematic_done() -> void:
	if SaveFlags.opening_seen():
		return
	SaveFlags.mark_opening_seen()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.7)
	await tw.finished
	Loader.goto_world(true)
