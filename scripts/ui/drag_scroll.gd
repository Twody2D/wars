class_name DragScroll
extends ScrollContainer
## Scroll box of the map and the upgrades: drag it with the held left mouse
## button (phones drag by touch already), a smooth mouse wheel with a small
## step, and a hint that bobs while there is more content further on.

## Pixels per wheel notch.
@export var wheel_step: float = 70.0
## Seconds for the smooth wheel scroll.
@export var wheel_sec: float = 0.18
## The mouse must move this far before it drags (a shorter move is a click).
@export var drag_threshold: float = 10.0
## Shown while there is more to scroll to (below or to the right); may be empty.
@export var more_hint: Control
@export var hint_bob: float = 6.0

const FAR := Vector2(-10000.0, -10000.0)

var _pressed: bool = false
var _dragging: bool = false
var _press_at: Vector2
var _start_scroll: Vector2
var _tween: Tween
var _target: float = 0.0
var _hint_y: float = 0.0


func _ready() -> void:
	if more_hint != null:
		_hint_y = more_hint.position.y
		var bob: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		bob.tween_property(more_hint, "position:y", _hint_y + hint_bob, 0.5)
		bob.tween_property(more_hint, "position:y", _hint_y, 0.5)


func _process(_delta: float) -> void:
	if more_hint != null:
		more_hint.visible = is_visible_in_tree() and _left() > 4.0


## How much is left to scroll on the main axis.
func _left() -> float:
	if _vertical():
		return get_v_scroll_bar().max_value - get_v_scroll_bar().page - scroll_vertical
	return get_h_scroll_bar().max_value - get_h_scroll_bar().page - scroll_horizontal


func _vertical() -> bool:
	return horizontal_scroll_mode == SCROLL_MODE_DISABLED


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	var dir: float = 0.0
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
		dir = 1.0
	elif mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT:
		dir = -1.0
	if dir == 0.0:
		return
	accept_event()
	var now: float = scroll_vertical if _vertical() else scroll_horizontal
	if _tween == null or not _tween.is_running():
		_target = now
	_target = clampf(_target + dir * wheel_step * maxf(mb.factor, 1.0), 0.0, now + _left())
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scroll_vertical" if _vertical() else "scroll_horizontal", roundi(_target), wheel_sec)


## The held left button drags the content. Touch is left to the container
## itself (emulated mouse events are skipped, or it would scroll twice).
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			var hovered: Control = get_viewport().gui_get_hovered_control()
			_pressed = hovered != null and (hovered == self or is_ancestor_of(hovered))
			_dragging = false
			_press_at = mb.position
			_start_scroll = Vector2(scroll_horizontal, scroll_vertical)
		elif _pressed:
			_pressed = false
			if _dragging:
				_dragging = false
				# The button under the pointer must not fire: the pointer
				# "leaves" it first, then the release comes far away from it.
				get_viewport().set_input_as_handled()
				var leave := InputEventMouseMotion.new()
				leave.position = FAR
				leave.global_position = FAR
				var away := mb.duplicate() as InputEventMouseButton
				away.position = FAR
				away.global_position = FAR
				get_viewport().push_input.call_deferred(leave)
				get_viewport().push_input.call_deferred(away)
		return
	var motion := event as InputEventMouseMotion
	if motion == null or not _pressed:
		return
	var moved: Vector2 = motion.position - _press_at
	if not _dragging and moved.length() < drag_threshold:
		return
	_dragging = true
	if _tween != null:
		_tween.kill()
	if _vertical():
		scroll_vertical = roundi(_start_scroll.y - moved.y)
	else:
		scroll_horizontal = roundi(_start_scroll.x - moved.x)
