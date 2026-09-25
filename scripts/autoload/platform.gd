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
