class_name BattleSim
extends RefCounted
## Headless battle logic (SPEC 3, 4). Fixed-step, deterministic by seed.
## Nodes only listen to signals and read state; nothing here touches the scene.
##
## Sides: PLAYER on the left moving right, BOT on the right moving left.
## Damage lands after `UnitData.hit_delay`, which matches the attack
## animation's hit frame — the view plays the swing, the sim owns the numbers.

signal unit_spawned(unit: SimUnit)
signal unit_attack_started(unit: SimUnit)
signal unit_damaged(unit: SimUnit, amount: float)
## killed = false for self-destruction (bomber).
signal unit_died(unit: SimUnit, killed: bool)
signal projectile_spawned(projectile: SimProjectile)
signal projectile_finished(projectile: SimProjectile)
signal explosion(x: float, radius: float, side: int)
signal base_damaged(side: int, amount: float)
signal meteor_cast(at: Vector2)
signal meteor_impact(at: Vector2)
signal battle_over(winner: int)

const PLAYER := 0
const BOT := 1
const NONE := -1
## Extra reach so a target that stepped back during the swing still gets hit.
const HIT_TOLERANCE := 10.0
## Units may overlap enemies slightly before stopping.
const BEHIND_TOLERANCE := 8.0

var balance: BalanceData
var setup: BattleSetup
var rng := RandomNumberGenerator.new()
var time: float = 0.0
var units: Array[SimUnit] = []
var projectiles: Array[SimProjectile] = []
var base_hp: Array[float] = [0.0, 0.0]
## Seconds left while the player's base ignores hits (BalanceData.player_base_hit_interval).
var base_guard: float = 0.0
var base_max_hp: Array[float] = [0.0, 0.0]
## Enemies killed by each side (bomber self-destruction doesn't count).
var kills: Array[int] = [0, 0]
var winner: int = NONE

# Player economy (SPEC 4)
var food: float = 0.0
var food_rate: float = 0.0
var food_max: float = 0.0
var card_cooldowns: Dictionary[StringName, float] = {}
var ore_cooldowns: Array[float] = []
var meteor_charges: int = 0
var meteor_timer: float = 0.0
## Falling meteors: [position, seconds left]
var _meteors: Array[Array] = []

var _next_uid: int = 1
var _accumulator: float = 0.0
## Alive units per side, front first (see _sort_sides).
var _front_order: Array[Array] = [[], []]


func _init(setup_: BattleSetup) -> void:
	setup = setup_
	balance = setup_.balance
	rng.seed = setup_.rng_seed
	base_hp = [setup_.player_base_hp, setup_.level.bot_base_hp]
	base_max_hp = base_hp.duplicate()
	food = maxf(setup_.start_food, setup_.level.min_start_food if setup_.level != null else 0.0)
	food_rate = setup_.food_rate
	food_max = setup_.food_max
	ore_cooldowns.resize(setup_.level.ore_blocks)
	ore_cooldowns.fill(0.0)
	meteor_charges = 1


func is_over() -> bool:
	return winner != NONE


## Advances by real time in fixed steps; returns the number of steps taken.
func advance(delta: float) -> int:
	_accumulator += delta
	var steps := 0
	while _accumulator >= balance.sim_dt and not is_over():
		_accumulator -= balance.sim_dt
		step(balance.sim_dt)
		steps += 1
	return steps


func step(dt: float) -> void:
	if is_over():
		return
	time += dt
	base_guard = maxf(base_guard - dt, 0.0)
	_step_economy(dt)
	_sort_sides()
	for unit: SimUnit in units:
		if unit.is_alive():
			_step_unit(unit, dt)
	_step_projectiles(dt)
	_step_meteors(dt)
	_remove_dead()
	_check_winner()


# --- spawning & player actions --------------------------------------------

func alive_count(side: int) -> int:
	var count := 0
	for unit: SimUnit in units:
		if unit.side == side and unit.is_alive():
			count += 1
	return count


