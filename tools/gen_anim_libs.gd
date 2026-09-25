extends SceneTree
## Generates anim/humanoid.tres, slime.tres, spider.tres, bomber.tres (SPEC 10).
## Run: "$GODOT" --headless --path . -s res://tools/gen_anim_libs.gd
##
## Node layout expected (built by UnitVisual):
##   UnitVisual/Rig/Parts/<Part>/S   — Rig: whole-body motion, S: the part sprite.
## Positions in SPEC are screen px; Parts is scaled 0.5, so part offsets ×2.

const PART_PX := 2.0
const UPPER := ["Body", "Head", "ArmFront", "ArmBack", "TeamAccent"]
const HIT_PATHS := ["Rig/Parts:modulate", "Rig:position:x"]


func _init() -> void:
	_save(_humanoid(), "res://anim/humanoid.tres")
	_save(_slime(), "res://anim/slime.tres")
	_save(_spider(), "res://anim/spider.tres")
	_save(_bomber(), "res://anim/bomber.tres")
	quit()


func _save(lib: AnimationLibrary, path: String) -> void:
	_fill_defaults(lib)
	var err: Error = ResourceSaver.save(lib, path)
	print("%s -> %s" % [path, error_string(err)])


# --- libraries -------------------------------------------------------------

func _humanoid() -> AnimationLibrary:
	var lib := AnimationLibrary.new()

	var walk := _anim(0.6, true)
	var t5: Array[float] = [0.0, 0.15, 0.3, 0.45, 0.6]
	_rot(walk, "LegFront", t5, [0, -25, 0, 25, 0])
	_rot(walk, "LegBack", t5, [0, 25, 0, -25, 0])
	_rot(walk, "ArmFront", t5, [0, 20, 0, -20, 0])
	_rot(walk, "ArmBack", t5, [0, -20, 0, 20, 0])
	_rot(walk, "Head", t5, [0, 2, 0, -2, 0])
	_bob(walk, t5, [0, -3, 0, -3, 0])
	lib.add_animation(&"walk", walk)

	var idle := _anim(1.2, true)
	var t3: Array[float] = [0.0, 0.6, 1.2]
	_bob(idle, t3, [0, -2, 0])
	_rot(idle, "Head", t3, [0, 2, 0])
	lib.add_animation(&"idle", idle)

	var attack := _anim(0.5, false)
	var ta: Array[float] = [0.0, 0.2, 0.3, 0.5]
	_rot(attack, "ArmFront", ta, [0, 120, -40, 0])
	_rot(attack, "Body", ta, [0, -5, 8, 0])
	_call(attack, 0.3, &"_on_hit_frame")
	lib.add_animation(&"attack", attack)

	lib.add_animation(&"hit", _hit())
	lib.add_animation(&"die", _die(-90.0))
	return lib


func _slime() -> AnimationLibrary:
	var lib := AnimationLibrary.new()

	var walk := _anim(0.6, true)
	var t5: Array[float] = [0.0, 0.15, 0.3, 0.45, 0.6]
	_track(walk, "Rig:scale", t5, [Vector2(1.15, 0.85), Vector2(0.9, 1.1), Vector2.ONE, Vector2(0.95, 1.05), Vector2(1.15, 0.85)])
	_track(walk, "Rig:position:y", t5, [0.0, -8.0, -12.0, -8.0, 0.0])
	lib.add_animation(&"walk", walk)

	var idle := _anim(1.2, true)
	var t3: Array[float] = [0.0, 0.6, 1.2]
	_track(idle, "Rig:scale", t3, [Vector2.ONE, Vector2(1.05, 0.95), Vector2.ONE])
	lib.add_animation(&"idle", idle)

	var attack := _anim(0.5, false)
	var ta: Array[float] = [0.0, 0.2, 0.3, 0.5]
	_track(attack, "Rig:scale", ta, [Vector2.ONE, Vector2(0.85, 1.15), Vector2(1.25, 0.8), Vector2.ONE])
	_track(attack, "Rig:position:y", ta, [0.0, -6.0, 0.0, 0.0])
	_call(attack, 0.3, &"_on_hit_frame")
	lib.add_animation(&"attack", attack)

	lib.add_animation(&"hit", _hit())
	var die := _die(0.0)
	_track(die, "Rig:scale", [0.0, 0.3] as Array[float], [Vector2.ONE, Vector2(1.4, 0.3)])
	lib.add_animation(&"die", die)
	return lib


func _spider() -> AnimationLibrary:
	var lib := AnimationLibrary.new()

	var walk := _anim(0.3, true)
	var t5: Array[float] = [0.0, 0.075, 0.15, 0.225, 0.3]
	for i: int in range(1, 9):
		var sign_: float = 1.0 if i % 2 == 1 else -1.0
		_rot(walk, "Leg%d" % i, t5, [0, 20 * sign_, 0, -20 * sign_, 0])
	_track(walk, "Rig/Parts/Body/S:position:y", t5, [0.0, -2.0 * PART_PX, 0.0, -2.0 * PART_PX, 0.0])
	_track(walk, "Rig/Parts/TeamAccent/S:position:y", t5, [0.0, -2.0 * PART_PX, 0.0, -2.0 * PART_PX, 0.0])
	lib.add_animation(&"walk", walk)

	var idle := _anim(1.2, true)
	var t3: Array[float] = [0.0, 0.6, 1.2]
	_track(idle, "Rig/Parts/Body/S:position:y", t3, [0.0, -1.0 * PART_PX, 0.0])
	_track(idle, "Rig/Parts/TeamAccent/S:position:y", t3, [0.0, -1.0 * PART_PX, 0.0])
	lib.add_animation(&"idle", idle)

	var attack := _anim(0.5, false)
	var ta: Array[float] = [0.0, 0.2, 0.3, 0.5]
	_track(attack, "Rig:rotation", ta, [0.0, deg_to_rad(8.0), deg_to_rad(-10.0), 0.0])
	_rot(attack, "Leg1", ta, [0, -30, 20, 0])
	_rot(attack, "Leg2", ta, [0, -30, 20, 0])
	_call(attack, 0.3, &"_on_hit_frame")
	lib.add_animation(&"attack", attack)

	lib.add_animation(&"hit", _hit())
	lib.add_animation(&"die", _die(180.0))
	return lib


