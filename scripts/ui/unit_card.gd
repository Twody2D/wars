class_name UnitCard
extends TextureButton
## Buy card on the bottom panel (SPEC 9, battle v3 kit): portrait, food price
## (red when there is not enough food), level tag, key badge on PC. The card
## is dim when it cannot be bought; after a purchase a shade over the portrait
## shrinks and a bar fills while the card cools down.

signal buy_requested(unit: UnitData)

const EXPENSIVE := Color("#FF6B6B")
const PORTRAIT_BOTTOM_GAP := 2.0
const COOLDOWN_MIN := 20.0
const FILL_MIN := 8.0

@export var ready_texture: Texture2D
@export var dim_texture: Texture2D
## Card art of each unit (blue team accent) and its height on the card.
@export var art: Dictionary[StringName, Texture2D] = {}
@export var art_height: Dictionary[StringName, float] = {}

var unit: UnitData

@onready var _portrait: TextureRect = $Portrait
@onready var _cost: Label = $Cost
@onready var _key_badge: Control = $KeyBadge
@onready var _key_label: Label = $KeyBadge/Key
@onready var _cooldown: Control = $Cooldown
@onready var _cooldown_full: float = _cooldown.size.y
@onready var _cd_bar: Control = $CooldownBar
@onready var _cd_fill: Control = $CooldownBar/Fill
@onready var _cd_fill_width: float = _cd_fill.size.x
@onready var _level: Label = $LevelTag/Level


func _ready() -> void:
	pressed.connect(func() -> void: buy_requested.emit(unit))
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup(unit_: UnitData, key_number: int, unit_level: int, show_key: bool) -> void:
	unit = unit_
	_portrait.texture = art.get(unit.id, unit.portrait)
	var bottom: float = _portrait.position.y + _portrait.size.y
	var h: float = art_height.get(unit.id, _portrait.size.y)
	_portrait.position.y = bottom - PORTRAIT_BOTTOM_GAP - h
	_portrait.size.y = h
	_cost.text = str(unit.cost)
	_key_label.text = str(key_number)
	_key_badge.visible = show_key
	_level.text = tr("LEVEL_SHORT") % unit_level
	tooltip_text = tr(unit.name_key)


## reason from BattleSim.buy_block_reason; affordable — enough food and below
## the unit limit; cooldown_ratio 1 → just bought, 0 → ready.
func refresh(reason: StringName, affordable: bool, cooldown_ratio: float) -> void:
	disabled = reason != &""
	var cooling: bool = cooldown_ratio > 0.0
	var bright: bool = affordable and not cooling
	texture_normal = ready_texture if bright else dim_texture
	texture_disabled = texture_normal
	_portrait.modulate.a = 1.0 if bright else 0.5
	_cost.add_theme_color_override(&"font_color", Color.WHITE if affordable else EXPENSIVE)
	_cooldown.visible = cooling
	_cd_bar.visible = cooling
	if cooling:
		# The shade cannot be thinner than its nine-patch: below that it fades
		# out, so it ends together with the bar instead of waiting as a strip.
		var shade: float = _cooldown_full * cooldown_ratio
		_cooldown.size.y = maxf(COOLDOWN_MIN, shade)
		_cooldown.modulate.a = minf(1.0, shade / COOLDOWN_MIN)
		_cd_fill.size.x = maxf(FILL_MIN, _cd_fill_width * (1.0 - cooldown_ratio))
