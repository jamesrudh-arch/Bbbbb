extends Node
## DRIVER — vehicle entry, exit, and control hand-off.
## Sits the player into a VehicleBody3D, hands the camera over, swaps the HUD to
## driving mode, and restores everything on exit. Handles both cars and bikes
## (bikes use a leaning visual, not two wheels — see vehicle.gd).

var player: CharacterBody3D
var vehicle = null
var _cooldown := 0.0

func setup(p: CharacterBody3D) -> void:
	player = p

func _hud():
	var w = player.get_parent()
	if w != null and w.get("hud") != null: return w.hud
	return null

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if player == null: return
	if vehicle == null: return
	if _cooldown > 0.0: return
	if Input.is_action_just_pressed("exit_vehicle"):
		exit()

## Try to enter `v`. Returns true on success.
func enter(v) -> bool:
	if v == null or vehicle != null: return false
	if not v.has_method("can_enter") or not v.can_enter(): return false
	vehicle = v
	v.occupy(player)
	player.vehicle = v
	player.visible = false
	player.set_physics_process(false)
	player.camera_rig.attach_vehicle(v)
	Game.stats["vehicles_stolen"] = int(Game.stats.get("vehicles_stolen", 0)) + 1
	if v.get("is_player_owned") == false:
		Game.add_heat(6.0)
	Audio.play_at("engine_start", v.global_position, 1.0, -2.0)
	Audio.play_at("door", v.global_position, 1.1, -6.0)
	var hud = _hud()
	if hud != null: hud.hud_enter_vehicle(v)
	Events.record("vehicle_enter", {"type": v.vehicle_type})
	_cooldown = 0.45
	return true

func exit() -> void:
	if vehicle == null: return
	var v = vehicle
	vehicle = null
	var point: Vector3 = v.exit_point_for(player.global_position) if v.has_method("exit_point_for") else v.global_position + Vector3(0, 1.2, 2.4)
	player.camera_rig.detach_vehicle()
	player.global_position = point
	player.visible = true
	player.set_physics_process(true)
	player.vehicle = null
	v.release()
	player.camera_rig.target_node = player
	player.camera_rig.yaw = v.rotation.y + PI
	var hud2 = _hud()
	if hud2 != null: hud2.hud_exit_vehicle()
	Audio.play_at("door", point, 0.95, -4.0)
	_cooldown = 0.45
