extends Node
## Proves the character rig still animates after the .tres -> .res swap.
## Renders a figure mid-punch, so a failed animation library shows as a T-pose.

var _frames := 0
var _out := "/home/user/leverage/shots/rig_proof.png"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
	_run.call_deferred()

func _run() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.06, 0.075)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.68)
	e.ambient_light_energy = 0.9
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 42, 0)
	sun.light_energy = 2.1
	add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(0.6, 1.15, 2.6)
	cam.fov = 42.0
	add_child(cam)
	cam.look_at(Vector3(0.0, 1.05, 0.0))

	var rig_script = load("res://scripts/character/character_rig.gd")
	var rig = rig_script.new()
	add_child(rig)
	var ok: bool = rig.build("Soldier")
	print("[R] build=", ok)

	# Advance far enough to be mid-strike, not at frame 0.
	await get_tree().create_timer(0.5).timeout
	var clip := "punch"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clip="):
			clip = a.trim_prefix("--clip=")
	rig.play(clip)
	# "punch" runs 2.17 s and opens on a neutral frame; sample partway in so the
	# render proves the pose is driven by data, not a bind pose.
	await get_tree().create_timer(0.95).timeout
	print("[R] clip_now=", rig.current_clip() if rig.has_method("current_clip") else "n/a")

	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	print("SHOT_SAVED ", _out)
	get_tree().quit()
