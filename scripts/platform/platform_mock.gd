class_name PlatformMock
extends PlatformBase
## Editor/test backend: ads are "watched" instantly and always reward;
## purchases go through at once (prices from ProductData.mock_price).

const SHOP_PATH := "res://data/shop/shop.tres"

## The mock "server": purchases not consumed yet.
var purchases: Array[Dictionary] = []
var _last_token: int = 0


func show_rewarded(tag: StringName) -> void:
	paused.emit()
	await get_tree().create_timer(0.3, true, false, true).timeout
	resumed.emit()
	rewarded.emit(tag)


func get_lang() -> String:
	var locale: String = OS.get_locale_language()
	return "ru" if locale == "ru" else "en"


func get_catalog() -> Array[Dictionary]:
	var shop: ShopData = load(SHOP_PATH)
	var list: Array[Dictionary] = []
	for p: ProductData in shop.products:
		if p.kind != ProductData.Kind.FREE:
			list.append({
				"id": String(p.id),
				"price": "%d YAN" % p.mock_price,
				"priceValue": str(p.mock_price),
				"priceCurrencyCode": "YAN",
				"currencyImage": "",
			})
	return list


func purchase(id: StringName) -> void:
	_last_token += 1
	var token: String = "mock-%d" % _last_token
	purchases.append({"productID": String(id), "purchaseToken": token})
	purchase_done.emit.call_deferred(id, token)


func get_purchases() -> Array[Dictionary]:
	return purchases.duplicate(true)


func consume(token: String) -> void:
	for i: int in purchases.size():
		if purchases[i].get("purchaseToken", "") == token:
			purchases.remove_at(i)
			return
