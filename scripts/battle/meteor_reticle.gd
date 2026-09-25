class_name MeteorReticle
extends Node2D
## Meteor aim circle that follows the pointer while targeting.

@export var radius: float = 110.0:
	set(value):
		radius = value
		queue_redraw()
@export var fill: Color = Color(1.0, 0.4, 0.1, 0.18)
@export var outline: Color = Color(1.0, 0.55, 0.15, 0.9)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, outline, 3.0)
