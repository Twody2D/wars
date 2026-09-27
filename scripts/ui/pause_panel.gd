class_name PausePanel
extends Control
## Pause overlay (SPEC 8, battle v3 kit): continue, settings, menu. Works while
## the tree is paused.

signal resume_pressed
signal settings_pressed
signal menu_pressed

@onready var _resume: Button = %ResumeButton
@onready var _settings: Button = %SettingsButton
@onready var _menu: Button = %MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_resume.pressed.connect(resume_pressed.emit)
	_settings.pressed.connect(settings_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)
	visible = false


func open() -> void:
	visible = true
	_resume.grab_focus()


## Esc (the "pause" action) on the open pause screen goes back to the battle.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		resume_pressed.emit()
