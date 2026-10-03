extends SceneTree

const ACT_IV := preload("res://scripts/act_iv_story.gd")
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
	_check(title.find_child("StoryActIIButton", true, false) != null, "Act II remains a separate title-screen route")
	_check(title.find_child("StoryActIIIButton", true, false) != null, "Act III remains a separate title-screen route")
	var act_iv_button: Button = title.find_child("StoryActIVButton", true, false)
	_check(act_iv_button != null and act_iv_button.text == root.get_node("I18n").t("title.story_act_iv"), "title exposes a dedicated Act IV route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_iv_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_iv, "Act IV launches in isolated story mode")
	_check(game.stage.id == "act_iv_letter_audit" and game._route_stage_ids() == ["act_iv_letter_audit"], "Act IV is exactly one compact standalone episode")
	_check(game.player.story_observer_mode, "the episode uses a silent observer marker, not a coercive character as player viewpoint")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "the episode adds no combat or hostile chase")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	var first: Dictionary = game.stage.story_beats[0]
	game.player.position = Vector2(float(first.x), 594.0)
	game.act_i.tick(0.01)
	_check(game.act_i.can_interact() and game.act_i.interact(), "the letter-chain interpretation stop is reachable and playable")
	_check(game.active_story_dialogue.get("id", "") == first.id, "the first Act IV story card opens")
	_check(game.active_story_dialogue.choices.size() == 3, "the evidence card offers verification, delay, or help")
	game._choose_dialogue(game.stage_index, 0)
	_check(game.route_label.text.contains("Verification would require the named sender"), "choosing verification does not fabricate a result")
	_check(game.score == original_score and game.reputation == original_reputation, "the evidence choice awards no score or reputation")
	for beat_index in range(1, game.stage.story_beats.size()):
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact(), "Act IV location is reachable: " + str(beat.location))
		_check(game.act_i.interact(), "Act IV story card opens: " + str(beat.id))
		_check(game.active_story_dialogue.get("id", "") == beat.id, "the expected Act IV card is shown: " + str(beat.id))
		game._choose_dialogue(game.stage_index, 0)
		_check(game.score == original_score and game.reputation == original_reputation, "Act IV scene choice does not award score or reputation")
	_check(game.act_i.can_clear_scene(), "the episode clears only after all three location beats")
	_check(game.act_i.objective_text().contains("ACT IV"), "the route objective is labeled Act IV")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_IV_STORY_PASS] three locations, letter evidence choices, ethical boundaries, source notes, and isolated route")
	for failure: String in failures:
		push_error("[ACT_IV_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT_IV.load_stage(0)
	_check(not stage.is_empty() and ACT_IV.validate_stage(stage), "Act IV story stage passes its schema")
	_check(ACT_IV.stage_ids() == ["act_iv_letter_audit"] and ACT_IV.load_stage(1).is_empty(), "Act IV catalog contains exactly one episode")
	_check(ACT_IV.SOURCE_WITNESS == "1909 second-edition first printing" and ACT_IV.SOURCE_URLS.size() == 5, "Act IV uses the selected 1909 witness and cites all five scene pages")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var locations: Array[String] = []
	var multi_choice_beats: Array = beats.filter(func(beat: Dictionary): return beat.choices.size() > 1)
	for beat: Dictionary in beats:
		locations.append(beat.location)
	_check(locations == ACT_IV.LOCATIONS and beats.size() == 3, "the route follows the three requested source locations in order")
	_check(multi_choice_beats.size() == 1 and multi_choice_beats[0].id == "act_iv_letter_chain", "only the evidence audit offers a multi-option interaction")
	var letter: Dictionary = beats[0]
	_check(letter.line.contains("Ramappantulu") and letter.line.contains("Agnihotravadhani's name") and letter.line.contains("Lubdhavadhani has the paper"), "the letter beat distinguishes author, named sender, and current holder")
	_check(letter.line.contains("Madhuravani improvises") and letter.line.contains("has not confirmed"), "the scene records Madhuravani's improvisation and the sender's unverified status")
	_check(letter.choices.size() == 3 and letter.choices[0].contains("Verify") and letter.choices[1].contains("Delay") and letter.choices[2].contains("Seek help"), "players can verify, delay, or seek help")
	_check(letter.choice_responses.size() == 3 and letter.choice_responses[0].contains("paper alone cannot establish") and letter.choice_responses[1].contains("does not settle the marriage") and letter.choice_responses[2].contains("no confession is forced"), "all evidence paths stay cautious and avoid forced disclosure")
	_check(letter.response.contains("named sender has not confirmed") and letter.response.contains("source plot"), "the player cannot substitute their verdict for independent sender confirmation or change the plot")
	var wedding: Dictionary = beats[1]
	_check(wedding.line.contains("one-night custom") and wedding.line.contains("costs") and wedding.line.contains("status") and wedding.line.contains("respectability"), "the wedding farce targets bargaining, status, and male respectability")
	_check(wedding.line.contains("does not establish who wrote the letter") and wedding.line.contains("not a bargaining token"), "the wedding beat keeps the letter and the woman's future out of player control")
	var buchchamma: Dictionary = beats[2]
	_check(buchchamma.line.contains("teaching Venkatesam") and buchchamma.line.contains("only way to stop her sister's arranged marriage") and buchchamma.line.contains("threats of self-harm"), "the residence beat preserves the source plot's lesson and coercive elopement pitch")
	_check(buchchamma.line.contains("does not make her responsible") and buchchamma.response.contains("not romance") and buchchamma.response.contains("neither asks Buchchamma to solve") and buchchamma.response.contains("nor rewards the proposed elopement"), "Buchchamma bears no blame and pressured elopement earns no romance reward")
	for beat: Dictionary in beats:
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.get("choice_responses", []):
			for character: String in value:
				var codepoint := character.unicode_at(0)
				_check(codepoint < 0x0C00 or codepoint > 0x0C7F, "Act IV adaptation adds no unverified Telugu dialogue")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_IV_ADAPTATION.md")
	_check(notes.contains(ACT_IV.SOURCE_WITNESS) and notes.contains("1961-based witness used for the Act I Telugu UI"), "Act IV notes distinguish the selected source from the 1961 Act I witness")
	for url: String in ACT_IV.SOURCE_URLS:
		_check(notes.contains(url), "contributor notes cite Act IV scene source: " + url)
	_check(notes.contains("Text facts used") and notes.contains("Adaptation choices") and notes.contains("not translation or quotation"), "contributor notes separate source facts from adaptation and label all prose")
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "the ordinary three-stage campaign remains unchanged")
	_check("act_iv_letter_audit" not in standard, "the Act IV episode is isolated from the ordinary campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
