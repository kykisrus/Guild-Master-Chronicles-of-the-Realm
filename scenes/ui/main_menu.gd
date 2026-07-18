extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle: Label = %Subtitle
@onready var btn_continue: Button = %BtnContinue
@onready var btn_new: Button = %BtnNew
@onready var btn_load: Button = %BtnLoad
@onready var btn_settings: Button = %BtnSettings
@onready var btn_credits: Button = %BtnCredits
@onready var btn_quit: Button = %BtnQuit
@onready var status: Label = %Status
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var continue_panel: PanelContainer = %ContinuePanel
@onready var credits_panel: PanelContainer = %CreditsPanel
@onready var slot_list: VBoxContainer = %SlotList
@onready var chk_tutorial: CheckButton = %ChkTutorial
@onready var slider_volume: HSlider = %SliderVolume
@onready var chk_fullscreen: CheckButton = %ChkFullscreen
@onready var background: TextureRect = $Background
@onready var menu_card: PanelContainer = $Center/MenuCard
@onready var last_save_panel: PanelContainer = %LastSavePanel
@onready var last_save_content: VBoxContainer = %LastSaveContent
@onready var menu_area: MarginContainer = $Center
@onready var top_logo: TextureRect = $TopLogo
@onready var menu_box: VBoxContainer = $Center/MenuCard/MenuBox

var latest_slot: int = 0


func _ready() -> void:
	MusicController.enter_menu_context()
	theme = UIStyle.create_theme()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	background.modulate = Color.WHITE
	menu_card.add_theme_stylebox_override("panel", UIStyle.kenney_frame_style(UIStyle.WARNING, 11, 18, UIStyle.BG_DARKEST))
	last_save_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(Color("151B25E8"), Color("4A586D"), 14, 1))
	var kicker: Label = $Center/MenuCard/MenuBox/Kicker
	kicker.add_theme_color_override("font_color", UIStyle.WARNING)
	kicker.add_theme_font_size_override("font_size", 10)
	$Center/MenuCard/MenuBox/Flavor.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	$Version.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	$LastSavePanel/LastSaveVBox/LastSaveKicker.add_theme_color_override("font_color", UIStyle.INFO)
	$LastSavePanel/LastSaveVBox/LastSaveKicker.add_theme_font_size_override("font_size", 10)
	title_label.text = "Guild Master"
	title_label.add_theme_color_override("font_color", UIStyle.TEXT_H)
	title_label.add_theme_font_size_override("font_size", 48)
	subtitle.text = "Chronicles of the Realm"
	subtitle.add_theme_color_override("font_color", UIStyle.INFO)
	btn_continue.disabled = not SaveLoad.has_any_save()
	btn_continue.pressed.connect(_on_continue)
	btn_new.pressed.connect(_on_new)
	btn_load.pressed.connect(_on_load)
	btn_settings.pressed.connect(_on_settings)
	btn_credits.pressed.connect(_on_credits)
	btn_quit.pressed.connect(_on_quit)
	settings_panel.visible = false
	continue_panel.visible = false
	credits_panel.visible = false
	settings_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.BG_PANEL, UIStyle.INFO, 10, 2))
	continue_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.BG_PANEL, UIStyle.INFO, 10, 2))
	credits_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.GLASS, UIStyle.WARNING, 12, 2))
	$CreditsPanel/CreditsVBox/CreditsKicker.add_theme_color_override("font_color", UIStyle.INFO)
	$CreditsPanel/CreditsVBox/CreditsAuthor.add_theme_color_override("font_color", UIStyle.WARNING)
	chk_tutorial.button_pressed = Settings.show_tutorial
	slider_volume.value = Settings.master_volume
	chk_fullscreen.button_pressed = Settings.fullscreen
	status.text = ""
	_style_menu_buttons()
	_rebuild_last_save()
	_apply_responsive_layout()
	UIStyle.polish_interactives(self)


func _apply_responsive_layout() -> void:
	var width := get_viewport_rect().size.x
	var height := get_viewport_rect().size.y
	var compact := width < 1000.0
	var short := height < 720.0
	last_save_panel.visible = not compact and not _has_open_overlay()
	if compact:
		menu_area.anchor_left = 0.08
		menu_area.anchor_right = 0.72
		top_logo.anchor_right = 0.86
	else:
		menu_area.anchor_left = 0.04
		menu_area.anchor_right = 0.34
		top_logo.anchor_right = 0.58
	menu_area.anchor_top = 0.29 if short else 0.38
	menu_area.anchor_bottom = 0.99 if short else 0.95
	top_logo.anchor_bottom = 0.28 if short else 0.37
	menu_box.add_theme_constant_override("separation", 6 if short else 12)
	for button in [btn_continue, btn_new, btn_load, btn_settings, btn_credits, btn_quit]:
		button.custom_minimum_size.y = 36 if short else 44


