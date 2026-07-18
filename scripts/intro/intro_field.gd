extends Node2D
## Intro exterior: click abandoned barracks to enter.

const MAP_W := 2048.0
const MAP_H := 1536.0
const BARRACKS_SCENE := "res://scenes/intro/intro_barracks.tscn"
const REG_SCENE := "res://scenes/intro/guildmaster_registration.tscn"
const GM_SCENE := "res://scenes/characters/guildmaster.tscn"
const BARRACKS_TEX := "res://assets/tiny_swords/buildings/blue/Barracks.png"

@onready var world: Node2D = %World
@onready var camera: Camera2D = %Camera2D
@onready var skip_btn: Button = %BtnSkip
@onready var building_label: Label = %BuildingLabel

var _gm: Node2D
var _barracks: Sprite2D
var _barracks_click: ClickableTarget
var _skip_confirm: ConfirmationDialog
var _busy := false


func _ready() -> void:
	MusicController.leave_menu_context()
	FieldWorld.fill_field(world, "left")
	_place_barracks()
	_spawn_gm()
	camera.position = Vector2(MAP_W * 0.45, MAP_H * 0.55)
	camera.make_current()
	skip_btn.theme = TinySwordsThemeFactory.build()
	skip_btn.text = tr("intro.skip")
	skip_btn.pressed.connect(_on_skip_pressed)
	building_label.text = tr("intro.abandoned_barracks")


func _place_barracks() -> void:
	var buildings := Node2D.new()
	buildings.name = "Buildings"
	buildings.y_sort_enabled = true
	world.add_child(buildings)
	_barracks = Sprite2D.new()
	_barracks.name = "Barracks"
	_barracks.texture = load(BARRACKS_TEX) as Texture2D
	_barracks.centered = true
	_barracks.position = Vector2(1550, 720)
	if _barracks.texture:
		_barracks.offset = Vector2(0, -_barracks.texture.get_height() * 0.5)
	buildings.add_child(_barracks)

	var tw := _barracks.texture.get_width() if _barracks.texture else 160
	var th := _barracks.texture.get_height() if _barracks.texture else 160
	_barracks_click = ClickableTarget.new()
	_barracks_click.name = "BarracksClick"
	_barracks.add_child(_barracks_click)
	_barracks_click.setup(_barracks, Vector2(tw, th), Vector2(0, -th * 0.5))
	_barracks_click.clicked.connect(_on_barracks_clicked)


func _spawn_gm() -> void:
	var chars := Node2D.new()
	chars.name = "Characters"
	chars.y_sort_enabled = true
	world.add_child(chars)
	_gm = (load(GM_SCENE) as PackedScene).instantiate()
	_gm.position = Vector2(700, 720)
	chars.add_child(_gm)


func _on_barracks_clicked() -> void:
	if _busy or _gm == null:
		return
	_busy = true
	if _barracks_click != null:
		_barracks_click.set_click_enabled(false)
	var entrance := Vector2(1500, 700)
	await _gm.walk_to(entrance)
	await _gm.play_enter_building()
	await SceneTransition.change_scene(BARRACKS_SCENE)


func _on_skip_pressed() -> void:
	if _skip_confirm == null:
		_skip_confirm = ConfirmationDialog.new()
		_skip_confirm.theme = TinySwordsThemeFactory.build()
		add_child(_skip_confirm)
		_skip_confirm.confirmed.connect(_do_skip)
	_skip_confirm.title = tr("intro.skip")
	_skip_confirm.dialog_text = tr("intro.skip_confirm")
	_skip_confirm.ok_button_text = tr("intro.skip")
	_skip_confirm.get_cancel_button().text = tr("menu.cancel")
	_skip_confirm.popup_centered()


func _do_skip() -> void:
	_busy = true
	await SceneTransition.change_scene(REG_SCENE)
