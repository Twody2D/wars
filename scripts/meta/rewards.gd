class_name Rewards
extends RefCounted
## Coins and stars after a battle (SPEC 6).


## Win: reward_coins + coins_per_kill × kills. Loss: lose_reward_ratio of that.
static func coins_for(balance: BalanceData, level: LevelData, kills: int, won: bool) -> int:
	var total: int = level.reward_coins + balance.coins_per_kill * kills
	if won:
		return total
	return floori(total * balance.lose_reward_ratio)


## Stars by the player's base HP left: ≥ 70% → 3, ≥ 35% → 2, else 1; loss → 0.
static func stars_for(balance: BalanceData, hp_ratio: float, won: bool) -> int:
	if not won:
		return 0
	if hp_ratio >= balance.three_stars_hp:
		return 3
	if hp_ratio >= balance.two_stars_hp:
		return 2
	return 1


static func calculate(sim: BattleSim) -> BattleResult:
	var r := BattleResult.new()
	r.level_number = sim.setup.level.number
	r.won = sim.winner == BattleSim.PLAYER
	r.kills = sim.kills[BattleSim.PLAYER]
	r.hp_ratio = sim.base_hp[BattleSim.PLAYER] / sim.base_max_hp[BattleSim.PLAYER]
	r.stars = stars_for(sim.balance, r.hp_ratio, r.won)
	r.coins = coins_for(sim.balance, sim.setup.level, r.kills, r.won)
	return r
