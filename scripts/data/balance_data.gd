class_name BalanceData
extends Resource
## Global battle and meta numbers (SPEC 2, 3, 4, 6, 7).

@export_group("Lane")
@export var lane_start_x: float = 160.0
@export var lane_end_x: float = 1120.0
@export var lane_y: float = 390.0
@export var y_jitter: float = 12.0
@export var player_base_pos: Vector2 = Vector2(90, 390)
@export var bot_base_pos: Vector2 = Vector2(1190, 390)

@export_group("Combat")
@export var unit_limit: int = 20
## Own unit ahead closer than this → Wait.
@export var wait_distance: float = 22.0
@export var projectile_speed: float = 400.0
@export var projectile_arc: float = 40.0
## +HP and damage per unit level above 1.
@export var unit_level_bonus: float = 0.1
@export var unit_max_level: int = 5
@export var sim_dt: float = 1.0 / 60.0

@export_group("Economy")
@export var start_food: float = 5.0
@export var food_rate: float = 0.5
@export var food_max: float = 30.0
@export var player_base_hp: float = 300.0
@export var card_cooldown: float = 1.0
@export var ore_food: float = 2.0
@export var ore_cooldown: float = 4.0

@export_group("Meteor")
@export var meteor_recharge: float = 25.0
@export var meteor_max_charges: int = 2
@export var meteor_damage: float = 80.0
@export var meteor_radius: float = 110.0

@export_group("Bot")
## After the last wave: one random unit every N seconds.
@export var bot_pressure_interval: float = 6.0

@export_group("Rewards")
@export var coins_per_kill: int = 1
@export var lose_reward_ratio: float = 0.3
@export var three_stars_hp: float = 0.7
@export var two_stars_hp: float = 0.35

@export_group("Upgrades")
@export var upgrade_cost_growth: float = 1.35
@export var upgrade_cost_round: int = 5
## Food max +N for every 2 levels of food production.
@export var food_max_per_2_levels: float = 5.0

@export_group("Boosters")
@export var booster_time_scale: float = 2.0
@export var booster_food: float = 15.0
@export var battle_speed_scale: float = 1.5

@export_group("Colors")
@export var player_color: Color = Color("#3A7BFF")
@export var bot_color: Color = Color("#FF4A4A")
