class_name EffectLayer
extends Node2D
## Pooled sprite-sheet effects (fx_*: 6 frames in a row). No nodes are created
## or freed during battle — sprites are prewarmed and reused.

@export var effects: Dictionary[StringName, Texture2D] = {}
@export var frames: int = 6
@export var fps: float = 14.0
@export var pool_size: int = 32
## Slower playback for some effects (e.g. the meteor blast).
@export var fps_overrides: Dictionary[StringName, float] = {}

var _free: Array[Sprite2D] = []
var _active: Array[Sprite2D] = []


func _ready() -> void:
	for i: int in pool_size:
		var s := Sprite2D.new()
		s.hframes = frames
		s.visible = false
		add_child(s)
		_free.append(s)


func spawn(kind: StringName, at: Vector2, size: float = 1.0) -> void:
	var tex: Texture2D = effects.get(kind)
	if tex == null or _free.is_empty():
		return
	var s: Sprite2D = _free.pop_back()
	s.texture = tex
	s.frame = 0
	s.position = at
	s.scale = Vector2.ONE * size
	s.visible = true
	s.set_meta(&"t", 0.0)
	s.set_meta(&"fps", fps_overrides.get(kind, fps))
	_active.append(s)


func _process(delta: float) -> void:
	var done: Array[Sprite2D] = []
	for s: Sprite2D in _active:
		var t: float = s.get_meta(&"t", 0.0)
		t += delta
		s.set_meta(&"t", t)
		var kind_fps: float = s.get_meta(&"fps", fps)
		var f: int = floori(t * kind_fps)
		if f >= frames:
			done.append(s)
		else:
			s.frame = f
	for s: Sprite2D in done:
		s.visible = false
		_active.erase(s)
		_free.append(s)
