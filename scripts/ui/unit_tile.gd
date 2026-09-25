class_name UnitTile
extends PanelContainer
## Unit on the upgrades screen: portrait, name, level, unlock / level-up button.

var unit: UnitData

@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %Name
@onready var _level: Label = %Level
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
	var unlocked: bool = GameState.is_unit_unlocked(unit.id)
	_portrait.modulate = Color.WHITE if unlocked else Color(0.25, 0.25, 0.3)
	if unlocked:
		var lvl: int = GameState.unit_level(unit.id)
		_level.text = tr("UPGRADE_LEVEL_FMT") % [lvl, GameState.balance().unit_max_level]
		var cost: int = GameState.unit_level_cost(unit.id)
		_button.text = tr("MAX") if cost < 0 else "%s %d" % [tr("BTN_LEVEL_UP"), cost]
		_button.disabled = cost < 0 or GameState.coins < cost
	else:
		var cost: int = GameState.unit_unlock_cost(unit.id)
		_level.text = ""
		_button.text = tr("UNLOCKS_IN_CAVE") if cost < 0 else "%s %d" % [tr("BTN_UNLOCK"), cost]
		_button.disabled = cost < 0 or GameState.coins < cost


func _on_buy() -> void:
	if GameState.is_unit_unlocked(unit.id):
		GameState.level_up_unit(unit.id)
	else:
		GameState.unlock_unit(unit.id)
