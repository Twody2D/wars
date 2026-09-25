class_name BattleSetup
extends RefCounted
## Everything BattleSim needs to start: level, balance and the player's loadout.

var balance: BalanceData
var level: LevelData
var player_units: Array[UnitData] = []
## unit id → level 1..5 (missing → 1).
var unit_levels: Dictionary[StringName, int] = {}
var player_base_hp: float = 300.0
var start_food: float = 5.0
var food_rate: float = 0.5
var food_max: float = 30.0
var rng_seed: int = 1
## HP/damage multiplier for all player units ("army power" upgrade).
var player_power: float = 1.0


func level_of(unit: UnitData) -> int:
	return unit_levels.get(unit.id, 1)


## Loadout with no upgrades, straight from balance.
static func basic(balance_: BalanceData, level_: LevelData, units: Array[UnitData], seed_: int = 1) -> BattleSetup:
	var s := BattleSetup.new()
	s.balance = balance_
	s.level = level_
	s.player_units = units
	s.player_base_hp = balance_.player_base_hp
	s.start_food = balance_.start_food
	s.food_rate = balance_.food_rate
	s.food_max = balance_.food_max
	s.rng_seed = seed_
	return s
