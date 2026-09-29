class_name ShopData
extends Resource
## The shop (T20): products in screen order and the shop numbers.

## Starter pack first (the big card), then the forever items, the coin packs
## and the free coins for an ad.
@export var products: Array[ProductData] = []
## "Coins for an ad" can be taken once per this many seconds.
@export var free_coins_cooldown_sec: int = 900
## Battle coins multiplier of the golden pickaxe.
@export var gold_pickaxe_coin_mult: float = 2.0
## The starter pack is offered once, after a win on this level.
@export var starter_offer_level: int = 3
## How many consumed purchase tokens the save remembers (a purchase delivered
## twice by the SDK is granted once).
@export var remembered_tokens: int = 32


func product(id: StringName) -> ProductData:
	for p: ProductData in products:
		if p.id == id:
			return p
	return null
