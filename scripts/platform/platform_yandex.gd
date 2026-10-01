class_name PlatformYandex
extends PlatformBase
## Yandex Games backend (SPEC 14): talks to window.YG from web/custom_shell.html
## through JavaScriptBridge (no eval). Every JS call answers through a callback,
## also on errors and timeouts, so nothing here waits forever.

## Leaderboard technical name in the Yandex Games console.
const LEADERBOARD := "stars"
## Yandex languages that get the Russian UI; the rest get English.
const RU_LANGS: Array[String] = ["ru", "be", "kk", "uk", "uz"]

signal _cloud_loaded(json: String)
signal _catalog_loaded(json: String)
signal _purchases_loaded(json: String)
signal _image_loaded(base64_png: String)

## True when the SDK came up; false — offline (local run, blocked SDK).
var sdk_ok: bool = false

var _yg: JavaScriptObject
var _lang: String = ""
var _reward_tag: StringName = &""
var _reward_earned: bool = false
var _reward_open: bool = false
var _purchase_id: StringName = &""
var _purchase_open: bool = false
# JavaScriptBridge callbacks must stay referenced while JS may call them.
var _cb_init: JavaScriptObject
var _cb_event: JavaScriptObject
var _cb_fullscreen: JavaScriptObject
var _cb_rewarded: JavaScriptObject
var _cb_load: JavaScriptObject
var _cb_catalog: JavaScriptObject
var _cb_purchase: JavaScriptObject
var _cb_purchases: JavaScriptObject
var _cb_image: JavaScriptObject


func init() -> void:
	_yg = JavaScriptBridge.get_interface("YG")
	if _yg == null:
		initialized.emit.call_deferred()
		return
	_cb_init = JavaScriptBridge.create_callback(_on_init)
	_cb_event = JavaScriptBridge.create_callback(_on_event)
	_cb_fullscreen = JavaScriptBridge.create_callback(_on_fullscreen)
	_cb_rewarded = JavaScriptBridge.create_callback(_on_rewarded)
	_cb_load = JavaScriptBridge.create_callback(_on_load)
	_cb_catalog = JavaScriptBridge.create_callback(_on_catalog)
	_cb_purchase = JavaScriptBridge.create_callback(_on_purchase)
	_cb_purchases = JavaScriptBridge.create_callback(_on_purchases)
	_cb_image = JavaScriptBridge.create_callback(_on_image)
	_yg.call("init", _cb_init)


func ready_to_play() -> void:
	if sdk_ok:
		_yg.call("loadingReady")


func gameplay_start() -> void:
	if sdk_ok:
		_yg.call("gameplayStart")


func gameplay_stop() -> void:
	if sdk_ok:
		_yg.call("gameplayStop")


func show_interstitial() -> void:
	if sdk_ok:
		_yg.call("showFullscreen", _cb_fullscreen)


func show_banner() -> void:
	if sdk_ok:
		_yg.call("showBanner")


func hide_banner() -> void:
	if sdk_ok:
		_yg.call("hideBanner")


func show_rewarded(tag: StringName) -> void:
	if not sdk_ok or _reward_open:
		rewarded_failed.emit.call_deferred(tag)
		return
	_reward_tag = tag
	_reward_earned = false
	_reward_open = true
	_yg.call("showRewarded", _cb_rewarded)


func get_lang() -> String:
	if _lang == "":
		return super.get_lang()
	return "ru" if _lang in RU_LANGS else "en"


func load_cloud() -> Dictionary:
	if not sdk_ok:
		return {}
	_yg.call("loadData", _cb_load)
	var json: String = await _cloud_loaded
	var parsed: Variant = JSON.parse_string(json) if json != "" else null
	if parsed is Dictionary:
		return parsed
	return {}


func save_cloud(data: Dictionary) -> void:
	if sdk_ok:
		_yg.call("saveData", JSON.stringify(data))


