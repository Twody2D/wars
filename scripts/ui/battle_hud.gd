class_name BattleHud
extends CanvasLayer
## Battle HUD (SPEC 2, 9): top bar, bottom panel with food and unit cards,
## meteor button. Reads BattleSim state every frame; sends player intents up.

signal card_pressed(unit: UnitData)
signal pause_pressed
signal meteor_pressed
## Rewarded booster (SPEC 4): &"boost_speed" or &"boost_food".
signal booster_pressed(tag: StringName)
signal debug_spawn(side: int, unit: UnitData)

@export var card_scene: PackedScene
## Debug buttons that spawn units for both sides (T07). Off in release builds.
@export var show_debug: bool = false

var _cards: Array[UnitCard] = []

@onready var _hp_label: Label = %HpLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _food_label: Label = %FoodLabel
@onready var _food_progress: ProgressBar = %FoodProgress
@onready var _cards_box: HBoxContainer = %Cards
@onready var _meteor_button: TextureButton = %MeteorButton
@onready var _meteor_label: Label = %MeteorLabel
@onready var _meteor_progress: TextureProgressBar = %MeteorProgress
@onready var _targeting_hint: Label = %TargetingHint
@onready var _debug_panel: Control = %DebugPanel
@onready var _pause_button: TextureButton = %PauseButton
@onready var _boost_speed: TextureButton = %BoostSpeed
@onready var _boost_food: TextureButton = %BoostFood
@onready var _boost_speed_label: Label = %BoostSpeedLabel
@onready var _boost_food_label: Label = %BoostFoodLabel

var _boosters: Dictionary[StringName, TextureButton] = {}


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
	_coins_label.text = str(GameState.coins)
	_wave_label.text = tr("WAVE_FMT") % [maxi(bot.current_wave(), 1), bot.wave_count()]
	_food_label.text = "%d/%d" % [floori(sim.food), roundi(sim.food_max)]
	# Progress to the next whole food; full bar when the stock is maxed.
	var full: bool = sim.food >= sim.food_max
	_food_progress.value = 100.0 if full else (sim.food - floorf(sim.food)) * 100.0
	for card: UnitCard in _cards:
		var cd: float = sim.card_cooldowns.get(card.unit.id, 0.0)
		var affordable: bool = sim.food >= card.unit.cost and sim.alive_count(BattleSim.PLAYER) < sim.balance.unit_limit
		card.refresh(sim.buy_block_reason(card.unit), affordable, cd / sim.balance.card_cooldown)
	_meteor_label.text = "%d/%d" % [sim.meteor_charges, sim.balance.meteor_max_charges]
	_meteor_button.disabled = sim.meteor_charges <= 0 or sim.is_over()
	_meteor_button.modulate = Color(0.55, 0.55, 0.55) if _meteor_button.disabled else Color.WHITE
	var charged: bool = sim.meteor_charges >= sim.balance.meteor_max_charges
	_meteor_progress.visible = not charged
	_meteor_progress.value = sim.meteor_timer / sim.balance.meteor_recharge * 100.0


## What the boosters give, from BalanceData (the art has an empty label box).
func set_booster_texts(time_scale: float, food: float) -> void:
	_boost_speed_label.text = "×%s" % String.num(time_scale)
	_boost_food_label.text = "+%d" % roundi(food)


## Boosters work once per battle: a used one stays grey.
func set_booster_available(tag: StringName, available: bool) -> void:
	var b: TextureButton = _boosters.get(tag)
	if b != null:
		b.disabled = not available
		b.modulate = Color.WHITE if available else Color(0.45, 0.45, 0.45, 0.8)


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
