extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var scale_option: OptionButton = %ScaleOption
@onready var language_option: OptionButton = %LanguageOption
@onready var btn_apply: Button = %BtnApply
@onready var btn_defaults: Button = %BtnDefaults
@onready var btn_back: Button = %BtnBack
@onready var label_audio: Label = %LabelAudio
@onready var label_video: Label = %LabelVideo
@onready var label_language: Label = %LabelLanguage
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	theme = TinyThemeFactory.build()
	MusicController.enter_menu_context()
	_populate_options()
	_load_into_controls()
	_refresh_texts()
	_update_resolution_enabled()

	btn_apply.pressed.connect(_on_apply)
	btn_defaults.pressed.connect(_on_defaults)
	btn_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Live audio preview while dragging.
	master_slider.value_changed.connect(_on_audio_preview)
	music_slider.value_changed.connect(_on_audio_preview)
	sfx_slider.value_changed.connect(_on_audio_preview)


func _populate_options() -> void:
	resolution_option.clear()
	for res in Settings.RESOLUTIONS:
		resolution_option.add_item("%d×%d" % [res.x, res.y])
	scale_option.clear()
	for s in Settings.UI_SCALES:
		scale_option.add_item("%d%%" % int(round(s * 100.0)))
	language_option.clear()
	language_option.add_item(tr("settings.language_ru"), 0)


func _load_into_controls() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05

	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	fullscreen_check.button_pressed = Settings.fullscreen

	var res_idx := 0
	for i in Settings.RESOLUTIONS.size():
		if Settings.RESOLUTIONS[i] == Settings.resolution:
			res_idx = i
			break
	resolution_option.select(res_idx)

	var scale_idx := 0
	for i in Settings.UI_SCALES.size():
		if is_equal_approx(Settings.UI_SCALES[i], Settings.ui_scale):
			scale_idx = i
			break
	scale_option.select(scale_idx)
	language_option.select(0)
	_update_resolution_enabled()


func _refresh_texts() -> void:
	label_audio.text = tr("settings.audio")
	label_video.text = tr("settings.video")
	label_language.text = tr("settings.language")
	fullscreen_check.text = tr("settings.fullscreen")
	btn_apply.text = tr("menu.apply")
	btn_defaults.text = tr("menu.defaults")
	btn_back.text = tr("menu.back")
	%LabelMaster.text = tr("settings.master_volume")
	%LabelMusic.text = tr("settings.music_volume")
	%LabelSfx.text = tr("settings.sfx_volume")
	%LabelResolution.text = tr("settings.resolution")
	%LabelScale.text = tr("settings.ui_scale")


func _on_fullscreen_toggled(_pressed: bool) -> void:
	_update_resolution_enabled()


func _update_resolution_enabled() -> void:
	var windowed := not fullscreen_check.button_pressed
	resolution_option.disabled = not windowed
	if status_label:
		if windowed:
			status_label.text = ""
		else:
			status_label.text = "Разрешение применяется в оконном режиме"


func _on_audio_preview(_value: float) -> void:
	Settings.master_volume = float(master_slider.value)
	Settings.music_volume = float(music_slider.value)
	Settings.sfx_volume = float(sfx_slider.value)
	Settings.apply_audio_only()


func _read_controls_into_settings() -> void:
	Settings.master_volume = float(master_slider.value)
	Settings.music_volume = float(music_slider.value)
	Settings.sfx_volume = float(sfx_slider.value)
	Settings.fullscreen = fullscreen_check.button_pressed
	var ri := resolution_option.selected
	if ri >= 0 and ri < Settings.RESOLUTIONS.size():
		Settings.resolution = Settings.RESOLUTIONS[ri]
	var si := scale_option.selected
	if si >= 0 and si < Settings.UI_SCALES.size():
		Settings.ui_scale = Settings.UI_SCALES[si]
	Settings.language = "ru"


func _on_apply() -> void:
	_read_controls_into_settings()
	Settings.apply()
	Settings.save_settings()
	_refresh_texts()
	_update_resolution_enabled()
	if status_label:
		var win := get_window()
		var size_txt := "%d×%d" % [win.size.x, win.size.y] if win else "?"
		status_label.text = "Применено · окно %s · масштаб %d%%" % [
			size_txt,
			int(round(Settings.ui_scale * 100.0)),
		]


func _on_defaults() -> void:
	Settings.reset_to_defaults()
	_load_into_controls()
	Settings.apply()
	Settings.save_settings()
	_refresh_texts()
	if status_label:
		status_label.text = "Сброшено по умолчанию"
