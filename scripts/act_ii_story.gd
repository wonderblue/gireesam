extends RefCounted
## Compact Act II route catalog; all English scene copy is adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const STAGE_ID := "act_ii_household"
const PATH := "res://data/story/act_ii_household.json"

static func stage_ids() -> Array:
	return [STAGE_ID]

static func load_stage(index: int) -> Dictionary:
	if index != 0:
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not validate_stage(parsed):
		return {}
	return parsed

static func validate_stage(stage: Dictionary) -> bool:
	if not STAGE_CATALOG.validate(stage) or str(stage.get("id", "")) != STAGE_ID:
		return false
	var beats: Variant = stage.get("story_beats", null)
	if not beats is Array or beats.is_empty():
		return false
	var previous_x := -1.0
	var ids: Array[String] = []
	for beat: Variant in beats:
		if not beat is Dictionary:
			return false
		for key in ["id", "x", "marker", "title", "line", "choices", "response"]:
			if not beat.has(key):
				return false
		if not beat.id is String or beat.id.is_empty() or beat.id in ids:
			return false
		if not beat.x is int and not beat.x is float:
			return false
		if float(beat.x) < previous_x or float(beat.x) < float(stage.spawn[0]) or float(beat.x) >= float(stage.goal[0]):
			return false
		if not beat.marker is String or beat.marker.is_empty() or not beat.title is String or beat.title.is_empty():
			return false
		if not beat.line is String or beat.line.is_empty() or not beat.response is String or beat.response.is_empty():
			return false
		if not beat.choices is Array or beat.choices.is_empty():
			return false
		for choice: Variant in beat.choices:
			if not choice is String or choice.is_empty():
				return false
		var choice_responses: Variant = beat.get("choice_responses", [])
		if not choice_responses is Array or (not choice_responses.is_empty() and choice_responses.size() != beat.choices.size()):
			return false
		ids.append(beat.id)
	return true


class LocationArt:
	extends Node2D

	const FONT := preload("res://assets/template/fonts/ui_bold.tres")
	var location_id := ""
	var world_width := 2560.0
	var ram_hidden := false
	var evidence_review_available := false

	func _draw() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#d6bd98"), true)
		draw_rect(Rect2(0, -180, 1530, 780), Color("#c98f68"), true)
		draw_rect(Rect2(0, 420, 1530, 200), Color("#a76c50"), true)
		draw_rect(Rect2(0, 52, 1530, 22), Color("#674638"), true)
		for x in range(170, 1450, 310):
			draw_line(Vector2(x, 75), Vector2(x, 420), Color("#aa7658"), 5.0)
		_draw_window(760.0, 190.0)
		_draw_table(1110.0, 520.0)
		_draw_house_label()
		_draw_temple()
		_draw_marker(470.0, "SCHOOL FEES")
		_draw_marker(1050.0, "SUBBI'S FUTURE")
		_draw_marker(1830.0, "TEMPLE PLAN")

	func _draw_window(x: float, y: float) -> void:
		draw_rect(Rect2(x - 105, y - 85, 210, 210), Color("#674638"), true)
		draw_rect(Rect2(x - 92, y - 72, 184, 184), Color("#70817b"), true)
		draw_rect(Rect2(x - 7, y - 72, 14, 184), Color("#e2bd8e"), true)
		draw_rect(Rect2(x - 92, y + 12, 184, 14), Color("#e2bd8e"), true)

	func _draw_table(x: float, y: float) -> void:
		draw_rect(Rect2(x - 160, y - 12, 320, 24), Color("#684535"), true)
		draw_rect(Rect2(x - 132, y + 12, 18, 90), Color("#684535"), true)
		draw_rect(Rect2(x + 114, y + 12, 18, 90), Color("#684535"), true)
		draw_rect(Rect2(x - 82, y - 36, 52, 24), Color("#e5d0a6"), true)
		draw_rect(Rect2(x + 6, y - 42, 64, 30), Color("#84906b"), true)

	func _draw_house_label() -> void:
		draw_rect(Rect2(65, 112, 490, 57), Color("#664735"), true)
		draw_rect(Rect2(72, 119, 476, 43), Color("#efd2a1"), true)
		draw_string(FONT, Vector2(86, 147), "VENKAMMA / BUCHCHAMMA · HOUSEHOLD", HORIZONTAL_ALIGNMENT_LEFT, 455, 16, Color("#5b392c"))

	func _draw_temple() -> void:
		draw_rect(Rect2(1635, 290, 710, 330), Color("#b98c67"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(1585, 295), Vector2(1985, 88), Vector2(2395, 295)]), Color("#76513f"))
		draw_colored_polygon(PackedVector2Array([Vector2(1645, 278), Vector2(1985, 110), Vector2(2335, 278)]), Color("#d7b27e"))
		for x in [1710.0, 1870.0, 2030.0, 2190.0, 2300.0]:
			draw_rect(Rect2(x, 300, 42, 300), Color("#e0bc8d"), true)
			draw_rect(Rect2(x - 12, 294, 66, 13), Color("#76513f"), true)
		draw_rect(Rect2(1945, 420, 88, 200), Color("#684638"), true)
		draw_rect(Rect2(1957, 432, 64, 188), Color("#48352e"), true)

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 587), Color("#674233"), 3.0)
		draw_rect(Rect2(x - 89, 474, 178, 32), Color(0.25, 0.14, 0.1, 0.88), true)
		draw_string(FONT, Vector2(x - 82, 496), text, HORIZONTAL_ALIGNMENT_CENTER, 164, 12, Color("#fff0d0"))
