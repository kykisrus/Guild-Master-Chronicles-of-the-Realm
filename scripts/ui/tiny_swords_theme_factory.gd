class_name TinySwordsThemeFactory
extends RefCounted
## Game UI theme from Tiny Swords (baked 9-slice). Settings keep TinyThemeFactory.

const FONT_PATH := "res://assets/fonts/ui/PixCyrillic-AShortHikeEdition.ttf"

const COL_TEXT := Color(0.96, 0.94, 0.88, 1.0)
const COL_TEXT_DIM := Color(0.78, 0.76, 0.70, 1.0)
const COL_DISABLED := Color(0.55, 0.53, 0.50, 1.0)
const COL_ACCENT := Color(0.95, 0.82, 0.35, 1.0)
const COL_TEXT_ON_PANEL := Color(0.12, 0.1, 0.08, 1.0)


static func build() -> Theme:
	var theme := Theme.new()
	var font := _load_font()
	if font != null:
		theme.default_font = font
		theme.default_font_size = 16
		for type_name in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "PopupMenu", "TooltipLabel", "RichTextLabel"]:
			theme.set_font("font", type_name, font)
			theme.set_font_size("font_size", type_name, 16)

	var panel := TinySwordsUi.style_from_sheet(TinySwordsUi.PAPER_SPECIAL, 16, TinySwordsUi.PANEL_MAX_TEX_MARGIN)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)
	theme.set_stylebox("panel", "AcceptDialog", panel)
	theme.set_stylebox("panel", "ConfirmationDialog", panel)

	var btn_n := TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN)
	var btn_p := TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE_PRESSED, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN)
	for type_name in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type_name, btn_n)
		theme.set_stylebox("hover", type_name, btn_n)
		theme.set_stylebox("pressed", type_name, btn_p)
		theme.set_stylebox("disabled", type_name, btn_n)
		theme.set_stylebox("focus", type_name, btn_n)

	# Paper panels are light — use dark body text.
	theme.set_color("font_color", "Label", COL_TEXT_ON_PANEL)
	theme.set_color("font_shadow_color", "Label", Color(1, 1, 1, 0.15))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_color("font_color", "Button", COL_TEXT)
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "Button", COL_ACCENT)
	theme.set_color("font_disabled_color", "Button", COL_DISABLED)
	theme.set_color("font_focus_color", "Button", Color(1, 1, 1, 1))

	theme.set_color("font_color", "OptionButton", COL_TEXT)
	theme.set_color("font_hover_color", "OptionButton", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "OptionButton", COL_ACCENT)
	theme.set_color("font_disabled_color", "OptionButton", COL_DISABLED)

	var line := TinySwordsUi.style_horizontal_bar(TinySwordsUi.WOOD_TABLE, 8, 12)
	theme.set_stylebox("normal", "LineEdit", line)
	theme.set_stylebox("focus", "LineEdit", line)
	theme.set_constant("minimum_character_width", "LineEdit", 8)
	theme.set_color("font_color", "LineEdit", COL_TEXT)
	theme.set_color("font_uneditable_color", "LineEdit", COL_DISABLED)
	theme.set_color("caret_color", "LineEdit", COL_ACCENT)
	theme.set_color("font_placeholder_color", "LineEdit", COL_TEXT_DIM)

	theme.set_color("default_color", "RichTextLabel", COL_TEXT_ON_PANEL)
	theme.set_constant("h_separation", "BoxContainer", 8)
	theme.set_constant("v_separation", "BoxContainer", 8)
	return theme


static func _load_font() -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		return null
	var loaded: Resource = load(FONT_PATH)
	if loaded is FontFile:
		var font := (loaded as FontFile).duplicate(true) as FontFile
		font.allow_system_fallback = false
		return font
	return null
