class_name DragScroll
extends ScrollContainer
## Scroll box of the map and the upgrades: one scroller for the mouse, the
## finger and the touchpad — drag (with a fling that slows down after a
## swipe), a smooth wheel, and a hint that bobs while there is more content
## further on. The container's own touch drag is off: on a device that
## reports a touchscreen it ran together with this one and the screen jerked.

## Pixels per wheel notch (a touchpad sends parts of a notch).
@export var wheel_step: float = 70.0
## Seconds for the smooth wheel scroll.
@export var wheel_sec: float = 0.18
## The pointer must move this far before it drags (a shorter move is a tap).
@export var drag_threshold: float = 10.0
## After a swipe the content keeps going and slows down by this factor per second.
@export var fling_friction: float = 6.0
## Slower swipes than this (px/s) stop dead.
@export var fling_min_speed: float = 60.0
## Pixels per unit of a touchpad pan gesture.
@export var pan_step: float = 40.0
## Shown while there is more to scroll to (below or to the right); may be empty.
@export var more_hint: Control
@export var hint_bob: float = 6.0

const FAR := Vector2(-10000.0, -10000.0)

var _pressed: bool = false
var _dragging: bool = false
var _press_at: float = 0.0
var _start_scroll: float = 0.0
var _last_at: float = 0.0
var _last_usec: int = 0
## Fling speed along the main axis, px/s (0 — standing still).
var _speed: float = 0.0
var _tween: Tween
var _target: float = 0.0


func _ready() -> void:
	# The built-in touch drag never starts: this script drags instead.
	scroll_deadzone = 1 << 20
	if more_hint != null:
		var y: float = more_hint.position.y
		var bob: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		bob.tween_property(more_hint, "position:y", y + hint_bob, 0.5)
		bob.tween_property(more_hint, "position:y", y, 0.5)


func _process(delta: float) -> void:
	if more_hint != null:
		more_hint.visible = is_visible_in_tree() and _left() > 4.0
	if _speed == 0.0 or _pressed:
		return
	_set_scroll(_scroll() + _speed * delta)
	_speed *= exp(-fling_friction * delta)
	if absf(_speed) < fling_min_speed or _left() <= 0.0 or _scroll() <= 0.0:
		_speed = 0.0


func _vertical() -> bool:
	return horizontal_scroll_mode == SCROLL_MODE_DISABLED


func _scroll() -> float:
	return float(scroll_vertical if _vertical() else scroll_horizontal)


func _set_scroll(value: float) -> void:
	var v: int = roundi(clampf(value, 0.0, _scroll() + _left()))
	if _vertical():
		scroll_vertical = v
	else:
		scroll_horizontal = v


## How much is left to scroll on the main axis.
func _left() -> float:
	var bar: ScrollBar = get_v_scroll_bar() if _vertical() else get_h_scroll_bar()
	return bar.max_value - bar.page - _scroll()


func _axis(p: Vector2) -> float:
	return p.y if _vertical() else p.x


func _stop() -> void:
	_speed = 0.0
	if _tween != null:
		_tween.kill()


## Mouse wheel and touchpad: smooth steps towards a target.
func _gui_input(event: InputEvent) -> void:
	var pan := event as InputEventPanGesture
	if pan != null:
		accept_event()
		_stop()
		_set_scroll(_scroll() + _axis(pan.delta) * pan_step)
		return
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
	_speed = 0.0
	var now: float = _scroll()
	if _tween == null or not _tween.is_running():
		_target = now
	# A touchpad sends many small parts of a notch (factor < 1).
	var factor: float = mb.factor if mb.factor > 0.0 else 1.0
	_target = clampf(_target + dir * wheel_step * factor, 0.0, now + _left())
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scroll_vertical" if _vertical() else "scroll_horizontal", roundi(_target), wheel_sec)


## Drag with the held left button or a finger (it comes as an emulated mouse).
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			var hovered: Control = get_viewport().gui_get_hovered_control()
			_pressed = hovered != null and (hovered == self or is_ancestor_of(hovered))
			if _pressed:
				_stop()
			_dragging = false
			_press_at = _axis(mb.position)
			_last_at = _press_at
			_last_usec = Time.get_ticks_usec()
		elif _pressed:
			_pressed = false
			if _dragging:
				_dragging = false
				# The swipe was too long ago: no fling.
				if Time.get_ticks_usec() - _last_usec > 80000 or absf(_speed) < fling_min_speed:
					_speed = 0.0
				_release_away(mb)
		return
	var motion := event as InputEventMouseMotion
	if motion == null or not _pressed:
		return
	var at: float = _axis(motion.position)
	if not _dragging:
		if absf(at - _press_at) < drag_threshold:
			return
		# Start from here, not from the press: no jump by the threshold.
		_dragging = true
		_press_at = at
		_start_scroll = _scroll()
	var now_usec: int = Time.get_ticks_usec()
	var dt: float = maxf((now_usec - _last_usec) / 1000000.0, 0.001)
	# Content follows the finger, so the fling goes against the finger's motion.
	_speed = lerpf(_speed, -(at - _last_at) / dt, 0.4)
	_last_at = at
	_last_usec = now_usec
	_set_scroll(_start_scroll - (at - _press_at))


## The button under the pointer must not fire after a drag: the pointer
## "leaves" it first, then the release comes far away from it.
func _release_away(mb: InputEventMouseButton) -> void:
	get_viewport().set_input_as_handled()
	var leave := InputEventMouseMotion.new()
	leave.position = FAR
	leave.global_position = FAR
	var away := mb.duplicate() as InputEventMouseButton
	away.position = FAR
	away.global_position = FAR
	get_viewport().push_input.call_deferred(leave)
	get_viewport().push_input.call_deferred(away)
