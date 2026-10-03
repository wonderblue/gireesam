extends Node2D

const YARN_BALL = preload("res://scripts/yarn_ball.gd")
const MAX_YARN_BALLS := 10

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENTITIES = preload("res://scripts/entities.gd")
const WORLD_ART = preload("res://scripts/world_art.gd")
const PAUSE_MENU = preload("res://scripts/pause_menu.gd")
const TOUCH_INPUT = preload("res://scripts/touch_input.gd")
const VISUAL_EFFECTS = preload("res://scripts/visual_effects.gd")
const BRICK_SURFACE = preload("res://scripts/brick_surface.gd")
const CAT_TREE_TEXTURE = preload("res://assets/template/cat/cat-tree.webp")
const QUESTION_BLOCK_CLEARANCE := 80.0
const STAGE_CATALOG = preload("res://scripts/stage_catalog.gd")
const RUN_SCORE = preload("res://scripts/run_score.gd")
const TUTORIAL = preload("res://scripts/tutorial_director.gd")
const MENU_STYLE = preload("res://scripts/menu_style.gd")
const MENU_MODAL = preload("res://scripts/menu_modal.gd")
const ACT_I_STORY = preload("res://scripts/act_i_story.gd")
const ACT_II_STORY = preload("res://scripts/act_ii_story.gd")
const ACT_III_STORY = preload("res://scripts/act_iii_story.gd")
const ACT_IV_STORY = preload("res://scripts/act_iv_story.gd")
const ACT_V_STORY = preload("res://scripts/act_v_story.gd")
const ACT_I_DIRECTOR = preload("res://scripts/act_i_director.gd")
const GIREE_TEXTURE = preload("res://assets/gireesam/gireesam_player.png")
const STAGE_TIME_LIMITS := [110.0, 95.0, 80.0]

const WORLD_WIDTH := 7800.0
const GROUND_Y := 620.0
const BASE_VIEWPORT_HEIGHT := 720.0
const REFERENCE_MAX_PLATFORM_RISE := 150.0
const MIN_JUMP_CLEARANCE := 24.0

@export var story_mode := false
@export var story_act_ii := false
@export var story_act_iii := false
@export var story_act_iv := false
@export var story_act_v := false
var player: CharacterBody2D
var camera: Camera2D
var run_score = RUN_SCORE.new()
var score: int:
	get: return run_score.total
var stage_index := 0
var stage: Dictionary = {}
var world_width := WORLD_WIDTH
var tutorial = null
var route_label: Label
var hud_root: Control
var stage_start_x := 160.0
var terminal_result: Dictionary = {}
var goal_hint_shown := false
var coins := 0
var reputation := 52
var dialogue_seen: Dictionary = {}
var dialogue_layer: CanvasLayer
var time_left := 180.0
var configured_level_time := 180.0
var finished := false
var resetting := false
var checkpoint := Vector2(160, 540)
var score_label: Label
var coin_label: Label
var reputation_label: Label
var time_label: Label
var progress_bar: ProgressBar
var message_panel: PanelContainer
var touch_input: Node
var pause_menu = null
var pause_button: Button
var attack_button: Button
var visual_effects = null
var score_caption: Label
var _time_icon: Control
var _hud_values: Dictionary = {}
var _best_at_start := 0
var checkpoint_effect_shown := false
var chase_audio_cooldown := 0.0
var configured_enemy_count := -1
var act_i = null
var story_interact_button: Button
var active_story_dialogue: Dictionary = {}

func _ready() -> void:
	_best_at_start = SaveStore.best_score()
	run_score.begin()
	TuningStore.begin_run()
	if story_mode:
		act_i = ACT_I_DIRECTOR.new()
		act_i.name = "ActIDirector"
		act_i.dialogue_requested.connect(_open_story_dialogue)
		add_child(act_i)
	if not _load_stage(0):
		show_message(I18n.t("stage.error.title"), I18n.t("stage.error.body"))
		return
	configured_level_time = TuningStore.get_value("level_time")
	time_left = minf(configured_level_time, STAGE_TIME_LIMITS[0])
	build_world()
	build_hud()
	visual_effects = VISUAL_EFFECTS.new()
	visual_effects.name = "VisualEffects"
	add_child(visual_effects)
	touch_input = TOUCH_INPUT.new()
	add_child(touch_input)
	spawn_player(checkpoint)
	tutorial = TUTORIAL.new()
	tutorial.name = "TutorialDirector"
	add_child(tutorial)
	if not story_mode:
		tutorial.begin()
	pause_menu = PAUSE_MENU.new()
	pause_menu.name = "PauseMenu"
	pause_menu.main_menu_requested.connect(return_to_main_menu)
	pause_menu.restart_requested.connect(restart_run)
	add_child(pause_menu)
	TuningStore.value_changed.connect(_on_tuning_value_changed)
	_on_tuning_value_changed("hud_opacity", TuningStore.get_value("hud_opacity"))
	GameAudio.begin_game()

func _load_stage(index: int) -> bool:
	var registry: Array = _route_stage_ids()
	if index < 0 or index >= registry.size():
		return false
	var definition: Dictionary
	if story_mode:
		definition = _load_story_stage(index)
	else:
		definition = STAGE_CATALOG.load_stage(str(registry[index]))
	if definition.is_empty():
		return false
	stage_index = index
	stage = definition
	world_width = float(stage.world_width)
	checkpoint = _point(stage.spawn)
	stage_start_x = checkpoint.x
	TuningStore.apply_boundary("NEXT_STAGE")
	configured_enemy_count = -1
	if story_mode and act_i != null:
		act_i.begin(self, stage)
	return true

func _route_stage_ids() -> Array:
	if story_mode:
		if story_act_v:
			return ACT_V_STORY.stage_ids()
		if story_act_iv:
			return ACT_IV_STORY.stage_ids()
		if story_act_iii:
			return ACT_III_STORY.stage_ids()
		return ACT_II_STORY.stage_ids() if story_act_ii else ACT_I_STORY.stage_ids()
	return STAGE_CATALOG.stages()

func _load_story_stage(index: int) -> Dictionary:
	if story_act_v:
		return ACT_V_STORY.load_stage(index)
	if story_act_iv:
		return ACT_IV_STORY.load_stage(index)
	if story_act_iii:
		return ACT_III_STORY.load_stage(index)
	if story_act_ii:
		return ACT_II_STORY.load_stage(index)
	return ACT_I_STORY.load_stage(index)

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _stage_child(node: Node) -> void:
	node.add_to_group("stage_node")
	add_child(node)

