extends Node
## STYLE RANK — the metre that rewards fighting well rather than fighting often.
##
## Borrowed in spirit from Sifu and Devil May Cry, but built to one rule from the
## design freeze: it must be readable at a glance on a phone, mid-fight, with a
## thumb covering part of the screen. So it is a letter grade plus a thin bar,
## never a number you have to read.
##
## Ranks: D - C - B - A - S - SS
## Sources of score: landing hits, varied attacks, dodges, counters, finishers.
## Decay: constant bleed from the moment you stop being good, faster at high rank,
## and a hard reset if you take a hit while above A.
##
## Decay is the whole design. Without it, mashing one attack would climb to SS.
## The variety bonus is what stops that: repeating the same attack in a row scores
## almost nothing after the third time.

signal rank_changed(new_rank: String, old_rank: String)
signal score_changed(score: float, maximum: float)
signal rank_lost(reason: String)

const RANKS := ["D", "C", "B", "A", "S", "SS"]
## Score thresholds for each rank.
const THRESHOLDS := [0.0, 90.0, 240.0, 460.0, 760.0, 1150.0]
## Bleed per second at each rank. Higher ranks fall faster.
const DECAY := [0.0, 5.0, 9.0, 15.0, 24.0, 36.0]
## Taking a hit above this rank index costs the whole grade.
const PUNISH_FROM := 3

var score := 0.0
var rank_index := 0
var best_rank_index := 0
var peak_score := 0.0
var in_fight := false

var _last_kind := ""
var _repeat := 0
var _kinds_used := {}
var _since_hit := 0.0
var _idle_grace := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func rank_name() -> String:
	return RANKS[rank_index]

func score_for_next() -> float:
	if rank_index >= RANKS.size() - 1:
		return THRESHOLDS[-1]
	return THRESHOLDS[rank_index + 1]

func progress() -> float:
	var lo: float = THRESHOLDS[rank_index]
	var hi := score_for_next()
	if hi <= lo:
		return 1.0
	return clampf((score - lo) / (hi - lo), 0.0, 1.0)

func begin_fight() -> void:
	in_fight = true
	_last_kind = ""
	_repeat = 0
	_kinds_used.clear()

func end_fight(victory: bool) -> void:
	in_fight = false
	if victory:
		# A clean win banks the score rather than letting it bleat away.
		pass
	else:
		_reset("defeat")

## A landed hit. `kind` is the attack name so repeats can be detected.
func on_hit(kind: String, damage: float, was_counter: bool = false) -> void:
	if not in_fight:
		begin_fight()
	_since_hit = 0.0
	_idle_grace = 2.6

	var gain := 6.0 + damage * 0.35

	# Variety: the same attack over and over pays almost nothing.
	if kind == _last_kind:
		_repeat += 1
		gain *= clampf(1.0 - _repeat * 0.30, 0.08, 1.0)
	else:
		_repeat = 0
	_last_kind = kind

	# Fresh tools are worth more — this is what pushes players to use the kit.
	if not _kinds_used.has(kind):
		_kinds_used[kind] = true
		gain *= 1.55

	if was_counter:
		gain *= 2.2
		_since_hit = -0.0
	_add(gain)

func on_dodge() -> void:
	if not in_fight:
		return
	_idle_grace = 2.6
	_add(14.0)

func on_counter() -> void:
	if not in_fight:
		return
	_idle_grace = 2.6
	_add(30.0)

func on_finisher() -> void:
	_add(70.0)

## The player got hit. This is the cost of fighting badly.
func on_player_hit() -> void:
	_since_hit = 0.0
	if rank_index >= PUNISH_FROM:
		_reset("you got hit")
		return
	score = maxf(0.0, score - THRESHOLDS[rank_index] * 0.55)
	_recompute()

func _add(amount: float) -> void:
	score += amount
	peak_score = maxf(peak_score, score)
	_recompute()

func _recompute() -> void:
	var old := rank_index
	var i := 0
	for t in THRESHOLDS:
		if score >= float(t):
			i = THRESHOLDS.find(t)
	rank_index = clampi(i, 0, RANKS.size() - 1)
	best_rank_index = maxi(best_rank_index, rank_index)
	score_changed.emit(score, score_for_next())
	if rank_index != old:
		rank_changed.emit(RANKS[rank_index], RANKS[old])

func _reset(reason: String) -> void:
	var had := rank_index
	score = 0.0
	rank_index = 0
	_last_kind = ""
	_repeat = 0
	score_changed.emit(score, THRESHOLDS[1])
	if had > 0:
		rank_lost.emit(reason)
		rank_changed.emit(RANKS[0], RANKS[had])

func _process(delta: float) -> void:
	if not in_fight:
		# Out of combat the rank slowly fades so a stale SS does not carry over.
		if score > 0.0:
			score = maxf(0.0, score - 26.0 * delta)
			_recompute()
		return
	_idle_grace = maxf(0.0, _idle_grace - delta)
	if _idle_grace > 0.0:
		return
	score = maxf(0.0, score - float(DECAY[rank_index]) * delta)
	_recompute()
