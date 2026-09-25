@tool
class_name UnitVisual
extends Node2D
## Cut-out unit built from art/units/<unit_id>/pivots.json (SPEC 10, 11).
##
## Layout: UnitVisual/Rig/Parts/<Part>/S
##   Rig   — whole-body motion (fall, squash, waddle); animated by libraries.
##   Parts — constant scale (display/import), holds joints.
##   <Part> — Node2D at the pivot with the rest rotation; S — the sprite, animated.
## Weapon is parented to ArmFront/S so it follows the swing.
## Origin is at the feet. Facing left = scale.x −1 on the root.

signal hit_frame
signal poof_requested(at: Vector2)
signal die_finished

const ART_DIR := "res://art/units/%s/"

@export var unit_id: StringName = &"":
	set(value):
		unit_id = value
		if is_node_ready():
			_build()
@export var team_color: Color = Color("#3A7BFF"):
	set(value):
		team_color = value
		_apply_team_color()
@export var facing_left: bool = false:
	set(value):
		facing_left = value
		scale.x = -1.0 if facing_left else 1.0
## Overrides the design's arm rest angle (zombie holds arms forward, SPEC 10).
@export var override_arm_rest: bool = false
@export_range(-180.0, 180.0) var arm_rest_deg: float = 0.0
## Bosses play the humanoid library slower (SPEC 10).
@export var anim_speed: float = 1.0

var _rig: Node2D
var _parts: Node2D
var _team_sprite: Sprite2D

@onready var _player: AnimationPlayer = $AnimationPlayer
@onready var _hit_player: AnimationPlayer = $HitPlayer


func _ready() -> void:
	_build()


func play(anim: StringName, speed: float = 1.0) -> void:
	_player.speed_scale = anim_speed * speed
	if anim == &"attack" or anim == &"die":
		_player.stop()
	if _player.current_animation != anim:
		_player.play(anim)


func play_hit() -> void:
	_hit_player.stop()
	_hit_player.play(&"hit")


## Back to a clean pose before returning to the pool.
func reset_pose() -> void:
	_hit_player.stop()
	_player.stop()
	_player.play(&"idle")
	_player.seek(0.0, true)
	_rig.modulate = Color.WHITE
	_parts.modulate = Color.WHITE


func _on_hit_frame() -> void:
	hit_frame.emit()


func _spawn_poof() -> void:
	poof_requested.emit(global_position + Vector2(0.0, -24.0))


func _on_die_finished() -> void:
	die_finished.emit()


func _build() -> void:
	if _rig != null:
		_rig.free()
		_rig = null
	if unit_id == &"":
		return
	var json_path: String = (ART_DIR % unit_id) + "pivots.json"
	if not FileAccess.file_exists(json_path):
		push_error("UnitVisual: no pivots for %s" % unit_id)
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	var import_scale: float = data["import_scale"]
	var display_scale: float = data["display_scale"]
	var feet_arr: Array = data["feet"]
	var feet: Vector2 = _vec(feet_arr)
	var order: Array = data["order"]
	var parts: Dictionary = data["parts"]

	_rig = Node2D.new()
	_rig.name = "Rig"
	add_child(_rig)
	move_child(_rig, 0)
	_parts = Node2D.new()
	_parts.name = "Parts"
	_parts.scale = Vector2.ONE * (display_scale / import_scale)
	_rig.add_child(_parts)

	var arm_front_sprite: Sprite2D = null
	var arm_front_xform := Transform2D.IDENTITY
	for part_id: String in order:
		var info: Dictionary = parts[part_id]
		var pivot_arr: Array = info["pivot"]
		var pivot: Vector2 = _vec(pivot_arr)
		var rest_deg: float = info["rest_deg"]
		if override_arm_rest and part_id.begins_with("arm_"):
			rest_deg = arm_rest_deg
		var joint := Node2D.new()
		joint.name = part_id.to_pascal_case()
		var sprite := Sprite2D.new()
		sprite.name = "S"
		sprite.centered = false
		sprite.texture = load((ART_DIR % unit_id) + part_id + ".svg")
		sprite.offset = -pivot * import_scale
		joint.add_child(sprite)
		var design_xform := Transform2D(deg_to_rad(rest_deg), pivot)
		if part_id == "weapon" and arm_front_sprite != null:
			# Keep the design placement, expressed relative to the front arm.
			var rel: Transform2D = arm_front_xform.affine_inverse() * design_xform
			joint.position = rel.origin * import_scale
			joint.rotation = rel.get_rotation()
			arm_front_sprite.add_child(joint)
		else:
			joint.position = (pivot - feet) * import_scale
			joint.rotation = deg_to_rad(rest_deg)
			_parts.add_child(joint)
		if part_id == "arm_front":
			arm_front_sprite = sprite
			arm_front_xform = design_xform
		if part_id == "team_accent":
			_team_sprite = sprite
	_apply_team_color()


func _apply_team_color() -> void:
	if _team_sprite != null:
		_team_sprite.self_modulate = team_color


func _vec(value: Array) -> Vector2:
	var x: float = value[0]
	var y: float = value[1]
	return Vector2(x, y)
