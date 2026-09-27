class_name BattleBot
extends RefCounted
## Scripted bot (SPEC 5): waves from LevelData; the base is shielded until
## the last wave's leader or boss dies; on its own food it sends
## defenders (counter picks) only while the player's army is on its half of
## the field, so waves stay clear packs; one random unit every few seconds
## after the last wave.
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
## Leader or boss of the last wave once it is on the field.
var _leader: SimUnit = null


func _init(sim_: BattleSim) -> void:
	sim = sim_
	level = sim_.setup.level
	_update_shield()


## The last wave has a leader or a boss: the bot base keeps a shield until it dies.
func has_shield() -> bool:
	return wave_count() > 0 and wave_leader(wave_count() - 1) != null


func is_shielded() -> bool:
	return sim.base_floor[BattleSim.BOT] > 0.0


func _update_shield() -> void:
	var on: bool = has_shield() and not is_broken()
	sim.base_floor[BattleSim.BOT] = sim.base_max_hp[BattleSim.BOT] * sim.balance.bot_shield_floor if on else 0.0


func wave_count() -> int:
	return level.waves.size()


## The wave that will start next is the last one.
func is_final_wave(index: int) -> bool:
	return index == wave_count() - 1


## The strongest unit of wave `index` (0-based): a boss, a leader or null.
func wave_leader(index: int) -> WaveEntry:
	var found: WaveEntry = null
	for entry: WaveEntry in level.waves[index].entries:
		if entry.unit.is_boss:
			return entry
		if entry.elite:
			found = entry
	return found


## The last wave is beaten — its leader or boss is dead (no leader: every bot
## unit is dead). The bot base stops sending units; only the base is left.
func is_broken() -> bool:
	if not all_waves_done():
		return false
	if _leader != null:
		return not _leader.is_alive()
	for unit: SimUnit in sim.units:
		if unit.side == BattleSim.BOT and unit.is_alive():
			return false
	return true


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
		var entries: Array[WaveEntry] = level.waves[waves_started].entries
		for i: int in entries.size():
			# Entries run in parallel; a small offset keeps them from stacking.
			_spawners.append([entries[i], entries[i].count, i * sim.balance.wave_stagger])
		waves_started += 1
	_step_spawners(dt)
	# Defenders only between waves and only under threat; after the last wave — pressure only.
	if level.counter_pick and not all_waves_done():
		food += level.bot_food_per_sec * dt
		if not is_spawning_wave() and _threatened():
			_counter_pick()
	if all_waves_done() and not is_broken():
		_pressure(dt)
	_update_shield()


func _step_spawners(dt: float) -> void:
	var done: Array[Array] = []
	for spawner: Array in _spawners:
		var entry: WaveEntry = spawner[0]
		var timer: float = spawner[2]
		timer -= dt
		if timer <= 0.0:
			var spawned: SimUnit = sim.spawn(BattleSim.BOT, entry.unit, 1, _power_for(entry.unit), entry.elite)
			if spawned != null:
				if entry.elite or entry.unit.is_boss:
					_leader = spawned
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


## A player unit has crossed BalanceData.bot_defend_line (share of the lane
## from the player's side).
func _threatened() -> bool:
	var b: BalanceData = sim.balance
	var line: float = lerpf(b.lane_start_x, b.lane_end_x, b.bot_defend_line)
	for unit: SimUnit in sim.units:
		if unit.side == BattleSim.PLAYER and unit.is_alive() and unit.x >= line:
			return true
	return false


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


## bot_power scales every bot unit; bosses get BalanceData.boss_power on top
## (Twody: bosses were too easy when they kept their base stats).
func _power_for(unit: UnitData) -> float:
	return level.bot_power * (sim.balance.boss_power if unit.is_boss else 1.0)
