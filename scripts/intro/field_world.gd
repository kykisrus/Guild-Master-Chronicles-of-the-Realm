class_name FieldWorld
extends RefCounted
## Builds a simple Tiny Swords-style outdoor map (2048×1536).

const MAP_SIZE := Vector2(2048, 1536)
const TILE := 64

const GRASS_TEX := "res://assets/tiny_swords/terrain/Tilemap_color1.png"
const WATER_BG := "res://assets/tiny_swords/terrain/Water Background color.png"
const TREE_TEX := "res://assets/tiny_swords/resources/Tree1.png"
const BUSH_TEX := "res://assets/tiny_swords/resources/Stump 1.png"
const ROCK_TEX := "res://assets/tiny_swords/resources/Gold Stone 1.png"


static func fill_field(parent: Node2D, water_edge: String = "left") -> void:
	var terrain := Node2D.new()
	terrain.name = "Terrain"
	parent.add_child(terrain)
	_fill_grass(terrain)
	_fill_road(terrain)
	_fill_water(terrain, water_edge)
	_scatter_decor(parent)


static func _fill_grass(terrain: Node2D) -> void:
	var tex: Texture2D = load(GRASS_TEX) as Texture2D
	if tex == null:
		var fallback := ColorRect.new()
		fallback.color = Color(0.35, 0.55, 0.28)
		fallback.size = MAP_SIZE
		terrain.add_child(fallback)
		return
	# Use one atlas tile (1,1) as grass fill via AtlasTexture
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(64, 64, 64, 64)
	var cols := int(MAP_SIZE.x / TILE)
	var rows := int(MAP_SIZE.y / TILE)
	for y in rows:
		for x in cols:
			var s := Sprite2D.new()
			s.texture = atlas
			s.centered = false
			s.position = Vector2(x * TILE, y * TILE)
			terrain.add_child(s)


static func _fill_road(terrain: Node2D) -> void:
	var tex: Texture2D = load(GRASS_TEX) as Texture2D
	if tex == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(192, 192, 64, 64)
	# Horizontal path toward barracks (center-ish)
	var road_y := 11
	for x in range(4, 26):
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
		water.size = Vector2(TILE * 3, MAP_SIZE.y)
	else:
		water.position = Vector2(MAP_SIZE.x - TILE * 3, 0)
		water.size = Vector2(TILE * 3, MAP_SIZE.y)
	terrain.add_child(water)
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = water.position
		s.scale = Vector2(water.size.x / maxf(tex.get_width(), 1), water.size.y / maxf(tex.get_height(), 1))
		s.modulate = Color(1, 1, 1, 0.65)
		terrain.add_child(s)


static func _scatter_decor(parent: Node2D) -> void:
	var decor := Node2D.new()
	decor.name = "Decorations"
	decor.y_sort_enabled = true
	parent.add_child(decor)
	var spots: Array[Vector2] = [
		Vector2(420, 380), Vector2(560, 900), Vector2(1100, 420),
		Vector2(1400, 1100), Vector2(780, 1280), Vector2(1680, 640),
		Vector2(320, 1200), Vector2(1500, 300),
	]
	var i := 0
	for p in spots:
		var path := TREE_TEX if i % 3 == 0 else (BUSH_TEX if i % 3 == 1 else ROCK_TEX)
		if not ResourceLoader.exists(path):
			# Try alternate decoration names
			path = _find_decor(i)
		if path.is_empty():
			i += 1
			continue
		var s := Sprite2D.new()
		s.texture = load(path) as Texture2D
		s.centered = true
		s.position = p
		s.offset = Vector2(0, -s.texture.get_height() * 0.5) if s.texture else Vector2.ZERO
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
