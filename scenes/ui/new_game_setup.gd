extends Control

var draft_gm: HeroData = null
var crests_data: Dictionary = {}
var selected_emblem: String = "star"
var selected_color: String = "crimson"
var selected_secondary_color: String = "ivory"
var selected_charge_color: String = "gold"
var selected_pattern: String = "solid"
var selected_shield: String = "heater"
var selected_border: String = "gold_simple"
var crest_seed: int = 0
var selected_scenario: String = "Свободная гильдия"
var current_step: int = 0
var _emblem_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}
var _pattern_buttons: Dictionary = {}
var _shape_buttons: Dictionary = {}
var _secondary_color_buttons: Dictionary = {}
var _charge_color_buttons: Dictionary = {}
var _border_buttons: Dictionary = {}

@onready var guild_edit: LineEdit = %GuildEdit
@onready var gm_name_edit: LineEdit = %GMNameEdit
@onready var gm_stats: RichTextLabel = %GMStats
@onready var primary_stats: VBoxContainer = %PrimaryStats
@onready var additional_skills_list: VBoxContainer = %AdditionalSkillsList
@onready var skills_modal_shade: ColorRect = %SkillsModalShade
@onready var temperament_value: Label = %TemperamentValue
@onready var gift_weakness: RichTextLabel = %GiftWeakness
@onready var portrait: PanelContainer = %Portrait
@onready var portrait_mark: Label = %PortraitMark
@onready var portrait_texture: TextureRect = %PortraitTexture
@onready var portrait_file_dialog: FileDialog = %PortraitFileDialog
@onready var free_points_label: Label = %FreePointsLabel
@onready var archetype_label: Label = %ArchetypeLabel
@onready var regenerate_confirm: ConfirmationDialog = %RegenerateConfirm
@onready var status: Label = %Status
@onready var background: TextureRect = $Background
@onready var crest_preview_slot: CenterContainer = %CrestPreview
@onready var large_crest_preview_slot: CenterContainer = %LargeCrestPreview
@onready var large_preview_caption: Label = %LargePreviewCaption
@onready var emblem_grid: GridContainer = %EmblemGrid
@onready var color_grid: GridContainer = %ColorGrid
@onready var secondary_color_grid: GridContainer = %SecondaryColorGrid
@onready var charge_color_grid: GridContainer = %ChargeColorGrid
@onready var pattern_grid: GridContainer = %PatternGrid
@onready var shape_grid: GridContainer = %ShapeGrid
@onready var border_grid: GridContainer = %BorderGrid
@onready var heraldry_row: HBoxContainer = $Margin/VBox/MainRow/GuildPanel/GuildVBox/HeraldryRow
@onready var crest_caption: Label = %CrestCaption
@onready var guild_panel: PanelContainer = $Margin/VBox/MainRow/GuildPanel
@onready var gm_panel: PanelContainer = $Margin/VBox/MainRow/GMPanel
@onready var story_panel: PanelContainer = %StoryPanel
@onready var story_text: Label = %StoryText
@onready var scenario_option: OptionButton = %ScenarioOption
@onready var nickname_edit: LineEdit = %NicknameEdit
@onready var last_name_edit: LineEdit = %LastNameEdit
@onready var gender_option: OptionButton = %GenderOption
@onready var origin_option: OptionButton = %OriginOption
@onready var age_option: OptionButton = %AgeOption
@onready var kingdom_option: OptionButton = %KingdomOption
@onready var alignment_option: OptionButton = %AlignmentOption
@onready var next_button: Button = $Margin/VBox/Footer/BtnStart
@onready var next_hint: Label = %NextHint
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel
var _toast_serial: int = 0
var _heraldry_tab: int = 0


func _ready() -> void:
	MusicController.enter_menu_context()
	theme = UIStyle.create_theme()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	$Margin/VBox/Header/HeaderText/Title.add_theme_color_override("font_color", UIStyle.TEXT_H)
	$Margin/VBox/Header/HeaderText/Subtitle.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	$Margin/VBox/Header/Progress.add_theme_color_override("font_color", UIStyle.INFO)
	for path in ["Margin/VBox/MainRow/GuildPanel/GuildVBox/GuildKicker", "Margin/VBox/MainRow/GMPanel/GMVBox/GMTop/GMHeading/GMKicker"]:
		var kicker: Label = get_node(path)
		kicker.add_theme_color_override("font_color", UIStyle.INFO)
		kicker.add_theme_font_size_override("font_size", 10)
	$Margin/VBox/MainRow/GuildPanel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.GLASS, Color("36516B"), 12, 1))
	$Margin/VBox/MainRow/GMPanel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.GLASS, Color("36516B"), 12, 1))
	story_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.GLASS, UIStyle.WARNING, 12, 1))
	toast_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.GLASS, UIStyle.INFO, 8, 1))
	$Margin/VBox/MainRow/StoryPanel/StoryVBox/StoryKicker.add_theme_color_override("font_color", UIStyle.WARNING)
	$Margin/VBox/MainRow/GuildPanel/GuildVBox/GuildTop/GuildIdentity/IdentityHint.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	$Margin/VBox/MainRow/GMPanel/GMVBox/GMTop/GMHeading/GMHint.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	$Margin/VBox/MainRow/GMPanel/GMVBox/GMColumns/PrimaryPanel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(Color("101B29"), UIStyle.INFO.darkened(0.25), 10, 1))
	$Margin/VBox/MainRow/GMPanel/GMVBox/GMColumns/IdentityPanel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(Color("101B29"), Color("36516B"), 10, 1))
	$SkillsModalShade/SkillsModal.add_theme_stylebox_override("panel", UIStyle.make_flat_style(Color("101823"), UIStyle.INFO, 12, 1))
	$Margin/VBox/Footer/BtnStart.add_theme_stylebox_override("normal", UIStyle.make_flat_style(Color("1F6B45"), UIStyle.SUCCESS, 8, 1))
	$Margin/VBox/Footer/BtnStart.add_theme_stylebox_override("hover", UIStyle.make_flat_style(Color("248A55"), UIStyle.SUCCESS.lightened(0.1), 8, 1))
	guild_edit.text = "Хроники Аркадии"
	crests_data = _load_crests()
	_setup_profile_options()
	if not crests_data.get("emblems", []).is_empty():
		selected_emblem = str(crests_data["emblems"][0].get("id", "star"))
	if not crests_data.get("colors", []).is_empty():
		selected_color = str(crests_data["colors"][0].get("id", "crimson"))
	crest_seed = int(Time.get_unix_time_from_system())
	_build_crest_pickers()
	_reroll_gm()
	_refresh_crest_preview()
	_on_heraldry_tab(0)
	_show_step(0)
	_apply_responsive_layout()
	UIStyle.polish_interactives(self)


