extends Node
## Boot (SPEC 8): the local save is already loaded by GameState. Wait for the
## platform, take the cloud save if it is newer, pick the language, tell the
## platform we are ready (LoadingAPI.ready), open the menu.

const MENU_SCENE := "res://scenes/menu/main.tscn"


func _ready() -> void:
	Platform.update_mute()
	if not Platform.is_initialized:
		await Platform.initialized
	var cloud: Dictionary = await Platform.load_cloud()
	GameState.merge_cloud(cloud)
	var lang: String = GameState.lang if GameState.lang != "" else Platform.get_lang()
	TranslationServer.set_locale(lang if lang in ["ru", "en"] else "ru")
	Platform.update_mute()
	Platform.ready_to_play()
	get_tree().change_scene_to_file(MENU_SCENE)
