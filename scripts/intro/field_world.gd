class_name FieldWorld
extends RefCounted
## Tiny Swords outdoor map 2048×1536 — grass, shore, water, decor on land only.

const MAP_SIZE := Vector2(2048, 1536)
const TILE := 64
const WATER_COLS := 3

const GRASS_TEX := "res://assets/tiny_swords/terrain/Tilemap_color1.png"
const WATER_BG := "res://assets/tiny_swords/terrain/Water Background color.png"
const TREE_TEX := "res://assets/tiny_swords/resources/Tree1.png"
const BUSH_TEX := "res://assets/tiny_swords/resources/Stump 1.png"
const ROCK_TEX := "res://assets/tiny_swords/resources/Gold Stone 1.png"


static func water_width() -> float:
	return float(WATER_COLS * TILE)


static func fill_field(parent: Node2D, water_edge: String = "left") -> void:
	var terrain := Node2D.new()
	terrain.name = "Terrain"
	parent.add_child(terrain)
	_fill_grass(terrain, water_edge)
	_fill_shore(terrain, water_edge)
	_fill_water(terrain, water_edge)
	_fill_road(terrain, water_edge)
	_scatter_decor(parent, water_edge)


static func _fill_grass(terrain: Node2D, water_edge: String) -> void:
	var tex: Texture2D = load(GRASS_TEX) as Texture2D
	var atlas := AtlasTexture.new()
	if tex != null:
		atlas.atlas = tex
		atlas.region = Rect2(64, 64, 64, 64)
	var cols := int(MAP_SIZE.x / TILE)
	var rows := int(MAP_SIZE.y / TILE)
	var x0 := WATER_COLS if water_edge == "left" else 0
	var x1 := cols if water_edge == "left" else cols - WATER_COLS
	for y in rows:
		for x in range(x0, x1):
			if tex == null:
				var r := ColorRect.new()
				r.color = Color(0.35, 0.55, 0.28)
				r.size = Vector2(TILE, TILE)
				r.position = Vector2(x * TILE, y * TILE)
				terrain.add_child(r)
			else:
				var s := Sprite2D.new()
				s.texture = atlas
				s.centered = false
				s.position = Vector2(x * TILE, y * TILE)
				terrain.add_child(s)


static func _fill_shore(terrain: Node2D, water_edge: String) -> void:
	var tex: Texture2D = load(GRASS_TEX) as Texture2D
	if tex == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 128, 64, 64)
	var rows := int(MAP_SIZE.y / TILE)
	var shore_x := WATER_COLS if water_edge == "left" else int(MAP_SIZE.x / TILE) - WATER_COLS - 1
	for y in rows:
		var s := Sprite2D.new()
		s.texture = atlas
		s.centered = false
		s.position = Vector2(shore_x * TILE, y * TILE)
		s.modulate = Color(0.75, 0.7, 0.55)
		terrain.add_child(s)


static func _fill_road(terrain: Node2D, water_edge: String) -> void:
	var tex: Texture2D = load(GRASS_TEX) as Texture2D
	if tex == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(192, 192, 64, 64)
	var road_y := 11
	var x_start := WATER_COLS + 1 if water_edge == "left" else 4
	for x in range(x_start, 26):
		var s := Sprite2D.new()
		s.texture = atlas
		s.centered = false
		s.position = Vector2(x * TILE, road_y * TILE)
		s.modulate = Color(0.85, 0.75, 0.55)
		terrain.add_child(s)
	for y in range(8, 12):
		var s2 := Sprite2D.new()
		s2.texture = atlas
		s2.centered = false
		s2.position = Vector2(24 * TILE, y * TILE)
		s2.modulate = Color(0.85, 0.75, 0.55)
		terrain.add_child(s2)


static func _fill_water(terrain: Node2D, edge: String) -> void:
	var tex: Texture2D = load(WATER_BG) as Texture2D
	var water := ColorRect.new()
	water.color = Color(0.25, 0.45, 0.7, 0.95)
	if edge == "left":
		water.position = Vector2(0, 0)
		water.size = Vector2(water_width(), MAP_SIZE.y)
	else:
		water.position = Vector2(MAP_SIZE.x - water_width(), 0)
		water.size = Vector2(water_width(), MAP_SIZE.y)
	terrain.add_child(water)
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = water.position
		s.scale = Vector2(water.size.x / maxf(tex.get_width(), 1), water.size.y / maxf(tex.get_height(), 1))
		s.modulate = Color(1, 1, 1, 0.65)
		terrain.add_child(s)


static func _scatter_decor(parent: Node2D, water_edge: String) -> void:
	var decor := Node2D.new()
	decor.name = "Decorations"
	decor.y_sort_enabled = true
	parent.add_child(decor)
	var min_x := water_width() + float(TILE) if water_edge == "left" else float(TILE)
	var max_x := MAP_SIZE.x - float(TILE) if water_edge == "left" else MAP_SIZE.x - water_width() - float(TILE)
	var spots: Array[Vector2] = [
		Vector2(420, 380), Vector2(560, 900), Vector2(1100, 420),
		Vector2(1400, 1100), Vector2(780, 1280), Vector2(1680, 640),
		Vector2(520, 1200), Vector2(1500, 300),
	]
	var i := 0
	for p in spots:
		var pos := p
		pos.x = clampf(pos.x, min_x, max_x)
		var path := TREE_TEX if i % 3 == 0 else (BUSH_TEX if i % 3 == 1 else ROCK_TEX)
		if not ResourceLoader.exists(path):
			path = _find_decor(i)
		if path.is_empty():
			i += 1
			continue
		var s := Sprite2D.new()
		s.texture = load(path) as Texture2D
		s.centered = true
		s.position = pos
		if s.texture:
			s.offset = Vector2(0, -s.texture.get_height() * 0.5)
		decor.add_child(s)
		i += 1


static func _find_decor(i: int) -> String:
	var dir := "res://assets/tiny_swords/resources/"
	var names := [
		"Tree1.png", "Tree2.png", "Tree3.png", "Tree4.png",
		"Stump 1.png", "Stump 2.png", "Gold Stone 1.png", "Gold Stone 2.png",
	]
	var cand: String = dir + names[i % names.size()]
	return cand if ResourceLoader.exists(cand) else ""
