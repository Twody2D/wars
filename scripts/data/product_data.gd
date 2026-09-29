class_name ProductData
extends Resource
## One shop item (T20). `id` is the product ID in the Yandex Games console;
## the price always comes from the SDK catalog (`mock_price` is only for the
## editor and tests).

enum Kind {
	## Consumable coins pack: granted, saved, then consumed.
	COINS,
	## Forever (not consumed): restored from getPurchases() at every launch.
	PERMANENT,
	## One-time pack: consumed like coins, a flag in the save stops a second buy.
	STARTER,
	## Rewarded ad, not an in-app purchase: coins on a cooldown.
	FREE,
}

@export var id: StringName
@export var kind: Kind = Kind.COINS
## Same text as the product name in the console (requirement 1.13.6).
@export var name_key: String
## Line under the picture ("Forever", "×2 coins forever").
@export var effect_key: String
## Coins given by the product (0 — none).
@export var coins: int = 0
## Unit opened by the product (starter pack).
@export var unit_id: StringName
@export var art: Texture2D
## Corner ribbon ("HIT", "+25%"): texture and text; none if the texture is empty.
@export var ribbon: Texture2D
@export var ribbon_key: String
## Starburst sticker text on the starter pack ("−60%").
@export var sticker_key: String
## Price shown by PlatformMock (editor, tests). The game uses the SDK catalog.
@export var mock_price: int = 0


func is_consumable() -> bool:
	return kind == Kind.COINS or kind == Kind.STARTER


## Owned for good once bought: the buy button turns into "Owned".
func is_one_time() -> bool:
	return kind == Kind.PERMANENT or kind == Kind.STARTER
