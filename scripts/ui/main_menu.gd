class_name MainMenu
extends Control
## Main menu (SPEC 7): bottom tab bar — Battle, Upgrades, Map.

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

@export var unit_tile_scene: PackedScene
@export var upgrade_row_scene: PackedScene
@export var level_button_scene: PackedScene
@export var logos: Dictionary[String, Texture2D] = {}
## Level slot centres on map_world (ARTBOARDS.md), index 0 = level 1.
@export var map_slots: PackedVector2Array = PackedVector2Array()
## Upgrades on the upgrades screen, in order (the rest are hidden or elsewhere:
## battle speed is in the settings).
@export var shown_upgrades: Array[StringName] = [&"army_power", &"food_rate", &"base_hp"]

@onready var _coins: Label = %CoinsLabel
@onready var _logo: TextureRect = %Logo
@onready var _tabs: Array[Control] = [%BattleTab, %UpgradesTab, %MapTab]
@onready var _tab_buttons: Array[Button] = [%TabBattle, %TabUpgrades, %TabMap]
@onready var _play: Button = %PlayButton
@onready var _level_label: Label = %LevelLabel
@onready var _unit_tiles: HBoxContainer = %UnitTiles
@onready var _upgrade_rows: GridContainer = %UpgradeRows
@onready var _evolve: Button = %EvolveButton
@onready var _map_slots: Control = %MapSlots
@onready var _settings: SettingsPanel = %Settings
@onready var _settings_button: Button = %SettingsButton


func _ready() -> void:
	get_tree().paused = false
	Audio.play_music(&"menu")
	_logo.texture = logos.get(TranslationServer.get_locale().left(2), logos.get("ru"))
	for i: int in _tab_buttons.size():
		_tab_buttons[i].pressed.connect(_show_tab.bind(i))
	_play.pressed.connect(func() -> void: _start(GameState.max_playable_level()))
	_evolve.pressed.connect(func() -> void: GameState.evolve())
	_settings_button.pressed.connect(_settings.open)
	for u: UnitData in GameState.config.player_units:
		var tile: UnitTile = unit_tile_scene.instantiate()
		_unit_tiles.add_child(tile)
		tile.setup(u)
	for id: StringName in shown_upgrades:
		var up: UpgradeData = GameState.config.upgrade(id)
		if up == null:
			continue
		var row: UpgradeRow = upgrade_row_scene.instantiate()
		_upgrade_rows.add_child(row)
		row.setup(up)
	for n: int in range(1, GameState.level_count() + 1):
		var b: LevelButton = level_button_scene.instantiate()
		_map_slots.add_child(b)
		b.setup(n)
		if n - 1 < map_slots.size():
			b.position = map_slots[n - 1] - b.size / 2.0
		b.level_chosen.connect(_start)
	_tabs[2].resized.connect(_layout_map)
	_layout_map()
	GameState.changed.connect(_refresh)
	_refresh()
	_show_tab(0)
	Platform.gameplay_stop()


## The map (1280×720, slots and background together) is scaled to the screen
## width so all 20 levels are always visible; on taller screens the background
## repeats mirrored above and below (MapBg tiles with texture_repeat = mirror).
func _layout_map() -> void:
	var area: Vector2 = _tabs[2].size
	var s: float = area.x / _map_slots.size.x
	_map_slots.scale = Vector2(s, s)
	_map_slots.position = Vector2(0.0, (area.y - _map_slots.size.y * s) / 2.0)


func _refresh() -> void:
	_coins.text = str(GameState.coins)
	var next: int = GameState.max_playable_level()
	_level_label.text = tr("LEVEL_FMT") % next
	_evolve.visible = GameState.can_evolve()


func _show_tab(index: int) -> void:
	for i: int in _tabs.size():
		_tabs[i].visible = i == index
		_tab_buttons[i].theme_type_variation = &"TabActive" if i == index else &"TabButton"


func _start(level_number: int) -> void:
	GameState.selected_level = level_number
	get_tree().change_scene_to_file(BATTLE_SCENE)
