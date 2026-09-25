class_name BattleBot
extends RefCounted
## Scripted bot (SPEC 5): waves from LevelData, counter picks on its own food
## between waves, and one random unit every few seconds after the last wave.
## Pure logic — drives BattleSim, no nodes.

var sim: BattleSim
var level: LevelData
var food: float = 0.0
var waves_started: int = 0

var _time: float = 0.0
## Active spawners: [entry, remaining, timer]
var _spawners: Array[Array] = []
var _pressure_timer: float = 0.0


func _init(sim_: BattleSim) -> void:
	sim = sim_
	level = sim_.setup.level


func wave_count() -> int:
	return level.waves.size()


## Current wave for the HUD, 1-based; 0 before the first wave.
func current_wave() -> int:
	return waves_started


func is_spawning_wave() -> bool:
	return not _spawners.is_empty()


func all_waves_done() -> bool:
	return waves_started >= wave_count() and _spawners.is_empty()


func step(dt: float) -> void:
	if sim.is_over():
		return
	_time += dt
	while waves_started < wave_count() and level.waves[waves_started].start_sec <= _time:
		for entry: WaveEntry in level.waves[waves_started].entries:
			_spawners.append([entry, entry.count, 0.0])
		waves_started += 1
	_step_spawners(dt)
	if level.counter_pick and not is_spawning_wave():
		food += level.bot_food_per_sec * dt
		_counter_pick()
	if all_waves_done():
		_pressure(dt)


func _step_spawners(dt: float) -> void:
	var done: Array[Array] = []
	for spawner: Array in _spawners:
		var entry: WaveEntry = spawner[0]
		var timer: float = spawner[2]
		timer -= dt
		if timer <= 0.0:
			if sim.spawn(BattleSim.BOT, entry.unit) != null:
				var remaining: int = spawner[1]
				spawner[1] = remaining - 1
				timer = entry.interval_sec
			else:
				timer = 0.0 # limit reached — retry next step
		spawner[2] = timer
		var left: int = spawner[1]
		if left <= 0:
			done.append(spawner)
	for spawner: Array in done:
		_spawners.erase(spawner)


## Answer the player's army: many melee → archers, many ranged → fast spiders.
func _counter_pick() -> void:
	var pick: UnitData = _choose_counter()
	if pick == null or food < pick.cost:
		return
	if sim.spawn(BattleSim.BOT, pick) != null:
		food -= pick.cost


func _choose_counter() -> UnitData:
	if level.bot_units.is_empty():
		return null
	var melee := 0
	var ranged := 0
	for unit: SimUnit in sim.units:
		if unit.side == BattleSim.PLAYER and unit.is_alive():
			if unit.data.is_ranged():
				ranged += 1
			else:
				melee += 1
	var wanted: StringName = &"zombie"
	if melee > ranged:
		wanted = &"skeleton"
	elif ranged > melee:
		wanted = &"spider"
	for unit_data: UnitData in level.bot_units:
		if unit_data.id == wanted:
			return unit_data
	return level.bot_units[0]


func _pressure(dt: float) -> void:
	if level.bot_units.is_empty():
		return
	_pressure_timer += dt
	if _pressure_timer >= sim.balance.bot_pressure_interval:
		_pressure_timer = 0.0
		var index: int = sim.rng.randi_range(0, level.bot_units.size() - 1)
		sim.spawn(BattleSim.BOT, level.bot_units[index])
