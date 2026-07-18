extends Control

## App Shell по UI/Guild_Master_UI_Visual_Concept.md

enum Tab {
	DASHBOARD, MAIL, GUILD, ROSTER, STAFF, PARTIES, QUESTS, TRAINING, TACTICS,
	RECRUIT, WORLD, TOURNAMENTS, STATISTICS, HALL, STORAGE, TRADE, FINANCES,
	JOURNAL, FORGE, LABORATORY, ARCHIVE, SAVE
}

var current_tab: int = Tab.DASHBOARD
var selected_hero_ids: Dictionary = {}
var selected_party_id: String = ""
var selected_quest_id: String = ""
var selected_hero_id: String = ""
var selected_candidate_id: String = ""
var hero_profile_tab: int = 0
var roster_detail_mode: bool = false
var make_gm_party: bool = false
var show_tutorial: bool = true
var roster_filter_class: String = "all"
var roster_filter_status: int = -1
var _tab_buttons: Array[Button] = []
var _nav_items: Array = [] ## {title, icon, tab}
var _page_title: String = "Обзор"
var _nav_history: Array[int] = []
var _nav_forward: Array[int] = []
var _compact_layout: bool = false
var staff_filter_role: String = "all"
var staff_min_skill: int = 0
var selected_world_location: String = "guild"
var dungeon_seed: int = 7301
var selected_dungeon_party_id: String = ""
var active_dungeon: DungeonData
var dungeon_simulation_open: bool = false
var dungeon_auto_running: bool = false
var dungeon_speed: int = 1
var dungeon_step_accumulator: float = 0.0
var dungeon_log: PackedStringArray = PackedStringArray()
var dungeon_resolved_rooms: PackedStringArray = PackedStringArray()

@onready var top_bar: PanelContainer = %TopBar
@onready var top_inner: HBoxContainer = %TopInner
@onready var tab_bar: VBoxContainer = %TabBar
@onready var content: ScrollContainer = %Content
@onready var status_label: Label = %StatusLabel
@onready var game_over_overlay: ColorRect = %GameOverOverlay
@onready var tutorial_panel: PanelContainer = %TutorialPanel
@onready var background: TextureRect = $Background
@onready var side_nav: PanelContainer = %SideNav
@onready var crest_slot: CenterContainer = %CrestSlot
@onready var guild_label: Label = %GuildLabel
@onready var guild_meta: Label = %GuildMeta
@onready var side_bottom: VBoxContainer = %SideBottom


func _ready() -> void:
	MusicController.leave_menu_context()
	theme = UIStyle.create_theme()
	background.modulate = Color("29313D")
	side_nav.add_theme_stylebox_override("panel", UIStyle.kenney_frame_style(UIStyle.WARNING.darkened(0.35), 11, 17, UIStyle.BG_DARKEST))
	top_bar.add_theme_stylebox_override("panel", UIStyle.kenney_frame_style(UIStyle.BORDER, 11, 17, UIStyle.BG_PANEL))
	GameState.state_changed.connect(_refresh)
	GameState.notifications_changed.connect(_refresh)
	GameState.game_over.connect(_on_game_over)
	GameState.quest_resolved.connect(_on_quest_report)
	TimeSystem.day_ended.connect(func(_d): _refresh())

	if GameState.heroes.is_empty() or GameState.get_guildmaster() == null:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return

	show_tutorial = Settings.show_tutorial and not GameState.tutorial_seen
	get_viewport().size_changed.connect(_on_viewport_resized)
	_update_layout_mode()
	_setup_nav_items()
	_build_tabs()
	_build_side_bottom()
	_ensure_game_over_menu()
	_refresh()
	tutorial_panel.visible = show_tutorial
	tutorial_panel.add_theme_stylebox_override("panel", UIStyle.kenney_frame_style(UIStyle.INFO, 11, 18, UIStyle.BG_PANEL))
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.position = Vector2(-310, -170)
	tutorial_panel.size = Vector2(620, 340)
	UIStyle.polish_interactives(self)


func _process(delta: float) -> void:
	if not dungeon_simulation_open or not dungeon_auto_running or active_dungeon == null or active_dungeon.completed:
		return
	dungeon_step_accumulator += delta * dungeon_speed
	if dungeon_step_accumulator >= 1.5:
		dungeon_step_accumulator = 0.0
		_advance_dungeon_simulation()


func _on_viewport_resized() -> void:
	var was_compact := _compact_layout
	_update_layout_mode()
	if was_compact != _compact_layout:
		_build_tabs()
	_refresh()


func _update_layout_mode() -> void:
	_compact_layout = get_viewport_rect().size.x < 1100.0
	side_nav.custom_minimum_size.x = UIStyle.SIDEBAR_COLLAPSED if _compact_layout else UIStyle.SIDEBAR_EXPANDED
	crest_slot.visible = not _compact_layout
	guild_label.visible = not _compact_layout
	guild_meta.visible = not _compact_layout


func _adaptive_row(separation: int = 12) -> BoxContainer:
	var box: BoxContainer = VBoxContainer.new() if _compact_layout else HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


func _setup_nav_items() -> void:
	_nav_items = [
		{"title": "Обзор", "tab": Tab.DASHBOARD},
		{"title": "Гильдия", "tab": Tab.GUILD},
		{"title": "Герои", "tab": Tab.ROSTER},
		{"title": "Отряды", "tab": Tab.PARTIES},
		{"title": "Доска заданий", "tab": Tab.QUESTS},
		{"title": "Рекрутинг", "tab": Tab.RECRUIT},
		{"title": "Карта мира", "tab": Tab.WORLD},
		{"title": "Гильд-холл", "tab": Tab.HALL},
		{"title": "Финансы", "tab": Tab.FINANCES},
		{"title": "Журнал", "tab": Tab.JOURNAL},
		{"title": "Сохранения", "tab": Tab.SAVE},
	]


func _build_side_bottom() -> void:
	for c in side_bottom.get_children():
		c.queue_free()
	var settings_btn := Button.new()
	settings_btn.text = "Настройки"
	settings_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	settings_btn.pressed.connect(_open_settings_dialog)
	side_bottom.add_child(settings_btn)
	var menu_btn := UIStyle.danger_button("В меню")
	menu_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_btn.pressed.connect(_confirm_return_to_menu)
	side_bottom.add_child(menu_btn)


func _open_settings_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Настройки"
	dialog.ok_button_text = "Применить"
	dialog.cancel_button_text = "Отмена"
	dialog.min_size = Vector2i(460, 300)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var tutorial := CheckButton.new()
	tutorial.text = "Показывать обучающие подсказки"
	tutorial.button_pressed = Settings.show_tutorial
	content.add_child(tutorial)
	content.add_child(UIStyle.body_label("Общая громкость", true))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = Settings.master_volume
	content.add_child(volume)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Полноэкранный режим"
	fullscreen.button_pressed = Settings.fullscreen
	content.add_child(fullscreen)
	dialog.add_child(content)
	dialog.confirmed.connect(func():
		Settings.show_tutorial = tutorial.button_pressed
		Settings.master_volume = volume.value
		Settings.fullscreen = fullscreen.button_pressed
		Settings.apply()
		Settings.save_settings()
		status_label.text = "Настройки применены"
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
	UIStyle.polish_interactives(dialog)


func _confirm_return_to_menu() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Вернуться в главное меню?"
	dialog.dialog_text = "Несохранённые изменения текущего дня будут потеряны."
	dialog.ok_button_text = "В главное меню"
	dialog.cancel_button_text = "Остаться"
	dialog.confirmed.connect(func():
		GameState.clear_campaign()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
	UIStyle.polish_interactives(dialog)


func _ensure_game_over_menu() -> void:
	if game_over_overlay.get_node_or_null("GOActions") != null:
		return
	var box := VBoxContainer.new()
	box.name = "GOActions"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-160, 40)
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 10)
	var menu_btn := UIStyle.primary_button("В главное меню")
	menu_btn.pressed.connect(func():
		GameState.clear_campaign()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	box.add_child(menu_btn)
	game_over_overlay.add_child(box)


func _build_tabs() -> void:
	for c in tab_bar.get_children():
		c.queue_free()
	_tab_buttons.clear()
	for i in _nav_items.size():
		var item: Dictionary = _nav_items[i]
		var btn := Button.new()
		var title: String = str(item["title"])
		btn.text = title.left(2).to_upper() if _compact_layout else title.to_upper()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		btn.pressed.connect(func(): _navigate_to_index(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)


func _navigate_to_index(idx: int) -> void:
	if idx < 0 or idx >= _nav_items.size():
		return
	var item: Dictionary = _nav_items[idx]
	_nav_history.append(current_tab)
	_nav_forward.clear()
	current_tab = int(item["tab"])
	_page_title = str(item["title"])
	_refresh()


func _set_tab(tab_id: int) -> void:
	for i in _nav_items.size():
		if int(_nav_items[i]["tab"]) == tab_id:
			_navigate_to_index(i)
			return
	current_tab = tab_id
	_refresh()


func _highlight_tabs() -> void:
	for i in _tab_buttons.size():
		var b: Button = _tab_buttons[i]
		var item: Dictionary = _nav_items[i]
		var active := current_tab == int(item["tab"])
		if active:
			b.add_theme_stylebox_override("normal", UIStyle.kenney_frame_style(UIStyle.INFO, 19, 10, Color("183B4A")))
			b.add_theme_color_override("font_color", UIStyle.TEXT_H)
		else:
			b.add_theme_stylebox_override("normal", UIStyle.surface_style(UIStyle.BG_DARKEST, UIStyle.BORDER_SOFT, 1, 10))
			b.add_theme_color_override("font_color", UIStyle.TEXT_DIM)


func _refresh_side_crest() -> void:
	for c in crest_slot.get_children():
		c.queue_free()
	var crest := CrestIcon.new()
	crest.custom_minimum_size = Vector2(76, 84)
	crest.setup_full(GameState.get_crest_config())
	crest_slot.add_child(crest)
	guild_label.text = GameState.guild_name
	guild_label.add_theme_color_override("font_color", UIStyle.TEXT_H)
	guild_meta.text = "Ур. %d  ·  слоты %d/%d" % [
		GameState.guild_level, GameState.living_roster_count(), GameState.roster_slots,
	]
	guild_meta.add_theme_color_override("font_color", UIStyle.TEXT_DIM)


func _refresh() -> void:
	_refresh_top()
	_refresh_side_crest()
	_highlight_tabs()
	for c in content.get_children():
		c.queue_free()
	match current_tab:
		Tab.DASHBOARD:
			_page_title = "Обзор"
			_add_page(_build_dashboard())
		Tab.ROSTER:
			_page_title = "Герои"
			_add_page(_build_roster())
		Tab.MAIL:
			_page_title = "Почта и события"
			_add_page(_build_mail())
		Tab.GUILD:
			_page_title = "Гильдия"
			_add_page(_build_guild_profile())
		Tab.STAFF:
			_page_title = "Персонал"
			_add_page(_build_staff())
		Tab.HALL:
			_page_title = "Гильд-холл"
			_add_page(_build_hall())
		Tab.PARTIES:
			_page_title = "Отряды"
			_add_page(_build_parties())
		Tab.QUESTS:
			_page_title = "Квесты"
			_add_page(_build_quests())
		Tab.RECRUIT:
			_page_title = "Рекрутинг"
			_add_page(_build_recruit())
		Tab.TRAINING:
			_page_title = "Тренировки"
			_add_page(_build_facility("arena", "Тренировочная арена", "Провести тренировку"))
		Tab.TACTICS:
			_page_title = "Тактики"
			_add_page(_build_tactics())
		Tab.WORLD:
			_page_title = "Карта мира"
			_add_page(_build_world())
		Tab.TOURNAMENTS:
			_page_title = "Турниры"
			_add_page(_build_tournaments())
		Tab.STATISTICS:
			_page_title = "Статистика"
			_add_page(_build_statistics())
		Tab.FORGE:
			_page_title = "Кузница"
			_add_page(_build_facility("forge", "Кузница", "Создать комплект снаряжения"))
		Tab.LABORATORY:
			_page_title = "Лаборатория"
			_add_page(_build_facility("laboratory", "Магическая лаборатория", "Начать исследование"))
		Tab.ARCHIVE:
			_page_title = "Архив"
			_add_page(_build_facility("library", "Архив знаний", "Восстановить хронику"))
		Tab.STORAGE:
			_page_title = "Склад"
			_add_page(_build_storage())
		Tab.TRADE:
			_page_title = "Торговля"
			_add_page(_build_trade())
		Tab.FINANCES:
			_page_title = "Финансы"
			_add_page(_build_finances())
		Tab.JOURNAL:
			_page_title = "Журнал"
			_add_page(_build_journal())
		Tab.SAVE:
			_page_title = "Сохранения"
			_add_page(_build_save())
	game_over_overlay.visible = GameState.is_game_over
	call_deferred("_polish_buttons")


func _add_page(page: Control) -> void:
	var frame := MarginContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_constant_override("margin_left", UIStyle.SPACE_L)
	frame.add_theme_constant_override("margin_top", UIStyle.SPACE_L)
	frame.add_theme_constant_override("margin_right", UIStyle.SPACE_L)
	frame.add_theme_constant_override("margin_bottom", UIStyle.SPACE_L)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(page)
	content.add_child(frame)


func _polish_buttons() -> void:
	UIStyle.polish_interactives(self)


func _has_day_warnings() -> bool:
	for p in GameState.parties:
		if p is PartyData and p.on_mission and p.days_remaining <= 1:
			return true
	if GameState.debt > 0 or GameState.food < 10:
		return true
	return false


func _scouting_forecast(chance: float) -> Dictionary:
	if chance >= 0.78:
		return {"text": "Очень высокая", "color": UIStyle.SUCCESS}
	if chance >= 0.62:
		return {"text": "Высокая", "color": UIStyle.SUCCESS}
	if chance >= 0.43:
		return {"text": "Неопределённая", "color": UIStyle.WARNING}
	if chance >= 0.25:
		return {"text": "Низкая", "color": UIStyle.DANGER}
	return {"text": "Крайне низкая", "color": UIStyle.DANGER}


func _refresh_top() -> void:
	for c in top_inner.get_children():
		c.queue_free()

	var back := Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(36, 36)
	back.disabled = _nav_history.is_empty()
	back.pressed.connect(func():
		if _nav_history.is_empty():
			return
		_nav_forward.append(current_tab)
		var prev: int = _nav_history.pop_back()
		current_tab = prev
		_refresh()
	)
	top_inner.add_child(back)

	var title := Label.new()
	title.text = _page_title
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UIStyle.TEXT_H)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_inner.add_child(title)

	top_inner.add_child(UIStyle.resource_chip("" if _compact_layout else "Золото", str(GameState.gold), UIStyle.GOLD))
	top_inner.add_child(UIStyle.resource_chip("" if _compact_layout else "Мана", str(GameState.mana_crystals), UIStyle.MANA))
	top_inner.add_child(UIStyle.resource_chip("" if _compact_layout else "Слава", str(GameState.fame), UIStyle.WARNING))
	top_inner.add_child(UIStyle.resource_chip("" if _compact_layout else "Еда", str(GameState.food), UIStyle.SUCCESS))

	var date_box := VBoxContainer.new()
	var d1 := Label.new()
	d1.text = TimeSystem.season_name()
	d1.add_theme_font_size_override("font_size", 11)
	d1.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	d1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_box.add_child(d1)
	var d2 := Label.new()
	d2.text = "Год %d · день %d" % [TimeSystem.year, TimeSystem.day]
	d2.add_theme_font_size_override("font_size", 13)
	d2.add_theme_color_override("font_color", UIStyle.TEXT_H)
	d2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_box.add_child(d2)
	if not _compact_layout:
		top_inner.add_child(date_box)

	var gm := GameState.get_guildmaster()
	if gm:
		var gm_chip := UIStyle.status_badge(gm.rank, UIStyle.rank_color(gm.rank))
		top_inner.add_child(gm_chip)

	var end_btn := UIStyle.end_day_button(_has_day_warnings(), GameState.is_game_over)
	end_btn.disabled = GameState.is_game_over
	end_btn.text = "ДЕНЬ" if _compact_layout else end_btn.text
	end_btn.custom_minimum_size = Vector2(76 if _compact_layout else 160, 36)
	end_btn.pressed.connect(_on_end_day)
	top_inner.add_child(end_btn)


func _quick_actions() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 10)
	var actions := [
		["ОТРЯД", Tab.PARTIES],
		["ЗАДАНИЯ", Tab.QUESTS],
		["НАЙМ", Tab.RECRUIT],
		["ХОЛЛ", Tab.HALL],
	]
	for a in actions:
		var b := Button.new()
		b.text = str(a[0])
		b.custom_minimum_size = Vector2(136, 48)
		b.add_theme_font_size_override("font_size", 14)
		var tab_idx: int = int(a[1])
		b.pressed.connect(func(): _set_tab(tab_idx))
		row.add_child(b)
	return row


