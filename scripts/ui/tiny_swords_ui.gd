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

## Cap texture margins so short buttons (~40px) don't shred 9-slice.
const DEFAULT_MAX_TEX_MARGIN := 14
const PANEL_MAX_TEX_MARGIN := 28

static var _bake_cache: Dictionary = {} # path -> {tex, ml, mr, mt, mb}


static func bake_seamless_panel(sheet_path: String) -> ImageTexture:
	var meta := _bake_meta(sheet_path)
	if meta.is_empty():
		return null
	return meta["tex"] as ImageTexture


static func style_from_sheet(path: String, content_margin := 18, max_tex_margin := DEFAULT_MAX_TEX_MARGIN) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var meta := _bake_meta(path)
	if meta.is_empty():
		return box
	_apply_meta_to_stylebox(box, meta, content_margin, max_tex_margin, false)
	return box


## Horizontal bar (LineEdit / TopBar): middle row only, no vertical 9-slice crush.
static func style_horizontal_bar(path: String, content_margin := 8, max_side_margin := 12) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var meta := _bake_middle_row_meta(path)
	if meta.is_empty():
		return style_from_sheet(path, content_margin, max_side_margin)
	_apply_meta_to_stylebox(box, meta, content_margin, max_side_margin, true)
	return box


static func apply_nine_patch(rect: NinePatchRect, sheet_path: String, max_tex_margin := PANEL_MAX_TEX_MARGIN) -> void:
	if rect == null:
		return
	var meta := _bake_meta(sheet_path)
	if meta.is_empty():
		return
	var tex: ImageTexture = meta["tex"]
	var ml := int(meta["ml"])
	var mr := int(meta["mr"])
	var mt := int(meta["mt"])
	var mb := int(meta["mb"])
	if max_tex_margin > 0:
		var need := float(maxi(maxi(ml, mr), maxi(mt, mb)))
		if need > float(max_tex_margin):
			var scale := float(max_tex_margin) / need
			tex = _scale_texture(tex, scale)
			ml = maxi(1, int(round(float(ml) * scale)))
			mr = maxi(1, int(round(float(mr) * scale)))
			mt = maxi(1, int(round(float(mt) * scale)))
			mb = maxi(1, int(round(float(mb) * scale)))
	rect.texture = tex
	rect.patch_margin_left = ml
	rect.patch_margin_right = mr
	rect.patch_margin_top = mt
	rect.patch_margin_bottom = mb


static func apply_dialogue_theme(control: Control) -> void:
	control.theme = TinySwordsThemeFactory.build()


