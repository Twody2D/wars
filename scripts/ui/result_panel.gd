class_name ResultPanel
extends Control
## Battle result (SPEC 6, battle v3 kit): a gold "Победа!" or grey
## "Поражение" ribbon, stars, coins, ×2 coins for a rewarded ad, next / retry,
## menu. Light rays turn behind a victory.

signal next_pressed
signal menu_pressed

const AD_TAG := &"double_coins"
## Turns per second of the light rays behind a victory.
const RAYS_SPEED := 0.1

@export var win_ribbon: Texture2D
@export var lose_ribbon: Texture2D
@export var star_full: Texture2D
@export var star_empty: Texture2D

var _result: BattleResult
var _rays_tween: Tween

@onready var _rays: Control = %Rays
@onready var _window: Control = %Window
@onready var _ribbon: TextureRect = %Ribbon
@onready var _title: Label = %Title
@onready var _stars: Array[TextureRect] = [%Star1, %Star2, %Star3]
@onready var _coins: Label = %CoinsValue
@onready var _double: Button = %DoubleButton
@onready var _next: Button = %NextButton
@onready var _menu: Button = %MenuButton


func _ready() -> void:
	visible = false
	_double.pressed.connect(_on_double)
	_next.pressed.connect(next_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)
	Platform.rewarded.connect(_on_rewarded)
	Platform.rewarded_failed.connect(_on_rewarded_failed)


func show_result(result: BattleResult) -> void:
	_result = result
	_title.text = tr("RESULT_WIN") if result.won else tr("RESULT_LOSE")
	_ribbon.texture = win_ribbon if result.won else lose_ribbon
	for i: int in _stars.size():
		_stars[i].texture = star_full if i < result.stars else star_empty
	_coins.text = "+%d" % result.coins
	_double.disabled = result.coins <= 0
	_next.text = tr("BTN_NEXT") if result.won else tr("BTN_RETRY")
	_rays.visible = result.won
	if result.won:
		_rays_tween = create_tween().set_loops()
		_rays_tween.tween_property(_rays, "rotation", TAU, 1.0 / RAYS_SPEED).from(0.0)
	visible = true
	_window.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(_window, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_double() -> void:
	_double.disabled = true
	Platform.show_rewarded(AD_TAG)


func _on_rewarded(tag: StringName) -> void:
	if tag != AD_TAG or _result == null or _result.doubled:
		return
	_result.doubled = true
	Audio.play_sfx(&"coin", false)
	GameState.add_coins(_result.coins)
	_coins.text = "+%d" % (_result.coins * 2)


## Ad closed early or failed: no reward, the button works again.
func _on_rewarded_failed(tag: StringName) -> void:
	if tag == AD_TAG and _result != null and not _result.doubled:
		_double.disabled = false
