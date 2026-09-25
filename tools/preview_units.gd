extends SceneTree
## Renders all unit visuals (rest pose + animation frames) to a PNG for review.
## Run (needs a window, not --headless):
##   "$GODOT" --path . -s res://tools/preview_units.gd -- <out.png> [anim] [time]

const UNITS: Array[String] = [
	"zombie", "skeleton", "slime", "spider", "goblin_miner", "barrel_bomber",
	"boss_zombie_king", "boss_stone_golem",
]
const ROWS: Array[StringName] = [&"idle", &"walk", &"attack", &"die"]
const ROW_TIMES: Array[float] = [0.0, 0.15, 0.3, 0.3]

var _frames := 0
var _out := "user://units_preview.png"
var _visuals: Array[UnitVisual] = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	root.size = Vector2i(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color("#7FB069")
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	for row: int in ROWS.size():
		for col: int in UNITS.size():
			var scene: PackedScene = load("res://art/units/%s/%s_visual.tscn" % [UNITS[col], UNITS[col]])
			var visual: UnitVisual = scene.instantiate()
			visual.position = Vector2(80 + col * 150, 160 + row * 170)
			if not UNITS[col].begins_with("boss_"):
				visual.scale = Vector2(2, 2)
			visual.team_color = Color("#3A7BFF") if col % 2 == 0 else Color("#FF4A4A")
			root.add_child(visual)
			_visuals.append(visual)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		for i: int in _visuals.size():
			var player: AnimationPlayer = _visuals[i].get_node("AnimationPlayer")
			player.play(ROWS[i / UNITS.size()])
			player.seek(ROW_TIMES[i / UNITS.size()], true)
			player.pause()
	if _frames == 5:
		var image := root.get_texture().get_image()
		image.save_png(_out)
		print("saved ", _out)
		return true
	return false
