extends SceneTree

const ACT_II := preload("res://scripts/act_ii_story.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("I18n").set_locale("en")
	await process_frame
	_test_content()
	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	await process_frame
	_check(title.find_child("StoryActIButton", true, false) != null, "Act I remains a separate title-screen route")
	var act_ii_button: Button = title.find_child("StoryActIIButton", true, false)
	_check(act_ii_button != null and act_ii_button.text == root.get_node("I18n").t("title.story_act_ii"), "title exposes a dedicated Act II household route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_ii_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_ii, "Act II launches in the isolated story mode")
	_check(game.stage.id == "act_ii_household" and game._route_stage_ids() == ["act_ii_household"], "Act II is one compact standalone episode")
	_check(game.player.story_observer_mode, "the household route uses a non-speaking listener marker, not Gireesam as its viewpoint")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "the household episode adds no combat or hostile chase")
	_check(not game.player.try_attack(), "observer mode rejects keyboard/gamepad attack requests")
	_check(game.get_tree().get_nodes_in_group("yarn_projectile").is_empty(), "observer mode does not spawn yarn projectiles")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	for beat: Dictionary in game.stage.story_beats:
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact(), "Act II marker is reachable: " + str(beat.id))
		_check(game.act_i.interact(), "Act II story card opens: " + str(beat.id))
		_check(game.active_story_dialogue.get("id", "") == beat.id, "the expected Act II card is shown: " + str(beat.id))
		var choice_index := 1 if beat.id == "act_ii_subbi_offer" else 0
		game._choose_dialogue(game.stage_index, choice_index)
		_check(game.score == original_score and game.reputation == original_reputation, "story choices do not award score or reputation")
		if beat.id == "act_ii_subbi_offer":
			_check(game.route_label.text.contains("Naming the cost") and game.route_label.text.contains("offer"), "the selected consequence is shown without cancelling the proposal")
	_check(game.act_i.can_clear_scene(), "the compact episode clears only after each required household/temple beat")
	_check(game.act_i.objective_text().contains("ACT II"), "the route objective is labeled as Act II")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_II_STORY_PASS] household facts, one claim/consequence interaction, risky unresolved plan, and separate route")
	for failure: String in failures:
		push_error("[ACT_II_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT_II.load_stage(0)
	_check(not stage.is_empty() and ACT_II.validate_stage(stage), "Act II household story stage passes its schema")
	_check(ACT_II.stage_ids() == ["act_ii_household"] and ACT_II.load_stage(1).is_empty(), "Act II catalog contains exactly one episode")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var multi_choice_beats: Array = beats.filter(func(beat: Dictionary): return beat.choices.size() > 1)
	_check(beats.size() == 3 and multi_choice_beats.size() == 1, "the episode has exactly one meaningful multi-option interaction")
	var education: Dictionary = beats[0]
	_check(education.line.contains("Venkamma") and education.line.contains("English education") and education.line.contains("costs") and education.line.contains("Gireesam demonstrates"), "the household opens on Venkamma's education-cost debate and Gireesam's claimed usefulness")
	var proposal: Dictionary = beats[1]
	_check(proposal.line.contains("Subbi") and proposal.line.contains("offers his daughter Subbi to the wealthy older Lubdhavadhani") and proposal.line.contains("1,800 rupees") and not proposal.line.contains("Venkatesam"), "Subbi is offered to Lubdhavadhani, not Venkatesam")
	_check(proposal.line.contains("Venkamma") and proposal.line.contains("Buchchamma") and proposal.line.contains("resist"), "the women’s resistance is explicit")
	_check(proposal.choice_responses.size() == 2 and proposal.choice_responses[0] != proposal.choice_responses[1], "claim and consequence choices produce distinct, explicit responses")
	_check(proposal.choice_responses[0].contains("not consent") and proposal.choice_responses[1].contains("does not claim"), "neither choice grants consent or silently cancels the proposal")
	var temple: Dictionary = beats[2]
	_check(temple.line.contains("male disciple") and temple.line.contains("pose as a girl") and temple.line.contains("cost the disciple his life"), "the temple disguise plan carries its source-stated danger")
	_check(temple.line.contains("stops before it is carried out"), "the adaptation does not turn the proposal into a wish-fulfillment rescue")
	for beat: Dictionary in beats:
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.get("choice_responses", []):
			for character: String in value:
				_check(character.unicode_at(0) < 0x0C00 or character.unicode_at(0) > 0x0C7F, "Act II adaptation adds no unverified Telugu dialogue")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_II_ADAPTATION.md")
	_check(notes.contains("1909 second-edition first printing") and notes.contains("1961-based"), "contributor notes label the two distinct witnesses")
	_check(notes.contains("not a translation") and notes.contains("new mechanic"), "contributor notes separate text facts from adaptation")
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "ordinary three-stage campaign remains unchanged")
	_check("act_ii_household" not in standard, "the Act II story stage is isolated from the ordinary campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