func can_spawn(side: int) -> bool:
	return not is_over() and alive_count(side) < balance.unit_limit


## power — extra HP/damage multiplier (bot difficulty, LevelData.bot_power).
func spawn(side: int, data: UnitData, level: int = 1, power: float = 1.0) -> SimUnit:
	if not can_spawn(side):
		return null
	var unit := SimUnit.new()
	unit.uid = _next_uid
	_next_uid += 1
	unit.data = data
	unit.side = side
	unit.level = clampi(level, 1, balance.unit_max_level)
	unit.dir = 1.0 if side == PLAYER else -1.0
	unit.x = balance.lane_start_x if side == PLAYER else balance.lane_end_x
	unit.y_offset = rng.randf_range(-balance.y_jitter, balance.y_jitter)
	var mult: float = (1.0 + balance.unit_level_bonus * (unit.level - 1)) * power
	unit.max_hp = data.hp * mult
	unit.hp = unit.max_hp
	unit.damage = data.damage * mult
	units.append(unit)
	unit_spawned.emit(unit)
	return unit


## Why a card can't be bought right now; &"" — it can.
func buy_block_reason(data: UnitData) -> StringName:
	if is_over():
		return &"over"
	if card_cooldowns.get(data.id, 0.0) > 0.0:
		return &"cooldown"
	if alive_count(PLAYER) >= balance.unit_limit:
		return &"limit"
	if food < data.cost:
		return &"food"
	return &""


func buy(data: UnitData) -> SimUnit:
	if buy_block_reason(data) != &"":
		return null
	food -= data.cost
	card_cooldowns[data.id] = balance.card_cooldown
	return spawn(PLAYER, data, setup.level_of(data), setup.player_power)


func tap_ore(index: int) -> bool:
	if is_over() or index < 0 or index >= ore_cooldowns.size() or ore_cooldowns[index] > 0.0:
		return false
	ore_cooldowns[index] = balance.ore_cooldown
	food = minf(food + balance.ore_food, food_max)
	return true


## Meteor: cast now, lands after meteor_fall_time and hits bot units
## within the radius of the point.
func cast_meteor(at: Vector2) -> bool:
	if is_over() or meteor_charges <= 0:
		return false
	meteor_charges -= 1
	_meteors.append([at, balance.meteor_fall_time])
	meteor_cast.emit(at)
	return true


func _step_meteors(dt: float) -> void:
	var landed: Array[Array] = []
	for m: Array in _meteors:
		var left: float = m[1]
		m[1] = left - dt
		if left - dt <= 0.0:
			landed.append(m)
	for m: Array in landed:
		_meteors.erase(m)
		var at: Vector2 = m[0]
		meteor_impact.emit(at)
		for unit: SimUnit in units:
			if unit.side == BOT and unit.is_alive():
				var pos := Vector2(unit.x, balance.lane_y + unit.y_offset)
				if pos.distance_to(at) <= balance.meteor_radius:
					_damage_unit(unit, balance.meteor_damage, PLAYER)


func add_food(amount: float) -> void:
	food = minf(food + amount, food_max)


# --- step internals --------------------------------------------------------

func _step_economy(dt: float) -> void:
	food = minf(food + food_rate * dt, food_max)
	for id: StringName in card_cooldowns:
		card_cooldowns[id] = maxf(card_cooldowns[id] - dt, 0.0)
	for i: int in ore_cooldowns.size():
		ore_cooldowns[i] = maxf(ore_cooldowns[i] - dt, 0.0)
	if meteor_charges < balance.meteor_max_charges:
		meteor_timer += dt
		if meteor_timer >= balance.meteor_recharge:
			meteor_timer = 0.0
			meteor_charges += 1
	else:
		meteor_timer = 0.0