func set_leaderboard_score(stars_total: int) -> void:
	if sdk_ok:
		_yg.call("setScore", LEADERBOARD, stars_total)


func get_catalog() -> Array[Dictionary]:
	if not sdk_ok:
		return []
	_yg.call("getCatalog", _cb_catalog)
	var json: String = await _catalog_loaded
	return _parse_list(json)


func purchase(id: StringName) -> void:
	if not sdk_ok or _purchase_open:
		purchase_failed.emit.call_deferred(id)
		return
	_purchase_id = id
	_purchase_open = true
	_yg.call("purchase", String(id), _cb_purchase)


func get_purchases() -> Array[Dictionary]:
	if not sdk_ok:
		return []
	_yg.call("getPurchases", _cb_purchases)
	var json: String = await _purchases_loaded
	return _parse_list(json)


func consume(token: String) -> void:
	if sdk_ok and token != "":
		_yg.call("consume", token)


## The browser loads the picture (any format, CORS) and hands it over as PNG:
## the web template has no HTTPRequest, SVG or JPG (custom.build).
func load_image(url: String) -> Texture2D:
	if not sdk_ok or url == "":
		return null
	_yg.call("loadImage", url, _cb_image)
	var data: String = await _image_loaded
	return image_from_base64_png(data)


static func image_from_base64_png(data: String) -> Texture2D:
	if data == "":
		return null
	var image := Image.new()
	if image.load_png_from_buffer(Marshalls.base64_to_raw(data)) != OK:
		return null
	return ImageTexture.create_from_image(image)


# --- JS callbacks (args arrive as an Array) --------------------------------

func _on_init(args: Array) -> void:
	sdk_ok = _arg(args, 0) == "ok"
	_lang = _arg(args, 1)
	if sdk_ok:
		_yg.call("setEventHandler", _cb_event)
	initialized.emit()


func _on_event(args: Array) -> void:
	match _arg(args, 0):
		"pause":
			paused.emit()
		"resume":
			resumed.emit()


## Interstitial: the game is silent and paused while it is on screen.
func _on_fullscreen(args: Array) -> void:
	match _arg(args, 0):
		"open":
			paused.emit()
		"close", "error":
			resumed.emit()


## Rewarded: the reward goes out once, on close, only if the video was watched.
func _on_rewarded(args: Array) -> void:
	match _arg(args, 0):
		"open":
			paused.emit()
		"rewarded":
			_reward_earned = true
		"close", "error":
			if not _reward_open:
				return
			_reward_open = false
			resumed.emit()
			if _reward_earned:
				rewarded.emit(_reward_tag)
			else:
				rewarded_failed.emit(_reward_tag)


func _on_load(args: Array) -> void:
	_cloud_loaded.emit(_arg(args, 0))


func _on_catalog(args: Array) -> void:
	_catalog_loaded.emit(_arg(args, 0))


## Purchase dialog closed: cb('ok', token) or cb('fail', '').
func _on_purchase(args: Array) -> void:
	if not _purchase_open:
		return
	_purchase_open = false
	var token: String = _arg(args, 1)
	if _arg(args, 0) == "ok" and token != "":
		purchase_done.emit(_purchase_id, token)
	else:
		purchase_failed.emit(_purchase_id)


func _on_purchases(args: Array) -> void:
	_purchases_loaded.emit(_arg(args, 0))


func _on_image(args: Array) -> void:
	_image_loaded.emit(_arg(args, 0))


## JSON array of objects → typed list; anything else → [].
static func _parse_list(json: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var parser := JSON.new()
	if json == "" or parser.parse(json) != OK:
		return result
	var parsed: Variant = parser.data
	if parsed is Array:
		var items: Array = parsed
		for item: Variant in items:
			if item is Dictionary:
				result.append(item)
	return result


static func _arg(args: Array, index: int) -> String:
	if index < args.size() and args[index] is String:
		var s: String = args[index]
		return s
	return ""
