class_name LevelButton
extends Button
## Level slot on the map: number, stars, lock (SPEC 7).

signal level_chosen(number: int)

var number: int = 1

@onready var _stars: Array[TextureRect] = [$Stars/S1, $Stars/S2, $Stars/S3]
@onready var _lock: TextureRect = $Lock


func _ready() -> void:
	pressed.connect(func() -> void: level_chosen.emit(number))


func setup(number_: int) -> void:
	number = number_
	text = str(number)
	var stars: int = GameState.level_stars.get(number, 0)
	var open: bool = number <= GameState.max_playable_level()
	disabled = not open
	_lock.visible = not open
	for i: int in 3:
		_stars[i].visible = stars > 0
		_stars[i].modulate = Color.WHITE if i < stars else Color(0.2, 0.2, 0.25, 0.7)
	if number == GameState.current_level and open:
		modulate = Color(1.15, 1.15, 0.8)
