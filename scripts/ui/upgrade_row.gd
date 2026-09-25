class_name UpgradeRow
extends PanelContainer
## One meta upgrade on the upgrades screen (SPEC 7).

var upgrade: UpgradeData

@onready var _name: Label = %Name
@onready var _desc: Label = %Desc
@onready var _level: Label = %Level
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	GameState.changed.connect(refresh)


func setup(upgrade_: UpgradeData) -> void:
	upgrade = upgrade_
	_name.text = tr(upgrade.name_key)
	_desc.text = tr("DESC_" + String(upgrade.id).to_upper())
	refresh()


func refresh() -> void:
	if upgrade == null:
		return
	var lvl: int = GameState.upgrade_level(upgrade.id)
	var cost: int = GameState.upgrade_cost(upgrade.id)
	if upgrade.one_time:
		_level.text = ""
		if lvl > 0:
			_button.text = tr("ON") if GameState.battle_speed_on else tr("OFF")
			_button.disabled = false
			return
	else:
		_level.text = tr("UPGRADE_LEVEL_FMT") % [lvl, upgrade.max_level]
	_button.text = tr("MAX") if cost < 0 else str(cost)
	_button.disabled = cost < 0 or GameState.coins < cost


func _on_pressed() -> void:
	if upgrade.one_time and GameState.upgrade_level(upgrade.id) > 0:
		GameState.set_battle_speed(not GameState.battle_speed_on)
	else:
		GameState.buy_upgrade(upgrade.id)
