extends RefCounted
## Compact Act VII finale catalog; English copy is an original adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const STAGE_ID := "act_vii_case_resolution"
const PATH := "res://data/story/act_vii_route.json"
const SOURCE_WITNESS := "1909 second-edition first printing"
const SOURCE_URLS := [
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/71.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/72.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/73.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/74.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/75.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/76.html"
]
const LOCATIONS := [
	"The deputy collector's case desk",
	"The witness and evidence register",
	"Separate household marriage records",
	"Madhuravani's protected disclosure",
	"Sowjanya Rao's consultation room"
]
const MARKERS := [
	"FILE / ALLEGATION",
	"OBSERVATION / HEARSAY / PRESSURE",
	"DISTINCT FAMILY MATTERS",
	"VOLUNTARY IDENTIFICATION",
	"EDUCATION / INDEPENDENCE"
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
	if not STAGE_CATALOG.validate(stage) or str(stage.get("id", "")) != STAGE_ID or str(stage.get("act", "")) != "VII":
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
		var wall_colors := [Color("#806b56"), Color("#6b7475"), Color("#88715b"), Color("#625969"), Color("#667668")]
		var floor_colors := [Color("#71584b"), Color("#68584d"), Color("#80674c"), Color("#594c4b"), Color("#536354")]
		for zone in range(LOCATIONS.size()):
			var x := float(zone * 1000)
			draw_rect(Rect2(x, -180, 1000, 600), wall_colors[zone], true)
			draw_rect(Rect2(x, 420, 1000, 200), floor_colors[zone], true)
			_draw_sign(x + 82.0, LOCATIONS[zone].to_upper())
			_draw_marker(x + 500.0, MARKERS[zone])
			match zone:
				0:
					_draw_docket(x + 500.0, 310.0)
				1:
					_draw_register(x + 500.0, 300.0)
				2:
					_draw_two_ledgers(x + 500.0, 300.0)
				3:
					_draw_screen(x + 500.0, 300.0)
				4:
					_draw_open_book(x + 500.0, 300.0)
		for boundary in range(1, LOCATIONS.size()):
			draw_line(Vector2(boundary * 1000, -180), Vector2(boundary * 1000, 620), Color("#503d35", 0.55), 4.0)

	func _draw_sign(x: float, text: String) -> void:
		draw_rect(Rect2(x, 65, 825, 66), Color("#563d32"), true)
		draw_rect(Rect2(x + 7, 72, 811, 52), Color("#f1dcba"), true)
		draw_string(FONT, Vector2(x + 16, 104), text, HORIZONTAL_ALIGNMENT_LEFT, 790, 16, Color("#49352e"))

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 585), Color("#563d32"), 3.0)
		draw_rect(Rect2(x - 205, 474, 410, 34), Color(0.22, 0.15, 0.12, 0.9), true)
		draw_string(FONT, Vector2(x - 196, 497), text, HORIZONTAL_ALIGNMENT_CENTER, 392, 12, Color("#fff0d0"))

	func _draw_docket(x: float, y: float) -> void:
		draw_rect(Rect2(x - 138, y - 95, 276, 190), Color("#ead7b4"), true)
		draw_rect(Rect2(x - 148, y - 105, 276, 190), Color("#bc9562"), false, 5.0)
		for row in range(5):
			draw_line(Vector2(x - 100, y - 55 + row * 27), Vector2(x + 94 - (row % 2) * 34, y - 55 + row * 27), Color("#80614c"), 3.0)

	func _draw_register(x: float, y: float) -> void:
		draw_rect(Rect2(x - 210, y - 75, 420, 150), Color("#e6d3ae"), true)
		for row in range(4):
			draw_line(Vector2(x - 190, y - 43 + row * 34), Vector2(x + 190, y - 43 + row * 34), Color("#94755c"), 2.0)
		draw_line(Vector2(x - 70, y - 70), Vector2(x - 70, y + 69), Color("#94755c"), 2.0)
		draw_line(Vector2(x + 68, y - 70), Vector2(x + 68, y + 69), Color("#94755c"), 2.0)

	func _draw_two_ledgers(x: float, y: float) -> void:
		for offset in [-130.0, 130.0]:
			draw_rect(Rect2(x + offset - 94, y - 70, 188, 140), Color("#ead7b4"), true)
			for row in range(3):
				draw_line(Vector2(x + offset - 68, y - 38 + row * 32), Vector2(x + offset + 70 - row * 12, y - 38 + row * 32), Color("#80614c"), 2.0)

	func _draw_screen(x: float, y: float) -> void:
		draw_line(Vector2(x - 120, y - 75), Vector2(x - 120, y + 75), Color("#523f37"), 7.0)
		draw_line(Vector2(x + 120, y - 75), Vector2(x + 120, y + 75), Color("#523f37"), 7.0)
		draw_line(Vector2(x - 120, y - 75), Vector2(x + 120, y - 75), Color("#523f37"), 7.0)
		for fold_x in [-72.0, -24.0, 24.0, 72.0]:
			draw_line(Vector2(x + fold_x, y - 62), Vector2(x + fold_x, y + 72), Color("#d9ac75"), 8.0)

	func _draw_open_book(x: float, y: float) -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 80), Vector2(x - 180, y - 52), Vector2(x - 180, y + 78), Vector2(x, y + 50)]), Color("#f0dfbd"))
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 80), Vector2(x + 180, y - 52), Vector2(x + 180, y + 78), Vector2(x, y + 50)]), Color("#ead3aa"))
		draw_line(Vector2(x, y - 78), Vector2(x, y + 50), Color("#8f684d"), 4.0)
		for row in range(3):
			draw_line(Vector2(x - 144, y - 18 + row * 25), Vector2(x - 28, y - 18 + row * 25), Color("#977c5c"), 2.0)
			draw_line(Vector2(x + 28, y - 18 + row * 25), Vector2(x + 144, y - 18 + row * 25), Color("#977c5c"), 2.0)
