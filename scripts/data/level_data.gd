class_name LevelData
extends Resource
## One battle level (SPEC 5).

@export var number: int = 1
@export var biome: StringName = &"meadow"
@export var bot_base_hp: float = 400.0
## Multiplier on HP and damage of every bot unit — the main difficulty knob.
@export var bot_power: float = 1.0
@export var waves: Array[WaveData] = []
## Bot income between waves, spent on counter picks.
@export var bot_food_per_sec: float = 0.3
@export var counter_pick: bool = false
## Units the bot uses for counter picks and pressure after the last wave.
@export var bot_units: Array[UnitData] = []
@export var reward_coins: int = 20
@export var ore_blocks: int = 2
@export var tutorial: bool = false
