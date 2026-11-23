extends Node
## DIFFICULTY — five ascending axes, per the design freeze.
##
## The rule that governs everything here: difficulty changes BEHAVIOUR, never
## health bars. Nothing in this file multiplies a health pool. What it produces is
## a single 1..6 "threat level" that the AI, the spawner and the event director
## read to decide how hard the city pushes back.
##
## The five axes:
##   1. DISTRICT HEAT     where you are. Fixed by district tier.
##   2. FACTION PRESSURE  who you have angered. Moves with trust.
##   3. NOTORIETY         how well known you are. Rises with kills, jobs, story.
##   4. STORY ESCALATION  which chapter you are in. Authored, not emergent.
##   5. ADAPTIVE          how well you are actually doing. Invisible, bounded.
##
## The adaptive axis is the controversial one, so it is deliberately gentle and
## capped: it can add at most 1 threat level and subtract at most 1, and it never
## touches a boss encounter. It exists to stop the game being boring when the
## player is cruising, and to stop it being impossible when they are drowning —
## not to rubber-band every fight to the wire.

signal threat_changed(level: int, breakdown: Dictionary)

## Weights are relative, not absolute. They combine into a 0..1 pressure score.
const W_DISTRICT := 0.40
const W_FACTION := 0.18
const W_NOTORIETY := 0.20
const W_STORY := 0.14
const W_ADAPTIVE := 0.08

## Adaptive state.
const ADAPTIVE_RANGE := 1.0          # max +/- threat level it can contribute
const ADAPT_WINDOW := 90.0           # seconds of history considered
const ADAPT_RAMP := 0.10             # how fast the belief moves per event

var world: Node3D = null

# Adaptive belief: -1 (player is struggling) .. +1 (player is cruising)
var _belief := 0.0
var _events: Array = []              # [{t, kind}]
var _clock := 0.0
var _last_level := -1

# Player performance tracking.
var _hits_taken := 0.0
var _hits_landed := 0.0
var _fights_lost := 0             # consecutive
var _fights_won := 0              # consecutive
var _deaths_without_progress := 0

func setup(w: Node3D) -> void:
	world = w

func _process(delta: float) -> void:
	_clock += delta
	# Decay the adaptive belief toward neutral so a bad patch does not define
	# the whole session.
	_belief = move_toward(_belief, 0.0, delta * 0.010)
	var lvl := threat_level()
	if lvl != _last_level:
		_last_level = lvl
		threat_changed.emit(lvl, breakdown())

# ------------------------------------------------------------------- axes
## 1. Where you are: the district's authored tier is the floor.
func axis_district() -> float:
	var d: String = str(Game.current_district)
	var tier: int = int(Content.DISTRICTS.get(d, {}).get("tier", 1))
	return float(tier - 1) / 5.0          # 0..1

## 2. Who you have angered. Hostile factions push back harder.
func axis_faction() -> float:
	var worst := 0.0
	for f in Game.trust:
		var t := float(Game.trust[f])
		if t < 0.0:
			worst = maxf(worst, clampf(-t / 100.0, 0.0, 1.0))
	# Being hunted by the police counts double: they are the only faction that
	# can pursue you anywhere in the city.
	if Game.wanted >= 3:
		worst = maxf(worst, 0.5 + float(Game.wanted - 3) * 0.2)
	return clampf(worst, 0.0, 1.0)

## 3. How well known you are. Named kills, completed work, story progress.
func axis_notoriety() -> float:
	var kills: int = int(Game.stats.get("fights_won", 0))
	var jobs: int = int(Game.completed_missions.size())
	var bosses: int = int(Game.stats.get("bosses_beaten", 0))
	var score := float(kills) * 0.012 + float(jobs) * 0.035 + float(bosses) * 0.10
	return clampf(score, 0.0, 1.0)

## 4. Where you are in the story. Authored escalation, deterministic.
func axis_story() -> float:
	var beat: int = int(Game.stats.get("story_chapter", 1))
	return clampf(float(beat - 1) / 15.0, 0.0, 1.0)

## 5. How you are actually doing. Invisible, bounded, gentle.
func axis_adaptive() -> float:
	return clampf(_belief * ADAPTIVE_RANGE, -ADAPTIVE_RANGE, ADAPTIVE_RANGE)

func breakdown() -> Dictionary:
	return {
		"district": axis_district(),
		"faction": axis_faction(),
		"notoriety": axis_notoriety(),
		"story": axis_story(),
		"adaptive": axis_adaptive(),
	}

