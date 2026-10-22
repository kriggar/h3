class_name DraconiaTheme
extends RefCounted

const INK: Color = Color("e6d5ad")
const MUTED: Color = Color("ad9e80")
const GOLD: Color = Color("b79551")
const CREAM: Color = Color("302b22")
const DARK: Color = Color("191d1a")

static func flat(color: Color, border: Color = Color("a18b62"), margin: int = 12) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(margin)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	return box

static func parchment(margin: int = 22) -> StyleBox:
	var box: DraconiaFrame = DraconiaFrame.new()
	box.set_content_margin_all(maxf(10.0, float(margin)))
	if ResourceLoader.exists("res://assets/generated/ui-material-v2.png"):
		box.texture = load("res://assets/generated/ui-material-v2.png")
	return box

static func command(active: bool = false, pressed: bool = false) -> StyleBox:
	var box: DraconiaFrame = parchment(10) as DraconiaFrame
	box.active = active
	box.inset = pressed
	box.ornaments = false
	box.fill = Color("55452a") if active else Color("2d2c22")
	box.edge = Color("d4b66c") if active else Color("806b44")
	return box

static func paper(margin: int = 18) -> StyleBox:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load("res://assets/generated/parchment.png")
	var texture_size: Vector2 = box.texture.get_size()
	box.region_rect = Rect2(texture_size * 0.18, texture_size * 0.64)
	box.set_content_margin_all(margin)
	return box

static func page_theme() -> Theme:
	var result: Theme = make_theme()
	result.set_color("font_color", "Label", Color("3a3022"))
	result.set_color("default_color", "RichTextLabel", Color("3a3022"))
	return result

static func make_theme() -> Theme:
	var result: Theme = Theme.new()
	result.default_font_size = 18
	if ResourceLoader.exists("res://assets/ebgaramond.ttf"):
		result.default_font = load("res://assets/ebgaramond.ttf")
	result.set_color("font_color", "Label", INK)
	result.set_color("default_color", "RichTextLabel", INK)
	result.set_constant("separation", "VBoxContainer", 9)
	result.set_constant("separation", "HBoxContainer", 10)
	result.set_stylebox("panel", "PanelContainer", parchment())
	result.set_stylebox("panel", "Panel", parchment())
	result.set_stylebox("normal", "Button", command())
	result.set_stylebox("hover", "Button", command(true))
	result.set_stylebox("pressed", "Button", command(true, true))
	result.set_stylebox("disabled", "Button", command(false, true))
	result.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), Color("705b33"), 0))
	result.set_color("font_color", "Button", INK)
	result.set_color("font_hover_color", "Button", Color("fff2cc"))
	result.set_color("font_pressed_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("726a55"))
	result.set_font_size("font_size", "Button", 17)
	result.set_stylebox("background", "ProgressBar", flat(Color("191c17"), Color("5a4d31"), 0))
	result.set_stylebox("fill", "ProgressBar", flat(Color("637451"), Color("637451"), 0))
	result.set_stylebox("normal", "LineEdit", command(false, true))
	result.set_color("font_color", "LineEdit", INK)
	result.set_color("font_color", "SpinBox", INK)
	result.set_stylebox("panel", "PopupMenu", parchment(14))
	result.set_stylebox("panel", "AcceptDialog", parchment(20))
	result.set_stylebox("panel", "TooltipPanel", parchment(14))
	result.set_color("font_color", "TooltipLabel", INK)
	return result

static func heading(text: String, size: int = 24, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	if color != INK:
		label.add_theme_color_override("font_color", color)
	if ResourceLoader.exists("res://assets/cinzel.ttf"):
		label.add_theme_font_override("font", load("res://assets/cinzel.ttf"))
	return label

static func body(text: String, size: int = 15, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size + 3)
	if color != INK:
		label.add_theme_color_override("font_color", color)
	return label

static func button(text: String, action: Callable, minimum: Vector2 = Vector2(0, 40)) -> Button:
	var control: Button = Button.new()
	control.text = text
	control.custom_minimum_size = minimum
	control.pressed.connect(action)
	return control
