extends GdUnitTestSuite
## Coins and stars (SPEC 6, T10).

var balance: BalanceData


func before() -> void:
	balance = load("res://data/balance.tres")


func test_coins_win_and_loss() -> void:
	var level := LevelData.new()
	level.reward_coins = 400
	assert_int(Rewards.coins_for(balance, level, 10, true)).is_equal(500)
	assert_int(Rewards.coins_for(balance, level, 10, false)).is_equal(150)
	assert_int(Rewards.coins_for(balance, level, 0, false)).is_equal(120)


func test_star_bonus_on_win_only() -> void:
	var level := LevelData.new()
	level.reward_coins = 400
	assert_int(Rewards.coins_for(balance, level, 10, true, 1)).is_equal(550)
	assert_int(Rewards.coins_for(balance, level, 10, true, 3)).is_equal(650)
	assert_int(Rewards.coins_for(balance, level, 10, false, 3)).is_equal(150)
	assert_float(Rewards.next_star_hp(balance, 1)).is_equal(balance.two_stars_hp)
	assert_float(Rewards.next_star_hp(balance, 2)).is_equal(balance.three_stars_hp)
	assert_float(Rewards.next_star_hp(balance, 3)).is_equal(0.0)


func test_stars_by_base_hp() -> void:
	assert_int(Rewards.stars_for(balance, 1.0, true)).is_equal(3)
	assert_int(Rewards.stars_for(balance, 0.7, true)).is_equal(3)
	assert_int(Rewards.stars_for(balance, 0.69, true)).is_equal(2)
	assert_int(Rewards.stars_for(balance, 0.35, true)).is_equal(2)
	assert_int(Rewards.stars_for(balance, 0.1, true)).is_equal(1)
	assert_int(Rewards.stars_for(balance, 1.0, false)).is_equal(0)
