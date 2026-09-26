extends GdUnitTestSuite

const UNIT_IDS: Array[String] = [
	"zombie", "skeleton", "slime", "spider", "goblin_miner", "barrel_bomber",
	"boss_zombie_king", "boss_stone_golem",
]
const UPGRADE_IDS: Array[String] = ["food_rate", "base_hp", "start_food", "unit_level", "battle_speed"]


func test_all_units_load_with_sane_stats() -> void:
	for id: String in UNIT_IDS:
		var unit: UnitData = load("res://data/units/%s.tres" % id)
		assert_object(unit).is_not_null()
		assert_str(String(unit.id)).is_equal(id)
		assert_float(unit.hp).is_between(10.0, 5000.0)
		assert_float(unit.damage).is_between(1.0, 200.0)
		assert_float(unit.cooldown).is_between(0.2, 5.0)
		assert_float(unit.attack_range).is_between(10.0, 300.0)
		assert_float(unit.speed).is_between(5.0, 200.0)
		assert_float(unit.hit_delay).is_less_equal(unit.cooldown)
		assert_object(unit.visual).is_not_null()
		assert_object(unit.portrait).is_not_null()
		if not unit.is_boss:
			assert_int(unit.cost).is_between(1, 20)


func test_spec_values() -> void:
	var zombie: UnitData = load("res://data/units/zombie.tres")
	assert_float(zombie.hp).is_equal(60.0)
	assert_int(zombie.cost).is_equal(3)
	var skeleton: UnitData = load("res://data/units/skeleton.tres")
	assert_bool(skeleton.is_ranged()).is_true()
	assert_float(skeleton.attack_range).is_equal(180.0)
	var bomber: UnitData = load("res://data/units/barrel_bomber.tres")
	assert_bool(bomber.explodes).is_true()
	assert_float(bomber.splash_radius).is_equal(60.0)


func test_balance_loads() -> void:
	var balance: BalanceData = load("res://data/balance.tres")
	# Twody: battles start with no food.
	assert_float(balance.start_food).is_equal(0.0)
	# Lowered from SPEC (0.5) at Twody's request: the game felt too fast; then a bit faster again.
	assert_float(balance.food_rate).is_equal(0.24)
	# Twody: the player's base has 5 HP, every enemy hit takes 1.
	assert_float(balance.player_base_hp).is_equal(5.0)
	assert_float(balance.player_base_hit).is_equal(1.0)
	assert_float(balance.food_max).is_equal(30.0)
	assert_int(balance.unit_limit).is_equal(20)
	assert_float(balance.lane_end_x).is_greater(balance.lane_start_x)


func test_upgrade_costs() -> void:
	for id: String in UPGRADE_IDS:
		var up: UpgradeData = load("res://data/upgrades/%s.tres" % id)
		assert_object(up).is_not_null()
		assert_int(up.max_level).is_greater(0)
	var food: UpgradeData = load("res://data/upgrades/food_rate.tres")
	# 30 × 1.35^0 = 30; 30 × 1.35^3 = 73.8 → 75
	assert_int(food.cost_for_level(0, 1.35, 5)).is_equal(30)
	assert_int(food.cost_for_level(3, 1.35, 5)).is_equal(75)
	var speed: UpgradeData = load("res://data/upgrades/battle_speed.tres")
	assert_int(speed.cost_for_level(0, 1.35, 5)).is_equal(600)
