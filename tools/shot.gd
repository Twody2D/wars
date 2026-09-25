extends SceneTree
## Opens a scene, lets it run, saves screenshots. For reviewing layout from the CLI.
## Run (needs a window): "$GODOT" --path . -s res://tools/shot.gd -- <scene> <out_prefix> <t1,t2,...> [spawn]
## "spawn" — in a battle, sends a mixed army for the player every few seconds.
## "call=<method>:<int>" — calls a method on the scene root after the first frame.

var _scene: String
var _prefix: String
var _times: Array[float] = []
var _spawn: bool = false
var _elapsed: float = 0.0
var _shot: int = 0
var _spawn_timer: float = 0.0
var _call: String = ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_scene = args[0]
	_prefix = args[1]
	for t: String in args[2].split(","):
		_times.append(t.to_float())
	_spawn = args.size() > 3 and args[3] == "spawn"
	if args.size() > 3 and args[3].begins_with("call="):
		_call = args[3].trim_prefix("call=")
	change_scene_to_file.call_deferred(_scene)


func _process(delta: float) -> bool:
	_elapsed += delta
	if _call != "" and current_scene != null and _elapsed > 0.3:
		var parts: PackedStringArray = _call.split(":")
		current_scene.call(StringName(parts[0]), parts[1].to_int())
		_call = ""
	# Duck-typed: -s scripts compile before autoloads, so no Battle type here.
	if _spawn and current_scene != null and current_scene.get(&"sim") != null:
		var sim: Object = current_scene.get(&"sim")
		_spawn_timer += delta
		if _spawn_timer > 2.5:
			_spawn_timer = 0.0
			var setup: Object = sim.get(&"setup")
			var units: Array = setup.get(&"player_units")
			sim.set(&"food", sim.get(&"food_max"))
			sim.call(&"buy", units[randi() % units.size()])
	if _shot < _times.size() and _elapsed >= _times[_shot]:
		var path := "%s_%d.png" % [_prefix, _shot]
		root.get_texture().get_image().save_png(path)
		print("saved ", path)
		_shot += 1
	return _shot >= _times.size()
