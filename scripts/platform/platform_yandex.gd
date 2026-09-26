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

## True when the SDK came up; false — offline (local run, blocked SDK).
var sdk_ok: bool = false

var _yg: JavaScriptObject
var _lang: String = ""
var _reward_tag: StringName = &""
var _reward_earned: bool = false
var _reward_open: bool = false
# JavaScriptBridge callbacks must stay referenced while JS may call them.
var _cb_init: JavaScriptObject
var _cb_event: JavaScriptObject
var _cb_fullscreen: JavaScriptObject
var _cb_rewarded: JavaScriptObject
var _cb_load: JavaScriptObject


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


static func _arg(args: Array, index: int) -> String:
	if index < args.size() and args[index] is String:
		var s: String = args[index]
		return s
	return ""
