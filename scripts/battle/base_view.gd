class_name BaseView
extends Node2D
## A base on the field: sprite by HP (100–60% / 60–25% / < 25%), shake on hit,
## HP bar above it (SPEC 2, T07).

@export var intact: Texture2D
@export var damaged: Texture2D
@export var destroyed: Texture2D
@export var bar_fill: Texture2D
@export var damaged_below: float = 0.6
@export var destroyed_below: float = 0.25
@export var shake_px: float = 4.0

var _ratio: float = 1.0
var _tween: Tween
## HP share → star mark above the bar (player base only, SPEC 6).
var _star_marks: Dictionary[float, TextureRect] = {}

@onready var _sprite: Sprite2D = $Sprite
@onready var _bar: TextureProgressBar = $HpBar
@onready var _hp_label: Label = $HpBar/Value
## Optional dome over the bot base (see BattleBot.is_shielded).
@onready var _shield: CanvasItem = get_node_or_null(^"Shield")
var _shield_on: bool = false
var _shield_tween: Tween


func _ready() -> void:
	if bar_fill != null:
		_bar.texture_progress = bar_fill
	_sprite.texture = intact
	if _shield != null:
		_shield.visible = false
		_shield.modulate.a = 0.0


func set_hp(hp: float, max_hp: float) -> void:
	_ratio = hp / max_hp if max_hp > 0.0 else 0.0
	_bar.value = _ratio * 100.0
	_hp_label.text = str(ceili(hp))
	if _ratio < destroyed_below:
		_sprite.texture = destroyed
	elif _ratio < damaged_below:
		_sprite.texture = damaged
	else:
		_sprite.texture = intact
	_update_star_marks()


## Shows where the stars are lost: a star with a tick at each HP threshold.
## The star dims when the base HP drops below it.
func set_star_marks(three_stars_hp: float, two_stars_hp: float) -> void:
	var box: Control = get_node_or_null("HpBar/StarMarks")
	if box == null:
		return
	_star_marks.clear()
	var marks: Dictionary[String, float] = {"Star3": three_stars_hp, "Star2": two_stars_hp}
	for mark_name: String in marks:
		var mark: TextureRect = box.get_node(mark_name)
		mark.position.x = marks[mark_name] * _bar.size.x - mark.size.x / 2.0
		_star_marks[marks[mark_name]] = mark
	_update_star_marks()


func _update_star_marks() -> void:
	for threshold: float in _star_marks:
		_star_marks[threshold].modulate = Color.WHITE if _ratio >= threshold else Color(0.3, 0.3, 0.35, 0.7)


func hit() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	for i: int in 4:
		var dx: float = shake_px if i % 2 == 0 else -shake_px
		_tween.tween_property(_sprite, "offset:x", dx, 0.03)
	_tween.tween_property(_sprite, "offset:x", 0.0, 0.03)


## Fades the shield dome in or out.
func set_shield(on: bool) -> void:
	if _shield == null or on == _shield_on:
		return
	_shield_on = on
	if _shield_tween != null and _shield_tween.is_valid():
		_shield_tween.kill()
	_shield.visible = true
	_shield_tween = create_tween()
	if on:
		_shield_tween.tween_property(_shield, "modulate:a", 1.0, 0.4)
	else:
		# Breaks: a flash and a quick fade.
		_shield_tween.tween_property(_shield, "scale", Vector2(1.25, 1.25), 0.25)
		_shield_tween.parallel().tween_property(_shield, "modulate:a", 0.0, 0.25)
		_shield_tween.tween_callback(_shield.hide)


## A hit stopped by the shield: the dome flashes.
func shield_hit() -> void:
	if _shield == null or not _shield_on:
		return
	if _shield_tween != null and _shield_tween.is_valid():
		return
	_shield_tween = create_tween()
	_shield_tween.tween_property(_shield, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.06)
	_shield_tween.tween_property(_shield, "modulate", Color.WHITE, 0.2)
