extends Node
## Single entry point to the game platform (Yandex Games SDK), SPEC 14.
## Picks a backend at startup; the rest of the game only talks to this node.

signal rewarded(tag: StringName)
signal rewarded_failed(tag: StringName)
## The game must pause now (SDK pause, ad on screen, focus lost, portrait).
signal paused
signal resumed
signal initialized

var backend: PlatformBase
## Backend init finished (the boot scene waits for it).
var is_initialized: bool = false

var _unfocused: bool = false
var _sdk_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Web export → Yandex bridge (falls back to offline itself); editor/tests → mock.
	if OS.has_feature("web"):
		backend = PlatformYandex.new()
	else:
		backend = PlatformMock.new()
	add_child(backend)
	backend.rewarded.connect(rewarded.emit)
	backend.rewarded_failed.connect(rewarded_failed.emit)
	backend.paused.connect(_on_backend_paused)
	backend.resumed.connect(_on_backend_resumed)
	backend.initialized.connect(_on_initialized, CONNECT_ONE_SHOT)
	backend.init()


## Window/tab lost focus (Yandex 1.3, 4.7): silence at once, pause the battle.
## Sound comes back on focus; the battle stays paused until the player resumes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_unfocused = true
		update_mute()
		paused.emit()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_unfocused = false
		update_mute()


## Master bus is silent when sound is off, the window has no focus, or the
## platform paused the game (an ad is on screen).
func update_mute() -> void:
	AudioServer.set_bus_mute(0, not GameState.sound_on or _unfocused or _sdk_paused)


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


## Cloud save ({} if none or unavailable). May take a moment: use with await.
func load_cloud() -> Dictionary:
	var data: Dictionary = await backend.load_cloud()
	return data


func save_cloud(data: Dictionary) -> void:
	backend.save_cloud(data)


func set_leaderboard_score(stars_total: int) -> void:
	backend.set_leaderboard_score(stars_total)


func _on_initialized() -> void:
	is_initialized = true
	initialized.emit()


func _on_backend_paused() -> void:
	_sdk_paused = true
	update_mute()
	paused.emit()


func _on_backend_resumed() -> void:
	_sdk_paused = false
	update_mute()
	resumed.emit()
