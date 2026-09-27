class_name BattleHud
extends CanvasLayer
## Battle HUD (SPEC 2, 9; battle v3 kit): top counters and wave plate, bottom
## panel with food, unit cards, ad boosters and the meteor button. Reads BattleSim state every frame; sends player intents up.

signal card_pressed(unit: UnitData)
signal pause_pressed
signal meteor_pressed
## Rewarded booster (SPEC 4): &"boost_speed" or &"boost_food".
signal booster_pressed(tag: StringName)
signal debug_spawn(side: int, unit: UnitData)

const WAVE_PLATE_PADDING := 62.0

@export var card_scene: PackedScene
## Debug buttons that spawn units for both sides (T07). Off in release builds.
@export var show_debug: bool = false
## Coins flying from killed enemies to the counter.
@export var coin_texture: Texture2D
@export var coin_size: float = 40.0
@export var coin_pop_px: float = 40.0
@export var coin_pop_time: float = 0.25
@export var coin_fly_time: float = 0.55
@export var coin_pool_size: int = 16

var _cards: Array[UnitCard] = []

@onready var _hp_label: Label = %HpLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _coin_icon: TextureRect = %CoinIcon
@onready var _flying_coins: Control = %FlyingCoins
@onready var _wave_label: Label = %WaveLabel
@onready var _wave_panel: Control = %WavePanel
@onready var _wave_min_width: float = _wave_panel.size.x
@onready var _food_label: Label = %FoodLabel
@onready var _food_progress: Control = %FoodProgress
@onready var _food_full_width: float = _food_progress.size.x
@onready var _cards_box: HBoxContainer = %Cards
@onready var _meteor_button: TextureButton = %MeteorButton
@onready var _meteor_label: Label = %MeteorLabel
@onready var _meteor_progress: TextureProgressBar = %MeteorProgress
@onready var _meteor_glow: Control = %Glow
@onready var _meteor_icon: Control = %Icon
@onready var _targeting_hint: Label = %TargetingHint
@onready var _debug_panel: Control = %DebugPanel
@onready var _pause_button: Button = %PauseButton
@onready var _boost_speed: Button = %BoostSpeed
@onready var _boost_food: Button = %BoostFood
@onready var _boost_speed_label: Label = %BoostSpeedLabel
@onready var _boost_food_label: Label = %BoostFoodLabel

var _boosters: Dictionary[StringName, Button] = {}
## Coins earned in this battle so far (shown next to the coin icon).
var _earned: int = 0
var _coin_pool: Array[TextureRect] = []
var _pulse: Tween
var _glow_tween: Tween


func _ready() -> void:
	_pause_button.pressed.connect(pause_pressed.emit)
	_meteor_button.pressed.connect(meteor_pressed.emit)
	_boosters = {&"boost_speed": _boost_speed, &"boost_food": _boost_food}
	for tag: StringName in _boosters:
		_boosters[tag].pressed.connect(booster_pressed.emit.bind(tag))
	_targeting_hint.visible = false
	_debug_panel.visible = show_debug and OS.is_debug_build()


func setup(units: Array[UnitData], unit_levels: Dictionary[StringName, int], debug_units: Array[UnitData]) -> void:
	var show_keys: bool = not DisplayServer.is_touchscreen_available()
	for i: int in units.size():
		var card: UnitCard = card_scene.instantiate()
		_cards_box.add_child(card)
		var lvl: int = unit_levels.get(units[i].id, 1)
		card.setup(units[i], i + 1, lvl, show_keys)
		card.buy_requested.connect(card_pressed.emit)
		_cards.append(card)
	if _debug_panel.visible:
		_build_debug(debug_units)


func refresh(sim: BattleSim, bot: BattleBot) -> void:
	_hp_label.text = str(ceili(sim.base_hp[BattleSim.PLAYER]))
	var wave_text: String = tr("LEVEL_WAVE_FMT") % [sim.setup.level.number, maxi(bot.current_wave(), 1), bot.wave_count()]
	if wave_text != _wave_label.text:
		_wave_label.text = wave_text
		# The plate stretches with the text (flag socket 50 px + right edge 12 px).
		var w: float = maxf(_wave_min_width, _wave_label.get_minimum_size().x + WAVE_PLATE_PADDING)
		_wave_panel.offset_left = -w / 2.0
		_wave_panel.offset_right = w / 2.0
	_food_label.text = "%d/%d" % [floori(sim.food), roundi(sim.food_max)]
	# Progress to the next whole food; full bar when the stock is maxed.
	var full: bool = sim.food >= sim.food_max
	var part: float = 1.0 if full else sim.food - floorf(sim.food)
	_food_progress.size.x = maxf(_food_progress.size.y, _food_full_width * part)
	for card: UnitCard in _cards:
		var cd: float = sim.card_cooldowns.get(card.unit.id, 0.0)
		var affordable: bool = sim.food >= card.unit.cost and sim.alive_count(BattleSim.PLAYER) < sim.balance.unit_limit
		card.refresh(sim.buy_block_reason(card.unit), affordable, cd / sim.balance.card_cooldown)
	_meteor_label.text = "%d/%d" % [sim.meteor_charges, sim.balance.meteor_max_charges]
	_meteor_button.disabled = sim.meteor_charges <= 0 or sim.is_over()
	_meteor_icon.modulate.a = 0.5 if _meteor_button.disabled else 1.0
	_set_meteor_glow(not _meteor_button.disabled)
	var charged: bool = sim.meteor_charges >= sim.balance.meteor_max_charges
	_meteor_progress.visible = not charged
	_meteor_progress.value = sim.meteor_timer / sim.balance.meteor_recharge * 100.0