func build_world() -> void:
	var art
	if story_mode:
		if story_act_v:
			art = ACT_V_STORY.LocationArt.new()
		elif story_act_iv:
			art = ACT_IV_STORY.LocationArt.new()
		elif story_act_iii:
			art = ACT_III_STORY.LocationArt.new()
		elif story_act_ii:
			art = ACT_II_STORY.LocationArt.new()
		else:
			art = ACT_I_STORY.LocationArt.new()
	else:
		art = WORLD_ART.new()
	art.name = "WorldArt"
	art.world_width = world_width
	if story_mode:
		art.location_id = str(stage.id)
	_stage_child(art)
	for entry: Array in stage.grounds:
		add_ground(_point(entry[0]), _point(entry[1]))
	for entry: Array in stage.platforms:
		add_platform(_point(entry[0]), _point(entry[1]))
	for entry: Array in stage.trees:
		add_pipe(_point(entry[0]), _point(entry[1]))
	for support: Array in stage.blocks:
		var block = ENTITIES.QuestionBlock.new()
		block.position = _point(support) - Vector2(0, 26.0 + QUESTION_BLOCK_CLEARANCE)
		block.activated.connect(_on_block_activated)
		_stage_child(block)
	for point: Array in stage.fish:
		spawn_coin(_point(point))
	if not story_mode:
		_spawn_distractions()
	_rebuild_enemies()
	var goal = ENTITIES.GoalFlag.new()
	goal.position = _point(stage.goal)
	goal.reached.connect(_on_goal_reached)
	_stage_child(goal)

