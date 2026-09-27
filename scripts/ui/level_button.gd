class_name LevelButton
extends Button
## Level node on the world map (menu v3 mockup): passed (blue, stars under it),
## current (big gold, a bouncing arrow above), locked (grey), boss levels 10
## and 20 (red, the boss's face, a lock until open). The node is placed by the
## centre of its face (see face_center), as in kit/map_nodes.json.

signal level_chosen(number: int)

@export var node_textures: Dictionary[String, Texture2D] = {}
@export var star_full: Texture2D
@export var star_empty: Texture2D
@export var boss_faces: Dictionary[int, Texture2D] = {}

## Per look: node size, face centre, number rect (y, height), number font size, stars y.
const LOOKS: Dictionary = {
	"passed": [Vector2(104, 112), Vector2(52, 48), Vector2(28, 40), 34, 90],
	"locked": [Vector2(104, 112), Vector2(52, 48), Vector2(28, 40), 34, 90],
	"current": [Vector2(156, 168), Vector2(78, 72), Vector2(46, 52), 44, 150],
	"boss": [Vector2(164, 184), Vector2(82, 80), Vector2(140, 36), 30, 178],
}
const LOCKED_NUMBER := Color("#EEF1F7")
const ARROW_BOB := 10.0
const ARROW_BOB_SEC := 0.4

var number: int = 1
var face_center: Vector2 = Vector2(52, 48)

@onready var _node: TextureRect = %Node
@onready var _face: TextureRect = %Face
@onready var _number: Label = %Number
@onready var _stars_box: Control = %Stars
@onready var _stars: Array[TextureRect] = [$Stars/S1, $Stars/S2, $Stars/S3]
@onready var _lock: TextureRect = %Lock
@onready var _arrow: TextureRect = %Arrow


func _ready() -> void:
	pressed.connect(func() -> void: level_chosen.emit(number))
	button_down.connect(func() -> void: scale = Vector2(0.94, 0.94))
	button_up.connect(func() -> void: scale = Vector2.ONE)


func setup(number_: int) -> void:
	number = number_
	var stars: int = GameState.level_stars.get(number, 0)
	var open: bool = number <= GameState.max_playable_level()
	var current: bool = open and number == GameState.max_playable_level()
	var boss: bool = boss_faces.has(number)
	var look: String = "boss" if boss else ("current" if current else ("passed" if open else "locked"))
	var l: Array = LOOKS[look]
	var node_size: Vector2 = l[0]
	face_center = l[1]
	var num_rect: Vector2 = l[2]
	size = node_size
	custom_minimum_size = node_size
	pivot_offset = face_center
	_node.texture = node_textures[look]
	_face.visible = boss
	if boss:
		_face.texture = boss_faces[number]
	_number.text = str(number)
	_number.position = Vector2(0.0, num_rect.x)
	_number.size = Vector2(node_size.x, num_rect.y)
	var font_size: int = l[3]
	_number.add_theme_font_size_override(&"font_size", font_size)
	_number.add_theme_color_override(&"font_color", LOCKED_NUMBER if look == "locked" else Color.WHITE)
	_stars_box.visible = stars > 0
	var stars_y: float = l[4]
	_stars_box.position = Vector2((node_size.x - _stars_box.size.x) / 2.0, stars_y)
	for i: int in 3:
		_stars[i].texture = star_full if i < stars else star_empty
	_lock.visible = boss and not open
	disabled = not open
	_arrow.visible = current
	if current:
		_arrow.position = Vector2(face_center.x - _arrow.size.x / 2.0, face_center.y - 152.0)
		var y: float = _arrow.position.y
		var tween: Tween = create_tween().set_loops()
		tween.tween_property(_arrow, "position:y", y - ARROW_BOB, ARROW_BOB_SEC).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_arrow, "position:y", y, ARROW_BOB_SEC).set_trans(Tween.TRANS_SINE)


## Places the node so its face centre is at `center` (map coordinates).
func place(center: Vector2) -> void:
	position = center - face_center
