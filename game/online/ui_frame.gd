extends Control
## Small original ironwork ornament. Geometry remains crisp at every UI scale.

const LEATHER=preload("res://assets/models/mara/materials/brown_leather_albedo_2k.jpg")
var fill := Color(0.055,0.059,0.050,0.97)
var edge := Color("9f8050")
var ornate := true
var inset := 3.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x<3.0 or size.y<3.0:return
	draw_rect(Rect2(Vector2(3,4),size),Color(0,0,0,0.36))
	# Layered brass bevel, dark forged recess, and a real CC0 leather inset.
	# This is the player's already-shipped material, not an unlicensed UI skin.
	draw_rect(Rect2(Vector2.ZERO,size),Color("17120d"))
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2.0),edge.darkened(0.24))
	draw_rect(Rect2(Vector2.ONE*3.0,size-Vector2.ONE*6.0),Color("27231a"))
	draw_rect(Rect2(Vector2.ONE*6.0,size-Vector2.ONE*12.0),fill)
	if size.x>22 and size.y>22:
		draw_texture_rect_region(LEATHER,Rect2(Vector2.ONE*7.0,size-Vector2.ONE*14.0),Rect2(Vector2(140,380),(size-Vector2.ONE*14.0)*2.4),Color(0.50,0.46,0.34,0.23))
	draw_rect(Rect2(Vector2.ONE*5.0,size-Vector2.ONE*10.0),Color(edge.darkened(0.16),0.6),false,1.0)
	draw_rect(Rect2(Vector2.ONE*7.0,size-Vector2.ONE*14.0),Color(0,0,0,0.6),false,1.0)
	draw_line(Vector2(3,1),Vector2(size.x-3,1),edge.lightened(0.35),1.0)
	draw_line(Vector2(1,3),Vector2(1,size.y-3),edge.lightened(0.12),1.0)
	draw_line(Vector2(4,size.y-2),Vector2(size.x-3,size.y-2),edge.darkened(0.55),2.0)
	draw_line(Vector2(size.x-2,3),Vector2(size.x-2,size.y-3),edge.darkened(0.48),2.0)
	for corner: Vector2 in [Vector2(7,7),Vector2(size.x-7,7),Vector2(7,size.y-7),Vector2(size.x-7,size.y-7)]:
		draw_circle(corner+Vector2(0,1),3.4,Color(0,0,0,0.85))
		draw_circle(corner,2.4,edge.darkened(0.08))
		draw_circle(corner-Vector2(0.5,0.8),1.1,edge.lightened(0.38))
		if ornate:
			var sx := 1.0 if corner.x<size.x*0.5 else -1.0
			var sy := 1.0 if corner.y<size.y*0.5 else -1.0
			_vine(corner,Vector2(sx,sy),minf(1.0,minf(size.x,size.y)/110.0))
	if ornate and size.x>180.0:
		for y: float in [3.0,size.y-4.0]:
			var c := Vector2(size.x*0.5,y)
			draw_colored_polygon(PackedVector2Array([c+Vector2(-11,0),c+Vector2(0,-4),c+Vector2(11,0),c+Vector2(0,5)]),edge.darkened(0.18))
			draw_colored_polygon(PackedVector2Array([c+Vector2(-5,0),c+Vector2(0,-2),c+Vector2(5,0),c+Vector2(0,3)]),edge.lightened(0.22))
			draw_line(c+Vector2(-50,0),c+Vector2(-16,0),Color(edge.lightened(0.22),0.6),1.0)
			draw_line(c+Vector2(16,0),c+Vector2(50,0),Color(edge.lightened(0.22),0.6),1.0)

func _vine(origin: Vector2, mirror: Vector2, scale: float) -> void:
	var points := PackedVector2Array()
	# Intertwined branch and leafwork, mirrored from an original corner motif.
	for point: Vector2 in [Vector2(1,31),Vector2(2,23),Vector2(5,16),Vector2(11,11),Vector2(19,9),Vector2(27,9),Vector2(30,6),Vector2(26,3),Vector2(21,5),Vector2(19,10),Vector2(21,15)]:
		points.append(origin+point*mirror*scale)
	draw_polyline(points,Color(0,0,0,0.7),3.3,true)
	draw_polyline(points,Color(edge,0.87),1.5,true)
	for data: Array in [[Vector2(7,15),Vector2(3,10),Vector2(5,4),Vector2(11,11)],[Vector2(14,10),Vector2(13,5),Vector2(17,1),Vector2(19,8)],[Vector2(5,22),Vector2(10,23),Vector2(15,20),Vector2(11,17)]]:
		var leaf := PackedVector2Array()
		for point: Vector2 in data:leaf.append(origin+point*mirror*scale)
		draw_colored_polygon(leaf,edge.darkened(0.36))
		leaf.append(leaf[0])
		draw_polyline(leaf,Color(edge.lightened(0.1),0.7),0.8,true)
