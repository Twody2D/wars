extends Node
## Player progress and meta economy (SPEC 7, 13). Saved after every change.

signal changed

const CONFIG_PATH := "res://data/game_config.tres"

var config: GameConfig
var coins: int = 0
## level number → best stars (only won levels are stored).
var level_stars: Dictionary[int, int] = {}
## Next level to play (1-based).
var current_level: int = 1
var biome_unlocked: int = 1
## unit id → level (missing = locked).
var unit_levels: Dictionary[StringName, int] = {}
## upgrade id → level
var upgrades: Dictionary[StringName, int] = {}
var battle_speed_on: bool = false
var sound_on: bool = true
## "" — take the language from the platform.
var lang: String = ""
## Level chosen for the next battle.
var selected_level: int = 1
## Off in tests so they never touch the real save file.
var autosave: bool = true
## Unix time of the last save (diagnostics; the cloud merge compares progress).
var saved_at: int = 0


func _ready() -> void:
	if config == null:
		config = load(CONFIG_PATH)
	if autosave:
		from_dict(SaveService.load_data())
	selected_level = current_level


# --- queries ---------------------------------------------------------------

func balance() -> BalanceData:
	return config.balance


func level(number: int) -> LevelData:
	return config.levels[clampi(number, 1, config.levels.size()) - 1]


func level_count() -> int:
	return config.levels.size()


func max_playable_level() -> int:
	return mini(current_level, biome_unlocked * config.levels_per_biome)


func is_unit_unlocked(id: StringName) -> bool:
	return unit_levels.get(id, 0) > 0


func unit_level(id: StringName) -> int:
	return unit_levels.get(id, 0)


func upgrade_level(id: StringName) -> int:
	return upgrades.get(id, 0)


func owned_units() -> Array[UnitData]:
	var result: Array[UnitData] = []
	for u: UnitData in config.player_units:
		if is_unit_unlocked(u.id):
			result.append(u)
	return result


func stars_total() -> int:
	var total := 0
	for n: int in level_stars:
		total += level_stars[n]
	return total


## Evolution is available after the last level of the unlocked biome.
func can_evolve() -> bool:
	var last: int = biome_unlocked * config.levels_per_biome
	return level_stars.has(last) and last < config.levels.size()


# --- prices ----------------------------------------------------------------

## −1 — maxed out.
func upgrade_cost(id: StringName) -> int:
	var up: UpgradeData = config.upgrade(id)
	var lvl: int = upgrade_level(id)
	if up == null or lvl >= up.max_level:
		return -1
	return up.cost_for_level(lvl, balance().upgrade_cost_growth, balance().upgrade_cost_round)


## −1 — already unlocked or not available in the unlocked biomes.
func unit_unlock_cost(id: StringName) -> int:
	var u: UnitData = config.unit(id)
	if u == null or is_unit_unlocked(id) or u.unlock_biome > biome_unlocked:
		return -1
	return u.unlock_cost


## −1 — locked or maxed.
func unit_level_cost(id: StringName) -> int:
	var lvl: int = unit_level(id)
	if lvl <= 0 or lvl >= balance().unit_max_level:
		return -1
	var up: UpgradeData = config.upgrade(&"unit_level")
	return up.cost_for_level(lvl - 1, balance().upgrade_cost_growth, balance().upgrade_cost_round)


# --- purchases (each saves) ------------------------------------------------

func buy_upgrade(id: StringName) -> bool:
	var cost: int = upgrade_cost(id)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	upgrades[id] = upgrade_level(id) + 1
	if id == &"battle_speed":
		battle_speed_on = true
	_commit()
	return true


func unlock_unit(id: StringName) -> bool:
	var cost: int = unit_unlock_cost(id)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	unit_levels[id] = 1
	_commit()
	return true


func level_up_unit(id: StringName) -> bool:
	var cost: int = unit_level_cost(id)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	unit_levels[id] = unit_level(id) + 1
	_commit()
	return true


func evolve() -> bool:
	if not can_evolve():
		return false
	biome_unlocked += 1
	_commit()
	return true


func set_battle_speed(on: bool) -> void:
	battle_speed_on = on and upgrade_level(&"battle_speed") > 0
	_commit()


## "ru" / "en"; "" — take it from the platform.
func set_lang(code: String) -> void:
	lang = code if code in ["", "ru", "en"] else ""
	_commit()


func set_sound(on: bool) -> void:
	sound_on = on
	_commit()


func apply_result(result: BattleResult) -> void:
	coins += result.coins
	if result.won:
		var best: int = level_stars.get(result.level_number, 0)
		level_stars[result.level_number] = maxi(best, result.stars)
		if result.level_number >= current_level:
			current_level = mini(result.level_number + 1, config.levels.size())
	_commit()
	if result.won and autosave:
		Platform.set_leaderboard_score(stars_total())


func add_coins(amount: int) -> void:
	coins += amount
	_commit()


# --- battle setup ------------------------------------------------------------

