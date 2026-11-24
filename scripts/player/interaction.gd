extends Node
## INTERACTION — context-sensitive B button outside combat.
## The same physical button is dodge while a fight is live (combat.gd consumes
## it and returns early), and interact when the player is calm. It scans for the
## nearest interactable: NPC, door/portal, pickup, vehicle, job board.

var player: CharacterBody3D
var system: Node = null
var current: Node3D = null

const RANGE := 3.2

func setup(p: CharacterBody3D, interaction_system: Node) -> void:
	player = p
	system = interaction_system

func _process(_delta: float) -> void:
	if player == null or system == null: return
	if player.vehicle != null:
		current = null
		return
	# Suppressed while fighting: combat owns B in that state.
	if player.combat != null and player.combat.in_combat:
		current = null
		system.set_prompt(null)
		return
	current = system.find_nearest(player.global_position, RANGE)
	system.set_prompt(current)
	if current != null and Input.is_action_just_pressed("interact"):
		system.activate(current, player)
