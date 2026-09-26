class_name UnitTile
extends PanelContainer
## Unit on the upgrades screen: portrait in a sky window, name, level pips, one
## green price button (unlock or next level). Locked units sit on a grey card.
## HP and damage are shown on the portrait; when the next level can be bought,
## its values follow an arrow — that is what the level-up gives.

@export var coin_icon: Texture2D

var unit: UnitData

@onready var _window: PanelContainer = %Window
@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %Name
@onready var _pips: LevelPips = %Pips
@onready var _hp: Label = %Hp
@onready var _hp_next: Label = %HpNext
@onready var _damage: Label = %Damage
@onready var _damage_next: Label = %DamageNext
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
	var level: int = maxi(GameState.unit_level(unit.id), 1)
	var now: Vector2 = GameState.unit_stats(unit.id, level)
	var next: Vector2 = now
	if unlocked and GameState.unit_level_cost(unit.id) >= 0:
		next = GameState.unit_stats(unit.id, level + 1)
	_show_stat(_hp, _hp_next, now.x, next.x)
	_show_stat(_damage, _damage_next, now.y, next.y)
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


## "66" and, when the next level changes it, a green "›72".
func _show_stat(label: Label, next_label: Label, now: float, next: float) -> void:
	label.text = str(roundi(now))
	next_label.visible = roundi(next) != roundi(now)
	next_label.text = "›%d" % roundi(next)


func _on_buy() -> void:
	if GameState.is_unit_unlocked(unit.id):
		GameState.level_up_unit(unit.id)
	else:
		GameState.unlock_unit(unit.id)
