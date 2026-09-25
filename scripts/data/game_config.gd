class_name GameConfig
extends Resource
## Root data resource: what exists in the game and in which order.

@export var balance: BalanceData
## Units the player can own, in card order (keys 1–6).
@export var player_units: Array[UnitData] = []
@export var upgrades: Array[UpgradeData] = []
@export var levels: Array[LevelData] = []
## Levels per biome; the last one of each biome has a boss.
@export var levels_per_biome: int = 10


func upgrade(id: StringName) -> UpgradeData:
	for up: UpgradeData in upgrades:
		if up.id == id:
			return up
	return null


func unit(id: StringName) -> UnitData:
	for u: UnitData in player_units:
		if u.id == id:
			return u
	return null
