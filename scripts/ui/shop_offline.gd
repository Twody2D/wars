class_name ShopOffline
extends Control
## "Shop unavailable" (T20): no SDK or an empty catalog.

@onready var _close: Button = %CloseButton


func _ready() -> void:
	_close.pressed.connect(close)


func open() -> void:
	visible = true
	_close.grab_focus()


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
