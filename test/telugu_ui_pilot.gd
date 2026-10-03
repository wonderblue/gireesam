extends SceneTree

const EXPECTED_LINE := "వేశ్య అనగానే అంత చులకనా పంతులుగారూ?"
const ROOM_DATA_PATH := "res://data/story/act_i_madhuravani_room.json"
const UI_MEDIUM_PATH := "res://assets/template/fonts/ui_medium.tres"
const TELUGU_FONT_PATH := "res://assets/template/fonts/telugu/noto_sans_telugu_medium.tres"

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var room_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOM_DATA_PATH))
	var arrival: Dictionary = room_data.story_beats[0]
	_check(arrival.get("telugu_line", "") == EXPECTED_LINE, "room-arrival beat preserves the exact verified Unicode line")

	var game = load("res://scenes/story_game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for _frame in 3:
		await process_frame
	game._open_dialogue(game.stage_index, arrival)
	await process_frame
	var quote_label := game.find_child("TeluguPilotLine", true, false) as Label
	_check(quote_label != null and quote_label.text == EXPECTED_LINE and quote_label.is_visible_in_tree(), "the room-arrival dialogue card shows the one Telugu pilot line")

	var ui_font := load(UI_MEDIUM_PATH) as FontVariation
	var telugu_font := load(TELUGU_FONT_PATH) as FontVariation
	_check(ui_font != null and telugu_font != null, "bundled Telugu and UI font variations load")
	if ui_font != null and telugu_font != null:
		_check(ui_font.base_font.has_char("A".unicode_at(0)), "Nunito primary font retains Latin glyph coverage")
		_check(not ui_font.fallbacks.is_empty() and ui_font.fallbacks[0].resource_path == TELUGU_FONT_PATH, "Telugu font is the first UI fallback")
		for index in range(EXPECTED_LINE.length()):
			var codepoint := EXPECTED_LINE.unicode_at(index)
			if codepoint >= 0x0C00 and codepoint <= 0x0C7F:
				_check(telugu_font.has_char(codepoint), "Noto Sans Telugu covers U+%04X" % codepoint)

		var shaped_line := TextLine.new()
		var probe_text := EXPECTED_LINE + " Act I"
		var accepted := shaped_line.add_string(probe_text, ui_font, 28, "te")
		_check(accepted and shaped_line.get_line_width() > 0.0, "Godot shapes a non-empty Telugu-plus-Latin line")
		var text_server := TextServerManager.get_primary_interface()
		var shaped := shaped_line.get_rid()
		var saw_telugu_run := false
		var saw_latin_run := false
		for run_index in range(text_server.shaped_get_run_count(shaped)):
			var run_text: String = text_server.shaped_get_run_text(shaped, run_index)
			var run_font: RID = text_server.shaped_get_run_font_rid(shaped, run_index)
			if run_text.contains("వ"):
				saw_telugu_run = _font_owns_rid(telugu_font, run_font)
			if run_text.contains("Act"):
				var ui_font_rids := ui_font.get_rids()
				saw_latin_run = not ui_font_rids.is_empty() and run_font == ui_font_rids[0]
		_check(saw_telugu_run, "shaped Telugu glyphs resolve to the bundled Telugu fallback")
		_check(saw_latin_run, "shaped Latin glyphs resolve to the Nunito primary font")

	game.queue_free()
	await process_frame
	var exit_code := 0
	if failures.is_empty():
		print("PASS: Telugu UI pilot exact string, visibility, shaping, and font fallback")
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL: %d Telugu UI pilot assertion(s)" % failures.size())
		exit_code = 1
	call_deferred("quit", exit_code)

func _font_owns_rid(font: Font, target: RID) -> bool:
	if font.get_rid() == target:
		return true
	for rid in font.get_rids():
		if rid == target:
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
