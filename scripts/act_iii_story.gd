extends RefCounted
## Compact Act III route catalog; all English scene copy is adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const STAGE_ID := "act_iii_route"
const PATH := "res://data/story/act_iii_route.json"
const SOURCE_WITNESS := "1909 second-edition first printing"
const SOURCE_URLS := [
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/31.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/32.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/33.html",
	"https://andhrabharati.com/nATakamulu/kanyASulkamu/34.html"
]
const LOCATIONS := [
	"Ramappantulu's front room",
	"Ramappantulu's bedroom",
	"Outside Agnihotravadhani's house",
	"The garden"
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
	if not STAGE_CATALOG.validate(stage) or str(stage.get("id", "")) != STAGE_ID or str(stage.get("act", "")) != "III":
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
	return locations == LOCATIONS and multi_choice_count == 1


class LocationArt:
	extends Node2D

	const FONT := preload("res://assets/template/fonts/ui_bold.tres")
	var location_id := ""
	var world_width := 4000.0

	func _draw() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#d8c59e"), true)
		var wall_colors := [Color("#c98965"), Color("#bd8064"), Color("#d8b98b"), Color("#78906a")]
		for zone in range(4):
			var x := float(zone * 1000)
			draw_rect(Rect2(x, -180, 1000, 600), wall_colors[zone], true)
			draw_rect(Rect2(x, 420, 1000, 200), Color("#a76c50") if zone < 2 else Color("#9b795b"), true)
			if zone < 2:
				for pillar_x in range(int(x + 90), int(x + 1000), 300):
					draw_line(Vector2(float(pillar_x), -160), Vector2(float(pillar_x), 418), Color("#aa7658"), 5.0)
					draw_line(Vector2(float(pillar_x + 8), -160), Vector2(float(pillar_x + 8), 418), Color("#e0b98d"), 2.0)
			_draw_location_sign(x + 84.0, LOCATIONS[zone].to_upper())
			match zone:
				0:
					_draw_window(700.0, 210.0)
					_draw_table(510.0, 520.0)
				1:
					_draw_bed(1500.0, 610.0)
				2:
					_draw_house_front(2200.0)
				3:
					_draw_tree(3440.0, 425.0)
					_draw_bench(3670.0, 570.0)
		draw_line(Vector2(1000, -180), Vector2(1000, 620), Color("#684638", 0.55), 4.0)
		draw_line(Vector2(2000, -180), Vector2(2000, 620), Color("#684638", 0.55), 4.0)
		draw_line(Vector2(3000, -180), Vector2(3000, 620), Color("#684638", 0.55), 4.0)
		_draw_marker(500.0, "CLAIMS / BOUNDARIES")
		_draw_marker(1500.0, "THE DISGUISE")
		_draw_marker(2500.0, "COURTSHIP / MOTIVE")
		_draw_marker(3500.0, "LESSON / CONSEQUENCE")

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
		draw_rect(Rect2(x - 120, y - 16, 240, 22), Color("#684535"), true)
		draw_rect(Rect2(x - 94, y + 6, 18, 72), Color("#684535"), true)
		draw_rect(Rect2(x + 76, y + 6, 18, 72), Color("#684535"), true)

	func _draw_bed(x: float, floor_y: float) -> void:
		draw_rect(Rect2(x - 170, floor_y - 112, 340, 28), Color("#603f33"), true)
		draw_rect(Rect2(x - 150, floor_y - 82, 300, 72), Color("#8c5a3f"), true)
		draw_rect(Rect2(x - 145, floor_y - 128, 110, 32), Color("#f1dfbd"), true)
		for leg_x in [x - 150, x + 130]:
			draw_rect(Rect2(leg_x, floor_y - 88, 20, 88), Color("#593c32"), true)

	func _draw_house_front(x: float) -> void:
		draw_rect(Rect2(x - 280, 118, 560, 390), Color("#b9825d"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 330, 125), Vector2(x, -45), Vector2(x + 330, 125)]), Color("#76513f"))
		draw_rect(Rect2(x - 68, 300, 136, 208), Color("#684638"), true)
		draw_rect(Rect2(x - 53, 315, 106, 193), Color("#44352f"), true)
		for pillar_x in [x - 220, x + 220]:
			draw_rect(Rect2(pillar_x, 150, 30, 358), Color("#e0bc8d"), true)

	func _draw_tree(x: float, base_y: float) -> void:
		draw_rect(Rect2(x - 18, base_y - 220, 36, 220), Color("#65443b"), true)
		for offset: Vector2 in [Vector2(-60, -200), Vector2(0, -245), Vector2(62, -190)]:
			draw_circle(Vector2(x + offset.x, base_y + offset.y), 62.0, Color("#52634b"))
			draw_circle(Vector2(x + offset.x - 13, base_y + offset.y - 12), 31.0, Color("#71805a"))

	func _draw_bench(x: float, y: float) -> void:
		draw_rect(Rect2(x - 115, y - 44, 230, 22), Color("#684535"), true)
		for leg_x in [x - 90, x + 72]:
			draw_rect(Rect2(leg_x, y - 22, 18, 65), Color("#684535"), true)

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 587), Color("#674233"), 3.0)
		draw_rect(Rect2(x - 125, 474, 250, 32), Color(0.25, 0.14, 0.1, 0.88), true)
		draw_string(FONT, Vector2(x - 117, 496), text, HORIZONTAL_ALIGNMENT_CENTER, 234, 12, Color("#fff0d0"))
