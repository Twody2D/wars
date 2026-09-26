class_name UnitTile
extends PanelContainer
## Unit on the upgrades screen: portrait in a sky window, name, level pips, one
## green price button (unlock or next level). Locked units sit on a grey card.

@export var coin_icon: Texture2D

var unit: UnitData

@onready var _window: PanelContainer = %Window
@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %Name
@onready var _pips: LevelPips = %Pips
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_button.pressed.connect(_on_buy)
	GameState.changed.connect(refresh)


func setup(unit_: UnitData) -> void:
	unit = unit_
	_portrait.texture = unit.portrait
	_name.text = tr(unit.name_key)
	refresh()


func refresh() -> void:
	if unit == null:
		return
	# Only the biomes the player has reached (SPEC 7: later units after Evolution).
	visible = unit.unlock_biome <= GameState.biome_unlocked
	var unlocked: bool = GameState.is_unit_unlocked(unit.id)
	theme_type_variation = &"CardPanel" if unlocked else &"LockedCard"
	_window.theme_type_variation = &"PortraitWindow" if unlocked else &"PortraitLocked"
	_portrait.modulate = Color.WHITE if unlocked else Color(0.35, 0.35, 0.42)
	var max_level: int = GameState.balance().unit_max_level
	_pips.set_level(GameState.unit_level(unit.id) if unlocked else 0, max_level)
	var cost: int = GameState.unit_level_cost(unit.id) if unlocked else GameState.unit_unlock_cost(unit.id)
	if cost < 0:
		# Maxed out, or unlocks only in a later biome.
		_button.icon = null
		_button.text = tr("MAX") if unlocked else tr("UNLOCKS_IN_CAVE")
		_button.disabled = true
	else:
		_button.icon = coin_icon
		_button.text = str(cost)
		_button.disabled = GameState.coins < cost


func _on_buy() -> void:
	if GameState.is_unit_unlocked(unit.id):
		GameState.level_up_unit(unit.id)
	else:
		GameState.unlock_unit(unit.id)
