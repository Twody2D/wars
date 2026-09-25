extends SceneTree
## Prints the wave composition of every level: count×unit per wave.


func _init() -> void:
	var config: GameConfig = load("res://data/game_config.tres")
	for level: LevelData in config.levels:
		var line := "L%02d:" % level.number
		for w: WaveData in level.waves:
			var parts: PackedStringArray = []
			for e: WaveEntry in w.entries:
				parts.append("%d%s" % [e.count, String(e.unit.id).left(3)])
			line += " [%s]" % " ".join(parts)
		print(line)
	quit()
