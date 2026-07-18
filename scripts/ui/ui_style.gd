class_name UIStyle
extends RefCounted

## Палитра из UI/Guild_Master_UI_Visual_Concept.md (Esports Manager structure + fantasy)

const BG_DARKEST := Color("11151D")
const BG_SCENE := Color("171D27")
const BG_PANEL := Color("1F2733")
const BG_ACTIVE := Color("2A3443")
const BORDER := Color("394558")
const BORDER_SOFT := Color("303B4C")
const GLASS := Color("151B25E8")

const TEXT_H := Color("F2F4F7")
const TEXT := Color("C8CFD9")
const TEXT_DIM := Color("8D98A8")
const TEXT_OFF := Color("596577")

const SUCCESS := Color("36D26E")
const INFO := Color("2CB7D9")
const WARNING := Color("F2B84B")
const DANGER := Color("E65B5B")
const MANA := Color("8A63D2")
const CRAFT := Color("D9893C")
const GOLD := Color("F2B84B")
const GOLD_SOFT := Color("F2F4F7")

## legacy aliases used in older screens
const BG_DEEP := BG_DARKEST
const BG_PANEL_ALT := BG_ACTIVE
const BG_CARD := BG_ACTIVE
const ACCENT_OK := SUCCESS
const ACCENT_WARN := WARNING
const ACCENT_BAD := DANGER
const ACCENT_MANA := MANA
const ACCENT_FAME := GOLD

const RANK_COLORS := {
	"E": Color("7F8A96"),
	"D": Color("A7B0BA"),
	"C": Color("43A4D8"),
	"B": Color("36B675"),
	"A": Color("C68CE6"),
	"S": Color("F1BE4B"),
	"SS": Color("FF7A45"),
	"SSS": Color("FF4F7B"),
}

const SIDEBAR_EXPANDED := 224
const SIDEBAR_COLLAPSED := 72
const SPACE_XS := 4
const SPACE_S := 8
const SPACE_M := 12
const SPACE_L := 16
const SPACE_XL := 24
static var _kenney_style_cache: Dictionary = {}


static func rank_color(rank: String) -> Color:
	return RANK_COLORS.get(rank, TEXT_DIM)


static func kenney_frame_style(tint: Color = TEXT, frame: int = 11, margin: float = 12.0, surface: Color = BG_PANEL) -> StyleBoxTexture:
	# Собираем одну непрозрачную пиксельную текстуру из оригинального спрайта
	# Kenney. Старой панели или второго StyleBox под рамкой нет.
	var column := frame % 8
	var row := int(frame / 8)
	var key := "%d:%s:%s" % [frame, tint.to_html(), surface.to_html()]
	var texture: Texture2D
	if _kenney_style_cache.has(key):
		texture = _kenney_style_cache[key]
	else:
		var source_texture: Texture2D = load("res://assets/kenney/ui/fantasy_ui_borders.svg")
		var source := source_texture.get_image()
		var region := Rect2i(39 + column * 62, 39 + row * 62, 50, 50)
		var sprite := source.get_region(region)
		var composed := Image.create(50, 50, false, Image.FORMAT_RGBA8)
		composed.fill(surface)
		for y in 50:
			for x in 50:
				var pixel := sprite.get_pixel(x, y)
				if pixel.a > 0.01:
					composed.set_pixel(x, y, Color(tint, pixel.a))
		texture = ImageTexture.create_from_image(composed)
		_kenney_style_cache[key] = texture
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(margin)
	style.set_content_margin_all(margin)
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.draw_center = true
	return style