func _build_dashboard() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.add_child(UIStyle.section_title("Обзор гильдии"))
	root.add_child(_quick_actions())

	var summary := HFlowContainer.new()
	summary.add_theme_constant_override("separation", 8)
	summary.add_child(UIStyle.status_badge("★  Уровень %d" % GameState.guild_level, UIStyle.INFO))
	summary.add_child(UIStyle.status_badge("♟  Герои %d/%d" % [GameState.living_roster_count(), GameState.roster_slots], UIStyle.SUCCESS))
	summary.add_child(UIStyle.status_badge("♛  Слава %d" % GameState.fame, UIStyle.WARNING))
	if GameState.debt > 0:
		summary.add_child(UIStyle.status_badge("Долг %d" % GameState.debt, UIStyle.DANGER))
	root.add_child(summary)

	var cols := _adaptive_row(12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)

	## Left: GM card
	var left := UIStyle.card()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lv := VBoxContainer.new()
	left.add_child(lv)
	lv.add_child(UIStyle.section_title("♛  Гильдмастер", 18))
	var gm := GameState.get_guildmaster()
	if gm:
		var crest_row := HBoxContainer.new()
		crest_row.add_theme_constant_override("separation", 12)
		var portrait_view := TextureRect.new()
		portrait_view.custom_minimum_size = Vector2(92, 116)
		portrait_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if ResourceLoader.exists(gm.portrait_id):
			portrait_view.texture = load(gm.portrait_id)
		crest_row.add_child(portrait_view)
		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_col.add_child(UIStyle.body_label("%s\n%s · Ур.%d · Ранг %s" % [gm.display_name().trim_suffix(" (ГМ)"), gm.class_name_ru(), gm.level, gm.rank]))
		crest_row.add_child(info_col)
		lv.add_child(crest_row)
		lv.add_child(UIStyle.body_label("Дипломатия %d  ·  Харизма %d\nВлияние %d  ·  Лидерство %d" % [
			int(gm.primary_management_stats.get("diplomacy", 5)), int(gm.primary_management_stats.get("charisma", 5)),
			int(gm.primary_management_stats.get("influence", 5)), int(gm.primary_management_stats.get("leadership", 5)),
		], true))
		var mark := Label.new()
		mark.text = gm.rank
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.add_theme_font_size_override("font_size", 28)
		mark.add_theme_color_override("font_color", UIStyle.rank_color(gm.rank))
		lv.add_child(mark)
		var details := UIStyle.info_button("Подробнее")
		details.pressed.connect(func(): selected_hero_id = gm.id; roster_detail_mode = true; _set_tab(Tab.ROSTER))
		lv.add_child(details)
	cols.add_child(left)

	## Center: hall teaser + missions
	var mid := UIStyle.card()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mv := VBoxContainer.new()
	mid.add_child(mv)
	mv.add_child(UIStyle.section_title("♜  Гильд-холл", 18))
	var hall_vis := _pixel_hall_preview()
	mv.add_child(hall_vis)
	mv.add_child(UIStyle.body_label("Уровень гильдии: %d\nПостроек: 2 / 10\nДоступно улучшение: Зал гильдии" % GameState.guild_level, true))
	var open_hall := UIStyle.info_button("Открыть зал")
	open_hall.pressed.connect(func(): _set_tab(Tab.HALL))
	mv.add_child(open_hall)
	var mission_count := 0
	for p in GameState.parties:
		if p is PartyData and p.on_mission:
			mission_count += 1
	mv.add_child(UIStyle.body_label("▤  Активные квесты: %d\n♢  Свободные отряды: %d\n♟  Герои в гильдии: %d/%d" % [
		mission_count, maxi(0, GameState.parties.size() - mission_count),
		GameState.living_roster_count(), GameState.roster_slots,
	], true))
	cols.add_child(mid)

	## Right: notifications / calendar feel
	var right := UIStyle.card()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := VBoxContainer.new()
	right.add_child(rv)
	rv.add_child(UIStyle.section_title("▤  Лента событий", 18))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 260)
	var notes := VBoxContainer.new()
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(notes)
	var list: PackedStringArray = GameState.notifications
	for i in range(list.size() - 1, -1, -1):
		var event_icon := "✦"
		if "квест" in list[i].to_lower():
			event_icon = "▤"
		elif "гильд" in list[i].to_lower():
			event_icon = "♜"
		elif "предуп" in list[i].to_lower():
			event_icon = "!"
		notes.add_child(UIStyle.body_label("%s  %s" % [event_icon, list[i]], i < list.size() - 3))
	rv.add_child(scroll)
	if not GameState.last_report.is_empty():
		rv.add_child(UIStyle.section_title("Отчёт", 16))
		rv.add_child(UIStyle.body_label(str(GameState.last_report.get("text", "")), true))
	var journal := Button.new()
	journal.text = "Открыть журнал"
	journal.pressed.connect(func(): _set_tab(Tab.JOURNAL))
	rv.add_child(journal)
	cols.add_child(right)

	root.add_child(cols)
	return root


func _pixel_hall_preview() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0, 152)
	preview.clip_contents = true
	var tile_size := Vector2(48, 48)
	for y in 3:
		for x in 7:
			var tile := TextureRect.new()
			tile.texture = load("res://assets/kenney/minimap/tile_%04d.png" % (6 + (x + y) % 10))
			tile.position = Vector2(x, y) * tile_size
			tile.size = tile_size
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.modulate = Color(1, 1, 1, 0.58)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.add_child(tile)
	var castle := TextureRect.new()
	castle.texture = load("res://assets/kenney/cartography/castle.png")
	castle.position = Vector2(126, 20)
	castle.size = Vector2(96, 112)
	castle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	castle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	castle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(castle)
	return preview


func _build_roster() -> Control:
	if roster_detail_mode:
		return _build_roster_full_detail()
	return _build_roster_table()


func _build_roster_table() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	page.add_child(UIStyle.section_title("Герои — %d/%d" % [GameState.living_roster_count(), GameState.roster_slots]))
	page.add_child(_roster_summary())
	page.add_child(_roster_filters())

	var table := UIStyle.card()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var table_box := VBoxContainer.new()
	table.add_child(table_box)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 36
	header.add_child(_table_cell("Имя", 260, true))
	header.add_child(_table_cell("Класс", 150, true))
	header.add_child(_table_cell("Ранг", 80, true))
	header.add_child(_table_cell("Состояние", 170, true))
	header.add_child(_table_cell("Статус", 130, true))
	header.add_child(_table_cell("", 130, true))
	table_box.add_child(header)
	var rule := HSeparator.new()
	table_box.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.name = "HeroesTableScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var rows := VBoxContainer.new()
	rows.name = "HeroesTableRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 4)
	scroll.add_child(rows)
	for hero in GameState.heroes:
		if hero is HeroData and _hero_matches_filter(hero):
			rows.add_child(_hero_table_row(hero))
	if rows.get_child_count() == 0:
		var empty := VBoxContainer.new()
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		empty.custom_minimum_size.y = 220
		empty.add_child(UIStyle.body_label("В гильдии пока нет героев по выбранному фильтру.", true))
		var recruit := UIStyle.primary_button("Перейти в рекрутинг")
		recruit.pressed.connect(func(): _set_tab(Tab.RECRUIT))
		empty.add_child(recruit)
		rows.add_child(empty)
	table_box.add_child(scroll)
	page.add_child(table)
	return page