## A ready meteor glows and pulses behind the button.
func _set_meteor_glow(on: bool) -> void:
	_meteor_glow.visible = on
	if on and (_glow_tween == null or not _glow_tween.is_valid()):
		_glow_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		_glow_tween.tween_property(_meteor_glow, "modulate:a", 0.6, 0.8)
		_glow_tween.tween_property(_meteor_glow, "modulate:a", 1.0, 0.8)
	elif not on and _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()


## Pool of coin sprites, created once before the battle (no instantiate in battle).
func prewarm_coins() -> void:
	_coins_label.text = "0"
	for i: int in coin_pool_size:
		var c := TextureRect.new()
		c.texture = coin_texture
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.size = Vector2(coin_size, coin_size)
		c.pivot_offset = c.size / 2.0
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.visible = false
		_flying_coins.add_child(c)
		_coin_pool.append(c)


## A coin pops out at `from` (screen position), flies to the counter and adds
## `amount` there when it arrives.
func fly_coin(from: Vector2, amount: int) -> void:
	if _coin_pool.is_empty():
		_add_earned(amount)
		return
	var c: TextureRect = _coin_pool.pop_back()
	c.visible = true
	c.scale = Vector2.ONE
	c.position = from - c.size / 2.0
	var target: Vector2 = _coin_icon.get_global_rect().get_center() - c.size / 2.0
	var tween := c.create_tween()
	tween.tween_property(c, "position:y", c.position.y - coin_pop_px, coin_pop_time) 		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(c, "position", target, coin_fly_time) 		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(c, "scale", Vector2(0.7, 0.7), coin_fly_time)
	tween.tween_callback(func() -> void:
		c.visible = false
		_coin_pool.append(c)
		_add_earned(amount))


func _add_earned(amount: int) -> void:
	_earned += amount
	_coins_label.text = str(_earned)
	Audio.play_sfx(&"coin")
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_coin_icon.pivot_offset = _coin_icon.size / 2.0
	_coin_icon.scale = Vector2(1.35, 1.35)
	_pulse = _coin_icon.create_tween()
	_pulse.tween_property(_coin_icon, "scale", Vector2.ONE, 0.2)


## What the boosters give, from BalanceData (the art has an empty label box).
func set_booster_texts(time_scale: float, food: float) -> void:
	var whole: bool = is_equal_approx(time_scale, roundf(time_scale))
	_boost_speed_label.text = ("×%d" % roundi(time_scale)) if whole else ("×%.1f" % time_scale)
	_boost_food_label.text = "+%d" % roundi(food)


## Boosters work once per battle: a used one stays grey, without the ad badge.
func set_booster_available(tag: StringName, available: bool) -> void:
	var b: Button = _boosters.get(tag)
	if b != null:
		b.disabled = not available
		(b.get_node(^"AdBadge") as CanvasItem).visible = available
		(b.get_node(^"Icon") as CanvasItem).modulate.a = 1.0 if available else 0.45


func set_targeting(on: bool) -> void:
	_targeting_hint.visible = on


func card_count() -> int:
	return _cards.size()


func card_unit(index: int) -> UnitData:
	return _cards[index].unit if index < _cards.size() else null


func card_rect(index: int) -> Rect2:
	return _cards[index].get_global_rect() if index < _cards.size() else Rect2()


func meteor_rect() -> Rect2:
	return _meteor_button.get_global_rect()


func _build_debug(units: Array[UnitData]) -> void:
	for side: int in 2:
		var row := HBoxContainer.new()
		_debug_panel.add_child(row)
		var title := Label.new()
		title.text = "P1" if side == BattleSim.PLAYER else "BOT"
		row.add_child(title)
		for u: UnitData in units:
			var b := Button.new()
			b.text = String(u.id).left(6)
			b.theme_type_variation = &"DebugButton"
			b.pressed.connect(func() -> void: debug_spawn.emit(side, u))
			row.add_child(b)
