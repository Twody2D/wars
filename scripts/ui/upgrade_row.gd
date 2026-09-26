class_name UpgradeRow
extends PanelContainer
## One meta upgrade on the upgrades screen (SPEC 7): icon, short name, effect
## of one level, level pips, green price button. "Battle speed" is bought once
## and then works as an on/off toggle.

@export var coin_icon: Texture2D

var upgrade: UpgradeData

@onready var _icon: TextureRect = %Icon
@onready var _name: Label = %Name
@onready var _effect: Label = %Effect
@onready var _pips: LevelPips = %Pips
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	GameState.changed.connect(refresh)


func setup(upgrade_: UpgradeData) -> void:
	upgrade = upgrade_
	_icon.texture = upgrade.icon
	_name.text = tr(upgrade.name_key + "_SHORT")
	_effect.text = effect_text(upgrade)
	refresh()


## What one level gives, as short as possible ("+10%", "+75", "+0.05/с", "×1.5").
static func effect_text(up: UpgradeData) -> String:
	match up.id:
		&"army_power":
			return "+%d%%" % roundi(up.per_level * 100.0)
		&"food_rate":
			return TranslationServer.translate("EFFECT_PER_SEC_FMT") % String.num(up.per_level, 2)
		&"battle_speed":
			return "×%s" % String.num(up.per_level, 1)
	return "+%d" % roundi(up.per_level)


func refresh() -> void:
	if upgrade == null:
		return
	var lvl: int = GameState.upgrade_level(upgrade.id)
	var cost: int = GameState.upgrade_cost(upgrade.id)
	_pips.visible = not upgrade.one_time
	_pips.set_level(lvl, upgrade.max_level)
	if upgrade.one_time and lvl > 0:
		_button.icon = null
		_button.text = tr("ON") if GameState.battle_speed_on else tr("OFF")
		_button.theme_type_variation = &"" if GameState.battle_speed_on else &"SecondaryButton"
		_button.disabled = false
		return
	_button.theme_type_variation = &""
	if cost < 0:
		_button.icon = null
		_button.text = tr("MAX")
		_button.disabled = true
	else:
		_button.icon = coin_icon
		_button.text = str(cost)
		_button.disabled = GameState.coins < cost


func _on_pressed() -> void:
	if upgrade.one_time and GameState.upgrade_level(upgrade.id) > 0:
		GameState.set_battle_speed(not GameState.battle_speed_on)
	else:
		GameState.buy_upgrade(upgrade.id)
