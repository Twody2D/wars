class_name ShopScreen
extends Control
## Shop tab (T20, mockup "Screen Shop"): the starter pack on two columns, the
## forever items, coin packs and free coins for an ad in a 4-column grid.
## Prices come from the SDK catalog; a purchase is delivered by Platform and
## GameState, the menu shows the "Purchase received!" window.

## The catalog is empty: the SDK is offline or payments are off.
signal unavailable
signal free_coins_claimed(product: ProductData)

const FREE_TAG := &"free_coins"

@export var card_scene: PackedScene
## Grid from the mockup: top, widest width, side margin, gaps, row height.
@export var grid_top: float = 118.0
@export var grid_max_width: float = 1232.0
@export var grid_side: float = 20.0
@export var column_gap: float = 16.0
@export var row_gap: float = 18.0
@export var row_height: float = 216.0
@export var card_height: float = 222.0
@export var columns: int = 4

var _cards: Array[ShopCard] = []
var _busy: bool = false
var _ad_running: bool = false

@onready var _grid: Control = %Grid
@onready var _hero: ShopHero = %Hero


func _ready() -> void:
	for p: ProductData in GameState.shop.products:
		if p.kind == ProductData.Kind.STARTER:
			_hero.setup(p)
			_hero.buy_pressed.connect(_buy)
			continue
		var card: ShopCard = card_scene.instantiate()
		_grid.add_child(card)
		card.setup(p)
		card.buy_pressed.connect(_buy)
		card.free_pressed.connect(_watch_ad)
		_cards.append(card)
	resized.connect(_layout)
	GameState.changed.connect(refresh)
	Platform.currency_icon_changed.connect(refresh)
	Platform.purchased.connect(_on_purchase_over)
	Platform.purchase_failed.connect(_on_purchase_over)
	Platform.rewarded.connect(_on_rewarded)
	Platform.rewarded_failed.connect(_on_rewarded_failed)
	refresh()
	_layout()


## The tab was opened: pending purchases, fresh prices.
func open() -> void:
	refresh()
	Platform.restore_purchases()
	var catalog: Array[Dictionary] = await Platform.get_catalog()
	refresh()
	_layout()
	if catalog.is_empty() and is_visible_in_tree():
		unavailable.emit()


func refresh(_arg: Variant = null) -> void:
	var now: int = int(Time.get_unix_time_from_system())
	_hero.refresh(_busy)
	for card: ShopCard in _cards:
		# Yandex 1.13.6: only products that exist in the console catalog.
		card.visible = card.product.kind == ProductData.Kind.FREE or Platform.catalog.is_empty() \
			or not Platform.product_info(card.product.id).is_empty()
		card.refresh(_busy or _ad_running, now)


## Once a second while the tab is open: the free coins timer.
func tick() -> void:
	if is_visible_in_tree():
		refresh()


## Cards fill the grid left to right; the starter pack takes two columns.
func _layout() -> void:
	var width: float = minf(grid_max_width, size.x - 2.0 * grid_side)
	var cell: float = (width - (columns - 1) * column_gap) / columns
	_grid.position = Vector2((size.x - width) / 2.0, grid_top)
	_grid.size = Vector2(width, 2.0 * row_height + row_gap)
	var items: Array[Control] = [_hero]
	for card: ShopCard in _cards:
		items.append(card)
	var slot: int = 0
	for item: Control in items:
		if not item.visible:
			continue
		var span: int = 2 if item == _hero else 1
		if slot % columns + span > columns:
			slot += columns - slot % columns
		var col: int = slot % columns
		var row: int = floori(float(slot) / columns)
		item.position = Vector2(col * (cell + column_gap), row * (row_height + row_gap))
		item.size = Vector2(span * cell + (span - 1) * column_gap, card_height)
		slot += span


func _buy(id: StringName) -> void:
	if _busy:
		return
	_busy = true
	refresh()
	Platform.purchase(id)


func _on_purchase_over(_id: StringName) -> void:
	_busy = false
	refresh()


func _watch_ad() -> void:
	if _ad_running or GameState.free_coins_left(int(Time.get_unix_time_from_system())) > 0:
		return
	_ad_running = true
	refresh()
	Platform.show_rewarded(FREE_TAG)


func _on_rewarded(tag: StringName) -> void:
	if tag != FREE_TAG or not _ad_running:
		return
	_ad_running = false
	if GameState.claim_free_coins(int(Time.get_unix_time_from_system())):
		free_coins_claimed.emit(GameState.shop.product(GameState.FREE_COINS))
	refresh()


## Ad closed early or failed: no coins, the button works again.
func _on_rewarded_failed(tag: StringName) -> void:
	if tag == FREE_TAG and _ad_running:
		_ad_running = false
		refresh()
