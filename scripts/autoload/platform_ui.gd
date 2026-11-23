extends Node
## PLATFORM UI — iOS safe areas, one-hand layout, and accessibility settings.
##
## iPhones with a Dynamic Island eat ~47 pt at the top and the home indicator
## claims ~34 pt at the bottom. The bottom band is the dangerous one: B and A
## sit there, and a swipe-up during a fight backgrounds the game.

signal settings_changed

const CFG := "user://settings.cfg"

var safe_top := 0.0
var safe_bottom := 0.0
var safe_left := 0.0
var safe_right := 0.0

# Accessibility
var subtitle_size := 1.0        # 0.85 / 1.0 / 1.3
var high_contrast_blips := false
var hold_to_heavy := false      # false = tap
var camera_invert_y := false
var camera_sensitivity := 1.0
var one_hand_left := false      # mirrors the action cluster to the left thumb
var touch_scale := 1.0

func _ready() -> void:
	# Reserve sensible defaults immediately: get_display_safe_area() returns an
	# empty rect on desktop and on some devices, and a zero inset puts touch
	# buttons under the home indicator.
	safe_top = 12.0
	safe_bottom = 16.0
	_refresh_safe_area()
	load_settings()
	get_viewport().size_changed.connect(_refresh_safe_area)

func _refresh_safe_area() -> void:
	# get_display_safe_area is in screen pixels; convert to the UI space.
	var vp_size := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return
	var safe := DisplayServer.get_display_safe_area()
	var sx := vp_size.x / float(win.x)
	var sy := vp_size.y / float(win.y)
	safe_top = maxf(0.0, float(safe.position.y) * sy)
	safe_bottom = maxf(0.0, float(win.y - (safe.position.y + safe.size.y)) * sy)
	safe_left = maxf(0.0, float(safe.position.x) * sx)
	safe_right = maxf(0.0, float(win.x - (safe.position.x + safe.size.x)) * sx)
	# Floor: proportional to view height so a 844 pt phone reserves a sane band
	# even when the platform reports nothing useful.
	safe_top = maxf(safe_top, vp_size.y * 0.035)
	safe_bottom = maxf(safe_bottom, vp_size.y * 0.045)

## Where action buttons must stop, so the home-indicator swipe never triggers them.
func action_floor() -> float:
	return safe_bottom + 14.0

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("a11y", "subtitle_size", subtitle_size)
	cf.set_value("a11y", "high_contrast_blips", high_contrast_blips)
	cf.set_value("a11y", "hold_to_heavy", hold_to_heavy)
	cf.set_value("input", "invert_y", camera_invert_y)
	cf.set_value("input", "sensitivity", camera_sensitivity)
	cf.set_value("ui", "one_hand_left", one_hand_left)
	cf.set_value("ui", "touch_scale", touch_scale)
	cf.save(CFG)
	settings_changed.emit()

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CFG) != OK:
		return
	subtitle_size = float(cf.get_value("a11y", "subtitle_size", 1.0))
	high_contrast_blips = bool(cf.get_value("a11y", "high_contrast_blips", false))
	hold_to_heavy = bool(cf.get_value("a11y", "hold_to_heavy", false))
	camera_invert_y = bool(cf.get_value("input", "invert_y", false))
	camera_sensitivity = float(cf.get_value("input", "sensitivity", 1.0))
	one_hand_left = bool(cf.get_value("ui", "one_hand_left", false))
	touch_scale = float(cf.get_value("ui", "touch_scale", 1.0))
