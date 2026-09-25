class_name AutoPlayer
extends RefCounted
## A "decent human" for balance tests: mines ore, spends food as it comes on a
## fixed mix of units, drops the meteor on clumps. Reaction delays included.

var sim: BattleSim
var bot: BattleBot
var mix: Array[UnitData] = []
## Seconds between decisions — humans don't act every frame.
var reaction: float = 0.4
## Taps on ore per ready block (humans forget sometimes).
var ore_diligence: float = 0.8

var _next: int = 0
var _think: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init(sim_: BattleSim, bot_: BattleBot) -> void:
	sim = sim_
	bot = bot_
	_rng.seed = sim_.setup.rng_seed
	# Two melee for every ranged, plus whatever else is owned.
	var melee: Array[UnitData] = []
	var ranged: Array[UnitData] = []
	for u: UnitData in sim.setup.player_units:
		if u.is_ranged():
			ranged.append(u)
		else:
			melee.append(u)
	for i: int in maxi(melee.size(), ranged.size()):
		if i < melee.size():
			mix.append(melee[i])
			mix.append(melee[i])
		if i < ranged.size():
			mix.append(ranged[i])


## Plays the whole battle; returns true if the player won.
func play(max_seconds: float = 900.0) -> bool:
	var dt: float = sim.balance.sim_dt * 2.0
	var t := 0.0
	while not sim.is_over() and t < max_seconds:
		_think -= dt
		if _think <= 0.0:
			_think = reaction
			_act()
		bot.step(dt)
		sim.step(dt)
		t += dt
	return sim.winner == BattleSim.PLAYER


func _act() -> void:
	for i: int in sim.ore_cooldowns.size():
		if sim.ore_cooldowns[i] <= 0.0 and _rng.randf() < ore_diligence:
			sim.tap_ore(i)
	if not mix.is_empty():
		var want: UnitData = mix[_next % mix.size()]
		if sim.buy(want) != null:
			_next += 1
	if sim.meteor_charges > 0:
		var front: SimUnit = null
		for u: SimUnit in sim.units:
			if u.side == BattleSim.BOT and (front == null or u.x < front.x):
				front = u
		if front != null:
			var near := 0
			for u: SimUnit in sim.units:
				if u.side == BattleSim.BOT and absf(u.x - front.x) <= sim.balance.meteor_radius:
					near += 1
			if near >= 3 or front.x < sim.balance.lane_start_x + 200.0:
				sim.cast_meteor(Vector2(front.x + 40.0, sim.balance.lane_y))
