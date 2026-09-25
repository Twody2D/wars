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


func _ready() -> void:
	_logo.texture = logos.get(TranslationServer.get_locale().left(2), logos.get("ru"))
	for i: int in _tab_buttons.size():
		_tab_buttons[i].pressed.connect(_show_tab.bind(i))
	_play.pressed.connect(func() -> void: _start(GameState.max_playable_level()))
	_evolve.pressed.connect(func() -> void: GameState.evolve())
	for u: UnitData in GameState.config.player_units:
		var tile: UnitTile = unit_tile_scene.instantiate()
		_unit_tiles.add_child(tile)
		tile.setup(u)
	for up: UpgradeData in GameState.config.upgrades:
		if up.id == &"unit_level":
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
	GameState.changed.connect(_refresh)
	_refresh()
	_show_tab(0)
	Platform.gameplay_stop()


func _refresh() -> void:
	_coins.text = str(GameState.coins)
	var next: int = GameState.max_playable_level()
	_level_label.text = tr("LEVEL_FMT") % next
	_evolve.visible = GameState.can_evolve()


func _show_tab(index: int) -> void:
	for i: int in _tabs.size():
		_tabs[i].visible = i == index
		_tab_buttons[i].theme_type_variation = &"" if i == index else &"SecondaryButton"


func _start(level_number: int) -> void:
	GameState.selected_level = level_number
	get_tree().change_scene_to_file(BATTLE_SCENE)