static func load_avatar(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func _apply_meta_to_stylebox(
	box: StyleBoxTexture,
	meta: Dictionary,
	content_margin: int,
	max_tex_margin: int,
	horizontal_bar: bool
) -> void:
	var tex: ImageTexture = meta["tex"]
	var ml := int(meta["ml"])
	var mr := int(meta["mr"])
	var mt := int(meta["mt"])
	var mb := int(meta["mb"])
	if horizontal_bar:
		# Keep full strip height; only slice left/right so wood doesn't get crushed bands.
		mt = 0
		mb = 0
		var th := float(tex.get_height())
		if th > 32.0:
			var vscale := 32.0 / th
			tex = _scale_texture(tex, vscale)
			ml = maxi(1, int(round(float(ml) * vscale)))
			mr = maxi(1, int(round(float(mr) * vscale)))
		# Cap margins without shrinking the whole strip again (avoids 10px-tall mush).
		if max_tex_margin > 0:
			ml = mini(ml, max_tex_margin)
			mr = mini(mr, max_tex_margin)
	elif max_tex_margin > 0:
		var need := float(maxi(maxi(ml, mr), maxi(mt, mb)))
		if need > float(max_tex_margin):
			var scale := float(max_tex_margin) / need
			tex = _scale_texture(tex, scale)
			ml = maxi(1, int(round(float(ml) * scale)))
			mr = maxi(1, int(round(float(mr) * scale)))
			mt = maxi(1, int(round(float(mt) * scale)))
			mb = maxi(1, int(round(float(mb) * scale)))
	box.texture = tex
	box.texture_margin_left = ml
	box.texture_margin_right = mr
	box.texture_margin_top = mt
	box.texture_margin_bottom = mb
	box.content_margin_left = content_margin
	box.content_margin_right = content_margin
	box.content_margin_top = content_margin
	box.content_margin_bottom = content_margin
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH


static func _bake_middle_row_meta(sheet_path: String) -> Dictionary:
	var cache_key := sheet_path + "::midrow"
	if _bake_cache.has(cache_key):
		return _bake_cache[cache_key] as Dictionary
	if not ResourceLoader.exists(sheet_path):
		return {}
	var src_tex := load(sheet_path) as Texture2D
	if src_tex == null:
		return {}
	var src: Image = src_tex.get_image()
	if src == null:
		return {}
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var cw := w / 3
	var ch := h / 3
	if cw < 8 or ch < 8:
		return {}

	var crops: Array = []
	for col in range(3):
		var cell := src.get_region(Rect2i(col * cw, ch, cw, ch)) # middle row
		var bbox := _content_bbox(cell)
		if bbox.size.x <= 0 or bbox.size.y <= 0:
			var empty := Image.create(1, 1, false, Image.FORMAT_RGBA8)
			empty.fill(Color(0, 0, 0, 0))
			crops.append(empty)
		else:
			crops.append(cell.get_region(bbox))

	var col_w: Array[int] = [crops[0].get_width(), crops[1].get_width(), crops[2].get_width()]
	var row_h := maxi(crops[0].get_height(), maxi(crops[1].get_height(), crops[2].get_height()))
	var out_w := col_w[0] + col_w[1] + col_w[2]
	var out := Image.create(out_w, row_h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var x := 0
	for col in range(3):
		var crop: Image = crops[col]
		var cell_img := Image.create(col_w[col], row_h, false, Image.FORMAT_RGBA8)
		cell_img.fill(_sample_fill_color(crop))
		var ox := 0
		if col == 1:
			ox = (col_w[col] - crop.get_width()) / 2
		elif col == 2:
			ox = col_w[col] - crop.get_width()
		var oy := (row_h - crop.get_height()) / 2
		cell_img.blit_rect(crop, Rect2i(0, 0, crop.get_width(), crop.get_height()), Vector2i(ox, oy))
		out.blit_rect(cell_img, Rect2i(0, 0, col_w[col], row_h), Vector2i(x, 0))
		x += col_w[col]

	var tex := ImageTexture.create_from_image(out)
	var meta := {
		"tex": tex,
		"ml": col_w[0],
		"mr": col_w[2],
		"mt": 0,
		"mb": 0,
	}
	_bake_cache[cache_key] = meta
	return meta


static func _bake_meta(sheet_path: String) -> Dictionary:
	if _bake_cache.has(sheet_path):
		return _bake_cache[sheet_path] as Dictionary
	if not ResourceLoader.exists(sheet_path):
		return {}
	var src_tex := load(sheet_path) as Texture2D
	if src_tex == null:
		return {}
	var src: Image = src_tex.get_image()
	if src == null:
		return {}
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var cw := w / 3
	var ch := h / 3
	if cw < 8 or ch < 8:
		return {}

	var crops: Array = []
	for row in range(3):
		for col in range(3):
			var cell := src.get_region(Rect2i(col * cw, row * ch, cw, ch))
			var bbox := _content_bbox(cell)
			if bbox.size.x <= 0 or bbox.size.y <= 0:
				var empty := Image.create(1, 1, false, Image.FORMAT_RGBA8)
				empty.fill(Color(0, 0, 0, 0))
				crops.append(empty)
			else:
				crops.append(cell.get_region(bbox))

	var col_w: Array[int] = [
		maxi(crops[0].get_width(), maxi(crops[3].get_width(), crops[6].get_width())),
		maxi(crops[1].get_width(), maxi(crops[4].get_width(), crops[7].get_width())),
		maxi(crops[2].get_width(), maxi(crops[5].get_width(), crops[8].get_width())),
	]
	var row_h: Array[int] = [
		maxi(crops[0].get_height(), maxi(crops[1].get_height(), crops[2].get_height())),
		maxi(crops[3].get_height(), maxi(crops[4].get_height(), crops[5].get_height())),
		maxi(crops[6].get_height(), maxi(crops[7].get_height(), crops[8].get_height())),
	]
	var out_w := col_w[0] + col_w[1] + col_w[2]
	var out_h := row_h[0] + row_h[1] + row_h[2]
	var out := Image.create(out_w, out_h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	var xs: Array[int] = [0, col_w[0], col_w[0] + col_w[1]]
	var ys: Array[int] = [0, row_h[0], row_h[0] + row_h[1]]
	for row in range(3):
		for col in range(3):
			var crop: Image = crops[row * 3 + col]
			var cell_img := Image.create(col_w[col], row_h[row], false, Image.FORMAT_RGBA8)
			var fill_c := _sample_fill_color(crop)
			cell_img.fill(fill_c)
			# Align toward outer edges so thin texture_margins keep the rim.
			var ox := 0
			var oy := 0
			match col:
				0:
					ox = 0
				1:
					ox = (col_w[col] - crop.get_width()) / 2
				2:
					ox = col_w[col] - crop.get_width()
			match row:
				0:
					oy = 0
				1:
					oy = (row_h[row] - crop.get_height()) / 2
				2:
					oy = row_h[row] - crop.get_height()
			cell_img.blit_rect(crop, Rect2i(0, 0, crop.get_width(), crop.get_height()), Vector2i(ox, oy))
			out.blit_rect(cell_img, Rect2i(0, 0, col_w[col], row_h[row]), Vector2i(xs[col], ys[row]))

	var tex := ImageTexture.create_from_image(out)
	var meta := {
		"tex": tex,
		"ml": col_w[0],
		"mr": col_w[2],
		"mt": row_h[0],
		"mb": row_h[2],
	}
	_bake_cache[sheet_path] = meta
	return meta


static func _scale_texture(tex: ImageTexture, scale: float) -> ImageTexture:
	var img := tex.get_image()
	if img == null:
		return tex
	if img.is_compressed():
		img.decompress()
	var nw := maxi(1, int(round(float(img.get_width()) * scale)))
	var nh := maxi(1, int(round(float(img.get_height()) * scale)))
	img.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


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
