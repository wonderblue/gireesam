extends SceneTree

const ACT_V := preload("res://scripts/act_v_story.gd")
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
	for route_name in ["StoryActIButton", "StoryActIIButton", "StoryActIIIButton", "StoryActIVButton"]:
		_check(title.find_child(route_name, true, false) != null, route_name + " remains a separate title-screen route")
	var act_v_button: Button = title.find_child("StoryActVButton", true, false)
	_check(act_v_button != null and act_v_button.text == root.get_node("I18n").t("title.story_act_v"), "title exposes a dedicated Act V route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_v_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_v, "Act V launches in isolated story mode")
	_check(game.stage.id == "act_v_disguise_search" and game._route_stage_ids() == ["act_v_disguise_search"], "Act V is exactly one compact standalone episode")
	_check(game.player.story_observer_mode, "the route uses a silent observer, not a coercive character as player viewpoint")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "the story route adds no combat or hostile chase")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	for beat_index in range(game.stage.story_beats.size()):
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact() and game.act_i.interact(), "Act V stop is reachable and playable: " + str(beat.location))
		_check(game.active_story_dialogue.get("id", "") == beat.id, "the expected Act V card opens: " + str(beat.id))
		if beat_index == 2:
			_check(game.active_story_dialogue.choices.size() == 3, "the search stop offers a compact evidence interaction")
		game._choose_dialogue(game.stage_index, 0)
		await process_frame
		_check(game.score == original_score and game.reputation == original_reputation, "Act V choices do not award score or reputation")
	_check(game.act_i.can_clear_scene(), "the single-stage route clears after all three story beats")
	_check(game.act_i.objective_text().contains("ACT V"), "the route objective is labeled Act V")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_V_STORY_PASS] three Act V stops, no Act VII displacement, evidence boundaries, source notes, and isolated route")
	for failure: String in failures:
		push_error("[ACT_V_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT_V.load_stage(0)
	_check(not stage.is_empty() and ACT_V.validate_stage(stage), "Act V story stage passes its schema")
	_check(ACT_V.stage_ids() == ["act_v_disguise_search"] and ACT_V.load_stage(1).is_empty(), "Act V catalog contains exactly one episode")
	_check(ACT_V.SOURCE_WITNESS == "1909 second-edition first printing" and ACT_V.SOURCE_URLS.size() == 6, "Act V cites all six pages in the selected 1909 witness")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var locations: Array[String] = []
	var multi_choice_beats: Array = beats.filter(func(beat: Dictionary): return beat.choices.size() > 1)
	for beat: Dictionary in beats:
		locations.append(beat.location)
	_check(locations == ACT_V.LOCATIONS and beats.size() == 3, "the route is a compact three-stop source sequence")
	_check(multi_choice_beats.size() == 1 and multi_choice_beats[0].id == "act_v_police_bribery", "only the police/bribery stop offers multiple responses")
	_check(beats[0].line.contains("wakes in alarm") and beats[0].line.contains("dream") and beats[0].line.contains("not a settled account"), "Lubdhavadhani's fear is shown without turning it into verified evidence")
	_check(beats[1].line.contains("late-night card game") and beats[1].line.contains("disguised visitor") and beats[1].line.contains("not a clue to collect"), "the disguise confusion protects the visitor's dignity and privacy")
	_check(beats[2].line.contains("conflicting orders") and beats[2].line.contains("bribe money") and beats[2].line.contains("legal posturing") and beats[2].line.contains("establishes what happened"), "the search farce separates accusations from proof")
	_check(beats[2].choices.size() == 3 and beats[2].choice_responses.size() == 3, "the evidence interaction has one response for each choice")
	var episode_copy := JSON.stringify(beats).to_lower()
	for forbidden in ["sowjanya", "power of attorney", "adoption"]:
		_check(not episode_copy.contains(forbidden), "Act V game copy excludes later-act material: " + forbidden)
	for url: String in ACT_V.SOURCE_URLS:
		_check(url.contains("/51.html") or url.contains("/52.html") or url.contains("/53.html") or url.contains("/54.html") or url.contains("/55.html") or url.contains("/56.html"), "source URL is within Act V scenes 51-56")
		_check(not url.ends_with("/75.html") and not url.ends_with("/76.html"), "later Act VII scenes are not source URLs")
	for beat: Dictionary in beats:
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.get("choice_responses", []):
			for character: String in value:
				var codepoint := character.unicode_at(0)
				_check(codepoint < 0x0C00 or codepoint > 0x0C7F, "Act V adaptation adds no unverified Telugu dialogue")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_V_ADAPTATION.md")
	_check(notes.contains(ACT_V.SOURCE_WITNESS) and notes.contains("1961-based witness used for the Act I Telugu UI"), "Act V notes distinguish this witness from Act I")
	_check(notes.contains("Plot facts used") and notes.contains("Adaptation choices") and notes.contains("not translation or quotation"), "contributor notes label facts and adaptation separately")
	_check(notes.contains("Act VII") and notes.contains("scenes 75–76") and notes.contains("not moved into this episode"), "contributor notes preserve later-act chronology")
	for url: String in ACT_V.SOURCE_URLS:
		_check(notes.contains(url), "contributor notes cite Act V source page: " + url)
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "the ordinary three-stage escape campaign is unchanged")
	_check("act_v_disguise_search" not in standard, "the Act V episode is isolated from the standard campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
