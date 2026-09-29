class_name Rewards
extends RefCounted
## Coins and stars after a battle (SPEC 6).


## Win: (reward_coins + coins_per_kill × kills) × (1 + star_coin_bonus × stars).
## Loss: lose_reward_ratio of the base amount. Both × `mult` (golden pickaxe ×2).
static func coins_for(balance: BalanceData, level: LevelData, kills: int, won: bool, stars: int = 0,
		mult: float = 1.0) -> int:
	var total: int = level.reward_coins + balance.coins_per_kill * kills
	if won:
		return roundi(total * (1.0 + balance.star_coin_bonus * stars) * mult)
	return floori(total * balance.lose_reward_ratio * mult)


## Base HP share needed for the next star (0 if already 3 stars).
static func next_star_hp(balance: BalanceData, stars: int) -> float:
	if stars <= 1:
		return balance.two_stars_hp
	if stars == 2:
		return balance.three_stars_hp
	return 0.0


## Stars by the player's base HP left: ≥ 70% → 3, ≥ 35% → 2, else 1; loss → 0.
static func stars_for(balance: BalanceData, hp_ratio: float, won: bool) -> int:
	if not won:
		return 0
	if hp_ratio >= balance.three_stars_hp:
		return 3
	if hp_ratio >= balance.two_stars_hp:
		return 2
	return 1


static func calculate(sim: BattleSim, mult: float = 1.0) -> BattleResult:
	var r := BattleResult.new()
	r.level_number = sim.setup.level.number
	r.won = sim.winner == BattleSim.PLAYER
	r.kills = sim.kills[BattleSim.PLAYER]
	r.hp_ratio = sim.base_hp[BattleSim.PLAYER] / sim.base_max_hp[BattleSim.PLAYER]
	r.stars = stars_for(sim.balance, r.hp_ratio, r.won)
	r.coins = coins_for(sim.balance, sim.setup.level, r.kills, r.won, r.stars, mult)
	return r
