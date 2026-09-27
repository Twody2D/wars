extends SceneTree
## Records the store gameplay video with Movie Maker (frames + sound, no drops).
## The game as the player sees it: the whole field and the HUD, no camera
## zoom, a tap ring on every press so it is clear how it is played. The story:
## a busy meadow battle from the first frame → meteor → the Zombie King →
## victory → new fighters on the upgrades screen → cave battle with goblins,
## bombers and the Stone Golem → victory. A scripted "director" plays at the
## bought ×1.5 battle speed. Progress lives in memory only: autosave is off,
## the real save is never touched.
##
## Run (a window opens for ~1.5 min, do not touch it). Movie Maker takes its
## size from the project settings, not --resolution: a temporary override.cfg
## gives 1920×1080 (delete it afterwards):
##   printf '[display]\nwindow/size/window_width_override=1920\nwindow/size/window_height_override=1080\n' > override.cfg
##   "$GODOT" --path . --write-movie build/store/raw.avi --fixed-fps 30 -s res://tools/record_trailer.gd
##   rm override.cfg
## then:
##   py -3.14 tools/make_trailer.py
## Music is muted here (the editor lays one continuous track over the cuts);
## event times (s of the recording) go to build/store/events.json.

const FPS := 30.0
const UPGRADES_SEC := 4.6
const RESULT_HOLD_SEC := 3.0
const MAX_TOTAL_SEC := 150.0
## The director presses a card this often (s of battle time).
const THINK_SEC := 0.75

## Per battle: level, kept waves, their start (sim s), boss HP, bot base HP,
## bot power, fighters already on the field at the first frame (ours, theirs).
const MEADOW := {
	"level": 10, "waves": [[10, 0], [10, -1]], "start": [1.5, 9.0], "boss_hp": 420.0, "base_hp": 380.0, "power": 1.3,
	"ours": [&"skeleton", &"zombie", &"slime", &"zombie"], "theirs": 3,
}
const CAVE := {
	"level": 11, "waves": [[11, 0], [20, -1]], "start": [1.5, 9.5], "boss_hp": 560.0, "base_hp": 360.0, "power": 1.6,
	"ours": [&"goblin_miner", &"zombie", &"skeleton", &"spider"], "theirs": 3,
}

enum Phase { MEADOW_BATTLE, UPGRADES, CAVE_BATTLE }

var _gs: Node
var _phase: Phase = Phase.MEADOW_BATTLE
## Seconds of the recording (frames / FPS: the battle runs at ×1.5, the video
## does not).
var _total: float = 0.0
var _t: float = 0.0
var _battle: Node
var _prefix: String = ""
var _think: float = 0.0
var _mix: Array = []
var _next: int = 0
var _over_at: float = -1.0
var _waves_seen: int = 0
var _step: int = 0
var _taps: CanvasLayer
var _ring: GradientTexture2D
## Event name → recording time (s), for tools/make_trailer.py.
var _events: Dictionary = {}


## Autoloads are added after _init of a -s script: set up on the first frame.
func _setup() -> void:
	_gs = root.get_node(^"GameState")
	_gs.set(&"autosave", false)
	_gs.call(&"from_dict", {
		"coins": 26450,
		"current_level": 11,
		"biome_unlocked": 2,
		"levels": {"1": 3, "2": 3, "3": 3, "4": 2, "5": 3, "6": 3, "7": 2, "8": 3, "9": 2, "10": 3},
		"units": {
			"zombie": {"unlocked": true, "level": 4},
			"skeleton": {"unlocked": true, "level": 4},
			"slime": {"unlocked": true, "level": 3},
			"spider": {"unlocked": true, "level": 3},
		},
		"upgrades": {"army_power": 8, "food_rate": 8, "base_hp": 4, "battle_speed": 1},
		"battle_speed_on": true,
		"settings": {"sound": true},
	})
	TranslationServer.set_locale("ru")
	_make_tap_layer()
	_start_battle(MEADOW, "m_")


func _process(_delta: float) -> bool:
	var dt: float = 1.0 / FPS
	_total += dt
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
	_t += dt
	match _phase:
		Phase.MEADOW_BATTLE:
			if _direct(dt):
				change_scene_to_file.call_deferred("res://scenes/menu/main.tscn")
				_battle = null
				_next_phase(Phase.UPGRADES)
		Phase.UPGRADES:
			_upgrades()
		Phase.CAVE_BATTLE:
			if _direct(dt):
				return _finish()
	return false


func _next_phase(phase: Phase) -> void:
	_phase = phase
	_t = 0.0
	_step = 0


