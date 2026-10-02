extends Node

class Coin:
	extends Area2D
	const TEXTURE = preload("res://assets/template/cat/fish.webp")
	signal collected(position: Vector2)
	var consumed := false
	var t := 0.0
	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 14
		shape.shape = circle
		add_child(shape)
		body_entered.connect(_on_body)
		queue_redraw()
	func _process(delta: float) -> void:
		t += delta
		position.y += sin(t * 4.0) * 0.12
		queue_redraw()
	func _on_body(body: Node) -> void:
		if body.is_in_group("player") and body.alive and not consumed:
			consumed = true
			collected.emit(global_position)
			queue_free()
	const COIN_FONT = preload("res://assets/template/fonts/ui_bold.tres")
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, sin(t * 3.0) * 0.06)
		draw_circle(Vector2.ZERO, 22.0, Color("#f6c453"))
		draw_circle(Vector2.ZERO, 17.0, Color("#d9922e"))
		draw_circle(Vector2.ZERO, 13.0, Color("#f8d56a"))
		draw_arc(Vector2.ZERO, 18.0, 0.2, 5.7, 24, Color("#fff0a8"), 2.0)
		draw_string(COIN_FONT, Vector2(-9, 7), "RF", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#7a431c"))
		draw_set_transform(Vector2.ZERO, 0.0)

class Distraction:
	extends Area2D
	signal attracted(kind: String, position: Vector2)
	var kind := "SNACK"
	var label := "BAJJI"
	var t := 0.0
	var consumed := false
	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 32.0
		shape.shape = circle
		add_child(shape)
		body_entered.connect(_on_body)
		queue_redraw()
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _on_body(body: Node) -> void:
		if body.is_in_group("player") and bool(body.get("alive")) and not consumed:
			consumed = true
			attracted.emit(kind, global_position)
			queue_free()
	func _draw() -> void:
		var bob := sin(t * 3.0) * 3.0
		if kind == "SNACK":
			draw_circle(Vector2(0, bob), 20.0, Color("#d47a32"))
			draw_circle(Vector2(-7, bob - 2), 9.0, Color("#f3c15e"))
			draw_circle(Vector2(7, bob - 2), 9.0, Color("#f3c15e"))
		elif kind == "CIGARETTE":
			draw_rect(Rect2(-18, bob - 5, 36, 10), Color("#f5e5b9"), true)
			draw_rect(Rect2(13, bob - 5, 6, 10), Color("#d85b38"), true)
			draw_line(Vector2(0, bob - 9), Vector2(5, bob - 20), Color(0.85, 0.85, 0.82, 0.55), 2.0)
		else:
			draw_rect(Rect2(-21, bob - 16, 42, 32), Color("#1f5860"), true)
			draw_rect(Rect2(-16, bob - 11, 32, 22), Color("#f6d58c"), true)
		draw_string(load("res://assets/template/fonts/ui_bold.tres"), Vector2(-13, bob + 5), "LECTURE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#7d3540"))
		draw_string(load("res://assets/template/fonts/ui_bold.tres"), Vector2(-30, -31 + bob), label, HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color("#fff1c7"))
