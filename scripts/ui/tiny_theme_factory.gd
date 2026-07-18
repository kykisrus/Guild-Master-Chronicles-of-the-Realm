class_name TinyThemeFactory
extends RefCounted
## Builds a readable pixel UI Theme (Tiny palette + Pix Cyrillic).
## Uses StyleBoxFlat for reliable contrast; texture atlases are reserved
## for later when 9-slice regions are authored explicitly.

const FONT_PATH := "res://assets/fonts/ui/PixCyrillic-AShortHikeEdition.ttf"

## Light text on dark controls — high contrast for Steam Deck / night scenes.
const COL_TEXT := Color(0.96, 0.94, 0.88, 1.0)
const COL_TEXT_DIM := Color(0.78, 0.76, 0.70, 1.0)
const COL_DISABLED := Color(0.55, 0.53, 0.50, 1.0)
const COL_ACCENT := Color(0.55, 0.82, 0.98, 1.0)

const COL_PANEL := Color(0.08, 0.09, 0.14, 0.92)
const COL_PANEL_BORDER := Color(0.28, 0.32, 0.42, 1.0)
const COL_BTN := Color(0.14, 0.16, 0.22, 1.0)
const COL_BTN_HOVER := Color(0.20, 0.24, 0.34, 1.0)
const COL_BTN_PRESSED := Color(0.10, 0.12, 0.18, 1.0)
const COL_BTN_DISABLED := Color(0.10, 0.10, 0.12, 1.0)
const COL_BTN_BORDER := Color(0.42, 0.46, 0.56, 1.0)
const COL_BTN_BORDER_FOCUS := Color(0.55, 0.82, 0.98, 1.0)


static func build() -> Theme:
	var theme := Theme.new()
	var font := _load_font()
	if font != null:
		theme.default_font = font
		theme.default_font_size = 16
		for type_name in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "PopupMenu", "TooltipLabel"]:
			theme.set_font("font", type_name, font)
			theme.set_font_size("font_size", type_name, 16)

	theme.set_color("font_color", "Label", COL_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	# Dark buttons + light text (readable on light atlas leftovers and night BG).
	theme.set_color("font_color", "Button", COL_TEXT)
	theme.set_color("font_hover_color", "Button", Color(1.0, 1.0, 1.0, 1.0))
	theme.set_color("font_pressed_color", "Button", COL_ACCENT)
	theme.set_color("font_disabled_color", "Button", COL_DISABLED)
	theme.set_color("font_focus_color", "Button", Color(1.0, 1.0, 1.0, 1.0))

	theme.set_color("font_color", "CheckButton", COL_TEXT)
	theme.set_color("font_hover_color", "CheckButton", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "CheckButton", COL_ACCENT)
	theme.set_color("font_disabled_color", "CheckButton", COL_DISABLED)

	theme.set_color("font_color", "OptionButton", COL_TEXT)
	theme.set_color("font_hover_color", "OptionButton", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "OptionButton", COL_ACCENT)
	theme.set_color("font_disabled_color", "OptionButton", COL_DISABLED)
	theme.set_color("font_focus_color", "OptionButton", Color(1, 1, 1, 1))

	theme.set_color("font_color", "LineEdit", COL_TEXT)
	theme.set_color("font_uneditable_color", "LineEdit", COL_DISABLED)
	theme.set_color("caret_color", "LineEdit", COL_ACCENT)

	var panel := _flat_panel(COL_PANEL, COL_PANEL_BORDER)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)
	theme.set_stylebox("panel", "AcceptDialog", panel)
	theme.set_stylebox("panel", "ConfirmationDialog", panel)
	theme.set_stylebox("panel", "TooltipPanel", panel)
	theme.set_color("font_color", "TooltipLabel", COL_TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 14)

	var btn_n := _flat_button(COL_BTN, COL_BTN_BORDER)
	var btn_h := _flat_button(COL_BTN_HOVER, COL_BTN_BORDER_FOCUS)
	var btn_p := _flat_button(COL_BTN_PRESSED, COL_ACCENT)
	var btn_d := _flat_button(COL_BTN_DISABLED, Color(0.25, 0.25, 0.28, 1.0))
	for type_name in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type_name, btn_n)
		theme.set_stylebox("hover", type_name, btn_h)
		theme.set_stylebox("pressed", type_name, btn_p)
		theme.set_stylebox("disabled", type_name, btn_d)
		theme.set_stylebox("focus", type_name, btn_h)

	var flat_track := StyleBoxFlat.new()
	flat_track.bg_color = Color(0.10, 0.11, 0.15, 1.0)
	flat_track.border_color = COL_PANEL_BORDER
	flat_track.set_border_width_all(1)
	flat_track.content_margin_top = 8
	flat_track.content_margin_bottom = 8
	var flat_fill := StyleBoxFlat.new()
	flat_fill.bg_color = COL_ACCENT
	theme.set_stylebox("slider", "HSlider", flat_track)
	theme.set_stylebox("grabber_area", "HSlider", flat_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_fill)

	var line := _flat_button(Color(0.06, 0.07, 0.10, 1.0), COL_PANEL_BORDER)
	theme.set_stylebox("normal", "LineEdit", line)
	theme.set_stylebox("focus", "LineEdit", _flat_button(Color(0.06, 0.07, 0.10, 1.0), COL_BTN_BORDER_FOCUS))

	theme.set_constant("h_separation", "BoxContainer", 8)
	theme.set_constant("v_separation", "BoxContainer", 8)
	return theme


static func _load_font() -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		push_warning("Font missing: %s" % FONT_PATH)
		return null
	var loaded: Resource = load(FONT_PATH)
	if loaded is FontFile:
		var font := (loaded as FontFile).duplicate(true) as FontFile
		font.allow_system_fallback = false
		return font
	var font2 := FontFile.new()
	var err := font2.load_dynamic_font(FONT_PATH)
	if err != OK:
		push_warning("Failed to load font: %s (%d)" % [FONT_PATH, err])
		return null
	font2.allow_system_fallback = false
	return font2


static func _flat_panel(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box


static func _flat_button(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box
