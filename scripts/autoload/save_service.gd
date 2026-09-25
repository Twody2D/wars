extends Node
## Local JSON save with validation and a backup copy (SPEC 13).
## Only knows about dictionaries; GameState owns the meaning of the fields.

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"


func save(data: Dictionary) -> void:
	data["schema_version"] = SCHEMA_VERSION
	var text := JSON.stringify(data, "\t")
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: cannot write %s (%s)" % [SAVE_PATH, error_string(FileAccess.get_open_error())])
		return
	file.store_string(text)


## Returns the saved dictionary, the backup if the main file is broken, or {}.
func load_data() -> Dictionary:
	var data: Dictionary = _read(SAVE_PATH)
	if data.is_empty() and FileAccess.file_exists(SAVE_PATH):
		push_warning("SaveService: save is broken, using backup")
		data = _read(BACKUP_PATH)
	return data


func clear() -> void:
	for path: String in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}
