extends SceneTree

const ACT := preload("res://scripts/act_vi_story.gd")
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
	var act_button: Button = title.find_child("StoryActVIButton", true, false)
	_check(act_button != null and act_button.text == root.get_node("I18n").t("title.story_act_vi"), "title exposes a dedicated Act VI route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_vi_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_vi, "Act VI launches in isolated story mode")
	_check(game.stage.id == "act_vi_wedding_reversal" and game._route_stage_ids() == ["act_vi_wedding_reversal"], "Act VI is one compact standalone episode")
	_check(game.player.story_observer_mode, "Act VI uses a non-speaking listener marker")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "Act VI adds no combat")
	_check(not game.player.try_attack(), "observer mode rejects attack requests")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	for beat: Dictionary in game.stage.story_beats:
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact(), "Act VI marker reachable: " + str(beat.id))
		_check(game.act_i.interact(), "Act VI card opens: " + str(beat.id))
		var choice_index := 0
		game._choose_dialogue(game.stage_index, choice_index)
		_check(game.score == original_score and game.reputation == original_reputation, "story choices award no score or reputation")
	_check(game.act_i.can_clear_scene(), "episode clears after required beats")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_VI_STORY_PASS] compact source-grounded Act VI route")
	for failure: String in failures:
		push_error("[ACT_VI_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT.load_stage(0)
	_check(not stage.is_empty() and ACT.validate_stage(stage), "Act VI stage validates")
	_check(ACT.stage_ids() == ["act_vi_wedding_reversal"], "Act VI catalog has one episode")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var multi: Array = beats.filter(func(beat: Dictionary): return beat.choices.size() > 1)
	_check(beats.size() == 3 and multi.size() == 1, "exactly one multi-option interaction")
	for beat: Dictionary in beats:
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.get("choice_responses", []):
			for character: String in value:
				_check(character.unicode_at(0) < 0x0C00 or character.unicode_at(0) > 0x0C7F, "no unverified Telugu dialogue")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_VI_ADAPTATION.md")
	_check(notes.contains("1909 second-edition first printing"), "notes label 1909 witness")
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check("act_vi_wedding_reversal" not in standard, "Act VI isolated from ordinary campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
