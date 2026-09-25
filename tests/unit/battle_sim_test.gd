extends GdUnitTestSuite

var balance: BalanceData
var zombie: UnitData
var skeleton: UnitData
var bomber: UnitData
var spider: UnitData
var slime: UnitData


func before() -> void:
	balance = load("res://data/balance.tres")
	zombie = load("res://data/units/zombie.tres")
	skeleton = load("res://data/units/skeleton.tres")
	bomber = load("res://data/units/barrel_bomber.tres")
	spider = load("res://data/units/spider.tres")
	slime = load("res://data/units/slime.tres")


func _sim(bot_base_hp: float = 10000.0, seed_: int = 1) -> BattleSim:
	var level := LevelData.new()
	level.bot_base_hp = bot_base_hp
	var units: Array[UnitData] = [zombie, skeleton]
	var setup := BattleSetup.basic(balance, level, units, seed_)
	setup.player_base_hp = 10000.0
	return BattleSim.new(setup)


func _run(sim: BattleSim, seconds: float) -> void:
	var steps: int = roundi(seconds / balance.sim_dt)
	for i: int in steps:
		sim.step(balance.sim_dt)


func test_melee_hits_melee() -> void:
	var sim := _sim()
	var a: SimUnit = sim.spawn(BattleSim.PLAYER, zombie)
	var b: SimUnit = sim.spawn(BattleSim.BOT, zombie)
	_run(sim, 30.0)
	# Same stats, both attack; exactly one of them must be dead by now.
	assert_bool(a.is_alive() and b.is_alive()).is_false()
	assert_bool(a.hp < a.max_hp or b.hp < b.max_hp).is_true()
	assert_int(sim.kills[BattleSim.PLAYER] + sim.kills[BattleSim.BOT]).is_greater_equal(1)


func test_archer_shoots_from_range() -> void:
	var sim := _sim()
	var archer: SimUnit = sim.spawn(BattleSim.PLAYER, skeleton)
	var target: SimUnit = sim.spawn(BattleSim.BOT, zombie)
	var shots: Array[float] = []
	sim.unit_attack_started.connect(func(u: SimUnit) -> void:
		if u == archer:
			shots.append(target.x - archer.x))
	_run(sim, 15.0)
	assert_int(shots.size()).is_greater(0)
	assert_float(shots[0]).is_between(160.0, 180.0)


func test_waits_behind_own_unit() -> void:
	var sim := _sim()
	var first: SimUnit = sim.spawn(BattleSim.PLAYER, zombie)
	var second: SimUnit = sim.spawn(BattleSim.PLAYER, zombie)
	sim.step(balance.sim_dt)
	assert_int(second.state).is_equal(SimUnit.State.WAIT)
	_run(sim, 2.0)
	assert_float(first.x - second.x).is_between(balance.wait_distance - 1.0, balance.wait_distance + 2.0)


func test_bomber_explodes_and_dies() -> void:
	var sim := _sim()
	var died: Array[bool] = []
	var explosions: Array[float] = []
	var boom: SimUnit = sim.spawn(BattleSim.PLAYER, bomber)
	sim.unit_died.connect(func(u: SimUnit, killed: bool) -> void:
		if u == boom:
			died.append(killed))
	sim.explosion.connect(func(x: float, _r: float, _s: int) -> void: explosions.append(x))
	var victim: SimUnit = sim.spawn(BattleSim.BOT, zombie)
	_run(sim, 20.0)
	assert_bool(boom.is_alive()).is_false()
	assert_array(died).is_equal([false])
	assert_int(explosions.size()).is_equal(1)
	assert_bool(victim.is_alive()).is_false()


func test_unit_damages_base() -> void:
	var sim := _sim(1000.0)
	sim.spawn(BattleSim.PLAYER, zombie)
	var hits: Array[float] = []
	sim.base_damaged.connect(func(side: int, amount: float) -> void:
		if side == BattleSim.BOT:
			hits.append(amount))
	_run(sim, 40.0)
	assert_int(hits.size()).is_greater(0)
	assert_float(hits[0]).is_equal(zombie.damage)
	assert_float(sim.base_hp[BattleSim.BOT]).is_less(1000.0)


func test_unit_limit() -> void:
	var sim := _sim()
	for i: int in 25:
		sim.spawn(BattleSim.PLAYER, zombie)
	assert_int(sim.alive_count(BattleSim.PLAYER)).is_equal(balance.unit_limit)


func test_unit_level_scales_stats() -> void:
	var sim := _sim()
	var unit: SimUnit = sim.spawn(BattleSim.PLAYER, zombie, 3)
	assert_float(unit.max_hp).is_equal_approx(zombie.hp * 1.2, 0.001)
	assert_float(unit.damage).is_equal_approx(zombie.damage * 1.2, 0.001)


func test_same_seed_same_result() -> void:
	var results: Array[String] = []
	for run: int in 2:
		var sim := _sim(300.0, 42)
		for i: int in 5:
			sim.spawn(BattleSim.PLAYER, zombie)
			sim.spawn(BattleSim.BOT, skeleton)
		_run(sim, 20.0)
		var snapshot := ""
		for unit: SimUnit in sim.units:
			snapshot += "%d:%.3f:%.3f;" % [unit.uid, unit.x, unit.hp]
		results.append(snapshot)
	assert_str(results[0]).is_equal(results[1])


## Random armies with a stronger and a weaker side (alternating): every battle
## must finish — no deadlocks, no stuck units, no dead units left on the field.
func test_bot_vs_bot_battles_always_end() -> void:
	var roster: Array[UnitData] = [zombie, skeleton, spider, slime, bomber]
	var dt := 0.1
	for battle: int in 500:
		var sim := _sim(100.0, battle + 1)
		sim.base_hp = [100.0, 100.0]
		var strong: int = battle % 2
		var pick := RandomNumberGenerator.new()
		pick.seed = battle
		var t := 0.0
		while not sim.is_over() and t < 900.0:
			for side: int in 2:
				var rate: float = 0.5 if side == strong else 0.12
				if pick.randf() < dt * rate:
					sim.spawn(side, roster[pick.randi_range(0, roster.size() - 1)])
			sim.step(dt)
			t += dt
		assert_bool(sim.is_over()).override_failure_message("battle %d did not end" % battle).is_true()
		for unit: SimUnit in sim.units:
			assert_bool(unit.is_alive()).is_true()
