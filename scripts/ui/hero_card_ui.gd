class_name HeroCardUI
extends RefCounted


static func build(hero: HeroData, on_details: Callable = Callable()) -> PanelContainer:
	var card := UIStyle.card()
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	card.add_child(root)

	## Portrait placeholder
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(72, 88)
	var pcol := UIStyle.rank_color(hero.rank)
	portrait.add_theme_stylebox_override("panel", UIStyle.make_flat_style(UIStyle.BG_ACTIVE, pcol, 8, 2))
	var pinner := VBoxContainer.new()
	pinner.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait.add_child(pinner)
	var rank_l := Label.new()
	rank_l.text = hero.rank
	rank_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_l.add_theme_font_size_override("font_size", 22)
	rank_l.add_theme_color_override("font_color", pcol)
	pinner.add_child(rank_l)
	var lvl := Label.new()
	lvl.text = "Ур.%d" % hero.level
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_font_size_override("font_size", 11)
	lvl.add_theme_color_override("font_color", UIStyle.TEXT_DIM)
	pinner.add_child(lvl)
	root.add_child(portrait)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	root.add_child(body)

	var name_row := HBoxContainer.new()
	var name_l := Label.new()
	name_l.text = hero.display_name()
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.add_theme_color_override("font_color", UIStyle.TEXT_H)
	name_l.add_theme_font_size_override("font_size", 15)
	name_row.add_child(name_l)
	name_row.add_child(UIStyle.status_badge(UIStyle.status_text(hero.status), UIStyle.status_color(hero.status)))
	body.add_child(name_row)

	body.add_child(UIStyle.body_label("%s · ранг %s · сила~%.1f" % [
		hero.class_name_ru(), hero.rank, hero.power_score(),
	], true))

	var traits := HBoxContainer.new()
	traits.add_theme_constant_override("separation", 6)
	if hero.likes.size() > 0:
		traits.add_child(UIStyle.status_badge(str(hero.likes[0]), UIStyle.SUCCESS))
	if hero.dislikes.size() > 0:
		traits.add_child(UIStyle.status_badge(str(hero.dislikes[0]), UIStyle.DANGER))
	traits.add_child(UIStyle.status_badge("Мораль %d" % hero.morale, UIStyle.INFO))
	body.add_child(traits)

	if on_details.is_valid():
		var btn := Button.new()
		btn.text = "ПОДРОБНЕЕ"
		btn.custom_minimum_size = Vector2(100, 0)
		btn.pressed.connect(on_details)
		root.add_child(btn)

	return card
