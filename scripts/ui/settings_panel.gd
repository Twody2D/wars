class_name SettingsPanel
extends Control
## Settings (SPEC 8, v3 window): music on/off, sound effects on/off, battle speed on/off (once
## bought on the upgrades screen). No language switch: Yandex picks the
## language from the SDK at launch (requirement 2.14).

@onready var _music: Button = %MusicButton
@onready var _sound: Button = %SoundButton
@onready var _speed: Button = %SpeedButton
@onready var _close: Button = %CloseButton


func _ready() -> void:
	_music.pressed.connect(_toggle_music)
	_sound.pressed.connect(_toggle_sound)
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


func _toggle_music() -> void:
	GameState.set_music(not GameState.music_on)
	Platform.update_mute()
	_refresh()


func _toggle_sound() -> void:
	GameState.set_sound(not GameState.sound_on)
	Platform.update_mute()
	_refresh()


func _toggle_speed() -> void:
	GameState.set_battle_speed(not GameState.battle_speed_on)
	_refresh()


func _refresh() -> void:
	_music.text = tr("MUSIC_ON") if GameState.music_on else tr("MUSIC_OFF")
	_sound.text = tr("SOUND_ON") if GameState.sound_on else tr("SOUND_OFF")
	_speed.visible = GameState.upgrade_level(&"battle_speed") > 0
	_speed.text = tr("SPEED_FMT") % (tr("ON") if GameState.battle_speed_on else tr("OFF"))
