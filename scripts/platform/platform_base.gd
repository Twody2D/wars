class_name PlatformBase
extends Node
## Platform backend interface (SPEC 14). The `Platform` autoload delegates here.
## Real Yandex backend comes in T14; editor and tests use PlatformMock.

signal rewarded(tag: StringName)
signal rewarded_failed(tag: StringName)
signal paused
signal resumed


func init() -> void:
	pass


## LoadingAPI.ready()
func ready_to_play() -> void:
	pass


func gameplay_start() -> void:
	pass


func gameplay_stop() -> void:
	pass


func show_interstitial() -> void:
	pass


func show_rewarded(_tag: StringName) -> void:
	pass


func get_lang() -> String:
	return "ru"


func load_cloud() -> Dictionary:
	return {}


func save_cloud(_data: Dictionary) -> void:
	pass


func set_leaderboard_score(_stars_total: int) -> void:
	pass
