class_name PlatformBase
extends Node
## Platform backend interface (SPEC 14). The `Platform` autoload delegates here.
## Real Yandex backend comes in T14; editor and tests use PlatformMock.

signal rewarded(tag: StringName)
signal rewarded_failed(tag: StringName)
signal paused
signal resumed
## init() finished (successfully or not) — the game may start.
signal initialized


func init() -> void:
	initialized.emit.call_deferred()


## LoadingAPI.ready()
func ready_to_play() -> void:
	pass


func gameplay_start() -> void:
	pass


func gameplay_stop() -> void:
	pass


func show_interstitial() -> void:
	pass


## No ads here: the reward is refused (the game must not hang waiting).
func show_rewarded(tag: StringName) -> void:
	rewarded_failed.emit.call_deferred(tag)


func get_lang() -> String:
	return "ru"


func load_cloud() -> Dictionary:
	return {}


func save_cloud(_data: Dictionary) -> void:
	pass


func set_leaderboard_score(_stars_total: int) -> void:
	pass
