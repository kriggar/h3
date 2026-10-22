class_name ManuscriptTheme
extends RefCounted
## Native manuscript controls: ink on vellum, illustrated outer folios, and
## restrained oxblood/slate commands. The legacy DraconiaTheme is untouched.

const Frame = preload("res://game/redesign/manuscript_frame.gd")
const INK: Color = Color("34291e")
const MUTED: Color = Color("736044")
const GOLD: Color = Color("8a5c22")
const CREAM: Color = Color("eddfbd")
const DARK: Color = Color("253537")
const IVORY: Color = Color("f3e6c7")
const OXBLOOD: Color = Color("652c29")
const SLATE: Color = Color("34494d")
const FOLIO_PATH: String = "res://assets/ui/manuscript/folio.png"
const FALLBACK_PATH: String = "res://assets/generated/parchment.png"

static var _textures: Dictionary = {}
static var _empty_icon: Texture2D

static func _texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var result: Texture2D
	if ResourceLoader.exists(path):
		result = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		# Lets an editor preview newly delivered art before its next import pass.
		var pixels: Image = Image.load_from_file(path)
		if pixels != null and not pixels.is_empty():
			result = ImageTexture.create_from_image(pixels)
	if result != null:
		_textures[path] = result
	return result

static func _frame(kind: String, margin: int) -> Frame:
	var result: Frame = Frame.new()
	result.mode = kind
	result.texture = _texture(FOLIO_PATH)
	result.artwork_border = result.texture != null
	if result.texture == null:
		result.texture = _texture(FALLBACK_PATH)
	result.set_content_margin_all(maxi(0, margin))
	return result

static func flat(color: Color, border: Color = Color("a18b62"), margin: int = 12) -> StyleBoxFlat:
	var result: StyleBoxFlat = StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_content_margin_all(maxi(0, margin))
	return result

static func parchment(margin: int = 22) -> StyleBox:
	return _frame("folio", maxi(14, margin))

static func paper(margin: int = 18) -> StyleBox:
	var result: Frame = _frame("paper", margin)
	result.ornaments = false
	return result

static func chrome(margin: int = 12) -> StyleBox:
	var result: Frame = _frame("chrome", margin)
	result.fill = DARK
	result.edge = Color("8d6b3c")
	result.bright = Color("c2a270")
	result.ornaments = true
	return result

static func tile(active: bool = false) -> StyleBox:
	var result: Frame = _frame("tile", 8)
	result.active = active
	result.fill = Color("f1e4c5") if active else CREAM
	result.ornaments = false
	return result

static func command(active: bool = false, pressed: bool = false) -> StyleBox:
	var result: Frame = _frame("command", 10)
	result.active = active
	result.inset = pressed
	result.ornaments = false
	result.fill = Color("6c4529") if pressed else Color("8a5b31") if active else OXBLOOD
	result.edge = Color("c8a76e") if active else Color("a27c46")
	result.bright = Color("e0bf83") if active else Color("bb925e")
	return result

static func _blank_icon() -> Texture2D:
	if _empty_icon == null:
		var pixels: Image = Image.create(1,1,false,Image.FORMAT_RGBA8)
		pixels.fill(Color.TRANSPARENT)
		_empty_icon = ImageTexture.create_from_image(pixels)
	return _empty_icon

static func _scroll_style(color: Color, border: Color, width: int = 3) -> StyleBoxFlat:
	var result: StyleBoxFlat = flat(color,border,0)
	result.set_content_margin_all(width)
	return result

