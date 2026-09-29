class_name ShopReward
extends Control
## "Purchase received!" (T20): the product picture in light rays and what it
## gave — coins, or the effect of a forever item.

## Turns per second of the light rays.
@export var rays_speed: float = 0.1

var _rays_tween: Tween

@onready var _rays: Control = %Rays
@onready var _window: Control = %Window
@onready var _art: TextureRect = %Art
@onready var _amount: Control = %Amount
@onready var _amount_label: Label = %AmountLabel
@onready var _effect: Label = %Effect
@onready var _ok: Button = %OkButton


func _ready() -> void:
	_ok.pressed.connect(close)


func open(product: ProductData) -> void:
	if product == null:
		return
	_art.texture = product.art
	_amount.visible = product.coins > 0
	_amount_label.text = "+" + UnitTile._format(product.coins)
	_effect.visible = product.coins <= 0
	_effect.text = tr(product.effect_key if product.effect_key != "" else product.name_key)
	visible = true
	Audio.play_sfx(&"coin", false)
	if _rays_tween != null:
		_rays_tween.kill()
	_rays_tween = create_tween().set_loops()
	_rays_tween.tween_property(_rays, "rotation", TAU, 1.0 / rays_speed).from(0.0)
	_window.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(_window, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ok.grab_focus()


func close() -> void:
	visible = false
	if _rays_tween != null:
		_rays_tween.kill()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
