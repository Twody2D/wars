class_name BattleResult
extends RefCounted
## Outcome of one battle, filled by Rewards.calculate.

var level_number: int = 1
var won: bool = false
var kills: int = 0
## Player base HP left, 0..1.
var hp_ratio: float = 0.0
var stars: int = 0
var coins: int = 0
## Set when the player doubled coins with a rewarded ad.
var doubled: bool = false
