extends SceneTree
## Records the store gameplay video with Movie Maker (frames + sound, no drops).
## Like the competitors' videos: no captions, the camera close to the fight,
## no HUD panels, variety — menu → meadow battle with the Zombie King → buying
## new fighters → cave battle with goblins, bombers and the Stone Golem →
## victory. A scripted "director" plays. Progress lives in memory only:
## autosave is off, the real save is never touched.
##
## Run (a window opens for ~2 min, do not touch it):
##   "$GODOT" --path . --write-movie build/store/raw.avi --fixed-fps 30 -s res://tools/record_trailer.gd
## (Movie Maker records at the project window size, 1280×720), then:
##   py -3.14 tools/make_trailer.py
## Music is muted here (the editor lays one continuous track over the cuts);
## event times go to build/store/events.json for the editor.

const END_CARD_SVG := "res://design/Art sections 1 and 2 complete/assets/v2/brand/store_cover.svg"
const MENU_SEC := 1.8
const UPGRADES_SEC := 3.2
## Game seconds of the meadow battle (it is cut before the end).
const MEADOW_SEC := 34.0
const RESULT_HOLD_SEC := 2.5
const MAX_TOTAL_SEC := 240.0
## Camera: zoomed in on the front line, follows it smoothly.
const ZOOM := 2.2
const CAMERA_Y := 345.0
const CAMERA_FOLLOW := 2.5

## Per battle: level, kept waves, their start (sim s), boss HP, bot base HP, bot power.
const MEADOW := {"level": 10, "waves": [0, -1], "start": [2.0, 10.0], "boss_hp": 380.0, "base_hp": 420.0, "power": 1.3}
const CAVE := {"level": 20, "waves": [5, -1], "start": [2.0, 11.0], "boss_hp": 520.0, "base_hp": 380.0, "power": 1.6}

enum Phase { MENU, MEADOW_BATTLE, UPGRADES, CAVE_BATTLE }

var _gs: Node
var _phase: Phase = Phase.MENU
var _t: float = 0.0
var _total: float = 0.0
var _battle: Node
var _prefix: String = ""
var _think: float = 0.0
var _mix: Array = []
var _next: int = 0
var _over_at: float = -1.0
var _waves_seen: int = 0
var _bought: int = 0
## Event name → recording time (s), for tools/make_trailer.py.
var _events: Dictionary = {}


## Autoloads are added after _init of a -s script: set up on the first frame.
func _setup() -> void:
	_gs = root.get_node(^"GameState")
	_gs.set(&"autosave", false)
	_gs.call(&"from_dict", {
		"coins": 16450,
		"current_level": 11,
		"biome_unlocked": 2,
		"levels": {"1": 3, "2": 3, "3": 3, "4": 2, "5": 3, "6": 3, "7": 2, "8": 3, "9": 2, "10": 3},
		"units": {
			"zombie": {"unlocked": true, "level": 4},
			"skeleton": {"unlocked": true, "level": 4},
			"slime": {"unlocked": true, "level": 3},
			"spider": {"unlocked": true, "level": 3},
		},
		"upgrades": {"army_power": 8, "food_rate": 8, "base_hp": 4},
		"settings": {"sound": true, "lang": "ru"},
	})
	TranslationServer.set_locale("ru")
	_save_end_card()
	change_scene_to_file.call_deferred("res://scenes/menu/main.tscn")


## The store cover (1920×1080 SVG) as the last frame of the video.
func _save_end_card() -> void:
	var img := Image.new()
	img.load_svg_from_string(FileAccess.get_file_as_string(END_CARD_SVG), 1.0)
	img.save_png("res://build/store/end_card.png")


func _process(delta: float) -> bool:
	_total += delta
	if _total > MAX_TOTAL_SEC:
		push_error("record_trailer: safety stop")
		return _finish()
	if _gs == null:
		_setup()
		return false
	# The recording window may lose focus: that pauses the battle and mutes
	# the sound (Platform) — not wanted in the video.
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
	if _battle != null and _battle.is_inside_tree() and paused:
		_battle.call(&"_close_pause")
	_t += delta
	match _phase:
		Phase.MENU:
			if _t >= MENU_SEC and current_scene != null and current_scene.has_method(&"_open_tab"):
				_start_battle(MEADOW, "m_")
				_next_phase(Phase.MEADOW_BATTLE)
		Phase.MEADOW_BATTLE:
			_direct(delta)
			if _t >= MEADOW_SEC:
				change_scene_to_file.call_deferred("res://scenes/menu/main.tscn")
				_battle = null
				_next_phase(Phase.UPGRADES)
		Phase.UPGRADES:
			_upgrades()
		Phase.CAVE_BATTLE:
			if _direct(delta):
				return _finish()
	return false


func _next_phase(phase: Phase) -> void:
	_phase = phase
	_t = 0.0


func _mark(event: String) -> void:
	if not _events.has(event):
		_events[event] = snappedf(_total, 0.001)


