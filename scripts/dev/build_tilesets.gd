extends SceneTree
## Headless: godot --path . --headless -s res://scripts/dev/build_tilesets.gd
## Builds Tiny Swords + Kings and Pigs TileSet resources.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_build_tiny_swords_terrain()
	_build_kap_tileset(
		"res://assets/kings_and_pigs/terrain/Terrain (32x32).png",
		"res://resources/tilesets/kings_and_pigs_terrain.tres",
		32
	)
	_build_kap_tileset(
		"res://assets/kings_and_pigs/decorations/Decorations (32x32).png",
		"res://resources/tilesets/kings_and_pigs_decorations.tres",
		32
	)
	print("TILESETS BUILT")
	quit(0)


func _build_tiny_swords_terrain() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	var paths := [
		"res://assets/tiny_swords/terrain/Tilemap_color1.png",
		"res://assets/tiny_swords/terrain/Tilemap_color2.png",
		"res://assets/tiny_swords/terrain/Tilemap_color3.png",
		"res://assets/tiny_swords/terrain/Tilemap_color4.png",
		"res://assets/tiny_swords/terrain/Tilemap_color5.png",
	]
	var source_id := 0
	for path in paths:
		if not ResourceLoader.exists(path):
			push_warning("Missing %s" % path)
			continue
		var tex: Texture2D = load(path)
		var atlas := TileSetAtlasSource.new()
		atlas.texture = tex
		atlas.texture_region_size = Vector2i(64, 64)
		var cols: int = int(tex.get_width() / 64)
		var rows: int = int(tex.get_height() / 64)
		for y in rows:
			for x in cols:
				atlas.create_tile(Vector2i(x, y))
		ts.add_source(atlas, source_id)
		source_id += 1
	# Extra overlays as 64-ish sources if present
	for path in [
		"res://assets/tiny_swords/terrain/Shadow.png",
		"res://assets/tiny_swords/terrain/Water Foam.png",
	]:
		if ResourceLoader.exists(path):
			var tex2: Texture2D = load(path)
			var atlas2 := TileSetAtlasSource.new()
			atlas2.texture = tex2
			var sz := mini(tex2.get_width(), tex2.get_height())
			# use full texture as one tile if not grid-aligned
			atlas2.texture_region_size = Vector2i(sz, sz) if sz > 0 else Vector2i(64, 64)
			atlas2.create_tile(Vector2i(0, 0))
			ts.add_source(atlas2, source_id)
			source_id += 1
	var err := ResourceSaver.save(ts, "res://resources/tilesets/tiny_swords_terrain.tres")
	assert(err == OK, "Failed saving tiny swords tileset: %s" % err)
	print("Saved tiny_swords_terrain.tres sources=", ts.get_source_count())


func _build_kap_tileset(texture_path: String, out_path: String, tile: int) -> void:
	if not ResourceLoader.exists(texture_path):
		push_warning("Missing %s" % texture_path)
		return
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile, tile)
	var tex: Texture2D = load(texture_path)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(tile, tile)
	var cols: int = int(tex.get_width() / tile)
	var rows: int = int(tex.get_height() / tile)
	for y in rows:
		for x in cols:
			atlas.create_tile(Vector2i(x, y))
	ts.add_source(atlas, 0)
	var err := ResourceSaver.save(ts, out_path)
	assert(err == OK, "Failed saving %s" % out_path)
	print("Saved ", out_path, " tiles=", cols * rows)
