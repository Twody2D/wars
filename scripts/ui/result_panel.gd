class_name ResultPanel
extends Control
## Battle result (SPEC 6): stars, coins, ×2 coins for a rewarded ad, next, menu.

signal next_pressed
signal menu_pressed

const AD_TAG := &"double_coins"

var _result: BattleResult

@onready var _title: Label = %Title
@onready var _stars: Array[TextureRect] = [%Star1, %Star2, %Star3]
@onready var _coins: Label = %CoinsValue
@onready var _double: Button = %DoubleButton
@onready var _next: Button = %NextButton
@onready var _menu: Button = %MenuButton
@onready var _hint: Label = %Hint


func _ready() -> void:
	visible = false
	_double.pressed.connect(_on_double)
	_next.pressed.connect(next_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)
	Platform.rewarded.connect(_on_rewarded)


func show_result(result: BattleResult) -> void:
	_result = result
	_title.text = tr("RESULT_WIN") if result.won else tr("RESULT_LOSE")
	for i: int in _stars.size():
		_stars[i].modulate = Color.WHITE if i < result.stars else Color(0.2, 0.2, 0.25, 0.6)
		_stars[i].visible = result.won
	_coins.text = "+%d" % result.coins
	_double.disabled = result.coins <= 0
	_next.text = tr("BTN_NEXT") if result.won else tr("BTN_RETRY")
	_hint.visible = not result.won
	_hint.text = tr("HINT_UPGRADE")
	visible = true
	scale = Vector2(0.8, 0.8)
	pivot_offset = size / 2.0
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_double() -> void:
	_double.disabled = true
	Platform.show_rewarded(AD_TAG)


func _on_rewarded(tag: StringName) -> void:
	if tag != AD_TAG or _result == null or _result.doubled:
		return
	_result.doubled = true
	GameState.add_coins(_result.coins)
	_coins.text = "+%d" % (_result.coins * 2)
