extends SceneTree
## Campaign probe: AutoPlayer plays levels in order from a fresh save, spends
## coins on the cheapest upgrade after every battle, retries on loss.
## Prints attempts per level — the target curve is "tutorial wins first try,
## then lose a couple of times, upgrade, win".
## Run: "$GODOT" --headless --path . -s res://tools/probe_campaign.gd -- <to_level> [seed]

const MAX_ATTEMPTS := 12


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var to: int = args[0].to_int()
	var seed_: int = args[1].to_int() if args.size() > 1 else 1
	var config: GameConfig = load("res://data/game_config.tres")
	var b: BalanceData = config.balance
	var coins := 0
	var ups: Dictionary[StringName, int] = {&"army_power": 0, &"food_rate": 0, &"base_hp": 0, &"start_food": 0}
	var unit_lvls: Dictionary[StringName, int] = {&"zombie": 1, &"skeleton": 1}
	var attempt_seed := seed_ * 1000
	for n: int in range(1, to + 1):
		var level: LevelData = config.levels[n - 1]
		var attempts := 0
		var won := false
		var log_line := ""
		while not won and attempts < MAX_ATTEMPTS:
			attempts += 1
			attempt_seed += 1
			var owned: Array[UnitData] = []
			for u: UnitData in config.player_units:
				if unit_lvls.has(u.id):
					owned.append(u)
			var s := BattleSetup.basic(b, level, owned, attempt_seed)
			s.food_rate += config.upgrade(&"food_rate").per_level * ups[&"food_rate"]
			s.food_max += floorf(ups[&"food_rate"] / 2.0) * b.food_max_per_2_levels
			s.player_base_hp += config.upgrade(&"base_hp").per_level * ups[&"base_hp"]
			s.start_food += config.upgrade(&"start_food").per_level * ups[&"start_food"]
			s.unit_levels = unit_lvls.duplicate()
			s.player_power = 1.0 + config.upgrade(&"army_power").per_level * ups[&"army_power"]
			var sim := BattleSim.new(s)
			var bot := BattleBot.new(sim)
			won = AutoPlayer.new(sim, bot).play()
			var result := Rewards.calculate(sim)
			coins += result.coins
			log_line += "%s(%.0fs,+%d,bot%d%%) " % ["W" if won else "L", sim.time, result.coins,
				roundi(sim.base_hp[1] / sim.base_max_hp[1] * 100.0)]
			coins = _spend(config, b, coins, ups, unit_lvls)
		print("L%02d attempts=%d %s| coins=%d ups=%s units=%s" % [n, attempts, log_line, coins, ups, unit_lvls])
		if not won:
			break
	quit()


## Greedy: buy the cheapest thing available until nothing is affordable.
func _spend(config: GameConfig, b: BalanceData, coins: int, ups: Dictionary[StringName, int], unit_lvls: Dictionary[StringName, int]) -> int:
	while true:
		var best_cost := 1 << 30
		var best := ""
		for id: StringName in ups:
			var up: UpgradeData = config.upgrade(id)
			if ups[id] < up.max_level:
				var c: int = up.cost_for_level(ups[id], b.upgrade_cost_growth, b.upgrade_cost_round)
				if c < best_cost:
					best_cost = c
					best = "up:" + String(id)
		for u: UnitData in config.player_units:
			if not unit_lvls.has(u.id) and u.unlock_biome == 1 and u.unlock_cost < best_cost:
				best_cost = u.unlock_cost
				best = "unlock:" + String(u.id)
		if best == "" or best_cost > coins:
			return coins
		coins -= best_cost
		var parts: PackedStringArray = best.split(":")
		if parts[0] == "up":
			ups[StringName(parts[1])] += 1
		else:
			unit_lvls[StringName(parts[1])] = 1
	return coins