func _table_cell(text: String, width: float, header: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if width >= 250 else Control.SIZE_SHRINK_BEGIN
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if header:
		label.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
		label.add_theme_font_size_override("font_size", 12)
	return label


func _hero_table_row(hero: HeroData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 58
	panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(
		UIStyle.BG_ACTIVE if hero.is_favorite else Color("18212D"),
		UIStyle.WARNING if hero.is_favorite else UIStyle.BORDER, 7, 1,
	))
	var row := HBoxContainer.new()
	panel.add_child(row)
	var favorite := "★  " if hero.is_favorite else ""
	row.add_child(_table_cell("%s%s" % [favorite, hero.display_name().trim_suffix(" (ГМ)")], 260))
	row.add_child(_table_cell(hero.class_name_ru(), 150))
	var rank := _table_cell(hero.rank, 80)
	rank.add_theme_color_override("font_color", UIStyle.rank_color(hero.rank))
	row.add_child(rank)
	row.add_child(_table_cell("Мораль %d · Энергия %d" % [hero.morale, maxi(0, 100 - hero.fatigue)], 170))
	var status := UIStyle.status_badge(UIStyle.status_text(hero.status), UIStyle.status_color(hero.status))
	status.custom_minimum_size.x = 130
	row.add_child(status)
	var details := Button.new()
	details.text = "Подробнее"
	details.custom_minimum_size.x = 130
	details.pressed.connect(func():
		selected_hero_id = hero.id
		selected_candidate_id = ""
		hero_profile_tab = 0
		roster_detail_mode = true
		_refresh()
	)
	row.add_child(details)
	return panel


func _build_roster_full_detail() -> Control:
	var page := VBoxContainer.new()
	page.name = "HeroFullDetails"
	page.add_theme_constant_override("separation", 10)
	var top := HBoxContainer.new()
	var back := Button.new()
	back.name = "HeroDetailsBack"
	back.text = "← Назад к списку"
	back.custom_minimum_size = Vector2(180, 42)
	back.pressed.connect(func(): roster_detail_mode = false; _refresh())
	top.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(UIStyle.eyebrow("ПОЛНАЯ КАРТОЧКА ГЕРОЯ", UIStyle.INFO))
	page.add_child(top)
	var card := UIStyle.card()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var content_box := VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 12)
	scroll.add_child(content_box)
	var hero := GameState.get_hero(selected_hero_id)
	if hero != null:
		_build_known_profile(content_box, hero)
	else:
		content_box.add_child(UIStyle.section_title("Герой не найден"))
		content_box.add_child(UIStyle.body_label("Вернитесь к списку и выберите другого героя.", true))
	page.add_child(card)
	return page


func _build_roster_legacy() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	page.add_child(UIStyle.section_title("Герои — %d/%d" % [GameState.living_roster_count(), GameState.roster_slots]))
	page.add_child(_roster_summary())

	var split := _adaptive_row(14)
	split.name = "HeroesContentSplit"
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := UIStyle.card()
	left.name = "HeroesListPanel"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.38
	left.custom_minimum_size.x = 320
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 8)
	left.add_child(left_box)
	left_box.add_child(_roster_filters())
	var scroll := ScrollContainer.new()
	scroll.name = "HeroesScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 410
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for hero in GameState.heroes:
		if hero is HeroData and _hero_matches_filter(hero):
			list.add_child(_hero_list_item(hero, true))
	if roster_filter_class == "all" and roster_filter_status < 0:
		for candidate in GameState.tavern_recruits:
			if candidate is HeroData:
				list.add_child(_hero_list_item(candidate, false))
	if list.get_child_count() == 0:
		list.add_child(UIStyle.body_label("Герои по выбранному фильтру не найдены.", true))
	left_box.add_child(scroll)
	split.add_child(left)

	var profile := UIStyle.card()
	profile.name = "HeroProfilePanel"
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.size_flags_stretch_ratio = 0.62
	profile.custom_minimum_size.x = 500
	var profile_scroll := ScrollContainer.new()
	profile_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	profile.add_child(profile_scroll)
	var profile_box := VBoxContainer.new()
	profile_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_box.add_theme_constant_override("separation", 10)
	profile_scroll.add_child(profile_box)
	var selected := GameState.get_hero(selected_hero_id)
	if selected != null:
		_build_known_profile(profile_box, selected)
	else:
		var candidate := _selected_candidate()
		if candidate != null:
			_build_unknown_profile(profile_box, candidate)
		else:
			profile_box.add_child(UIStyle.section_title("Карточка героя", 20))
			profile_box.add_child(UIStyle.body_label("Выберите героя в списке слева,\nчтобы просмотреть его характеристики.", true))
			var recruit := UIStyle.primary_button("Перейти в рекрутинг")
			recruit.pressed.connect(func(): _set_tab(Tab.RECRUIT))
			profile_box.add_child(recruit)
	split.add_child(profile)
	page.add_child(split)
	return page


func _roster_summary() -> Control:
	var summary := HFlowContainer.new()
	var morale := 0
	var living := 0
	var available := 0
	var wounded := 0
	var quests := 0
	for hero in GameState.heroes:
		if not (hero is HeroData) or hero.status == HeroData.Status.DEAD:
			continue
		living += 1
		morale += hero.morale
		available += 1 if hero.status == HeroData.Status.AVAILABLE else 0
		wounded += 1 if hero.status == HeroData.Status.HOSPITAL else 0
		quests += 1 if hero.status == HeroData.Status.ON_QUEST else 0
	summary.add_child(UIStyle.status_badge("Мораль %d" % (int(morale / maxi(1, living))), UIStyle.INFO))
	summary.add_child(UIStyle.status_badge("Свободно %d" % available, UIStyle.SUCCESS))
	summary.add_child(UIStyle.status_badge("Ранены %d" % wounded, UIStyle.DANGER))
	summary.add_child(UIStyle.status_badge("На заданиях %d" % quests, UIStyle.MANA))
	return summary


func _roster_filters() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("separation", 5)
	var options := [["all", "Все"]]
	for cid in GameState.classes_data:
		options.append([str(cid), str(GameState.classes_data[cid].get("name", cid))])
	for option in options:
		var button := Button.new()
		button.text = str(option[1])
		var class_id := str(option[0])
		button.pressed.connect(func(): roster_filter_class = class_id; roster_filter_status = -1; _refresh())
		if roster_filter_class == class_id and roster_filter_status < 0:
			button.add_theme_stylebox_override("normal", UIStyle.make_flat_style(UIStyle.BG_ACTIVE, UIStyle.WARNING, 7, 2))
		flow.add_child(button)
	for status_option in [[HeroData.Status.AVAILABLE, "Доступны"], [HeroData.Status.HOSPITAL, "Ранены"], [HeroData.Status.ON_QUEST, "На задании"]]:
		var button := Button.new()
		button.text = str(status_option[1])
		var status_id := int(status_option[0])
		button.pressed.connect(func(): roster_filter_class = "all"; roster_filter_status = status_id; _refresh())
		if roster_filter_status == status_id:
			button.add_theme_stylebox_override("normal", UIStyle.make_flat_style(UIStyle.BG_ACTIVE, UIStyle.INFO, 7, 2))
		flow.add_child(button)
	return flow


func _hero_matches_filter(hero: HeroData) -> bool:
	if hero.status == HeroData.Status.DEAD:
		return false
	if roster_filter_class != "all" and hero.class_id != roster_filter_class:
		return false
	return roster_filter_status < 0 or hero.status == roster_filter_status


func _hero_list_item(hero: HeroData, known: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 82)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = ("  %s\n  %s · Ур.%s · Ранг %s\n  %s" % [
		hero.display_name().trim_suffix(" (ГМ)") if known else _unknown_name(hero),
		hero.class_name_ru() if known or hero.known_level >= 2 else "Класс не установлен",
		str(hero.level) if known or hero.known_level >= 3 else "?", hero.rank,
		UIStyle.status_text(hero.status) if known else "Изучение %d/5" % hero.known_level,
	])
	if known and ResourceLoader.exists(hero.portrait_id):
		button.icon = load(hero.portrait_id)
		button.expand_icon = true
	var selected := selected_hero_id == hero.id if known else selected_candidate_id == hero.id
	if selected:
		button.add_theme_stylebox_override("normal", UIStyle.make_flat_style(UIStyle.BG_ACTIVE, UIStyle.WARNING, 8, 2))
	button.pressed.connect(func():
		selected_hero_id = hero.id if known else ""
		selected_candidate_id = "" if known else hero.id
		hero_profile_tab = 0
		_refresh()
	)
	return button


func _selected_candidate() -> HeroData:
	for candidate in GameState.tavern_recruits:
		if candidate is HeroData and candidate.id == selected_candidate_id:
			return candidate
	return null


func _unknown_name(hero: HeroData) -> String:
	var gender_word := "Неизвестная" if hero.gender == "female" and hero.known_level >= 2 else "Неизвестный"
	return "%s %s" % [gender_word, hero.class_name_ru().to_lower() if hero.known_level >= 2 else "наёмник"]


func _build_known_profile(root: VBoxContainer, hero: HeroData) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(150, 188)
	var frame_color := UIStyle.WARNING if hero.is_guildmaster else UIStyle.rank_color(hero.rank)
	portrait_frame.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.BG_ACTIVE, frame_color, 10, 3))
	if ResourceLoader.exists(hero.portrait_id):
		var texture := TextureRect.new()
		texture.texture = load(hero.portrait_id)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_frame.add_child(texture)
	else:
		var fallback := Label.new()
		fallback.text = hero.hero_name.left(1).to_upper()
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 52)
		portrait_frame.add_child(fallback)
	header.add_child(portrait_frame)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(UIStyle.section_title(hero.display_name().trim_suffix(" (ГМ)"), 22))
	identity.add_child(UIStyle.body_label("%s · Ур.%d · Ранг %s\n%s · %s\nСтатус: %s\nОтряд: %s" % [
		hero.class_name_ru(), hero.level, hero.rank, hero.origin, hero.home_kingdom,
		UIStyle.status_text(hero.status), _hero_party_name(hero.id),
	]))
	identity.add_child(UIStyle.body_label("Потенциал: %s" % ("★".repeat(hero.potential) + "☆".repeat(5 - hero.potential))))
	header.add_child(identity)
	root.add_child(header)
	root.add_child(_hero_condition_bars(hero))

	var tabs := HBoxContainer.new()
	tabs.name = "HeroProfileTabs"
	for tab_data in [[0, "Атрибуты"], [1, "Биография"], [2, "История"]]:
		var button := Button.new()
		button.text = str(tab_data[1])
		var tab_id := int(tab_data[0])
		button.pressed.connect(func(): hero_profile_tab = tab_id; _refresh())
		if hero_profile_tab == tab_id:
			button.add_theme_stylebox_override("normal", UIStyle.make_flat_style(UIStyle.BG_ACTIVE, UIStyle.INFO, 7, 2))
		tabs.add_child(button)
	root.add_child(tabs)
	match hero_profile_tab:
		1:
			_build_biography_tab(root, hero)
		2:
			_build_history_tab(root, hero)
		_:
			_build_attributes_tab(root, hero)
	root.add_child(_known_hero_actions(hero))


func _hero_party_name(hero_id: String) -> String:
	for party in GameState.parties:
		if party is PartyData and party.member_ids.has(hero_id):
			return party.party_name
	return "не назначен"


