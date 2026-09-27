extends SceneTree
## Generates data/units/*.tres, data/balance.tres, data/upgrades/*.tres from SPEC 3, 4, 7.
## Starting values only: after generation the .tres files are the source of truth
## and are tuned in the editor. Re-running overwrites them.
## Run: "$GODOT" --headless --path . -s res://tools/gen_data.gd

# id: [hp, damage, cooldown, range, speed, cost, unlock_cost, unlock_biome, splash, projectile, explodes, hit_delay, boss]
const UNITS: Dictionary[String, Array] = {
	"zombie": [60, 8, 1.0, 20, 40, 3, 0, 1, 0, "", false, 0.3, false],
	"skeleton": [50, 14, 1.2, 180, 38, 5, 0, 1, 0, "arrow", false, 0.3, false],
	"slime": [150, 5, 1.2, 20, 30, 7, 1500, 1, 0, "", false, 0.3, false],
	"spider": [40, 6, 0.6, 18, 70, 4, 3000, 1, 0, "", false, 0.3, false],
	"goblin_miner": [55, 12, 1.6, 120, 38, 6, 5000, 2, 0, "pickaxe", false, 0.3, false],
	"barrel_bomber": [30, 60, 1.0, 20, 45, 8, 8000, 2, 60, "", true, 0.4, false],
	"boss_zombie_king": [1200, 30, 1.5, 30, 20, 0, 0, 1, 40, "", false, 0.5, true],
	"boss_stone_golem": [2000, 45, 2.0, 35, 18, 0, 0, 2, 50, "", false, 0.5, true],
}

# id: [base_cost, max_level, per_level, one_time]
const UPGRADES: Dictionary[String, Array] = {
	"army_power": [200, 10, 0.1, false],
	"food_rate": [300, 10, 0.05, false],
	"base_hp": [200, 10, 5.0, false],
	"start_food": [400, 5, 3.0, false],
	"unit_level": [500, 4, 0.1, false],
	"battle_speed": [6000, 1, 1.5, true],
}


func _init() -> void:
	for id: String in UNITS:
		_save(_unit(id, UNITS[id]), "res://data/units/%s.tres" % id)
	# balance.tres is tuned by hand in the editor — only create it if missing.
	if not ResourceLoader.exists("res://data/balance.tres"):
		_save(BalanceData.new(), "res://data/balance.tres")
	for id: String in UPGRADES:
		var row: Array = UPGRADES[id]
		var up := UpgradeData.new()
		up.id = StringName(id)
		up.name_key = "UPGRADE_" + id.to_upper()
		up.base_cost = row[0]
		up.max_level = row[1]
		up.per_level = row[2]
		up.one_time = row[3]
		up.icon = load("res://art/ui/upgrades/upgrade_%s.svg" % id)
		_save(up, "res://data/upgrades/%s.tres" % id)
	quit()


func _unit(id: String, row: Array) -> UnitData:
	var u := UnitData.new()
	u.id = StringName(id)
	u.name_key = "UNIT_" + id.to_upper()
	u.hp = row[0]
	u.damage = row[1]
	u.cooldown = row[2]
	u.attack_range = row[3]
	u.speed = row[4]
	u.cost = row[5]
	u.unlock_cost = row[6]
	u.unlock_biome = row[7]
	u.splash_radius = row[8]
	var proj: String = row[9]
	u.projectile = StringName(proj)
	u.explodes = row[10]
	u.hit_delay = row[11]
	u.is_boss = row[12]
	u.visual = load("res://art/units/%s/%s_visual.tscn" % [id, id])
	u.portrait = load("res://art/units/%s/portrait.svg" % id)
	return u


func _save(res: Resource, path: String) -> void:
	print("%s -> %s" % [path, error_string(ResourceSaver.save(res, path))])
