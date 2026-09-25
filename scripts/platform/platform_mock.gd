class_name PlatformMock
extends PlatformBase
## Editor/test backend: ads are "watched" instantly and always reward.


func show_rewarded(tag: StringName) -> void:
	paused.emit()
	await get_tree().create_timer(0.3, true, false, true).timeout
	resumed.emit()
	rewarded.emit(tag)


func get_lang() -> String:
	var locale: String = OS.get_locale_language()
	return "ru" if locale == "ru" else "en"