static func kenney_control_icon(tint: Color = INFO, frame: int = 19, size: int = 14) -> ImageTexture:
	var key := "icon:%d:%d:%s" % [frame, size, tint.to_html()]
	if _kenney_style_cache.has(key):
		return _kenney_style_cache[key]
	var source_texture: Texture2D = load("res://assets/kenney/ui/fantasy_ui_borders.svg")
	var source: Image = source_texture.get_image()
	var column := frame % 8
	var row := int(frame / 8)
	var sprite := source.get_region(Rect2i(39 + column * 62, 39 + row * 62, 50, 50))
	for y in 50:
		for x in 50:
			var pixel := sprite.get_pixel(x, y)
			if pixel.a > 0.01:
				sprite.set_pixel(x, y, Color(tint, pixel.a))
	sprite.resize(size, size, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(sprite)
	_kenney_style_cache[key] = texture
	return texture


static func make_flat_style(bg: Color, border: Color = BORDER, _radius: float = 8.0, border_w: float = 1.0) -> StyleBoxFlat:
	return surface_style(bg, border, maxi(1, int(border_w)), 12)


static func surface_style(bg: Color = BG_PANEL, border: Color = BORDER_SOFT, border_width: int = 1, margin: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg, 1.0)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_content_margin_all(margin)
	style.set_corner_radius_all(0)
	return style


static func make_button_style(bg: Color, border: Color, _radius: float = 7.0, _border_w: int = 1) -> StyleBoxTexture:
	return kenney_frame_style(border, 18, 11, bg if bg.a >= 0.95 else Color(bg, 1.0))


static func create_theme() -> Theme:
	var base: Theme = load("res://ui/theme/guild_master_theme.tres")
	var t: Theme = base.duplicate()
	t.default_font_size = 14
	t.default_base_scale = 1.0
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.4))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_constant("outline_size", "Label", 0)

	var btn_normal := surface_style(BG_ACTIVE, BORDER, 1, 11)
	var btn_hover := surface_style(Color("26384A"), INFO, 1, 11)
	var btn_pressed := surface_style(Color("183B4A"), INFO, 2, 11)
	var btn_disabled := surface_style(Color("171D26"), Color("283241"), 1, 11)
	var btn_focus := surface_style(BG_ACTIVE, INFO, 2, 11)
	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_color("font_color", "Button", TEXT_H)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", INFO)
	t.set_color("font_disabled_color", "Button", TEXT_OFF)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_font_size("font_size", "Button", 13)
	t.set_constant("h_separation", "Button", 8)

	t.set_stylebox("panel", "PanelContainer", surface_style(BG_PANEL, BORDER_SOFT, 1, 14))

	var le := surface_style(BG_DARKEST, BORDER, 1, 10)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", surface_style(BG_DARKEST, INFO, 2, 10))
	t.set_color("font_color", "LineEdit", TEXT_H)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	t.set_font_size("font_size", "LineEdit", 14)
	t.set_constant("minimum_character_width", "LineEdit", 4)

	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_pressed_color", "CheckButton", TEXT_H)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "OptionButton", t.get_stylebox(state, "Button"))
	t.set_color("font_color", "OptionButton", TEXT_H)
	t.set_color("font_hover_color", "OptionButton", Color.WHITE)
	t.set_color("font_disabled_color", "OptionButton", TEXT_OFF)

	t.set_stylebox("panel", "PopupMenu", surface_style(BG_PANEL, BORDER, 1, 10))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", TEXT_H)

	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color("141922")
	scroll_bg.set_corner_radius_all(4)
	scroll_bg.content_margin_left = 5
	scroll_bg.content_margin_right = 5
	var scroll_grab := StyleBoxFlat.new()
	scroll_grab.bg_color = BORDER
	scroll_grab.set_corner_radius_all(4)
	scroll_grab.content_margin_left = 5
	scroll_grab.content_margin_right = 5
	var scroll_hover := scroll_grab.duplicate()
	scroll_hover.bg_color = INFO.darkened(0.2)
	for type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", type, scroll_bg)
		t.set_stylebox("grabber", type, scroll_grab)
		t.set_stylebox("grabber_highlight", type, scroll_hover)
		t.set_stylebox("grabber_pressed", type, scroll_hover)

	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = BORDER_SOFT
	slider_bg.set_corner_radius_all(2)
	slider_bg.content_margin_top = 2
	slider_bg.content_margin_bottom = 2
	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = INFO
	slider_fill.set_corner_radius_all(2)
	slider_fill.content_margin_top = 2
	slider_fill.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", slider_bg)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	var grabber: Texture2D = kenney_control_icon(INFO, 19, 16)
	t.set_icon("grabber", "HSlider", grabber)
	t.set_icon("grabber_highlight", "HSlider", grabber)
	t.set_icon("grabber_disabled", "HSlider", grabber)
	return t


static func section_title(text: String, size: int = 20) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT_H)
	l.add_theme_color_override("font_outline_color", BG_DARKEST)
	l.add_theme_constant_override("outline_size", 2)
	return l


