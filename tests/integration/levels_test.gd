extends GdUnitTestSuite
## Levels and bot (SPEC 5, T09). Difficulty design (Twody): without upgrades
## even level 1 is (almost) never won; one level of "army power", bought after
## a couple of losses, makes it winnable.

var config: GameConfig


func before() -> void:
	config = load("res://data/game_config.tres")


func _play(n: int, seed_: int, army_power: int = 0) -> bool:
	var units: Array[UnitData] = [config.player_units[0], config.player_units[1]]
	var s := BattleSetup.basic(config.balance, config.levels[n - 1], units, seed_)
	s.player_power = 1.0 + config.upgrade(&"army_power").per_level * army_power
	var sim := BattleSim.new(s)
	return AutoPlayer.new(sim, BattleBot.new(sim)).play()


func _wins(n: int, army_power: int) -> int:
	var wins := 0
	for seed_: int in range(500, 506):
		if _play(n, seed_, army_power):
			wins += 1
	return wins


func test_all_levels_load() -> void:
	assert_int(config.levels.size()).is_equal(20)
	for i: int in config.levels.size():
		var level: LevelData = config.levels[i]
		assert_int(level.number).is_equal(i + 1)
		assert_int(level.waves.size()).is_between(3, 12)
		assert_float(level.bot_base_hp).is_between(250.0, 900.0)
		for wave: WaveData in level.waves:
			assert_bool(wave.entries.is_empty()).is_false()
		var has_boss := false
		for e: WaveEntry in level.waves[-1].entries:
			has_boss = has_boss or e.unit.is_boss
		assert_bool(has_boss).is_equal((i + 1) % config.levels_per_biome == 0)


## Without upgrades level 1 is mostly lost (at most 2 wins of 6; the margin
## to "won with one army power" is thin, see TODO.md).
func test_level_1_is_lost_without_upgrades() -> void:
	assert_int(_wins(1, 0)).is_less_equal(2)


func test_level_1_is_won_with_army_power() -> void:
	assert_int(_wins(1, 1)).is_greater_equal(4)


func test_level_20_is_not_won_without_upgrades() -> void:
	assert_bool(_play(20, 1)).is_false()


## Twody: after the final leader falls the bot base must stop sending units
## (it used to spawn for five more minutes).
func test_bot_stops_after_final_leader_dies() -> void:
	var level: LevelData = config.levels[4]
	var s := BattleSetup.basic(config.balance, level, [config.player_units[0]] as Array[UnitData], 1)
	var sim := BattleSim.new(s)
	var bot := BattleBot.new(sim)
	var guard := 0
	while not bot.all_waves_done() and guard < 100000:
		bot.step(sim.balance.sim_dt)
		guard += 1
	assert_bool(bot.is_broken()).is_false()
	for u: SimUnit in sim.units:
		if u.side == BattleSim.BOT:
			u.hp = 0.0
			u.state = SimUnit.State.DEAD
	assert_bool(bot.is_broken()).is_true()
	var before: int = sim.units.size()
	for i: int in 3000:
		bot.step(sim.balance.sim_dt)
	assert_int(sim.units.size()).is_equal(before)