# --------------------------------------------------------------- the level
## Combined pressure 0..1.
func pressure() -> float:
	var p := axis_district() * W_DISTRICT \
		+ axis_faction() * W_FACTION \
		+ axis_notoriety() * W_NOTORIETY \
		+ axis_story() * W_STORY \
		+ (axis_adaptive() + 1.0) * 0.5 * W_ADAPTIVE
	return clampf(p, 0.0, 1.0)

## A threat level 1..6 that spawners and AI tiers read.
func threat_level() -> int:
	var floor_tier: int = int(Content.DISTRICTS.get(str(Game.current_district), {}).get("tier", 1))
	# The non-district axes contribute ADDITIVELY above the district floor, so
	# being notorious genuinely makes even the starting districts harder.
	# The old formula took max(district, lift), which meant a tier-1 district
	# clamped everything back to 1 no matter how notorious you were -- so
	# awards and reputation had no mechanical effect where the player spends
	# their first hours.
	var extra: float = axis_faction() * W_FACTION \
		+ axis_notoriety() * W_NOTORIETY \
		+ axis_story() * W_STORY \
		+ (axis_adaptive() + 1.0) * 0.5 * W_ADAPTIVE
	var extra_max: float = W_FACTION + W_NOTORIETY + W_STORY + W_ADAPTIVE
	var extra_norm: float = clampf(extra / maxf(0.001, extra_max), 0.0, 1.0)
	# Capped at +2 so Vesper Heights remains the hardest place in the city.
	var lift := int(round(extra_norm * 2.0))
	return clampi(floor_tier + lift, 1, 6)

func tier_for_spawn() -> int:
	return threat_level()

## Enemy count for a spawned encounter, scaled by pressure. Deliberately small
## numbers: two well-behaved enemies read better than five that stack.
func squad_size(base: int = 2) -> int:
	return clampi(base + int(round(pressure() * 2.0)), 1, 6)

# ------------------------------------------------------- adaptive tracking
## The player got hit. Repeated hits mean they are struggling.
func note_player_hit() -> void:
	_hits_taken += 1.0
	_recompute_belief()

## The player landed a hit.
func note_player_hit_landed() -> void:
	_hits_landed += 1.0
	_recompute_belief()

func note_fight_won() -> void:
	_fights_won += 1
	_fights_lost = 0
	_belief = move_toward(_belief, 0.45, 0.12 * float(mini(_fights_won, 3)))
	_events.append({"t": _clock, "kind": "win"})

func note_fight_lost() -> void:
	_fights_lost += 1
	_fights_won = 0
	_belief = move_toward(_belief, -0.55, 0.14 * float(mini(_fights_lost, 3)))
	_events.append({"t": _clock, "kind": "loss"})

func note_death() -> void:
	_deaths_without_progress += 1
	# Dying repeatedly is the clearest signal the game is too hard right now.
	_belief = move_toward(_belief, -0.9, 0.20 * float(mini(_deaths_without_progress, 3)))
	_events.append({"t": _clock, "kind": "death"})

func note_progress() -> void:
	_deaths_without_progress = 0
	_events.append({"t": _clock, "kind": "progress"})

func _recompute_belief() -> void:
	var total := _hits_landed + _hits_taken
	if total < 8.0:
		return                          # too little evidence to judge
	var ratio: float = _hits_landed / total     # 0.5 = even trade
	# Above 0.65 they are winning exchanges comfortably; below 0.35 they are not.
	var target := clampf((ratio - 0.5) * 2.4, -0.8, 0.8)
	_belief = move_toward(_belief, target, ADAPT_RAMP)
	# Wind the counters down so the belief tracks recent form, not all-time.
	_hits_landed *= 0.94
	_hits_taken *= 0.94

## Debug / tuning surface. Never shown to the player.
func debug_line() -> String:
	var b := breakdown()
	return "threat %d/%d  district %.2f faction %.2f notoriety %.2f story %.2f adaptive %+.2f" % [
		threat_level(), 6, b["district"], b["faction"], b["notoriety"], b["story"], b["adaptive"]]

func reset() -> void:
	_belief = 0.0
	_hits_taken = 0.0
	_hits_landed = 0.0
	_fights_lost = 0
	_fights_won = 0
	_deaths_without_progress = 0
	_events.clear()