func _apply_responsive_layout() -> void:
	var width := get_viewport_rect().size.x
	var height := get_viewport_rect().size.y
	var compact := width < 980.0
	var short := height < 760.0
	var panel_width := maxf(320.0, width - 48.0)
	guild_panel.custom_minimum_size.x = panel_width
	gm_panel.custom_minimum_size.x = panel_width
	story_panel.custom_minimum_size.x = panel_width
	$Margin/VBox/Header/HeaderText/Subtitle.visible = not compact
	$Margin/VBox/Header/HeaderText/Title.add_theme_font_size_override("font_size", 22 if short else 28)
	$Margin/VBox/Header/Progress.add_theme_font_size_override("font_size", 11 if compact else 14)
	$Margin/VBox/MainRow/GMPanel/GMVBox/GMColumns/IdentityPanel/IdentityVBox/IdentityBody/ProfileGrid.columns = 2
	$Margin/VBox/MainRow/GMPanel/GMVBox/GMColumns/IdentityPanel/IdentityVBox/IdentityBody/PortraitColumn.visible = not compact
	emblem_grid.columns = 4 if compact else 8
	color_grid.columns = 5 if compact else 10
	secondary_color_grid.columns = color_grid.columns
	charge_color_grid.columns = color_grid.columns
	pattern_grid.columns = 2 if compact else 3
	shape_grid.columns = 2 if compact else 3
	border_grid.columns = 2 if compact else 4
	$Margin/VBox/MainRow/GuildPanel/GuildVBox/HeraldryRow/LargePreviewPanel.visible = not compact
	large_crest_preview_slot.custom_minimum_size.y = clampf(height - 500.0, 170.0, 260.0)
	heraldry_row.custom_minimum_size.y = clampf(height - 390.0, 300.0, 520.0)
	$Margin/VBox/MainRow.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func _fill_option(option: OptionButton, values: Array) -> void:
	option.clear()
	for value in values:
		option.add_item(str(value))


func _setup_profile_options() -> void:
	_fill_option(gender_option, ["Мужской", "Женский"])
	_fill_option(origin_option, [
		"Городская семья", "Пограничное поселение", "Старый воинский род",
		"Семья ремесленников", "Странствующие авантюристы", "Ученики храма",
	])
	var ages: Array = []
	for age in range(18, 66):
		ages.append(age)
	_fill_option(age_option, ages)
	_fill_option(kingdom_option, [
		"Свободные Земли", "Валенор", "Элдорин", "Лирия", "Астара", "Громтар",
		"Фростхольм", "Дварфхолд", "Сильвария", "Зараш", "Тал'Мара",
	])
	_fill_option(alignment_option, [
		"Законопослушный добрый", "Нейтральный добрый", "Хаотичный добрый",
		"Законопослушный нейтральный", "Истинно нейтральный", "Хаотичный нейтральный",
		"Законопослушный злой", "Нейтральный злой", "Хаотичный злой",
	])
	_fill_option(scenario_option, [
		"Заброшенный гильд-холл", "Малая городская гильдия", "Пограничный форпост",
		"Торговая гильдия", "Магическая ассоциация", "Свободная гильдия",
	])
	origin_option.tooltip_text = "Происхождение даёт тематический бонус к связанным знаниям и отношениям."
	alignment_option.tooltip_text = "Мировоззрение влияет на доверие, лояльность и реакции героев разных взглядов."


