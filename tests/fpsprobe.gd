extends Node
var t := 0.0
var frames := 0
func _ready():
	if OS.get_environment("PROBE") == "nophysics":
		ProjectSettings.set_setting("physics/3d/physics_engine", "Dummy")
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
func _process(d):
	t += d
	frames += 1
	if t > 3.0:
		print("FPS avg=", frames / t)
		get_tree().quit()
