class_name HowToPlay
extends Control
## "How to play" (Yandex requirement 2.2): three pictures with one line each —
## cards, ore, meteor — and the goal. Opened from the "?" button in the menu;
## Esc or "Got it" closes it.

@onready var _ok: Button = %OkButton


func _ready() -> void:
	_ok.pressed.connect(func() -> void: visible = false)


func open() -> void:
	visible = true
	_ok.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		visible = false
