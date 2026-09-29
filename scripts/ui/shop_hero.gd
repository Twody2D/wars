class_name ShopHero
extends Control
## The big starter pack card (T20): goblin + coins, a price or "Owned".

signal buy_pressed(id: StringName)

@export var frame_live: Texture2D
@export var frame_bought: Texture2D
@export var gray: Material
@export_range(0.0, 1.0) var bought_alpha: float = 0.45

var product: ProductData

@onready var _frame: NinePatchRect = %Frame
@onready var _rays: Control = %Rays
@onready var _glow: Control = %Glow
@onready var _art: TextureRect = %Art
@onready var _goblin: TextureRect = %Goblin
@onready var _unit_label: Label = %UnitLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _price_button: Button = %PriceButton
@onready var _currency: TextureRect = _price_button.get_node(^"Currency")
@onready var _price: Label = _price_button.get_node(^"Price")
@onready var _bought: Control = %Bought
@onready var _sticker: Control = %Sticker
@onready var _sticker_label: Label = %StickerLabel


func _ready() -> void:
	_price_button.pressed.connect(func() -> void: buy_pressed.emit(product.id))


func setup(p: ProductData) -> void:
	product = p
	_art.texture = p.art
	var unit: UnitData = GameState.config.unit(p.unit_id)
	_unit_label.text = tr(unit.name_key) if unit != null else ""
	_coins_label.text = tr("SHOP_COINS_FMT") % UnitTile._format(p.coins)
	_sticker_label.text = tr(p.sticker_key)


func refresh(busy: bool) -> void:
	if product == null:
		return
	var owned: bool = GameState.owns(product.id)
	_frame.texture = frame_bought if owned else frame_live
	_rays.visible = not owned
	_glow.visible = not owned
	_sticker.visible = not owned
	for picture: TextureRect in [_art, _goblin]:
		picture.material = gray if owned else null
		picture.modulate.a = bought_alpha if owned else 1.0
	_bought.visible = owned
	_price_button.visible = not owned
	_price_button.disabled = busy or not ShopCard.show_price(product.id, _price, _currency)
