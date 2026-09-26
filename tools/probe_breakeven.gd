extends SceneTree
## Break-even probe: for each level finds the bot_power at which AutoPlayer with
## a typical upgrade state for that level wins about half of the battles.
## The state table is what a player who wins every level first try owns when
## entering the level (from probe_campaign). Set BOT_POWER in gen_levels.gd
## relative to these numbers: below — easy level, above — "lose, upgrade, win".
## Run: "$GODOT" --headless --path . -s res://tools/probe_breakeven.gd -- <from> <to> [seeds]

## Level → [army_power, food_rate, base_hp, start_food, zombie_lvl, skeleton_lvl]
## (from a probe_campaign run; start_food is no longer sold).
const STATE: Dictionary[int, Array] = {
	1: [0, 0, 0, 0, 1, 1], 2: [1, 0, 1, 0, 1, 1], 3: [2, 1, 2, 0, 1, 1], 4: [3, 1, 3, 0, 1, 1], 5: [4, 2, 4, 0, 1, 1], 6: [4, 2, 4, 0, 2, 2], 7: [4, 3, 4, 0, 2, 2], 8: [5, 3, 4, 0, 2, 2], 9: [5, 3, 5, 0, 3, 2], 10: [6, 4, 5, 0, 3, 3], 11: [6, 4, 6, 0, 3, 3], 12: [6, 4, 6, 0, 4, 3], 13: [6, 4, 6, 0, 4, 4], 14: [6, 5, 6, 0, 4, 4], 15: [7, 5, 6, 0, 4, 4], 16: [7, 5, 7, 0, 4, 4], 17: [7, 5, 7, 0, 5, 5], 18: [7, 6, 7, 0, 5, 5], 19: [7, 6, 7, 0, 5, 5], 20: [7, 6, 7, 0, 5, 5],
}
const STEPS := 7


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var from: int = args[0].to_int()
	var to: int = args[1].to_int()
	var seeds: int = args[2].to_int() if args.size() > 2 else 6
	var config: GameConfig = load("res://data/game_config.tres")
	for n: int in range(from, to + 1):
		var level: LevelData = config.levels[n - 1]
		var original: float = level.bot_power
		var lo := 0.6
		var hi := 4.0
		for i: int in STEPS:
			var mid: float = (lo + hi) / 2.0
			level.bot_power = mid
			if _wins(config, level, n, seeds) * 2 >= seeds:
				lo = mid
			else:
				hi = mid
		level.bot_power = original
		print("L%02d break_even=%.2f current=%.2f ratio=%.2f" % [n, lo, original, original / lo])
	quit()


func _wins(config: GameConfig, level: LevelData, n: int, seeds: int) -> int:
	var st: Array = STATE[n]
	var b: BalanceData = config.balance
	var zombie_lvl: int = st[4]
	var skeleton_lvl: int = st[5]
	var food_lvl: int = st[1]
	var hp_lvl: int = st[2]
	var start_lvl: int = st[3]
	var army_lvl: int = st[0]
	var wins := 0
	for k: int in seeds:
		var units: Array[UnitData] = [config.player_units[0], config.player_units[1]]
		var s := BattleSetup.basic(b, level, units, 7000 + n * 100 + k)
		s.food_rate += config.upgrade(&"food_rate").per_level * food_lvl
		s.food_max += floorf(food_lvl / 2.0) * b.food_max_per_2_levels
		s.player_base_hp += config.upgrade(&"base_hp").per_level * hp_lvl
		s.start_food += config.upgrade(&"start_food").per_level * start_lvl
		s.player_power = 1.0 + config.upgrade(&"army_power").per_level * army_lvl
		var lvls: Dictionary[StringName, int] = {&"zombie": zombie_lvl, &"skeleton": skeleton_lvl}
		s.unit_levels = lvls
		var sim := BattleSim.new(s)
		if AutoPlayer.new(sim, BattleBot.new(sim)).play():
			wins += 1
	return wins
