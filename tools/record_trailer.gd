extends SceneTree
## Records the store gameplay video with Movie Maker (frames + sound, no drops):
## menu → upgrades → a short boss battle played by a scripted "director" →
## victory screen. Progress lives in memory only: autosave is off, the real
## save is never touched.
##
## Run (needs a window):
##   "$GODOT" --path . --write-movie build/store/raw.avi --fixed-fps 30 -s res://tools/record_trailer.gd
## (Movie Maker records at the project window size, 1280×720), then:
##   py -3.14 tools/make_trailer.py
## Music is muted here (the editor lays one continuous track over the cuts);
## event times go to build/store/events.json for the editor.

const LEVEL := 10
## Waves of the level kept for the video and when they start (sim seconds).
const WAVES: Array[int] = [0, 3, -1]
const WAVE_START: Array[float] = [3.0, 11.0, 21.0]
const BOT_BASE_HP := 420.0
const BOT_POWER := 1.3
## The boss of the video is weaker so the battle ends in about half a minute.
const BOSS_HP := 380.0
const END_CARD_SVG := "res://design/Art sections 1 and 2 complete/assets/v2/brand/store_cover.svg"
const MENU_SEC := 2.0
const UPGRADES_SEC := 2.6
const RESULT_HOLD_SEC := 3.5
## Safety stop (game seconds after the battle starts).
const MAX_BATTLE_SEC := 110.0
## Safety stop for the whole recording.
const MAX_TOTAL_SEC := 180.0

var _gs: Node
var _phase: int = 0
var _t: float = 0.0
var _battle: Node
var _think: float = 0.0
var _mix: Array = []
var _next: int = 0
var _over_at: float = -1.0
var _total: float = 0.0
## Event name → recording time (s), for tools/make_trailer.py.
var _events: Dictionary = {}
var _waves_seen: int = 0


## Autoloads are added after _init of a -s script: set up on the first frame.
func _setup() -> void:
	_gs = root.get_node(^"GameState")
	_gs.set(&"autosave", false)
	_gs.call(&"from_dict", {
		"coins": 12650,
		"current_level": LEVEL,
		"levels": {"1": 3, "2": 3, "3": 3, "4": 2, "5": 3, "6": 3, "7": 2, "8": 3, "9": 2},
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
		0:
			if _t >= MENU_SEC and current_scene != null and current_scene.has_method(&"_open_tab"):
				current_scene.call(&"_open_tab", 1)
				_mark("upgrades")
				_next_phase()
		1:
			if _t >= UPGRADES_SEC:
				_start_battle()
				_mark("battle")
				_next_phase()
		2:
			if _direct(delta):
				return _finish()
	return false


func _mark(event: String) -> void:
	if not _events.has(event):
		_events[event] = snappedf(_total, 0.001)


func _finish() -> bool:
	var f := FileAccess.open("res://build/store/events.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_events, "	"))
	f.close()
	return true


func _next_phase() -> void:
	_phase += 1
	_t = 0.0


func _start_battle() -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	_battle = packed.instantiate()
	_battle.set(&"level_override", _demo_level())
	_gs.set(&"selected_level", LEVEL)
	change_scene_to_node.call_deferred(_battle)


## Level 10 cut down to three waves (first, a middle one, the boss).
func _demo_level() -> LevelData:
	var src: LevelData = _gs.call(&"level", LEVEL)
	var level: LevelData = src.duplicate(true)
	var waves: Array[WaveData] = []
	for i: int in WAVES.size():
		var w: WaveData = src.waves[WAVES[i]].duplicate(true)
		w.start_sec = WAVE_START[i]
		for entry: WaveEntry in w.entries:
			if entry.unit.is_boss:
				var boss: UnitData = entry.unit.duplicate()
				boss.hp = BOSS_HP
				entry.unit = boss
		waves.append(w)
	level.waves = waves
	level.bot_base_hp = BOT_BASE_HP
	level.bot_power = BOT_POWER
	level.tutorial = false
	return level


## Plays for the player like a quick human: ore, a mix of units, meteor on crowds.
func _direct(delta: float) -> bool:
	if _battle == null or not _battle.is_inside_tree():
		return false
	var sim: BattleSim = _battle.get(&"sim")
	if sim == null:
		return false
	if _mix.is_empty():
		var u: Dictionary = {}
		for d: UnitData in sim.setup.player_units:
			u[d.id] = d
		_mix = [u[&"zombie"], u[&"skeleton"], u[&"zombie"], u[&"slime"], u[&"skeleton"], u[&"spider"]]
		sim.food = 16.0
	var bot: BattleBot = _battle.get(&"bot")
	if bot.current_wave() > _waves_seen:
		_waves_seen = bot.current_wave()
		_mark("wave_%d" % _waves_seen)
	if sim.is_over():
		if _over_at < 0.0:
			_over_at = _t
			_mark("over")
		# Result panel appears after result_delay; hold it on screen, then stop.
		return _t - _over_at > 1.2 + RESULT_HOLD_SEC
	if _t > MAX_BATTLE_SEC:
		return true
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
		var near: int = 0
		var front: SimUnit = null
		for unit: SimUnit in sim.units:
			if unit.side == BattleSim.BOT and unit.is_alive() and (front == null or unit.x < front.x):
				front = unit
		if front != null:
			for unit: SimUnit in sim.units:
				if unit.side == BattleSim.BOT and unit.is_alive() and absf(unit.x - front.x) <= sim.balance.meteor_radius:
					near += 1
			if near >= 3 or front.data.is_boss:
				_battle.call(&"_cast_meteor", Vector2(front.x + 30.0, sim.balance.lane_y))
				_mark("meteor_%d" % sim.meteor_charges)
	return false
