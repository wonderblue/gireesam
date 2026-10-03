extends RefCounted
## Compact Act V route catalog; all English scene copy is adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const STAGE_ID := "act_v_disguise_search"
const PATH := "res://data/story/act_v_route.json"
const SOURCE_WITNESS := "1909 second-edition first printing"
const SOURCE_URLS := [
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/51.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/52.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/53.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/54.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/55.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/56.html"
]
const LOCATIONS := [
	"Lubdhavadhani's bedroom",
	"Madhuravani's card room",
	"The search from the courtyard to the temple street"
]
const MARKERS := ["FEAR / RUMOR", "DISGUISE / DOOR", "SEARCH / BRIBES"]

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
	if not STAGE_CATALOG.validate(stage) or str(stage.get("id", "")) != STAGE_ID or str(stage.get("act", "")) != "V":
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
	return locations == LOCATIONS and multi_choice_count == 1 and beats[2].choices.size() == 3


class LocationArt:
	extends Node2D

	const FONT := preload("res://assets/template/fonts/ui_bold.tres")
	var location_id := ""
	var world_width := 3000.0

	func _draw() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#d8c59e"), true)
		var wall_colors := [Color("#62677a"), Color("#9a6756"), Color("#687461")]
		var floor_colors := [Color("#6f594f"), Color("#805d4d"), Color("#887153")]
		for zone in range(LOCATIONS.size()):
			var x := float(zone * 1000)
			draw_rect(Rect2(x, -180, 1000, 600), wall_colors[zone], true)
			draw_rect(Rect2(x, 420, 1000, 200), floor_colors[zone], true)
			_draw_location_sign(x + 84.0, LOCATIONS[zone].to_upper())
			_draw_marker(x + 500.0, MARKERS[zone])
			match zone:
				0:
					_draw_window(x + 760.0, 190.0)
					_draw_bed(x + 500.0, 610.0)
				1:
					_draw_screen(x + 725.0)
					_draw_card_table(x + 500.0, 520.0)
				2:
					_draw_temple_arch(x + 500.0)
					_draw_notice_board(x + 815.0, 310.0)
		draw_line(Vector2(1000, -180), Vector2(1000, 620), Color("#684638", 0.55), 4.0)
		draw_line(Vector2(2000, -180), Vector2(2000, 620), Color("#684638", 0.55), 4.0)

	func _draw_location_sign(x: float, text: String) -> void:
		draw_rect(Rect2(x, 70, 820, 62), Color("#664735"), true)
		draw_rect(Rect2(x + 7, 77, 806, 48), Color("#efd2a1"), true)
		draw_string(FONT, Vector2(x + 18, 108), text, HORIZONTAL_ALIGNMENT_LEFT, 780, 17, Color("#5b392c"))

	func _draw_window(x: float, y: float) -> void:
		draw_rect(Rect2(x - 95, y - 90, 190, 190), Color("#493f50"), true)
		draw_rect(Rect2(x - 82, y - 77, 164, 164), Color("#b58b69"), true)
		draw_rect(Rect2(x - 6, y - 77, 12, 164), Color("#e2bd8e"), true)
		draw_rect(Rect2(x - 82, y - 6, 164, 12), Color("#e2bd8e"), true)
		draw_circle(Vector2(x + 42, y - 36), 18.0, Color("#f3d49b"))

	func _draw_bed(x: float, floor_y: float) -> void:
		draw_rect(Rect2(x - 170, floor_y - 112, 340, 28), Color("#50392f"), true)
		draw_rect(Rect2(x - 150, floor_y - 82, 300, 72), Color("#916546"), true)
		draw_rect(Rect2(x - 145, floor_y - 128, 110, 32), Color("#f1dfbd"), true)
		for leg_x in [x - 150, x + 130]:
			draw_rect(Rect2(leg_x, floor_y - 88, 20, 88), Color("#593c32"), true)

	func _draw_screen(x: float) -> void:
		draw_line(Vector2(x, 175), Vector2(x, 405), Color("#684638"), 7.0)
		for fold_x in [x + 22.0, x + 48.0, x + 74.0]:
			draw_line(Vector2(fold_x, 190), Vector2(fold_x, 405), Color("#d9ac75"), 8.0)
		draw_line(Vector2(x - 20, 176), Vector2(x + 110, 176), Color("#684638"), 8.0)

	func _draw_card_table(x: float, y: float) -> void:
		draw_rect(Rect2(x - 150, y - 18, 300, 24), Color("#51392f"), true)
		draw_rect(Rect2(x - 122, y + 6, 18, 78), Color("#51392f"), true)
		draw_rect(Rect2(x + 104, y + 6, 18, 78), Color("#51392f"), true)
		for card_x in [x - 68.0, x - 18.0, x + 32.0]:
			draw_rect(Rect2(card_x, y - 30, 34, 44), Color("#f0dfbd"), true)
			draw_line(Vector2(card_x + 8, y - 15), Vector2(card_x + 26, y - 15), Color("#8e5e46"), 2.0)

	func _draw_temple_arch(center_x: float) -> void:
		draw_rect(Rect2(center_x - 240, 215, 54, 230), Color("#684638"), true)
		draw_rect(Rect2(center_x + 186, 215, 54, 230), Color("#684638"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(center_x - 260, 225), Vector2(center_x, 70), Vector2(center_x + 260, 225)]), Color("#c79a66"))
		draw_colored_polygon(PackedVector2Array([Vector2(center_x - 195, 225), Vector2(center_x, 112), Vector2(center_x + 195, 225)]), Color("#687461"))

	func _draw_notice_board(x: float, y: float) -> void:
		draw_rect(Rect2(x - 75, y - 95, 150, 175), Color("#684735"), true)
		draw_rect(Rect2(x - 65, y - 85, 130, 155), Color("#efdbb5"), true)
		for row in range(5):
			draw_line(Vector2(x - 48, y - 54 + row * 24), Vector2(x + 44 - (row % 2) * 14, y - 54 + row * 24), Color("#815d4b"), 3.0)

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 587), Color("#674233"), 3.0)
		draw_rect(Rect2(x - 140, 474, 280, 32), Color(0.25, 0.14, 0.1, 0.88), true)
		draw_string(FONT, Vector2(x - 132, 496), text, HORIZONTAL_ALIGNMENT_CENTER, 264, 12, Color("#fff0d0"))