class Walker:
	extends CharacterBody2D
	const TEXTURE = preload("res://assets/gireesam/creditor_chaser.png")
	const SPRITE_GROUNDING = preload("res://scripts/sprite_grounding.gd")
	var sprite_grounding := SPRITE_GROUNDING.new()
	const HITBOX_SIZE := Vector2(52, 26)
	const HITBOX_OFFSET := Vector2(0, 6)
	const SPRITE_SIZE := 124.0
	var sprite_texture: Texture2D = TEXTURE:
		set(value):
			sprite_texture = value
			_update_sprite_region()
			queue_redraw()
	var sprite_region := Rect2()
	var visual_scale := Vector2.ONE:
		set(value):
			visual_scale = value
			queue_redraw()
	var alive := true
	var chases_player := false
	var pursuit_bonus := 0.0
	var t := 0.0
	var direction := -1.0
	var floor_probe: RayCast2D
	func _ready() -> void:
		add_to_group("enemy")
		_update_sprite_region()
		collision_layer = 4
		# The player owns contact damage and stomps; never judge its post-bounce velocity here.
		collision_mask = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = HITBOX_SIZE
		shape.shape = rect
		shape.position = HITBOX_OFFSET
		add_child(shape)
		floor_probe = RayCast2D.new()
		floor_probe.collision_mask = 1
		floor_probe.enabled = true
		floor_probe.target_position = Vector2(direction * 32.0, 42.0)
		add_child(floor_probe)
		velocity.x = direction * TuningStore.get_value("enemy_speed")
		queue_redraw()
	func _physics_process(delta: float) -> void:
		if not alive:
			return
		t += delta
		var target := get_tree().get_first_node_in_group("player")
		if chases_player and target != null and bool(target.get("alive")) and absf(target.global_position.x - global_position.x) < 1400.0:
			direction = signf(target.global_position.x - global_position.x) if absf(target.global_position.x - global_position.x) > 18.0 else direction
		velocity.x = direction * (TuningStore.get_value("enemy_speed") + 16.0 + pursuit_bonus)
		if not is_on_floor():
			velocity.y += TuningStore.get_value("enemy_gravity") * delta
		else:
			floor_probe.target_position.x = direction * 32.0
			floor_probe.force_raycast_update()
			if not floor_probe.is_colliding():
				direction *= -1.0
				velocity.x = direction * TuningStore.get_value("enemy_speed")
		move_and_slide()
		if is_on_wall():
			direction *= -1.0
		if global_position.y > 900.0:
			queue_free()
		queue_redraw()
	func stomp_top_y() -> float:
		return global_position.y + HITBOX_OFFSET.y - HITBOX_SIZE.y * 0.5
	func stomp() -> void:
		if not alive:
			return
		alive = false
		collision_layer = 0
		collision_mask = 0
		var tween := create_tween()
		# Squash artwork about its feet; scaling the body origin would lift it.
		tween.tween_property(self, "visual_scale", Vector2(1.25, 0.2), 0.12)
		tween.tween_interval(0.18)
		tween.tween_callback(queue_free)
	func _draw() -> void:
		if sprite_texture != null and sprite_region.has_area():
			var canvas: Rect2 = sprite_grounding.canvas_rect(sprite_texture, sprite_pixel_scale(), HITBOX_OFFSET.y + HITBOX_SIZE.y * 0.5)
			draw_texture_rect(sprite_texture, canvas, false)
	func sprite_pixel_scale() -> Vector2:
		if sprite_texture == null:
			return Vector2.ONE
		var canvas_size := sprite_texture.get_size()
		var canvas_scale := SPRITE_SIZE / maxf(canvas_size.x, canvas_size.y)
		return Vector2.ONE * canvas_scale * visual_scale * Vector2(1.0, 1.0 + sin(t * 12.0) * 0.025 if alive else 1.0)
	func sprite_draw_rect() -> Rect2:
		return sprite_grounding.visible_rect(sprite_texture, sprite_pixel_scale(), HITBOX_OFFSET.y + HITBOX_SIZE.y * 0.5)
	func _update_sprite_region() -> void:
		sprite_region = sprite_grounding.alpha_region(sprite_texture)

class QuestionBlock:
	extends StaticBody2D
	const TEXTURE = preload("res://assets/template/cat/felt-special-block.webp")
	const SURFACE_FINISH = preload("res://scripts/surface_finish.gd")
	const EDGE_RADIUS := 8.0
	signal activated(position: Vector2)
	var active := true
	var bump_offset := 0.0:
		set(value):
			bump_offset = value
			queue_redraw()
	func _ready() -> void:
		add_to_group("question_block")
		collision_layer = 1
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(52, 52)
		shape.shape = rect
		add_child(shape)
		queue_redraw()
	func activate() -> void:
		if not active:
			return
		active = false
		activated.emit(global_position - Vector2(0, 54))
		var tween := create_tween()
		# Keep the StaticBody2D stationary: its return stroke must not squeeze
		# a player between the block and the supporting platform.
		tween.tween_property(self, "bump_offset", -10.0, 0.08)
		tween.tween_property(self, "bump_offset", 0.0, 0.1)
		queue_redraw()
	func _draw() -> void:
		draw_set_transform(Vector2(0, bump_offset))
		var wood := Color("#8b4d32") if active else Color("#51413b")
		var paper := Color("#f6d58c") if active else Color("#76645b")
		draw_rect(Rect2(-27, -24, 54, 48), wood, true)
		draw_rect(Rect2(-21, -17, 42, 34), paper, true)
		draw_line(Vector2(-16, -8), Vector2(16, -8), Color("#6d3b2a"), 2.0)
		draw_line(Vector2(-16, 0), Vector2(12, 0), Color("#6d3b2a"), 2.0)
		draw_line(Vector2(-16, 8), Vector2(5, 8), Color("#6d3b2a"), 2.0)
		draw_string(load("res://assets/template/fonts/ui_bold.tres"), Vector2(-8, -29), "LEDGER", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#f5dfad"))

class GoalFlag:
	extends Area2D
	signal reached
	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(70, 300)
		shape.shape = rect
		shape.position = Vector2(0, -120)
		add_child(shape)
		body_entered.connect(_on_body)
		queue_redraw()
	func _on_body(body: Node) -> void:
		if body.is_in_group("player") and body.alive:
			reached.emit()
	func _draw() -> void:
		# A safe-house doorway and striped awning replace the generic finish flag.
		draw_rect(Rect2(-42, -184, 84, 184), Color("#3c2630"), true)
		draw_rect(Rect2(-31, -162, 62, 162), Color("#183b45"), true)
		draw_rect(Rect2(-25, -154, 50, 154), Color("#f1c36f"), true)
		for x in [-22, -7, 8, 23]:
			draw_rect(Rect2(x, -184, 11, 22), Color("#a74436" if int(x) % 2 == 0 else "#f1c36f"), true)
		draw_rect(Rect2(-58, -207, 116, 20), Color("#1f5860"), true)
		draw_string(load("res://assets/template/fonts/ui_bold.tres"), Vector2(-45, -218), "SAFE HOUSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff1c7"))
