extends RefCounted
## Compact Act VI route catalog; all English scene copy is adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const STAGE_ID := "act_vi_wedding_reversal"
const PATH := "res://data/story/act_vi_route.json"
const SOURCE_WITNESS := "1909 second-edition first printing"
const SOURCE_URLS := [
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/61.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/62.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/63.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/64.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/65.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/66.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/67.html",
]
const LOCATIONS := [
	"Ramachandrapuram agraharam",
	"Street outside Madhuravani's lodging",
	"Saujanya Rao Pantulu's office",
]
const MARKERS := ["ARRIVAL / CLAIM", "LODGING / PRESSURE", "COUNSEL / STATUS"]

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
	if not STAGE_CATALOG.validate(stage) or str(stage.get("id", "")) != STAGE_ID or str(stage.get("act", "")) != "VI":
		return false
	var beats: Variant = stage.get("story_beats", null)
	if not beats is Array or beats.size() != LOCATIONS.size():
		return false
	var previous_x := -1.0
	var ids: Array[String] = []
	var locations: Array[String] = []
	var multi_choice_count := 0
	for beat: Variant in beats:
		if not beat is Dictionary:
			return false
		for key in ["id", "x", "location", "marker", "title", "line", "choices", "response"]:
			if not beat.has(key):
				return false
		if not beat.id is String or beat.id.is_empty() or beat.id in ids:
			return false
		if not beat.x is int and not beat.x is float:
			return false
		if float(beat.x) < previous_x or float(beat.x) < float(stage.spawn[0]) or float(beat.x) >= float(stage.goal[0]):
			return false
		if not beat.location is String or beat.location.is_empty() or not beat.marker is String or beat.marker.is_empty():
			return false
		if not beat.title is String or beat.title.is_empty() or not beat.line is String or beat.line.is_empty():
			return false
		if not beat.response is String or beat.response.is_empty() or not beat.choices is Array or beat.choices.is_empty():
			return false
		for choice: Variant in beat.choices:
			if not choice is String or choice.is_empty():
				return false
		var choice_responses: Variant = beat.get("choice_responses", [])
		if not choice_responses is Array or (not choice_responses.is_empty() and choice_responses.size() != beat.choices.size()):
			return false
		if beat.choices.size() > 1:
			multi_choice_count += 1
		previous_x = float(beat.x)
		ids.append(beat.id)
		locations.append(beat.location)
	return locations == LOCATIONS and multi_choice_count == 1 and beats[0].choices.size() == 3


class LocationArt:
	extends Node2D

	const FONT := preload("res://assets/template/fonts/ui_bold.tres")
	var location_id := ""
	var world_width := 3000.0

	func _draw() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#d8c59e"), true)
		var wall_colors := [Color("#c98965"), Color("#bd8064"), Color("#78906a")]
		for zone in range(LOCATIONS.size()):
			var x := float(zone * 1000)
			draw_rect(Rect2(x, -180, 1000, 600), wall_colors[zone], true)
			draw_rect(Rect2(x, 420, 1000, 200), Color("#a76c50") if zone < 2 else Color("#9b795b"), true)
			_draw_location_sign(x + 84.0, LOCATIONS[zone].to_upper())
			_draw_marker(x + 500.0, MARKERS[zone])
			if zone == 0:
				_draw_window(x + 760.0, 190.0)
				_draw_table(x + 500.0, 520.0)
			elif zone == 1:
				_draw_canopy(x + 500.0)
				_draw_seat(x + 500.0, 590.0)
			else:
				_draw_window(x + 760.0, 190.0)
				_draw_lesson_board(x + 500.0, 330.0)
		draw_line(Vector2(1000, -180), Vector2(1000, 620), Color("#684638", 0.55), 4.0)
		draw_line(Vector2(2000, -180), Vector2(2000, 620), Color("#684638", 0.55), 4.0)

	func _draw_location_sign(x: float, text: String) -> void:
		draw_rect(Rect2(x, 70, 820, 62), Color("#664735"), true)
		draw_rect(Rect2(x + 7, 77, 806, 48), Color("#efd2a1"), true)
		draw_string(FONT, Vector2(x + 18, 108), text, HORIZONTAL_ALIGNMENT_LEFT, 780, 17, Color("#5b392c"))

	func _draw_window(x: float, y: float) -> void:
		draw_rect(Rect2(x - 95, y - 90, 190, 190), Color("#674638"), true)
		draw_rect(Rect2(x - 82, y - 77, 164, 164), Color("#70817b"), true)
		draw_rect(Rect2(x - 6, y - 77, 12, 164), Color("#e2bd8e"), true)
		draw_rect(Rect2(x - 82, y - 6, 164, 12), Color("#e2bd8e"), true)

	func _draw_table(x: float, y: float) -> void:
		draw_rect(Rect2(x - 130, y - 12, 260, 22), Color("#684535"), true)
		draw_rect(Rect2(x - 108, y + 10, 18, 78), Color("#684535"), true)
		draw_rect(Rect2(x + 90, y + 10, 18, 78), Color("#684535"), true)

	func _draw_canopy(center_x: float) -> void:
		draw_line(Vector2(center_x - 310, 395), Vector2(center_x - 230, 150), Color("#69483b"), 10.0)
		draw_line(Vector2(center_x + 310, 395), Vector2(center_x + 230, 150), Color("#69483b"), 10.0)
		draw_line(Vector2(center_x - 230, 150), Vector2(center_x + 230, 150), Color("#69483b"), 10.0)
		draw_colored_polygon(PackedVector2Array([Vector2(center_x - 230, 150), Vector2(center_x, 75), Vector2(center_x + 230, 150)]), Color("#dfb878"))

	func _draw_seat(center_x: float, floor_y: float) -> void:
		draw_rect(Rect2(center_x - 100, floor_y - 56, 200, 18), Color("#684535"), true)
		for leg_x in [center_x - 78, center_x + 60]:
			draw_rect(Rect2(leg_x, floor_y - 38, 18, 72), Color("#684535"), true)

	func _draw_lesson_board(center_x: float, y: float) -> void:
		draw_rect(Rect2(center_x - 145, y - 80, 290, 160), Color("#684735"), true)
		draw_rect(Rect2(center_x - 132, y - 67, 264, 134), Color("#728064"), true)
		draw_line(Vector2(center_x - 92, y - 23), Vector2(center_x + 82, y - 23), Color("#f0dfb9"), 3.0)
		draw_line(Vector2(center_x - 92, y + 15), Vector2(center_x + 48, y + 15), Color("#f0dfb9"), 3.0)

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 587), Color("#674233"), 3.0)
		draw_rect(Rect2(x - 140, 474, 280, 32), Color(0.25, 0.14, 0.1, 0.88), true)
		draw_string(FONT, Vector2(x - 132, 496), text, HORIZONTAL_ALIGNMENT_CENTER, 264, 12, Color("#fff0d0"))
