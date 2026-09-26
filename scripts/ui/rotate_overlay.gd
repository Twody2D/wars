extends CanvasLayer
## Portrait screen (phone held upright, SPEC 8): "Rotate the device" over
## everything, blocks input and pauses the battle. Autoload scene.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_update)
	_update()


func _update() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var portrait: bool = size.y > size.x
	if portrait and not visible:
		Platform.request_pause()
	visible = portrait
