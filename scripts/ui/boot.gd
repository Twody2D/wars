extends Node
## Boot (SPEC 8): save is already loaded by GameState; pick the language,
## tell the platform we are ready, open the menu.

const MENU_SCENE := "res://scenes/menu/main.tscn"


func _ready() -> void:
	var lang: String = GameState.lang if GameState.lang != "" else Platform.get_lang()
	TranslationServer.set_locale(lang if lang in ["ru", "en"] else "ru")
	AudioServer.set_bus_mute(0, not GameState.sound_on)
	Platform.ready_to_play()
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)