func _mark(event: String) -> void:
	if not _events.has(event):
		_events[event] = snappedf(_total, 0.001)


func _finish() -> bool:
	var f := FileAccess.open("res://build/store/events.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_events, "\t"))
	f.close()
	return true


# --- tap rings ---------------------------------------------------------------

func _make_tap_layer() -> void:
	_taps = CanvasLayer.new()
	_taps.layer = 100
	root.add_child.call_deferred(_taps)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 0.68, 0.8, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.2), Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0),
	])
	_ring = GradientTexture2D.new()
	_ring.gradient = gradient
	_ring.fill = GradientTexture2D.FILL_RADIAL
	_ring.fill_from = Vector2(0.5, 0.5)
	_ring.fill_to = Vector2(0.5, 0.0)
	_ring.width = 128
	_ring.height = 128


## A white ring that grows and fades where the "finger" pressed (screen
## coordinates of the 1280×720 canvas).
func _tap(at: Vector2) -> void:
	var ring := TextureRect.new()
	ring.texture = _ring
	ring.size = Vector2(128, 128)
	ring.pivot_offset = ring.size / 2.0
	ring.position = at - ring.size / 2.0
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.scale = Vector2(0.35, 0.35)
	_taps.add_child(ring)
	var tween := create_tween().set_parallel()
	tween.tween_property(ring, ^"scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, ^"modulate:a", 0.0, 0.4).set_delay(0.12)
	tween.chain().tween_callback(ring.queue_free)


func _tap_control(c: Control) -> void:
	_tap(c.get_global_rect().get_center())


# --- upgrades ----------------------------------------------------------------

## Upgrades tab: raise the army power twice, open the goblin and the bomber.
func _upgrades() -> void:
	if current_scene == null or not current_scene.has_method(&"_open_tab"):
		return
	var at: Array[float] = [0.05, 0.9, 1.45, 2.3, 3.2, UPGRADES_SEC]
	if _step >= at.size() or _t < at[_step]:
		return
	match _step:
		0:
			current_scene.call(&"_open_tab", 1)
			_mark("upgrades")
		1, 2:
			_press_upgrade(&"army_power")
		3:
			_press_tile(&"goblin_miner")
			_mark("buy_1")
		4:
			_press_tile(&"barrel_bomber")
		5:
			_start_battle(CAVE, "c_")
			_next_phase(Phase.CAVE_BATTLE)
			return
	_step += 1


func _press_upgrade(id: StringName) -> void:
	for card: Node in current_scene.find_children("*", "UpgradeCard", true, false):
		var up: UpgradeData = card.get(&"upgrade")
		if up.id == id:
			var c: Control = card
			_tap_control(c)
			card.call(&"_on_pressed")


func _press_tile(id: StringName) -> void:
	for tile: Node in current_scene.find_children("*", "UnitTile", true, false):
		var unit: UnitData = tile.get(&"unit")
		if unit.id == id:
			var button: Control = tile.get(&"_button")
			_tap_control(button)
			tile.call(&"_on_buy")


# --- battles -----------------------------------------------------------------

func _start_battle(spec: Dictionary, prefix: String) -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	_battle = packed.instantiate()
	_battle.set(&"level_override", _demo_level(spec))
	_battle.set_meta(&"spec", spec)
	_gs.set(&"selected_level", spec["level"])
	change_scene_to_node.call_deferred(_battle)
	_prefix = prefix
	_mix.clear()
	_next = 0
	_think = 0.6
	_waves_seen = 0
	_over_at = -1.0
	_mark(prefix + "battle")


## A real level cut down to two waves, with a weaker boss so a battle ends
## in about 20 s of video.
func _demo_level(spec: Dictionary) -> LevelData:
	var src: LevelData = _gs.call(&"level", spec["level"])
	var level: LevelData = src.duplicate(true)
	level.number = spec["level"]
	var waves: Array[WaveData] = []
	var picks: Array = spec["waves"]
	var starts: Array = spec["start"]
	for i: int in picks.size():
		var pick: Array = picks[i]
		var from: LevelData = _gs.call(&"level", pick[0])
		var index: int = pick[1]
		var w: WaveData = from.waves[index].duplicate(true)
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


## Plays for the player like a quick human: cards, ore, the meteor on crowds —
## each press with a tap ring. true — the result has been on screen long enough.
func _direct(dt: float) -> bool:
	if _battle == null or not _battle.is_inside_tree():
		return false
	var sim: BattleSim = _battle.get(&"sim")
	if sim == null:
		return false
	if _mix.is_empty():
		_prepare(sim)
	var bot: BattleBot = _battle.get(&"bot")
	if bot.current_wave() > _waves_seen:
		_waves_seen = bot.current_wave()
		_mark("%swave_%d" % [_prefix, _waves_seen])
		if bot.is_final_wave(_waves_seen - 1):
			_mark(_prefix + "final")
	if bot.is_broken():
		_mark(_prefix + "broken")
	if sim.is_over():
		if _over_at < 0.0:
			_over_at = _t
			_mark(_prefix + "over")
		# Result panel appears after result_delay; hold it on screen, then stop.
		return _t - _over_at > 1.2 + RESULT_HOLD_SEC
	_think -= dt * Engine.time_scale
	if _think > 0.0:
		return false
	_think = THINK_SEC
	if _cast_meteor(sim):
		return false
	var hud: Object = _battle.get(&"_hud")
	for i: int in sim.ore_cooldowns.size():
		if sim.ore_cooldowns[i] <= 0.0 and sim.food < 6.0:
			var ores: Array = _battle.call(&"_ore_list")
			var ore: Control = ores[i]
			_tap_control(ore)
			_battle.call(&"_mine", i)
			return false
	var want: UnitData = _mix[_next % _mix.size()]
	# A little help so the army keeps coming.
	sim.food = maxf(sim.food, want.cost + 12.0)
	if sim.buy_block_reason(want) == &"":
		var count: int = hud.call(&"card_count")
		for i: int in count:
			if hud.call(&"card_unit", i) == want:
				var rect: Rect2 = hud.call(&"card_rect", i)
				_tap(rect.get_center())
		_battle.call(&"_buy", want)
		_next += 1
	return false


## Meteor on a crowd of three or on the boss: press the button, then the spot.
func _cast_meteor(sim: BattleSim) -> bool:
	if sim.meteor_charges <= 0:
		return false
	var front: SimUnit = _front(sim, BattleSim.BOT)
	if front == null:
		return false
	var near: int = 0
	for unit: SimUnit in sim.units:
		if unit.side == BattleSim.BOT and unit.is_alive() and absf(unit.x - front.x) <= sim.balance.meteor_radius:
			near += 1
	if near < 3 and not front.data.is_boss:
		return false
	var hud: Object = _battle.get(&"_hud")
	var button: Rect2 = hud.call(&"meteor_rect")
	_tap(button.get_center())
	var target := Vector2(front.x + 30.0, sim.balance.lane_y)
	var screen: Vector2 = _battle.get_viewport().get_canvas_transform() * target
	create_timer(0.25).timeout.connect(func() -> void:
		if _battle != null and _battle.is_inside_tree():
			_tap(screen)
			_battle.call(&"_cast_meteor", target))
	_mark(_prefix + "meteor")
	return true


## The battle starts in the middle of a fight: both armies are already on the
## field, no level banner.
func _prepare(sim: BattleSim) -> void:
	var spec: Dictionary = _battle.get_meta(&"spec")
	var u: Dictionary = {}
	for d: UnitData in sim.setup.player_units:
		u[d.id] = d
	_mix = [u[&"zombie"], u[&"skeleton"], u[&"slime"], u[&"zombie"], u[&"spider"], u[&"skeleton"]]
	if u.has(&"goblin_miner"):
		_mix.insert(1, u[&"goblin_miner"])
	if u.has(&"barrel_bomber"):
		_mix.insert(4, u[&"barrel_bomber"])
	sim.food = 10.0
	_battle.set(&"_announced_waves", 1)
	var b: BalanceData = sim.balance
	var ours: Array = spec["ours"]
	for i: int in ours.size():
		var d: UnitData = u[ours[i]]
		var unit: SimUnit = sim.spawn(BattleSim.PLAYER, d, sim.setup.level_of(d), sim.setup.player_power)
		unit.x = b.lane_start_x + 250.0 - i * 55.0
	var level: LevelData = _battle.get(&"level")
	var first: WaveData = level.waves[0]
	var theirs: int = spec["theirs"]
	for i: int in theirs:
		var entry: WaveEntry = first.entries[i % first.entries.size()]
		var unit: SimUnit = sim.spawn(BattleSim.BOT, entry.unit, 1, level.bot_power)
		unit.x = b.lane_end_x - 300.0 + i * 60.0


func _front(sim: BattleSim, side: int) -> SimUnit:
	var best: SimUnit = null
	for unit: SimUnit in sim.units:
		if unit.side == side and unit.is_alive():
			if best == null or unit.x * unit.dir > best.x * best.dir:
				best = unit
	return best