func _hero_condition_bars(hero: HeroData) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	for data in [["Мораль", hero.morale], ["Здоровье", 35 if hero.status == HeroData.Status.HOSPITAL else 100], ["Лояльность", hero.loyalty], ["Энергия", maxi(0, 100 - hero.fatigue)]]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = "%s  %d" % [data[0], data[1]]
		box.add_child(label)
		var bar := ProgressBar.new()
		bar.value = int(data[1])
		bar.show_percentage = false
		bar.custom_minimum_size.y = 12
		box.add_child(bar)
		grid.add_child(box)
	return grid


func _build_attributes_tab(root: VBoxContainer, hero: HeroData) -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.add_child(_attribute_group("БОЕВЫЕ", [["Сила", hero.str_stat], ["Ловкость", hero.dex_stat], ["Телосложение", hero.con_stat]]))
	columns.add_child(_attribute_group("МЕНТАЛЬНЫЕ", [["Интеллект", hero.int_stat], ["Мудрость", hero.wis_stat], ["Харизма", hero.cha_stat]]))
	columns.add_child(_attribute_group("СОСТОЯНИЕ", [["Мораль", hero.morale], ["Лояльность", hero.loyalty], ["Усталость", hero.fatigue], ["Энергия", 100 - hero.fatigue]]))
	root.add_child(columns)
	root.add_child(UIStyle.eyebrow("Роли и специализация", UIStyle.INFO))
	root.add_child(UIStyle.body_label("Основная роль: %s\nДополнительная роль: %s\nСтиль: %s\nПредпочитает: %s" % [
		hero.class_name_ru(), _secondary_role(hero), _combat_style(hero),
		", ".join(hero.likes) if not hero.likes.is_empty() else "универсальные задания",
	], true))
	root.add_child(_hero_radar(hero))
	root.add_child(UIStyle.eyebrow("Навыки и владение", UIStyle.WARNING))
	root.add_child(UIStyle.body_label(_format_hero_values(hero.skills, {
		"athletics": "Атлетика", "acrobatics": "Акробатика", "stealth": "Скрытность",
		"perception": "Восприятие", "survival": "Выживание", "medicine": "Медицина",
		"diplomacy": "Дипломатия", "intimidation": "Запугивание", "crafting": "Ремесло",
		"alchemy": "Алхимия", "lore": "Знания",
	}, 3), true))