func _step_unit(unit: SimUnit, dt: float) -> void:
	unit.cooldown_left -= dt
	if unit.hit_timer >= 0.0:
		unit.hit_timer -= dt
		if unit.hit_timer <= 0.0:
			unit.hit_timer = -1.0
			_resolve_hit(unit)
			if not unit.is_alive():
				return
		else:
			return # mid-swing: stand still

	var enemy: SimUnit = _nearest_enemy_ahead(unit)
	var in_range_unit: bool = enemy != null and unit.ahead(enemy.x) <= unit.data.attack_range
	var in_range_base: bool = _base_distance(unit) <= unit.data.attack_range
	if in_range_unit or in_range_base:
		unit.state = SimUnit.State.ATTACK
		unit.target = enemy if in_range_unit else null
		unit.target_base = not in_range_unit
		if unit.cooldown_left <= 0.0:
			unit.cooldown_left = unit.data.cooldown
			unit.hit_timer = unit.data.hit_delay
			unit_attack_started.emit(unit)
		return

	unit.target = null
	unit.target_base = false
	if _friend_blocking(unit):
		unit.state = SimUnit.State.WAIT
		return
	unit.state = SimUnit.State.WALK
	unit.x = clampf(unit.x + unit.data.speed * unit.dir * dt, balance.lane_start_x, balance.lane_end_x)


func _resolve_hit(unit: SimUnit) -> void:
	var enemy_side: int = 1 - unit.side
	if unit.data.explodes:
		_explode(unit)
		return
	# Re-validate the target: it may have died or moved during the swing.
	var reach: float = unit.data.attack_range + HIT_TOLERANCE
	var target: SimUnit = unit.target
	if unit.target_base:
		if _base_distance(unit) > reach:
			return
	elif target == null or not target.is_alive() or unit.ahead(target.x) > reach:
		target = _nearest_enemy_ahead(unit)
		if target == null or unit.ahead(target.x) > reach:
			if _base_distance(unit) > reach:
				return
			target = null
	var hits_base: bool = target == null

	if unit.data.is_ranged():
		_fire(unit, target, hits_base)
		return
	if hits_base:
		_damage_base(enemy_side, unit.damage)
	elif unit.data.splash_radius > 0.0:
		_splash(target.x, unit.data.splash_radius, unit.damage, unit.side)
	else:
		_damage_unit(target, unit.damage, unit.side)


func _fire(unit: SimUnit, target: SimUnit, hits_base: bool) -> void:
	var p := SimProjectile.new()
	p.uid = _next_uid
	_next_uid += 1
	p.kind = unit.data.projectile
	p.side = unit.side
	p.damage = unit.damage
	p.splash = unit.data.splash_radius
	p.target = target
	p.target_base = hits_base
	p.start_x = unit.x
	p.x = unit.x
	p.y_offset = unit.y_offset
	p.target_x = _enemy_base_front(unit.side) if hits_base else target.x
	p.duration = maxf(absf(p.target_x - p.start_x) / balance.projectile_speed, 0.05)
	projectiles.append(p)
	projectile_spawned.emit(p)


func _step_projectiles(dt: float) -> void:
	var finished: Array[SimProjectile] = []
	for p: SimProjectile in projectiles:
		p.elapsed += dt
		if p.target != null and p.target.is_alive():
			p.target_x = p.target.x
		p.x = lerpf(p.start_x, p.target_x, p.progress())
		if p.elapsed >= p.duration:
			finished.append(p)
	for p: SimProjectile in finished:
		projectiles.erase(p)
		if p.target_base:
			_damage_base(1 - p.side, p.damage)
		elif p.target != null and p.target.is_alive():
			if p.splash > 0.0:
				_splash(p.target.x, p.splash, p.damage, p.side)
			else:
				_damage_unit(p.target, p.damage, p.side)
		projectile_finished.emit(p)