## Loadout for a battle with all meta upgrades applied (SPEC 4).
func make_setup(level_data: LevelData) -> BattleSetup:
	var b: BalanceData = balance()
	var s := BattleSetup.basic(b, level_data, owned_units(), randi())
	var food_lvl: int = upgrade_level(&"food_rate")
	s.food_rate = b.food_rate + food_lvl * _per_level(&"food_rate")
	s.food_max = b.food_max + floorf(food_lvl / 2.0) * b.food_max_per_2_levels
	s.player_base_hp = b.player_base_hp + upgrade_level(&"base_hp") * _per_level(&"base_hp")
	s.start_food = b.start_food + upgrade_level(&"start_food") * _per_level(&"start_food")
	s.player_power = 1.0 + upgrade_level(&"army_power") * _per_level(&"army_power")
	for id: StringName in unit_levels:
		s.unit_levels[id] = unit_levels[id]
	return s


func _per_level(id: StringName) -> float:
	var up: UpgradeData = config.upgrade(id)
	return up.per_level if up != null else 0.0


# --- save ------------------------------------------------------------------

func to_dict() -> Dictionary:
	var stars: Dictionary = {}
	for n: int in level_stars:
		stars[str(n)] = level_stars[n]
	var units: Dictionary = {}
	for id: StringName in unit_levels:
		units[String(id)] = {"unlocked": true, "level": unit_levels[id]}
	var ups: Dictionary = {}
	for id: StringName in upgrades:
		ups[String(id)] = upgrades[id]
	return {
		"coins": coins,
		"levels": stars,
		"current_level": current_level,
		"biome_unlocked": biome_unlocked,
		"units": units,
		"upgrades": ups,
		"battle_speed_on": battle_speed_on,
		"settings": {"sound": sound_on, "lang": lang},
		"saved_at": saved_at,
	}


## Loads a saved dictionary: unknown keys are dropped, every value is clamped.
func from_dict(data: Dictionary) -> void:
	_reset()
	if data.is_empty():
		return
	var max_level: int = config.levels.size()
	var max_biome: int = ceili(float(max_level) / config.levels_per_biome)
	saved_at = maxi(_int(data, "saved_at", 0), 0)
	coins = maxi(_int(data, "coins", 0), 0)
	current_level = clampi(_int(data, "current_level", 1), 1, max_level)
	biome_unlocked = clampi(_int(data, "biome_unlocked", 1), 1, max_biome)
	var stars: Dictionary = _dict(data, "levels")
	for key: Variant in stars:
		var n: int = str(key).to_int()
		var s: int = clampi(_int(stars, key, 0), 0, 3)
		if n >= 1 and n <= max_level and s > 0:
			level_stars[n] = s
	var units: Dictionary = _dict(data, "units")
	for u: UnitData in config.player_units:
		var entry: Dictionary = _dict(units, String(u.id))
		if entry.get("unlocked", false) == true:
			unit_levels[u.id] = clampi(_int(entry, "level", 1), 1, balance().unit_max_level)
	var ups: Dictionary = _dict(data, "upgrades")
	for up: UpgradeData in config.upgrades:
		if up.id != &"unit_level":
			upgrades[up.id] = clampi(_int(ups, String(up.id), 0), 0, up.max_level)
	battle_speed_on = data.get("battle_speed_on", false) == true and upgrade_level(&"battle_speed") > 0
	var settings: Dictionary = _dict(data, "settings")
	sound_on = settings.get("sound", true) != false
	var saved_lang: Variant = settings.get("lang", "")
	lang = saved_lang if saved_lang is String and saved_lang in ["", "ru", "en"] else ""


func reset_progress() -> void:
	_reset()
	if autosave:
		SaveService.clear()
	selected_level = 1
	changed.emit()


func _reset() -> void:
	saved_at = 0
	coins = 0
	level_stars.clear()
	current_level = 1
	biome_unlocked = 1
	unit_levels.clear()
	upgrades.clear()
	battle_speed_on = false
	for u: UnitData in config.player_units:
		if u.unlock_cost == 0:
			unit_levels[u.id] = 1
	for up: UpgradeData in config.upgrades:
		if up.id != &"unit_level":
			upgrades[up.id] = 0


## Cloud save from the platform (SPEC 13): taken if it has more progress —
## more stars in total, then more coins (another device, cleared browser data).
## Called once at boot.
func merge_cloud(data: Dictionary) -> void:
	if data.is_empty():
		return
	var local: Dictionary = to_dict()
	var local_rank: Vector2i = Vector2i(stars_total(), coins)
	from_dict(data)
	if Vector2i(stars_total(), coins) <= local_rank:
		from_dict(local)
		return
	selected_level = current_level
	if autosave:
		SaveService.save(to_dict())
	changed.emit()


func _commit() -> void:
	if autosave:
		saved_at = int(Time.get_unix_time_from_system())
		var data: Dictionary = to_dict()
		SaveService.save(data)
		Platform.save_cloud(data)
	changed.emit()


static func _int(d: Dictionary, key: Variant, fallback: int) -> int:
	var v: Variant = d.get(key, fallback)
	if v is int:
		return v
	if v is float:
		var f: float = v
		return int(f) if is_finite(f) else fallback
	return fallback


static func _dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	return v if v is Dictionary else {}