func _hero_radar(hero: HeroData) -> Control:
	var view := Control.new()
	view.custom_minimum_size = Vector2(0, 190)
	var center := Vector2(190, 95)
	var radius := 72.0
	var values := [
		clampf(float(hero.str_stat + hero.dex_stat) / 40.0, 0.1, 1.0),
		clampf(float(hero.con_stat) / 20.0, 0.1, 1.0),
		clampf(float(hero.int_stat + hero.wis_stat) / 40.0, 0.1, 1.0),
		clampf(float(hero.skills.get("survival", 0)) / 20.0, 0.1, 1.0),
		clampf(float(hero.cha_stat) / 20.0, 0.1, 1.0),
		clampf(float(hero.skills.get("medicine", 0) + hero.skills.get("diplomacy", 0)) / 40.0, 0.1, 1.0),
	]
	var labels := ["Атака", "Защита", "Магия", "Выживание", "Лидерство", "Поддержка"]
	var outline := PackedVector2Array()
	var filled := PackedVector2Array()
	for i in 6:
		var angle := -PI / 2.0 + float(i) * TAU / 6.0
		outline.append(center + Vector2.from_angle(angle) * radius)
		filled.append(center + Vector2.from_angle(angle) * radius * float(values[i]))
		var axis := Line2D.new()
		axis.points = PackedVector2Array([center, outline[i]])
		axis.default_color = UIStyle.BORDER
		axis.width = 1
		view.add_child(axis)
		var label := Label.new()
		label.text = labels[i]
		label.position = center + Vector2.from_angle(angle) * (radius + 20.0) - Vector2(36, 10)
		label.size = Vector2(72, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
		view.add_child(label)
	var outline_line := Line2D.new()
	var closed_outline := outline.duplicate()
	closed_outline.append(outline[0])
	outline_line.points = closed_outline
	outline_line.default_color = UIStyle.BORDER
	outline_line.width = 1.5
	view.add_child(outline_line)
	var polygon := Polygon2D.new()
	polygon.polygon = filled
	polygon.color = Color(UIStyle.INFO, 0.36)
	view.add_child(polygon)
	var value_line := Line2D.new()
	var closed_values := filled.duplicate()
	closed_values.append(filled[0])
	value_line.points = closed_values
	value_line.default_color = UIStyle.INFO
	value_line.width = 2
	view.add_child(value_line)
	return view


func _attribute_group(title: String, values: Array) -> Control:
	var card := UIStyle.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	card.add_child(box)
	box.add_child(UIStyle.eyebrow(title, UIStyle.WARNING))
	for data in values:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = str(data[0])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var value := Label.new()
		value.text = str(data[1])
		var score := int(data[1])
		value.add_theme_color_override("font_color", UIStyle.DANGER if score <= 5 else UIStyle.TEXT if score <= 10 else UIStyle.WARNING if score <= 15 else UIStyle.SUCCESS)
		row.add_child(value)
		box.add_child(row)
	return card


func _secondary_role(hero: HeroData) -> String:
	return {
		"archer": "Разведчик", "mage": "Контроль", "acolyte": "Поддержка",
		"summoner": "Призыватель", "rogue": "Диверсант", "druid": "Целитель",
		"bard": "Вдохновитель", "warrior": "Защитник",
	}.get(hero.class_id, "Универсал")


func _combat_style(hero: HeroData) -> String:
	return "Дальний бой" if hero.class_id in ["archer", "mage", "summoner"] else "Поддержка" if hero.class_id in ["acolyte", "bard", "druid"] else "Ближний бой"


func _build_biography_tab(root: VBoxContainer, hero: HeroData) -> void:
	root.add_child(UIStyle.eyebrow("Биография", UIStyle.INFO))
	root.add_child(UIStyle.body_label("Возраст: %d\nПроисхождение: %s\nРегион: %s\n\n%s\n\nЛичная цель:\n%s" % [
		hero.age, hero.origin, hero.home_kingdom,
		hero.biography_short if not hero.biography_short.is_empty() else "История героя ещё не записана.",
		hero.personal_goal if not hero.personal_goal.is_empty() else "Пока неизвестна.",
	], true))


func _build_history_tab(root: VBoxContainer, hero: HeroData) -> void:
	root.add_child(UIStyle.eyebrow("История героя", UIStyle.WARNING))
	if hero.history.is_empty():
		root.add_child(UIStyle.body_label("Важных событий пока не было.", true))
	for event in hero.history:
		root.add_child(UIStyle.body_label("• " + event, true))


func _known_hero_actions(hero: HeroData) -> Control:
	var actions := HFlowContainer.new()
	actions.name = "HeroManagementActions"
	for action_data in [["Назначить в отряд", Tab.PARTIES], ["Отправить на задание", Tab.QUESTS], ["Отправить на тренировку", Tab.TRAINING]]:
		var button := UIStyle.primary_button(str(action_data[0]))
		var target := int(action_data[1])
		button.disabled = hero.status != HeroData.Status.AVAILABLE
		button.pressed.connect(func(): selected_hero_ids[hero.id] = true; current_tab = target; _refresh())
		actions.add_child(button)
	var favorite := Button.new()
	favorite.text = "★ В избранном" if hero.is_favorite else "☆ В избранное"
	favorite.pressed.connect(func():
		status_label.text = GameState.toggle_hero_favorite(hero.id)
		_refresh()
	)
	actions.add_child(favorite)
	var promotion: Dictionary = GameState.promotion_info(hero)
	var promote := Button.new()
	var next_rank := str(promotion.get("next", ""))
	promote.text = "Максимальный ранг" if next_rank.is_empty() else "Повысить до %s" % next_rank
	promote.disabled = not bool(promotion.get("available", false))
	if promote.disabled:
		promote.tooltip_text = "Требуется уровень %d" % int(promotion.get("level", 0))
	else:
		promote.tooltip_text = "Стоимость: %d славы" % int(promotion.get("cost", 0))
	promote.pressed.connect(func():
		var err := GameState.promote_hero(hero.id)
		status_label.text = err if err != "" else "Герой повышен."
		_refresh()
	)
	actions.add_child(promote)
	var equip := Button.new()
	equip.text = "Экипировка"
	equip.pressed.connect(func(): status_label.text = "Экипировка героя открыта в карточке владений и навыков.")
	actions.add_child(equip)
	if not hero.is_guildmaster:
		var dismiss := UIStyle.danger_button("Уволить")
		dismiss.pressed.connect(func(): _confirm_dismiss_hero(hero))
		actions.add_child(dismiss)
	return actions


func _confirm_dismiss_hero(hero: HeroData) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Уволить героя?"
	dialog.dialog_text = "%s покинет гильдию. Это действие нельзя отменить." % hero.display_name()
	dialog.ok_button_text = "Уволить"
	dialog.confirmed.connect(func():
		status_label.text = GameState.dismiss_hero(hero.id)
		selected_hero_id = ""
		_refresh()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _build_unknown_profile(root: VBoxContainer, hero: HeroData) -> void:
	root.add_child(UIStyle.section_title(_unknown_name(hero), 22))
	var silhouette := PanelContainer.new()
	silhouette.custom_minimum_size = Vector2(0, 190)
	silhouette.add_theme_stylebox_override("panel", UIStyle.make_flat_style(Color("0A0F18"), UIStyle.BORDER, 10, 2))
	var mark := Label.new()
	mark.text = "?"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 72)
	mark.add_theme_color_override("font_color", UIStyle.TEXT_OFF)
	silhouette.add_child(mark)
	root.add_child(silhouette)
	root.add_child(UIStyle.status_badge("Степень изучения: %d/5" % hero.known_level, UIStyle.INFO))
	root.add_child(UIStyle.body_label("Класс: %s\nУровень: %s · Ранг %s\nПотенциал: ???\nПроисхождение: ???" % [
		hero.class_name_ru() if hero.known_level >= 2 else "???",
		str(hero.level) if hero.known_level >= 3 else "???", hero.rank,
	]))
	root.add_child(UIStyle.eyebrow("Частично известные атрибуты", UIStyle.WARNING))
	root.add_child(UIStyle.body_label("Сила: %s   Ловкость: %s   Телосложение: ???\nИнтеллект: ???   Мудрость: %s   Харизма: ???" % [
		str(hero.str_stat) if hero.known_level >= 3 else "???",
		str(hero.dex_stat) if hero.known_level >= 1 else "???",
		str(hero.wis_stat) if hero.known_level >= 2 else "???",
	]))
	root.add_child(UIStyle.body_label("Чтобы раскрыть больше информации:\n• проведите разведку;\n• пригласите героя на собеседование;\n• проведите экзамен;\n• наймите героя в гильдию.", true))
	var actions := HFlowContainer.new()
	for data in [["Разведать", 1, 10], ["Собеседование", 3, 25], ["Провести экзамен", 4, 50]]:
		var button := Button.new()
		button.text = "%s · %d зол." % [data[0], data[2]]
		var target_level := int(data[1])
		var cost := int(data[2])
		button.disabled = hero.known_level >= target_level
		button.pressed.connect(func(): _study_candidate(hero, target_level, cost))
		actions.add_child(button)
	var offer := UIStyle.primary_button("Сделать предложение")
	offer.pressed.connect(func(): _hire_selected_candidate(hero))
	actions.add_child(offer)
	root.add_child(actions)


func _study_candidate(hero: HeroData, target_level: int, cost: int) -> void:
	if GameState.gold < cost:
		status_label.text = "Недостаточно золота."
		return
	GameState.gold -= cost
	hero.known_level = maxi(hero.known_level, target_level)
	status_label.text = "Степень изучения героя повышена до %d/5." % hero.known_level
	GameState.emit_signal("state_changed")


func _hire_selected_candidate(hero: HeroData) -> void:
	for i in GameState.tavern_recruits.size():
		if GameState.tavern_recruits[i] == hero:
			var err := GameState.hire_recruit(i)
			status_label.text = err if err != "" else "Герой вступил в гильдию."
			if err == "":
				selected_candidate_id = ""
				selected_hero_id = hero.id
			_refresh()
			return


func _format_hero_values(values: Dictionary, labels: Dictionary, columns: int = 2) -> String:
	var lines := PackedStringArray()
	var cells := PackedStringArray()
	for key in labels.keys():
		cells.append("%s: %d" % [str(labels[key]), int(values.get(key, 0))])
		if cells.size() >= columns:
			lines.append("   ·   ".join(cells))
			cells.clear()
	if not cells.is_empty():
		lines.append("   ·   ".join(cells))
	return "\n".join(lines)


func _build_mail() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.add_child(UIStyle.section_title("✉  Почта и события"))
	var list: PackedStringArray = GameState.notifications
	if list.is_empty():
		root.add_child(UIStyle.body_label("Новых сообщений нет.", true))
	for i in range(list.size() - 1, -1, -1):
		var card := UIStyle.card()
		card.add_child(UIStyle.body_label("✦  %s" % list[i], i < list.size() - 5))
		root.add_child(card)
	return root


func _build_guild_profile() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.add_child(UIStyle.section_title("♜  %s" % GameState.guild_name))
	root.add_child(UIStyle.body_label("Происхождение: %s\nУровень: %d\nГероев: %d/%d\nСлава: %d" % [
		GameState.guild_origin, GameState.guild_level, GameState.living_roster_count(),
		GameState.roster_slots, GameState.fame,
	]))
	var hall := UIStyle.primary_button("Открыть Гильд-холл")
	hall.pressed.connect(func(): _set_tab(Tab.HALL))
	root.add_child(hall)
	return root


func _build_staff() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.add_child(UIStyle.section_title("♙  Сотрудники гильд-холла"))
	root.add_child(UIStyle.body_label("Сотрудников: %d · Статус: %s · Зарплата: %d золота в неделю" % [
		GameState.npc_staff, "работают" if GameState.staff_working else "приостановили работу",
		_staff_total_wage(),
	]))
	var hired := HFlowContainer.new()
	for i in GameState.staff_members.size():
		var member: Dictionary = GameState.staff_members[i]
		var card := UIStyle.card()
		card.custom_minimum_size.x = 260
		var vb := VBoxContainer.new()
		card.add_child(vb)
		vb.add_child(UIStyle.body_label("%s\n%s: %d · зарплата %d" % [
			member.get("class_name", "Сотрудник"), member.get("skill_name", "Навык"),
			member.get("skill", 0), member.get("wage", 10),
		]))
		var dismiss := Button.new()
		dismiss.text = "Уволить"
		var member_index := i
		dismiss.pressed.connect(func():
			status_label.text = GameState.dismiss_staff_member(member_index)
			_refresh()
		)
		vb.add_child(dismiss)
		hired.add_child(card)
	if GameState.staff_members.is_empty():
		hired.add_child(UIStyle.body_label("Штат пуст. Все обязанности выполняет Гильдмастер.", true))
	root.add_child(hired)

	root.add_child(UIStyle.section_title("Кандидаты", 18))
	var filters := HBoxContainer.new()
	var role_filter := OptionButton.new()
	var role_options := [
		["all", "Все классы"], ["healer", "Лекарь"], ["administrator", "Администратор"],
		["treasurer", "Казначей"], ["scholar", "Учёный"], ["trainer", "Мастер-наставник"],
		["blacksmith", "Кузнец"], ["alchemist", "Алхимик"],
	]
	for option in role_options:
		role_filter.add_item(str(option[1]))
		role_filter.set_item_metadata(role_filter.item_count - 1, option[0])
		if option[0] == staff_filter_role:
			role_filter.select(role_filter.item_count - 1)
	role_filter.item_selected.connect(func(index):
		staff_filter_role = str(role_filter.get_item_metadata(index))
		_refresh()
	)
	filters.add_child(role_filter)
	var skill_filter := SpinBox.new()
	skill_filter.min_value = 0
	skill_filter.max_value = 20
	skill_filter.value = staff_min_skill
	skill_filter.prefix = "Навык от "
	skill_filter.value_changed.connect(func(value):
		staff_min_skill = int(value)
	)
	filters.add_child(skill_filter)
	var apply := Button.new()
	apply.text = "Применить фильтр"
	apply.pressed.connect(_refresh)
	filters.add_child(apply)
	var refresh_candidates := Button.new()
	refresh_candidates.text = "Обновить кандидатов"
	refresh_candidates.pressed.connect(func(): GameState.refresh_staff_candidates(); _refresh())
	filters.add_child(refresh_candidates)
	root.add_child(filters)

	for i in GameState.staff_candidates.size():
		var candidate: Dictionary = GameState.staff_candidates[i]
		if staff_filter_role != "all" and str(candidate.get("role", "")) != staff_filter_role:
			continue
		if int(candidate.get("skill", 0)) < staff_min_skill:
			continue
		var card := UIStyle.card()
		var row := HBoxContainer.new()
		card.add_child(row)
		var info := UIStyle.body_label("%s · %s %d\n%s" % [
			candidate.get("class_name", "Сотрудник"), candidate.get("skill_name", "Навык"),
			candidate.get("skill", 0), candidate.get("description", ""),
		])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var cost := 50 + int(candidate.get("skill", 5)) * 5
		var hire := UIStyle.primary_button("Нанять · %d зол." % cost)
		var candidate_index := i
		hire.pressed.connect(func():
			var err := GameState.hire_staff_candidate(candidate_index)
			status_label.text = err if err != "" else "Сотрудник нанят"
			_refresh()
		)
		row.add_child(hire)
		root.add_child(card)
	return root


func _staff_total_wage() -> int:
	var total := 0
	for member in GameState.staff_members:
		if typeof(member) == TYPE_DICTIONARY:
			total += int(member.get("wage", 10))
	return total


func _build_facility(building_id: String, title: String, action_text: String) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	var def := _building_def(building_id)
	var level := GameState.get_building_level(building_id)
	root.add_child(UIStyle.section_title("%s · ур.%d" % [title, level]))
	root.add_child(UIStyle.body_label(str(def.get("desc", "")), true))
	var required_role := _facility_required_role(building_id)
	var specialist_ready := required_role.is_empty() or GameState.has_staff_role(required_role)
	root.add_child(UIStyle.body_label("Персонал: %s\nСостояние: %s" % [
		"специалист назначен" if specialist_ready else "требуется %s" % _staff_role_name(required_role),
		"работает" if GameState.staff_working and specialist_ready else "остановлено",
	]))
	var action := UIStyle.primary_button(action_text)
	action.disabled = level <= 0 or not GameState.staff_working or not specialist_ready
	action.pressed.connect(func():
		var err := GameState.run_facility_action(building_id)
		status_label.text = err if err != "" else "Работа завершена"
		_refresh()
	)
	root.add_child(action)
	var hall := Button.new()
	hall.text = "Улучшить помещение в Гильд-холле"
	hall.pressed.connect(func(): _set_tab(Tab.HALL))
	root.add_child(hall)
	return root


func _facility_required_role(building_id: String) -> String:
	return {
		"arena": "trainer", "forge": "blacksmith",
		"laboratory": "scholar", "library": "scholar",
	}.get(building_id, "")


func _staff_role_name(role: String) -> String:
	return {
		"trainer": "Мастер-наставник", "blacksmith": "Кузнец",
		"scholar": "Учёный", "administrator": "Администратор",
	}.get(role, "специалист")


func _building_def(building_id: String) -> Dictionary:
	for value in GameState.get_building_defs():
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == building_id:
			return value
	return {}


func _build_tactics() -> Control:
	var root := VBoxContainer.new()
	root.add_child(UIStyle.section_title("⌘  Тактики отрядов"))
	if GameState.parties.is_empty():
		root.add_child(UIStyle.body_label("Сначала создайте отряд. Тактический профиль формируется из состава героев.", true))
	for party in GameState.parties:
		if party is PartyData:
			var card := UIStyle.card()
			card.add_child(UIStyle.body_label("%s\nСостав: %d · Состояние: %s" % [
				party.party_name, party.member_ids.size(), "на задании" if party.on_mission else "готов",
			]))
			root.add_child(card)
	var parties_button := UIStyle.primary_button("Управление отрядами")
	parties_button.pressed.connect(func(): _set_tab(Tab.PARTIES))
	root.add_child(parties_button)
	return root


func _build_world() -> Control:
	if dungeon_simulation_open:
		return _build_dungeon_simulation_screen()
	var root := VBoxContainer.new()
	root.name = "WorldScreen"
	root.add_theme_constant_override("separation", 12)
	root.add_child(UIStyle.section_title("◎  Карта мира"))
	root.add_child(UIStyle.body_label("Разведанные земли Аркадии. Выберите знак на карте, чтобы изучить направление.", true))
	root.add_child(UIStyle.fantasy_divider())

	var split := _adaptive_row(16)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	var map_card := UIStyle.glass_card(UIStyle.WARNING)
	map_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_card.size_flags_stretch_ratio = 1.85
	map_card.add_child(_build_world_map_canvas())
	split.add_child(map_card)

	var details := _build_world_location_details()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_stretch_ratio = 1.0
	split.add_child(details)

	var dungeon_card := UIStyle.glass_card(UIStyle.INFO)
	dungeon_card.name = "DungeonMinimap"
	dungeon_card.add_child(_build_dungeon_minimap())
	root.add_child(dungeon_card)
	return root


func _world_locations() -> Array[Dictionary]:
	return [
		{"id": "guild", "name": GameState.guild_name, "type": "Гильдия", "icon": "castle", "position": Vector2(292, 232), "danger": 0, "travel": 0, "text": "Ваш дом, штаб и безопасная точка возвращения."},
		{"id": "watch", "name": "Северная застава", "type": "Дозор", "icon": "towerWatch", "position": Vector2(308, 48), "danger": 2, "travel": 2, "text": "Пограничная башня сообщает о движении чудовищ."},
		{"id": "mine", "name": "Серебряные копи", "type": "Ресурсы", "icon": "mine", "position": Vector2(86, 282), "danger": 3, "travel": 3, "text": "Заброшенные штольни богаты рудой и опасными глубинами."},
		{"id": "sanctuary", "name": "Святилище Рассвета", "type": "Поселение", "icon": "churchLarge", "position": Vector2(500, 92), "danger": 1, "travel": 3, "text": "Место исцеления, паломничества и древних клятв."},
		{"id": "forest", "name": "Темнолесье", "type": "Дикая местность", "icon": "treePines", "position": Vector2(492, 300), "danger": 4, "travel": 4, "text": "Лес меняет тропы и скрывает входы в подземелья."},
		{"id": "ruins", "name": "Пепельные руины", "type": "Подземелье", "icon": "skull", "position": Vector2(102, 72), "danger": 5, "travel": 5, "text": "Разведка отмечает здесь сильное магическое искажение."},
	]


func _build_world_map_canvas() -> Control:
	var canvas := Control.new()
	canvas.name = "WorldMapCanvas"
	canvas.custom_minimum_size = Vector2(620, 410)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.clip_contents = true

	var parchment := ColorRect.new()
	parchment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parchment.color = Color("172432")
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(parchment)

	var compass := TextureRect.new()
	compass.texture = load("res://assets/kenney/cartography/compass.png")
	compass.position = Vector2(530, 320)
	compass.size = Vector2(68, 68)
	compass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	compass.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	compass.modulate = Color(1, 1, 1, 0.42)
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(compass)

	var route_points := {
		"watch": [Vector2(320, 220), Vector2(334, 90)],
		"mine": [Vector2(292, 250), Vector2(132, 302)],
		"sanctuary": [Vector2(338, 224), Vector2(526, 122)],
		"forest": [Vector2(338, 260), Vector2(520, 330)],
		"ruins": [Vector2(290, 220), Vector2(132, 103)],
	}
	for points in route_points.values():
		var line := Line2D.new()
		line.points = PackedVector2Array(points)
		line.width = 3.0
		line.default_color = Color(UIStyle.WARNING, 0.34)
		line.antialiased = true
		canvas.add_child(line)

	for location in _world_locations():
		var button := Button.new()
		button.name = "Location_%s" % location.id
		button.icon = load("res://assets/kenney/cartography/%s.png" % location.icon)
		button.expand_icon = true
		button.position = location.position
		button.size = Vector2(68, 68)
		button.tooltip_text = "%s\n%s" % [location.name, location.type]
		var location_id: String = location.id
		button.pressed.connect(func():
			selected_world_location = location_id
			_refresh()
		)
		if location_id == selected_world_location:
			button.add_theme_stylebox_override("normal", UIStyle.make_button_style(Color("443A1E"), UIStyle.WARNING, 34, 2))
		canvas.add_child(button)

	var legend := Label.new()
	legend.text = "АРКАДИЯ  ·  РАЗВЕДАННЫЕ ЗЕМЛИ"
	legend.position = Vector2(18, 372)
	legend.add_theme_font_size_override("font_size", 11)
	legend.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	canvas.add_child(legend)
	return canvas


func _selected_world_location_data() -> Dictionary:
	for location in _world_locations():
		if location.id == selected_world_location:
			return location
	return _world_locations()[0]


func _build_world_location_details() -> PanelContainer:
	var card := UIStyle.glass_card(UIStyle.BORDER)
	card.name = "WorldLocationDetails"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	card.add_child(box)
	var location := _selected_world_location_data()
	box.add_child(UIStyle.eyebrow(str(location.type), UIStyle.WARNING))
	box.add_child(UIStyle.section_title(str(location.name), 22))
	box.add_child(UIStyle.body_label(str(location.text), true))
	box.add_child(UIStyle.fantasy_divider())
	box.add_child(UIStyle.status_badge("Опасность: %s" % ("безопасно" if location.danger == 0 else "◆".repeat(int(location.danger))), UIStyle.SUCCESS if location.danger <= 1 else UIStyle.WARNING if location.danger <= 3 else UIStyle.DANGER))
	box.add_child(UIStyle.body_label("Путь: %d дн.\nЗаданий на доске: %d" % [location.travel, GameState.board_quests.size()]))
	var quests := UIStyle.primary_button("Открыть доску заданий")
	quests.pressed.connect(func(): _set_tab(Tab.QUESTS))
	box.add_child(quests)
	if location.id in ["forest", "ruins", "mine"]:
		var focus_dungeon := UIStyle.info_button("Открыть экспедицию")
		focus_dungeon.tooltip_text = "Открыть процедурную карту и симуляцию прохождения."
		focus_dungeon.pressed.connect(_open_dungeon_simulation)
		box.add_child(focus_dungeon)
	return card


func _open_dungeon_simulation() -> void:
	if active_dungeon == null or active_dungeon.seed_value != dungeon_seed:
		active_dungeon = DungeonGenerator.generate(dungeon_seed, maxi(1, int(_selected_world_location_data().get("danger", 1)) / 2))
		dungeon_log = PackedStringArray(["Экспедиция подготовлена.", "Вход в подземелье обнаружен."])
		dungeon_resolved_rooms = PackedStringArray()
	selected_dungeon_party_id = _first_free_party_id() if selected_dungeon_party_id.is_empty() else selected_dungeon_party_id
	dungeon_simulation_open = true
	dungeon_auto_running = false
	_refresh()


func _build_dungeon_simulation_screen() -> Control:
	if active_dungeon == null:
		active_dungeon = DungeonGenerator.generate(dungeon_seed, 2)
	var root := VBoxContainer.new()
	root.name = "DungeonSimulationScreen"
	root.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	var back := Button.new()
	back.text = "←  КАРТА МИРА"
	back.pressed.connect(func():
		dungeon_simulation_open = false
		dungeon_auto_running = false
		_refresh()
	)
	header.add_child(back)
	var title := UIStyle.section_title(active_dungeon.dungeon_name, 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UIStyle.status_badge("ЭТАЖ 1/%d" % active_dungeon.floors, UIStyle.INFO))
	for speed_value in [0, 1, 2, 4]:
		var speed_button := Button.new()
		speed_button.text = "ПАУЗА" if speed_value == 0 else "×%d" % speed_value
		speed_button.custom_minimum_size.x = 64
		speed_button.pressed.connect(_set_dungeon_speed.bind(speed_value))
		if (speed_value == 0 and not dungeon_auto_running) or (speed_value == dungeon_speed and dungeon_auto_running):
			speed_button.add_theme_stylebox_override("normal", UIStyle.kenney_frame_style(UIStyle.INFO, 19, 9, Color("183B4A")))
		header.add_child(speed_button)
	var skip := UIStyle.warning_button("Результат")
	skip.pressed.connect(_finish_dungeon_instantly)
	header.add_child(skip)
	root.add_child(header)

	var main := _adaptive_row(12)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var squad := _build_dungeon_squad_panel()
	squad.custom_minimum_size.x = 210
	main.add_child(squad)
	var map_card := UIStyle.glass_card(UIStyle.INFO)
	map_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_card.add_child(_build_dungeon_graph_map())
	main.add_child(map_card)
	var encounter := _build_dungeon_encounter_panel()
	encounter.custom_minimum_size.x = 220
	main.add_child(encounter)
	root.add_child(main)

	var bottom := UIStyle.card()
	var bottom_box := VBoxContainer.new()
	bottom.add_child(bottom_box)
	var log_header := HBoxContainer.new()
	var log_title := UIStyle.eyebrow("ЖУРНАЛ ЭКСПЕДИЦИИ", UIStyle.WARNING)
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_header.add_child(log_title)
	var step_button := UIStyle.primary_button("Следующий шаг")
	step_button.disabled = active_dungeon.completed
	step_button.pressed.connect(_advance_dungeon_simulation)
	log_header.add_child(step_button)
	bottom_box.add_child(log_header)
	var recent: Array[String] = []
	for i in range(maxi(0, dungeon_log.size() - 4), dungeon_log.size()):
		recent.append(dungeon_log[i])
	bottom_box.add_child(UIStyle.body_label("\n".join(recent), true))
	root.add_child(bottom)
	return root


func _build_dungeon_squad_panel() -> PanelContainer:
	var panel := UIStyle.card()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UIStyle.eyebrow("ОТРЯД", UIStyle.INFO))
	var party: PartyData
	for candidate in GameState.parties:
		if candidate is PartyData and candidate.id == selected_dungeon_party_id:
			party = candidate
			break
	if party == null:
		box.add_child(UIStyle.section_title("Не назначен", 17))
		box.add_child(UIStyle.body_label("Создайте свободный отряд, чтобы начать полноценное прохождение.", true))
		var assign := Button.new()
		assign.text = "НАЗНАЧИТЬ"
		assign.disabled = _first_free_party_id().is_empty()
		assign.pressed.connect(func():
			selected_dungeon_party_id = _first_free_party_id()
			_refresh()
		)
		box.add_child(assign)
		return panel
	box.add_child(UIStyle.section_title(party.party_name, 17))
	for hero in GameState.get_heroes_by_ids(party.member_ids):
		var row := VBoxContainer.new()
		row.add_child(UIStyle.body_label("%s · %s" % [hero.display_name().trim_suffix(" (ГМ)"), hero.class_name_ru()]))
		var hp := ProgressBar.new()
		hp.max_value = 100
		hp.value = hero.health
		hp.show_percentage = true
		row.add_child(hp)
		box.add_child(row)
	box.add_child(UIStyle.status_badge("МОРАЛЬ 74", UIStyle.SUCCESS))
	box.add_child(UIStyle.body_label("Сплочённость: %d\nПрипасы: %d" % [party.size() * 4, GameState.food], true))
	return panel


