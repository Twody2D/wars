class_name Purchases
extends RefCounted
## In-app purchase delivery (T20, Yandex 1.13). `state` is GameState (or a
## private copy in tests), `backend` — the platform backend.


## A purchase went through: grant it (GameState saves locally and to the
## cloud), then consume it if it is consumable. True if something was given now.
static func deliver(state: Node, backend: PlatformBase, id: StringName, token: String) -> bool:
	var granted: bool = state.call(&"grant_product", id, token)
	var shop: ShopData = state.get(&"shop")
	var product: ProductData = shop.product(id)
	if product != null and product.is_consumable() and token != "":
		backend.consume(token)
	return granted


## At every launch (and when the shop opens): what the platform still holds —
## unconsumed purchases are granted and consumed, the forever ones restore
## their flags (a new device, cleared data). Returns the products given now.
static func restore(state: Node, backend: PlatformBase) -> Array[StringName]:
	var given: Array[StringName] = []
	var list: Array[Dictionary] = await backend.get_purchases()
	for entry: Dictionary in list:
		var id: StringName = StringName(str(entry.get("productID", "")))
		var token: String = str(entry.get("purchaseToken", ""))
		if deliver(state, backend, id, token):
			given.append(id)
	return given


## "No ads" bought: no fullscreen ads (rewarded ones stay, the player asks for them).
static func ads_allowed(state: Node) -> bool:
	var no_ads: bool = state.call(&"owns", GameState.NO_ADS)
	return not no_ads
