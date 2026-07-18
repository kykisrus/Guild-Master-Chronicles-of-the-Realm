class_name TinyThemeFactory
extends RefCounted
## Builds a pixel UI Theme from Tiny GUI textures + Galmuri font.

const FONT_PATH := "res://assets/fonts/ui/Galmuri11.ttf"
const PANEL_PATH := "res://assets/tiny_gui/panels/Split/Popup_Window_Dark_16x16.png"
const PANEL_LIGHT_PATH := "res://assets/tiny_gui/panels/Split/Popup_Window_Brown_16x16.png"
const BUTTON_SHEET_PATH := "res://assets/tiny_gui/buttons/Rectangle_Buttons_48x16px.png"

const COL_TEXT := Color(0.95, 0.93, 0.88, 1.0)
const COL_TEXT_DIM := Color(0.72, 0.70, 0.64, 1.0)
const COL_DISABLED := Color(0.45, 0.43, 0.40, 1.0)
const COL_ACCENT := Color(0.55, 0.78, 0.95, 1.0)


static func build() -> Theme:
	var theme := Theme.new()
	var font := _load_font()
	if font != null:
		theme.default_font = font
		theme.default_font_size = 16
		theme.set_font("font", "Label", font)
		theme.set_font("font", "Button", font)
		theme.set_font("font", "CheckButton", font)
		theme.set_font("font", "OptionButton", font)
		theme.set_font("font", "LineEdit", font)
		theme.set_font("font", "PopupMenu", font)
		theme.set_font_size("font_size", "Label", 16)
		theme.set_font_size("font_size", "Button", 16)
		theme.set_font_size("font_size", "CheckButton", 16)
		theme.set_font_size("font_size", "OptionButton", 16)
		theme.set_font_size("font_size", "LineEdit", 16)

	theme.set_color("font_color", "Label", COL_TEXT)
	theme.set_color("font_color", "Button", COL_TEXT)
	theme.set_color("font_hover_color", "Button", COL_ACCENT)
	theme.set_color("font_pressed_color", "Button", Color(1, 1, 1, 1))
	theme.set_color("font_disabled_color", "Button", COL_DISABLED)
	theme.set_color("font_focus_color", "Button", COL_ACCENT)

	var panel := _panel_style(PANEL_PATH, 16)
	var panel_light := _panel_style(PANEL_LIGHT_PATH, 16)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)
	theme.set_stylebox("panel", "AcceptDialog", panel)
	theme.set_stylebox("panel", "ConfirmationDialog", panel)

	var btn_n := _button_style(0)
	var btn_h := _button_style(1)
	var btn_p := _button_style(2)
	var btn_d := _button_style(3)
	theme.set_stylebox("normal", "Button", btn_n)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("disabled", "Button", btn_d)
	theme.set_stylebox("focus", "Button", btn_h)
	theme.set_stylebox("normal", "OptionButton", btn_n)
	theme.set_stylebox("hover", "OptionButton", btn_h)
	theme.set_stylebox("pressed", "OptionButton", btn_p)
	theme.set_stylebox("disabled", "OptionButton", btn_d)
	theme.set_stylebox("focus", "OptionButton", btn_h)

	var flat_track := StyleBoxFlat.new()
	flat_track.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	flat_track.set_corner_radius_all(2)
	flat_track.content_margin_top = 6
	flat_track.content_margin_bottom = 6
	var flat_fill := StyleBoxFlat.new()
	flat_fill.bg_color = COL_ACCENT
	flat_fill.set_corner_radius_all(2)
	theme.set_stylebox("slider", "HSlider", flat_track)
	theme.set_stylebox("grabber_area", "HSlider", flat_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_fill)

	var line := StyleBoxFlat.new()
	line.bg_color = Color(0.08, 0.09, 0.12, 1.0)
	line.border_color = Color(0.35, 0.38, 0.45, 1.0)
	line.set_border_width_all(2)
	line.content_margin_left = 8
	line.content_margin_right = 8
	line.content_margin_top = 6
	line.content_margin_bottom = 6
	theme.set_stylebox("normal", "LineEdit", line)
	theme.set_stylebox("focus", "LineEdit", line)

	var tip := panel_light.duplicate() as StyleBoxTexture
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", COL_TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)

	theme.set_constant("h_separation", "BoxContainer", 8)
	theme.set_constant("v_separation", "BoxContainer", 8)
	return theme


static func _load_font() -> FontFile:
	if not ResourceLoader.exists(FONT_PATH):
		push_warning("Font missing: %s" % FONT_PATH)
		return null
	var loaded: Resource = load(FONT_PATH)
	if loaded is FontFile:
		var font := loaded as FontFile
		font.allow_system_fallback = false
		return font
	var font2 := FontFile.new()
	var err := font2.load_dynamic_font(FONT_PATH)
	if err != OK:
		push_warning("Failed to load font: %s (%d)" % [FONT_PATH, err])
		return null
	font2.allow_system_fallback = false
	return font2


static func _panel_style(path: String, margin: int) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	if ResourceLoader.exists(path):
		box.texture = load(path) as Texture2D
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = margin + 8
	box.content_margin_right = margin + 8
	box.content_margin_top = margin + 8
	box.content_margin_bottom = margin + 8
	return box


static func _button_style(row: int) -> StyleBoxTexture:
	## Rectangle sheet is 96x176 → cells 48x16, 2 columns. Use left column rows 0..n.
	var box := StyleBoxTexture.new()
	if ResourceLoader.exists(BUTTON_SHEET_PATH):
		var sheet := load(BUTTON_SHEET_PATH) as Texture2D
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		var y := clampi(row, 0, 10) * 16
		atlas.region = Rect2(0, y, 48, 16)
		box.texture = atlas
	box.texture_margin_left = 8
	box.texture_margin_right = 8
	box.texture_margin_top = 4
	box.texture_margin_bottom = 4
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box
