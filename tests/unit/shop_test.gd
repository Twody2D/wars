extends GdUnitTestSuite
## Shop and in-app purchases (T20, Yandex 1.13): every product is granted,
## a restart does not grant twice, "No ads" stops fullscreen ads, the golden
## pickaxe doubles battle coins, the free coins cooldown. Private GameState
## with autosave off and a private PlatformMock — nothing real is touched.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const NOW := 1_800_000_000

var gs: Node
var server: PlatformMock


func before_test() -> void:
	gs = _fresh()
	server = auto_free(PlatformMock.new())


func after_test() -> void:
	gs.free()


func _fresh() -> Node:
	var state: Node = GameStateScript.new()
	state.set(&"autosave", false)
	state.set(&"config", load("res://data/game_config.tres"))
	state.call(&"from_dict", {})
	return state


func _coins() -> int:
	return gs.get(&"coins")


## Buy through the mock "server" and deliver like Platform does.
func _buy(id: StringName) -> String:
	server.purchase(id)
	var entry: Dictionary = server.purchases[server.purchases.size() - 1]
	var token: String = entry["purchaseToken"]
	Purchases.deliver(gs, server, id, token)
	return token


func test_shop_data_matches_the_task() -> void:
	var shop: ShopData = load("res://data/shop/shop.tres")
	var ids: Array[StringName] = []
	for p: ProductData in shop.products:
		ids.append(p.id)
		assert_bool(p.art != null).is_true()
	assert_array(ids).is_equal([&"starter_pack", &"no_ads", &"gold_pickaxe", &"coins_small", &"coins_bag", &"coins_chest", &"free_coins"])
	assert_int(shop.product(&"coins_small").coins).is_equal(2000)
	assert_int(shop.product(&"coins_bag").coins).is_equal(8000)
	assert_int(shop.product(&"coins_chest").coins).is_equal(25000)
	assert_int(shop.product(&"free_coins").coins).is_equal(500)
	assert_int(shop.free_coins_cooldown_sec).is_equal(900)
	# The catalog lists only real in-app products (free coins are an ad).
	assert_int(server.get_catalog().size()).is_equal(6)


func test_coin_packs_are_granted_and_consumed() -> void:
	_buy(&"coins_small")
	_buy(&"coins_bag")
	_buy(&"coins_chest")
	assert_int(_coins()).is_equal(35000)
	assert_array(server.purchases).is_empty()


func test_starter_pack_gives_goblin_and_coins_once() -> void:
	assert_bool(gs.call(&"is_unit_unlocked", &"goblin_miner")).is_false()
	_buy(&"starter_pack")
	assert_bool(gs.call(&"is_unit_unlocked", &"goblin_miner")).is_true()
	assert_bool(gs.call(&"owns", &"starter_pack")).is_true()
	assert_int(_coins()).is_equal(5000)
	# Not consumed: the platform keeps it, so it comes back on a new device.
	assert_int(server.purchases.size()).is_equal(1)
	# A second grant (another token) gives nothing: the flag is in the save.
	assert_bool(gs.call(&"grant_product", &"starter_pack", "other")).is_false()
	assert_int(_coins()).is_equal(5000)


func test_forever_products_are_not_consumed() -> void:
	_buy(&"no_ads")
	_buy(&"gold_pickaxe")
	assert_bool(gs.call(&"owns", &"no_ads")).is_true()
	assert_bool(gs.call(&"owns", &"gold_pickaxe")).is_true()
	assert_int(server.purchases.size()).is_equal(2)


func test_restart_does_not_grant_twice() -> void:
	_buy(&"no_ads")
	_buy(&"coins_bag")
	# An unconsumed coins purchase left by a crash before consume().
	server.purchases.append({"productID": "coins_small", "purchaseToken": "crash-1"})
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gs.call(&"to_dict")))
	# Launch 1: the pending coins are granted and consumed; no_ads stays owned.
	gs.call(&"from_dict", saved)
	var given: Array[StringName] = await Purchases.restore(gs, server)
	assert_array(given).is_equal([&"coins_small"])
	assert_int(_coins()).is_equal(10000)
	# Launch 2: nothing new.
	given = await Purchases.restore(gs, server)
	assert_array(given).is_empty()
	assert_int(_coins()).is_equal(10000)
	assert_array(server.purchases).is_equal([{"productID": "no_ads", "purchaseToken": "mock-1"}])


func test_same_token_is_granted_once() -> void:
	# Saved, but consume() never reached the server: the SDK delivers it again.
	assert_bool(gs.call(&"grant_product", &"coins_bag", "t-1")).is_true()
	server.purchases.append({"productID": "coins_bag", "purchaseToken": "t-1"})
	var given: Array[StringName] = await Purchases.restore(gs, server)
	assert_array(given).is_empty()
	assert_int(_coins()).is_equal(8000)
	assert_array(server.purchases).is_empty()


func test_new_device_restores_forever_products() -> void:
	_buy(&"no_ads")
	_buy(&"gold_pickaxe")
	var other: Node = _fresh()
	var given: Array[StringName] = await Purchases.restore(other, server)
	assert_array(given).contains_exactly_in_any_order([&"no_ads", &"gold_pickaxe"])
	assert_bool(other.call(&"owns", &"gold_pickaxe")).is_true()
	other.free()


