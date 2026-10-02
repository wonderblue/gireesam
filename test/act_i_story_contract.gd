extends SceneTree

const ACT_I := preload("res://scripts/act_i_story.gd")
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
	var story_button: Button = title.find_child("StoryActIButton", true, false)
	_check(story_button != null and story_button.text == root.get_node("I18n").t("title.story_act_i"), "title exposes a dedicated Act I story route")
	title.queue_free()
	await process_frame
	var game = load("res://scenes/story_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.stage.id == "act_i_bonkula_dibba", "story launch selects Bonkula Dibba")
	_check(not game.tutorial.active, "story launch does not show the generic escape tutorial")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty(), "the literary slice does not invent a hostile chase")
	_check(not game.attack_button.visible, "combat control is hidden in the story route")
	_check(InputMap.has_action("interact") and InputMap.action_get_events("interact").any(func(event): return event is InputEventKey and event.physical_keycode == KEY_E), "E is mapped to scene interaction")
	_check(InputMap.action_get_events("interact").any(func(event): return event is InputEventJoypadButton and event.button_index == JOY_BUTTON_Y), "gamepad Y is mapped to scene interaction")
	_check(is_instance_valid(game.story_interact_button), "story route creates an on-screen interaction control")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	var first: Dictionary = game.stage.story_beats[0]
	game.player.position = Vector2(float(first.x), 594.0)
	game.act_i.tick(0.01)
	_check(game.act_i.can_interact(), "first Bonkula Dibba beat becomes reachable")
	_check(game.act_i.interact(), "first story marker opens")
	_check(game.active_story_dialogue.id == "dibba_debt", "debt scene is the first adapted beat")
	game._choose_dialogue(game.stage_index, 0)
	_check(game.score == original_score and game.reputation == original_reputation, "story choice does not change score or reputation")
	for beat_index in range(1, game.stage.story_beats.size()):
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact(), "Bonkula marker reachable: " + str(beat.id))
		game.act_i.interact()
		game._choose_dialogue(game.stage_index, 0)
	_check(game.act_i.can_clear_scene(), "Bonkula route requires and then accepts all story beats")
	_check(game.stage.story_beats[1].line.contains("scarcely taught") and game.stage.story_beats[2].line.contains("books, cash, sweets, cigars, and transport"), "tutor contrast and full request list are present")
	game._on_goal_reached()
	_check(game.finished and game.terminal_result.is_empty(), "Bonkula exit transitions to the room scene, not a completed campaign")
	game.next_stage()
	await process_frame
	_check(game.stage.id == "act_i_madhuravani_room", "second location is Madhuravani's room")
	var room_score: int = game.score
	var room_reputation: int = game.reputation
	_check(game.stage.story_beats[-1].id == "room_madhuravani_terms", "Madhuravani's terms are the final beat")
	_check(game.stage.story_beats[-1].line.contains("not a Gireesam-wins-her outcome"), "ending rejects a Gireesam-wins-her outcome")
	for beat_index in 2:
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		game.act_i.interact()
		if beat.id == "room_cash_offer":
			_check(beat.choice_responses.size() == beat.choices.size(), "each evidence choice has an explicit, non-rewarding response")
		game._choose_dialogue(game.stage_index, 0)
		if beat.id == "room_cash_offer":
			_check(game.route_label.text.contains("neutral case note"), "recorded evidence response grants no leverage")
	_check(game.act_i.offer_record_shared and game.get_node("WorldArt").evidence_review_available, "recording the witnessed offer opens the optional review marker")
	var review_beat: Dictionary = game.act_i.current_beat_data()
	_check(review_beat.id == "room_evidence_review", "shared evidence unlocks the review scene")
	game.player.position = Vector2(float(review_beat.x), 594.0)
	game.act_i.tick(0.01)
	_check(game.act_i.can_interact(), "unlocked evidence review is playable")
	game.act_i.interact()
	game._choose_dialogue(game.stage_index, 0)
	var ram_hides_beat: Dictionary = game.act_i.current_beat_data()
	_check(ram_hides_beat.id == "room_ramappantulu_hides", "Ramappantulu's source-order hiding beat precedes Gireesam's")
	game.player.position = Vector2(float(ram_hides_beat.x), 594.0)
	game.act_i.tick(0.01)
	game.act_i.interact()
	game._choose_dialogue(game.stage_index, 0)
	_check(game.get_node("WorldArt").ram_hidden, "Ramappantulu is staged under the bed before Gireesam")
	var hide_beat: Dictionary = game.act_i.current_beat_data()
	game.player.position = Vector2(float(hide_beat.x), 594.0)
	game.act_i.tick(0.01)
	game.act_i.interact()
	game._choose_dialogue(game.stage_index, 0)
	_check(game.player.story_hidden and game.act_i.stealth_active, "Hyderabad-invention beat sends Gireesam under the bed")
	game.act_i.tick(3.19)
	_check(game.active_story_dialogue.is_empty(), "broom-search payoff waits for the stealth beat")
	game.act_i.tick(0.02)
	_check(not game.player.story_hidden and game.active_story_dialogue.get("id", "") == "room_search_accident", "completed hide triggers Pootakullamma's accidental strike on Ramappantulu")
	_check(not game.get_node("WorldArt").ram_hidden, "the broom exposes Ramappantulu after the shared hiding beat")
	game._choose_dialogue(game.stage_index, 0)
	var final_beat: Dictionary = game.stage.story_beats[-1]
	game.player.position = Vector2(float(final_beat.x), 594.0)
	game.act_i.tick(0.01)
	game.act_i.interact()
	game._choose_dialogue(game.stage_index, 0)
	_check(game.act_i.can_clear_scene(), "Act I can finish only after Madhuravani defines her terms")
	_check(game.score == room_score and game.reputation == room_reputation, "no Act I choice adds a coercion/deception reward")
	_check(root.get_node("I18n").t("story.act1.ending").contains("MADHURAVANI"), "final route result remains Madhuravani-led")
	game.act_i.begin(game, game.stage)
	game.act_i.beat_index = 1
	var private_response: String = game.act_i.resolve_choice(1)
	_check(not game.act_i.offer_record_shared and game.act_i.current_beat_data().id == "room_ramappantulu_hides" and private_response.contains("No shared evidence-review stop opens"), "leaving the private exchange unrecorded skips only the optional review")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_I_STORY_PASS] source-grounded beats, two-scene routing, no rewards, stealth and Madhuravani-led ending")
	for failure: String in failures:
		push_error("[ACT_I_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var ids := ACT_I.stage_ids()
	_check(ids == ["act_i_bonkula_dibba", "act_i_madhuravani_room"], "Act I stage order is isolated and stable")
	_check(ACT_I.SOURCE_REVISION == "252038" and ACT_I.SOURCE_EDITION_LABEL == "1961", "source witness revision and page edition label are explicit")
	if FileAccess.file_exists("res://docs/ACT_I_ADAPTATION.md"):
		var notes := FileAccess.get_file_as_string("res://docs/ACT_I_ADAPTATION.md")
		_check(notes.contains(ACT_I.SOURCE_URL), "adaptation docs point to the exact permanent source revision")
	for index in ids.size():
		var stage: Dictionary = ACT_I.load_stage(index)
		_check(not stage.is_empty() and ACT_I.validate_stage(stage), "valid story-stage schema: " + str(ids[index]))
		for beat: Dictionary in stage.get("story_beats", []):
			_check(beat.choices.all(func(choice): return choice is String), "story choices are non-rewarding presentation choices: " + str(beat.id))
			for value: String in [beat.title, beat.line, beat.response] + beat.get("choice_responses", []):
				for character: String in value:
					_check(character.unicode_at(0) < 0x0C00 or character.unicode_at(0) > 0x0C7F, "adaptation does not invent Telugu dialogue: " + str(beat.id))
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "Act I does not mutate the ordinary three-stage route")
	var invalid := ACT_I.load_stage(0).duplicate(true)
	invalid.story_beats[0].x = invalid.goal[0]
	_check(not ACT_I.validate_stage(invalid), "story beat at/after the exit is rejected")
	var room: Dictionary = ACT_I.load_stage(1)
	_check(room.story_beats[1].id == "room_cash_offer" and room.story_beats[1].line.contains("two hundred rupees"), "evidence action records the witness's stated 200-rupee offer")
	_check(room.story_beats[2].get("requires_recorded_offer", false), "optional negotiation review is gated by the evidence choice")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
