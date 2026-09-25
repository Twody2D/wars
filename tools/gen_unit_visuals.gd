extends SceneTree
## Generates art/units/<id>/<id>_visual.tscn for every unit and boss (T04).
## Run: "$GODOT" --headless --path . -s res://tools/gen_unit_visuals.gd

const VISUAL_SCRIPT := "res://scripts/battle/unit_visual.gd"
const LIBS: Dictionary[String, String] = {
	"zombie": "humanoid",
	"skeleton": "archer",
	"goblin_miner": "humanoid",
	"slime": "slime",
	"spider": "spider",
	"barrel_bomber": "bomber",
	"boss_zombie_king": "humanoid",
	"boss_stone_golem": "humanoid",
}


func _init() -> void:
	var script: Script = load(VISUAL_SCRIPT)
	for unit_id: String in LIBS:
		var lib: AnimationLibrary = load("res://anim/%s.tres" % LIBS[unit_id])
		var root := Node2D.new()
		root.name = unit_id.to_pascal_case() + "Visual"
		root.set_script(script)
		for player_name: String in ["AnimationPlayer", "HitPlayer"]:
			var player := AnimationPlayer.new()
			player.name = player_name
			player.add_animation_library(&"", lib)
			root.add_child(player)
			player.owner = root
		root.set(&"unit_id", StringName(unit_id))
		if unit_id == "zombie":
			root.set(&"override_arm_rest", true)
			root.set(&"arm_rest_deg", -80.0)
		if unit_id == "skeleton":
			root.set(&"attack_anim", &"shoot")
		if unit_id.begins_with("boss_"):
			root.set(&"anim_speed", 0.6)
		var scene := PackedScene.new()
		scene.pack(root)
		var path := "res://art/units/%s/%s_visual.tscn" % [unit_id, unit_id]
		print("%s -> %s" % [path, error_string(ResourceSaver.save(scene, path))])
		root.free()
	quit()
