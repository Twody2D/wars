extends GdUnitTestSuite
## Levels and bot (SPEC 5, T09). Difficulty design (Twody): the tutorial is won
## without upgrades; from level 2 the bot beats an un-upgraded player, so
## upgrades bought in the menu are needed.

var config: GameConfig


func before() -> void:
	config = load("res://data/game_config.tres")


func _play(n: int, seed_: int) -> bool:
	var units: Array[UnitData] = [config.player_units[0], config.player_units[1]]
	var s := BattleSetup.basic(config.balance, config.levels[n - 1], units, seed_)
	var sim := BattleSim.new(s)
	return AutoPlayer.new(sim, BattleBot.new(sim)).play()


func test_all_levels_load() -> void:
	assert_int(config.levels.size()).is_equal(20)
	for i: int in config.levels.size():
		var level: LevelData = config.levels[i]
		assert_int(level.number).is_equal(i + 1)
		assert_int(level.waves.size()).is_between(4, 13)
		assert_float(level.bot_base_hp).is_between(400.0, 1500.0)
		for wave: WaveData in level.waves:
			assert_bool(wave.entries.is_empty()).is_false()
		var has_boss := false
		for e: WaveEntry in level.waves[-1].entries:
			has_boss = has_boss or e.unit.is_boss
		assert_bool(has_boss).is_equal((i + 1) % config.levels_per_biome == 0)


func test_tutorial_is_won_without_upgrades() -> void:
	for seed_: int in [1, 2, 3]:
		assert_bool(_play(1, seed_)).override_failure_message("level 1, seed %d" % seed_).is_true()


func test_level_2_needs_upgrades() -> void:
	var wins := 0
	for seed_: int in range(500, 510):
		if _play(2, seed_):
			wins += 1
	# Not reliably won without upgrades (AutoPlayer is a fairly good player).
	assert_int(wins).is_less_equal(6)


func test_level_20_is_not_won_without_upgrades() -> void:
	assert_bool(_play(20, 1)).is_false()
