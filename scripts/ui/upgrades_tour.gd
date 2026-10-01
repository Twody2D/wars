class_name UpgradesTour
extends Control
## A short tour of the upgrades screen after the first win: the fighters, the
## army power-ups, then the Battle tab. Everything but the shown part is
## dimmed (a soft-edged hole that glides from part to part); a tap anywhere
## goes to the next step.

signal finished

const TEXTS: Array[String] = ["TOUR_UNITS", "TOUR_ARMY", "TOUR_BATTLE"]

## Space around the highlighted part, px.
@export var padding: float = 10.0
@export var bob_px: float = 10.0
## Fingertip inside the hand icon (0..1), after the vertical flip.
@export var fingertip: Vector2 = Vector2(0.43, 0.94)
## Seconds for the light to glide to the next part and to fade in.
@export var move_sec: float = 0.45

var _targets: Array[Control] = []
var _step: int = -1
var _time: float = 0.0
## The lit rect now (glides towards the step's part).
var _hole: Rect2
var _from: Rect2
var _move: float = 1.0

@onready var _shade: ColorRect = $Shade
@onready var _hand: TextureRect = $Hand
@onready var _text: Label = $Text
@onready var _tap: Label = $Tap


func _ready() -> void:
	visible = false
	_hand.flip_v = true


func start(targets: Array[Control]) -> void:
	_targets = targets
	_step = 0
	_time = 0.0
	visible = true
	_text.text = tr(TEXTS[0])
	_hole = _visible_rect(targets[0]).grow(padding)
	_from = _hole
	_move = 1.0
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, move_sec)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	Audio.play_sfx(&"click", false)
	_step += 1
	if _step >= _targets.size():
		_step = -1
		visible = false
		finished.emit()
		return
	_text.text = tr(TEXTS[_step])
	_from = _hole
	_move = 0.0


func _process(delta: float) -> void:
	if _step < 0:
		return
	_time += delta
	var goal: Rect2 = _visible_rect(_targets[_step]).grow(padding)
	_move = minf(_move + delta / move_sec, 1.0)
	var k: float = ease(_move, -2.0)
	_hole = Rect2(_from.position.lerp(goal.position, k), _from.size.lerp(goal.size, k))
	var r: Rect2 = _hole
	var full: Vector2 = size
	var mat := _shade.material as ShaderMaterial
	mat.set_shader_parameter(&"rect_size", full)
	mat.set_shader_parameter(&"hole", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	# The hand points down at the top edge; the text sits above the hand, or
	# below the part when there is no room above.
	var bob: float = (sin(_time * 6.0) - 1.0) * 0.5 * bob_px
	var tip := Vector2(r.get_center().x, r.position.y + padding + 6.0)
	_hand.position = tip - fingertip * _hand.size + Vector2(0.0, bob)
	var text_y: float = _hand.position.y - _text.size.y - _tap.size.y - 4.0
	if text_y < 8.0:
		text_y = r.end.y + 8.0
	_text.position = Vector2(clampf(r.get_center().x - _text.size.x / 2.0, 16.0, full.x - 16.0 - _text.size.x), text_y)
	_tap.position = Vector2(_text.position.x + (_text.size.x - _tap.size.x) / 2.0, _text.position.y + _text.size.y)
	_tap.modulate.a = 0.8 + 0.2 * sin(_time * 3.0)


## The part of `c` on screen: cut by the scroll boxes it is in.
func _visible_rect(c: Control) -> Rect2:
	var r: Rect2 = c.get_global_rect()
	var p: Node = c.get_parent()
	while p != null:
		if p is ScrollContainer:
			r = r.intersection((p as Control).get_global_rect())
		p = p.get_parent()
	return r
