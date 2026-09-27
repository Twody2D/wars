class_name UnitTile
extends Control
## Fighter card on the upgrades screen (menu v3 mockup): portrait on a sky
## window, name, HP and damage (with the next level's values in green after
## "›" when it can be bought), level pips, a price button — green when
## affordable, grey when not; maxed — a gold card with "МАКС"; locked — a
## black silhouette with a lock and the unlock price (grey until the unit's
## biome is open).

## Card by state: "normal", "locked", "max".
@export var frames: Dictionary[String, Texture2D] = {}
## Menu art of each unit (blue team accent) and its height in the window.
@export var art: Dictionary[StringName, Texture2D] = {}
@export var art_height: Dictionary[StringName, float] = {}

const WINDOW := Rect2(17.0, 17.0, 162.0, 88.0)
const ART_BOTTOM_GAP := 6.0

var unit: UnitData

@onready var _frame: TextureRect = %Frame
@onready var _portrait: TextureRect = %Portrait
@onready var _lock: TextureRect = %Lock
@onready var _name: Label = %Name
@onready var _pips: LevelPips = %Pips
@onready var _hp: Label = %Hp
@onready var _hp_next: Control = %HpNext
@onready var _damage: Label = %Damage
@onready var _damage_next: Control = %DamageNext
@onready var _max_plate: Control = %MaxPlate
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_button.pressed.connect(_on_buy)
	GameState.changed.connect(refresh)


func setup(unit_: UnitData) -> void:
	unit = unit_
	_portrait.texture = art.get(unit.id, unit.portrait)
	var h: float = art_height.get(unit.id, WINDOW.size.y - ART_BOTTOM_GAP)
	_portrait.position = Vector2(WINDOW.position.x, WINDOW.end.y - ART_BOTTOM_GAP - h)
	_portrait.size = Vector2(WINDOW.size.x, h)
	_name.text = tr(unit.name_key)
	refresh()


func refresh() -> void:
	if unit == null:
		return
	var unlocked: bool = GameState.is_unit_unlocked(unit.id)
	var max_level: int = GameState.balance().unit_max_level
	var level: int = maxi(GameState.unit_level(unit.id), 1)
	var maxed: bool = unlocked and level >= max_level
	_frame.texture = frames["max" if maxed else ("normal" if unlocked else "locked")]
	_portrait.modulate = Color.WHITE if unlocked else Color(0.0, 0.0, 0.0, 0.6)
	_lock.visible = not unlocked
	_pips.set_level(GameState.unit_level(unit.id) if unlocked else 0, max_level)
	var now: Vector2 = GameState.unit_stats(unit.id, level)
	var next: Vector2 = now
	if unlocked and GameState.unit_level_cost(unit.id) >= 0:
		next = GameState.unit_stats(unit.id, level + 1)
	_show_stat(_hp, _hp_next, now.x, next.x)
	_show_stat(_damage, _damage_next, now.y, next.y)
	_max_plate.visible = maxed
	_button.visible = not maxed
	if maxed:
		return
	var cost: int = GameState.unit_level_cost(unit.id) if unlocked else GameState.unit_unlock_cost(unit.id)
	# A unit of a biome that is not open yet: its price, greyed out.
	var shown: int = cost if cost >= 0 else unit.unlock_cost
	_button.text = _format(shown)
	var can_buy: bool = cost >= 0 and GameState.coins >= cost
	_button.theme_type_variation = &"" if can_buy else &"GreyButton"
	_button.disabled = cost < 0


## "66" and, when the next level changes it, "›72" in green.
func _show_stat(label: Label, next_box: Control, now: float, next: float) -> void:
	label.text = str(roundi(now))
	next_box.visible = roundi(next) != roundi(now)
	var value: Label = next_box.get_child(1)
	value.text = str(roundi(next))


## 20000 → "20 000", like the mockup.
static func _format(n: int) -> String:
	var s: String = str(n)
	var out: String = ""
	while s.length() > 3:
		out = " " + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out


func _on_buy() -> void:
	var cost: int = GameState.unit_level_cost(unit.id) if GameState.is_unit_unlocked(unit.id) else GameState.unit_unlock_cost(unit.id)
	if cost < 0 or GameState.coins < cost:
		return
	if GameState.is_unit_unlocked(unit.id):
		GameState.level_up_unit(unit.id)
	else:
		GameState.unlock_unit(unit.id)
