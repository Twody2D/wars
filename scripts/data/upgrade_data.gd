class_name UpgradeData
extends Resource
## A meta upgrade bought with coins (SPEC 7).

@export var id: StringName
@export var name_key: String
@export var base_cost: int = 30
@export var max_level: int = 10
## Effect per level, meaning depends on the upgrade (food/s, HP, food).
@export var per_level: float = 0.0
## One-time purchase (battle speed toggle): cost is base_cost, max_level 1.
@export var one_time: bool = false


## Price of the next level: base_cost × growth^level, rounded to `round_to`.
func cost_for_level(level: int, growth: float, round_to: int) -> int:
	if one_time:
		return base_cost
	var raw: float = base_cost * pow(growth, level)
	return roundi(raw / round_to) * round_to
