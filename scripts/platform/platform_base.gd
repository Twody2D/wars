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
## In-app purchase went through: the game grants `id`, then consumes `token`.
signal purchase_done(id: StringName, token: String)
## Purchase cancelled, failed or the shop is unavailable.
signal purchase_failed(id: StringName)


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


## Sticky banner on / off (shown to everyone but the "No ads" owners).
func show_banner() -> void:
	pass


func hide_banner() -> void:
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


## Products with prices (T20): [{id, price, priceValue, priceCurrencyCode,
## currencyImage}]. [] — the shop is unavailable (offline, payments off).
func get_catalog() -> Array[Dictionary]:
	return []


## Answers with purchase_done or purchase_failed.
func purchase(id: StringName) -> void:
	purchase_failed.emit.call_deferred(id)


## Purchases the platform still holds (unconsumed and forever ones):
## [{productID, purchaseToken}].
func get_purchases() -> Array[Dictionary]:
	return []


func consume(_token: String) -> void:
	pass


## Currency icon of the portal from the catalog URL; null if unavailable.
func load_image(_url: String) -> Texture2D:
	return null
