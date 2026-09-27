class_name UnitTile
extends Control
## Fighter card on the upgrades screen (menu v3 mockup): portrait on a sky
## window, name, HP and damage (with the next level's values in green after
## "›" when it can be bought), level pips, a price button — green when
## affordable, grey when not; maxed — a gold card with "МАКС"; locked — a
## black silhouette with a lock and the unlock price. Units of a biome that is
## not open yet are hidden (Twody: the screen was too crowded).

## Card by state: "normal", "locked", "max".
@export var frames: Dictionary[String, Texture2D] = {}
## Menu art of each unit (blue team accent) and its height in the window.
@export var art: Dictionary[StringName, Texture2D] = {}
@export var art_height: Dictionary[StringName, float] = {}

const WINDOW := Rect2(17.0, 17.0, 162.0, 88.0)
const ART_BOTTOM_GAP := 6.0
## The stats row must fit inside the card frame; big numbers get a smaller font.
const STATS_MAX_WIDTH := 184.0
const STATS_FONT_MAX := 24
const STATS_FONT_MIN := 15

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
@onready var _stats: Control = $Stats
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
	# Only the biomes the player has reached: later units appear after the caves open.
	visible = unit.unlock_biome <= GameState.biome_unlocked
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
	_fit_stats()
	_max_plate.visible = maxed
	_button.visible = not maxed
	if maxed:
		return
	var cost: int = GameState.unit_level_cost(unit.id) if unlocked else GameState.unit_unlock_cost(unit.id)
	_button.text = _format(maxi(cost, 0))
	var can_buy: bool = cost >= 0 and GameState.coins >= cost
	_button.theme_type_variation = &"" if can_buy else &"GreyButton"
	_button.disabled = cost < 0


## "66" and, when the next level changes it, "›72" in green.
func _show_stat(label: Label, next_box: Control, now: float, next: float) -> void:
	label.text = str(roundi(now))
	next_box.visible = roundi(next) != roundi(now)
	var value: Label = next_box.get_child(1)
	value.text = str(roundi(next))


## Shrinks the stats font until the row fits the card (e.g. "140›151 ⚔19›20").
## The width is measured from the font: the containers' minimum size is
## updated a frame later and would still hold the old font size.
func _fit_stats() -> void:
	var labels: Array[Label] = []
	for label: Node in _stats.find_children("*", "Label", true, false):
		labels.append(label as Label)
	var font_size: int = STATS_FONT_MAX
	while font_size > STATS_FONT_MIN and _stats_width(font_size) > STATS_MAX_WIDTH:
		font_size -= 1
	for label: Label in labels:
		label.add_theme_font_size_override(&"font_size", font_size)


func _stats_width(font_size: int) -> float:
	var width: float = 0.0
	var boxes: Array[Node] = _stats.get_children()
	for box: Node in boxes:
		var row: BoxContainer = box
		var shown: int = 0
		for part: Node in row.get_children():
			var c: Control = part
			if c.visible:
				shown += 1
				width += _part_width(c, font_size)
		width += row.get_theme_constant(&"separation") * maxi(shown - 1, 0)
	return width + _stats.get_theme_constant(&"separation") * (boxes.size() - 1)


func _part_width(part: Control, font_size: int) -> float:
	if not part.visible:
		return 0.0
	if part is Label:
		var label: Label = part
		var font: Font = label.get_theme_font(&"font")
		return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if part is BoxContainer:
		var sum: float = 0.0
		for child: Node in part.get_children():
			sum += _part_width(child as Control, font_size)
		return sum
	return part.custom_minimum_size.x


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
		Audio.play_sfx(&"deny", false)
		return
	if GameState.is_unit_unlocked(unit.id):
		GameState.level_up_unit(unit.id)
		Audio.play_sfx(&"upgrade", false)
	else:
		GameState.unlock_unit(unit.id)
		Audio.play_sfx(&"unlock", false)
