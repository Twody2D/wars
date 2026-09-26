extends GdUnitTestSuite
## Player economy in BattleSim (SPEC 4, T08).

var balance: BalanceData
var zombie: UnitData


func before() -> void:
	balance = load("res://data/balance.tres")
	zombie = load("res://data/units/zombie.tres")


func _sim() -> BattleSim:
	var level := LevelData.new()
	level.bot_base_hp = 10000.0
	var units: Array[UnitData] = [zombie]
	return BattleSim.new(BattleSetup.basic(balance, level, units))


func _run(sim: BattleSim, seconds: float) -> void:
	for i: int in roundi(seconds / balance.sim_dt):
		sim.step(balance.sim_dt)


func test_food_income_and_cap() -> void:
	var sim := _sim()
	assert_float(sim.food).is_equal(balance.start_food)
	_run(sim, 10.0)
	assert_float(sim.food).is_equal_approx(balance.start_food + balance.food_rate * 10.0, 0.05)
	_run(sim, 200.0)
	assert_float(sim.food).is_equal(balance.food_max)


func test_buy_spends_food_and_starts_card_cooldown() -> void:
	var sim := _sim()
	sim.food = zombie.cost + 1.0
	assert_object(sim.buy(zombie)).is_not_null()
	assert_float(sim.food).is_equal(1.0)
	assert_str(String(sim.buy_block_reason(zombie))).is_equal("cooldown")
	assert_object(sim.buy(zombie)).is_null()
	_run(sim, balance.card_cooldown + 0.05)
	assert_str(String(sim.buy_block_reason(zombie))).is_equal("food")


func test_limit_blocks_card() -> void:
	var sim := _sim()
	sim.food = 1000.0
	sim.food_max = 1000.0
	for i: int in balance.unit_limit:
		sim.spawn(BattleSim.PLAYER, zombie)
	assert_str(String(sim.buy_block_reason(zombie))).is_equal("limit")


func test_ore_gives_food_then_cools_down() -> void:
	var sim := _sim()
	var before_food: float = sim.food
	assert_bool(sim.tap_ore(0)).is_true()
	assert_float(sim.food).is_equal(before_food + balance.ore_food)
	assert_bool(sim.tap_ore(0)).is_false()
	_run(sim, balance.ore_cooldown + 0.05)
	assert_bool(sim.tap_ore(0)).is_true()
	assert_bool(sim.tap_ore(99)).is_false()


func test_meteor_charges_and_delayed_impact() -> void:
	var sim := _sim()
	var enemy: SimUnit = sim.spawn(BattleSim.BOT, zombie)
	var at := Vector2(enemy.x, balance.lane_y)
	assert_int(sim.meteor_charges).is_equal(1)
	assert_bool(sim.cast_meteor(at)).is_true()
	assert_int(sim.meteor_charges).is_equal(0)
	assert_bool(sim.cast_meteor(at)).is_false()
	# Nothing happens until the rock lands.
	assert_float(enemy.hp).is_equal(enemy.max_hp)
	_run(sim, balance.meteor_fall_time + 0.05)
	assert_float(enemy.hp).is_less(enemy.max_hp)
	_run(sim, balance.meteor_recharge)
	assert_int(sim.meteor_charges).is_equal(1)


func test_level_min_start_food() -> void:
	var level := LevelData.new()
	level.min_start_food = 3.0
	var units: Array[UnitData] = [zombie]
	var sim := BattleSim.new(BattleSetup.basic(balance, level, units))
	assert_float(sim.food).is_equal(maxf(balance.start_food, 3.0))
	var level1: LevelData = load("res://data/levels/level_01.tres")
	assert_float(level1.min_start_food).is_equal(3.0)
