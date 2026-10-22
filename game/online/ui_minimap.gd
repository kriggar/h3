extends Control
## North-up, live positional map: markers are driven by the server snapshot.

const Catalog=preload("res://game/online/catalog.gd")
var state: Dictionary={}
var player_id := 1
var target_id := ""
var font: Font
var map_radius := 40.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font
	resized.connect(queue_redraw)

func update_state(value: Dictionary, id: int, target: String) -> void:
	state=value
	player_id=id
	target_id=target
	queue_redraw()

func _draw() -> void:
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.5-10.0
	if radius<=0:return
	draw_circle(center+Vector2(0,3),radius+5.0,Color(0,0,0,0.5))
	draw_circle(center,radius+4.0,Color("332d23"))
	draw_circle(center,radius+2.0,Color("9d8250"))
	draw_circle(center,radius,Color("161f1d"))
	for r: float in [radius*0.3,radius*0.6,radius*0.9]:draw_arc(center,r,0,TAU,64,Color(0.4,0.5,0.36,0.09),1.0,true)
	var players: Dictionary=state.get("players",{})
	var player: Dictionary=players.get(str(player_id),{})
	var position: Vector3=Catalog.vector(player.get("pos",[0,0,28]))
	# Road and authored footprints, clipped to the circular chart.
	for z: int in range(-96,96,2):
		var road := Vector3(sin(float(z)*0.04)*2.0,0,z)
		var point := _point(road,position,center,radius)
		if point.distance_to(center)<radius-5.0:draw_circle(point,3.0,Color("81795a"))
	for b: Dictionary in Catalog.BUILDINGS:
		var point := _point(Catalog.vector(b.pos),position,center,radius)
		if point.distance_to(center)<radius-10.0:
			var footprint := Vector2(float(b.size[0]),float(b.size[1]))*radius/map_radius
			draw_rect(Rect2(point-footprint*0.5,footprint),Color("625a46"))
			draw_rect(Rect2(point-footprint*0.5,footprint),Color("948062"),false,1.0)
	for n: Dictionary in Catalog.NPCS:
		var point := _point(Catalog.vector(n.pos),position,center,radius)
		if point.distance_to(center)<radius-7.0:
			var color := Color("f1cd77") if str(n.role)=="quests" else Color("88b7ca")
			draw_colored_polygon(_diamond(point,3.7),color)
	for e: Dictionary in state.get("enemies",{}).values():
		if bool(e.get("dead",false)):continue
		var point := _point(Catalog.vector(e.get("pos",[])),position,center,radius)
		if point.distance_to(center)<radius-6.0:
			if str(e.get("id",""))==target_id:draw_arc(point,6,0,TAU,20,Color("efd18f"),1.5,true)
			draw_circle(point,2.5,Color("bd6654"))
	for g: Dictionary in state.get("gathers",{}).values():
		if not bool(g.get("available",true)):continue
		var point := _point(Catalog.vector(g.get("pos",[])),position,center,radius)
		if point.distance_to(center)<radius-5.0:draw_circle(point,2.0,Color("c4ad6f"))
	for p: Dictionary in players.values():
		if int(p.get("id",0))==player_id:continue
		var point := _point(Catalog.vector(p.get("pos",[])),position,center,radius)
		if point.distance_to(center)<radius-6.0:draw_circle(point,3.0,Color("7ec8dc"))
	var yaw := float(player.get("yaw",PI))
	var direction := Vector2(sin(yaw),cos(yaw))
	var right := Vector2(direction.y,-direction.x)
	draw_colored_polygon(PackedVector2Array([center+direction*7.0,center-direction*4.0+right*4.0,center-direction*1.7,center-direction*4.0-right*4.0]),Color("f4df9c"))
	for i: int in range(32):
		var direction_tick := Vector2(sin(float(i)*TAU/32.0),cos(float(i)*TAU/32.0))
		var length_tick := 5.0 if i%8==0 else 2.0
		draw_line(center+direction_tick*(radius+1.0),center+direction_tick*(radius+1.0-length_tick),Color("b39a61"),1.0,true)
	draw_string(font,center+Vector2(-4,-radius+13),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f1d495"))

func _point(world: Vector3, origin: Vector3, center: Vector2, radius: float) -> Vector2:
	return center+Vector2(world.x-origin.x,world.z-origin.z)*radius/map_radius

func _diamond(point: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([point+Vector2(0,-radius),point+Vector2(radius,0),point+Vector2(0,radius),point+Vector2(-radius,0)])
