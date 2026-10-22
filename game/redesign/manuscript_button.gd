extends Button
## A real keyboard/mouse Button whose face is a painted miniature.
## Text remains on the Button for input tooling and accessibility.

const UI = preload("res://game/redesign/manuscript_theme.gd")
var artwork: Texture2D
var paint_layout: String = "tile"
var key_hint: String = ""
var badge: String = ""
var selected: bool = false
var empty_slot: bool = false
var ink: Color = Color("34291e")
var _last_face: String = ""

func _ready() -> void:
	clip_text = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state_name: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_focus_color"]:
		add_theme_color_override(state_name,Color(0,0,0,0))
	add_theme_stylebox_override("normal",UI.tile(selected))
	add_theme_stylebox_override("hover",UI.tile(true))
	add_theme_stylebox_override("pressed",UI.tile(true))
	add_theme_stylebox_override("disabled",UI.tile(false))
	add_theme_stylebox_override("focus",UI.flat(Color(0,0,0,0),Color("a65b30"),0))
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	var face: String = text+badge+str(selected)+str(disabled)+str(empty_slot)
	if face!=_last_face:
		_last_face=face
		add_theme_stylebox_override("normal",UI.tile(selected))
		queue_redraw()

func _fit(rect: Rect2, source: Texture2D) -> Rect2:
	var factor: float = minf(rect.size.x/source.get_width(),rect.size.y/source.get_height())
	var dimensions: Vector2 = source.get_size()*factor
	return Rect2(rect.get_center()-dimensions*0.5,dimensions)

func _text_line(value: String, area: Rect2, font: Font, font_size: int, color: Color) -> void:
	while font_size>11 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>area.size.x:
		font_size-=1
	var measured: Vector2 = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	var origin: Vector2 = Vector2(area.position.x+(area.size.x-measured.x)*0.5,area.position.y+(area.size.y-font.get_height(font_size))*0.5+font.get_ascent(font_size))
	draw_string(font,origin,value,HORIZONTAL_ALIGNMENT_LEFT,area.size.x,font_size,color)

func _draw() -> void:
	var font: Font = get_theme_font("font")
	var heading: Font = load("res://assets/cinzel.ttf")
	var font_size: int = get_theme_font_size("font_size")
	var color: Color = ink if not disabled else Color("806e52")
	var art_rect: Rect2
	var text_rect: Rect2
	var parts: PackedStringArray = text.split("\n")
	if paint_layout=="wide":
		var edge: float = minf(size.y-10,64)
		art_rect=Rect2(7,(size.y-edge)*0.5,edge,edge)
		text_rect=Rect2(edge+12,5,maxf(0,size.x-edge-20),size.y-10)
	elif paint_layout=="slot":
		art_rect=Rect2(4,3,size.x-8,size.y-(7 if text.is_empty() else 20))
		text_rect=Rect2(3,size.y-19,size.x-6,16)
		font_size=11
	else:
		var caption_height: float = 22 if parts.size()==1 else 37
		art_rect=Rect2(5,3,size.x-10,size.y-caption_height-5)
		text_rect=Rect2(4,size.y-caption_height-2,size.x-8,caption_height)
	if artwork!=null:
		draw_texture_rect(artwork,_fit(art_rect,artwork),false,Color(1,1,1,0.30 if empty_slot else (0.62 if disabled else 1.0)))
	if parts.size()==1:
		_text_line(text,text_rect,heading if paint_layout!="slot" else font,font_size,color)
	else:
		var first: Rect2 = Rect2(text_rect.position,Vector2(text_rect.size.x,text_rect.size.y*0.55))
		var second: Rect2 = Rect2(text_rect.position+Vector2(0,first.size.y),Vector2(text_rect.size.x,text_rect.size.y-first.size.y))
		_text_line(parts[0],first,heading,font_size,color)
		_text_line(parts[1],second,font,maxi(12,font_size-1),color.lightened(0.08))
	if selected:
		draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color("8a452e"),false,2)
		draw_line(Vector2(7,size.y-3),Vector2(size.x-7,size.y-3),Color("b58b44"),2)
	if not key_hint.is_empty():
		var key_rect: Rect2=Rect2(size.x-27,5,21,18)
		draw_rect(key_rect,Color("32434a"))
		draw_rect(key_rect,Color("ad905c"),false,1)
		_text_line(key_hint,key_rect,font,12,Color("ead8aa"))
	if not badge.is_empty():
		var badge_rect: Rect2=Rect2(6,5,18,18)
		draw_circle(badge_rect.get_center(),9,Color("527049") if badge=="✓" else Color("7a3c2f"))
		_text_line(badge,badge_rect,font,13,Color("f1e0b9"))
