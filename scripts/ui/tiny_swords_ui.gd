class_name TinySwordsUi
extends RefCounted
## Tiny Swords UI: bake 3×3 sheets into seamless StyleBoxTexture panels.

const PAPER_REGULAR := "res://assets/tiny_swords/ui/papers/RegularPaper.png"
const PAPER_SPECIAL := "res://assets/tiny_swords/ui/papers/SpecialPaper.png"
const WOOD_TABLE := "res://assets/tiny_swords/ui/wood_table/WoodTable.png"
const BTN_BLUE := "res://assets/tiny_swords/ui/buttons/BigBlueButton_Regular.png"
const BTN_BLUE_PRESSED := "res://assets/tiny_swords/ui/buttons/BigBlueButton_Pressed.png"
const BTN_SMALL := "res://assets/tiny_swords/ui/buttons/SmallBlueSquareButton_Regular.png"
const BTN_SMALL_PRESSED := "res://assets/tiny_swords/ui/buttons/SmallBlueSquareButton_Pressed.png"
const AVATAR_THIEF := "res://assets/tiny_swords/ui/avatars/Avatars_08.png"
const AVATAR_GM := "res://assets/tiny_swords/ui/avatars/Avatars_01.png"

static var _bake_cache: Dictionary = {}


static func bake_seamless_panel(sheet_path: String) -> ImageTexture:
	if _bake_cache.has(sheet_path):
		return _bake_cache[sheet_path] as ImageTexture
	if not ResourceLoader.exists(sheet_path):
		return null
	var src_tex := load(sheet_path) as Texture2D
	if src_tex == null:
		return null
	var src: Image = src_tex.get_image()
	if src == null:
		return null
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var cw := w / 3
	var ch := h / 3
	if cw < 8 or ch < 8:
		return null

	# Crop non-black content from each of 9 cells.
	var crops: Array = []
	var max_cw := 1
	var max_ch := 1
	for row in range(3):
		for col in range(3):
			var cell := src.get_region(Rect2i(col * cw, row * ch, cw, ch))
			var bbox := _content_bbox(cell)
			var crop: Image
			if bbox.size.x <= 0 or bbox.size.y <= 0:
				crop = Image.create(1, 1, false, Image.FORMAT_RGBA8)
				crop.fill(Color(0, 0, 0, 0))
			else:
				crop = cell.get_region(bbox)
			crops.append(crop)
			max_cw = maxi(max_cw, crop.get_width())
			max_ch = maxi(max_ch, crop.get_height())

	# Uniform cell for clean 9-slice margins.
	var cell_out := maxi(maxi(max_cw, max_ch), 16)
	var out := Image.create(cell_out * 3, cell_out * 3, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for i in range(9):
		var row := i / 3
		var col := i % 3
		var crop: Image = crops[i]
		var padded := Image.create(cell_out, cell_out, false, Image.FORMAT_RGBA8)
		# Fill with average edge color from crop center-ish for stretch fill
		var fill_c := _sample_fill_color(crop)
		padded.fill(fill_c)
		var ox := (cell_out - crop.get_width()) / 2
		var oy := (cell_out - crop.get_height()) / 2
		padded.blit_rect(crop, Rect2i(0, 0, crop.get_width(), crop.get_height()), Vector2i(ox, oy))
		out.blit_rect(padded, Rect2i(0, 0, cell_out, cell_out), Vector2i(col * cell_out, row * cell_out))

	var tex := ImageTexture.create_from_image(out)
	_bake_cache[sheet_path] = tex
	return tex


static func style_from_sheet(path: String, content_margin := 18) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var baked := bake_seamless_panel(path)
	if baked == null:
		return box
	box.texture = baked
	var cell := maxi(baked.get_width() / 3, 8)
	box.texture_margin_left = cell
	box.texture_margin_right = cell
	box.texture_margin_top = cell
	box.texture_margin_bottom = cell
	box.content_margin_left = content_margin
	box.content_margin_right = content_margin
	box.content_margin_top = content_margin
	box.content_margin_bottom = content_margin
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return box


static func apply_nine_patch(rect: NinePatchRect, sheet_path: String) -> void:
	var baked := bake_seamless_panel(sheet_path)
	if baked == null or rect == null:
		return
	rect.texture = baked
	var cell := maxi(baked.get_width() / 3, 8)
	rect.patch_margin_left = cell
	rect.patch_margin_right = cell
	rect.patch_margin_top = cell
	rect.patch_margin_bottom = cell


static func apply_dialogue_theme(control: Control) -> void:
	control.theme = TinySwordsThemeFactory.build()


static func load_avatar(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func _content_bbox(img: Image) -> Rect2i:
	var iw := img.get_width()
	var ih := img.get_height()
	var min_x := iw
	var min_y := ih
	var max_x := -1
	var max_y := -1
	for y in range(ih):
		for x in range(iw):
			var c := img.get_pixel(x, y)
			if c.a > 0.08 and (c.r + c.g + c.b) > 0.12:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func _sample_fill_color(img: Image) -> Color:
	if img.get_width() < 1 or img.get_height() < 1:
		return Color(0.2, 0.22, 0.28, 1.0)
	return img.get_pixel(img.get_width() / 2, img.get_height() / 2)