func _style_menu_buttons() -> void:
	btn_continue.custom_minimum_size = Vector2(0, 44)
	btn_new.custom_minimum_size = Vector2(0, 44)
	btn_load.custom_minimum_size = Vector2(0, 44)
	btn_settings.custom_minimum_size = Vector2(0, 44)
	btn_credits.custom_minimum_size = Vector2(0, 44)
	btn_quit.custom_minimum_size = Vector2(0, 44)
	## Primary CTA
	btn_new.add_theme_stylebox_override("normal", UIStyle.make_flat_style(Color("1F6B45"), UIStyle.SUCCESS, 8, 1))
	btn_new.add_theme_stylebox_override("hover", UIStyle.make_flat_style(Color("248A55"), UIStyle.SUCCESS.lightened(0.1), 8, 1))
	btn_continue.add_theme_stylebox_override("normal", UIStyle.make_flat_style(Color("1A5A6B"), UIStyle.INFO, 8, 1))
	btn_quit.add_theme_stylebox_override("normal", UIStyle.make_flat_style(Color("6B2A2A"), UIStyle.DANGER, 8, 1))
	for b in [btn_continue, btn_new, btn_load, btn_settings, btn_credits, btn_quit]:
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", UIStyle.TEXT_H)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_continue.text = "  ▶   ПРОДОЛЖИТЬ                                      →"
	btn_new.text = "  +   НОВАЯ ИГРА"
	btn_load.text = "  ▤   ЗАГРУЗИТЬ ИГРУ"
	btn_settings.text = "  ⚙   НАСТРОЙКИ"
	btn_credits.text = "  i   АВТОРЫ"
	btn_quit.text = "  ×   ВЫХОД"


func _on_continue() -> void:
	if latest_slot <= 0:
		status.text = "Нет доступных сохранений. Начните новую игру."
		return
	_set_menu_enabled(false)
	btn_continue.text = "Загрузка..."
	var err: String = SaveLoad.load_game(latest_slot)
	if err != "":
		status.text = err
		btn_continue.text = "Продолжить"
		_set_menu_enabled(true)
		return
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")


func _set_menu_enabled(enabled: bool) -> void:
	for button in [btn_continue, btn_new, btn_load, btn_settings, btn_credits, btn_quit]:
		button.disabled = not enabled


func _saved_crest_color(color_id: String) -> Color:
	var f := FileAccess.open("res://data/crests.json", FileAccess.READ)
	if f == null:
		return UIStyle.INFO
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return UIStyle.INFO
	for color in parsed.get("colors", []):
		if str(color.get("id", "")) == color_id:
			return Color(str(color.get("hex", "#2CB7D9")))
	return UIStyle.INFO


