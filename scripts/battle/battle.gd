class_name Battle
extends Node2D
## Battle scene controller (SPEC 2–6, T07–T10).
## Owns BattleSim + BattleBot, steps them with a fixed dt, and keeps pooled
## views (units, projectiles, effects) in sync. No instantiate()/queue_free()
## during the fight: everything is prewarmed in _ready().

const MENU_SCENE := "res://scenes/menu/main.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
## Rewarded ad tags of the boosters (also the Platform.show_rewarded tag).
const BOOSTERS: Array[StringName] = [&"boost_speed", &"boost_food"]

## Play this level instead of GameState.selected_level (handy for F6 in the editor).
@export var level_override: LevelData
## Unit views prewarmed per unit type per side.
@export var pool_per_type: int = 6
@export var projectile_textures: Dictionary[StringName, Texture2D] = {}
@export var biome_backgrounds: Dictionary[StringName, Texture2D] = {}
@export var biome_bases: Dictionary[StringName, Array] = {}
@export var result_delay: float = 1.2
@export var projectile_height: float = 50.0
## Where the meteor rock starts relative to the target.
@export var meteor_fall_from: Vector2 = Vector2(260, -520)

var sim: BattleSim
var bot: BattleBot
var level: LevelData
var balance: BalanceData
var targeting_meteor: bool = false

var _views: Dictionary[int, UnitVisual] = {}
var _pool: Dictionary[StringName, Array] = {}
var _projectile_views: Dictionary[int, Sprite2D] = {}
var _projectile_pool: Array[Sprite2D] = []
var _last_base_hp: Array[float] = [0.0, 0.0]
var _result: BattleResult
var _time_scale_before: float = 1.0
## Rewarded boosters used in this battle (one each, SPEC 4).
var _boosts_used: Dictionary[StringName, bool] = {}
## Our own rewarded ad is on screen: the SDK pause must not open the pause menu.
var _ad_running: bool = false

@onready var _background: Sprite2D = $Background
@onready var _units_layer: Node2D = $Units
@onready var _projectiles_layer: Node2D = $Projectiles
@onready var _effects: EffectLayer = $Effects
@onready var _player_base: BaseView = $PlayerBase
@onready var _bot_base: BaseView = $BotBase
@onready var _ore_blocks: Node2D = $OreBlocks
@onready var _reticle: MeteorReticle = $MeteorReticle
@onready var _meteor_rock: Sprite2D = $MeteorRock
@onready var _hud: BattleHud = $HUD
@onready var _pause: PausePanel = $Overlay/Pause
@onready var _result_panel: ResultPanel = $Overlay/Result
@onready var _tutorial: TutorialHints = $Overlay/Tutorial


func _ready() -> void:
	balance = GameState.balance()
	level = level_override if level_override != null else GameState.level(GameState.selected_level)
	sim = BattleSim.new(GameState.make_setup(level))
	bot = BattleBot.new(sim)
	_apply_biome()
	_prewarm()
	_connect_sim()

	var debug_units: Array[UnitData] = GameState.config.player_units.duplicate()
	_hud.setup(sim.setup.player_units, sim.setup.unit_levels, debug_units)
	_hud.card_pressed.connect(_buy)
	_hud.pause_pressed.connect(_open_pause)
	_hud.meteor_pressed.connect(_toggle_meteor_targeting)
	_hud.booster_pressed.connect(_request_booster)
	Platform.rewarded.connect(_on_booster_rewarded)
	Platform.rewarded_failed.connect(_on_booster_failed)
	_hud.debug_spawn.connect(func(side: int, u: UnitData) -> void: sim.spawn(side, u))
	_pause.resume_pressed.connect(_close_pause)
	_pause.menu_pressed.connect(_go_menu)
	_pause.restart_pressed.connect(_restart)
	_result_panel.next_pressed.connect(_next_level)
	_result_panel.menu_pressed.connect(_go_menu)

	for ore: OreBlock in _ore_list():
		ore.visible = ore.index < sim.ore_cooldowns.size()
		ore.mined.connect(_mine)
	_reticle.visible = false
	_reticle.radius = balance.meteor_radius
	_last_base_hp = sim.base_hp.duplicate()
	_player_base.set_star_marks(balance.three_stars_hp, balance.two_stars_hp)
	_update_bases()
	_tutorial.setup(self, level.tutorial)

	_time_scale_before = Engine.time_scale
	Engine.time_scale = balance.battle_speed_scale if GameState.battle_speed_on else 1.0
	Platform.update_mute()
	Audio.play_music(&"battle")
	Platform.paused.connect(_on_platform_paused)
	Platform.gameplay_start()


