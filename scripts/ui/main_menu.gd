class_name MainMenu
extends Control
## Main menu (SPEC 7, menu v3 mockup "Mine Rush menu redesign"): bottom tab bar
## — Battle, Upgrades, Map; settings and the coin counter on top.

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const MAP_SIZE := Vector2(2560.0, 720.0)
## Bottom tabs: centre x of each slot in the 800 px bar; the open tab is
## bigger and raised (tab_active 248×118 at y 4, tab_inactive 232×102 at y 26).
const TAB_CENTERS: Array[float] = [156.0, 400.0, 644.0]
const TAB_ACTIVE := Rect2(0.0, 4.0, 248.0, 118.0)
const TAB_IDLE := Rect2(0.0, 26.0, 232.0, 102.0)
## Icon (x, y, size) and label (y, height, font size) inside a tab.
const TAB_ACTIVE_ICON := Vector3(94.0, 4.0, 60.0)
const TAB_IDLE_ICON := Vector3(92.0, 5.0, 48.0)
const TAB_ACTIVE_LABEL := Vector3(62.0, 32.0, 26.0)
const TAB_IDLE_LABEL := Vector3(52.0, 30.0, 24.0)
const GLOW_SCALE := Vector2(0.95, 1.08)
const GLOW_ALPHA := Vector2(0.6, 1.0)
const GLOW_SEC := 0.9
const BADGE_BOB := 2.0
const MAP_WHEEL_STEP := 120.0

@export var unit_tile_scene: PackedScene
@export var upgrade_card_scene: PackedScene
@export var level_button_scene: PackedScene
@export var logos: Dictionary[String, Texture2D] = {}
## Level node centres on bg_map (kit/map_nodes.json), index 0 = level 1.
@export var map_nodes: PackedVector2Array = PackedVector2Array()
## Army power-ups on the upgrades screen, in order.
@export var shown_upgrades: Array[StringName] = [&"army_power", &"food_rate", &"base_hp", &"start_food", &"battle_speed"]

@onready var _sky: Control = %Sky
@onready var _scenery: Control = %Scenery
@onready var _characters: Control = %Characters
@onready var _coins: Label = %CoinsLabel
@onready var _logo: TextureRect = %Logo
@onready var _tabs: Array[Control] = [%BattleTab, %UpgradesTab, %MapTab]
@onready var _tab_buttons: Array[Button] = [%TabBattle, %TabUpgrades, %TabMap]
@onready var _badge: Control = %Badge
@onready var _play: Button = %PlayButton
@onready var _glow: Control = %Glow
@onready var _level_label: Label = %LevelLabel
@onready var _stars: Array[TextureRect] = [$BattleTab/Stars/S1, $BattleTab/Stars/S2, $BattleTab/Stars/S3]
@onready var _boss_plate: Control = %BossPlate
@onready var _boss_label: Label = %BossLabel
@onready var _unit_tiles: HBoxContainer = %UnitTiles
@onready var _upgrade_grid: GridContainer = %UpgradeGrid
@onready var _cave: Button = %CaveButton
@onready var _cave_lock: Control = %Lock
@onready var _cave_hint: Label = %Hint
@onready var _map_scroll: ScrollContainer = %MapScroll
@onready var _map_content: Control = %MapContent
@onready var _map_canvas: Control = %MapCanvas
@onready var _map_nodes: Control = %Nodes
@onready var _settings: SettingsPanel = %Settings
@onready var _settings_button: Button = %SettingsButton

## Tabs opened before the current one; Esc goes back through them.
var _tab_history: Array[int] = []
var _current_tab: int = 0
var _star_full: Texture2D
var _star_empty: Texture2D
var _level_buttons: Array[LevelButton] = []


func _ready() -> void:
	get_tree().paused = false
	Audio.play_music(&"menu")
	_logo.texture = logos.get(TranslationServer.get_locale().left(2), logos.get("ru"))
	for i: int in _tab_buttons.size():
		_tab_buttons[i].pressed.connect(_open_tab.bind(i))
	_play.pressed.connect(func() -> void: _start(GameState.max_playable_level()))
	_cave.pressed.connect(func() -> void: GameState.evolve())
	_settings_button.pressed.connect(_settings.open)
	for u: UnitData in GameState.config.player_units:
		var tile: UnitTile = unit_tile_scene.instantiate()
		_unit_tiles.add_child(tile)
		tile.setup(u)
	for id: StringName in shown_upgrades:
		var up: UpgradeData = GameState.config.upgrade(id)
		if up == null:
			continue
		var card: UpgradeCard = upgrade_card_scene.instantiate()
		_upgrade_grid.add_child(card)
		card.setup(up)
	_map_scroll.gui_input.connect(_on_map_input)
	resized.connect(_layout)
	GameState.changed.connect(_refresh)
	_refresh()
	_layout()
	_start_animations()
	_show_tab(0)
	Platform.gameplay_stop()


## The scenery is drawn for 1440×720 and sits on the bottom edge (a taller
## 4:3 screen shows more sky); the map is scaled to the screen height.
func _layout() -> void:
	var map_scale: float = size.y / MAP_SIZE.y
	_map_canvas.scale = Vector2(map_scale, map_scale)
	_map_content.custom_minimum_size = MAP_SIZE * map_scale


