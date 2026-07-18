extends Node2D
## Stage 3 Guild Hub: map, camera, UI stubs, GM patrol.

const MAP_W := 2048.0
const MAP_H := 1536.0
const GM_SCENE := "res://scenes/characters/guildmaster.tscn"

@onready var world: Node2D = %World
@onready var camera: Camera2D = %HubCamera
@onready var top_bar: PanelContainer = %TopBar
@onready var guild_title: Label = %GuildTitle
@onready var resources_label: Label = %ResourcesLabel
@onready var day_label: Label = %DayLabel
@onready var btn_end_day: Button = %BtnEndDay
@onready var bottom_nav: HBoxContainer = %BottomNav
@onready var toast: Label = %Toast

var _gm: Node2D
var _info: AcceptDialog
var _patrol_points: Array[Vector2] = []


func _ready() -> void:
	FieldWorld.fill_field(world, "left")
	_place_buildings()
	_spawn_gm()
	_setup_ui()
	camera.position = Vector2(1400, 720)
	await get_tree().process_frame
	_show_founded_toast()
	_patrol_loop()


func _place_buildings() -> void:
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	buildings.y_sort_enabled = true
	world.add_child(buildings)

	var palette := CampaignState.guild_palette()
	var path := "res://assets/tiny_swords/buildings/%s/Barracks.png" % palette
	if not ResourceLoader.exists(path):
		path = "res://assets/tiny_swords/buildings/blue/Barracks.png"
	var spr := Sprite2D.new()
	spr.name = "Barracks"
	spr.texture = load(path) as Texture2D
	spr.centered = true
	spr.position = Vector2(1450, 720)
	if spr.texture:
		spr.offset = Vector2(0, -spr.texture.get_height() * 0.5)
	buildings.add_child(spr)

	var reception := Marker2D.new()
	reception.name = "ReceptionSpot"
	reception.position = Vector2(1280, 780)
	world.add_child(reception)

	_patrol_points = [
		Vector2(1200, 780),
		Vector2(1450, 820),
		Vector2(1600, 760),
		Vector2(1320, 700),
	]


func _spawn_gm() -> void:
	var chars := Node2D.new()
	chars.name = "Characters"
	chars.y_sort_enabled = true
	world.add_child(chars)
	_gm = (load(GM_SCENE) as PackedScene).instantiate()
	_gm.position = Vector2(1380, 800)
	chars.add_child(_gm)
	if _gm.has_method("set_palette_frames"):
		_gm.set_palette_frames(CampaignState.guild_palette())


func _setup_ui() -> void:
	var theme := TinyThemeFactory.build()
	top_bar.theme = theme
	guild_title.text = CampaignState.guild_display_name()
	resources_label.text = tr("hub.resources_stub") % [0, 0, 0, 0, 0]
	var day := int(CampaignState.time.get("day", 1))
	day_label.text = tr("hub.day") % day
	btn_end_day.text = tr("hub.end_day")
	btn_end_day.pressed.connect(_on_end_day)

	for child in bottom_nav.get_children():
		child.queue_free()
	var keys := [
		"hub.nav.guild", "hub.nav.heroes", "hub.nav.parties",
		"hub.nav.quests", "hub.nav.build", "hub.nav.world",
	]
	for k in keys:
		var b := Button.new()
		b.text = tr(k)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_nav_stub)
		bottom_nav.add_child(b)


func _show_founded_toast() -> void:
	toast.text = tr("guild_creation.founded") % CampaignState.guild_display_name()
	toast.visible = true
	await get_tree().create_timer(3.5).timeout
	toast.visible = false


func _on_end_day() -> void:
	_popup(tr("hub.end_day"), tr("hub.later"))


func _on_nav_stub() -> void:
	_popup(tr("hub.section"), tr("hub.section_later"))


func _popup(title_text: String, body: String) -> void:
	if _info == null:
		_info = AcceptDialog.new()
		_info.theme = TinyThemeFactory.build()
		add_child(_info)
	_info.title = title_text
	_info.dialog_text = body
	_info.ok_button_text = tr("menu.ok")
	_info.popup_centered()


func _patrol_loop() -> void:
	if _gm == null or _patrol_points.is_empty():
		return
	while is_instance_valid(_gm):
		for p in _patrol_points:
			if not is_instance_valid(_gm):
				return
			await _gm.walk_to(p)
			await get_tree().create_timer(1.2).timeout