static func eyebrow(text: String, color: Color = INFO) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	return l


static func body_label(text: String, dim: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", TEXT_DIM if dim else TEXT)
	return l


static func fantasy_divider() -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size.y = 28
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/kenney/ui/fantasy_ui_borders.svg")
	# Горизонтальный орнамент из CC0-атласа Kenney.
	atlas.region = Rect2(688, 568, 352, 76)
	var ornament := TextureRect.new()
	ornament.texture = atlas
	ornament.custom_minimum_size = Vector2(220, 24)
	ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ornament.modulate = Color(WARNING, 0.78)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(ornament)
	return center


static func card() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", kenney_frame_style(BORDER, 11, 17, BG_PANEL))
	return p


static func glass_card(accent: Color = BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	var style := kenney_frame_style(accent, 11, 19, BG_PANEL)
	p.add_theme_stylebox_override("panel", style)
	return p


static func resource_chip(label: String, value: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", surface_style(BG_ACTIVE, Color(color, 0.55), 1, 7))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var name_l := Label.new()
	name_l.text = label.to_upper()
	name_l.add_theme_color_override("font_color", color)
	name_l.add_theme_font_size_override("font_size", 11)
	h.add_child(name_l)
	var val_l := Label.new()
	val_l.text = value
	val_l.add_theme_color_override("font_color", TEXT_H)
	val_l.add_theme_font_size_override("font_size", 15)
	h.add_child(val_l)
	return p


static func primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	_apply_fantasy_button(b, SUCCESS)
	b.custom_minimum_size.y = 40
	return b


static func danger_button(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	_apply_fantasy_button(b, DANGER)
	b.custom_minimum_size.y = 40
	return b


static func info_button(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	_apply_fantasy_button(b, INFO)
	b.custom_minimum_size.y = 40
	return b


static func warning_button(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	_apply_fantasy_button(b, WARNING)
	b.custom_minimum_size.y = 40
	return b


static func _apply_fantasy_button(button: Button, semantic_color: Color) -> void:
	button.add_theme_stylebox_override("normal", kenney_frame_style(semantic_color.darkened(0.2), 18, 11, BG_ACTIVE))
	button.add_theme_stylebox_override("hover", kenney_frame_style(semantic_color, 19, 11, Color("26384A")))
	button.add_theme_stylebox_override("pressed", kenney_frame_style(WARNING, 19, 11, Color("182633")))
	button.add_theme_stylebox_override("focus", kenney_frame_style(semantic_color, 19, 11, BG_ACTIVE))
	button.add_theme_color_override("font_color", semantic_color.lightened(0.18))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


static func status_badge(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var s := surface_style(BG_ACTIVE, Color(color, 0.55), 1, 6)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	p.add_child(l)
	return p


static func status_color(status: int) -> Color:
	match status:
		HeroData.Status.AVAILABLE:
			return SUCCESS
		HeroData.Status.ON_QUEST:
			return INFO
		HeroData.Status.HOSPITAL:
			return WARNING
		_:
			return DANGER


static func status_text(status: int) -> String:
	match status:
		HeroData.Status.AVAILABLE:
			return "Доступен"
		HeroData.Status.ON_QUEST:
			return "На задании"
		HeroData.Status.HOSPITAL:
			return "Ранен"
		_:
			return "Погиб"


static func quest_type_color(qtype: String) -> Color:
	match qtype:
		"combat":
			return DANGER
		"gathering":
			return SUCCESS
		"escort":
			return INFO
		_:
			return GOLD


static func end_day_button(has_warnings: bool = false, blocking: bool = false) -> Button:
	if blocking:
		return danger_button("Закончить день")
	if has_warnings:
		return warning_button("Закончить день")
	return primary_button("Закончить день")


static func polish_interactives(root: Node) -> void:
	if root is BaseButton:
		var button := root as BaseButton
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.focus_mode = Control.FOCUS_ALL
		if button.custom_minimum_size.y <= 0:
			button.custom_minimum_size.y = 38
		if button.disabled and button.tooltip_text.is_empty():
			button.tooltip_text = "Действие сейчас недоступно."
	for child in root.get_children():
		polish_interactives(child)
