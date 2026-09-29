class_name ShopOffer
extends Control
## Starter pack offer (T20, mockup popup_starter_offer): once, over the main
## menu after a win on the offer level. Buying goes through Platform; the menu
## closes this window and shows "Purchase received!".

@export var rays_speed: float = 0.1

var product: ProductData
var _busy: bool = false
var _rays_tween: Tween

@onready var _rays: Control = %Rays
@onready var _window: Control = %Window
@onready var _coins_label: Label = %CoinsLabel
@onready var _sticker_label: Label = %StickerLabel
@onready var _buy: Button = %BuyButton
@onready var _currency: TextureRect = _buy.get_node(^"Currency")
@onready var _price: Label = _buy.get_node(^"Price")
@onready var _close: Button = %CloseButton


func _ready() -> void:
	_buy.pressed.connect(_on_buy)
	_close.pressed.connect(close)
	Platform.purchase_failed.connect(_on_failed)
	Platform.currency_icon_changed.connect(_refresh)


## False — the starter pack has no price in the catalog (nothing is shown).
func open(p: ProductData) -> bool:
	product = p
	_coins_label.text = tr("SHOP_COINS_FMT") % UnitTile._format(p.coins)
	_sticker_label.text = tr(p.sticker_key)
	_busy = false
	if not _refresh():
		return false
	visible = true
	_rays_tween = create_tween().set_loops()
	_rays_tween.tween_property(_rays, "rotation", TAU, 1.0 / rays_speed).from(0.0)
	_window.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(_window, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_buy.grab_focus()
	return true


func close() -> void:
	visible = false
	if _rays_tween != null:
		_rays_tween.kill()


func _refresh() -> bool:
	if product == null:
		return false
	var priced: bool = ShopCard.show_price(product.id, _price, _currency)
	_buy.disabled = _busy or not priced
	return priced


func _on_buy() -> void:
	_busy = true
	_refresh()
	Platform.purchase(product.id)


func _on_failed(_id: StringName) -> void:
	_busy = false
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