func _show_step(step: int) -> void:
	current_step = clampi(step, 0, 2)
	gm_panel.visible = current_step == 0
	guild_panel.visible = current_step == 1
	story_panel.visible = current_step == 2
	var progress: Label = $Margin/VBox/Header/Progress
	progress.text = ["01  ГИЛЬДМАСТЕР", "01  ГИЛЬДМАСТЕР  ✓    02  ГИЛЬДИЯ", "01  ГИЛЬДМАСТЕР  ✓    02  ГИЛЬДИЯ  ✓    03  ПРОЛОГ"][current_step]
	next_button.text = ["Далее", "Перейти к прологу", "Начать хронику"][current_step]
	next_hint.text = ["Следующий этап: создание гильдии", "Следующий этап: пролог", "Гильдия готова к началу хроники"][current_step]
	next_button.disabled = current_step == 0 and _remaining_primary_points() > 0
	if current_step == 0 and _remaining_primary_points() > 0:
		next_hint.text = "Распределите ещё %d очков характеристик" % _remaining_primary_points()
	$Margin/VBox/Footer/BtnBack.text = "В меню" if current_step == 0 else "Назад"
	if current_step == 2:
		_build_intro_story()
	call_deferred("_polish_current_step")


func _polish_current_step() -> void:
	UIStyle.polish_interactives(self)


func _load_crests() -> Dictionary:
	var f := FileAccess.open("res://data/crests.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _color_by_id(cid: String) -> Color:
	for c in crests_data.get("colors", []):
		if str(c.get("id", "")) == cid:
			return Color(str(c.get("hex", "#8b2e2e")))
	return Color("8b2e2e")


func _emblem_name(eid: String) -> String:
	for e in crests_data.get("emblems", []):
		if str(e.get("id", "")) == eid:
			return str(e.get("name", eid))
	return eid


func _color_name(cid: String) -> String:
	for c in crests_data.get("colors", []):
		if str(c.get("id", "")) == cid:
			return str(c.get("name", cid))
	return cid


func _shield_name(sid: String) -> String:
	for shield in crests_data.get("shields", []):
		if str(shield.get("id", "")) == sid:
			return str(shield.get("name", sid))
	return sid


func _build_crest_pickers() -> void:
	for c in emblem_grid.get_children():
		c.queue_free()
	for c in color_grid.get_children():
		c.queue_free()
	for c in secondary_color_grid.get_children():
		c.queue_free()
	for c in charge_color_grid.get_children():
		c.queue_free()
	for c in pattern_grid.get_children():
		c.queue_free()
	for c in shape_grid.get_children():
		c.queue_free()
	for c in border_grid.get_children():
		c.queue_free()
	_emblem_buttons.clear()
	_color_buttons.clear()
	_pattern_buttons.clear()
	_shape_buttons.clear()
	_secondary_color_buttons.clear()
	_charge_color_buttons.clear()
	_border_buttons.clear()

	for shield in crests_data.get("shields", []):
		var sid: String = str(shield.get("id", "heater"))
		var btn := Button.new()
		btn.text = str(shield.get("name", sid))
		var captured := sid
		btn.pressed.connect(func():
			selected_shield = captured
			_refresh_crest_preview()
			_rebuild_emblem_colors()
			_highlight_pickers()
		)
		shape_grid.add_child(btn)
		_shape_buttons[sid] = btn

	for e in crests_data.get("emblems", []):
		var eid: String = str(e.get("id", ""))
		var wrap := VBoxContainer.new()
		wrap.custom_minimum_size = Vector2(76, 100)
		var crest := CrestIcon.new()
		crest.custom_minimum_size = Vector2(56, 64)
		crest.setup_full(_crest_config(eid))
		var btn := Button.new()
		btn.text = str(e.get("name", eid))
		btn.custom_minimum_size = Vector2(0, 28)
		btn.add_theme_font_size_override("font_size", 11)
		var id_capture := eid
		btn.pressed.connect(func():
			selected_emblem = id_capture
			_refresh_crest_preview()
			_highlight_pickers()
		)
		wrap.add_child(crest)
		wrap.add_child(btn)
		emblem_grid.add_child(wrap)
		_emblem_buttons[eid] = btn

	for c in crests_data.get("colors", []):
		var cid: String = str(c.get("id", ""))
		_add_color_button(color_grid, _color_buttons, cid, "primary")
		_add_color_button(secondary_color_grid, _secondary_color_buttons, cid, "secondary")
		_add_color_button(charge_color_grid, _charge_color_buttons, cid, "charge")

	for pattern in crests_data.get("patterns", []):
		var pid: String = str(pattern.get("id", "solid"))
		var btn := Button.new()
		btn.text = str(pattern.get("name", pid))
		btn.custom_minimum_size = Vector2(0, 32)
		var pattern_capture := pid
		btn.pressed.connect(func():
			selected_pattern = pattern_capture
			_refresh_crest_preview()
			_rebuild_emblem_colors()
			_highlight_pickers()
		)
		pattern_grid.add_child(btn)
		_pattern_buttons[pid] = btn

	for border in crests_data.get("borders", []):
		var bid: String = str(border.get("id", "gold_simple"))
		var btn := Button.new()
		btn.text = str(border.get("name", bid))
		var captured := bid
		btn.pressed.connect(func():
			selected_border = captured
			_refresh_crest_preview()
			_rebuild_emblem_colors()
			_highlight_pickers()
		)
		border_grid.add_child(btn)
		_border_buttons[bid] = btn

	_highlight_pickers()


func _add_color_button(grid: GridContainer, registry: Dictionary, color_id: String, role: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 36)
	btn.tooltip_text = _color_name(color_id)
	var col := _color_by_id(color_id)
	btn.add_theme_stylebox_override("normal", UIStyle.make_flat_style(col, UIStyle.BORDER, 6, 1))
	btn.add_theme_stylebox_override("hover", UIStyle.make_flat_style(col.lightened(0.1), UIStyle.GOLD, 6, 2))
	btn.pressed.connect(func():
		match role:
			"secondary":
				selected_secondary_color = color_id
			"charge":
				selected_charge_color = color_id
			_:
				selected_color = color_id
		_refresh_crest_preview()
		_rebuild_emblem_colors()
		_highlight_pickers()
	)
	grid.add_child(btn)
	registry[color_id] = btn


func _crest_config(emblem_override: String = "") -> Dictionary:
	return {
		"primary": _color_by_id(selected_color),
		"secondary": _color_by_id(selected_secondary_color),
		"charge": _color_by_id(selected_charge_color),
		"emblem": selected_emblem if emblem_override.is_empty() else emblem_override,
		"pattern": selected_pattern,
		"shield": selected_shield,
		"border": selected_border,
	}


func _rebuild_emblem_colors() -> void:
	## обновляем цвет на превью-щитах в сетке эмблем
	var i := 0
	for e in crests_data.get("emblems", []):
		var wrap: Node = emblem_grid.get_child(i)
		if wrap and wrap.get_child_count() > 0 and wrap.get_child(0) is CrestIcon:
			(wrap.get_child(0) as CrestIcon).setup_full(_crest_config(str(e.get("id", ""))))
		i += 1


func _highlight_pickers() -> void:
	for eid in _emblem_buttons.keys():
		var b: Button = _emblem_buttons[eid]
		if eid == selected_emblem:
			var selected_style := UIStyle.make_flat_style(UIStyle.BG_CARD, UIStyle.GOLD, 4, 2)
			b.add_theme_stylebox_override("normal", selected_style)
			b.add_theme_stylebox_override("hover", selected_style)
		else:
			b.add_theme_stylebox_override("normal", UIStyle.make_flat_style(UIStyle.BG_PANEL_ALT, UIStyle.BORDER, 4, 1))
			b.remove_theme_stylebox_override("hover")
	for cid in _color_buttons.keys():
		var b: Button = _color_buttons[cid]
		var col := _color_by_id(cid)
		var border := UIStyle.GOLD if cid == selected_color else UIStyle.BORDER
		var bw := 2.5 if cid == selected_color else 1.0
		b.add_theme_stylebox_override("normal", UIStyle.make_flat_style(col, border, 6, bw))
		if cid == selected_color:
			b.add_theme_stylebox_override("hover", b.get_theme_stylebox("normal"))
		else:
			b.remove_theme_stylebox_override("hover")
	_highlight_color_registry(_secondary_color_buttons, selected_secondary_color)
	_highlight_color_registry(_charge_color_buttons, selected_charge_color)
	for pid in _pattern_buttons.keys():
		var b: Button = _pattern_buttons[pid]
		var selected: bool = pid == selected_pattern
		b.add_theme_stylebox_override("normal", UIStyle.make_flat_style(
			UIStyle.BG_ACTIVE,
			UIStyle.GOLD if selected else UIStyle.BORDER,
			5,
			2 if selected else 1
		))
		if selected:
			b.add_theme_stylebox_override("hover", b.get_theme_stylebox("normal"))
		else:
			b.remove_theme_stylebox_override("hover")
	for sid in _shape_buttons.keys():
		_highlight_text_button(_shape_buttons[sid], sid == selected_shield)
	for bid in _border_buttons.keys():
		_highlight_text_button(_border_buttons[bid], bid == selected_border)


func _highlight_color_registry(registry: Dictionary, selected_id: String) -> void:
	for cid in registry.keys():
		var button: Button = registry[cid]
		button.add_theme_stylebox_override("normal", UIStyle.make_flat_style(
			_color_by_id(cid), UIStyle.GOLD if cid == selected_id else UIStyle.BORDER, 6, 2 if cid == selected_id else 1
		))
		if cid == selected_id:
			button.add_theme_stylebox_override("hover", button.get_theme_stylebox("normal"))
		else:
			button.remove_theme_stylebox_override("hover")


func _highlight_text_button(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", UIStyle.make_flat_style(
		UIStyle.BG_ACTIVE, UIStyle.GOLD if selected else UIStyle.BORDER, 5, 2 if selected else 1
	))
	if selected:
		button.add_theme_stylebox_override("hover", button.get_theme_stylebox("normal"))
	else:
		button.remove_theme_stylebox_override("hover")


