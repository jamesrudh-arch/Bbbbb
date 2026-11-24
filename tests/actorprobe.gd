extends SceneTree
func _init():
	var a = load("res://scripts/npc/actor.gd").new()
	print("actor instantiated")
	get_root().add_child(a)
	print("actor in tree")
	a.queue_free()
	quit()
