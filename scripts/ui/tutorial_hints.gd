class_name TutorialHints
extends Control
## Level 1 hints (SPEC 5): a pointing hand + text — buy a unit, tap the ore,
## use the meteor. Each step ends when the player does it.

const STEPS: Array[StringName] = [&"bought", &"ore", &"meteor"]
const TEXTS: Array[String] = ["TUTORIAL_CARD", "TUTORIAL_ORE", "TUTORIAL_METEOR"]

@export var bob_px: float = 10.0
## Fingertip inside the hand icon (0..1), after the vertical flip.
@export var fingertip: Vector2 = Vector2(0.43, 0.94)
## How far inside the target's top edge the fingertip lands, px.
@export var tip_inset: float = 6.0

var _battle: Battle
var _step: int = -1
var _time: float = 0.0

@onready var _hand: TextureRect = $Hand
@onready var _label: Label = $Text


func setup(battle: Battle, enabled: bool) -> void:
	_battle = battle
	_step = 0 if enabled else -1
	visible = enabled
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.flip_v = true


func notify(action: StringName) -> void:
	if _step >= 0 and _step < STEPS.size() and STEPS[_step] == action:
		_step += 1
		if _step >= STEPS.size():
			_step = -1
			visible = false


func _process(delta: float) -> void:
	if _step < 0 or _battle == null:
		return
	_time += delta
	var target := Rect2()
	match STEPS[_step]:
		&"bought":
			target = _battle._hud.card_rect(0)
		&"ore":
			var ores: Array[OreBlock] = _battle._ore_list()
			if not ores.is_empty():
				# World → screen: the battle camera centres the field.
				var xf: Transform2D = ores[0].get_global_transform_with_canvas()
				target = Rect2(xf.origin, ores[0].size * xf.get_scale())
		&"meteor":
			if _battle.sim.meteor_charges <= 0 or _battle.sim.alive_count(BattleSim.BOT) == 0:
				_hand.visible = false
				_label.visible = false
				return
			target = _battle._hud.meteor_rect()
	_hand.visible = true
	_label.visible = true
	# The hand points down from above: its fingertip touches the top edge of
	# the target, so the target itself stays visible.
	var bob: float = (sin(_time * 6.0) - 1.0) * 0.5 * bob_px
	var tip := Vector2(target.get_center().x, target.position.y + tip_inset)
	_hand.global_position = tip - fingertip * _hand.size + Vector2(0.0, bob)
	_label.text = tr(TEXTS[_step])
	_label.global_position = Vector2(
		clampf(target.get_center().x - _label.size.x / 2.0, 16.0, get_viewport_rect().size.x - 16.0 - _label.size.x),
		_hand.global_position.y - _label.size.y - 4.0)
