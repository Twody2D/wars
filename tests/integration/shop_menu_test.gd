extends GdUnitTestSuite
## Main menu with the shop (T20): the 4-tab bar, the shop grid laid out like
## the mockup (1280×720), prices from the (mock) catalog. Opening the shop only
## reads the save; nothing is bought here.

const MENU: PackedScene = preload("res://scenes/menu/main.tscn")

var menu: MainMenu


func before_test() -> void:
	menu = auto_free(MENU.instantiate())
	add_child(menu)
	await await_idle_frame()


func test_tab_bar_has_four_tabs_shop_first() -> void:
	var shop: Button = menu.get_node(^"%TabShop")
	var battle: Button = menu.get_node(^"%TabBattle")
	var map: Button = menu.get_node(^"%TabMap")
	# Battle is open: Shop 204 wide at x 22, Battle raised 220×118 at 234.
	assert_vector(shop.position).is_equal(Vector2(22.0, 26.0))
	assert_vector(shop.size).is_equal(Vector2(204.0, 102.0))
	assert_vector(battle.position).is_equal(Vector2(234.0, 4.0))
	assert_vector(battle.size).is_equal(Vector2(220.0, 118.0))
	assert_float(map.position.x + map.size.x).is_equal(878.0)


func test_plus_opens_the_shop() -> void:
	var plus: BaseButton = menu.get_node(^"%PlusButton")
	plus.pressed.emit()
	await await_idle_frame()
	var shop: ShopScreen = menu.get_node(^"%ShopTab")
	assert_bool(shop.visible).is_true()
	assert_bool((menu.get_node(^"%BattleTab") as Control).visible).is_false()
	var tab: Button = menu.get_node(^"%TabShop")
	assert_vector(tab.position).is_equal(Vector2(22.0, 4.0))


func test_shop_grid_matches_the_mockup() -> void:
	menu.call(&"_open_tab", MainMenu.TAB_SHOP)
	await await_millis(50)
	var shop: ShopScreen = menu.get_node(^"%ShopTab")
	var grid: Control = shop.get_node(^"%Grid")
	var hero: ShopHero = shop.get_node(^"%Hero")
	assert_vector(grid.position).is_equal(Vector2(24.0, 118.0))
	assert_vector(hero.position).is_equal(Vector2.ZERO)
	assert_vector(hero.size).is_equal(Vector2(608.0, 222.0))
	var cards: Array[ShopCard] = []
	for child: Node in grid.get_children():
		if child is ShopCard:
			cards.append(child)
	assert_int(cards.size()).is_equal(6)
	var expected: Array[Vector2] = [Vector2(624, 0), Vector2(936, 0), Vector2(0, 234), Vector2(312, 234),
		Vector2(624, 234), Vector2(936, 234)]
	for i: int in cards.size():
		assert_vector(cards[i].position).is_equal(expected[i])
		assert_vector(cards[i].size).is_equal(Vector2(296.0, 222.0))
	# Mock catalog: no currency icon → "<price> <code>" as text.
	var bag: ShopCard = cards[3]
	assert_str(String(bag.product.id)).is_equal("coins_bag")
	var price: Label = bag.get_node(^"%PriceButton/Price")
	assert_str(price.text).is_equal("99 YAN")
	var free: ShopCard = cards[5]
	assert_bool((free.get_node(^"%AdButton") as Control).visible).is_true()