func _on_heraldry_tab(tab_index: int) -> void:
	_heraldry_tab = clampi(tab_index, 0, 3)
	var column := $Margin/VBox/MainRow/GuildPanel/GuildVBox/HeraldryRow/HeraldryControls/SettingsMargin/SettingsColumn
	var groups := [
		["ShapeTitle", "ShapeGrid"],
		["PatternTitle", "PatternGrid", "ColorTitle", "ColorGrid", "SecondaryColorTitle", "SecondaryColorGrid"],
		["CrestTitle", "EmblemScroll", "ChargeColorTitle", "ChargeColorGrid"],
		["BorderTitle", "BorderGrid"],
	]
	for group_index in groups.size():
		for node_name in groups[group_index]:
			column.get_node(str(node_name)).visible = group_index == _heraldry_tab
	var tabs := [
		column.get_node("SectionTabs/TabBase"),
		column.get_node("SectionTabs/TabField"),
		column.get_node("SectionTabs/TabSymbol"),
		column.get_node("SectionTabs/TabDecor"),
	]
	for i in tabs.size():
		_highlight_text_button(tabs[i], i == _heraldry_tab)


func _refresh_crest_preview() -> void:
	for c in crest_preview_slot.get_children():
		c.queue_free()
	var crest := CrestIcon.new()
	crest.custom_minimum_size = Vector2(100, 112)
	crest.setup_full(_crest_config())
	crest_preview_slot.add_child(crest)
	crest_caption.text = "%s · %s / %s" % [
		_emblem_name(selected_emblem), _color_name(selected_color), _color_name(selected_secondary_color)
	]
	crest_caption.add_theme_color_override("font_color", UIStyle.GOLD_SOFT)
	for child in large_crest_preview_slot.get_children():
		child.queue_free()
	var large_crest := CrestIcon.new()
	var preview_height := clampf(get_viewport_rect().size.y - 520.0, 160.0, 240.0)
	large_crest.custom_minimum_size = Vector2(preview_height * 0.86, preview_height)
	large_crest.setup_full(_crest_config())
	large_crest_preview_slot.add_child(large_crest)
	large_preview_caption.text = "%s\n%s · %s\n%s · seed %d" % [
		_emblem_name(selected_emblem), _color_name(selected_color),
		_color_name(selected_secondary_color), _shield_name(selected_shield), crest_seed,
	]
	large_preview_caption.add_theme_color_override("font_color", UIStyle.TEXT_DIM)


