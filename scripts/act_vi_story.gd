extends RefCounted
## Compact Act VI route catalog; English copy is an adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const STAGE_ID := "act_vi_evidence_chain"
const PATH := "res://data/story/act_vi_route.json"
const SOURCE_WITNESS := "1909 second-edition first printing"
const SOURCE_URLS := [
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/61.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/62.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/63.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/64.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/65.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/66.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/67.html"
]
const LOCATIONS := [
	"Ramachandrapuram wedding-party road",
	"The litigation and pawn ledger",
	"Lubdhavadhani's lodging",
	"Madhuravani's room",
	"Sowjanya Rao's consultation room"
]
const MARKERS := [
	"OBSERVATION / HEARSAY",
	"DEBT / BRIBE / FALSE TESTIMONY",
	"REMORSE / SEPARATE FAMILY MATTER",
	"PRIVACY / HONEST ACCOUNT",
	"REFORM / EDUCATION / PROPERTY"
]

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
	return locations == LOCATIONS and multi_choice_count == LOCATIONS.size()


class LocationArt:
	extends Node2D

	const FONT := preload("res://assets/template/fonts/ui_bold.tres")
	var location_id := ""
	var world_width := 5000.0

	func _draw() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#d8c59e"), true)
		var wall_colors := [Color("#8b7964"), Color("#8b6555"), Color("#8a735b"), Color("#627879"), Color("#76816a")]
		var floor_colors := [Color("#6f594f"), Color("#805d4d"), Color("#887153"), Color("#594e48"), Color("#74654d")]
		for zone in range(LOCATIONS.size()):
			var x := float(zone * 1000)
			draw_rect(Rect2(x, -180, 1000, 600), wall_colors[zone], true)
			draw_rect(Rect2(x, 420, 1000, 200), floor_colors[zone], true)
			_draw_location_sign(x + 84.0, LOCATIONS[zone].to_upper())
			_draw_marker(x + 500.0, MARKERS[zone])
			match zone:
				0:
					_draw_canopy(x + 500.0)
					_draw_notice_board(x + 790.0, 300.0)
				1:
					_draw_table(x + 500.0, 520.0)
					_draw_record(x + 570.0, 475.0)
				2:
					_draw_house_window(x + 750.0, 220.0)
					_draw_record(x + 500.0, 500.0)
				3:
					_draw_screen(x + 720.0)
					_draw_seat(x + 500.0, 570.0)
				4:
					_draw_lesson_board(x + 500.0, 330.0)
					_draw_record(x + 785.0, 500.0)
		for boundary in range(1, LOCATIONS.size()):
			draw_line(Vector2(boundary * 1000, -180), Vector2(boundary * 1000, 620), Color("#684638", 0.55), 4.0)

	func _draw_location_sign(x: float, text: String) -> void:
		draw_rect(Rect2(x, 70, 820, 62), Color("#664735"), true)
		draw_rect(Rect2(x + 7, 77, 806, 48), Color("#efd2a1"), true)
		draw_string(FONT, Vector2(x + 18, 108), text, HORIZONTAL_ALIGNMENT_LEFT, 780, 17, Color("#5b392c"))

	func _draw_canopy(center_x: float) -> void:
		draw_line(Vector2(center_x - 260, 395), Vector2(center_x - 190, 170), Color("#684638"), 9.0)
		draw_line(Vector2(center_x + 260, 395), Vector2(center_x + 190, 170), Color("#684638"), 9.0)
		draw_line(Vector2(center_x - 190, 170), Vector2(center_x + 190, 170), Color("#684638"), 9.0)
		draw_colored_polygon(PackedVector2Array([Vector2(center_x - 190, 170), Vector2(center_x, 95), Vector2(center_x + 190, 170)]), Color("#d8b77f"))

	func _draw_notice_board(x: float, y: float) -> void:
		draw_rect(Rect2(x - 62, y - 85, 124, 140), Color("#684735"), true)
		draw_rect(Rect2(x - 52, y - 75, 104, 120), Color("#efdbb5"), true)
		for row in range(4):
			draw_line(Vector2(x - 38, y - 48 + row * 22), Vector2(x + 36 - (row % 2) * 12, y - 48 + row * 22), Color("#815d4b"), 3.0)

	func _draw_table(x: float, y: float) -> void:
		draw_rect(Rect2(x - 150, y - 18, 300, 24), Color("#51392f"), true)
		for leg_x in [x - 128, x + 110]:
			draw_rect(Rect2(leg_x, y + 6, 18, 72), Color("#51392f"), true)

	func _draw_record(x: float, y: float) -> void:
		draw_rect(Rect2(x - 42, y - 48, 84, 62), Color("#f0dfbd"), true)
		for row in range(3):
			draw_line(Vector2(x - 30, y - 32 + row * 14), Vector2(x + 28 - (row % 2) * 9, y - 32 + row * 14), Color("#8e5e46"), 2.0)
		draw_circle(Vector2(x + 48, y - 4), 18.0, Color("#d7aa53"))
		draw_circle(Vector2(x + 48, y - 4), 12.0, Color("#efd58f"))

	func _draw_house_window(self_x: float, y: float) -> void:
		draw_rect(Rect2(self_x - 92, y - 88, 184, 184), Color("#493f50"), true)
		draw_rect(Rect2(self_x - 78, y - 74, 156, 156), Color("#bd9a73"), true)
		draw_line(Vector2(self_x, y - 74), Vector2(self_x, y + 82), Color("#e2bd8e"), 8.0)
		draw_line(Vector2(self_x - 78, y + 4), Vector2(self_x + 78, y + 4), Color("#e2bd8e"), 8.0)

	func _draw_screen(x: float) -> void:
		draw_line(Vector2(x, 175), Vector2(x, 405), Color("#684638"), 7.0)
		for fold_x in [x + 22.0, x + 48.0, x + 74.0]:
			draw_line(Vector2(fold_x, 190), Vector2(fold_x, 405), Color("#d9ac75"), 8.0)
		draw_line(Vector2(x - 20, 176), Vector2(x + 110, 176), Color("#684638"), 8.0)

	func _draw_seat(x: float, floor_y: float) -> void:
		draw_rect(Rect2(x - 110, floor_y - 52, 220, 20), Color("#51392f"), true)
		for leg_x in [x - 88, x + 70]:
			draw_rect(Rect2(leg_x, floor_y - 32, 18, 72), Color("#51392f"), true)

	func _draw_lesson_board(x: float, y: float) -> void:
		draw_rect(Rect2(x - 145, y - 80, 290, 160), Color("#684735"), true)
		draw_rect(Rect2(x - 132, y - 67, 264, 134), Color("#728064"), true)
		for row in range(3):
			draw_line(Vector2(x - 94, y - 34 + row * 34), Vector2(x + 86 - row * 20, y - 34 + row * 34), Color("#f0dfb9"), 3.0)

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 587), Color("#674233"), 3.0)
		draw_rect(Rect2(x - 185, 474, 370, 32), Color(0.25, 0.14, 0.1, 0.88), true)
		draw_string(FONT, Vector2(x - 177, 496), text, HORIZONTAL_ALIGNMENT_CENTER, 354, 12, Color("#fff0d0"))
