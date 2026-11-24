extends Node
## Renders the assembled city from a high vantage so the district streets can
## be judged together - the "combine to make a city" check.
var t := 0.0
var done := false
func _ready():
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
func _process(d):
	t += d
	if t > 14.0 and not done:
		done = true
		var img := get_viewport().get_texture().get_image()
		if img: img.save_png("/home/user/city.png"); print("SHOT /home/user/city.png")
		get_tree().quit()
