class_name UnitHpBar
extends Node2D
## Small HP bar above a unit, in the team colour.

@export var width: float = 46.0
@export var height: float = 7.0
@export var back: Color = Color(0.105882, 0.105882, 0.184314, 0.85)

var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()
var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-width / 2.0, -height / 2.0, width, height)
	draw_rect(rect.grow(1.5), back)
	draw_rect(Rect2(rect.position, Vector2(width * ratio, height)), color)