func _color_group(color_id: String) -> String:
	for color in crests_data.get("colors", []):
		if str(color.get("id", "")) == color_id:
			return str(color.get("group", "color"))
	return "color"


func _random_color_from_group(group: String, rng: RandomNumberGenerator, excluded: String = "") -> String:
	var candidates: Array[String] = []
	for color in crests_data.get("colors", []):
		var cid := str(color.get("id", ""))
		if str(color.get("group", "color")) == group and cid != excluded:
			candidates.append(cid)
	return candidates[rng.randi_range(0, candidates.size() - 1)] if not candidates.is_empty() else "ivory"


func _on_random_crest() -> void:
	var rng := RandomNumberGenerator.new()
	crest_seed = int(Time.get_unix_time_from_system() * 1000.0) ^ randi()
	rng.seed = crest_seed
	var shields: Array = crests_data.get("shields", [])
	var patterns: Array = crests_data.get("patterns", [])
	var emblems: Array = crests_data.get("emblems", [])
	var borders: Array = crests_data.get("borders", [])
	selected_shield = str(shields[rng.randi_range(0, shields.size() - 1)].get("id", "heater"))
	selected_pattern = str(patterns[rng.randi_range(0, patterns.size() - 1)].get("id", "solid"))
	selected_emblem = str(emblems[rng.randi_range(0, emblems.size() - 1)].get("id", "star"))
	selected_border = str(borders[rng.randi_range(0, borders.size() - 1)].get("id", "gold_simple"))
	selected_color = _random_color_from_group("color", rng)
	selected_secondary_color = _random_color_from_group("metal", rng)
	selected_charge_color = _random_color_from_group("metal" if _color_group(selected_color) == "color" else "color", rng, selected_secondary_color)
	_refresh_crest_preview()
	_rebuild_emblem_colors()
	_highlight_pickers()
	_show_toast("Создан контрастный герб · seed %d" % crest_seed)


func _reroll_gm() -> void:
	var keep_name: String = gm_name_edit.text.strip_edges() if gm_name_edit else ""
	draft_gm = HeroGenerator.create_guildmaster()
	if keep_name != "" and gm_name_edit.has_focus():
		draft_gm.hero_name = keep_name
	else:
		gm_name_edit.text = draft_gm.hero_name
	_refresh_stats()
	_sync_profile_controls()


func _sync_profile_controls() -> void:
	if draft_gm == null:
		return
	gender_option.select(1 if draft_gm.gender == "female" else 0)
	age_option.select(clampi(draft_gm.age - 18, 0, age_option.item_count - 1))
	alignment_option.select(clampi(draft_gm.alignment, 0, alignment_option.item_count - 1))
	_select_option_text(kingdom_option, draft_gm.home_kingdom)
	_select_option_text(origin_option, draft_gm.origin.capitalize())
	last_name_edit.text = draft_gm.last_name
	nickname_edit.text = draft_gm.nickname


func _select_option_text(option: OptionButton, text: String) -> void:
	for i in option.item_count:
		if option.get_item_text(i).to_lower() == text.to_lower():
			option.select(i)
			return


func _apply_profile_controls() -> void:
	draft_gm.nickname = nickname_edit.text.strip_edges()
	draft_gm.last_name = last_name_edit.text.strip_edges()
	draft_gm.gender = "female" if gender_option.selected == 1 else "male"
	draft_gm.origin = origin_option.get_item_text(origin_option.selected)
	draft_gm.age = int(age_option.get_item_text(age_option.selected))
	draft_gm.home_kingdom = kingdom_option.get_item_text(kingdom_option.selected)
	draft_gm.alignment = alignment_option.selected


func _on_random_name() -> void:
	gm_name_edit.text = HeroGenerator.random_name()
	if draft_gm:
		draft_gm.hero_name = gm_name_edit.text
	_refresh_stats()


