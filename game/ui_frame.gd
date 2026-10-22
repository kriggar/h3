class_name DraconiaFrame
extends StyleBox
## A tactile, beveled frame rendered by Godot around live controls.

var fill: Color = Color("27241d")
var edge: Color = Color("927043")
var bright: Color = Color("c2a76a")
var texture: Texture2D
var active: bool = false
var inset: bool = false
var ornaments: bool = true

func _get_minimum_size() -> Vector2:
	return Vector2(12, 12)

func _line(item: RID, a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	RenderingServer.canvas_item_add_line(item, a, b, color, width, true)

func _outline(item: RID, area: Rect2, color: Color, width: float = 1.0) -> void:
	_line(item, area.position, Vector2(area.end.x, area.position.y), color, width)
	_line(item, Vector2(area.end.x, area.position.y), area.end, color, width)
	_line(item, area.end, Vector2(area.position.x, area.end.y), color, width)
	_line(item, Vector2(area.position.x, area.end.y), area.position, color, width)

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect.grow(1), Color(0.02, 0.025, 0.018, 0.95))
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect.grow(-2), fill)
	if texture != null:
		texture.draw_rect(to_canvas_item, rect.grow(-3), false, Color(1.05, 1.0, 0.9, 0.8) if active else Color(0.85, 0.88, 0.82, 0.8))
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect.grow(-6), Color(0.035, 0.05, 0.04, 0.34 if active else 0.52))
	_outline(to_canvas_item, rect.grow(-2.5), Color("241c14"), 4.0)
	_outline(to_canvas_item, rect.grow(-3.5), edge, 2.0)
	var bevel: Rect2 = rect.grow(-5.0)
	_line(to_canvas_item, bevel.position, Vector2(bevel.end.x, bevel.position.y), Color("3d2d1e") if inset else bright)
	_line(to_canvas_item, bevel.position, Vector2(bevel.position.x, bevel.end.y), Color("3d2d1e") if inset else bright.darkened(0.15))
	_line(to_canvas_item, Vector2(bevel.position.x, bevel.end.y), bevel.end, bright if inset else Color("100f0c"), 2.0)
	_line(to_canvas_item, Vector2(bevel.end.x, bevel.position.y), bevel.end, bright if inset else Color("100f0c"), 2.0)
	_outline(to_canvas_item, rect.grow(-8.0), Color(0.55, 0.43, 0.25, 0.4))
	if ornaments and rect.size.x > 64 and rect.size.y > 40:
		for corner: Vector2 in [rect.position + Vector2(8, 8), Vector2(rect.end.x - 8, rect.position.y + 8), rect.end - Vector2(8, 8), Vector2(rect.position.x + 8, rect.end.y - 8)]:
			RenderingServer.canvas_item_add_circle(to_canvas_item, corner, 3.1, Color("17130f"), true)
			RenderingServer.canvas_item_add_circle(to_canvas_item, corner - Vector2(0.4, 0.5), 1.7, bright, true)
