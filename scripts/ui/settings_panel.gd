class_name SettingsPanel
extends Control
## Settings (SPEC 8, v3 window): sound on/off, language, battle speed on/off
## (once bought on the upgrades screen). Language names are written in their
## own language. Changing the language saves it and reloads the scene so every
## text and the logo pick it up.

@onready var _sound: Button = %SoundButton
@onready var _ru: Button = %RuButton
@onready var _en: Button = %EnButton
@onready var _speed: Button = %SpeedButton
@onready var _close: Button = %CloseButton


func _ready() -> void:
	_sound.pressed.connect(_toggle_sound)
	_ru.pressed.connect(_set_lang.bind("ru"))
	_en.pressed.connect(_set_lang.bind("en"))
	_speed.pressed.connect(_toggle_speed)
	_close.pressed.connect(func() -> void: visible = false)


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


func _toggle_speed() -> void:
	GameState.set_battle_speed(not GameState.battle_speed_on)
	_refresh()


func _set_lang(code: String) -> void:
	if TranslationServer.get_locale().left(2) == code:
		return
	GameState.set_lang(code)
	TranslationServer.set_locale(code)
	# Opened from the battle pause: the reloaded scene must not start paused.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _refresh() -> void:
	_sound.text = tr("SOUND_ON") if GameState.sound_on else tr("SOUND_OFF")
	var current: String = TranslationServer.get_locale().left(2)
	_ru.theme_type_variation = &"" if current == "ru" else &"GreyButton"
	_en.theme_type_variation = &"" if current == "en" else &"GreyButton"
	_speed.visible = GameState.upgrade_level(&"battle_speed") > 0
	_speed.text = tr("SPEED_FMT") % (tr("ON") if GameState.battle_speed_on else tr("OFF"))