func _refresh() -> void:
	_coins.text = UnitTile._format(GameState.coins)
	var next: int = GameState.max_playable_level()
	_level_label.text = tr("LEVEL_FMT") % next
	var stars: int = GameState.level_stars.get(next, 0)
	for i: int in 3:
		_stars[i].texture = _star(i < stars)
	var boss: UnitData = _boss_of(next)
	_boss_plate.visible = boss != null
	if boss != null:
		_boss_label.text = tr("BANNER_BOSS_FMT") % tr(boss.name_key)
	# "Open the caves": shown until the next biome is open.
	var last_biome: int = ceili(float(GameState.level_count()) / GameState.config.levels_per_biome)
	_cave.visible = GameState.biome_unlocked < last_biome
	_cave.disabled = not GameState.can_evolve()
	_cave_lock.visible = _cave.disabled
	_cave_hint.text = tr("EVOLVE_HINT") if _cave.disabled else tr("EVOLVE_READY")
	_badge.visible = _can_buy_something()
	_build_map()


func _star(full: bool) -> Texture2D:
	if _star_full == null:
		_star_full = _stars[0].texture
		_star_empty = load("res://art/ui/v3/star_empty.svg")
	return _star_full if full else _star_empty


## The boss of a level (its last wave), or null.
func _boss_of(number: int) -> UnitData:
	var level: LevelData = GameState.level(number)
	if level.waves.is_empty():
		return null
	for entry: WaveEntry in level.waves[level.waves.size() - 1].entries:
		if entry.unit.is_boss:
			return entry.unit
	return null


## Red dot on the Upgrades tab: some unit or power-up is affordable now.
func _can_buy_something() -> bool:
	for u: UnitData in GameState.config.player_units:
		var cost: int = GameState.unit_level_cost(u.id) if GameState.is_unit_unlocked(u.id) else GameState.unit_unlock_cost(u.id)
		if cost >= 0 and cost <= GameState.coins:
			return true
	for id: StringName in shown_upgrades:
		var cost: int = GameState.upgrade_cost(id)
		if cost >= 0 and cost <= GameState.coins:
			return true
	return false


func _build_map() -> void:
	for b: LevelButton in _level_buttons:
		b.queue_free()
	_level_buttons.clear()
	for n: int in range(1, mini(GameState.level_count(), map_nodes.size()) + 1):
		var b: LevelButton = level_button_scene.instantiate()
		_map_nodes.add_child(b)
		b.setup(n)
		b.place(map_nodes[n - 1])
		b.level_chosen.connect(_start)
		_level_buttons.append(b)


## Centres the map on the current level.
func _scroll_map_to_current() -> void:
	var i: int = clampi(GameState.max_playable_level(), 1, map_nodes.size()) - 1
	var x: float = map_nodes[i].x * _map_canvas.scale.x - _map_scroll.size.x / 2.0
	_map_scroll.scroll_horizontal = maxi(0, roundi(x))


## The mouse wheel scrolls the map sideways.
func _on_map_input(event: InputEvent) -> void:
	var wheel: InputEventMouseButton = event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return
	var step: float = 0.0
	if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN or wheel.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
		step = MAP_WHEEL_STEP
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_UP or wheel.button_index == MOUSE_BUTTON_WHEEL_LEFT:
		step = -MAP_WHEEL_STEP
	if step != 0.0:
		_map_scroll.scroll_horizontal += roundi(step)
		_map_scroll.accept_event()


func _start_animations() -> void:
	var glow: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	glow.tween_property(_glow, "scale", Vector2.ONE * GLOW_SCALE.y, GLOW_SEC)
	glow.parallel().tween_property(_glow, "modulate:a", GLOW_ALPHA.y, GLOW_SEC)
	glow.tween_property(_glow, "scale", Vector2.ONE * GLOW_SCALE.x, GLOW_SEC)
	glow.parallel().tween_property(_glow, "modulate:a", GLOW_ALPHA.x, GLOW_SEC)
	var y: float = _badge.position.y
	var bob: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	bob.tween_property(_badge, "position:y", y - BADGE_BOB, 0.5)
	bob.tween_property(_badge, "position:y", y, 0.5)


## Esc (the "pause" action): back to the previous tab.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not _tab_history.is_empty():
		get_viewport().set_input_as_handled()
		var previous: int = _tab_history.pop_back()
		_show_tab(previous)


func _open_tab(index: int) -> void:
	if index == _current_tab:
		return
	_tab_history.append(_current_tab)
	_show_tab(index)


func _show_tab(index: int) -> void:
	_current_tab = index
	# The meadow scenery is behind the Battle and Upgrades tabs; the map has its own.
	_scenery.visible = index != 2
	_sky.visible = index != 2
	_characters.visible = index == 0
	for i: int in _tabs.size():
		_tabs[i].visible = i == index
		_style_tab(_tab_buttons[i], i, i == index)
	if index == 2:
		_scroll_map_to_current.call_deferred()


func _style_tab(button: Button, index: int, active: bool) -> void:
	var box: Rect2 = TAB_ACTIVE if active else TAB_IDLE
	button.theme_type_variation = &"TabActive" if active else &"TabButton"
	button.position = Vector2(TAB_CENTERS[index] - box.size.x / 2.0, box.position.y)
	button.size = box.size
	var icon_box: Vector3 = TAB_ACTIVE_ICON if active else TAB_IDLE_ICON
	var icon: TextureRect = button.get_node(^"Icon")
	icon.position = Vector2(icon_box.x, icon_box.y)
	icon.size = Vector2(icon_box.z, icon_box.z)
	var label_box: Vector3 = TAB_ACTIVE_LABEL if active else TAB_IDLE_LABEL
	var label: Label = button.get_node(^"Label")
	label.position = Vector2(0.0, label_box.x)
	label.size = Vector2(box.size.x, label_box.y)
	label.add_theme_font_size_override(&"font_size", roundi(label_box.z))
	label.theme_type_variation = &"" if active else &"SoftLabel"
	var badge: Control = button.get_node_or_null(^"Badge")
	if badge != null:
		badge.position.x = box.size.x - badge.size.x + 8.0


func _start(level_number: int) -> void:
	GameState.selected_level = level_number
	get_tree().change_scene_to_file(BATTLE_SCENE)
