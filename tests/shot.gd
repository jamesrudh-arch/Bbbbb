extends Node
var t := 0.0
var done := false
var out := "/home/user/street.png"
func _ready():
	var e := OS.get_environment("SHOT_OUT")
	if e != "": out = e
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
func _process(d):
	t += d
	if t > 8.0 and not done:
		done = true
		var img := get_viewport().get_texture().get_image()
		if img: img.save_png(out); print("SHOT ", out)
		get_tree().quit()
