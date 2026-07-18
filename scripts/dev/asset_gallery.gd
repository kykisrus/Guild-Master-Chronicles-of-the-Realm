extends Control
## Dev-only Tiny asset gallery. Open via editor (F6). Not linked from main menu.

const CATALOG_PATH := "res://resources/asset_catalog/tiny_assets.json"

const SECTIONS: Array[Dictionary] = [
	{"title": "Tiny Swords Units", "pack": "Tiny Swords", "category": "Unit"},
	{"title": "Tiny Swords Buildings", "pack": "Tiny Swords", "category": "Building"},
	{"title": "Tiny Swords Terrain", "pack": "Tiny Swords", "category": "Terrain"},
	{"title": "Tiny Swords Decorations", "pack": "Tiny Swords", "category": "Decoration"},
	{"title": "Tiny Swords Resources", "pack": "Tiny Swords", "category": "Resource"},
	{"title": "Tiny Swords FX", "pack": "Tiny Swords", "category": "FX"},
	{"title": "Tiny Neighbours NPC", "pack": "Tiny Neighbours", "category": "NPC"},
	{"title": "Tiny Neighbours Emotions", "pack": "Tiny Neighbours", "category": "Emotion"},
	{"title": "Kings and Pigs Characters", "pack": "Kings and Pigs", "category": "Character"},
	{"title": "Kings and Pigs Doors", "pack": "Kings and Pigs", "category": "Door"},
	{"title": "Kings and Pigs Terrain", "pack": "Kings and Pigs", "category": "Terrain"},
]

@onready var section_list: ItemList = %SectionList
@onready var item_list: ItemList = %ItemList
@onready var anim_option: OptionButton = %AnimOption
@onready var scale_slider: HSlider = %ScaleSlider
@onready var play_btn: Button = %PlayBtn
@onready var stop_btn: Button = %StopBtn
@onready var flip_btn: CheckButton = %FlipBtn
@onready var name_label: Label = %NameLabel
@onready var info_label: Label = %InfoLabel
@onready var preview_panel: PanelContainer = %PreviewPanel

var _catalog: Array = []
var _filtered: Array = []
var _sprite: AnimatedSprite2D
var _static: Sprite2D
var _door: Node2D
var _preview_root: Node2D


func _ready() -> void:
	theme = TinyThemeFactory.build()
	_preview_root = Node2D.new()
	_preview_root.name = "PreviewRoot"
	preview_panel.add_child(_preview_root)
	_sprite = AnimatedSprite2D.new()
	_static = Sprite2D.new()
	_preview_root.add_child(_sprite)
	_preview_root.add_child(_static)
	_static.visible = false
	preview_panel.resized.connect(_center_preview)
	_center_preview()

	_load_catalog()
	section_list.clear()
	for s in SECTIONS:
		section_list.add_item(str(s["title"]))
	section_list.item_selected.connect(_on_section)
	item_list.item_selected.connect(_on_item)
	anim_option.item_selected.connect(_on_anim)
	scale_slider.value_changed.connect(_on_scale)
	play_btn.pressed.connect(func() -> void: _sprite.play())
	stop_btn.pressed.connect(func() -> void: _sprite.pause())
	flip_btn.toggled.connect(func(v: bool) -> void:
		_sprite.flip_h = v
		_static.flip_h = v
	)
	scale_slider.min_value = 1.0
	scale_slider.max_value = 6.0
	scale_slider.step = 0.5
	scale_slider.value = 2.0
	if section_list.item_count > 0:
		section_list.select(0)
		_on_section(0)


func _center_preview() -> void:
	if _preview_root == null:
		return
	var sz := preview_panel.size
	_preview_root.position = Vector2(sz.x * 0.5, sz.y * 0.55)


func _load_catalog() -> void:
	var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f == null:
		info_label.text = "Catalog missing"
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		info_label.text = "Catalog parse error"
		return
	_catalog = parsed


func _on_section(index: int) -> void:
	if index < 0 or index >= SECTIONS.size():
		return
	var spec: Dictionary = SECTIONS[index]
	_filtered.clear()
	item_list.clear()
	for e in _catalog:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if e.get("pack") == spec["pack"] and e.get("category") == spec["category"]:
			_filtered.append(e)
			item_list.add_item(str(e.get("id", "?")))
	if item_list.item_count > 0:
		item_list.select(0)
		_on_item(0)


func _on_item(index: int) -> void:
	if index < 0 or index >= _filtered.size():
		return
	var e: Dictionary = _filtered[index]
	name_label.text = str(e.get("id", ""))
	info_label.text = "%s | %s | frames %s | %s" % [
		e.get("pack", ""), e.get("frame_size", ""), e.get("frame_count", ""), e.get("purpose", "")
	]
	_show_resource(e)


func _show_resource(e: Dictionary) -> void:
	_sprite.visible = false
	_static.visible = false
	_sprite.stop()
	if _door != null:
		_door.queue_free()
		_door = null
	anim_option.clear()
	var res_path := str(e.get("resource", ""))
	var full := res_path if res_path.begins_with("res://") else "res://%s" % res_path
	if not ResourceLoader.exists(full):
		info_label.text += " | MISSING %s" % full
		return
	var res: Resource = load(full)
	var scl := Vector2.ONE * float(scale_slider.value)
	if res is SpriteFrames:
		_sprite.sprite_frames = res as SpriteFrames
		_sprite.visible = true
		_sprite.scale = scl
		var names := _sprite.sprite_frames.get_animation_names()
		for n in names:
			anim_option.add_item(String(n))
		var chosen := StringName()
		for prefer in [&"idle", &"run", &"closed"]:
			if _sprite.sprite_frames.has_animation(prefer):
				chosen = prefer
				break
		if chosen == StringName() and names.size() > 0:
			chosen = names[0]
		if chosen != StringName():
			_sprite.play(chosen)
			for i in names.size():
				if names[i] == chosen:
					anim_option.select(i)
					break
	elif res is Texture2D or res is AtlasTexture:
		_static.texture = res
		_static.visible = true
		_static.scale = scl
	if str(e.get("id", "")).begins_with("door."):
		_door = (load("res://scenes/assets/kings_and_pigs/basic_door.tscn") as PackedScene).instantiate()
		_preview_root.add_child(_door)
		_door.scale = scl


func _on_anim(index: int) -> void:
	if index < 0 or not _sprite.visible:
		return
	_sprite.play(StringName(anim_option.get_item_text(index)))


func _on_scale(v: float) -> void:
	var scl := Vector2.ONE * v
	_sprite.scale = scl
	_static.scale = scl
	if _door != null:
		_door.scale = scl
