class_name ManuscriptFrame
extends StyleBox
## Painted manuscript surfaces around live native controls. Border artwork is
## assembled from quiet edge spans and fixed corners; the crest never stretches.

var mode: String = "folio"
var fill: Color = Color("eddfbd")
var edge: Color = Color("8a5c22")
var bright: Color = Color("d0b47b")
var texture: Texture2D
var artwork_border: bool = false
var active: bool = false
var inset: bool = false
var ornaments: bool = true
var show_crest: bool = false

func _get_minimum_size() -> Vector2:
	return Vector2(8, 8)

func _line(item: RID, a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	RenderingServer.canvas_item_add_line(item, a, b, color, width, true)

func _outline(item: RID, area: Rect2, color: Color, width: float = 1.0) -> void:
	if area.size.x <= 0 or area.size.y <= 0:
		return
	_line(item, area.position, Vector2(area.end.x, area.position.y), color, width)
	_line(item, Vector2(area.end.x, area.position.y), area.end, color, width)
	_line(item, area.end, Vector2(area.position.x, area.end.y), color, width)
	_line(item, Vector2(area.position.x, area.end.y), area.position, color, width)

func _crop(item: RID, target: Rect2, source: Rect2, tint: Color = Color.WHITE) -> void:
	if texture != null and target.size.x > 0 and target.size.y > 0:
		texture.draw_rect_region(item, target, source, tint)

func _band(item: RID, target: Rect2, source: Rect2, horizontal: bool) -> void:
	if target.size.x <= 0 or target.size.y <= 0:
		return
	var scale: float = target.size.y/source.size.y if horizontal else target.size.x/source.size.x
	var length: float = source.size.x*scale if horizontal else source.size.y*scale
	var remaining: float = target.size.x if horizontal else target.size.y
	var offset: float = 0.0
	while remaining > 0.01:
		var amount: float = minf(length,remaining)
		var destination: Rect2 = Rect2(target.position+Vector2(offset,0),Vector2(amount,target.size.y)) if horizontal else Rect2(target.position+Vector2(0,offset),Vector2(target.size.x,amount))
		var crop: Rect2 = Rect2(source.position,Vector2(amount/scale,source.size.y)) if horizontal else Rect2(source.position,Vector2(source.size.x,amount/scale))
		_crop(item,destination,crop)
		offset += amount
		remaining -= amount

func _vellum(item: RID, area: Rect2, dark: bool = false) -> void:
	RenderingServer.canvas_item_add_rect(item, area, fill)
	if texture == null:
		return
	var source: Rect2 = Rect2(270, 260, 996, 500) if artwork_border else Rect2(texture.get_size()*0.2, texture.get_size()*0.6)
	var tint: Color = Color(fill.r, fill.g, fill.b, 0.25) if dark else Color(1.0, 1.0, 1.0, 0.78)
	_crop(item, area, source, tint)

func _folio(item: RID, area: Rect2) -> void:
	_vellum(item, area)
	if not ornaments or area.size.x < 96 or area.size.y < 70:
		_outline(item, area.grow(-1.5), Color("927648"))
		return
	if not artwork_border:
		_outline(item, area.grow(-1.5), Color("5b442b"))
		_outline(item, area.grow(-4.5), Color("ab8b52"))
		_line(item, area.position+Vector2(7,7), Vector2(area.end.x-7,area.position.y+7), Color("783e30"), 2.0)
		return
	# At most 44 px of corner art: enough character without putting leaves under
	# body text. Smaller requested padding produces correspondingly quiet corners.
	var padding: float = minf(get_content_margin(SIDE_LEFT), get_content_margin(SIDE_TOP))
	var corner_w: float = minf(44.0, maxf(20.0, padding*1.3))
	corner_w = minf(corner_w, minf(area.size.x*0.24, area.size.y*0.24))
	var scale: float = corner_w/220.0
	var corner_h: float = 204.0*scale
	var band_h: float = 72.0*scale
	var band_w: float = 62.0*scale
	# Quiet source spans exclude the crest. Repetition preserves the small gilt
	# motifs' proportions rather than stretching them with a wide panel.
	_band(item, Rect2(area.position+Vector2(corner_w,0),Vector2(area.size.x-2*corner_w,band_h)), Rect2(260,28,320,72),true)
	_band(item, Rect2(Vector2(area.position.x+corner_w,area.end.y-band_h),Vector2(area.size.x-2*corner_w,band_h)), Rect2(260,924,320,72),true)
	_band(item, Rect2(area.position+Vector2(0,corner_h),Vector2(band_w,area.size.y-2*corner_h)), Rect2(16,260,62,440),false)
	_band(item, Rect2(Vector2(area.end.x-band_w,area.position.y+corner_h),Vector2(band_w,area.size.y-2*corner_h)), Rect2(1458,260,62,440),false)
	_crop(item, Rect2(area.position,Vector2(corner_w,corner_h)), Rect2(16,28,220,204))
	_crop(item, Rect2(Vector2(area.end.x-corner_w,area.position.y),Vector2(corner_w,corner_h)), Rect2(1300,28,220,204))
	_crop(item, Rect2(Vector2(area.position.x,area.end.y-corner_h),Vector2(corner_w,corner_h)), Rect2(16,792,220,204))
	_crop(item, Rect2(area.end-Vector2(corner_w,corner_h),Vector2(corner_w,corner_h)), Rect2(1300,792,220,204))
	if show_crest and area.size.x >= 440 and area.size.y >= 240:
		var crest_size: Vector2 = Vector2(84,84*225.0/235.0)
		_crop(item, Rect2(Vector2(area.get_center().x-crest_size.x/2.0,area.position.y),crest_size), Rect2(654,0,235,225))

func _dark_frame(item: RID, area: Rect2) -> void:
	_vellum(item, area, true)
	# A narrow bronze rim; the page itself carries the illustration and detail.
	_outline(item, area.grow(-0.5), Color("201b17"), 1.0)
	_outline(item, area.grow(-1.5), edge, 1.0)
	_line(item, area.position+Vector2(3,3), Vector2(area.end.x-3,area.position.y+3), bright.darkened(0.35) if inset else bright, 1.0)
	_line(item, Vector2(area.position.x+3,area.end.y-3), area.end-Vector2(3,3), Color("1d211e") if not inset else bright.darkened(0.2), 1.0)
	if mode == "chrome":
		_chrome_inlay(item, area)
	elif active:
		_line(item, Vector2(area.position.x+10,area.end.y-5), area.end-Vector2(10,5), Color("e3c38c"), 1.0)

func _chrome_inlay(item: RID, area: Rect2) -> void:
	# The binding repeats the folio's painted bands. Keep every ornament inside
	# the caller's reserved margin, including the narrow frame around a viewport.
	var padding: float = minf(minf(get_content_margin(SIDE_LEFT),get_content_margin(SIDE_RIGHT)),minf(get_content_margin(SIDE_TOP),get_content_margin(SIDE_BOTTOM)))
	var band: float = minf(7.0,maxf(0.0,padding-3.0))
	if not ornaments or band < 2.0 or not artwork_border:
		_line(item,area.position+Vector2(5,5),Vector2(area.end.x-5,area.position.y+5),Color("784436"),2.0)
		return
	var inset_area: Rect2 = area.grow(-2.0)
	var corner: float = band+1.0
	_band(item,Rect2(inset_area.position+Vector2(corner,0),Vector2(inset_area.size.x-2.0*corner,band)),Rect2(260,32,320,64),true)
	_band(item,Rect2(Vector2(inset_area.position.x+corner,inset_area.end.y-band),Vector2(inset_area.size.x-2.0*corner,band)),Rect2(260,932,320,54),true)
	var side_width: float = minf(4.0,band)
	_band(item,Rect2(inset_area.position+Vector2(0,corner),Vector2(side_width,inset_area.size.y-2.0*corner)),Rect2(20,260,54,440),false)
	_band(item,Rect2(Vector2(inset_area.end.x-side_width,inset_area.position.y+corner),Vector2(side_width,inset_area.size.y-2.0*corner)),Rect2(1462,260,54,440),false)
	# Small brass corner joins, rather than a second heavy illustrated border.
	for point: Vector2 in [inset_area.position+Vector2(corner*0.5,corner*0.5),Vector2(inset_area.end.x-corner*0.5,inset_area.position.y+corner*0.5),inset_area.end-Vector2(corner*0.5,corner*0.5),Vector2(inset_area.position.x+corner*0.5,inset_area.end.y-corner*0.5)]:
		var half: float = minf(2.5,corner*0.35)
		var mount: Rect2 = Rect2(point-Vector2(half,half),Vector2(half*2.0,half*2.0))
		RenderingServer.canvas_item_add_rect(item,mount,Color("97713b"))
		_outline(item,mount,Color("352a1e"),1.0)
		_line(item,mount.position+Vector2(1,1),Vector2(mount.end.x-1,mount.position.y+1),Color("e0bf83"),1.0)

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	if mode == "folio":
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(rect.position+Vector2(1,2),rect.size), Color(0.07,0.055,0.04,0.22))
		_folio(to_canvas_item, rect)
	elif mode in ["chrome", "command"]:
		_dark_frame(to_canvas_item, rect)
	else:
		_vellum(to_canvas_item, rect)
		var rule: Color = Color("ac9568") if mode == "paper" else Color("8e7548")
		_outline(to_canvas_item, rect.grow(-0.5), rule, 1.0)
		if active:
			_outline(to_canvas_item, rect.grow(-2.5), Color("94502f"), 1.0)
			_line(to_canvas_item, rect.position+Vector2(5,5), Vector2(rect.end.x-5,rect.position.y+5), Color("7b332b"), 2.0)