static func make_theme() -> Theme:
	var result: Theme = Theme.new()
	result.default_font_size = 20
	if ResourceLoader.exists("res://assets/ebgaramond.ttf"):
		result.default_font = load("res://assets/ebgaramond.ttf")
	result.set_color("font_color", "Label", INK)
	result.set_color("font_shadow_color", "Label", Color.TRANSPARENT)
	result.set_color("default_color", "RichTextLabel", INK)
	result.set_color("font_color", "TooltipLabel", INK)
	result.set_constant("separation", "VBoxContainer", 9)
	result.set_constant("separation", "HBoxContainer", 10)
	result.set_stylebox("panel", "PanelContainer", parchment())
	result.set_stylebox("panel", "Panel", parchment())
	var disabled: Frame = _frame("command",10)
	disabled.fill = Color("686657")
	disabled.edge = Color("8e8265")
	disabled.bright = Color("a89d80")
	disabled.inset = true
	for type_name: String in ["Button", "OptionButton"]:
		result.set_stylebox("normal", type_name, command())
		result.set_stylebox("hover", type_name, command(true))
		result.set_stylebox("pressed", type_name, command(true,true))
		result.set_stylebox("hover_pressed", type_name, command(true,true))
		result.set_stylebox("disabled", type_name, disabled)
		result.set_stylebox("focus", type_name, flat(Color.TRANSPARENT,Color("e0bd77"),0))
		result.set_color("font_color", type_name, IVORY)
		result.set_color("font_hover_color", type_name, Color("fff3d5"))
		result.set_color("font_pressed_color", type_name, IVORY)
		result.set_color("font_disabled_color", type_name, Color("d9cfb4"))
		result.set_color("font_focus_color", type_name, IVORY)
		result.set_color("font_outline_color", type_name, Color("352019"))
		result.set_constant("outline_size", type_name, 0)
		result.set_font_size("font_size", type_name, 18)
		if ResourceLoader.exists("res://assets/cinzel.ttf"):
			result.set_font("font", type_name, load("res://assets/cinzel.ttf"))
	for type_name: String in ["HSeparator", "VSeparator"]:
		var line: StyleBoxLine = StyleBoxLine.new()
		line.color = Color("a38a59")
		line.thickness = 1
		line.vertical = type_name == "VSeparator"
		line.set_content_margin_all(5)
		result.set_stylebox("separator", type_name, line)
		result.set_constant("separation", type_name, 11)
	for type_name: String in ["VScrollBar", "HScrollBar"]:
		result.set_stylebox("scroll", type_name, _scroll_style(Color("d6c39a"),Color("b3a079"),3))
		result.set_stylebox("scroll_focus", type_name, _scroll_style(Color("d6c39a"),GOLD,3))
		result.set_stylebox("grabber", type_name, _scroll_style(Color("937342"),Color("72512d"),4))
		result.set_stylebox("grabber_highlight", type_name, _scroll_style(Color("aa8550"),Color("72512d"),4))
		result.set_stylebox("grabber_pressed", type_name, _scroll_style(Color("745631"),Color("5d4225"),4))
		for icon_name: String in ["increment", "increment_highlight", "increment_pressed", "decrement", "decrement_highlight", "decrement_pressed"]:
			result.set_icon(icon_name,type_name,_blank_icon())
	result.set_stylebox("background", "ProgressBar", flat(Color("b5a27b"),Color("8c744c"),0))
	result.set_stylebox("fill", "ProgressBar", flat(Color("617341"),Color("526133"),0))
	result.set_color("font_color", "ProgressBar", INK)
	result.set_stylebox("normal", "LineEdit", paper(9))
	result.set_stylebox("read_only", "LineEdit", flat(Color("d9cba9"),Color("a08b61"),9))
	result.set_stylebox("focus", "LineEdit", flat(Color.TRANSPARENT,GOLD,0))
	result.set_color("font_color", "LineEdit", INK)
	result.set_color("caret_color", "LineEdit", OXBLOOD)
	result.set_color("selection_color", "LineEdit", Color("ccb484"))
	result.set_color("font_color", "SpinBox", INK)
	var slate_tab: Frame = _frame("command",12)
	slate_tab.fill = SLATE
	slate_tab.edge = Color("9f8351")
	slate_tab.bright = Color("bea77b")
	for type_name: String in ["TabBar", "TabContainer"]:
		result.set_stylebox("tab_unselected",type_name,slate_tab)
		result.set_stylebox("tab_hovered",type_name,command(true))
		result.set_stylebox("tab_selected",type_name,tile(true))
		result.set_color("font_unselected_color",type_name,IVORY)
		result.set_color("font_selected_color",type_name,INK)
		result.set_color("font_hovered_color",type_name,IVORY)
		result.set_stylebox("panel",type_name,paper())
	for type_name: String in ["PopupMenu", "AcceptDialog", "TooltipPanel", "PopupPanel"]:
		result.set_stylebox("panel",type_name,parchment(18))
	result.set_color("font_color", "PopupMenu", INK)
	result.set_color("font_hover_color", "PopupMenu", IVORY)
	result.set_stylebox("hover", "PopupMenu", command())
	return result

static func page_theme() -> Theme:
	return make_theme()

static func heading(text: String, size: int = 24, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	if ResourceLoader.exists("res://assets/cinzel.ttf"):
		label.add_theme_font_override("font",load("res://assets/cinzel.ttf"))
	return label

static func body(text: String, size: int = 15, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size+3)
	label.add_theme_color_override("font_color",color)
	return label

static func button(text: String, action: Callable, minimum: Vector2 = Vector2(0,40)) -> Button:
	var control: Button = Button.new()
	control.text = text
	control.custom_minimum_size = minimum
	if action.is_valid():
		control.pressed.connect(action)
	return control
