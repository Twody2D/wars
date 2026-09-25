class_name SimProjectile
extends RefCounted
## A projectile in flight: homes on the target's x, hits when time runs out.

var uid: int
var kind: StringName
var side: int
var damage: float
var splash: float = 0.0
var target: SimUnit = null
var target_base: bool = false
var start_x: float
var x: float
var target_x: float
var y_offset: float = 0.0
var elapsed: float = 0.0
var duration: float = 0.1


func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0)