func _rebuild_last_save() -> void:
	for child in last_save_content.get_children():
		child.queue_free()
	latest_slot = SaveLoad.latest_save_slot()
	if latest_slot == 0:
		last_save_content.add_child(UIStyle.section_title("История ещё не началась", 20))
		last_save_content.add_child(UIStyle.body_label(
			"Основав гильдию, вы увидите здесь её состояние и сможете одним нажатием вернуться к управлению.",
			true
		))
		last_save_content.add_child(UIStyle.status_badge("Нет сохранений", UIStyle.TEXT_DIM))
		btn_continue.tooltip_text = "Нет доступных сохранений. Начните новую игру."
		return

	var data := SaveLoad.slot_metadata(latest_slot)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var crest := CrestIcon.new()
	crest.custom_minimum_size = Vector2(66, 76)
	crest.setup_full({
		"primary": _saved_crest_color(str(data.get("guild_crest_color", "crimson"))),
		"secondary": _saved_crest_color(str(data.get("guild_crest_secondary_color", "ivory"))),
		"charge": _saved_crest_color(str(data.get("guild_crest_charge_color", "gold"))),
		"emblem": str(data.get("guild_crest_emblem", "star")),
		"pattern": str(data.get("guild_crest_pattern", "solid")),
		"shield": str(data.get("guild_crest_shield", "heater")),
		"border": str(data.get("guild_crest_border", "gold_simple")),
	})
	header.add_child(crest)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UIStyle.section_title(str(data.get("guild_name", "Гильдия")), 22))
	identity.add_child(UIStyle.body_label("Слот %d · Свободные Земли" % latest_slot, true))
	identity.add_child(UIStyle.body_label("Сохранено: %s" % str(data.get("saved_at", "неизвестно")), true))
	header.add_child(identity)
	last_save_content.add_child(header)

	var time: Dictionary = data.get("time", {})
	var day := int(time.get("day", 1))
	var season: String = ["Весна", "Лето", "Осень", "Зима"][int((day - 1) / 90) % 4]
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 8)
	stats.add_theme_constant_override("v_separation", 8)
	stats.add_child(UIStyle.resource_chip("Дата", "%s · д.%d · г.%d" % [season, day, int(time.get("year", 1))], UIStyle.INFO))
	stats.add_child(UIStyle.resource_chip("Уровень", str(int(data.get("guild_level", 1))), UIStyle.SUCCESS))
	stats.add_child(UIStyle.resource_chip("Золото", str(int(data.get("gold", 0))), UIStyle.GOLD))
	stats.add_child(UIStyle.resource_chip("Мана", str(int(data.get("mana_crystals", 0))), UIStyle.MANA))
	stats.add_child(UIStyle.resource_chip("Слава", str(int(data.get("fame", 0))), UIStyle.WARNING))
	var heroes: Array = data.get("heroes", [])
	stats.add_child(UIStyle.resource_chip("Герои", "%d/%d" % [maxi(heroes.size() - 1, 0), int(data.get("roster_slots", 10))], UIStyle.SUCCESS))
	last_save_content.add_child(stats)

	var gm: Dictionary = {}
	for hero in heroes:
		if bool(hero.get("is_guildmaster", false)):
			gm = hero
			break
	if not gm.is_empty():
		last_save_content.add_child(UIStyle.eyebrow("Гильдмастер", UIStyle.WARNING))
		last_save_content.add_child(UIStyle.body_label("%s\n%s · Ур.%d · Ранг %s" % [
			str(gm.get("hero_name", "Неизвестный")),
			str(gm.get("class_display", gm.get("class_id", "Герой"))),
			int(gm.get("level", 1)),
			str(gm.get("rank", "E")),
		]))

	var warning_count := int(data.get("debt", 0) > 0) + int(data.get("food", 0) < 10)
	if warning_count > 0:
		last_save_content.add_child(UIStyle.status_badge("Потребуется внимание: %d" % warning_count, UIStyle.WARNING))
	else:
		last_save_content.add_child(UIStyle.status_badge("Гильдия действует штатно", UIStyle.SUCCESS))
	btn_continue.tooltip_text = "Продолжить игру за гильдию «%s»" % str(data.get("guild_name", "Гильдия"))


func _rebuild_slots() -> void:
	for c in slot_list.get_children():
		c.queue_free()
	for slot in range(1, SaveLoad.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		var info := Label.new()
		info.text = SaveLoad.slot_info(slot)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var load_btn := UIStyle.primary_button("Загрузить")
		load_btn.disabled = not SaveLoad.has_save(slot)
		var s := slot
		load_btn.pressed.connect(func():
			var err: String = SaveLoad.load_game(s)
			if err != "":
				status.text = err
				return
			get_tree().change_scene_to_file("res://scenes/game/main.tscn")
		)
		row.add_child(load_btn)
		slot_list.add_child(row)


func _on_load() -> void:
	_rebuild_slots()
	continue_panel.visible = true
	settings_panel.visible = false
	credits_panel.visible = false
	last_save_panel.visible = false


func _on_credits() -> void:
	continue_panel.visible = false
	settings_panel.visible = false
	credits_panel.visible = true
	last_save_panel.visible = false
	status.text = ""


func _on_new() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/new_game_setup.tscn")


func _on_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	continue_panel.visible = false
	credits_panel.visible = false
	last_save_panel.visible = false if settings_panel.visible else get_viewport_rect().size.x >= 1000.0


func _on_quit() -> void:
	get_tree().quit()


func _on_close_continue() -> void:
	continue_panel.visible = false
	_restore_last_save()


func _on_apply_settings() -> void:
	Settings.show_tutorial = chk_tutorial.button_pressed
	Settings.master_volume = slider_volume.value
	Settings.fullscreen = chk_fullscreen.button_pressed
	Settings.apply()
	Settings.save_settings()
	status.text = "Настройки сохранены"
	settings_panel.visible = false
	_restore_last_save()


func _on_close_settings() -> void:
	settings_panel.visible = false
	_restore_last_save()


func _on_close_credits() -> void:
	credits_panel.visible = false
	_restore_last_save()


func _has_open_overlay() -> bool:
	return continue_panel.visible or settings_panel.visible or credits_panel.visible


func _restore_last_save() -> void:
	last_save_panel.visible = get_viewport_rect().size.x >= 1000.0 and not _has_open_overlay()
