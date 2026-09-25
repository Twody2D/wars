class_name OreBlock
extends TextureButton
## Ore on the field: tap/click → +food, then cools down (SPEC 4).

signal mined(index: int)

@export var index: int = 0
@export var hover_scale: float = 1.15
@export var hover_tint: Color = Color(1.3, 1.3, 1.15)

var _tween: Tween
var _hovered: bool = false
var _cooling: bool = false

@onready var _cooldown: TextureProgressBar = $Cooldown


func _ready() -> void:
	pressed.connect(func() -> void: mined.emit(index))
	pivot_offset = size / 2.0
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		_hovered = true
		_update_look())
	mouse_exited.connect(func() -> void:
		_hovered = false
		_update_look())


## ratio 0 — ready, 1 — just mined.
func set_cooldown(ratio: float) -> void:
	var cooling: bool = ratio > 0.0
	disabled = cooling
	_cooldown.visible = cooling
	_cooldown.value = ratio * 100.0
	if cooling != _cooling:
		_cooling = cooling
		_update_look()


func _update_look() -> void:
	if _cooling:
		modulate = Color(0.55, 0.55, 0.55)
	elif _hovered:
		modulate = hover_tint
	else:
		modulate = Color.WHITE
	if _tween == null or not _tween.is_running():
		scale = Vector2.ONE * (hover_scale if _hovered and not _cooling else 1.0)


func punch() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = Vector2(0.8, 0.8)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * (hover_scale if _hovered else 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
