extends SceneTree
## Traces one AutoPlayer battle: every N sim-seconds prints armies, front, bases.
## Run: "$GODOT" --headless --path . -s res://tools/probe_trace.gd -- <level> <seed> [every] [food_lvl] [hp_lvl] [bot_power]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var config: GameConfig = load("res://data/game_config.tres")
	var level: LevelData = config.levels[args[0].to_int() - 1]
	if args.size() > 5:
		level = level.duplicate()
		level.bot_power = args[5].to_float()
	var every: float = args[2].to_float() if args.size() > 2 else 20.0
	var units: Array[UnitData] = [config.player_units[0], config.player_units[1]]
	var s := BattleSetup.basic(config.balance, level, units, args[1].to_int())
	if args.size() > 4:
		s.food_rate += config.upgrade(&"food_rate").per_level * args[3].to_int()
		s.player_base_hp += config.upgrade(&"base_hp").per_level * args[4].to_int()
	var sim := BattleSim.new(s)
	var bot := BattleBot.new(sim)
	var ap := AutoPlayer.new(sim, bot)
	var dt: float = config.balance.sim_dt * 2.0
	var next := 0.0
	while not sim.is_over() and sim.time < 900.0:
		ap._think -= dt
		if ap._think <= 0.0:
			ap._think = ap.reaction
			ap._act()
		bot.step(dt)
		sim.step(dt)
		if sim.time >= next:
			next += every
			var pf := 0.0
			var bf := 2000.0
			for u: SimUnit in sim.units:
				if u.side == 0:
					pf = maxf(pf, u.x)
				else:
					bf = minf(bf, u.x)
			print("t=%3.0f wave %d/%d P=%2d B=%2d front P%.0f B%.0f food %.0f botfood %.0f bases %.0f/%.0f kills %d/%d" % [
				sim.time, bot.current_wave(), bot.wave_count(), sim.alive_count(0), sim.alive_count(1),
				pf, bf, sim.food, bot.food, sim.base_hp[0], sim.base_hp[1], sim.kills[0], sim.kills[1]])
	print("winner ", sim.winner, " t=", sim.time)
	quit()
