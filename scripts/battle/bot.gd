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
var _pick_counter: int = 0


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
	# Counter picks only between waves (SPEC 5); after the last wave — pressure only.
	if level.counter_pick and not is_spawning_wave() and not all_waves_done():
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
			if sim.spawn(BattleSim.BOT, entry.unit, 1, _power_for(entry.unit)) != null:
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
	if sim.spawn(BattleSim.BOT, pick, 1, level.bot_power) != null:
		food -= pick.cost
		_pick_counter += 1


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
	# Base mix: two melee per archer; lean to archers vs. a melee-only crowd,
	# to fast spiders vs. many archers.
	var wanted: StringName = &"skeleton" if _pick_counter % 3 == 0 else &"zombie"
	if ranged > melee:
		wanted = &"spider"
	elif melee > ranged * 3 and _pick_counter % 2 == 0:
		wanted = &"skeleton"
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
		# Pressure keeps the player from idling; it is not meant to stall the push.
		sim.spawn(BattleSim.BOT, level.bot_units[index])


## Bosses keep their own stats; bot_power scales regular units only.
func _power_for(unit: UnitData) -> float:
	return 1.0 if unit.is_boss else level.bot_power
