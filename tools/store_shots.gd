extends SceneTree
## Store screenshots (Yandex: 1920×1080, mostly gameplay). A mid-game save
## lives in memory only (autosave off, the real save is never touched); a
## scripted player keeps buying units so the battles are busy.
##
## Run (a window opens for ~1 min):
##   "$GODOT" --path . --resolution 1920x1080 -s res://tools/store_shots.gd
## Output: build/store/shot_*.png

const OUT := "res://build/store/"
## [name, scene, tab or level, seconds to wait]. Battles are the real levels
## cut to the first and the last wave (the boss comes early, see _demo_level).
const SHOTS: Array[Array] = [
	["menu", "menu", 0, 1.2],
	["upgrades", "menu", 1, 1.2],
	["map", "menu", 2, 1.2],
	["battle_meadow", "battle", 10, 17.0],
	["battle_cave", "battle", 20, 17.0],
]
## Seconds (battle time) when the last wave starts in a shot battle.
const BOSS_WAVE_SEC := 5.0
## Stop buying this long before the shot so the cards are bright again.
const QUIET_SEC := 3.5
const BUY_EVERY_SEC := 1.1
const MIX: Array[StringName] = [&"zombie", &"skeleton", &"slime", &"zombie", &"spider", &"goblin_miner", &"barrel_bomber"]

var _gs: Node
var _index: int = -1
var _t: float = 0.0
var _think: float = 0.0
var _next: int = 0


func _process(delta: float) -> bool:
	if _gs == null:
		_gs = root.get_node(^"GameState")
		_gs.set(&"autosave", false)
		_gs.call(&"from_dict", {
			"coins": 16450, "current_level": 12, "biome_unlocked": 2,
			"levels": {"1": 3, "2": 3, "3": 3, "4": 2, "5": 3, "6": 3, "7": 2, "8": 3, "9": 2, "10": 3, "11": 2},
			"units": {
				"zombie": {"unlocked": true, "level": 4}, "skeleton": {"unlocked": true, "level": 4},
				"slime": {"unlocked": true, "level": 3}, "spider": {"unlocked": true, "level": 3},
				"goblin_miner": {"unlocked": true, "level": 2}, "barrel_bomber": {"unlocked": true, "level": 1},
			},
			"upgrades": {"army_power": 8, "food_rate": 7, "base_hp": 6, "start_food": 2},
			"settings": {"sound": false},
		})
		TranslationServer.set_locale("ru")
		_start(0)
		return false
	_t += delta
	var shot: Array = SHOTS[_index]
	if shot[1] == "menu" and _t > 0.3 and current_scene != null and current_scene.has_method(&"_open_tab"):
		current_scene.call(&"_open_tab", shot[2])
	if shot[1] == "battle":
		_play(delta)
	if _t >= shot[3]:
		root.get_texture().get_image().save_png(OUT + "shot_%s.png" % shot[0])
		print("saved shot_", shot[0])
		if _index + 1 >= SHOTS.size():
			return true
		_start(_index + 1)
	return false


func _start(index: int) -> void:
	_index = index
	_t = 0.0
	_next = 0
	var shot: Array = SHOTS[index]
	if shot[1] == "menu":
		change_scene_to_file.call_deferred("res://scenes/menu/main.tscn")
	else:
		var number: int = shot[2]
		_gs.set(&"selected_level", number)
		var battle: Node = (load("res://scenes/battle/battle.tscn") as PackedScene).instantiate()
		battle.set(&"level_override", _demo_level(number))
		change_scene_to_node.call_deferred(battle)


func _demo_level(number: int) -> LevelData:
	var src: LevelData = _gs.call(&"level", number)
	var level: LevelData = src.duplicate(true)
	var first: WaveData = src.waves[0].duplicate(true)
	var last: WaveData = src.waves[src.waves.size() - 1].duplicate(true)
	first.start_sec = 1.0
	last.start_sec = BOSS_WAVE_SEC
	level.waves = [first, last] as Array[WaveData]
	level.tutorial = false
	return level


## A quick player: full food, one unit of the mix every half second, ore and meteor.
func _play(delta: float) -> void:
	if current_scene == null or current_scene.get(&"sim") == null:
		return
	var sim: Object = current_scene.get(&"sim")
	_think -= delta
	if _think > 0.0 or _t > SHOTS[_index][3] - QUIET_SEC:
		return
	_think = BUY_EVERY_SEC
	sim.set(&"food", sim.get(&"food_max"))
	var setup: Object = sim.get(&"setup")
	var units: Array = setup.get(&"player_units")
	for u: Object in units:
		if u.get(&"id") == MIX[_next % MIX.size()]:
			current_scene.call(&"_buy", u)
			break
	_next += 1
	if _t > 8.0 and _t < 9.0:
		current_scene.call(&"_mine", 0)
