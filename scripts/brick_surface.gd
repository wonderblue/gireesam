extends Node2D
## Finish the outer edge while keeping texture joins and the walking surface flat.


const SURFACE_FINISH = preload("res://scripts/surface_finish.gd")
const SOURCE_RECT := Rect2(0, 0, 256, 256)
const TILE_SIZE := 168.0
const EDGE_RADIUS := 8.0
var surface_size := Vector2.ZERO


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	# Terracotta roof and market-plank route surfaces, intentionally unlike brick blocks.
	draw_rect(Rect2(Vector2.ZERO, surface_size), Color("#733f38"), true)
	draw_rect(Rect2(0, 0, surface_size.x, 8), Color("#e0a05a"), true)
	var rows := int(maxf(1.0, surface_size.y / 22.0))
	for row in rows:
		var y := 12.0 + row * 22.0
		draw_line(Vector2(0, y), Vector2(surface_size.x, y), Color("#9f5c45"), 2.0)
		var offset := 28.0 if row % 2 == 0 else 0.0
		for x in range(int(offset), int(surface_size.x), 56):
			draw_line(Vector2(x, y - 20.0), Vector2(x + 18.0, y), Color("#5c3534"), 2.0)
