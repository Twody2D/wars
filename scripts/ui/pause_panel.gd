class_name PausePanel
extends Control
## Pause overlay (SPEC 8): continue, restart, sound, menu. Works while the tree is paused.

signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var _resume: Button = %ResumeButton
@onready var _restart: Button = %RestartButton
@onready var _menu: Button = %MenuButton
@onready var _sound: Button = %SoundButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_resume.pressed.connect(resume_pressed.emit)
	_restart.pressed.connect(restart_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)
	_sound.pressed.connect(_toggle_sound)
	visible = false


func open() -> void:
	_update_sound()
	visible = true
	_resume.grab_focus()


func _toggle_sound() -> void:
	GameState.set_sound(not GameState.sound_on)
	AudioServer.set_bus_mute(0, not GameState.sound_on)
	_update_sound()


func _update_sound() -> void:
	_sound.text = tr("SOUND_ON") if GameState.sound_on else tr("SOUND_OFF")