func _bomber() -> AnimationLibrary:
	var lib := AnimationLibrary.new()

	var walk := _anim(0.6, true)
	var t5: Array[float] = [0.0, 0.15, 0.3, 0.45, 0.6]
	_track(walk, "Rig:rotation", t5, [0.0, deg_to_rad(10.0), 0.0, deg_to_rad(-10.0), 0.0])
	_rot(walk, "LegFront", t5, [0, -25, 0, 25, 0])
	_rot(walk, "LegBack", t5, [0, 25, 0, -25, 0])
	_fuse(walk, 0.6)
	lib.add_animation(&"walk", walk)

	var idle := _anim(1.2, true)
	_fuse(idle, 1.2)
	lib.add_animation(&"idle", idle)

	var attack := _anim(0.4, false)
	var ta: Array[float] = [0.0, 0.4]
	_track(attack, "Rig:scale", ta, [Vector2.ONE, Vector2(1.3, 1.3)])
	_fuse(attack, 0.4)
	_call(attack, 0.4, &"_on_hit_frame")
	lib.add_animation(&"attack", attack)

	lib.add_animation(&"hit", _hit())
	var die := _die(0.0)
	_track(die, "Rig:scale", [0.0, 0.1] as Array[float], [Vector2(1.3, 1.3), Vector2(1.5, 1.5)])
	lib.add_animation(&"die", die)
	return lib


# --- shared animations -----------------------------------------------------

func _hit() -> Animation:
	var hit := _anim(0.2, false)
	var t: Array[float] = [0.0, 0.2]
	_track(hit, "Rig/Parts:modulate", t, [Color(1, 0.5, 0.5), Color.WHITE])
	_track(hit, "Rig:position:x", t, [-4.0, 0.0])
	return hit


func _die(fall_deg: float) -> Animation:
	var die := _anim(0.6, false)
	_track(die, "Rig:rotation", [0.0, 0.3] as Array[float], [0.0, deg_to_rad(fall_deg)])
	_track(die, "Rig:position:y", [0.0, 0.3] as Array[float], [0.0, 20.0 if fall_deg != 0.0 else 0.0])
	_track(die, "Rig:modulate", [0.0, 0.3, 0.6] as Array[float], [Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	_call(die, 0.4, &"_spawn_poof")
	_call(die, 0.6, &"_on_die_finished")
	return die


func _fuse(anim: Animation, length: float) -> void:
	var times: Array[float] = []
	var values: Array = []
	var t := 0.0
	var bright := true
	while t <= length + 0.001:
		times.append(t)
		values.append(Color(1.6, 1.4, 0.8) if bright else Color.WHITE)
		bright = not bright
		t += 0.1
	var track: int = _track(anim, "Rig/Parts/Fuse/S:modulate", times, values)
	anim.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)


# --- helpers ---------------------------------------------------------------

func _anim(length: float, loop: bool) -> Animation:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	return anim


func _track(anim: Animation, path: String, times: Array[float], values: Array) -> int:
	var track: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath(path))
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	for i: int in times.size():
		anim.track_insert_key(track, times[i], values[i])
	return track


func _rot(anim: Animation, part: String, times: Array[float], degrees: Array) -> void:
	var values: Array = []
	for d: float in degrees:
		values.append(deg_to_rad(d))
	_track(anim, "Rig/Parts/%s/S:rotation" % part, times, values)


## Body bob in screen px, applied to every upper-body part so they stay attached.
func _bob(anim: Animation, times: Array[float], px: Array) -> void:
	var values: Array = []
	for p: float in px:
		values.append(p * PART_PX)
	for part: String in UPPER:
		_track(anim, "Rig/Parts/%s/S:position:y" % part, times, values)


func _call(anim: Animation, time: float, method: StringName) -> void:
	var track: int = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track, NodePath("."))
	anim.track_insert_key(track, time, {"method": method, "args": []})


## Every value track used anywhere in the library (except "hit") gets a constant
## default key in animations that don't animate it, so switching animations never
## leaves a limb stuck in the previous pose.
func _fill_defaults(lib: AnimationLibrary) -> void:
	var defaults: Dictionary[String, Variant] = {}
	for anim_name: StringName in lib.get_animation_list():
		if anim_name == &"hit":
			continue
		var anim: Animation = lib.get_animation(anim_name)
		for track: int in anim.get_track_count():
			if anim.track_get_type(track) != Animation.TYPE_VALUE:
				continue
			var path := String(anim.track_get_path(track))
			if path not in HIT_PATHS:
				defaults[path] = _default_for(path)
	for anim_name: StringName in lib.get_animation_list():
		if anim_name == &"hit":
			continue
		var anim: Animation = lib.get_animation(anim_name)
		for path: String in defaults:
			if anim.find_track(NodePath(path), Animation.TYPE_VALUE) == -1:
				var track: int = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(track, NodePath(path))
				anim.track_insert_key(track, 0.0, defaults[path])


func _default_for(path: String) -> Variant:
	if path.ends_with(":scale"):
		return Vector2.ONE
	if path.ends_with(":modulate"):
		return Color.WHITE
	return 0.0
