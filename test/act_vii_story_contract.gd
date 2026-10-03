extends SceneTree

const ACT_VII := preload("res://scripts/act_vii_story.gd")
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
	for route_name in ["StoryActIButton", "StoryActIIButton", "StoryActIIIButton", "StoryActIVButton", "StoryActVButton", "StoryActVIButton"]:
		_check(title.find_child(route_name, true, false) != null, route_name + " remains a separate title-screen route")
	var act_vii_button: Button = title.find_child("StoryActVIIButton", true, false)
	_check(act_vii_button != null and act_vii_button.text == root.get_node("I18n").t("title.story_act_vii"), "title exposes the dedicated Act VII finale route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_vii_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_vii, "Act VII launches in isolated story mode")
	_check(game.stage.id == "act_vii_case_resolution" and game._route_stage_ids() == ["act_vii_case_resolution"], "Act VII is exactly one compact standalone finale")
	_check(game.player.story_observer_mode, "the route uses a silent observer, not an accused or vulnerable person as the player")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "the finale adds no combat or chase")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	for beat_index in range(game.stage.story_beats.size()):
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact() and game.act_i.interact(), "Act VII stop is reachable and playable: " + str(beat.location))
		_check(game.active_story_dialogue.get("id", "") == beat.id, "the expected Act VII card opens: " + str(beat.id))
		_check(game.active_story_dialogue.choices.size() == beat.choices.size(), "each Act VII interaction exposes its evidence choices: " + str(beat.id))
		game._choose_dialogue(game.stage_index, beat_index % beat.choices.size())
		await process_frame
		_check(game.score == original_score and game.reputation == original_reputation, "Act VII choices do not award score or reputation")
	_check(game.act_i.can_clear_scene(), "the finale clears only after all five evidence and agency stops")
	_check(game.act_i.objective_text().contains("ACT VII"), "the objective is labeled Act VII")
	_check(root.get_node("I18n").t("story.act7.ending_copy").contains("Madhuravani, Sowjanya, and Buchchamma"), "the route ending shown after scene clear centers the three women")
	var save_store = root.get_node("SaveStore")
	var saved_data: Dictionary = save_store.data.duplicate(true)
	var cloud_profile = root.get_node("CloudProfile")
	var saved_session: Dictionary = cloud_profile.session.duplicate(true)
	cloud_profile.session = {}
	game.time_left = 0.0
	game._on_goal_reached()
	_check(game.finished and game.terminal_result.get("outcome", "") == "victory", "the final goal closes the playable Act VII route")
	var ending_copy: String = root.get_node("I18n").t("story.act7.ending_copy")
	var ending_visible := false
	if game.message_panel != null:
		for label: Label in game.message_panel.find_children("", "Label", true, false):
			ending_visible = ending_visible or label.text == ending_copy
	_check(ending_visible, "the actual Act VII terminal panel shows its women-centered ending copy")
	_check(game.score == original_score and game.reputation == original_reputation, "closing the file awards no Act VII score or reputation")
	save_store.data = saved_data
	save_store.save()
	cloud_profile.session = saved_session
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_VII_STORY_PASS] evidence procedure, respectful identity reveal, distinct family matters, women-led ending, and campaign isolation")
	for failure: String in failures:
		push_error("[ACT_VII_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT_VII.load_stage(0)
	_check(not stage.is_empty() and ACT_VII.validate_stage(stage), "Act VII story stage passes its schema")
	_check(ACT_VII.stage_ids() == ["act_vii_case_resolution"] and ACT_VII.load_stage(1).is_empty(), "Act VII catalog contains exactly one episode")
	_check(ACT_VII.SOURCE_WITNESS == "1909 second-edition first printing" and ACT_VII.SOURCE_URLS.size() == 6, "Act VII cites the six-page 1909 witness sequence")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var locations: Array[String] = []
	for beat: Dictionary in beats:
		locations.append(beat.location)
	_check(locations == ACT_VII.LOCATIONS and beats.size() == 5, "the finale is a compact five-stop episode")

	var opening := JSON.stringify(beats[0]).to_lower()
	_check(opening.contains("allegation") and opening.contains("lacks a verified identity") and opening.contains("firsthand account"), "the missing-person charge remains an allegation before evidence")
	var pre_reveal := JSON.stringify(beats.slice(0, 3)).to_lower()
	_check(not pre_reveal.contains("male disciple in disguise") and not pre_reveal.contains("not meenakshi or buchchamma"), "the identity is not asserted before the voluntary disclosure")
	_check(opening.contains("disputed property claim") and opening.contains("not prove a girl or property was taken"), "the contested property claim is separated from observed confusion")

	var register := JSON.stringify(beats[1]).to_lower()
	_check(beats[1].choices.size() == 4 and beats[1].choice_responses.size() == 4, "the evidence register has a focused four-way classification interaction")
	for category in ["direct observation", "hearsay", "payment", "threats", "coaching", "fabrication"]:
		_check(register.contains(category), "the testimony interaction separately records " + category)
	_check(register.contains("polishetty") and register.contains("gavarayya") and register.contains("not proof"), "source-grounded testimony problems are kept distinct from proof")

	var family_records := JSON.stringify(beats[2]).to_lower()
	_check(family_records.contains("subbi") and family_records.contains("meenakshi") and family_records.contains("distinct family matters"), "Subbi's bargain and Meenakshi's separate family matter remain distinct")
	_check(family_records.contains("a clue, prize, obstacle, or mission object"), "neither daughter becomes a mission object, prize, or obstacle")

	var reveal := JSON.stringify(beats[3]).to_lower()
	_check(reveal.contains("karataka śāstri's male disciple in disguise") and reveal.contains("not meenakshi or buchchamma"), "the reveal identifies the disciple and distinguishes both women")
	_check(reveal.contains("not a punchline, mission object, prize, or obstacle") and reveal.contains("voluntary, uncoached account"), "the identity reveal is respectful and voluntary")

	var ending := JSON.stringify(beats[4]).to_lower()
	_check(ending.contains("sowjanya recognizes") and ending.contains("rejects gireesam") and ending.contains("buchchamma's education and independence"), "Sowjanya recognizes Madhuravani, rejects Gireesam, and supports Buchchamma's future")
	_check(ending.contains("madhuravani, sowjanya, and buchchamma") and ending.contains("not gireesam"), "the closing beat centers the three women rather than Gireesam")
	var episode_copy := JSON.stringify(beats).to_lower()
	for forbidden in ["catch the girl", "gender gag", "romance reward", "chase"]:
		_check(not episode_copy.contains(forbidden), "the finale avoids the prohibited device: " + forbidden)

	for beat: Dictionary in beats:
		_check(beat.choices.size() == beat.choice_responses.size(), "each choice has a specific bounded response: " + str(beat.id))
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.choice_responses:
			for character: String in value:
				var codepoint := character.unicode_at(0)
				_check(codepoint < 0x0C00 or codepoint > 0x0C7F, "Act VII adds no unverified Telugu dialogue")

	for index in ACT_VII.SOURCE_URLS.size():
		_check(ACT_VII.SOURCE_URLS[index].ends_with("/%d.html" % (71 + index)), "source list covers only Act VII scenes 71–76")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_VII_ADAPTATION.md")
	_check(notes.contains(ACT_VII.SOURCE_WITNESS) and notes.contains("1961-based witness used for the Act I Telugu UI"), "notes distinguish the 1909 Act VII and Act I witnesses")
	_check(notes.contains("Source facts used") and notes.contains("Adaptation choices") and notes.contains("not a translation or quotation"), "notes label source facts separately from adaptation")
	_check(notes.contains("not a claim that these pages record a formal court judgment") and notes.contains("The reveal is delivered as a person's identity") and notes.contains("voluntary, uncoached\" phrasing is consent-and-procedure framing added by this adaptation"), "notes label the procedural close, voluntary testimony framing, and respectful reveal as adaptation")
	for url: String in ACT_VII.SOURCE_URLS:
		_check(notes.contains(url), "contributor notes cite Act VII source page: " + url)
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "the ordinary three-stage campaign is unchanged")
	_check("act_vii_case_resolution" not in standard, "Act VII remains isolated from the standard campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