func _finish() -> bool:
	var f := FileAccess.open("res://build/store/events.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_events, "\t"))
	f.close()
	return true


## Upgrades tab: buy the two cave fighters one after another, then fight.
func _upgrades() -> void:
	if current_scene == null or not current_scene.has_method(&"_open_tab"):
		return
	if _t < 0.1:
		return
	if not _events.has("upgrades"):
		current_scene.call(&"_open_tab", 1)
		_mark("upgrades")
	if _bought == 0 and _t >= 1.0:
		_gs.call(&"unlock_unit", &"goblin_miner")
		_bought = 1
		_mark("buy_1")
	elif _bought == 1 and _t >= 1.9:
		_gs.call(&"unlock_unit", &"barrel_bomber")
		_bought = 2
		_mark("buy_2")
	elif _t >= UPGRADES_SEC:
		_start_battle(CAVE, "c_")
		_next_phase(Phase.CAVE_BATTLE)


func _start_battle(spec: Dictionary, prefix: String) -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	_battle = packed.instantiate()
	_battle.set(&"level_override", _demo_level(spec))
	_gs.set(&"selected_level", spec["level"])
	change_scene_to_node.call_deferred(_battle)
	_prefix = prefix
	_mix.clear()
	_next = 0
	_waves_seen = 0
	_over_at = -1.0
	_mark(prefix + "battle")


## A real level cut down to a few waves, with a weaker boss so a battle ends
## in about half a minute.
func _demo_level(spec: Dictionary) -> LevelData:
	var src: LevelData = _gs.call(&"level", spec["level"])
	var level: LevelData = src.duplicate(true)
	var waves: Array[WaveData] = []
	var picks: Array = spec["waves"]
	var starts: Array = spec["start"]
	for i: int in picks.size():
		var index: int = picks[i]
		var w: WaveData = src.waves[index].duplicate(true)
		w.start_sec = starts[i]
		for entry: WaveEntry in w.entries:
			if entry.unit.is_boss:
				var boss: UnitData = entry.unit.duplicate()
				boss.hp = spec["boss_hp"]
				entry.unit = boss
		waves.append(w)
	level.waves = waves
	level.bot_base_hp = spec["base_hp"]
	level.bot_power = spec["power"]
	level.tutorial = false
	return level


## Plays for the player like a quick human: ore, a mix of units, meteor on
## crowds. Also drives the camera and hides the HUD panels. true — done.
func _direct(delta: float) -> bool:
	if _battle == null or not _battle.is_inside_tree():
		return false
	var sim: BattleSim = _battle.get(&"sim")
	if sim == null:
		return false
	if _mix.is_empty():
		_prepare(sim)
	_follow_front(sim, delta)
	var bot: BattleBot = _battle.get(&"bot")
	if bot.current_wave() > _waves_seen:
		_waves_seen = bot.current_wave()
		_mark("%swave_%d" % [_prefix, _waves_seen])
		if bot.is_final_wave(_waves_seen - 1):
			_mark(_prefix + "final")
	if sim.is_over():
		if _over_at < 0.0:
			_over_at = _t
			_mark(_prefix + "over")
		# Result panel appears after result_delay; hold it on screen, then stop.
		return _t - _over_at > 1.2 + RESULT_HOLD_SEC
	_think -= delta
	if _think > 0.0:
		return false
	_think = 0.3
	for i: int in sim.ore_cooldowns.size():
		if sim.ore_cooldowns[i] <= 0.0:
			_battle.call(&"_mine", i)
			break
	var want: UnitData = _mix[_next % _mix.size()]
	if sim.buy_block_reason(want) == &"":
		_battle.call(&"_buy", want)
		_next += 1
	if sim.meteor_charges > 0:
		var front: SimUnit = _front(sim, BattleSim.BOT)
		if front != null:
			var near: int = 0
			for unit: SimUnit in sim.units:
				if unit.side == BattleSim.BOT and unit.is_alive() and absf(unit.x - front.x) <= sim.balance.meteor_radius:
					near += 1
			if near >= 3 or front.data.is_boss:
				_battle.call(&"_cast_meteor", Vector2(front.x + 30.0, sim.balance.lane_y))
				_mark(_prefix + "meteor")
	return false


func _prepare(sim: BattleSim) -> void:
	var u: Dictionary = {}
	for d: UnitData in sim.setup.player_units:
		u[d.id] = d
	_mix = [u[&"zombie"], u[&"skeleton"], u[&"zombie"], u[&"slime"], u[&"skeleton"], u[&"spider"]]
	if u.has(&"goblin_miner"):
		_mix.append(u[&"goblin_miner"])
	if u.has(&"barrel_bomber"):
		_mix.append(u[&"barrel_bomber"])
	sim.food = 16.0
	# Only the field and the banners: no top bar, no bottom panel, no ore
	# (its recharge ring sits at the bottom edge of the close-up; the director
	# still mines it).
	for path: NodePath in [^"HUD/Root/TopBar", ^"HUD/Root/BottomPanel", ^"OreBlocks"]:
		var n: CanvasItem = _battle.get_node(path)
		n.visible = false
	var cam: Camera2D = _battle.get_node(^"Camera")
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.position = Vector2(sim.balance.lane_start_x + 330.0, CAMERA_Y)


## The camera looks at the middle between the two front units.
func _follow_front(sim: BattleSim, delta: float) -> void:
	var cam: Camera2D = _battle.get_node(^"Camera")
	var ours: SimUnit = _front(sim, BattleSim.PLAYER)
	var theirs: SimUnit = _front(sim, BattleSim.BOT)
	var a: float = ours.x if ours != null else sim.balance.lane_start_x + 200.0
	var b: float = theirs.x if theirs != null else a + 400.0
	var half_view: float = 640.0 / ZOOM
	var x: float = clampf((a + b) / 2.0, half_view, 1280.0 - half_view)
	cam.position.x = lerpf(cam.position.x, x, clampf(delta * CAMERA_FOLLOW, 0.0, 1.0))


func _front(sim: BattleSim, side: int) -> SimUnit:
	var best: SimUnit = null
	for unit: SimUnit in sim.units:
		if unit.side == side and unit.is_alive():
			if best == null or unit.x * unit.dir > best.x * best.dir:
				best = unit
	return best
