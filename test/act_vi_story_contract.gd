extends SceneTree

const ACT_VI := preload("res://scripts/act_vi_story.gd")
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
	for route_name in ["StoryActIButton", "StoryActIIButton", "StoryActIIIButton", "StoryActIVButton", "StoryActVButton"]:
		_check(title.find_child(route_name, true, false) != null, route_name + " remains a separate title-screen route")
	var act_vi_button: Button = title.find_child("StoryActVIButton", true, false)
	_check(act_vi_button != null and act_vi_button.text == root.get_node("I18n").t("title.story_act_vi"), "title exposes a dedicated Act VI route")
	title.queue_free()
	await process_frame

	var game = load("res://scenes/story_act_vi_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 5:
		await process_frame
	_check(game.story_mode and game.story_act_vi, "Act VI launches in isolated story mode")
	_check(game.stage.id == "act_vi_evidence_chain" and game._route_stage_ids() == ["act_vi_evidence_chain"], "Act VI is one compact standalone episode")
	_check(game.player.story_observer_mode, "the route uses a silent observer rather than an accused or vulnerable person")
	_check(game.get_tree().get_nodes_in_group("enemy").is_empty() and not game.attack_button.visible, "the story route adds no combat or hostile chase")
	var original_score: int = game.score
	var original_reputation: int = game.reputation
	for beat_index in range(game.stage.story_beats.size()):
		var beat: Dictionary = game.stage.story_beats[beat_index]
		game.player.position = Vector2(float(beat.x), 594.0)
		game.act_i.tick(0.01)
		_check(game.act_i.can_interact() and game.act_i.interact(), "Act VI stop is reachable and playable: " + str(beat.location))
		_check(game.active_story_dialogue.get("id", "") == beat.id, "the expected Act VI card opens: " + str(beat.id))
		_check(game.active_story_dialogue.choices.size() == 3, "each stop offers a compact evidence/resource interaction: " + str(beat.id))
		game._choose_dialogue(game.stage_index, beat_index % 3)
		await process_frame
		_check(game.score == original_score and game.reputation == original_reputation, "Act VI choices do not award score or reputation")
	_check(game.act_i.can_clear_scene(), "the route clears only after all five record cards")
	_check(game.act_i.objective_text().contains("ACT VI"), "the route objective is labeled Act VI")
	game.queue_free()
	await process_frame
	root.get_node("GameAudio").stop_game()
	OS.delay_msec(180)
	await process_frame
	if failures.is_empty():
		print("[ACT_VI_STORY_PASS] five stops, allegation boundary, separate Meenakshi thread, evidence/resource chain, and campaign isolation")
	for failure: String in failures:
		push_error("[ACT_VI_STORY_FAIL] " + failure)
	quit(1 if not failures.is_empty() else 0)

func _test_content() -> void:
	var stage: Dictionary = ACT_VI.load_stage(0)
	_check(not stage.is_empty() and ACT_VI.validate_stage(stage), "Act VI story stage passes its schema")
	_check(ACT_VI.stage_ids() == ["act_vi_evidence_chain"] and ACT_VI.load_stage(1).is_empty(), "Act VI catalog contains exactly one episode")
	_check(ACT_VI.SOURCE_WITNESS == "1909 second-edition first printing" and ACT_VI.SOURCE_URLS.size() == 7, "Act VI cites all seven pages in the selected 1909 witness")
	if stage.is_empty():
		return
	var beats: Array = stage.story_beats
	var locations: Array[String] = []
	for beat: Dictionary in beats:
		locations.append(beat.location)
	_check(locations == ACT_VI.LOCATIONS and beats.size() == 5, "the route is a compact five-stop source sequence")
	var episode_copy := JSON.stringify(beats).to_lower()
	var report := JSON.stringify(beats[0]).to_lower()
	_check(report.contains("alleges") and report.contains("hearsay") and report.contains("no witnessed abduction") and report.contains("is established here"), "the missing-disciple report remains an allegation, not established abduction")
	_check(not episode_copy.contains("gireesam abducted"), "game copy does not state an abduction as fact")
	var ledger := JSON.stringify(beats[1]).to_lower()
	for category in ["borrowed money", "pawn", "bribe", "false testimony", "not proof"]:
		_check(ledger.contains(category), "the case ledger distinguishes resource/evidence category: " + category)
	var meena := JSON.stringify(beats[2]).to_lower()
	_check(meena.contains("lubdhavadhani") and meena.contains("meenakshi") and meena.contains("regrets") and meena.contains("old man"), "the separate Meenakshi beat records her father's regret")
	_check(meena.contains("not evidence about the missing-disciple allegation") and meena.contains("distinct from the disputed missing-disciple case") and not meena.contains("karataka's disciple"), "Meenakshi's beat explicitly remains separate from the missing-disciple case")
	_check(not JSON.stringify(beats[3]).contains("Meenakshi"), "the missing-disciple beat does not use Meenakshi as evidence, property, obstacle, or rescue token")
	var madhuravani := JSON.stringify(beats[3]).to_lower()
	_check(madhuravani.contains("madhuravani") and madhuravani.contains("karataka's disciple") and madhuravani.contains("honest") and madhuravani.contains("no testimony is forced"), "Madhuravani protects the disciple while pressing for an honest, voluntary path")
	var sowjanya := JSON.stringify(beats[4]).to_lower()
	for concern in ["refuses payment", "reform", "education", "care", "property", "honest inquiry"]:
		_check(sowjanya.contains(concern), "Sowjanya's rights-focused counsel includes: " + concern)
	_check(not sowjanya.contains("meenakshi") and sowjanya.contains("separate missing-disciple allegation"), "Sowjanya's household advice stays separate from the missing-person claim")
	for beat: Dictionary in beats:
		_check(beat.choices.size() == 3 and beat.choice_responses.size() == 3, "each choice has a specific bounded response: " + str(beat.id))
		for value: String in [beat.title, beat.line, beat.response] + beat.choices + beat.choice_responses:
			for character: String in value:
				var codepoint := character.unicode_at(0)
				_check(codepoint < 0x0C00 or codepoint > 0x0C7F, "Act VI adaptation adds no unverified Telugu dialogue")
	for index in ACT_VI.SOURCE_URLS.size():
		_check(ACT_VI.SOURCE_URLS[index].ends_with("/%d.html" % (61 + index)), "source list covers only Act VI scenes 61–67")
	var notes := FileAccess.get_file_as_string("res://docs/ACT_VI_ADAPTATION.md")
	_check(notes.contains(ACT_VI.SOURCE_WITNESS) and notes.contains("1961-based witness used for the Act I Telugu UI"), "notes distinguish the 1909 and Act I witnesses")
	_check(notes.contains("Source facts used"), "notes label the source facts")
	_check(notes.contains("not a translation or quotation") and notes.contains("Adaptation choices"), "notes identify original English adaptation")
	_check(notes.contains("allegation only") and notes.contains("not identified with the disciple"), "notes state the missing-disciple/Meenakshi boundary")
	for url: String in ACT_VI.SOURCE_URLS:
		_check(notes.contains(url), "contributor notes cite Act VI source page: " + url)
	var standard: Array = load("res://scripts/stage_catalog.gd").stages()
	_check(standard == ["sunlit_nook", "lofty_lounge", "temple_rooftops"], "the ordinary three-stage campaign is unchanged")
	_check("act_vi_evidence_chain" not in standard, "Act VI is isolated from the ordinary campaign")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
