extends Node
## Single entry point to the game platform (Yandex Games SDK), SPEC 14.
## Picks a backend at startup; the rest of the game only talks to this node.

signal rewarded(tag: StringName)
signal rewarded_failed(tag: StringName)
signal paused
signal resumed

var backend: PlatformBase


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	backend = PlatformMock.new()
	add_child(backend)
	backend.rewarded.connect(rewarded.emit)
	backend.rewarded_failed.connect(rewarded_failed.emit)
	backend.paused.connect(paused.emit)
	backend.resumed.connect(resumed.emit)
	backend.init()


## Window/tab lost focus (Yandex 1.3, 4.7): silence at once, pause the battle.
## Sound comes back on focus; the battle stays paused until the player resumes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		AudioServer.set_bus_mute(0, true)
		paused.emit()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		AudioServer.set_bus_mute(0, not GameState.sound_on)


## Ask the current scene to pause (e.g. the rotate overlay); same path as the SDK pause.
func request_pause() -> void:
	paused.emit()


func ready_to_play() -> void:
	backend.ready_to_play()


func gameplay_start() -> void:
	backend.gameplay_start()


func gameplay_stop() -> void:
	backend.gameplay_stop()


func show_interstitial() -> void:
	backend.show_interstitial()


func show_rewarded(tag: StringName) -> void:
	backend.show_rewarded(tag)


func get_lang() -> String:
	return backend.get_lang()
