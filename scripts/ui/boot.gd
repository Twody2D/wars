extends Node
## Boot (SPEC 8): the local save is already loaded by GameState. Wait for the
## platform, take the cloud save if it is newer, deliver pending purchases, take the language from the SDK, tell the
## platform we are ready (LoadingAPI.ready), open the menu.

const MENU_SCENE := "res://scenes/menu/main.tscn"


func _ready() -> void:
	Platform.update_mute()
	if not Platform.is_initialized:
		await Platform.initialized
	var cloud: Dictionary = await Platform.load_cloud()
	GameState.merge_cloud(cloud)
	# Yandex 1.13: purchases not processed yet are granted and consumed, the
	# forever ones restore their flags — at every launch, after the cloud.
	await Platform.restore_purchases()
	# Yandex 2.14: the language comes from the SDK at launch (no in-game switch).
	var lang: String = Platform.get_lang()
	TranslationServer.set_locale(lang if lang in ["ru", "en"] else "ru")
	Platform.update_mute()
	Platform.ready_to_play()
	get_tree().change_scene_to_file(MENU_SCENE)
