class_name WaveEntry
extends Resource
## `count` units of one type, one every `interval_sec` (SPEC 5).

@export var unit: UnitData
@export var count: int = 1
@export var interval_sec: float = 1.0
## Wave leader: stronger (BalanceData.elite_power) and bigger on screen.
@export var elite: bool = false