func _build_dungeon_graph_map() -> Control:
	var map := Control.new()
	map.name = "DungeonGraphMap"
	map.custom_minimum_size = Vector2(500, 330)
	map.clip_contents = true
	var origin := Vector2(16, 62)
	var cell := Vector2(52, 70)
	for room in active_dungeon.rooms:
		var room_id := str(room.id)
		var discovered := room_id in active_dungeon.discovered_rooms
		if not discovered:
			continue
		for next_id in room.next:
			if str(next_id) not in active_dungeon.discovered_rooms:
				continue
			var next_room := active_dungeon.room_by_id(str(next_id))
			var line := Line2D.new()
			line.points = PackedVector2Array([
				origin + Vector2(room.position) * cell + Vector2(24, 24),
				origin + Vector2(next_room.position) * cell + Vector2(24, 24),
			])
			line.width = 3
			line.default_color = Color(UIStyle.INFO, 0.55)
			map.add_child(line)
	for room in active_dungeon.rooms:
		var room_id := str(room.id)
		if room_id not in active_dungeon.discovered_rooms:
			continue
		var tile := TextureRect.new()
		tile.texture = load("res://assets/kenney/minimap/tile_%04d.png" % _dungeon_room_tile(str(room.type)))
		tile.position = origin + Vector2(room.position) * cell
		tile.size = Vector2(48, 48)
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		tile.modulate = Color.WHITE if room_id in active_dungeon.explored_rooms else Color("566273")
		tile.tooltip_text = _dungeon_room_name(str(room.type)) if room_id in active_dungeon.explored_rooms else "Обнаруженная область"
		map.add_child(tile)
		var marker := Label.new()
		marker.position = tile.position + Vector2(16, 12)
		marker.text = "?" if room_id not in active_dungeon.explored_rooms else _dungeon_room_mark(str(room.type))
		marker.add_theme_font_size_override("font_size", 16)
		marker.add_theme_color_override("font_color", UIStyle.TEXT_H)
		map.add_child(marker)
		if room_id == active_dungeon.current_room_id:
			var party_marker := Label.new()
			party_marker.position = tile.position + Vector2(30, -14)
			party_marker.text = "◆"
			party_marker.add_theme_color_override("font_color", UIStyle.WARNING)
			party_marker.add_theme_font_size_override("font_size", 18)
			map.add_child(party_marker)
	return map


func _build_dungeon_encounter_panel() -> PanelContainer:
	var panel := UIStyle.card()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(UIStyle.eyebrow("ТЕКУЩАЯ КОМНАТА", UIStyle.WARNING))
	var room := active_dungeon.current_room()
	box.add_child(UIStyle.section_title(_dungeon_room_name(str(room.get("type", "entrance"))), 18))
	box.add_child(UIStyle.body_label("Опасность: %d\nНаграда: %d золота" % [room.get("danger", 0), room.get("reward", 0)], true))
	var monster: Dictionary = room.get("monster", {})
	if not monster.is_empty():
		box.add_child(UIStyle.status_badge("ВРАГ · УР.%d" % monster.level, UIStyle.DANGER))
		box.add_child(UIStyle.body_label("%s\nСила: %d\nОсобенности: %s" % [
			monster.name, monster.combat_power, ", ".join(monster.traits),
		]))
	if active_dungeon.completed:
		box.add_child(UIStyle.status_badge("ДАНЖ ЗАВЕРШЁН", UIStyle.SUCCESS))
	var choices: Array = room.get("next", [])
	if choices.size() > 1 and active_dungeon.current_room_id in dungeon_resolved_rooms:
		box.add_child(UIStyle.eyebrow("ВЫБОР МАРШРУТА", UIStyle.INFO))
		for i in choices.size():
			var target_id := str(choices[i])
			var target := active_dungeon.room_by_id(target_id)
			var choice := Button.new()
			choice.text = "ОСНОВНОЙ ПУТЬ" if i == 0 else "БОКОВАЯ ВЕТВЬ"
			choice.tooltip_text = "Опасность: %d" % int(target.get("danger", 0))
			choice.pressed.connect(_choose_dungeon_route.bind(target_id))
			box.add_child(choice)
	return panel


func _set_dungeon_speed(value: int) -> void:
	dungeon_auto_running = value > 0
	if value > 0:
		dungeon_speed = value
	_refresh()


