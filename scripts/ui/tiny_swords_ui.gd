class_name TinySwordsUi
extends RefCounted
## Helpers for Tiny Swords UI Elements (9-slice papers/buttons, avatars).

const PAPER_REGULAR := "res://assets/tiny_swords/ui/papers/RegularPaper.png"
const PAPER_SPECIAL := "res://assets/tiny_swords/ui/papers/SpecialPaper.png"
const WOOD_TABLE := "res://assets/tiny_swords/ui/wood_table/WoodTable.png"
const BTN_BLUE := "res://assets/tiny_swords/ui/buttons/BigBlueButton_Regular.png"
const BTN_BLUE_PRESSED := "res://assets/tiny_swords/ui/buttons/BigBlueButton_Pressed.png"
const BTN_SMALL := "res://assets/tiny_swords/ui/buttons/SmallBlueSquareButton_Regular.png"
const BTN_SMALL_PRESSED := "res://assets/tiny_swords/ui/buttons/SmallBlueSquareButton_Pressed.png"
const AVATAR_THIEF := "res://assets/tiny_swords/ui/avatars/Avatars_08.png"
const AVATAR_GM := "res://assets/tiny_swords/ui/avatars/Avatars_01.png"


static func style_from_sheet(path: String, content_margin := 18) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	if not ResourceLoader.exists(path):
		return box
	var tex := load(path) as Texture2D
	if tex == null:
		return box
	box.texture = tex
	# Sheets are 3×3 tiles (320×320 → ~106px corners).
	var cell := maxi(int(tex.get_width() / 3.0), 8)
	box.texture_margin_left = cell
	box.texture_margin_right = cell
	box.texture_margin_top = cell
	box.texture_margin_bottom = cell
	box.content_margin_left = content_margin
	box.content_margin_right = content_margin
	box.content_margin_top = content_margin
	box.content_margin_bottom = content_margin
	return box


static func apply_dialogue_theme(control: Control) -> void:
	var theme := TinyThemeFactory.build()
	control.theme = theme
	var panel := style_from_sheet(PAPER_SPECIAL if ResourceLoader.exists(PAPER_SPECIAL) else PAPER_REGULAR, 20)
	theme.set_stylebox("panel", "PanelContainer", panel)
	var btn_n := style_from_sheet(BTN_SMALL if ResourceLoader.exists(BTN_SMALL) else BTN_BLUE, 12)
	var btn_p := style_from_sheet(BTN_SMALL_PRESSED if ResourceLoader.exists(BTN_SMALL_PRESSED) else BTN_BLUE_PRESSED, 12)
	theme.set_stylebox("normal", "Button", btn_n)
	theme.set_stylebox("hover", "Button", btn_n)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("focus", "Button", btn_n)
	theme.set_color("font_color", "Button", Color(0.12, 0.1, 0.08, 1.0))
	theme.set_color("font_hover_color", "Button", Color(0.05, 0.04, 0.03, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.2, 0.12, 0.05, 1.0))
	theme.set_color("font_color", "Label", Color(0.12, 0.1, 0.08, 1.0))
	theme.set_color("font_shadow_color", "Label", Color(1, 1, 1, 0.15))
	theme.set_color("default_color", "RichTextLabel", Color(0.12, 0.1, 0.08, 1.0))


static func load_avatar(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
