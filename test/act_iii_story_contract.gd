extends SceneTree

const ACT_III := preload("res://scripts/act_iii_story.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	_test_content()
	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	await process_frame
	_check(title.find_child("StoryActIButton", true, false) != null, "Act I remains a separate title-screen route")
	_check(title.find_child("StoryActIIButton", true, false) != null, "Act II remains a separate title-screen route")
	var act_iii_button: Button = title.find_child("StoryActIIIButton", true, false)
	_check(act_iii_button != null and act_iii_button.text == root.get_node("I18n").t("title.story_act_iii"), "title exposes a dedicated Act III route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_iii_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_iii, "Act III launches in isolated story mode")
	_check(game.stage.id == "act_iii_route" and game._route_stage_ids() == ["act_iii_route"], "Act III is exactly one compact standalone episode")
	_check(game.player.story_observer_mode, "the route uses a silent observer marker, not Gireesam as the player's viewpoint")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "the episode adds no combat or hostile chase")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	var first: Dictionary = game.stage.story_beats[0]
	game.player.position = Vector2(float(first.x), 594.0)
	game.act_i.tick(0.01)
	_check(game.act_i.can_interact() and game.act_i.interact(), "the front-room interpretation stop is reachable and playable")
	_check(game.active_story_dialogue.get("id", "") == first.id, "the front-room story card opens")
	_check(game.active_story_dialogue.choices.size() == 2, "the claims-versus-conduct interaction presents two readings")
	game._choose_dialogue(game.stage_index, 1)
	_check(game.route_label.text.contains("responsibility stays with Ramappantulu"), "the conduct reading names responsibility without changing the story")
	_check(game.score == original_score and game.reputation == original_reputation, "the branching reading gives no score or reputation")
	for beat_index in range(1, game.stage.story_beats.size()):
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact(), "Act III location is reachable: " + str(beat.location))
		_check(game.act_i.interact(), "Act III story card opens: " + str(beat.id))
		_check(game.active_story_dialogue.get("id", "") == beat.id, "the expected Act III card is shown: " + str(beat.id))
		game._choose_dialogue(game.stage_index, 0)
		_check(game.score == original_score and game.reputation == original_reputation, "Act III scene choice does not award score or reputation")
	_check(game.act_i.can_clear_scene(), "the episode clears only after all four location beats")
	_check(game.act_i.objective_text().contains("ACT III"), "the route objective is labeled Act III")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_III_STORY_PASS] four locations, claim/conduct interaction, preserved boundaries, source notes, and isolated route")
	for failure: String in failures:
		push_error("[ACT_III_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT_III.load_stage(0)
	_check(not stage.is_empty() and ACT_III.validate_stage(stage), "Act III story stage passes its schema")
	_check(ACT_III.stage_ids() == ["act_iii_route"] and ACT_III.load_stage(1).is_empty(), "Act III catalog contains exactly one episode")
	_check(ACT_III.SOURCE_WITNESS == "1909 second-edition first printing" and ACT_III.SOURCE_URLS.size() == 4, "Act III source witness is distinct and has four cited scene pages")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var locations: Array[String] = []
	var multi_choice_beats: Array = beats.filter(func(beat: Dictionary): return beat.choices.size() > 1)
	for beat: Dictionary in beats:
		locations.append(beat.location)
	_check(locations == ACT_III.LOCATIONS, "the route follows the four source locations in order")
	_check(beats.size() == 4 and multi_choice_beats.size() == 1 and multi_choice_beats[0].id == "act_iii_front_room_claims", "exactly one meaningful multi-option interaction anchors Madhuravani's front-room perspective")
	var front_room: Dictionary = beats[0]
	_check(front_room.line.contains("mortgaged") and front_room.line.contains("evades debts") and front_room.line.contains("obligations of their relationship") and front_room.line.contains("forces a kiss after her refusal"), "the front-room card names the debt and relationship evasion and the boundary violation without euphemizing it")
	_check(front_room.choice_responses.size() == 2 and front_room.choice_responses[0] != front_room.choice_responses[1], "both readings have distinct explicit consequences")
	_check(front_room.choice_responses[0].contains("costs are still carried") and front_room.choice_responses[1].contains("responsibility stays with Ramappantulu"), "the interaction keeps consequence-bearers and responsibility visible")
	_check(front_room.response.contains("not Madhuravani's refusal"), "the player's reading cannot change Madhuravani's boundary or canon")
	var bedroom: Dictionary = beats[1]
	_check(bedroom.line.contains("Karataka") and bedroom.line.contains("male disciple") and bedroom.line.contains("disguise") and bedroom.line.contains("Madhuravani joins his scheme"), "the bedroom beat preserves the disguise and Madhuravani's role in the plan")
	_check(bedroom.line.contains("put the disguised disciple in danger") and bedroom.response.contains("does not expose the disguise"), "the disciple's risk remains serious and non-playable")
	var outside: Dictionary = beats[2]
	_check(outside.line.contains("Gireesam") and outside.line.contains("Buchchamma") and outside.line.contains("editing his principles"), "the outside-house beat pairs courtship with Gireesam's self-interest")
	var garden: Dictionary = beats[3]
	_check(garden.line.contains("improvised claims") and garden.line.contains("courting Buchchamma") and garden.response.contains("not a prize"), "the garden keeps the pseudo-lesson comic target on Gireesam and Buchchamma's agency")
	for beat: Dictionary in beats:
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.get("choice_responses", []):
			for character: String in value:
				var codepoint := character.unicode_at(0)
				_check(codepoint < 0x0C00 or codepoint > 0x0C7F, "Act III adaptation adds no unverified Telugu dialogue")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_III_ADAPTATION.md")
	_check(notes.contains(ACT_III.SOURCE_WITNESS) and notes.contains("1961-based text used for the Act I Telugu UI pilot"), "contributor notes distinguish the Act III and Act I witnesses")
	for url: String in ACT_III.SOURCE_URLS:
		_check(notes.contains(url), "contributor notes cite Act III scene source: " + url)
	_check(notes.contains("Text facts used") and notes.contains("Adaptation choices") and notes.contains("not translation or quotation"), "contributor notes separate source facts from adaptation and label all prose")
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "the ordinary three-stage campaign remains unchanged")
	_check("act_iii_route" not in standard, "the Act III episode is isolated from the ordinary campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