func _advance_dungeon_simulation() -> void:
	if active_dungeon == null or active_dungeon.completed:
		return
	var current := active_dungeon.current_room()
	active_dungeon.reveal(active_dungeon.current_room_id, true)
	if active_dungeon.current_room_id not in dungeon_resolved_rooms:
		_resolve_dungeon_room(current)
		dungeon_resolved_rooms.append(active_dungeon.current_room_id)
	var next_rooms: Array = current.get("next", [])
	if str(current.get("type", "")) == "boss" or next_rooms.is_empty():
		active_dungeon.completed = true
		dungeon_auto_running = false
		dungeon_log.append("Экспедиция завершена. Отряд возвращается в гильдию.")
	else:
		if next_rooms.size() > 1:
			dungeon_auto_running = false
			dungeon_log.append("Обнаружена развилка. Требуется решение Гильдмастера.")
			_refresh()
			return
		var next_id := str(next_rooms[0])
		active_dungeon.current_room_id = next_id
		active_dungeon.reveal(next_id, true)
	_refresh()


func _choose_dungeon_route(room_id: String) -> void:
	active_dungeon.current_room_id = room_id
	active_dungeon.reveal(room_id, true)
	dungeon_log.append("Выбран маршрут: %s." % _dungeon_room_name(str(active_dungeon.current_room().get("type", "corridor"))))
	_refresh()


func _resolve_dungeon_room(room: Dictionary) -> void:
	var type := str(room.get("type", "corridor"))
	match type:
		"combat", "elite_combat", "boss":
			var monster: Dictionary = room.get("monster", {})
			dungeon_log.append("Бой: %s побеждён. Отряд получил усталость." % monster.get("name", "противник"))
		"trap":
			dungeon_log.append("Ловушка обнаружена. Отряд потерял часть припасов.")
		"treasure":
			var reward := int(room.get("reward", 0))
			GameState.gold += reward
			dungeon_log.append("Найдено сокровище: +%d золота." % reward)
		"rest":
			dungeon_log.append("Привал восстановил здоровье и мораль.")
		"event", "shrine":
			dungeon_log.append("Отряд пережил необычное событие.")
		_:
			dungeon_log.append("Комната исследована.")


func _finish_dungeon_instantly() -> void:
	var guard := 0
	while active_dungeon != null and not active_dungeon.completed and guard < 30:
		var current := active_dungeon.current_room()
		active_dungeon.reveal(active_dungeon.current_room_id, true)
		if active_dungeon.current_room_id not in dungeon_resolved_rooms:
			_resolve_dungeon_room(current)
			dungeon_resolved_rooms.append(active_dungeon.current_room_id)
		var next_rooms: Array = current.get("next", [])
		if str(current.get("type", "")) == "boss" or next_rooms.is_empty():
			active_dungeon.completed = true
		else:
			active_dungeon.current_room_id = str(next_rooms[0])
			active_dungeon.reveal(active_dungeon.current_room_id, true)
		guard += 1
	dungeon_auto_running = false
	dungeon_log.append("Автосимуляция завершена.")
	_refresh()


func _dungeon_room_tile(type: String) -> int:
	return {"entrance": 21, "boss": 24, "treasure": 18, "trap": 16, "rest": 20, "event": 13, "shrine": 22, "combat": 10}.get(type, 8)


func _dungeon_room_mark(type: String) -> String:
	return {"entrance": "В", "boss": "Б", "treasure": "С", "trap": "!", "rest": "П", "event": "?", "shrine": "✦", "combat": "×"}.get(type, "·")


func _dungeon_room_name(type: String) -> String:
	return {"entrance": "Вход", "boss": "Комната босса", "treasure": "Сокровищница", "trap": "Ловушка", "rest": "Привал", "event": "Событие", "shrine": "Святилище", "resource": "Ресурсы", "combat": "Боевая комната"}.get(type, "Коридор")


func _build_dungeon_minimap() -> VBoxContainer:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	var header := HBoxContainer.new()
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(UIStyle.eyebrow("ЭКСПЕДИЦИЯ", UIStyle.INFO))
	title_box.add_child(UIStyle.section_title("Миникарта подземелья", 18))
	header.add_child(title_box)
	var regenerate := UIStyle.info_button("Новый маршрут")
	regenerate.pressed.connect(func():
		dungeon_seed = int(Time.get_ticks_msec()) | 1
		_refresh()
	)
	header.add_child(regenerate)
	root.add_child(header)

	var map := Control.new()
	map.name = "DungeonMapCanvas"
	map.custom_minimum_size = Vector2(720, 248)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.clip_contents = true
	root.add_child(map)
	var route := _generate_dungeon_route(dungeon_seed)
	var tile_size := Vector2(44, 44)
	var origin := Vector2(20, 12)
	for y in 5:
		for x in 14:
			var tile := TextureRect.new()
			var tile_index := 0
			for point in route:
				if point == Vector2i(x, y):
					tile_index = 6 + ((x + y + dungeon_seed) % 10)
					break
			tile.texture = load("res://assets/kenney/minimap/tile_%04d.png" % tile_index)
			tile.position = origin + Vector2(x, y) * tile_size
			tile.size = tile_size
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.modulate = Color(1, 1, 1, 0.96 if tile_index > 0 else 0.26)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			map.add_child(tile)

	var line := Line2D.new()
	var line_points := PackedVector2Array()
	for point in route:
		line_points.append(origin + (Vector2(point) + Vector2(0.5, 0.5)) * tile_size)
	line.points = line_points
	line.width = 4
	line.default_color = Color(UIStyle.INFO, 0.75)
	line.antialiased = true
	map.add_child(line)
	_add_dungeon_marker(map, load("res://assets/kenney/cartography/flag.png"), route[0], origin, tile_size, "Вход")
	_add_dungeon_marker(map, load("res://assets/kenney/cartography/skull.png"), route[-1], origin, tile_size, "Цель")
	var hero_step: int = int(TimeSystem.day) % route.size()
	_add_dungeon_marker(map, load("res://assets/kenney/cartography/campfire.png"), route[hero_step], origin, tile_size, "Позиция отряда")

	var footer := HBoxContainer.new()
	footer.add_child(UIStyle.status_badge("Маршрут: %d залов" % route.size(), UIStyle.INFO))
	var party_name := "отряд не назначен"
	for party in GameState.parties:
		if party is PartyData and party.id == selected_dungeon_party_id:
			party_name = party.party_name
			break
	var party_label := UIStyle.body_label("Отряд: %s · разведано %d%%" % [party_name, int(float(hero_step + 1) / route.size() * 100.0)], true)
	party_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(party_label)
	var assign := Button.new()
	assign.text = "НАЗНАЧИТЬ СВОБОДНЫЙ ОТРЯД"
	assign.disabled = _first_free_party_id().is_empty()
	assign.pressed.connect(func():
		selected_dungeon_party_id = _first_free_party_id()
		_refresh()
	)
	footer.add_child(assign)
	root.add_child(footer)
	return root


func _generate_dungeon_route(seed_value: int) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var route: Array[Vector2i] = []
	var y := 2
	for x in 14:
		route.append(Vector2i(x, y))
		if x < 13 and rng.randf() < 0.55:
			var next_y := clampi(y + (-1 if rng.randf() < 0.5 else 1), 0, 4)
			if next_y != y:
				y = next_y
				route.append(Vector2i(x, y))
	return route


func _add_dungeon_marker(parent: Control, texture: Texture2D, cell: Vector2i, origin: Vector2, tile_size: Vector2, hint: String) -> void:
	var marker := TextureRect.new()
	marker.texture = texture
	marker.position = origin + Vector2(cell) * tile_size + Vector2(7, 4)
	marker.size = Vector2(30, 34)
	marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marker.tooltip_text = hint
	parent.add_child(marker)


func _first_free_party_id() -> String:
	for party in GameState.parties:
		if party is PartyData and not party.on_mission:
			return party.id
	return ""


func _build_tournaments() -> Control:
	var root := VBoxContainer.new()
	root.add_child(UIStyle.section_title("♛  Турниры и рейтинг"))
	root.add_child(UIStyle.body_label("Текущая слава: %d\nРанг гильдии: %s\nДо следующего дивизиона: %d славы" % [
		GameState.fame, "Претендент" if GameState.fame < 50 else "Известная гильдия", maxi(0, 50 - GameState.fame),
	]))
	return root


func _build_statistics() -> Control:
	var root := VBoxContainer.new()
	root.add_child(UIStyle.section_title("▥  Статистика гильдии"))
	var active := 0
	for party in GameState.parties:
		if party is PartyData and party.on_mission:
			active += 1
	root.add_child(UIStyle.body_label("Героев: %d\nОтрядов: %d\nАктивных заданий: %d\nУровень холла: %d\nСлава: %d\nЗолото: %d" % [
		GameState.living_roster_count(), GameState.parties.size(), active,
		GameState.guild_level, GameState.fame, GameState.gold,
	]))
	return root


func _build_storage() -> Control:
	var root := VBoxContainer.new()
	root.add_child(UIStyle.section_title("▣  Склад"))
	root.add_child(UIStyle.body_label("Припасы: %d\nКристаллы маны: %d\nВместимость героев: %d" % [
		GameState.food, GameState.mana_crystals, GameState.roster_slots,
	]))
	return root


func _build_trade() -> Control:
	var root := VBoxContainer.new()
	root.add_child(UIStyle.section_title("⇄  Торговля"))
	root.add_child(UIStyle.body_label("Золото: %d · Припасы: %d · Кристаллы: %d" % [GameState.gold, GameState.food, GameState.mana_crystals]))
	for offer in [["Купить 10 припасов · 20 золота", "buy_food"], ["Продать 1 кристалл · 30 золота", "sell_mana"]]:
		var button := UIStyle.primary_button(str(offer[0]))
		var action_id := str(offer[1])
		button.pressed.connect(func():
			var err := GameState.trade_resource(action_id)
			status_label.text = err if err != "" else "Сделка завершена"
			_refresh()
		)
		root.add_child(button)
	return root


func _build_finances() -> Control:
	var root := VBoxContainer.new()
	root.add_child(UIStyle.section_title("●  Финансы"))
	var wage := _staff_total_wage()
	root.add_child(UIStyle.body_label("Казна: %d золота\nДолг: %d\nЗарплаты персоналу: %d каждые 5 дней\nСодержание героев: учитывается в конце недели" % [
		GameState.gold, GameState.debt, wage,
	]))
	return root


func _build_journal() -> Control:
	var root := _build_mail()
	var title := UIStyle.section_title("☰  Хроника гильдии")
	root.add_child(title)
	if not GameState.intro_story.is_empty():
		root.add_child(UIStyle.body_label(GameState.intro_story, true))
	if not GameState.last_report.is_empty():
		root.add_child(UIStyle.body_label("Последний отчёт:\n%s" % str(GameState.last_report.get("text", "")), true))
	return root


