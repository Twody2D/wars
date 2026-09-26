extends SceneTree
## Generates data/levels/level_01..20.tres and data/game_config.tres (SPEC 5).
## Starting curve only — after generation the .tres files are tuned in the editor.
## Run: "$GODOT" --headless --path . -s res://tools/gen_levels.gd

const LEVELS := 20
const PER_BIOME := 10
## Total bot wave budget in food per level (split over the waves), index 0 = level 1.
const BUDGET: Array[float] = [
	33.4, 35.2, 37.68, 40.43, 43.18, 46.2, 49.5, 52.8, 56.65, 60.5,
	57.48, 61.6, 65.73, 70.4, 75.35, 80.58, 86.35, 92.4, 98.73, 105.6,
]
const INTERVALS: Dictionary[StringName, float] = {
	&"zombie": 2.0, &"skeleton": 3.0, &"spider": 2.0, &"slime": 4.0,
	&"goblin_miner": 3.5, &"barrel_bomber": 5.0,
}
## Bot income for counter picks (food/s), index 0 = level 1.
const BOT_FOOD: Array[float] = [
	0.3, 0.3, 0.31, 0.32, 0.33, 0.34, 0.34, 0.35, 0.36, 0.37,
	0.33, 0.34, 0.35, 0.35, 0.36, 0.37, 0.38, 0.39, 0.4, 0.4,
]
## HP/damage multiplier of bot units, index 0 = level 1. Set from
## tools/probe_breakeven.gd (power at which a typical player wins half the time):
## ordinary levels ~0.93 of break-even, every third level and bosses ~1.1 —
## "lose a couple of times, upgrade, win". Level 1: lost without upgrades.
const BOT_POWER: Array[float] = [
	1.16, 1.0, 1.05, 1.45, 1.5, 1.6, 1.9, 2.05, 1.8, 2.1,
	2.5, 2.75, 2.9, 2.8, 2.9, 2.85, 2.85, 2.95, 3.05, 3.35,
]
## Boss levels get a smaller army: the boss is the threat.
const BOSS_LEVEL_BUDGET := 0.75
const FIRST_WAVE_SEC := 8.0
const WAVE_GAP_SEC := 16.0
## Bot base HP from level 1 to level 20 (SPEC: 400 → 1500, lowered for shorter battles).
const BOT_BASE_HP := Vector2(250.0, 900.0)


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
	for id: String in ["army_power", "food_rate", "base_hp", "start_food", "unit_level", "battle_speed"]:
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
	level.bot_base_hp = roundf(lerpf(BOT_BASE_HP.x, BOT_BASE_HP.y, t) / 10.0) * 10.0
	level.bot_food_per_sec = BOT_FOOD[n - 1]
	level.bot_power = BOT_POWER[n - 1]
	level.counter_pick = true
	level.reward_coins = 240 + 40 * (n - 1)
	level.tutorial = n == 1
	level.min_start_food = 3.0 if n == 1 else 0.0
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
	# Fractional unit counts carry over to the next wave, so rare unit types
	# still show up instead of rounding to zero every wave.
	var carry: Dictionary[UnitData, float] = {}
	for i: int in wave_count:
		var wave := WaveData.new()
		wave.start_sec = FIRST_WAVE_SEC + i * WAVE_GAP_SEC + (5.0 if n == 1 else 0.0)
		var ramp: float = lerpf(0.5, 1.5, i / float(maxi(wave_count - 1, 1)))
		var budget: float = BUDGET[n - 1] / wave_count * ramp
		if n % PER_BIOME == 0:
			budget *= BOSS_LEVEL_BUDGET
		# The first wave of a level is zombies only: time to set up.
		if i == 0:
			_add(wave, u["zombie"], maxf(budget / u["zombie"].cost, 1.0), 2.0)
		else:
			for unit: UnitData in weights:
				var exact: float = budget * weights[unit] / total_w / unit.cost + carry.get(unit, 0.0)
				var whole: int = floori(exact)
				carry[unit] = exact - whole
				var interval: float = INTERVALS.get(unit.id, 3.0)
				_add(wave, unit, whole, interval)
			if wave.entries.is_empty():
				_add(wave, u["zombie"], 1.0, 2.0)
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
