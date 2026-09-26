class_name SettingsPanel
extends Control
## Settings (SPEC 8): sound on/off and language. Language names are written in
## their own language. Changing the language saves it and reloads the scene so
## every text and the logo pick it up.

@onready var _sound: Button = %SoundButton
@onready var _ru: Button = %RuButton
@onready var _en: Button = %EnButton
@onready var _close: Button = %CloseButton
@onready var _speed: UpgradeRow = %SpeedRow


func _ready() -> void:
	_sound.pressed.connect(_toggle_sound)
	_ru.pressed.connect(_set_lang.bind("ru"))
	_en.pressed.connect(_set_lang.bind("en"))
	_close.pressed.connect(func() -> void: visible = false)
	_speed.setup(GameState.config.upgrade(&"battle_speed"))


func open() -> void:
	_refresh()
	visible = true
	_close.grab_focus()


## Esc closes the settings.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		visible = false


func _toggle_sound() -> void:
	GameState.set_sound(not GameState.sound_on)
	Platform.update_mute()
	_refresh()


func _set_lang(code: String) -> void:
	if TranslationServer.get_locale().left(2) == code:
		return
	GameState.set_lang(code)
	TranslationServer.set_locale(code)
	get_tree().reload_current_scene()


func _refresh() -> void:
	_sound.text = tr("SOUND_ON") if GameState.sound_on else tr("SOUND_OFF")
	var current: String = TranslationServer.get_locale().left(2)
	_ru.theme_type_variation = &"" if current == "ru" else &"SecondaryButton"
	_en.theme_type_variation = &"" if current == "en" else &"SecondaryButton"