func _exit_tree() -> void:
	Engine.time_scale = _time_scale_before
	get_tree().paused = false


func _process(delta: float) -> void:
	if not sim.is_over():
		_step(delta)
	_sync_units()
	_sync_projectiles(delta)
	_sync_ore()
	_hud.refresh(sim, bot)
	if targeting_meteor:
		_reticle.global_position = get_global_mouse_position()


var _accumulator: float = 0.0


func _step(delta: float) -> void:
	_accumulator += delta * balance.battle_pace
	var dt: float = balance.sim_dt
	while _accumulator >= dt and not sim.is_over():
		_accumulator -= dt
		bot.step(dt)
		sim.step(dt)


# --- player input ----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if sim.is_over():
		return
	if event.is_action_pressed(&"pause"):
		if targeting_meteor:
			_set_targeting(false)
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"meteor"):
		_toggle_meteor_targeting()
		get_viewport().set_input_as_handled()
		return
	for i: int in _hud.card_count():
		if event.is_action_pressed(StringName("card_%d" % (i + 1))):
			_buy(_hud.card_unit(i))
			get_viewport().set_input_as_handled()
			return
	if targeting_meteor and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_set_targeting(false)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			_cast_meteor(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func _buy(unit: UnitData) -> void:
	if unit != null and sim.buy(unit) != null:
		_tutorial.notify(&"bought")


func _mine(index: int) -> void:
	if sim.tap_ore(index):
		var ore: OreBlock = _ore_list()[index]
		ore.punch()
		Audio.play_sfx(&"ore")
		_effects.spawn(&"coin", ore.position + ore.size / 2.0 - Vector2(0, 20), 0.8)
		_tutorial.notify(&"ore")


func _toggle_meteor_targeting() -> void:
	_set_targeting(not targeting_meteor and sim.meteor_charges > 0)


func _set_targeting(on: bool) -> void:
	targeting_meteor = on
	_reticle.visible = on
	_hud.set_targeting(on)


func _cast_meteor(at: Vector2) -> void:
	# Only the field counts: not the HUD strips at the top and bottom.
	if at.y < 60.0 or at.y > 560.0:
		return
	if sim.cast_meteor(at):
		_tutorial.notify(&"meteor")
	_set_targeting(false)


# --- sim → views -----------------------------------------------------------

func _connect_sim() -> void:
	sim.unit_spawned.connect(_on_unit_spawned)
	sim.unit_attack_started.connect(func(u: SimUnit) -> void:
		var v: UnitVisual = _views.get(u.uid)
		if v != null:
			v.play(v.attack_anim))
	sim.unit_damaged.connect(_on_unit_damaged)
	sim.unit_died.connect(_on_unit_died)
	sim.projectile_spawned.connect(_on_projectile_spawned)
	sim.projectile_finished.connect(_on_projectile_finished)
	sim.explosion.connect(func(x: float, radius: float, _side: int) -> void:
		Audio.play_sfx(&"explosion")
		_effects.spawn(&"explosion", Vector2(x, balance.lane_y - 20.0), radius / 40.0))
	sim.meteor_cast.connect(_on_meteor_cast)
	sim.meteor_impact.connect(func(at: Vector2) -> void:
		Audio.play_sfx(&"explosion")
		_effects.spawn(&"meteor", at, balance.meteor_radius / 40.0)
		_effects.spawn(&"explosion", at, balance.meteor_radius / 45.0))
	sim.base_damaged.connect(_on_base_damaged)
	sim.battle_over.connect(_on_battle_over)


## A rock falls from the upper right onto the target during meteor_fall_time.
func _on_meteor_cast(at: Vector2) -> void:
	Audio.play_sfx(&"meteor", false)
	var rock := _meteor_rock
	rock.visible = true
	rock.position = at + meteor_fall_from
	rock.rotation = 0.0
	var fall: float = balance.meteor_fall_time / balance.battle_pace
	var tween := create_tween().set_parallel()
	tween.tween_property(rock, "position", at, fall).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(rock, "rotation", -TAU, fall)
	tween.chain().tween_callback(func() -> void: rock.visible = false)


func _on_unit_spawned(u: SimUnit) -> void:
	var v: UnitVisual = _acquire(u.data)
	v.team_color = balance.player_color if u.side == BattleSim.PLAYER else balance.bot_color
	v.facing_left = u.side == BattleSim.BOT
	v.size_scale = balance.unit_scale
	v.pace = balance.battle_pace
	v.position = Vector2(u.x, balance.lane_y + u.y_offset)
	v.visible = true
	v.reset_pose()
	v.set_hp(1.0, v.team_color)
	v.play(&"walk")
	_views[u.uid] = v
	if u.side == BattleSim.PLAYER:
		Audio.play_sfx(&"spawn")


func _on_unit_damaged(u: SimUnit, _amount: float) -> void:
	var v: UnitVisual = _views.get(u.uid)
	if v == null:
		return
	v.set_hp(u.hp / u.max_hp if u.is_alive() else -1.0, v.team_color)
	if u.is_alive():
		v.play_hit()
		Audio.play_sfx(&"hit")
	_effects.spawn(&"hit", v.position + Vector2(0, v.top_offset() * 0.5), 0.8)


func _on_unit_died(u: SimUnit, _killed: bool) -> void:
	var v: UnitVisual = _views.get(u.uid)
	if v == null:
		return
	_views.erase(u.uid)
	v.play(&"die")
	Audio.play_sfx(&"death")


func _sync_units() -> void:
	for u: SimUnit in sim.units:
		var v: UnitVisual = _views.get(u.uid)
		if v == null:
			continue
		v.position = Vector2(u.x, balance.lane_y + u.y_offset)
		if v.is_busy():
			continue
		v.play(&"walk" if u.state == SimUnit.State.WALK and not sim.is_over() else &"idle")


func _on_projectile_spawned(p: SimProjectile) -> void:
	if _projectile_pool.is_empty():
		return
	var s: Sprite2D = _projectile_pool.pop_back()
	s.texture = projectile_textures.get(p.kind)
	s.flip_h = p.side == BattleSim.BOT
	s.rotation = 0.0
	s.visible = true
	_projectile_views[p.uid] = s
	Audio.play_sfx(&"shoot")


func _on_projectile_finished(p: SimProjectile) -> void:
	var s: Sprite2D = _projectile_views.get(p.uid)
	if s == null:
		return
	_projectile_views.erase(p.uid)
	s.visible = false
	_projectile_pool.append(s)


func _sync_projectiles(delta: float) -> void:
	for p: SimProjectile in sim.projectiles:
		var s: Sprite2D = _projectile_views.get(p.uid)
		if s == null:
			continue
		var t: float = p.progress()
		var arc: float = balance.projectile_arc * sin(PI * t)
		s.position = Vector2(p.x, balance.lane_y + p.y_offset - projectile_height - arc)
		if p.kind == &"pickaxe":
			s.rotation += 14.0 * delta * (-1.0 if s.flip_h else 1.0)
		else:
			var dx: float = (p.target_x - p.start_x) / p.duration
			var dy: float = -balance.projectile_arc * PI * cos(PI * t) / p.duration
			s.rotation = atan2(dy, dx) - (PI if s.flip_h else 0.0)


func _on_base_damaged(side: int, _amount: float) -> void:
	var view: BaseView = _player_base if side == BattleSim.PLAYER else _bot_base
	view.hit()
	Audio.play_sfx(&"hit")
	_update_bases()


func _update_bases() -> void:
	_player_base.set_hp(sim.base_hp[BattleSim.PLAYER], sim.base_max_hp[BattleSim.PLAYER])
	_bot_base.set_hp(sim.base_hp[BattleSim.BOT], sim.base_max_hp[BattleSim.BOT])


func _sync_ore() -> void:
	var ores: Array[OreBlock] = _ore_list()
	for i: int in sim.ore_cooldowns.size():
		if i < ores.size():
			ores[i].set_cooldown(sim.ore_cooldowns[i] / balance.ore_cooldown)


# --- end of battle -----------------------------------------------------------

func _on_battle_over(winner: int) -> void:
	_set_targeting(false)
	for tag: StringName in BOOSTERS:
		_hud.set_booster_available(tag, false)
	Audio.stop_music()
	Audio.play_sfx(&"win" if winner == BattleSim.PLAYER else &"lose", false)
	_update_bases()
	_result = Rewards.calculate(sim)
	GameState.apply_result(_result)
	Platform.gameplay_stop()
	await get_tree().create_timer(result_delay).timeout
	_result_panel.show_result(_result)


func _next_level() -> void:
	if _result != null and _result.won:
		GameState.selected_level = mini(_result.level_number + 1, GameState.level_count())
	_leave(BATTLE_SCENE)


## Replay the same level from scratch (pause menu). Nothing is saved.
func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_menu() -> void:
	_leave(MENU_SCENE)


func _leave(scene: String) -> void:
	# The ad pauses the platform; this battle is going away and must not react.
	if Platform.paused.is_connected(_on_platform_paused):
		Platform.paused.disconnect(_on_platform_paused)
	get_tree().paused = false
	Platform.show_interstitial()
	get_tree().change_scene_to_file(scene)


func _open_pause() -> void:
	if sim.is_over():
		return
	get_tree().paused = true
	Platform.gameplay_stop()
	_pause.open()


func _close_pause() -> void:
	_pause.visible = false
	get_tree().paused = false
	Platform.gameplay_start()


func _on_platform_paused() -> void:
	if _ad_running:
		return
	if not get_tree().paused:
		_open_pause()


# --- rewarded boosters (SPEC 4) -------------------------------------------------

## Watch an ad → the battle is paused while it is on screen → reward on success.
func _request_booster(tag: StringName) -> void:
	if _ad_running or _boosts_used.get(tag, false) or sim.is_over():
		return
	_ad_running = true
	_set_targeting(false)
	get_tree().paused = true
	Platform.gameplay_stop()
	Platform.show_rewarded(tag)


func _on_booster_rewarded(tag: StringName) -> void:
	if not _ad_running or not tag in BOOSTERS:
		return
	_boosts_used[tag] = true
	_hud.set_booster_available(tag, false)
	if tag == &"boost_speed":
		Engine.time_scale = maxf(Engine.time_scale, balance.booster_time_scale)
	else:
		sim.add_food(balance.booster_food)
	Audio.play_sfx(&"coin", false)
	_end_booster_ad()


func _on_booster_failed(tag: StringName) -> void:
	if _ad_running and tag in BOOSTERS:
		_end_booster_ad()


func _end_booster_ad() -> void:
	_ad_running = false
	get_tree().paused = false
	Platform.gameplay_start()


# --- setup -------------------------------------------------------------------

func _apply_biome() -> void:
	var bg: Texture2D = biome_backgrounds.get(level.biome)
	if bg != null:
		_background.texture = bg
	var bases: Array = biome_bases.get(level.biome, [])
	if bases.size() == 3:
		for view: BaseView in [_player_base, _bot_base]:
			view.intact = bases[0]
			view.damaged = bases[1]
			view.destroyed = bases[2]


func _prewarm() -> void:
	var types: Array[UnitData] = []
	for u: UnitData in sim.setup.player_units:
		types.append(u)
	for u: UnitData in level.bot_units:
		if u not in types:
			types.append(u)
	for wave: WaveData in level.waves:
		for e: WaveEntry in wave.entries:
			if e.unit not in types:
				types.append(e.unit)
	for u: UnitData in types:
		var count: int = 1 if u.is_boss else pool_per_type * 2
		for i: int in count:
			_release(_create_view(u))
	for i: int in 24:
		var s := Sprite2D.new()
		s.visible = false
		_projectiles_layer.add_child(s)
		_projectile_pool.append(s)


func _create_view(u: UnitData) -> UnitVisual:
	var v: UnitVisual = u.visual.instantiate()
	v.set_meta(&"unit_id", u.id)
	_units_layer.add_child(v)
	v.die_finished.connect(_release.bind(v))
	v.poof_requested.connect(func(at: Vector2) -> void: _effects.spawn(&"poof", at, 0.8))
	return v


func _acquire(u: UnitData) -> UnitVisual:
	var free: Array = _pool.get(u.id, [])
	if free.is_empty():
		push_warning("Battle: pool for %s exhausted, growing" % u.id)
		return _create_view(u)
	var v: UnitVisual = free.pop_back()
	return v


func _release(v: UnitVisual) -> void:
	v.visible = false
	var id: StringName = v.get_meta(&"unit_id")
	if not _pool.has(id):
		_pool[id] = []
	var free: Array = _pool[id]
	free.append(v)


func _ore_list() -> Array[OreBlock]:
	var result: Array[OreBlock] = []
	for child: Node in _ore_blocks.get_children():
		if child is OreBlock:
			result.append(child)
	return result