func _build_hall() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.add_child(UIStyle.section_title("Зал гильдии · ур.%d" % GameState.guild_level))
	root.add_child(UIStyle.body_label("Улучшайте здания за золото. Уровень гильдии растёт от суммы уровней построек.", true))
	var sections := HFlowContainer.new()
	sections.add_theme_constant_override("separation", 8)
	var hall_sections := [
		["▤ Доска заданий", Tab.QUESTS], ["♙ Персонал", Tab.STAFF],
		["⚔ Тренировки", Tab.TRAINING], ["⚒ Кузница", Tab.FORGE],
		["✧ Лаборатория", Tab.LABORATORY], ["▥ Архив", Tab.ARCHIVE],
		["▣ Склад", Tab.STORAGE], ["⇄ Торговля", Tab.TRADE],
	]
	for section in hall_sections:
		var section_button := Button.new()
		section_button.text = str(section[0])
		var target := int(section[1])
		section_button.pressed.connect(func(): current_tab = target; _refresh())
		sections.add_child(section_button)
	root.add_child(sections)
	var available_jobs := 0
	for quest in GameState.board_quests:
		if quest is QuestData and not quest.taken:
			available_jobs += 1
	root.add_child(UIStyle.body_label("▤ На доске заданий: %d · Ручное назначение: %s\nСвободные герои самостоятельно оценивают задания в конце дня." % [
		available_jobs, GameState.assignment_authority(),
	], true))
	var staff_card := UIStyle.card()
	var staff_row := HBoxContainer.new()
	staff_card.add_child(staff_row)
	var staff_info := UIStyle.body_label("♙  Персонал: %d · %s" % [
		GameState.npc_staff, "работает" if GameState.staff_working else "работа остановлена",
	])
	staff_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff_row.add_child(staff_info)
	var staff_button := UIStyle.info_button("Управление сотрудниками")
	staff_button.pressed.connect(func(): _set_tab(Tab.STAFF))
	staff_row.add_child(staff_button)
	root.add_child(staff_card)

	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	for def in GameState.get_building_defs():
		if typeof(def) != TYPE_DICTIONARY:
			continue
		var id: String = str(def.get("id", ""))
		var lvl: int = GameState.get_building_level(id)
		var max_lvl: int = int(def.get("max_level", 3))
		var cost: int = int(def.get("gold_base", 100)) + lvl * int(def.get("gold_per_level", 50))
		var card := UIStyle.card()
		var row := HBoxContainer.new()
		card.add_child(row)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(vb)
		vb.add_child(UIStyle.body_label("%s  ·  ур.%d/%d" % [str(def.get("name", id)), lvl, max_lvl]))
		vb.add_child(UIStyle.body_label(str(def.get("desc", "")), true))
		var up_text := "Макс." if lvl >= max_lvl else "Улучшить (%d зол.)" % cost
		var up := UIStyle.primary_button(up_text)
		up.disabled = lvl >= max_lvl or GameState.is_game_over
		var bid := id
		up.pressed.connect(func():
			var err: String = GameState.upgrade_building(bid)
			status_label.text = err if err != "" else "Здание улучшено"
			_refresh()
		)
		row.add_child(up)
		var facility_tab := _facility_tab(id)
		if facility_tab >= 0:
			var open := Button.new()
			open.text = "Открыть"
			open.pressed.connect(func(): _set_tab(facility_tab))
			row.add_child(open)
		grid.add_child(card)
	root.add_child(grid)
	return root


func _facility_tab(building_id: String) -> int:
	match building_id:
		"forge":
			return Tab.FORGE
		"laboratory":
			return Tab.LABORATORY
		"library":
			return Tab.ARCHIVE
		"arena":
			return Tab.TRAINING
	return -1


func _build_parties() -> Control:
	var root := _adaptive_row(16)
	root.add_theme_constant_override("separation", 16)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(UIStyle.section_title("Собрать отряд"))

	var gm_check := CheckButton.new()
	gm_check.text = "Отряд Гильдмастера"
	gm_check.button_pressed = make_gm_party
	gm_check.toggled.connect(func(v):
		make_gm_party = v
		selected_hero_ids.clear()
		_refresh()
	)
	left.add_child(gm_check)
	left.add_child(UIStyle.body_label("ГМ не вступает в готовый чужой отряд. 2–6 героев.", true))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var picks := VBoxContainer.new()
	scroll.add_child(picks)
	for h in GameState.heroes:
		if not (h is HeroData) or h.status != HeroData.Status.AVAILABLE:
			continue
		if h.is_guildmaster and not make_gm_party:
			continue
		var card := UIStyle.card()
		var row := HBoxContainer.new()
		card.add_child(row)
		var cb := CheckBox.new()
		cb.text = "%s (%s, %s)" % [h.display_name(), h.class_name_ru(), h.rank]
		cb.button_pressed = selected_hero_ids.has(h.id)
		var hid: String = h.id
		cb.toggled.connect(func(on):
			if on:
				selected_hero_ids[hid] = true
			else:
				selected_hero_ids.erase(hid)
		)
		row.add_child(cb)
		picks.add_child(card)
	left.add_child(scroll)
	var create_btn := UIStyle.primary_button("Создать отряд")
	create_btn.pressed.connect(_on_create_party)
	left.add_child(create_btn)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(UIStyle.section_title("Отряды"))
	for p in GameState.parties:
		if not (p is PartyData):
			continue
		var card := UIStyle.card()
		var vb := VBoxContainer.new()
		card.add_child(vb)
		var member_names := PackedStringArray()
		for mh in GameState.get_heroes_by_ids(p.member_ids):
			member_names.append(mh.display_name())
		var mission := ("на задании, %d дн." % p.days_remaining) if p.on_mission else "в гильдии"
		vb.add_child(UIStyle.body_label("%s%s · %s" % [p.party_name, " [ГМ]" if p.is_gm_party else "", mission]))
		vb.add_child(UIStyle.body_label(", ".join(member_names), true))
		var row := HBoxContainer.new()
		if not p.on_mission:
			var pid: String = p.id
			var dis := Button.new()
			dis.text = "Распуск"
			dis.pressed.connect(func():
				GameState.disband_party(pid)
				_refresh()
			)
			row.add_child(dis)
			var sel := Button.new()
			sel.text = "Выбрать для квеста"
			sel.pressed.connect(func():
				selected_party_id = pid
				status_label.text = "Выбран отряд «%s»" % p.party_name
				_set_tab(Tab.QUESTS)
			)
			row.add_child(sel)
		vb.add_child(row)
		right.add_child(card)

	root.add_child(left)
	root.add_child(right)
	return root


func _build_quests() -> Control:
	var root := _adaptive_row(16)
	root.add_theme_constant_override("separation", 16)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(UIStyle.section_title("Доска квестов"))
	left.add_child(UIStyle.body_label("Задания сначала появляются здесь. Свободные герои оценивают риск и могут отправиться самостоятельно. Ручное назначение выполняет: %s." % GameState.assignment_authority(), true))
	var refresh := Button.new()
	refresh.text = "Обновить доску"
	refresh.pressed.connect(func():
		GameState.refresh_quest_board()
		_refresh()
	)
	left.add_child(refresh)

	for q in GameState.board_quests:
		if not (q is QuestData) or q.taken:
			continue
		var card := UIStyle.card()
		var vb := VBoxContainer.new()
		card.add_child(vb)
		var type_l := Label.new()
		type_l.text = q.quest_type.to_upper()
		type_l.add_theme_color_override("font_color", UIStyle.quest_type_color(q.quest_type))
		vb.add_child(type_l)
		vb.add_child(UIStyle.body_label(q.quest_name))
		vb.add_child(UIStyle.body_label("★%d · %d дн. · %d зол. · %d славы" % [
			q.difficulty, q.duration_days, q.gold_reward, q.fame_reward,
		], true))
		var btn := Button.new()
		btn.text = "Выбрать"
		var qid: String = q.id
		btn.pressed.connect(func():
			selected_quest_id = qid
			status_label.text = "Выбран квест: %s" % q.quest_name
			_refresh()
		)
		vb.add_child(btn)
		left.add_child(card)

	var right := UIStyle.card()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := VBoxContainer.new()
	right.add_child(rv)
	rv.add_child(UIStyle.section_title("Отправка", 18))
	var party_name := "(не выбран)"
	for p in GameState.parties:
		if p.id == selected_party_id:
			party_name = p.party_name
	var quest_name := "(не выбран)"
	for q in GameState.board_quests:
		if q.id == selected_quest_id:
			quest_name = q.quest_name
	rv.add_child(UIStyle.body_label("Отряд: %s\nКвест: %s" % [party_name, quest_name]))

	if selected_party_id != "" and selected_quest_id != "":
		var party: PartyData = null
		var quest: QuestData = null
		for p in GameState.parties:
			if p.id == selected_party_id:
				party = p
		for q in GameState.board_quests:
			if q.id == selected_quest_id:
				quest = q
		if party and quest:
			var chance := QuestSimulator.estimate_success(party, quest)
			var forecast := _scouting_forecast(chance)
			var ch := Label.new()
			ch.text = "Оценка разведки: %s" % str(forecast["text"])
			ch.add_theme_font_size_override("font_size", 20)
			ch.add_theme_color_override("font_color", forecast["color"])
			rv.add_child(ch)
			rv.add_child(UIStyle.body_label("Разведданные приблизительны: скрытые угрозы могут изменить исход.", true))

	var send := UIStyle.primary_button("Отправить отряд")
	send.pressed.connect(_on_send_quest)
	rv.add_child(send)

	root.add_child(left)
	root.add_child(right)
	return root


func _build_recruit() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.add_child(UIStyle.section_title("Таверна — найм"))
	root.add_child(UIStyle.body_label("Уровень таверны влияет на число и качество кандидатов.", true))
	var refresh := Button.new()
	refresh.text = "Обновить кандидатов"
	refresh.pressed.connect(func():
		GameState.refresh_tavern()
		_refresh()
	)
	root.add_child(refresh)

	for i in GameState.tavern_recruits.size():
		var h: HeroData = GameState.tavern_recruits[i]
		var cost: int = HeroGenerator.hire_cost(h)
		var card := UIStyle.card()
		var row := HBoxContainer.new()
		card.add_child(row)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(vb)
		vb.add_child(UIStyle.body_label("%s · %s · Ур.%d %s" % [h.hero_name, h.class_name_ru(), h.level, h.rank]))
		vb.add_child(UIStyle.body_label("сила~%.1f · любит %s" % [h.power_score(), ", ".join(h.likes)], true))
		var btn := UIStyle.primary_button("Нанять (%d)" % cost)
		var idx := i
		btn.pressed.connect(func():
			var err := GameState.hire_recruit(idx)
			status_label.text = err if err != "" else "Нанят!"
			_refresh()
		)
		row.add_child(btn)
		root.add_child(card)
	return root


func _build_save() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.add_child(UIStyle.section_title("Сохранения"))
	for slot in range(1, 4):
		var card := UIStyle.card()
		var row := HBoxContainer.new()
		card.add_child(row)
		var info := UIStyle.body_label(SaveLoad.slot_info(slot))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var s := slot
		var save_btn := Button.new()
		save_btn.text = "Сохранить"
		save_btn.pressed.connect(func():
			var err := SaveLoad.save_game(s)
			status_label.text = err if err != "" else "Сохранено в слот %d" % s
			_refresh()
		)
		row.add_child(save_btn)
		var load_btn := Button.new()
		load_btn.text = "Загрузить"
		load_btn.pressed.connect(func():
			var err := SaveLoad.load_game(s)
			status_label.text = err if err != "" else "Загружено"
			selected_hero_ids.clear()
			selected_party_id = ""
			selected_quest_id = ""
			_refresh()
		)
		row.add_child(load_btn)
		root.add_child(card)

	var menu := UIStyle.primary_button("В главное меню")
	menu.pressed.connect(func():
		GameState.clear_campaign()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	root.add_child(menu)
	return root


func _on_create_party() -> void:
	var ids := PackedStringArray(selected_hero_ids.keys())
	if make_gm_party:
		var gm := GameState.get_guildmaster()
		if gm and gm.status == HeroData.Status.AVAILABLE and not ids.has(gm.id):
			ids.append(gm.id)
	var err := GameState.create_party("", ids, make_gm_party)
	status_label.text = err if err != "" else "Отряд создан"
	if err == "":
		selected_hero_ids.clear()
	_refresh()


func _on_send_quest() -> void:
	var err := GameState.assign_quest(selected_party_id, selected_quest_id)
	status_label.text = err if err != "" else "Отряд выступил"
	if err == "":
		selected_quest_id = ""
	_refresh()


func _on_end_day() -> void:
	TimeSystem.end_day()
	status_label.text = "День завершён: %s" % TimeSystem.display_date()
	_refresh()


func _on_game_over(reason: String) -> void:
	status_label.text = reason
	_refresh()


func _on_quest_report(report: Dictionary) -> void:
	status_label.text = str(report.get("text", "Отчёт"))


func _on_skip_tutorial() -> void:
	GameState.tutorial_seen = true
	tutorial_panel.visible = false
	show_tutorial = false