func _refresh_stats() -> void:
	if draft_gm == null:
		return
	_rebuild_stat_rows(primary_stats, draft_gm.primary_management_stats, {
		"diplomacy": "ДИПЛОМАТИЯ", "charisma": "ХАРИЗМА",
		"influence": "ВЛИЯНИЕ", "leadership": "ЛИДЕРСТВО",
	}, true)
	_rebuild_stat_rows(additional_skills_list, draft_gm.management_skills, {
		"strategy": "Стратегия", "tactics": "Тактика", "finance": "Финансы",
		"organization": "Организация", "trade": "Торговля", "psychology": "Психология",
		"staff_management": "Управление персоналом", "crafting": "Крафт",
		"arcane_knowledge": "Магические знания", "warfare": "Военное дело",
		"scouting": "Разведка", "logistics": "Логистика", "training": "Обучение",
		"reputation": "Репутация", "stress_resistance": "Стрессоустойчивость",
	}, false)
	temperament_value.text = draft_gm.temperament
	gift_weakness.text = """[color=#36D26E]РЕДКИЙ ДАР[/color]
[font_size=16]%s[/font_size]  [color=#8D98A8]%s[/color]
[color=#E65B5B]СЛАБОСТЬ[/color]
[font_size=16]%s[/font_size]  [color=#8D98A8]%s[/color]
[color=#2CB7D9]СТАРТОВАЯ СПЕЦИАЛИЗАЦИЯ[/color]
[font_size=16]%s[/font_size]  [color=#8D98A8]+25%% опыта Гильдмастеру[/color]""" % [
		draft_gm.rare_gift, _gift_effect(draft_gm.rare_gift),
		draft_gm.weakness, _weakness_effect(draft_gm.weakness), draft_gm.class_name_ru(),
	]
	_refresh_portrait()
	var remaining := _remaining_primary_points()
	free_points_label.text = "Свободные очки: %d" % remaining
	free_points_label.add_theme_color_override("font_color", UIStyle.SUCCESS if remaining == 0 else UIStyle.WARNING)
	archetype_label.text = _guildmaster_archetype()
	if current_step == 0:
		next_button.disabled = remaining > 0
		next_hint.text = "Следующий этап: создание гильдии" if remaining == 0 else "Распределите ещё %d очков характеристик" % remaining


func _gift_effect(value: String) -> String:
	return {
		"Прирождённый дипломат": "+15% к результату дипломатических миссий.",
		"Военный гений": "Повышает качество тактической подготовки.",
		"Голос авторитета": "Усиливает мораль и выполнение приказов.",
		"Магическая интуиция": "Помогает распознавать магические угрозы.",
	}.get(value, "Даёт редкое преимущество в событиях гильдии.")


func _weakness_effect(value: String) -> String:
	return {
		"Склонность к риску": "Повышает шанс опасных решений в событиях.",
		"Плохое управление финансами": "Снижает эффективность финансовых решений.",
		"Трудности с дипломатией": "Усложняет переговоры с фракциями.",
		"Медленное обучение": "Замедляет освоение новых навыков.",
	}.get(value, "Создаёт ситуативное ограничение для Гильдмастера.")


func _rebuild_stat_rows(container: VBoxContainer, values: Dictionary, labels: Dictionary, large: bool) -> void:
	for child in container.get_children():
		child.queue_free()
	for key in labels:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 42 if large else 28
		var label := Label.new()
		label.text = str(labels[key])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 14 if large else 13)
		if large:
			label.tooltip_text = {
				"diplomacy": "Переговоры, договоры, отношения с королевствами и разрешение конфликтов.",
				"charisma": "Мораль, найм, лояльность и публичный образ Гильдмастера.",
				"influence": "Политический вес, редкие контакты и сила решений на мировой карте.",
				"leadership": "Управление героями, отрядами, персоналом и эффективность приказов.",
			}.get(key, "")
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(150 if large else 210, 24)
		bar.max_value = 20
		bar.value = int(values.get(key, 1))
		bar.show_percentage = false
		var number := Label.new()
		number.custom_minimum_size.x = 32
		number.text = str(int(values.get(key, 1)))
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.add_theme_color_override("font_color", UIStyle.WARNING)
		number.add_theme_font_size_override("font_size", 18 if large else 14)
		row.add_child(label)
		if large:
			var minus := Button.new()
			minus.text = "−"
			minus.custom_minimum_size = Vector2(38, 34)
			minus.disabled = int(values.get(key, 5)) <= 5
			minus.pressed.connect(_change_primary_stat.bind(str(key), -1))
			row.add_child(minus)
		row.add_child(bar)
		row.add_child(number)
		if large:
			var plus := Button.new()
			plus.text = "+"
			plus.custom_minimum_size = Vector2(38, 34)
			plus.disabled = int(values.get(key, 5)) >= 15 or _remaining_primary_points() <= 0
			plus.pressed.connect(_change_primary_stat.bind(str(key), 1))
			row.add_child(plus)
		container.add_child(row)


func _remaining_primary_points() -> int:
	if draft_gm == null:
		return 20
	var spent := 0
	for value in draft_gm.primary_management_stats.values():
		spent += maxi(0, int(value) - 5)
	return maxi(0, 20 - spent)


func _change_primary_stat(stat_id: String, delta: int) -> void:
	var current := int(draft_gm.primary_management_stats.get(stat_id, 5))
	if delta > 0 and (_remaining_primary_points() == 0 or current >= 15):
		return
	if delta < 0 and current <= 5:
		return
	draft_gm.primary_management_stats[stat_id] = current + delta
	draft_gm.cha_stat = int(draft_gm.primary_management_stats["charisma"])
	draft_gm.skills["diplomacy"] = int(draft_gm.primary_management_stats["diplomacy"])
	_refresh_stats()


