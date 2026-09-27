class_name UpgradeCard
extends Control
## Army power-up tile on the upgrades screen (menu v3 mockup): icon in a round
## socket, name, what one level gives (green), "ур. 3/10" over a progress bar,
## price button — green when affordable, grey when not. "Battle speed" is bought
## once and then works as an on/off toggle (also in the settings).

@export var icons: Dictionary[StringName, Texture2D] = {}

const BAR_INNER := 118.0
const FILL_MIN := 26.0

var upgrade: UpgradeData

@onready var _icon: TextureRect = %Icon
@onready var _name: Label = %Name
@onready var _effect: Label = %Effect
@onready var _fill: Control = %Fill
@onready var _level: Label = %Level
@onready var _button: Button = %BuyButton
@onready var _coin: Texture2D = _button.icon


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	GameState.changed.connect(refresh)


func setup(upgrade_: UpgradeData) -> void:
	upgrade = upgrade_
	_icon.texture = icons.get(upgrade.id, upgrade.icon)
	_name.text = tr(upgrade.name_key)
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
	_level.text = tr("UPGRADE_LEVEL_FMT") % [lvl, upgrade.max_level]
	_fill.visible = lvl > 0
	_fill.size.x = maxf(FILL_MIN, BAR_INNER * lvl / upgrade.max_level)
	_button.disabled = false
	if upgrade.one_time and lvl > 0:
		_button.icon = null
		_button.text = tr("ON") if GameState.battle_speed_on else tr("OFF")
		_button.theme_type_variation = &"" if GameState.battle_speed_on else &"GreyButton"
		return
	if cost < 0:
		_button.icon = null
		_button.text = tr("MAX")
		_button.theme_type_variation = &"GreyButton"
		_button.disabled = true
		return
	_button.icon = _coin
	_button.text = UnitTile._format(cost)
	_button.theme_type_variation = &"" if GameState.coins >= cost else &"GreyButton"


func _on_pressed() -> void:
	if upgrade.one_time and GameState.upgrade_level(upgrade.id) > 0:
		GameState.set_battle_speed(not GameState.battle_speed_on)
		Audio.play_sfx(&"click", false)
	else:
		Audio.play_sfx(&"upgrade" if GameState.buy_upgrade(upgrade.id) else &"deny", false)
