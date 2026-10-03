extends Node
## Stateful play director for the first two scenes; choices never alter score or reputation.

signal dialogue_requested(data: Dictionary)
signal prompt_changed(text: String)

const ACT_I := preload("res://scripts/act_i_story.gd")
const HIDE_DURATION := 3.2
const INTERACTION_RADIUS := 118.0

var game: Node
var stage: Dictionary = {}
var beat_index := 0
var stealth_active := false
var stealth_elapsed := 0.0
var prompt := ""
var offer_record_shared := false

func begin(owner_game: Node, stage_data: Dictionary) -> void:
	game = owner_game
	stage = stage_data
	beat_index = 0
	stealth_active = false
	stealth_elapsed = 0.0
	prompt = ""
	offer_record_shared = false
	if is_instance_valid(game.player):
		game.player.set_story_hidden(false)
	var art := game.get_node_or_null("WorldArt")
	if art != null:
		art.ram_hidden = false
		art.evidence_review_available = false
	_set_prompt("")

func tick(delta: float) -> void:
	if game == null or not is_instance_valid(game.player) or game.finished or game.resetting:
		_set_prompt("")
		return
	if stealth_active:
		if game.player.story_hidden:
			stealth_elapsed += delta
			var art := game.get_node_or_null("WorldArt")
			if art != null:
				art.search_progress = clampf(stealth_elapsed / HIDE_DURATION, 0.0, 1.0)
			if stealth_elapsed >= HIDE_DURATION:
				stealth_active = false
				game.player.set_story_hidden(false)
				if art != null:
					art.search_progress = 0.0
					art.ram_hidden = false
				var search_scene := _current_beat()
				if not search_scene.is_empty() and str(search_scene.id) == "room_search_accident":
					dialogue_requested.emit(search_scene)
		else:
			# The search pauses when Gireesam peeks out. He can hide again at the same bed.
			stealth_elapsed = 0.0
			var art := game.get_node_or_null("WorldArt")
			if art != null:
				art.search_progress = 0.0
		_set_prompt(I18n.t("story.prompt.stealth"))
		return
	var beat := _current_beat()
	if beat.is_empty() or str(beat.id) == "room_search_accident":
		_set_prompt("")
		return
	var player_position: Vector2 = game.player.global_position
	var marker_x := float(beat.x)
	var near_marker := absf(player_position.x - marker_x) <= INTERACTION_RADIUS and absf(player_position.y - game.GROUND_Y + 26.0) < 180.0
	if near_marker:
		_set_prompt(I18n.t("story.prompt.interact", {"marker": str(beat.marker)}))
	else:
		_set_prompt("")

func can_interact() -> bool:
	return not prompt.is_empty() and not game.finished and not game.resetting

func interact() -> bool:
	if not can_interact():
		return false
	if stealth_active:
		game.player.set_story_hidden(not game.player.story_hidden)
		return true
	var beat := _current_beat()
	if beat.is_empty():
		return false
	dialogue_requested.emit(beat.duplicate(true))
	return true

func resolve_choice(choice_index: int) -> String:
	var beat := _current_beat()
	if beat.is_empty():
		return ""
	var choices: Array = beat.choices
	var safe_index := clampi(choice_index, 0, choices.size() - 1)
	var response := str(beat.response)
	var choice_responses: Array = beat.get("choice_responses", [])
	if safe_index < choice_responses.size():
		response = str(choice_responses[safe_index])
	var art := game.get_node_or_null("WorldArt")
	if str(beat.id) == "room_cash_offer":
		offer_record_shared = safe_index == 0
		if art != null:
			art.evidence_review_available = offer_record_shared
	if str(beat.id) == "room_ramappantulu_hides" and art != null:
		art.ram_hidden = true
	if bool(beat.get("stealth", false)):
		beat_index += 1
		stealth_active = true
		stealth_elapsed = 0.0
		game.player.set_story_hidden(true)
		_set_prompt(I18n.t("story.prompt.stealth"))
		return response
	beat_index += 1
	_set_prompt("")
	return response

func can_clear_scene() -> bool:
	_skip_unavailable_beats()
	return beat_index >= stage.get("story_beats", []).size() and not stealth_active

func objective_text() -> String:
	if stage.is_empty():
		return ""
	var act := str(stage.get("act", "I"))
	var find_key := "story.objective.find"
	var exit_key := "story.objective.exit"
	if act == "II":
		find_key = "story.objective.act2.find"
		exit_key = "story.objective.act2.exit"
	elif act == "III":
		find_key = "story.objective.act3.find"
		exit_key = "story.objective.act3.exit"
	if stealth_active:
		return I18n.t("story.objective.hide")
	var beat := _current_beat()
	if not beat.is_empty():
		if str(beat.id) == "room_search_accident":
			return I18n.t("story.objective.hide")
		return I18n.t(find_key, {"marker": str(beat.marker)})
	return I18n.t(exit_key)

func _current_beat() -> Dictionary:
	_skip_unavailable_beats()
	var beats: Array = stage.get("story_beats", [])
	if beat_index < 0 or beat_index >= beats.size():
		return {}
	return beats[beat_index]

func current_beat_data() -> Dictionary:
	return _current_beat().duplicate(true)

func _skip_unavailable_beats() -> void:
	var beats: Array = stage.get("story_beats", [])
	while beat_index >= 0 and beat_index < beats.size():
		var beat: Dictionary = beats[beat_index]
		if not bool(beat.get("requires_recorded_offer", false)) or offer_record_shared:
			return
		beat_index += 1

func _set_prompt(value: String) -> void:
	if prompt == value:
		return
	prompt = value
	prompt_changed.emit(prompt)