func _guildmaster_archetype() -> String:
	var s: Dictionary = draft_gm.primary_management_stats
	var pairs := [["diplomacy", int(s["diplomacy"])], ["charisma", int(s["charisma"])], ["influence", int(s["influence"])], ["leadership", int(s["leadership"])]]
	pairs.sort_custom(func(a, b): return a[1] > b[1])
	if int(pairs[0][1]) - int(pairs[3][1]) <= 2:
		return "ПРОФИЛЬ: УНИВЕРСАЛ\nСбалансированное управление всеми сторонами гильдии."
	var top := {str(pairs[0][0]): true, str(pairs[1][0]): true}
	if int(s["leadership"]) >= int(pairs[1][1]) + 3:
		return "ПРОФИЛЬ: КОМАНДИР\nСильное управление героями и крупными отрядами."
	if top.has("diplomacy") and top.has("charisma"):
		return "ПРОФИЛЬ: ДИПЛОМАТ\nПереговоры, отношения с фракциями и редкий найм."
	if top.has("influence") and top.has("leadership"):
		return "ПРОФИЛЬ: ПРАВИТЕЛЬ\nПолитический вес и управление организацией."
	if top.has("charisma") and top.has("leadership"):
		return "ПРОФИЛЬ: ВДОХНОВИТЕЛЬ\nВысокая мораль, лояльность и эффективность приказов."
	return "ПРОФИЛЬ: ПОСРЕДНИК\nДоговоры, связи и разрешение конфликтов."


func _refresh_portrait() -> void:
	if draft_gm.portrait_id.begins_with("res://") and ResourceLoader.exists(draft_gm.portrait_id):
		portrait_texture.texture = load(draft_gm.portrait_id)
		portrait_texture.visible = portrait_texture.texture != null
		portrait_mark.visible = not portrait_texture.visible
		if portrait_texture.visible:
			return
	if draft_gm.portrait_id.begins_with("user://"):
		var image := Image.load_from_file(draft_gm.portrait_id)
		if image != null and not image.is_empty():
			portrait_texture.texture = ImageTexture.create_from_image(image)
			portrait_texture.visible = true
			portrait_mark.visible = false
			return
	portrait_texture.visible = false
	portrait_mark.visible = true
	var index := int(draft_gm.portrait_id.get_slice("_", 2))
	var colors := [Color("315A78"), Color("6B3F55"), Color("3D6651"), Color("695733"), Color("4E4775"), Color("704337"), Color("345E65"), Color("5D4964")]
	var accent: Color = colors[(index - 1) % colors.size()]
	portrait.add_theme_stylebox_override("panel", UIStyle.make_flat_style(accent.darkened(0.45), accent.lightened(0.25), 12, 2))
	var initials := PackedStringArray()
	for part in draft_gm.hero_name.split(" ", false):
		initials.append(part.left(1).to_upper())
	portrait_mark.text = "".join(initials).left(2) if not initials.is_empty() else "GM"
	portrait_mark.add_theme_color_override("font_color", accent.lightened(0.55))


func _format_skill_group(values: Dictionary, labels: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in labels.keys():
		parts.append("%s %d" % [str(labels[key]), int(values.get(key, 0))])
	return "  ·  ".join(parts)


func _preference_text(values: PackedStringArray) -> String:
	var names := {
		"combat": "боевые задания",
		"gathering": "сбор ресурсов",
		"escort": "сопровождение",
		"pacifist": "мирные решения",
	}
	var result := PackedStringArray()
	for value in values:
		result.append(str(names.get(value, value)))
	return ", ".join(result) if not result.is_empty() else "не определено"


func _on_reroll() -> void:
	_reroll_gm()
	_show_toast("Статы Гильдмастера обновлены")


func _on_generate_all() -> void:
	if _remaining_primary_points() < 20:
		regenerate_confirm.popup_centered()
		return
	_confirm_generate_all()


func _confirm_generate_all() -> void:
	_reroll_gm()
	_show_toast("Новый Гильдмастер создан.", UIStyle.SUCCESS)


func _on_random_primary() -> void:
	if draft_gm == null:
		return
	HeroGenerator.randomize_guildmaster_primary(draft_gm)
	_refresh_stats()
	_show_toast("Ключевые параметры обновлены")


func _on_reset_primary() -> void:
	for key in draft_gm.primary_management_stats:
		draft_gm.primary_management_stats[key] = 5
	_refresh_stats()


func _on_gender_selected(index: int) -> void:
	if draft_gm == null:
		return
	draft_gm.gender = "female" if index == 1 else "male"
	var identity := HeroGenerator.random_identity(draft_gm.gender)
	draft_gm.hero_name = str(identity["first_name"])
	draft_gm.last_name = str(identity["last_name"])
	draft_gm.nickname = str(identity["nickname"])
	draft_gm.portrait_id = "res://assets/portraits/portrait_default_%s.png" % draft_gm.gender
	gm_name_edit.text = draft_gm.hero_name
	last_name_edit.text = draft_gm.last_name
	nickname_edit.text = draft_gm.nickname
	_refresh_stats()


func _on_open_skills() -> void:
	_refresh_stats()
	skills_modal_shade.visible = true
	%BtnCloseSkills.grab_focus()


func _on_close_skills() -> void:
	skills_modal_shade.visible = false


func _on_reroll_skills() -> void:
	if draft_gm == null:
		return
	HeroGenerator.randomize_guildmaster_skills(draft_gm)
	_refresh_stats()
	_show_toast("Дополнительные навыки обновлены")


func _on_random_portrait() -> void:
	if draft_gm == null:
		return
	var pool := ["res://assets/portraits/portrait_default_%s.png" % draft_gm.gender]
	draft_gm.portrait_id = str(pool.pick_random())
	_refresh_portrait()


func _on_upload_portrait() -> void:
	portrait_file_dialog.popup_centered_ratio(0.72)


func _on_portrait_file_selected(path: String) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		_show_toast("Не удалось открыть изображение.", UIStyle.DANGER)
		return
	image.resize(512, 640, Image.INTERPOLATE_LANCZOS)
	var target := "user://custom_guildmaster_portrait.png"
	if image.save_png(target) != OK:
		_show_toast("Не удалось сохранить портрет.", UIStyle.DANGER)
		return
	draft_gm.portrait_id = target
	_refresh_portrait()
	_show_toast("Портрет загружен.", UIStyle.SUCCESS)


func _validate_crest() -> String:
	if selected_shield.is_empty() or selected_pattern.is_empty():
		return "Выберите основу и деление герба."
	if selected_emblem.is_empty():
		return "Выберите геральдическую фигуру."
	if selected_color.is_empty() or selected_secondary_color.is_empty() or selected_charge_color.is_empty():
		return "Выберите цвета герба."
	if selected_pattern != "solid" and selected_color == selected_secondary_color:
		return "Основной и второй цвета поля должны различаться."
	if _color_group(selected_color) == _color_group(selected_charge_color):
		return "Фигура должна контрастировать с основным полем."
	return ""


func _show_toast(message: String, accent: Color = UIStyle.INFO) -> void:
	_toast_serial += 1
	var serial := _toast_serial
	toast_label.text = message
	toast_panel.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.GLASS, accent, 8, 1))
	toast_panel.visible = true
	await get_tree().create_timer(3.0).timeout
	if serial == _toast_serial and is_instance_valid(toast_panel):
		toast_panel.visible = false


