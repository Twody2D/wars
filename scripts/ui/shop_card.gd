class_name ShopCard
extends Control
## One shop card (T20, mockup "Screen Shop"): a forever item (gold frame), a
## coins pack (blue) or free coins for an ad (green). Bought forever items turn
## grey with an "Owned" plate.

signal buy_pressed(id: StringName)
signal free_pressed

## Frames: gold, coins, free, bought.
@export var frames: Dictionary[String, Texture2D] = {}
## Glows behind the picture: gold, blue, green.
@export var glows: Dictionary[String, Texture2D] = {}
## Greys out the picture of a bought item.
@export var gray: Material
## Picture size and top: forever items / coins and free coins.
@export var art_forever := Rect2(0.0, 32.0, 124.0, 124.0)
@export var art_coins := Rect2(0.0, 30.0, 128.0, 128.0)
@export_range(0.0, 1.0) var bought_alpha: float = 0.45
## Title size; the long "Coins for an ad" is a bit smaller.
@export var title_size: int = 26
@export var title_size_free: int = 24

var product: ProductData

@onready var _frame: NinePatchRect = %Frame
@onready var _glow: TextureRect = %Glow
@onready var _art: TextureRect = %Art
@onready var _title: Label = %Title
@onready var _effect: Label = %Effect
@onready var _amount: Control = %Amount
@onready var _amount_label: Label = %AmountLabel
@onready var _ribbon: TextureRect = %Ribbon
@onready var _ribbon_label: Label = %RibbonLabel
@onready var _price_button: Button = %PriceButton
@onready var _currency: TextureRect = _price_button.get_node(^"Currency")
@onready var _price: Label = _price_button.get_node(^"Price")
@onready var _bought: Control = %Bought
@onready var _ad_button: Button = %AdButton
@onready var _ad_label: Label = %AdLabel
@onready var _wait: Control = %Wait
@onready var _time: Label = %TimeLabel
@onready var _ad_badge: Control = %AdBadge


func _ready() -> void:
	_price_button.pressed.connect(func() -> void: buy_pressed.emit(product.id))
	_ad_button.pressed.connect(free_pressed.emit)


func setup(p: ProductData) -> void:
	product = p
	_title.text = tr(p.name_key)
	_art.texture = p.art
	var forever: bool = p.kind == ProductData.Kind.PERMANENT
	var box: Rect2 = art_forever if forever else art_coins
	_art.offset_left = -box.size.x / 2.0
	_art.offset_right = box.size.x / 2.0
	_art.offset_top = box.position.y
	_art.offset_bottom = box.position.y + box.size.y
	_effect.visible = forever
	_effect.text = tr(p.effect_key)
	_amount.visible = not forever
	_amount_label.text = ("+" if p.kind == ProductData.Kind.FREE else "") + UnitTile._format(p.coins)
	_ribbon.visible = p.ribbon != null
	_ribbon.texture = p.ribbon
	_ribbon_label.text = tr(p.ribbon_key)
	var free: bool = p.kind == ProductData.Kind.FREE
	# Free coins: the green card and the violet ad button with a video badge.
	_title.add_theme_font_size_override(&"font_size", title_size_free if free else title_size)
	_price_button.visible = not free
	_ad_button.visible = free
	_glow.texture = glows["green" if free else ("gold" if forever else "blue")]
	_frame.texture = frames["free" if free else ("gold" if forever else "coins")]


## `busy` — a purchase or an ad is in progress: no second one.
func refresh(busy: bool, now: int) -> void:
	if product == null:
		return
	match product.kind:
		ProductData.Kind.PERMANENT:
			var owned: bool = GameState.owns(product.id)
			_frame.texture = frames["bought" if owned else "gold"]
			_glow.visible = not owned
			_art.material = gray if owned else null
			_art.modulate.a = bought_alpha if owned else 1.0
			_effect.theme_type_variation = &"MutedLabel" if owned else &"GreenLabel"
			_bought.visible = owned
			_price_button.visible = not owned
			_price_button.disabled = busy or not show_price(product.id, _price, _currency)
		ProductData.Kind.COINS:
			_price_button.disabled = busy or not show_price(product.id, _price, _currency)
		ProductData.Kind.FREE:
			var left: int = GameState.free_coins_left(now)
			_ad_button.disabled = busy or left > 0
			_ad_label.visible = left <= 0
			_ad_badge.visible = left <= 0
			_wait.visible = left > 0
			_time.text = "%d:%02d" % [floori(left / 60.0), left % 60]


## Price from the SDK catalog (Yandex 1.13.4): the number next to the portal
## currency icon; without the icon — "<price> <currency code>" as text.
## False — the product is not in the catalog (no price, the button is off).
static func show_price(id: StringName, label: Label, icon: TextureRect) -> bool:
	var info: Dictionary = Platform.product_info(id)
	if info.is_empty():
		label.text = ""
		icon.visible = false
		return false
	icon.texture = Platform.currency_icon
	icon.visible = icon.texture != null
	label.text = str(info.get("priceValue", "")) if icon.visible else str(info.get("price", ""))
	return true
