class_name UnitHpBar
extends Node2D
## Small HP bar above a unit (battle v3 kit): a dark frame and a blue or red
## fill, both nine-sliced so the bar can grow for leaders and bosses.

const FRAME: Texture2D = preload("res://art/ui/v3/battle/hp_unit_frame.svg")
const FILL_BLUE: Texture2D = preload("res://art/ui/v3/battle/hp_unit_fill_blue.svg")
const FILL_RED: Texture2D = preload("res://art/ui/v3/battle/hp_unit_fill_red.svg")
const FRAME_MARGIN := 4.0
const FILL_MARGIN := 3.0
const INSET := 1.5

@export var width: float = 36.0
@export var height: float = 9.0

var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()
## Team colour; a red-ish colour picks the enemy fill.
var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()

var _frame: StyleBoxTexture = _box(FRAME, FRAME_MARGIN)
var _blue: StyleBoxTexture = _box(FILL_BLUE, FILL_MARGIN)
var _red: StyleBoxTexture = _box(FILL_RED, FILL_MARGIN)


static func _box(texture: Texture2D, margin: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = margin
	box.texture_margin_top = margin
	box.texture_margin_right = margin
	box.texture_margin_bottom = margin
	return box


func _draw() -> void:
	var rect := Rect2(-width / 2.0, -height / 2.0, width, height)
	draw_style_box(_frame, rect)
	if ratio <= 0.0:
		return
	var inner: Rect2 = rect.grow(-INSET)
	inner.size.x = maxf(FILL_MARGIN * 2.0, inner.size.x * ratio)
	draw_style_box(_red if color.r > color.b else _blue, inner)