func _on_start() -> void:
	if current_step == 0:
		var gm_name := gm_name_edit.text.strip_edges()
		if gm_name.is_empty():
			_show_toast("Введите имя Гильдмастера", UIStyle.WARNING)
			return
		if last_name_edit.text.strip_edges().is_empty():
			_show_toast("Введите фамилию или родовое имя", UIStyle.WARNING)
			return
		if _remaining_primary_points() > 0:
			_show_toast("Распределите ещё %d очков характеристик." % _remaining_primary_points(), UIStyle.WARNING)
			next_hint.text = "Распределите ещё %d очка характеристик" % _remaining_primary_points()
			return
		draft_gm.hero_name = gm_name
		_apply_profile_controls()
		_show_step(1)
		return
	if current_step == 1:
		var guild_name := guild_edit.text.strip_edges()
		if guild_name.is_empty():
			_show_toast("Введите название гильдии", UIStyle.WARNING)
			return
		var crest_error := _validate_crest()
		if not crest_error.is_empty():
			_show_toast(crest_error, UIStyle.DANGER)
			return
		selected_scenario = scenario_option.get_item_text(scenario_option.selected)
		_show_step(2)
		return
	var gname: String = guild_edit.text.strip_edges()
	var gm_name: String = gm_name_edit.text.strip_edges()
	if gname.is_empty():
		_show_toast("Введите название гильдии", UIStyle.WARNING)
		status.add_theme_color_override("font_color", UIStyle.ACCENT_BAD)
		return
	if gm_name.is_empty():
		_show_toast("Введите имя Гильдмастера", UIStyle.WARNING)
		status.add_theme_color_override("font_color", UIStyle.ACCENT_BAD)
		return
	if draft_gm == null:
		_show_toast("Сначала сгенерируйте Гильдмастера", UIStyle.WARNING)
		status.add_theme_color_override("font_color", UIStyle.ACCENT_BAD)
		return
	draft_gm.hero_name = gm_name
	GameState.new_game_with_gm(
		gname, draft_gm, selected_emblem, selected_color, selected_pattern,
		selected_scenario, story_text.text, selected_shield, selected_secondary_color,
		selected_charge_color, selected_border, crest_seed
	)
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")


func _on_back() -> void:
	if current_step > 0:
		_show_step(current_step - 1)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _build_intro_story() -> void:
	var nickname := (" «%s»" % draft_gm.nickname) if draft_gm.nickname != "" else ""
	var founder_name := draft_gm.hero_name + ((" " + draft_gm.last_name) if not draft_gm.last_name.is_empty() else "")
	story_text.text = """%s%s прибыл из региона «%s», неся редкий дар, способный объединять людей и ускорять собственное развитие.

Вместо службы уже известным орденам %s решил основать собственную гильдию — «%s». Её первым домом станет «%s».

Впереди нет предначертанной победы. Есть только пустой зал, несколько неизвестных героев и обещание однажды занять первое место среди гильдий Аркадии.

Так начинается хроника гильдии «%s».""" % [
		founder_name, nickname, draft_gm.home_kingdom,
		"она" if draft_gm.gender == "female" else "он",
		guild_edit.text.strip_edges(), selected_scenario, guild_edit.text.strip_edges(),
	]
