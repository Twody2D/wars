extends Node
## Single entry point to the game platform (Yandex Games SDK), SPEC 14.
## Picks a backend at startup; the rest of the game only talks to this node.

signal rewarded(tag: StringName)
signal rewarded_failed(tag: StringName)
## The game must pause now (SDK pause, ad on screen, focus lost, portrait).
signal paused
signal resumed
signal initialized
## A shop product was delivered (bought now or restored at launch).
signal purchased(id: StringName)
signal purchase_failed(id: StringName)
## The portal currency icon arrived (price buttons show it next to the price).
signal currency_icon_changed

var backend: PlatformBase
## Backend init finished (the boot scene waits for it).
var is_initialized: bool = false
## Last non-empty catalog (see PlatformBase.get_catalog).
var catalog: Array[Dictionary] = []
## Currency icon from the SDK (null — show the currency code as text).
var currency_icon: Texture2D

var _unfocused: bool = false
var _sdk_paused: bool = false
var _restoring: bool = false
var _icon_loading: bool = false


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
	backend.purchase_done.connect(_on_purchase_done)
	backend.purchase_failed.connect(purchase_failed.emit)
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


## Skipped once "No ads" is bought.
func show_interstitial() -> void:
	if Purchases.ads_allowed(GameState):
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


## Catalog with prices; [] — the shop is unavailable. Use with await.
func get_catalog() -> Array[Dictionary]:
	var list: Array[Dictionary] = await backend.get_catalog()
	if not list.is_empty():
		catalog = list
		if currency_icon == null and not _icon_loading:
			_load_currency_icon(str(list[0].get("currencyImage", "")))
	return catalog


## Catalog entry of a product ({} — not in the catalog).
func product_info(id: StringName) -> Dictionary:
	for entry: Dictionary in catalog:
		if str(entry.get("id", "")) == String(id):
			return entry
	return {}


## Answers with `purchased` or `purchase_failed`.
func purchase(id: StringName) -> void:
	backend.purchase(id)


## Unprocessed purchases (Yandex 1.13): at every launch and when the shop opens.
func restore_purchases() -> void:
	if _restoring:
		return
	_restoring = true
	var given: Array[StringName] = await Purchases.restore(GameState, backend)
	_restoring = false
	for id: StringName in given:
		purchased.emit(id)


func _on_purchase_done(id: StringName, token: String) -> void:
	Purchases.deliver(GameState, backend, id, token)
	purchased.emit(id)


func _load_currency_icon(url: String) -> void:
	if url == "":
		return
	_icon_loading = true
	var icon: Texture2D = await backend.load_image(url)
	_icon_loading = false
	if icon != null:
		currency_icon = icon
		currency_icon_changed.emit()


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
