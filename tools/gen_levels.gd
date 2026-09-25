extends SceneTree
## Generates data/levels/level_01..20.tres and data/game_config.tres (SPEC 5).
## Starting curve only — after generation the .tres files are tuned in the editor.
## Run: "$GODOT" --headless --path . -s res://tools/gen_levels.gd

const LEVELS := 20
const PER_BIOME := 10
## Total bot wave budget in food per level (split over the waves), index 0 = level 1.
const BUDGET: Array[float] = [
	48.0, 128.0, 137.0, 147.0, 157.0, 168.0, 180.0, 192.0, 206.0, 220.0,
	209.0, 224.0, 239.0, 256.0, 274.0, 293.0, 314.0, 336.0, 359.0, 384.0,
]
const INTERVALS: Dictionary[StringName, float] = {
	&"zombie": 2.0, &"skeleton": 3.0, &"spider": 2.0, &"slime": 4.0,
	&"goblin_miner": 3.5, &"barrel_bomber": 5.0,
}
## Bot income for counter picks (food/s), index 0 = level 1.
const BOT_FOOD: Array[float] = [
	0.5, 1.1, 1.13, 1.16, 1.19, 1.22, 1.25, 1.28, 1.31, 1.34,
	1.2, 1.23, 1.26, 1.29, 1.32, 1.35, 1.38, 1.41, 1.44, 1.47,
]
## HP/damage multiplier of bot units, index 0 = level 1 (tutorial = 1.0).
const BOT_POWER: Array[float] = [
	1.0, 1.8, 1.85, 1.9, 1.95, 2.0, 2.05, 2.1, 2.15, 2.0,
	1.75, 1.78, 1.81, 1.84, 1.87, 1.9, 1.93, 1.96, 1.99, 1.95,
]
## Boss levels get a smaller army: the boss is the threat.
const BOSS_LEVEL_BUDGET := 0.75
const FIRST_WAVE_SEC := 10.0
const WAVE_GAP_SEC := 20.0


func _init() -> void:
	var u: Dictionary[String, UnitData] = {}
	for id: String in ["zombie", "skeleton", "slime", "spider", "goblin_miner", "barrel_bomber", "boss_zombie_king", "boss_stone_golem"]:
		u[id] = load("res://data/units/%s.tres" % id)

	var levels: Array[LevelData] = []
	for n: int in range(1, LEVELS + 1):
		var level := _level(n, u)
		var path := "res://data/levels/level_%02d.tres" % n
		print("%s -> %s" % [path, error_string(ResourceSaver.save(level, path))])
		levels.append(load(path))

	var config := GameConfig.new()
	config.balance = load("res://data/balance.tres")
	config.levels_per_biome = PER_BIOME
	for id: String in ["zombie", "skeleton", "slime", "spider", "goblin_miner", "barrel_bomber"]:
		config.player_units.append(u[id])
	for id: String in ["food_rate", "base_hp", "start_food", "unit_level", "battle_speed"]:
		config.upgrades.append(load("res://data/upgrades/%s.tres" % id))
	config.levels = levels
	print("game_config -> ", error_string(ResourceSaver.save(config, "res://data/game_config.tres")))
	quit()


func _level(n: int, u: Dictionary[String, UnitData]) -> LevelData:
	var t: float = (n - 1) / float(LEVELS - 1)
	var cave: bool = n > PER_BIOME
	var level := LevelData.new()
	level.number = n
	level.biome = &"cave" if cave else &"meadow"
	level.bot_base_hp = roundf(lerpf(400.0, 1500.0, t) / 10.0) * 10.0
	level.bot_food_per_sec = BOT_FOOD[n - 1]
	level.bot_power = BOT_POWER[n - 1]
	level.counter_pick = n >= 2
	level.reward_coins = 20 + 5 * (n - 1)
	level.tutorial = n == 1
	level.ore_blocks = 2

	var pool: Array[UnitData] = [u["zombie"], u["skeleton"]]
	if n >= 4:
		pool.append(u["spider"])
	if n >= 6:
		pool.append(u["slime"])
	if cave:
		pool.append(u["goblin_miner"])
	if n >= 13:
		pool.append(u["barrel_bomber"])
	level.bot_units = pool

	# Waves: +1 every two levels (4 → 13, SPEC 5); each wave has a food budget
	# that ramps from 0.5× to 1.5× of the level budget, split by unit weights.
	var wave_count: int = clampi(4 + (n - 2) / 2, 4, 13)
	var weights: Dictionary[UnitData, float] = {u["zombie"]: 0.55, u["skeleton"]: 0.3}
	if n >= 4:
		weights[u["spider"]] = 0.15
	if n >= 6:
		weights[u["slime"]] = 0.15
	if cave:
		weights[u["goblin_miner"]] = 0.2
	if n >= 13:
		weights[u["barrel_bomber"]] = 0.1
	var total_w := 0.0
	for unit: UnitData in weights:
		total_w += weights[unit]
	for i: int in wave_count:
		var wave := WaveData.new()
		wave.start_sec = FIRST_WAVE_SEC + i * WAVE_GAP_SEC + (5.0 if n == 1 else 0.0)
		var ramp: float = lerpf(0.5, 1.5, i / float(maxi(wave_count - 1, 1)))
		var budget: float = BUDGET[n - 1] / wave_count * ramp
		if n % PER_BIOME == 0:
			budget *= BOSS_LEVEL_BUDGET
		for unit: UnitData in weights:
			var share: float = budget * weights[unit] / total_w
			# The first wave of a level is melee-only: time to set up.
			if i == 0 and unit != u["zombie"]:
				continue
			var interval: float = INTERVALS.get(unit.id, 3.0)
			_add(wave, unit, share / unit.cost, interval)
		var boss_level: bool = n % PER_BIOME == 0
		if boss_level and i == wave_count - 1:
			_add(wave, u["boss_stone_golem"] if cave else u["boss_zombie_king"], 1.0, 1.0)
		level.waves.append(wave)
	return level


func _add(wave: WaveData, unit: UnitData, count: float, interval: float) -> void:
	var c: int = roundi(count)
	if c <= 0:
		return
	var entry := WaveEntry.new()
	entry.unit = unit
	entry.count = c
	entry.interval_sec = interval
	wave.entries.append(entry)
