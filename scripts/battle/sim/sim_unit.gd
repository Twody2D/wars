class_name SimUnit
extends RefCounted
## A unit inside BattleSim. Pure data, no nodes.

enum State { WALK, WAIT, ATTACK, DEAD }

var uid: int
var data: UnitData
var side: int
var level: int = 1
## +1 — moves right (player), −1 — moves left (bot).
var dir: float = 1.0
var x: float
## Visual lane offset (±y_jitter), rolled by the sim RNG for determinism.
var y_offset: float = 0.0
var hp: float
var max_hp: float
var damage: float
var state: State = State.WALK
var cooldown_left: float = 0.0
## Seconds until the pending hit lands; < 0 — no attack in progress.
var hit_timer: float = -1.0
var target: SimUnit = null
var target_base: bool = false
## Index in its side's front-to-back order, refreshed every step.
var rank: int = 0


func is_alive() -> bool:
	return state != State.DEAD


## Signed distance to `other_x` along the movement direction (> 0 — ahead).
func ahead(other_x: float) -> float:
	return (other_x - x) * dir
