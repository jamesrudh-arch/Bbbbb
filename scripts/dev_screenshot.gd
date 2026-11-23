extends Node
## DEVELOPMENT TOOL — headless/offscreen screenshot capture.
##
## Attached to the World scene as a child node. It only does anything when the game is
## launched with command-line user args (passed after `--`), so it has zero cost in a
## normal play session.
##
## Usage:
##   Godot --path . res://scenes/world.tscn -- \
##       --shot /abs/path/out.png [--wait 60] [--district neon_mile] [--hour 21.5]
##
## `--district` and `--hour` are handled by world.gd; this node handles `--shot/--wait`.

var _enabled := false
var _out_path := ""
var _wait := 40.0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--shot":
				if i + 1 < args.size():
					_out_path = args[i + 1]
					_enabled = true
			"--wait":
				if i + 1 < args.size():
					_wait = float(args[i + 1])
	if _enabled and not _out_path.is_empty():
		_capture_later()

func _capture_later() -> void:
	await get_tree().create_timer(_wait).timeout
	# Two frames so the viewport texture is complete in the current frame.
	await get_tree().process_frame
	await get_tree().process_frame
	var vp := get_viewport()
	if vp == null:
		push_error("[SHOT] no viewport")
		get_tree().quit()
		return
	var tex := vp.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null:
		push_error("[SHOT] viewport image was null")
		get_tree().quit()
		return
	var err := img.save_png(_out_path)
	if err == OK:
		print("SHOT_SAVED ", _out_path)
	else:
		push_error("[SHOT] save failed: %d" % err)
	get_tree().quit()
