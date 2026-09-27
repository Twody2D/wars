class_name BattleBanner
extends Control
## Big announcement over the battle field (battle v3 kit: an orange ribbon, a
## red one for the final wave / boss): level start, each wave, the final wave.
## Pops in, holds, fades out; never blocks input.

@export var pop_time: float = 0.35
@export var hold_time: float = 1.6
@export var fade_time: float = 0.5
@export var normal_texture: Texture2D
## Final wave / boss.
@export var danger_texture: Texture2D

var _tween: Tween

@onready var _box: Control = %Box
@onready var _plate: TextureRect = %Plate
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle


func _ready() -> void:
	visible = false


func announce(title: String, subtitle: String, danger: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_plate.texture = danger_texture if danger else normal_texture
	_title.text = title
	_subtitle.text = subtitle
	visible = true
	modulate = Color.WHITE
	_box.scale = Vector2(0.5, 0.5)
	_tween = create_tween()
	_tween.tween_property(_box, "scale", Vector2.ONE, pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(func() -> void: visible = false)
