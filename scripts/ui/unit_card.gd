class_name UnitCard
extends TextureButton
## Buy card on the bottom panel (SPEC 9): portrait, food cost, key badge on PC,
## grey when not affordable / limit, cooldown sweep after a purchase.

signal buy_requested(unit: UnitData)

var unit: UnitData

@onready var _portrait: TextureRect = $Portrait
@onready var _cost: Label = $Cost
@onready var _key_badge: Control = $KeyBadge
@onready var _key_label: Label = $KeyBadge/Key
@onready var _cooldown: ColorRect = $Cooldown
@onready var _level: Label = $Level


func _ready() -> void:
	pressed.connect(func() -> void: buy_requested.emit(unit))
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup(unit_: UnitData, key_number: int, unit_level: int, show_key: bool) -> void:
	unit = unit_
	_portrait.texture = unit.portrait
	_cost.text = str(unit.cost)
	_key_label.text = str(key_number)
	_key_badge.visible = show_key
	_level.text = tr("LEVEL_SHORT") % unit_level if unit_level > 1 else ""
	tooltip_text = tr(unit.name_key)


## reason from BattleSim.buy_block_reason; affordable — enough food and below
## the unit limit (greyed otherwise, even during the cooldown); cooldown_ratio 1 → just bought.
func refresh(reason: StringName, affordable: bool, cooldown_ratio: float) -> void:
	disabled = reason != &""
	modulate = Color.WHITE if affordable else Color(0.5, 0.5, 0.5)
	_cooldown.visible = cooldown_ratio > 0.0
	_cooldown.anchor_top = 1.0 - cooldown_ratio