func _explode(unit: SimUnit) -> void:
	var radius: float = unit.data.splash_radius
	explosion.emit(unit.x, radius, unit.side)
	_splash(unit.x, radius, unit.damage, unit.side)
	if _base_distance(unit) <= radius:
		_damage_base(1 - unit.side, unit.damage)
	_kill(unit, false, NONE)


func _splash(center_x: float, radius: float, amount: float, attacker_side: int) -> void:
	for other: SimUnit in units:
		if other.side != attacker_side and other.is_alive() and absf(other.x - center_x) <= radius:
			_damage_unit(other, amount, attacker_side)


func _damage_unit(unit: SimUnit, amount: float, attacker_side: int) -> void:
	if not unit.is_alive():
		return
	unit.hp -= amount
	unit_damaged.emit(unit, amount)
	if unit.hp <= 0.0:
		_kill(unit, true, attacker_side)


func _kill(unit: SimUnit, killed: bool, killer_side: int) -> void:
	unit.hp = 0.0
	unit.state = SimUnit.State.DEAD
	unit.hit_timer = -1.0
	if killed and killer_side != NONE:
		kills[killer_side] += 1
	unit_died.emit(unit, killed)


func _damage_base(side: int, amount: float) -> void:
	if is_over():
		return
	if side == PLAYER and balance.player_base_hit > 0.0:
		if base_guard > 0.0:
			return
		amount = balance.player_base_hit
		base_guard = balance.player_base_hit_interval
	base_hp[side] = maxf(base_hp[side] - amount, 0.0)
	base_damaged.emit(side, amount)


func _remove_dead() -> void:
	var alive: Array[SimUnit] = []
	for unit: SimUnit in units:
		if unit.is_alive():
			alive.append(unit)
	units = alive


func _check_winner() -> void:
	if base_hp[BOT] <= 0.0:
		winner = PLAYER
	elif base_hp[PLAYER] <= 0.0:
		winner = BOT
	if is_over():
		battle_over.emit(winner)


# --- queries ---------------------------------------------------------------

## Front-to-back order per side; ties — older unit (lower uid) in front.
func _sort_sides() -> void:
	var player: Array[SimUnit] = []
	var bot: Array[SimUnit] = []
	for unit: SimUnit in units:
		if unit.is_alive():
			if unit.side == PLAYER:
				player.append(unit)
			else:
				bot.append(unit)
	player.sort_custom(_is_in_front)
	bot.sort_custom(_is_in_front)
	for i: int in player.size():
		player[i].rank = i
	for i: int in bot.size():
		bot[i].rank = i
	_front_order = [player, bot]


static func _is_in_front(a: SimUnit, b: SimUnit) -> bool:
	var pa: float = a.x * a.dir
	var pb: float = b.x * b.dir
	if pa == pb:
		return a.uid < b.uid
	return pa > pb


## Enemies are ordered front first, i.e. by increasing distance from us.
func _nearest_enemy_ahead(unit: SimUnit) -> SimUnit:
	for other: SimUnit in _front_order[1 - unit.side]:
		if other.is_alive() and unit.ahead(other.x) >= -BEHIND_TOLERANCE:
			return other
	return null


## Queue behind the unit ahead (wait_distance). Exception: when the units ahead
## are already fighting, join them until front_width units are in the crowd.
func _friend_blocking(unit: SimUnit) -> bool:
	var order: Array = _front_order[unit.side]
	var fighting := 0
	var i: int = unit.rank - 1
	while i >= 0:
		var other: SimUnit = order[i]
		i -= 1
		if not other.is_alive():
			continue
		var d: float = unit.ahead(other.x)
		if d < 0.0 or d >= balance.wait_distance:
			return false
		if other.state != SimUnit.State.ATTACK:
			return true
		fighting += 1
		if fighting >= balance.front_width:
			return true
	return false


func _enemy_base_front(side: int) -> float:
	return balance.lane_end_x if side == PLAYER else balance.lane_start_x


func _base_distance(unit: SimUnit) -> float:
	return unit.ahead(_enemy_base_front(unit.side))
