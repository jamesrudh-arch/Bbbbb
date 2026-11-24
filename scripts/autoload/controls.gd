extends Node
## CONTROLS — authoritative input map, built at boot.
## Binding contract (non-negotiable, from the design brief):
##   X = punch      Y = heavy attack    A = kick    B = dodge
##   B outside combat = contextual interaction (same physical button, no conflict:
##   combat.gd only consumes B while a fight is live; otherwise interaction.gd owns it).
## Keyboard/gamepad mirrors exist for desktop testing and XOGOT controllers; the
## on-screen touch layout in hud.gd issues the exact same action names.

const ACTIONS := {
	# ---- movement ----
	"move_forward": {"keys": [KEY_W, KEY_UP], "pad": [JOY_BUTTON_DPAD_UP]},
	"move_back": {"keys": [KEY_S, KEY_DOWN], "pad": [JOY_BUTTON_DPAD_DOWN]},
	"move_left": {"keys": [KEY_A, KEY_LEFT], "pad": [JOY_BUTTON_DPAD_LEFT]},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "pad": [JOY_BUTTON_DPAD_RIGHT]},
	"sprint": {"keys": [KEY_SHIFT], "pad": [JOY_BUTTON_LEFT_STICK]},
	"jump": {"keys": [KEY_SPACE], "pad": [JOY_BUTTON_A]},
	"crouch": {"keys": [KEY_CTRL], "pad": [JOY_BUTTON_B]},
	"lock_on": {"keys": [KEY_Q], "pad": [JOY_BUTTON_RIGHT_STICK]},
	# ---- combat: the four required faces ----
	"punch": {"keys": [KEY_J], "pad": [JOY_BUTTON_X]},
	"heavy": {"keys": [KEY_K], "pad": [JOY_BUTTON_Y]},
	"kick": {"keys": [KEY_L], "pad": [JOY_BUTTON_LEFT_SHOULDER]},
	"dodge": {"keys": [KEY_SPACE], "pad": [JOY_BUTTON_RIGHT_SHOULDER]},
	"block": {"keys": [KEY_CTRL], "pad": [JOY_BUTTON_LEFT_SHOULDER]},
	"counter": {"keys": [KEY_H], "pad": [JOY_BUTTON_DPAD_LEFT]},
	"aim": {"keys": [KEY_R], "pad": [JOY_AXIS_TRIGGER_LEFT]},
	"shoot": {"keys": [KEY_F], "pad": [JOY_AXIS_TRIGGER_RIGHT]},
	"reload": {"keys": [KEY_T], "pad": [JOY_BUTTON_DPAD_RIGHT]},
	"weapon_switch": {"keys": [KEY_G], "pad": [JOY_BUTTON_DPAD_UP]},
	# ---- world ----
	"interact": {"keys": [KEY_E], "pad": [JOY_BUTTON_B]},
	"enter_vehicle": {"keys": [KEY_E], "pad": [JOY_BUTTON_B]},
	"exit_vehicle": {"keys": [KEY_E], "pad": [JOY_BUTTON_B]},
	# ---- driving ----
	"steer_left": {"keys": [KEY_A, KEY_LEFT], "pad": [JOY_BUTTON_DPAD_LEFT]},
	"steer_right": {"keys": [KEY_D, KEY_RIGHT], "pad": [JOY_BUTTON_DPAD_RIGHT]},
	"throttle": {"keys": [KEY_W, KEY_UP], "pad": [JOY_AXIS_TRIGGER_RIGHT]},
	"brake": {"keys": [KEY_S, KEY_DOWN], "pad": [JOY_AXIS_TRIGGER_LEFT]},
	"handbrake": {"keys": [KEY_SPACE], "pad": [JOY_BUTTON_RIGHT_SHOULDER]},
	"horn": {"keys": [KEY_H], "pad": [JOY_BUTTON_LEFT_STICK]},
	# ---- ui ----
	"pause": {"keys": [KEY_ESCAPE], "pad": [JOY_BUTTON_START]},
	"ui_accept": {"keys": [KEY_ENTER, KEY_SPACE]},
	"ui_cancel": {"keys": [KEY_ESCAPE]},
}

func _ready() -> void:
	_build()

func _build() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		var cfg: Dictionary = ACTIONS[action]
		for k in cfg.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in cfg.get("pad", []):
			if b is int and b >= JOY_BUTTON_A:
				var jb := InputEventJoypadButton.new()
				jb.button_index = b
				InputMap.action_add_event(action, jb)
		# Triggers arrive as axis events, not buttons.
		if action == "aim":
			var ax := InputEventJoypadMotion.new()
			ax.axis = JOY_AXIS_TRIGGER_LEFT
			ax.axis_value = 1.0
			InputMap.action_add_event(action, ax)
		if action == "shoot" or action == "throttle":
			var ax2 := InputEventJoypadMotion.new()
			ax2.axis = JOY_AXIS_TRIGGER_RIGHT
			ax2.axis_value = 1.0
			InputMap.action_add_event(action, ax2)
		if action == "brake":
			var ax3 := InputEventJoypadMotion.new()
			ax3.axis = JOY_AXIS_TRIGGER_LEFT
			ax3.axis_value = -1.0
			InputMap.action_add_event(action, ax3)
