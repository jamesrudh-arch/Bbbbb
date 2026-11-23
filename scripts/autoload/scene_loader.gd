extends Node
## LOADER — single owner of scene transitions (fade, thread-free, mobile-safe).

signal fade_finished

var _fade: ColorRect
var _layer: CanvasLayer

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 200
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.035, 0.045, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	_fade.visible = false
	_layer.add_child(_fade)

func fade_out(duration: float = 0.35) -> void:
	_fade.visible = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, duration)
	await tw.finished
	fade_finished.emit()

func fade_in(duration: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, duration)
	await tw.finished
	_fade.visible = false

func goto_scene(path: String, fade_time: float = 0.35) -> void:
	await fade_out(fade_time)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in(fade_time)

func goto_world(new_game: bool = false) -> void:
	if new_game:
		Game.reset_new_game()
		Game.start_mission("homecoming")
	await goto_scene("res://scenes/world.tscn")

func goto_menu() -> void:
	await goto_scene("res://scenes/main_menu.tscn")
