extends Control
## Screen-space combat information projected from the native 3D arena.

const Guidance = preload("res://game/redesign/expedition_chart.gd")

var stage: Node3D
var _floaters: Array = []
var _font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load("res://assets/ebgaramond.ttf")

func show_events(events: Array) -> void:
	for event: Dictionary in events:
		if str(event.type) == "damage" and int(event.amount) > 0:
			_floaters.append({"pos":event.pos.duplicate(),"amount":str(event.amount),"life":0.9,"hero":str(event.actorId)==str(stage.action_state.heroId)})

func _process(delta: float) -> void:
	for index: int in range(_floaters.size()-1,-1,-1):
		_floaters[index].life = float(_floaters[index].life)-delta
		if float(_floaters[index].life)<=0:
			_floaters.remove_at(index)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(stage) or stage.camera == null or stage.action_state.is_empty():
		return
	var state: Dictionary = stage.action_state
	var target: Dictionary = Guidance.target_summary(state)
	var destination: Array = Guidance.movement_destination(state)
	if not destination.is_empty():
		_ground_ring(destination,0.38,Color("ead6a4"),1.6)
		var destination_screen: Vector2=stage.camera.unproject_position(Vector3(float(destination[0]),0.06,float(destination[1])))
		draw_circle(destination_screen,2.2,Color("ead6a4"))
	if state.arena.has("exit"):
		var exit_pos: Array=state.arena.exit
		var exit_screen: Vector2=stage.camera.unproject_position(Vector3(float(exit_pos[0]),0.15,float(exit_pos[1])))
		_world_tag(exit_screen+Vector2(0,19),"Entrance",Color("dce2bc"))
	for actor: Dictionary in state.actors:
		if int(actor.hp)<=0:
			continue
		var height: float = 2.0 if bool(actor.isHero) else (2.8 if str(actor.id)=="crypt_alpha" else 2.3)
		var pos: Vector2 = stage.camera.unproject_position(Vector3(float(actor.pos[0]),height,float(actor.pos[1])))
		var width: float = 58 if bool(actor.isHero) else 48
		var rect: Rect2 = Rect2(pos-Vector2(width*0.5,5),Vector2(width,5))
		draw_rect(rect.grow(1),Color("171a16"))
		draw_rect(rect,Color("493830"))
		draw_rect(Rect2(rect.position,Vector2(width*float(actor.hp)/maxf(1,float(actor.maxHp)),5)),Color("80905b") if bool(actor.isHero) else Color("a95240"))
		if not target.is_empty() and str(actor.id)==str(target.id):
			_ground_ring(actor.pos,float(actor.radius)+0.32,Color("edcf85"),2.0)
			_world_tag(pos+Vector2(0,-27),str(target.role),Color("f2dda9"))
		elif str(actor.id)=="crypt_alpha":
			draw_string(_font,pos+Vector2(-45,-13),"Vaultfang",HORIZONTAL_ALIGNMENT_CENTER,90,17,Color("e2ca98"))
	for loot: Dictionary in state.loot:
		if bool(loot.claimed):
			continue
		var hero: Dictionary = state.actors[0]
		if Vector2(float(hero.pos[0]),float(hero.pos[1])).distance_to(Vector2(float(loot.pos[0]),float(loot.pos[1])))<4:
			var pos: Vector2 = stage.camera.unproject_position(Vector3(float(loot.pos[0]),0.7,float(loot.pos[1])))
			var count: int = 0
			for other: Dictionary in state.loot:
				if not bool(other.claimed) and Vector2(float(other.pos[0]),float(other.pos[1])).is_equal_approx(Vector2(float(loot.pos[0]),float(loot.pos[1]))):
					count+=1
			draw_string(_font,pos+Vector2(-78,18),"Unclaimed spoils" if count==1 else "%d unclaimed rewards" % count,HORIZONTAL_ALIGNMENT_CENTER,156,18,Color("e3d1a2"))
			break
	for floater: Dictionary in _floaters:
		var pos: Vector2 = stage.camera.unproject_position(Vector3(float(floater.pos[0]),2.0,float(floater.pos[1])))
		pos.y -= (0.9-float(floater.life))*45
		var color: Color = Color("ffad8d") if bool(floater.hero) else Color("f4e4b5")
		color.a = minf(1,float(floater.life)*2)
		draw_string(_font,pos+Vector2(-20,0),str(floater.amount),HORIZONTAL_ALIGNMENT_CENTER,40,22,color)

func _ground_ring(position: Array, radius: float, color: Color, width: float) -> void:
	var points: PackedVector2Array=PackedVector2Array()
	for index: int in range(33):
		var angle: float=TAU*float(index)/32.0
		points.append(stage.camera.unproject_position(Vector3(float(position[0])+cos(angle)*radius,0.06,float(position[1])+sin(angle)*radius)))
	draw_polyline(points,color,width,true)

func _world_tag(position: Vector2, text_value: String, color: Color) -> void:
	var width: float=124.0
	var rect: Rect2=Rect2(position+Vector2(-width*0.5,-2),Vector2(width,22))
	draw_rect(rect,Color(0.11,0.14,0.12,0.9))
	draw_rect(rect,Color("aa8c58"),false,1.0)
	draw_string(_font,position+Vector2(-width*0.5,15),text_value,HORIZONTAL_ALIGNMENT_CENTER,width,15,color)
