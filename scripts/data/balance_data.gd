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
## How many own units may crowd into a fight at the front line: while the unit
## ahead is attacking, followers close in until this many are fighting.
@export var front_width: int = 3
@export var projectile_speed: float = 400.0
@export var projectile_arc: float = 40.0
## +HP and damage per unit level above 1.
@export var unit_level_bonus: float = 0.1
@export var unit_max_level: int = 5
@export var sim_dt: float = 1.0 / 60.0
## Global battle pace: 1 = SPEC speed. Slows movement, food, attacks and waves
## alike, so balance stays the same.
@export var battle_pace: float = 0.7
## Unit size on screen relative to the 64 px design size.
@export var unit_scale: float = 1.4

@export_group("Economy")
@export var start_food: float = 5.0
@export var food_rate: float = 0.5
@export var food_max: float = 30.0
@export var player_base_hp: float = 300.0
## Every enemy hit on the player's base takes exactly this much, whatever the
## unit's damage (base HP counts hits; 0 = use the unit damage).
@export var player_base_hit: float = 0.0
## After a hit the player's base ignores further hits for this long, so a crowd
## of fast attackers cannot erase a 5-HP base in two seconds.
@export var player_base_hit_interval: float = 0.0
@export var card_cooldown: float = 1.0
@export var ore_food: float = 2.0
@export var ore_cooldown: float = 4.0

@export_group("Meteor")
@export var meteor_recharge: float = 25.0
@export var meteor_max_charges: int = 2
@export var meteor_damage: float = 80.0
@export var meteor_radius: float = 110.0
## Seconds from the cast to the impact (the rock is falling).
@export var meteor_fall_time: float = 0.9

@export_group("Bot")
## Bosses: HP and damage multiplier on top of bot_power.
@export var boss_power: float = 1.0
## Wave leader (last wave of a level): HP and damage multiplier on top of bot_power.
@export var elite_power: float = 3.0
## Wave leader size on screen relative to a normal unit.
@export var elite_scale: float = 1.5
## Units of one wave that start together are let out this far apart (s).
@export var wave_stagger: float = 0.35
## The bot sends defenders once a player unit is past this share of the lane.
@export var bot_defend_line: float = 0.5
## While the last wave's leader or boss is alive, the bot base can't drop
## below this share of its HP (Twody: the boss must be beaten, not skipped).
@export var bot_shield_floor: float = 0.15
## The first hit on the bot base lets out this many defenders at once.
@export var bot_defenders: int = 3
## The bot base at this share of its HP calls the last wave (with its leader
## or boss) at once, whatever the wave timer says.
@export var bot_rally_ratio: float = 0.5
## Bot power grows by this share per level on top of LevelData.bot_power
## (Twody 01.10: an upgraded army won on the 2nd wave).
@export var bot_power_per_level: float = 0.0
## After the last wave: one random unit every N seconds.
@export var bot_pressure_interval: float = 6.0

@export_group("Rewards")
@export var coins_per_kill: int = 1
@export var lose_reward_ratio: float = 0.3
## Win bonus per star: +10% of the reward for each star (3 stars → +30%).
@export var star_coin_bonus: float = 0.1
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
