extends GdUnitTestSuite
## Save validation and meta purchases (SPEC 7, 13, T11). Uses a private
## GameState instance with autosave off — the real save is never touched.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var gs: Node


func before_test() -> void:
	gs = _fresh()


func after_test() -> void:
	gs.free()


func _fresh() -> Node:
	var state: Node = GameStateScript.new()
	state.set(&"autosave", false)
	state.set(&"config", load("res://data/game_config.tres"))
	state.call(&"from_dict", {})
	return state


func test_fresh_state() -> void:
	assert_int(gs.get(&"coins")).is_equal(0)
	assert_int(gs.get(&"current_level")).is_equal(1)
	assert_bool(gs.call(&"is_unit_unlocked", &"zombie")).is_true()
	assert_bool(gs.call(&"is_unit_unlocked", &"skeleton")).is_true()
	assert_bool(gs.call(&"is_unit_unlocked", &"slime")).is_false()


func test_round_trip() -> void:
	gs.set(&"coins", 500)
	gs.call(&"buy_upgrade", &"base_hp")
	gs.call(&"unlock_unit", &"slime")
	var saved: Dictionary = gs.call(&"to_dict")
	var other: Node = _fresh()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(saved))
	other.call(&"from_dict", parsed)
	assert_int(other.get(&"coins")).is_equal(gs.get(&"coins"))
	assert_int(other.call(&"upgrade_level", &"base_hp")).is_equal(1)
	assert_bool(other.call(&"is_unit_unlocked", &"slime")).is_true()
	other.free()


func test_bad_save_is_sanitised() -> void:
	gs.call(&"from_dict", {
		"coins": -50,
		"current_level": 999,
		"biome_unlocked": "lots",
		"levels": {"1": 7, "abc": 3, "40": 2},
		"units": {"zombie": {"unlocked": true, "level": 99}, "dragon": {"unlocked": true}},
		"upgrades": {"base_hp": 1e9, "food_rate": "x"},
		"hacked": true,
	})
	assert_int(gs.get(&"coins")).is_equal(0)
	assert_int(gs.get(&"current_level")).is_equal(20)
	assert_int(gs.get(&"biome_unlocked")).is_equal(1)
	var stars: Dictionary = gs.get(&"level_stars")
	assert_int(stars.size()).is_equal(1)
	assert_int(stars[1]).is_equal(3)
	assert_int(gs.call(&"unit_level", &"zombie")).is_equal(5)
	assert_int(gs.call(&"unit_level", &"dragon")).is_equal(0)
	assert_int(gs.call(&"upgrade_level", &"base_hp")).is_equal(10)
	assert_int(gs.call(&"upgrade_level", &"food_rate")).is_equal(0)


func test_purchases_need_coins() -> void:
	assert_bool(gs.call(&"buy_upgrade", &"food_rate")).is_false()
	gs.set(&"coins", 30)
	assert_bool(gs.call(&"buy_upgrade", &"food_rate")).is_true()
	assert_int(gs.get(&"coins")).is_equal(0)
	assert_int(gs.call(&"upgrade_level", &"food_rate")).is_equal(1)


func test_setup_applies_upgrades() -> void:
	gs.set(&"coins", 10000)
	gs.call(&"buy_upgrade", &"base_hp")
	gs.call(&"buy_upgrade", &"food_rate")
	gs.call(&"buy_upgrade", &"food_rate")
	gs.call(&"buy_upgrade", &"start_food")
	var level: LevelData = gs.call(&"level", 1)
	var s: BattleSetup = gs.call(&"make_setup", level)
	assert_float(s.player_base_hp).is_equal(375.0)
	assert_float(s.food_rate).is_equal_approx(0.35, 0.0001)
	assert_float(s.food_max).is_equal(35.0)
	assert_float(s.start_food).is_equal(8.0)


func test_win_advances_level() -> void:
	var r := BattleResult.new()
	r.level_number = 1
	r.won = true
	r.stars = 2
	r.coins = 40
	gs.call(&"apply_result", r)
	assert_int(gs.get(&"current_level")).is_equal(2)
	assert_int(gs.get(&"coins")).is_equal(40)
	r.won = false
	r.level_number = 2
	gs.call(&"apply_result", r)
	assert_int(gs.get(&"current_level")).is_equal(2)
