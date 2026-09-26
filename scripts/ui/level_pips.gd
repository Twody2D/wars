class_name LevelPips
extends HBoxContainer
## Level as a row of squares (filled = bought), readable on a phone without text.

@export var full: Texture2D
@export var empty: Texture2D
## Pip width; the height follows the texture.
@export var pip_size: float = 20.0

var _pips: Array[TextureRect] = []


func set_level(level: int, max_level: int) -> void:
	while _pips.size() < max_level:
		var pip := TextureRect.new()
		pip.custom_minimum_size = Vector2(pip_size, pip_size * full.get_height() / full.get_width())
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pip)
		_pips.append(pip)
	for i: int in _pips.size():
		_pips[i].visible = i < max_level
		_pips[i].texture = full if i < level else empty