func test_new_device_restores_starter_pack() -> void:
	_buy(&"starter_pack")
	var other: Node = _fresh()
	var given: Array[StringName] = await Purchases.restore(other, server)
	assert_array(given).is_equal([&"starter_pack"])
	assert_bool(other.call(&"owns", &"starter_pack")).is_true()
	assert_bool(other.call(&"is_unit_unlocked", &"goblin_miner")).is_true()
	# The next launch on that device gives nothing again.
	given = await Purchases.restore(other, server)
	assert_array(given).is_empty()
	other.free()


func test_no_ads_stops_fullscreen_ads() -> void:
	assert_bool(Purchases.ads_allowed(gs)).is_true()
	_buy(&"no_ads")
	assert_bool(Purchases.ads_allowed(gs)).is_false()


func test_gold_pickaxe_doubles_battle_coins() -> void:
	var balance: BalanceData = gs.call(&"balance")
	var level: LevelData = gs.call(&"level", 1)
	var mult: float = gs.call(&"coin_multiplier")
	var win: int = Rewards.coins_for(balance, level, 10, true, 3, mult)
	var lose: int = Rewards.coins_for(balance, level, 10, false, 0, mult)
	_buy(&"gold_pickaxe")
	mult = gs.call(&"coin_multiplier")
	assert_float(mult).is_equal(2.0)
	assert_int(Rewards.coins_for(balance, level, 10, true, 3, mult)).is_equal(win * 2)
	assert_int(Rewards.coins_for(balance, level, 10, false, 0, mult)).is_equal(lose * 2)


func test_free_coins_cooldown() -> void:
	assert_int(gs.call(&"free_coins_left", NOW)).is_equal(0)
	assert_bool(gs.call(&"claim_free_coins", NOW)).is_true()
	assert_int(_coins()).is_equal(500)
	assert_int(gs.call(&"free_coins_left", NOW + 60)).is_equal(840)
	assert_bool(gs.call(&"claim_free_coins", NOW + 899)).is_false()
	assert_int(_coins()).is_equal(500)
	assert_bool(gs.call(&"claim_free_coins", NOW + 900)).is_true()
	assert_int(_coins()).is_equal(1000)
	# The time survives a save; a clock set back never waits longer than the cooldown.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gs.call(&"to_dict")))
	gs.call(&"from_dict", saved)
	assert_int(gs.call(&"free_coins_left", NOW + 900)).is_equal(900)
	assert_int(gs.call(&"free_coins_left", NOW - 5000)).is_equal(900)


func test_starter_offer_once_after_level_3() -> void:
	assert_bool(gs.call(&"starter_offer_due")).is_false()
	var stars: Dictionary[int, int] = {1: 3, 2: 3, 3: 2}
	gs.set(&"level_stars", stars)
	assert_bool(gs.call(&"starter_offer_due")).is_true()
	gs.call(&"mark_starter_offer_shown")
	assert_bool(gs.call(&"starter_offer_due")).is_false()


func test_cloud_merge_keeps_purchases_of_both_sides() -> void:
	_buy(&"no_ads")
	var local_stars: Dictionary[int, int] = {1: 3, 2: 3}
	gs.set(&"level_stars", local_stars)
	var cloud_state: Node = _fresh()
	cloud_state.call(&"grant_product", &"gold_pickaxe", "")
	var cloud: Dictionary = JSON.parse_string(JSON.stringify(cloud_state.call(&"to_dict")))
	cloud_state.free()
	# Local has more progress and wins, but the pickaxe bought elsewhere stays.
	gs.call(&"merge_cloud", cloud)
	assert_bool(gs.call(&"owns", &"no_ads")).is_true()
	assert_bool(gs.call(&"owns", &"gold_pickaxe")).is_true()


func test_bad_shop_save_is_sanitised() -> void:
	gs.call(&"from_dict", {"shop": {"owned": ["no_ads", "coins_bag", "hack", 5], "tokens": "x", "free_coins_at": -7}})
	assert_bool(gs.call(&"owns", &"no_ads")).is_true()
	assert_bool(gs.call(&"owns", &"coins_bag")).is_false()
	assert_bool(gs.call(&"owns", &"hack")).is_false()
	assert_int(gs.get(&"free_coins_at")).is_equal(0)


func test_yandex_purchase_callbacks() -> void:
	var yandex: PlatformYandex = auto_free(PlatformYandex.new())
	var done: Array = []
	var failed: Array[StringName] = []
	yandex.purchase_done.connect(func(id: StringName, token: String) -> void: done.append([id, token]))
	yandex.purchase_failed.connect(func(id: StringName) -> void: failed.append(id))
	yandex._purchase_id = &"coins_bag"
	yandex._purchase_open = true
	yandex._on_purchase(["ok", "tok"])
	yandex._on_purchase(["ok", "tok"])
	assert_array(done).is_equal([[&"coins_bag", "tok"]])
	yandex._purchase_open = true
	yandex._on_purchase(["fail", ""])
	assert_array(failed).is_equal([&"coins_bag"])
	assert_int(PlatformYandex._parse_list("[{\"id\":\"no_ads\"}, 3]").size()).is_equal(1)
	assert_array(PlatformYandex._parse_list("oops")).is_empty()
