class_name UnitData
extends Resource
## One unit type (SPEC 3). Stats are for unit level 1.

@export var id: StringName
@export var name_key: String
@export_group("Combat")
@export var hp: float = 50.0
@export var damage: float = 5.0
## Seconds between attack starts.
@export var cooldown: float = 1.0
## px; enemy or base within this distance ahead is attacked.
@export var attack_range: float = 20.0
## px/s
@export var speed: float = 40.0
## px; > 0 — damage hits everything in this radius around the target.
@export var splash_radius: float = 0.0
## Seconds from attack start to the hit frame (matches the attack animation).
@export var hit_delay: float = 0.3
## Non-empty — ranged, fires this projectile (art/projectiles/proj_<id>).
@export var projectile: StringName = &""
## Bomber: explodes on first contact and dies.
@export var explodes: bool = false
@export_group("Shop")
## Food cost in battle.
@export var cost: int = 3
## Coins to unlock; 0 — unlocked from the start.
@export var unlock_cost: int = 0
## Biome where the unit can be unlocked (1 — meadow, 2 — cave).
@export var unlock_biome: int = 1
@export var is_boss: bool = false
@export_group("Visual")
@export var visual: PackedScene
@export var portrait: Texture2D


func is_ranged() -> bool:
	return projectile != &""
