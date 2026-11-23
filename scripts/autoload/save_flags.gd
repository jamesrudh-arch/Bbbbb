extends Node
## SAVE FLAGS — tiny persistent switches that are not part of a save slot
## (intro seen, notice dismissed, first-run checks).

const PATH := "user://flags.cfg"

func _read() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(PATH)
	return cf

func opening_seen() -> bool:
	return bool(_read().get_value("intro", "opening_seen", false))

func mark_opening_seen() -> void:
	var cf := _read()
	cf.set_value("intro", "opening_seen", true)
	cf.save(PATH)