func add_ground(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos + Vector2(size.x * 0.5, size.y * 0.5)
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_brick_skin(body, size)
	_stage_child(body)

func add_platform(pos: Vector2, size: Vector2, _color := Color("#c97842")) -> void:
	var body := StaticBody2D.new()
	body.position = pos + Vector2(size.x * 0.5, size.y * 0.5)
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_brick_skin(body, size)
	_stage_child(body)

func add_brick_skin(body: StaticBody2D, size: Vector2) -> void:
	var surface := BRICK_SURFACE.new()
	surface.name = "BrickSurface"
	surface.position = -size * 0.5
	surface.surface_size = size
	body.add_child(surface)

func add_pipe(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var tree := Sprite2D.new()
	tree.texture = CAT_TREE_TEXTURE
	tree.scale = size / CAT_TREE_TEXTURE.get_size()
	body.add_child(tree)
	_stage_child(body)

func spawn_player(pos: Vector2) -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.story_observer_mode = story_mode and (story_act_ii or story_act_iii or story_act_iv or story_act_v)
	player.add_to_group("player")
	player.position = pos
	player.touch_input = touch_input
	player.shot_requested.connect(_on_shot_requested)
	player.died.connect(_on_player_died)
	player.stomped.connect(_on_enemy_stomped)
	player.jumped.connect(_on_player_jumped)
	player.landed.connect(_on_player_landed)
	if player.has_signal("trail_requested"):
		player.trail_requested.connect(visual_effects.spawn_run_dust)
	_stage_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(250, -60)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = TuningStore.get_value("camera_smoothing")
	camera.zoom = Vector2.ONE * TuningStore.get_value("camera_zoom") * ViewportPolicy.world_scale()
	camera.limit_left = 0
	camera.limit_right = int(world_width)
	if not get_viewport().size_changed.is_connected(update_camera_bounds):
		get_viewport().size_changed.connect(update_camera_bounds)
	update_camera_bounds()
	player.add_child(camera)

func update_camera_bounds() -> void:
	if camera == null:
		return
	camera.zoom = Vector2.ONE * TuningStore.get_value("camera_zoom") * ViewportPolicy.world_scale()
	var vertical_extra := maxf(0.0, get_viewport_rect().size.y / camera.zoom.y - BASE_VIEWPORT_HEIGHT)
	camera.limit_top = -ceili(vertical_extra * 0.5)
	camera.limit_bottom = ceili(BASE_VIEWPORT_HEIGHT + vertical_extra * 0.5)

func spawn_coin(pos: Vector2) -> void:
	var coin = ENTITIES.Coin.new()
	coin.position = pos
	coin.collected.connect(_on_coin_collected)
	_stage_child(coin)

## Felt stat patch: cream felt, cocoa rim, running stitch (see felt_kit.gd).
func _hud_chip(name: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = name
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := MENU_STYLE.plate(Color(1.0, 0.953, 0.86, 0.96), 0)
	style.set_corner_radius_all(18)
	style.border_color = Color("#c8905f")
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.content_margin_left = 14
	style.content_margin_right = 16
	style.content_margin_top = 5
	style.content_margin_bottom = 6
	style.shadow_color = Color(0.26, 0.12, 0.05, 0.26)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	chip.add_theme_stylebox_override("panel", style)
	FeltKit.decorate_panel(chip, Color(MENU_STYLE.STITCH, 0.85), 5.0)
	return chip

## Small drawn HUD icon (star for score, felt clock for time).
func _hud_icon(kind: String) -> Control:
	var icon := Control.new()
	icon.name = kind.capitalize() + "Icon"
	icon.custom_minimum_size = Vector2(30, 30)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var c := icon.size * 0.5
		if kind == "star":
			# A ledger mark replaces the generic star score icon.
			icon.draw_rect(Rect2(c - Vector2(11, 13), Vector2(22, 26)), Color("#7d3540"), true)
			icon.draw_rect(Rect2(c - Vector2(7, 9), Vector2(14, 18)), Color("#f1c36f"), true)
			icon.draw_line(c + Vector2(-4, -3), c + Vector2(4, -3), Color("#7d3540"), 2.0)
			icon.draw_line(c + Vector2(-4, 3), c + Vector2(2, 3), Color("#7d3540"), 2.0)
		elif kind == "fund":
			icon.draw_circle(c, 13.0, Color("#d9922e"))
			icon.draw_circle(c, 9.0, Color("#f8d56a"))
			icon.draw_string(load("res://assets/template/fonts/ui_bold.tres"), c + Vector2(-6, 5), "RF", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7a431c"))
		else:
			var total := maxf(1.0, configured_level_time)
			FeltKit.draw_clock(icon, c + Vector2(0, 2), 12, 1.0 - time_left / total, time_left <= 30.0))
	return icon

## Punchy count feedback: the number pops and warms when its value changes.
func _punch(label: Label, value: String, urgent: bool = false) -> void:
	if _hud_values.get(label, "") == value: return
	var first := not _hud_values.has(label)
	_hud_values[label] = value
	if first or FeltKit.reduced_motion() or not label.is_inside_tree():
		if urgent: label.add_theme_color_override("font_color", FeltKit.TOMATO)
		return
	label.pivot_offset = label.size * 0.5
	var tween := label.create_tween().set_parallel(true)
	label.scale = Vector2(1.28, 1.28)
	tween.tween_property(label, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label.add_theme_color_override("font_color", MENU_STYLE.ACCENT)
	tween.tween_method(func(v: float): label.add_theme_color_override("font_color", MENU_STYLE.ACCENT.lerp(FeltKit.TOMATO if urgent else MENU_STYLE.COCOA, v)), 0.0, 1.0, 0.4)

func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HudLayer"
	layer.layer = 10
	add_child(layer)
	hud_root = Control.new()
	hud_root.name = "ResponsiveHud"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	# Felt stat chips float over the art instead of a heavy full-width bar.
	var top_bar := PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 12
	top_bar.offset_top = 10
	top_bar.offset_right = -12
	top_bar.offset_bottom = 84
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	top_bar.add_theme_stylebox_override("panel", style)
	hud_root.add_child(top_bar)
	top_bar.minimum_size_changed.connect(_fit_hud_height)
	var content := VBoxContainer.new()
	content.name = "HudContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	top_bar.add_child(content)
	var row := HBoxContainer.new()
	row.name = "Stats"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	score_label = make_hud_label(I18n.t("hud.score", {"score": "000000"}), Vector2(0, 40))
	coin_label = make_hud_label(I18n.t("hud.fish", {"count": "00"}), Vector2(0, 40))
	time_label = make_hud_label(I18n.t("hud.time", {"time": "%03d" % ceili(time_left)}), Vector2(0, 40))
	for pair: Array in [["ScoreChip", score_label], ["FishChip", coin_label], ["TimeChip", time_label]]:
		var chip := _hud_chip(pair[0])
		var inner := HBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_constant_override("separation", 6)
		chip.add_child(inner)
		if pair[0] == "ScoreChip":
			inner.add_child(_hud_icon("star"))
			var stack := VBoxContainer.new()
			stack.name = "ScoreStack"
			stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stack.add_theme_constant_override("separation", -4)
			stack.alignment = BoxContainer.ALIGNMENT_CENTER
			inner.add_child(stack)
			score_caption = Label.new()
			score_caption.name = "ScoreCaption"
			score_caption.text = I18n.t("hud.score.caption")
			score_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			score_caption.add_theme_font_override("font", MENU_STYLE.tracked(MENU_STYLE.BOLD, 2))
			score_caption.add_theme_font_size_override("font_size", 11)
			score_caption.add_theme_color_override("font_color", MENU_STYLE.MUTED)
			stack.add_child(score_caption)
			stack.add_child(pair[1])
			row.add_child(chip)
			continue
		if pair[0] == "TimeChip":
			_time_icon = _hud_icon("clock")
			inner.add_child(_time_icon)
		if pair[0] == "FishChip":
			inner.add_child(_hud_icon("fund"))
		inner.add_child(pair[1])
		row.add_child(chip)
	var rep_chip := _hud_chip("ReputationChip")
	var rep_inner := HBoxContainer.new()
	rep_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rep_inner.add_theme_constant_override("separation", 6)
	reputation_label = make_hud_label(I18n.t("hud.reputation", {"value": reputation}), Vector2(0, 40))
	rep_inner.add_child(reputation_label)
	rep_chip.add_child(rep_inner)
	row.add_child(rep_chip)
	var progress := VBoxContainer.new()
	progress.name = "Route"
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress.alignment = BoxContainer.ALIGNMENT_CENTER
	progress.add_theme_constant_override("separation", 4)
	row.add_child(progress)
	route_label = Label.new()
	route_label.text = _objective_text()
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	route_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	route_label.add_theme_font_override("font", MENU_STYLE.MEDIUM)
	route_label.add_theme_font_size_override("font_size", 14)
	route_label.add_theme_color_override("font_color", Color("#fff4dd"))
	route_label.add_theme_color_override("font_outline_color", Color(0.29, 0.15, 0.08, 0.85))
	route_label.add_theme_constant_override("outline_size", 6)
	progress.add_child(route_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 12)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.max_value = world_width
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Route = a felt strip with a running stitch; a yarn ball rolls along it,
	# unwinding its thread from the start post towards the flag.
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.36, 0.19, 0.1, 0.62)
	bg.border_color = Color(1.0, 0.95, 0.84, 0.75)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	progress_bar.add_theme_stylebox_override("background", bg)
	progress_bar.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	progress_bar.custom_minimum_size.y = 16
	progress_bar.material = FeltKit.felt_material()
	progress_bar.draw.connect(_draw_route)
	progress.add_child(progress_bar)
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "Ⅱ"
	pause_button.tooltip_text = I18n.t("hud.pause")
	pause_button.accessibility_name = I18n.t("hud.pause")
	pause_button.custom_minimum_size = Vector2(48, 48)
	pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_round_button(pause_button, Color(1.0, 0.953, 0.86, 0.96), MENU_STYLE.STITCH, MENU_STYLE.COCOA)
	pause_button.add_theme_font_override("font", MENU_STYLE.BOLD)
	pause_button.add_theme_font_size_override("font_size", 22)
	pause_button.pressed.connect(toggle_pause)
	row.add_child(pause_button)
	attack_button = Button.new()
	attack_button.name = "AttackButton"
	attack_button.text = I18n.t("hud.yarn")
	attack_button.tooltip_text = I18n.t("hud.yarn")
	attack_button.accessibility_name = I18n.t("hud.yarn")
	attack_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	attack_button.offset_left = -88
	attack_button.offset_top = -84
	attack_button.offset_right = -16
	attack_button.offset_bottom = -16
	_style_round_button(attack_button, Color(MENU_STYLE.ACCENT, 0.94), Color("#9b3520"), Color("#fffaf0"))
	attack_button.add_theme_font_override("font", MENU_STYLE.BOLD)
	attack_button.add_theme_font_size_override("font_size", 15)
	attack_button.add_theme_constant_override("line_spacing", -2)
	attack_button.pressed.connect(_request_touch_attack)
	hud_root.add_child(attack_button)
	story_interact_button = Button.new()
	story_interact_button.name = "StoryInteractButton"
	story_interact_button.text = I18n.t("story.button.listen")
	story_interact_button.tooltip_text = I18n.t("story.button.listen")
	story_interact_button.accessibility_name = I18n.t("story.button.listen")
	story_interact_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	story_interact_button.offset_left = -122
	story_interact_button.offset_top = -86
	story_interact_button.offset_right = 122
	story_interact_button.offset_bottom = -16
	_style_round_button(story_interact_button, Color("#f4dda9"), Color("#a76545"), Color("#5d382c"))
	story_interact_button.add_theme_font_override("font", MENU_STYLE.BOLD)
	story_interact_button.add_theme_font_size_override("font_size", 15)
	story_interact_button.pressed.connect(_request_story_interact)
	story_interact_button.visible = false
	hud_root.add_child(story_interact_button)
	_add_mouse_controls()
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_fade_in()

## Scene transition: a cocoa felt veil lifts off the course as the run begins.
func _fade_in() -> void:
	if FeltKit.reduced_motion(): return
	var layer := CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 90
	add_child(layer)
	var veil := ColorRect.new()
	veil.color = Color("#3a1d0f")
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(veil)
	var tween := veil.create_tween()
	tween.tween_property(veil, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(layer.queue_free)

## Round felt "sewn button" (pause, yarn): stitched ring, stuffed depth, press squash.
func _style_round_button(button: Button, color: Color, edge: Color, ink: Color) -> void:
	FeltKit.felt_button(button, &"round", color, edge, 24.0, 4.0, 1.0)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, ink)


func _layout_hud() -> void:
	if not is_instance_valid(hud_root): return
	var size := get_viewport_rect().size
	for label in [score_label, coin_label, time_label]:
		label.add_theme_font_size_override("font_size", 14 if size.x < 400 else 17 if size.x < 800 else 19)
		label.add_theme_font_override("font", MENU_STYLE.trimmed(MENU_STYLE.SMALL_HEADING, label.get_theme_font_size("font_size"), 0.26, 0.3))
	var top: PanelContainer = hud_root.get_node("TopBar")
	top.offset_top = 4 if size.y < 240 else 10
	var compact := size.y < 240 or size.x < 700
	for chip_name in ["ScoreChip", "FishChip", "TimeChip"]:
		var chip: PanelContainer = top.get_node("HudContent/Stats/" + chip_name)
		var chip_style := chip.get_theme_stylebox("panel") as StyleBoxFlat
		chip_style.content_margin_left = 8 if compact else 14
		chip_style.content_margin_right = 10 if compact else 16
		chip_style.content_margin_top = 2 if compact else 5
		chip_style.content_margin_bottom = 3 if compact else 6
	top.get_node("HudContent/Stats/FishChip").get_child(0).get_node("FundIcon").visible = size.x >= 520
	top.get_node("HudContent/Stats/ScoreChip").get_child(0).get_node("StarIcon").visible = size.x >= 520
	_time_icon.visible = size.x >= 520
	score_caption.visible = size.y >= 240 and size.x >= 400
	top.get_node("HudContent/Stats").add_theme_constant_override("separation", 6 if compact else 10)
	top.get_node("HudContent/Stats/Route").visible = size.y >= 340 and size.x >= 700
	top.offset_left = 12
	top.offset_right = -12
	_fit_hud_height()

func _fit_hud_height() -> void:
	if not is_instance_valid(hud_root): return
	var top: PanelContainer = hud_root.get_node("TopBar")
	top.offset_bottom = top.offset_top + top.get_combined_minimum_size().y

func _sync_touch_controls() -> void:
	var active := is_inside_tree() and not get_tree().paused and not finished and not resetting
	if is_instance_valid(attack_button): attack_button.visible = active and not story_mode
	if is_instance_valid(story_interact_button):
		story_interact_button.visible = active and story_mode and act_i != null and act_i.can_interact()
		if story_mode and act_i != null:
			if act_i.stealth_active:
				story_interact_button.text = I18n.t("story.button.peek") if player.story_hidden else I18n.t("story.button.hide")
			else:
				story_interact_button.text = I18n.t("story.button.listen")
			story_interact_button.accessibility_name = story_interact_button.text
	for mouse_control in get_tree().get_nodes_in_group("mouse_controls"):
		mouse_control.visible = active
	if is_instance_valid(touch_input):
		touch_input.set_process_unhandled_input(active)
		if not active: touch_input.clear_input()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED:
		_sync_touch_controls()

func make_hud_label(text: String, minimum_size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = minimum_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", MENU_STYLE.SMALL_HEADING)
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", MENU_STYLE.COCOA)
	return label

func _process(delta: float) -> void:
	if finished or resetting or player == null:
		return
	run_score.tick(delta)
	if tutorial != null and absf(player.global_position.x - stage_start_x) > 60.0:
		tutorial.notify("moved")
	if story_mode and act_i != null:
		act_i.tick(delta)
		if Input.is_action_just_pressed("interact"):
			_request_story_interact()
		if is_instance_valid(route_label):
			route_label.text = _objective_text()
		_sync_touch_controls()
	if camera != null:
		camera.position_smoothing_speed = TuningStore.get_value("camera_smoothing")
	time_left = maxf(time_left - delta, 0.0)
	chase_audio_cooldown = maxf(chase_audio_cooldown - delta, 0.0)
	if is_instance_valid(player) and chase_audio_cooldown <= 0.0:
		var creditor := get_tree().get_first_node_in_group("enemy")
		if creditor != null and player.global_position.distance_to(creditor.global_position) < 520.0:
			GameAudio.play(&"voice_chase")
			GameAudio.play(&"pursuit")
			chase_audio_cooldown = 9.0
	if time_left <= 0.0:
		_on_time_up()
		return
	if not story_mode and not checkpoint_effect_shown and player.global_position.x >= float(stage.checkpoint[0]):
		checkpoint_effect_shown = true
		GameAudio.play(&"checkpoint")
		checkpoint = _point(stage.checkpoint)
		if stage_index == 0: GameAudio.play(&"voice_excerpt")
		visual_effects.spawn_checkpoint_burst(checkpoint + Vector2(0, -36))
		if tutorial != null: tutorial.notify("checkpoint")
		if not bool(dialogue_seen.get(stage_index, false)):
			dialogue_seen[stage_index] = true
			call_deferred("_open_dialogue", stage_index)
	progress_bar.value = clampf(player.global_position.x, 0.0, world_width)
	time_label.text = I18n.t("hud.time", {"time": "%03d" % ceili(time_left)})
	_tick_timer()

## Felt clock hand sweeps; under 30 s the numbers turn tomato and tick-punch.
func _tick_timer() -> void:
	if is_instance_valid(_time_icon): _time_icon.queue_redraw()
	var urgent := time_left <= 30.0
	if urgent:
		_punch(time_label, time_label.text, true)
	elif _hud_values.has(time_label):
		_hud_values.erase(time_label)
		time_label.add_theme_color_override("font_color", MENU_STYLE.COCOA)

func _accept_game_event() -> bool:
	return not finished and not resetting and is_instance_valid(player) and player.alive

func _objective_text() -> String:
	if stage.is_empty():
		return ""
	if story_mode and act_i != null:
		return act_i.objective_text()
	var stage_name := I18n.t(str(stage.name_key))
	if int(stage.required_fish) > 0:
		return I18n.t("stage.objective.fish", {"stage": stage_name, "count": mini(coins, int(stage.required_fish)), "target": int(stage.required_fish)})
	return I18n.t("stage.objective.exit", {"stage": stage_name})

func _on_coin_collected(position: Vector2) -> void:
	if not _accept_game_event(): return
	GameAudio.play(&"coin")
	coins += 1
	SaveStore.note_reform_fund()
	reputation = clampi(reputation + 1, 0, 100)
	run_score.award("fish")
	visual_effects.spawn_collect_sparkle(position)
	update_hud()

func _on_enemy_stomped() -> void:
	if not _accept_game_event(): return
	GameAudio.play(&"stomp")
	run_score.award("robot")
	visual_effects.spawn_stomp_impact(player.global_position + Vector2(0, 20))
	update_hud()

func _on_block_activated(pos: Vector2) -> void:
	if not _accept_game_event(): return
	GameAudio.play(&"coin")
	run_score.award("block")
	visual_effects.spawn_collect_sparkle(pos)
	spawn_coin(pos)
	update_hud()

func _on_player_jumped(position: Vector2) -> void:
	if tutorial != null: tutorial.notify("jumped")
	GameAudio.play(&"jump")
	visual_effects.spawn_jump_dust(position)

func _on_player_landed(position: Vector2) -> void:
	GameAudio.play(&"land")
	visual_effects.spawn_land_dust(position)

func update_hud() -> void:
	_sync_touch_controls()
	score_label.text = I18n.t("hud.score", {"score": "%06d" % score})
	coin_label.text = I18n.t("hud.fish", {"count": "%02d" % coins})
	if reputation_label != null: reputation_label.text = I18n.t("hud.reputation", {"value": reputation})
	route_label.text = _objective_text()
	if score_caption != null: score_caption.text = I18n.t("hud.score.caption")
	_punch(score_label, score_label.text)
	_punch(coin_label, coin_label.text)

func _draw_route() -> void:
	var bar := progress_bar
	var ratio := clampf(bar.value / maxf(1.0, bar.max_value), 0.0, 1.0)
	var mid := bar.size.y * 0.5
	var left := 10.0
	var right := bar.size.x - 22.0
	FeltKit.draw_dashes(bar, Vector2(left, mid), Vector2(right, mid), Color(1.0, 0.95, 0.84, 0.55), 1.6, 6, 5)
	var head := lerpf(left, right, ratio)
	# Unwound thread behind the ball, gently wavy like real yarn.
	var thread := PackedVector2Array()
	var steps := maxi(2, int((head - left) / 6.0))
	for i in steps + 1:
		var x := lerpf(left, head, float(i) / steps)
		thread.append(Vector2(x, mid + sin(x * 0.18) * 1.6))
	bar.draw_polyline(thread, Color("#e0584a"), 3.0, true)
	# Street map marker and safe-house endpoint; no flag or yarn-ball route cue.
	var safe := Vector2(bar.size.x - 22.0, mid)
	bar.draw_rect(Rect2(safe - Vector2(12, 10), Vector2(24, 20)), Color("#1f5860"), true)
	bar.draw_colored_polygon(PackedVector2Array([safe + Vector2(-15, -10), safe + Vector2(15, -10), safe + Vector2(0, -20)]), Color("#a74436"))
	bar.draw_rect(Rect2(safe - Vector2(5, 2), Vector2(10, 12)), Color("#f1c36f"), true)
	bar.draw_circle(Vector2(head, mid), 8.0, Color("#f1b24b"))
	bar.draw_string(load("res://assets/template/fonts/ui_bold.tres"), Vector2(head - 6, mid + 4), "G", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#7d3540"))

func _dialogue_data(stage_id: int) -> Dictionary:
	var scenes := [
		{
			"title": "LECTURE 1 · MY STOMACH FIRST",
			"line": "Dammit! This reform fund belongs to the people. Who are the people? I am among them, am I not? Therefore the first fund in my pocket is a democratic procedure.",
			"choices": [
				{"text": "National progress first; but I do require a snack.", "delta": -7, "after": "Reputation slipped. The snack did not."},
				{"text": "Write it down, my boy—half goes toward your education.", "delta": 8, "after": "Sweet words. Peppery intentions."}
			]
			},
			{
				"title": "LECTURE 2 · THE ECHO IN THE PURSE",
				"line": "Dammit, creditor, my purse is so empty its echo has started asking me for rent. I owe you a plan, not another grand excuse.",
				"choices": [
					{"text": "Your patience is a public treasure, sir. Could it cover my private debt?", "delta": -2, "after": "He enjoys the praise, then taps the unpaid ledger. No delay; no shortcut."},
					{"text": "No coin today; my purse is an echo. Let me write a repayment plan.", "delta": 9, "time_bonus": 5.0, "after": "He accepts the plan and points out a safe shortcut (+5 seconds). Even Gireesam hears the echo."}
				]
			},
		{
			"title": "FINAL LECTURE · A PRUDENT ESCAPE",
			"line": "Dammit! Escape is not cowardice—it is prudence. If caught, my philosophy collapses; if free, the same philosophy becomes a triumph. Dammit, where is the door?",
			"choices": [
				{"text": "Protect our reputation and proceed like gentlemen.", "delta": 10, "after": "Reputation rose. Gireesam applauded himself."},
				{"text": "Find the door first; history can be written tomorrow.", "delta": -6, "after": "The door appeared. History gained another story."}
			]
		}
	]
	return scenes[clampi(stage_id, 0, scenes.size() - 1)]

func _open_story_dialogue(data: Dictionary) -> void:
	_open_dialogue(stage_index, data)

func _request_story_interact() -> void:
	if story_mode and act_i != null and act_i.can_interact():
		act_i.interact()

func _open_dialogue(stage_id: int, story_data: Dictionary = {}) -> void:
	if dialogue_layer != null or finished or resetting: return
	var data := story_data if story_mode else _dialogue_data(stage_id)
	active_story_dialogue = data.duplicate(true) if story_mode else {}
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.name = "GireesamDialogue"
	dialogue_layer.layer = 60
	dialogue_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialogue_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.12, 0.05, 0.03, 0.74)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "DialoguePanel"
	panel.custom_minimum_size = Vector2(minf(760.0, get_viewport_rect().size.x - 32.0), 0)
	MENU_STYLE.felt_card(panel, Color(1.0, 0.955, 0.86, 0.99), 26)
	center.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	var title_text := ("ADAPTED SCENE · " if story_mode else "") + str(data.title)
	var title := MENU_STYLE.ribbon(title_text, 30, FeltKit.TEAL)
	body.add_child(title)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	body.add_child(content)
	if not story_mode:
		var portrait := TextureRect.new()
		portrait.texture = GIREE_TEXTURE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(245, 245)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		content.add_child(portrait)
	var copy := Label.new()
	copy.text = str(data.line)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_font_override("font", MENU_STYLE.MEDIUM)
	copy.add_theme_font_size_override("font_size", 21)
	copy.add_theme_color_override("font_color", MENU_STYLE.INK)
	content.add_child(copy)
	var telugu_line_text := str(data.get("telugu_line", ""))
	if story_mode and not telugu_line_text.is_empty():
		var telugu_line := MENU_STYLE.label(telugu_line_text, 24)
		telugu_line.name = "TeluguPilotLine"
		telugu_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		telugu_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		telugu_line.add_theme_font_override("font", MENU_STYLE.MEDIUM)
		telugu_line.add_theme_color_override("font_color", MENU_STYLE.INK)
		body.add_child(telugu_line)
	var prompt := MENU_STYLE.label(I18n.t("story.dialogue.tag") if story_mode else "WHICH ARGUMENT WILL OPEN THE WAY?", 16)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_color", MENU_STYLE.MUTED)
	body.add_child(prompt)
	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	body.add_child(choices)
	for choice in data.choices:
		var choice_text := str(choice) if story_mode else str(choice.text)
		var button := MENU_STYLE.button(choice_text, false)
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_choose_dialogue.bind(stage_id, choices.get_child_count()))
		choices.add_child(button)
	get_tree().paused = true
	if is_instance_valid(player): player.clear_input()
	choices.get_child(0).grab_focus()

func _choose_dialogue(stage_id: int, choice_index: int) -> void:
	if dialogue_layer == null: return
	if story_mode:
		var response: String = act_i.resolve_choice(choice_index)
		var story_layer := dialogue_layer
		dialogue_layer = null
		active_story_dialogue = {}
		story_layer.queue_free()
		get_tree().paused = false
		if is_instance_valid(player): player.clear_input()
		update_hud()
		route_label.text = response
		_sync_touch_controls()
		return
	var data := _dialogue_data(stage_id)
	var selected: Dictionary = data.choices[clampi(choice_index, 0, data.choices.size() - 1)]
	reputation = clampi(reputation + int(selected.delta), 0, 100)
	var time_bonus := float(selected.get("time_bonus", 0.0))
	if time_bonus > 0.0:
		var bonus_stage := clampi(stage_id, 0, STAGE_TIME_LIMITS.size() - 1)
		var stage_time_cap := minf(configured_level_time, float(STAGE_TIME_LIMITS[bonus_stage]))
		var boosted_time := time_left + time_bonus
		if time_left <= stage_time_cap:
			boosted_time = minf(boosted_time, stage_time_cap)
		time_left = maxf(time_left, boosted_time)
	var response := str(selected.after)
	var layer := dialogue_layer
	dialogue_layer = null
	layer.queue_free()
	get_tree().paused = false
	if is_instance_valid(player): player.clear_input()
	update_hud()
	route_label.text = response
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(route_label) and not finished: route_label.text = _objective_text()

func _on_player_died() -> void:
	if resetting or finished:
		return
	resetting = true
	_sync_touch_controls()
	if tutorial != null: tutorial.notify("damaged")
	touch_input._end()
	GameAudio.play(&"death")
	visual_effects.spawn_death_burst(player.global_position)
	show_message(I18n.t("result.retry"), I18n.t("result.checkpoint"))
	await get_tree().create_timer(0.8, false).timeout
	if finished or not is_inside_tree(): return
	if is_instance_valid(player):
		player.queue_free()
	await get_tree().process_frame
	remove_message()
	time_left = maxf(time_left - 10.0, 0.0)
	spawn_player(checkpoint)
	resetting = false
	_sync_touch_controls()
	if time_left <= 0.0: _on_time_up()

func _on_time_up() -> void:
	if finished or resetting:
		return
	finished = true
	time_left = 0.0
	time_label.text = I18n.t("hud.time", {"time": "000"})
	GameAudio.play(&"death")
	_finish_run("defeat")
	_freeze_stage()
	show_message(I18n.t("result.timeout"), I18n.t("result.summary", {"score": score, "duration": ceili(run_score.duration), "reputation": reputation}))

func _on_goal_reached() -> void:
	if not _accept_game_event():
		return
	if story_mode and act_i != null and not act_i.can_clear_scene():
		if not goal_hint_shown:
			goal_hint_shown = true
			GameAudio.play(&"invalid")
		route_label.text = _objective_text()
		return
	if coins < int(stage.required_fish):
		if not goal_hint_shown:
			goal_hint_shown = true
			GameAudio.play(&"invalid")
		route_label.text = I18n.t("stage.need_fish", {"count": int(stage.required_fish) - coins})
		return
	finished = true
	run_score.award("time_second", int(time_left))
	update_hud()
	_freeze_stage()
	visual_effects.spawn_finish_confetti(player.global_position + Vector2(0, -90))
	if stage_index + 1 < _route_stage_ids().size():
		GameAudio.play(&"stage_clear")
		var next_definition: Dictionary
		if story_mode:
			next_definition = _load_story_stage(stage_index + 1)
		else:
			next_definition = STAGE_CATALOG.load_stage(str(_route_stage_ids()[stage_index + 1]))
		if story_mode:
			show_message(I18n.t("story.stage_clear"), I18n.t("story.stage_summary", {"stage": I18n.t(stage.name_key), "next": I18n.t(str(next_definition.get("name_key", "stage.error.title")))}))
		else:
			show_message(I18n.t("result.stage_clear"), I18n.t("result.stage_summary", {"stage": I18n.t(stage.name_key), "score": score, "reputation": reputation, "next": I18n.t(str(next_definition.get("name_key", "stage.error.title")))}))
	else:
		GameAudio.play(&"success")
		_finish_run("victory")
		if story_mode:
			if story_act_v:
				show_message(I18n.t("story.act5.ending"), I18n.t("story.act5.ending_copy"))
			elif story_act_iv:
				show_message(I18n.t("story.act4.ending"), I18n.t("story.act4.ending_copy"))
			elif story_act_iii:
				show_message(I18n.t("story.act3.ending"), I18n.t("story.act3.ending_copy"))
			elif story_act_ii:
				show_message(I18n.t("story.act2.ending"), I18n.t("story.act2.ending_copy"))
			else:
				show_message(I18n.t("story.act1.ending"), I18n.t("story.act1.ending_copy"))
		else:
			show_message(I18n.t("result.victory"), I18n.t("result.summary", {"score": score, "duration": ceili(run_score.duration), "reputation": reputation}))

func _finish_run(outcome: String) -> void:
	if not story_mode:
		SaveStore.update_campaign_progress(stage_index + 1 if outcome == "victory" else stage_index, reputation)
	terminal_result = run_score.finalize(str(stage.id), outcome, not TuningStore.is_run_tainted(), TuningStore.get_run_config())
	SaveStore.record_run(terminal_result)
	CloudProfile.sync_now()
	TuningStore.end_run()
	if tutorial != null and tutorial.active:
		tutorial.skip()

func _freeze_stage() -> void:
	_sync_touch_controls()
	touch_input._end()
	if is_instance_valid(player):
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("enemy"):
		node.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("yarn_projectile"):
		node.queue_free()

func restart_run() -> void:
	get_tree().paused = false
	GameAudio.stop_game()
	get_tree().reload_current_scene()

func next_stage() -> void:
	if not finished or not terminal_result.is_empty():
		return
	remove_message()
	for node in get_tree().get_nodes_in_group("stage_node"):
		node.free()
	player = null
	camera = null
	if visual_effects.has_method("reset_effects"):
		visual_effects.reset_effects()
	coins = 0
	checkpoint_effect_shown = false
	goal_hint_shown = false
	if not _load_stage(stage_index + 1):
		show_message(I18n.t("stage.error.title"), I18n.t("stage.error.body"))
		return
	time_left = configured_level_time
	build_world()
	spawn_player(checkpoint)
	progress_bar.max_value = world_width
	finished = false
	resetting = false
	update_hud()
	GameAudio.begin_game()

func show_message(title: String, subtitle: String) -> void:
	if message_panel != null:
		remove_message()
	var terminal := finished or stage.is_empty()
	var canvas := CanvasLayer.new()
	canvas.layer = 35
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	var veil := ColorRect.new()
	veil.name = "ResultVeil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(0.16, 0.08, 0.04, 1.0 if terminal else 0.0)
	veil.material = FeltKit.veil_material(0.32)
	veil.visible = terminal
	canvas.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)
	message_panel = PanelContainer.new()
	message_panel.name = "ResultPanel"
	message_panel.custom_minimum_size = Vector2(minf(560.0, get_viewport_rect().size.x - 24.0), 0)
	MENU_STYLE.felt_card(message_panel, Color(1.0, 0.955, 0.86, 0.98), 24)
	center.add_child(message_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	message_panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var cleared := finished and time_left > 0.0
	var ribbon_color := FeltKit.TEAL if cleared else MENU_STYLE.ACCENT
	box.add_child(MENU_STYLE.ribbon(title, 40, ribbon_color, "ResultHeading"))
	var reveal: Label
	if finished:
		# Big felt score reveal, counted up, with the run's fish haul beside it.
		var tally := VBoxContainer.new()
		tally.name = "ScoreReveal"
		tally.add_theme_constant_override("separation", -6)
		box.add_child(tally)
		var caption := MENU_STYLE.label(I18n.t("result.score_caption"), 14)
		caption.add_theme_font_override("font", MENU_STYLE.tracked(MENU_STYLE.BOLD, 3))
		caption.add_theme_color_override("font_color", MENU_STYLE.MUTED)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tally.add_child(caption)
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 18)
		tally.add_child(line)
		reveal = Label.new()
		reveal.name = "ScoreValue"
		reveal.text = "%06d" % (0 if not FeltKit.reduced_motion() else score)
		MENU_STYLE.display(reveal, 64, Color("#fff6e2"), MENU_STYLE.COCOA, 9)
		line.add_child(reveal)
		var haul := HBoxContainer.new()
		haul.add_theme_constant_override("separation", 2)
		line.add_child(haul)
		var fund_icon := _hud_icon("fund")
		fund_icon.custom_minimum_size = Vector2(40, 40)
		haul.add_child(fund_icon)
		var count := MENU_STYLE.label(I18n.t("result.fish", {"count": "%02d" % coins}), 26)
		count.add_theme_font_override("font", MENU_STYLE.trimmed(MENU_STYLE.SMALL_HEADING, 26, 0.24, 0.3))
		count.add_theme_color_override("font_color", MENU_STYLE.COCOA)
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		haul.add_child(count)
		if not terminal_result.is_empty() and score > _best_at_start and score > 0:
			var best := MENU_STYLE.ribbon(I18n.t("result.new_best"), 20, FeltKit.MUSTARD)
			best.name = "NewBest"
			best.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tally.add_child(best)
	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_override("font", MENU_STYLE.MEDIUM)
	sub_label.add_theme_font_size_override("font_size", 18 if finished else 20)
	sub_label.add_theme_constant_override("line_spacing", 4)
	sub_label.add_theme_color_override("font_color", MENU_STYLE.MUTED if finished else MENU_STYLE.INK)
	box.add_child(sub_label)
	if terminal:
		var gap := Control.new()
		gap.custom_minimum_size.y = 2
		box.add_child(gap)
	var first_button: Button
	if terminal:
		if finished and terminal_result.is_empty() and stage_index + 1 < _route_stage_ids().size():
			first_button = _result_button(box, "result.next_stage", next_stage)
		else:
			first_button = _result_button(box, "result.play_again", restart_run)
		_result_button(box, "result.title", return_to_main_menu)
	var result_panel := message_panel
	var fit := func():
		if not is_instance_valid(result_panel): return
		var reserved := 0.0
		center.offset_bottom = -reserved
		var available := get_viewport_rect().size - Vector2(24, 24 + reserved)
		var target_height := minf(box.get_combined_minimum_size().y + 48.0, available.y)
		result_panel.custom_minimum_size = Vector2(minf(560.0, available.x), target_height)
		scroll.custom_minimum_size.y = maxf(12.0, target_height - 48.0)
	center.resized.connect(fit)
	box.minimum_size_changed.connect(fit)
	add_child(canvas)
	fit.call()
	if terminal:
		var cursor := FeltKit.YarnCursor.new()
		canvas.add_child(cursor)
		for button in box.find_children("*", "Button", true, false): cursor.track(button)
	MENU_MODAL.pop_in(veil, message_panel)
	if reveal != null and not FeltKit.reduced_motion():
		var final_score := score
		var count_up := reveal.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		count_up.tween_interval(0.25)
		count_up.tween_method(func(v: float): reveal.text = "%06d" % roundi(v), 0.0, float(final_score), clampf(0.4 + final_score / 4000.0, 0.5, 1.1)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		count_up.tween_callback(func():
			reveal.pivot_offset = reveal.size * 0.5
			reveal.scale = Vector2(1.18, 1.18))
		count_up.tween_property(reveal, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if first_button != null:
		first_button.grab_focus()

func _result_button(parent: Control, key: String, callback: Callable) -> Button:
	var button := MENU_STYLE.button(I18n.t(key), key != "result.title")
	button.accessibility_name = button.text
	button.custom_minimum_size = Vector2(0, 56 if key != "result.title" else 48)
	button.add_theme_font_size_override("font_size", 22 if key != "result.title" else 18)
	if key == "result.title":
		button.set_meta("audio_cue", "back")
		MENU_STYLE.menu_item(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func remove_message() -> void:
	if message_panel != null:
		var canvas := message_panel.get_parent().get_parent()
		canvas.queue_free()
		message_panel = null

func toggle_pause() -> void:
	if finished or resetting: return
	if tutorial != null: tutorial.notify("paused")
	if pause_menu == null:
		return
	pause_menu.toggle_menu()

func return_to_main_menu() -> void:
	GameAudio.stop_game()
	TuningStore.end_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	if finished and event.is_action_pressed("ui_cancel"):
		viewport.set_input_as_handled()
		return_to_main_menu()
		return
	if event.is_action_pressed("pause"):
		toggle_pause()
		viewport.set_input_as_handled()
		return
	if finished and event.is_action_pressed("start"):
		var focused := viewport.gui_get_focus_owner()
		if focused is Button: focused.pressed.emit()
		viewport.set_input_as_handled()


func _exit_tree() -> void:
	GameAudio.stop_game()


func _request_touch_attack() -> void:
	if is_instance_valid(player):
		player.try_attack()


func _on_shot_requested(position: Vector2, direction: float) -> void:
	if finished or resetting or get_tree().paused:
		return
	TuningStore.apply_boundary("NEXT_SPAWN")
	if tutorial != null: tutorial.notify("shot")
	if get_tree().get_nodes_in_group("yarn_projectile").size() >= MAX_YARN_BALLS:
		return
	var ball := YARN_BALL.new()
	ball.position = position
	ball.direction = direction
	ball.speed = TuningStore.get_value("yarn_speed")
	ball.lifetime = TuningStore.get_value("yarn_lifetime")
	ball.gravity = TuningStore.get_value("yarn_gravity")
	ball.launch_speed = TuningStore.get_value("yarn_launch_speed")
	ball.enemy_hit.connect(_on_yarn_hit)
	add_child(ball)
	GameAudio.play(&"attack")


func _on_yarn_hit(position: Vector2) -> void:
	if finished or resetting:
		return
	run_score.award("robot")
	GameAudio.play(&"stomp")
	visual_effects.spawn_stomp_impact(position)
	update_hud()


func _on_tuning_value_changed(key: String, value: float) -> void:
	if key == "hud_opacity" and hud_root != null:
		hud_root.modulate.a = value
	elif key == "camera_zoom" and camera != null:
		camera.zoom = Vector2.ONE * value * ViewportPolicy.world_scale()
		update_camera_bounds()
		camera.force_update_scroll()
	elif key == "enemy_count" and roundi(value) != configured_enemy_count:
		_rebuild_enemies.call_deferred()


func _spawn_distractions() -> void:
	var route_x := [900.0, 2050.0, 3350.0, 5050.0, 6500.0]
	var kinds := [["SNACK", "BAJJI"], ["CIGARETTE", "SMOKE"], ["BOOK", "LECTURE"]]
	for i in 3:
		var d = ENTITIES.Distraction.new()
		d.kind = str(kinds[(stage_index + i) % kinds.size()][0])
		d.label = str(kinds[(stage_index + i) % kinds.size()][1])
		d.position = Vector2(route_x[(stage_index * 2 + i) % route_x.size()], 540.0)
		d.attracted.connect(_on_distraction_attracted)
		_stage_child(d)
func _on_distraction_attracted(kind: String, position: Vector2) -> void:
	if not _accept_game_event(): return
	time_left = maxf(time_left - 5.0, 0.0)
	reputation = clampi(reputation - 2, 0, 100)
	GameAudio.play(&"temptation")
	if kind == "SNACK": GameAudio.play(&"voice_snack")
	route_label.text = "DAMMIT! TEMPTED BY %s · -5 SECONDS" % kind
	visual_effects.spawn_collect_sparkle(position)
	update_hud()
func _add_mouse_controls() -> void:
	var controls := HBoxContainer.new()
	controls.name = "MouseControls"
	controls.add_to_group("mouse_controls")
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 18
	controls.offset_top = -84
	controls.offset_right = 360
	controls.offset_bottom = -16
	controls.add_theme_constant_override("separation", 7)
	for spec in [["◀", "LEFT"], ["▶", "RIGHT"], ["JUMP", "JUMP"], ["TALK", "TALK"]]:
		var button := Button.new()
		button.text = str(spec[0])
		button.tooltip_text = "Mouse: " + str(spec[1])
		button.custom_minimum_size = Vector2(72 if str(spec[1]) in ["LEFT", "RIGHT"] else 82, 52)
		_style_round_button(button, Color("#1f5860") if str(spec[1]) != "TALK" else Color(MENU_STYLE.ACCENT, 0.94), Color("#8e4a38"), Color("#fffaf0"))
		button.add_theme_font_override("font", MENU_STYLE.BOLD)
		button.add_theme_font_size_override("font_size", 14)
		if spec[1] == "LEFT":
			button.button_down.connect(func(): touch_input.vector = Vector2(-1, 0))
			button.button_up.connect(func():
				if touch_input.vector.x < 0: touch_input.vector = Vector2.ZERO)
		elif spec[1] == "RIGHT":
			button.button_down.connect(func(): touch_input.vector = Vector2(1, 0))
			button.button_up.connect(func():
				if touch_input.vector.x > 0: touch_input.vector = Vector2.ZERO)
		elif spec[1] == "JUMP":
			button.pressed.connect(func(): touch_input.trigger_virtual_jump())
		else:
			button.pressed.connect(_request_touch_attack)
		controls.add_child(button)
	hud_root.add_child(controls)
func _rebuild_enemies() -> void:
	var requested := clampi(roundi(TuningStore.get_value("enemy_count")), 0, 22)
	if requested == configured_enemy_count:
		return
	configured_enemy_count = requested
	for child in get_children():
		if child.is_in_group("enemy"):
			child.queue_free()
	var spawned := 0
	if stage.enemies.is_empty(): return
	for index in 44:
		if spawned >= requested:
			break
		var spawn_position: Vector2 = _point(stage.enemies[index % stage.enemies.size()]) + Vector2(floori(float(index) / stage.enemies.size()) * 48, 0)
		# Rebuild population on slider changes, but never spawn directly on the cat.
		if is_instance_valid(player) and spawn_position.distance_to(player.position) < 110:
			continue
		var enemy = ENTITIES.Walker.new()
		enemy.position = spawn_position
		# The lead creditor pursues; the rest remain readable patrol hazards.
		enemy.chases_player = spawned == 0
		enemy.pursuit_bonus = stage_index * 22.0
		_stage_child(enemy)
		spawned += 1
