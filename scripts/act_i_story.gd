extends RefCounted
## Two-location, source-grounded first-act route; the script's dialogue is adaptation, not quotation.

const STAGE_CATALOG := preload("res://scripts/stage_catalog.gd")
const IDS := ["act_i_bonkula_dibba", "act_i_madhuravani_room"]
const SOURCE_URL := "https://te.wikisource.org/w/index.php?title=కన్యాశులకము/ప్రథమాంకము&oldid=252038"
const SOURCE_REVISION := "252038"
const SOURCE_EDITION_LABEL := "1961"
const PATHS := [
	"res://data/story/act_i_bonkula_dibba.json",
	"res://data/story/act_i_madhuravani_room.json"
]

static func stage_ids() -> Array:
	return IDS.duplicate()

static func load_stage(index: int) -> Dictionary:
	if index < 0 or index >= PATHS.size():
		return {}
	var file := FileAccess.open(PATHS[index], FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not validate_stage(parsed):
		return {}
	return parsed

static func validate_stage(stage: Dictionary) -> bool:
	if not STAGE_CATALOG.validate(stage) or stage.id not in IDS:
		return false
	if not stage.has("story_beats") or not stage.story_beats is Array or stage.story_beats.is_empty():
		return false
	var previous_x := -1.0
	var beat_ids: Array[String] = []
	for beat: Variant in stage.story_beats:
		if not beat is Dictionary:
			return false
		for key in ["id", "x", "marker", "title", "line", "choices", "response"]:
			if not beat.has(key):
				return false
		if not beat.id is String or beat.id.is_empty() or beat.id in beat_ids:
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
		if bool(beat.get("stealth", false)) and beat.choices.size() != 1:
			return false
		beat_ids.append(beat.id)
	return true


class LocationArt:
	extends Node2D

	const FONT := preload("res://assets/template/fonts/ui_bold.tres")
	var location_id := ""
	var world_width := 3200.0
	var search_progress := 0.0
	var ram_hidden := false
	var evidence_review_available := false

	func _process(_delta: float) -> void:
		if location_id == "act_i_madhuravani_room":
			queue_redraw()

	func _draw() -> void:
		if location_id == "act_i_madhuravani_room":
			_draw_room()
		else:
			_draw_dibba()

	func _draw_dibba() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#dfb778"), true)
		draw_rect(Rect2(0, -240, world_width, 360), Color("#8c8094"), true)
		draw_rect(Rect2(0, 120, world_width, 210), Color("#d9a56f"), true)
		draw_rect(Rect2(0, 330, world_width, 290), Color("#c9804e"), true)
		for x in range(120, int(world_width), 430):
			_draw_tree(float(x), 280.0, 0.78)
		_draw_mound(430.0, 615.0, 250.0, 90.0, Color("#ad6946"))
		_draw_mound(1830.0, 615.0, 290.0, 115.0, Color("#a96345"))
		_draw_sign(80.0, 405.0, "BONKULA DIBBA")
		_draw_marker(430.0, "ACCOUNT BOOK")
		_draw_marker(1080.0, "VENKATESAM")
		_draw_marker(1740.0, "TUTOR'S LIST")
		_draw_marker(2550.0, "ROAD OUT")

	func _draw_room() -> void:
		draw_rect(Rect2(0, -240, world_width, 860), Color("#d3a776"), true)
		draw_rect(Rect2(0, -240, world_width, 760), Color("#c98965"), true)
		draw_rect(Rect2(0, 400, world_width, 220), Color("#9f624c"), true)
		for x in range(80, int(world_width), 360):
			draw_line(Vector2(x, -180), Vector2(x, 400), Color("#aa704f"), 8.0)
			draw_line(Vector2(x + 8, -180), Vector2(x + 8, 400), Color("#e0b98d"), 3.0)
		_draw_window(790.0, 110.0)
		_draw_lamp(1160.0, 170.0)
		_draw_bed(1770.0, 610.0)
		_draw_cash_offer(840.0, 540.0)
		if ram_hidden:
			draw_rect(Rect2(1727.0, 596.0, 86.0, 8.0), Color("#342923"), true)
			draw_circle(Vector2(1740.0, 600.0), 5.0, Color("#b49a78"))
			draw_circle(Vector2(1800.0, 600.0), 5.0, Color("#b49a78"))
		_draw_marker(470.0, "DEBTS / BOUNDARIES")
		_draw_marker(840.0, "200-RUPEE OFFER")
		if evidence_review_available:
			_draw_marker(1080.0, "OPTIONAL TERMS REVIEW")
		_draw_marker(1390.0, "RAMAPPAANTULU HIDES")
		_draw_marker(1770.0, "UNDER THE BED")
		_draw_marker(2590.0, "HER TERMS")
		if search_progress > 0.0:
			var sweep_x := lerpf(1500.0, 2210.0, fposmod(search_progress * 2.2, 1.0))
			draw_line(Vector2(sweep_x, 530), Vector2(sweep_x + 105, 588), Color("#6b4937"), 10.0)
			draw_line(Vector2(sweep_x + 105, 588), Vector2(sweep_x + 210, 606), Color("#8f342d"), 5.0)
			draw_circle(Vector2(sweep_x + 210, 606), 4.0, Color("#f0d298"))

	func _draw_tree(x: float, base_y: float, scale: float) -> void:
		var trunk_w := 28.0 * scale
		draw_rect(Rect2(x - trunk_w * 0.5, base_y - 180.0 * scale, trunk_w, 185.0 * scale), Color("#65443b"), true)
		for offset: Vector2 in [Vector2(-46, -174), Vector2(0, -220), Vector2(52, -165)]:
			draw_circle(Vector2(x + offset.x * scale, base_y + offset.y * scale), 52.0 * scale, Color("#52634b"))
			draw_circle(Vector2(x + offset.x * scale - 12.0, base_y + offset.y * scale - 12.0), 27.0 * scale, Color("#71805a"))

	func _draw_mound(x: float, y: float, width: float, height: float, color: Color) -> void:
		var points := PackedVector2Array([Vector2(x - width * 0.5, y), Vector2(x - width * 0.38, y - height * 0.42), Vector2(x - width * 0.1, y - height), Vector2(x + width * 0.16, y - height * 0.84), Vector2(x + width * 0.5, y)])
		draw_colored_polygon(points, color)
		draw_polyline(points, Color("#854c3d"), 4.0, true)

	func _draw_sign(x: float, y: float, text: String) -> void:
		draw_rect(Rect2(x, y, 310, 74), Color("#664735"), true)
		draw_rect(Rect2(x + 7, y + 7, 296, 60), Color("#efd2a1"), true)
		draw_string(FONT, Vector2(x + 17, y + 45), text, HORIZONTAL_ALIGNMENT_LEFT, 270, 21, Color("#5b392c"))

	func _draw_marker(x: float, text: String) -> void:
		draw_circle(Vector2(x, 548), 9.0, Color("#f6d38c"))
		draw_line(Vector2(x, 555), Vector2(x, 587), Color("#674233"), 3.0)
		draw_rect(Rect2(x - 78, 474, 156, 32), Color(0.25, 0.14, 0.1, 0.88), true)
		draw_string(FONT, Vector2(x - 70, 496), text, HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color("#fff0d0"))

	func _draw_window(x: float, y: float) -> void:
		draw_rect(Rect2(x - 98, y - 18, 196, 160), Color("#694737"), true)
		draw_rect(Rect2(x - 86, y - 6, 172, 136), Color("#607374"), true)
		draw_rect(Rect2(x - 6, y - 6, 12, 136), Color("#cf9b72"), true)
		draw_rect(Rect2(x - 86, y + 58, 172, 10), Color("#cf9b72"), true)
		draw_rect(Rect2(x - 102, y - 26, 204, 12), Color("#edcf9e"), true)

	func _draw_lamp(x: float, y: float) -> void:
		draw_line(Vector2(x, y - 70), Vector2(x, y - 8), Color("#614638"), 5.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 34, y - 8), Vector2(x + 34, y - 8), Vector2(x + 20, y + 15), Vector2(x - 20, y + 15)]), Color("#cb8745"))
		draw_circle(Vector2(x, y + 20), 18.0, Color(1.0, 0.72, 0.36, 0.18))
		draw_circle(Vector2(x, y + 11), 8.0, Color("#ffe1a0"))

	func _draw_bed(x: float, floor_y: float) -> void:
		draw_rect(Rect2(x - 165, floor_y - 112, 330, 28), Color("#603f33"), true)
		draw_rect(Rect2(x - 147, floor_y - 82, 294, 76), Color("#8c5a3f"), true)
		draw_rect(Rect2(x - 144, floor_y - 128, 104, 32), Color("#f1dfbd"), true)
		draw_rect(Rect2(x - 30, floor_y - 128, 173, 32), Color("#b96253"), true)
		for leg_x in [x - 148, x + 128]:
			draw_rect(Rect2(leg_x, floor_y - 88, 20, 88), Color("#593c32"), true)
		draw_rect(Rect2(x - 105, floor_y - 12, 210, 9), Color("#4b352d"), true)

	func _draw_cash_offer(x: float, y: float) -> void:
		draw_rect(Rect2(x - 42.0, y - 24.0, 78.0, 42.0), Color("#73906b"), true)
		draw_rect(Rect2(x - 33.0, y - 31.0, 78.0, 42.0), Color("#e6cf9c"), true)
		draw_rect(Rect2(x - 27.0, y - 25.0, 66.0, 30.0), Color("#f3dfae"), false, 2.0)
		draw_string(FONT, Vector2(x - 13.0, y - 5.0), "200", HORIZONTAL_ALIGNMENT_CENTER, 34.0, 13, Color("#704d35"))
