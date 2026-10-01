extends SceneTree
## Products for the Yandex Games console (Инап-покупки): a CSV to upload and a
## 256×256 PNG picture of every in-app product, from data/shop/*.tres and
## the shop art. Names come from localization (ru/en, the same as in the game:
## requirement 1.13.6); descriptions and prices are in DESCRIPTIONS / the
## product's mock_price (the mockup prices — change them in the console if
## Twody picks others). "Coins for an ad" is an ad, not a product: skipped.
##
## Run: "$GODOT" --headless --path . -s res://tools/export_products.gd
## Output: build/store/products/products.csv and <id>.png
## The column names follow the console docs (id, price, title_ru, title_en,
## description_ru, description_en): compare with the sample file the console
## offers before uploading.

const OUT := "res://build/store/products/"
const SHOP := "res://data/shop/shop.tres"
const SIZE := 256
## Products drawn from two layers (as on the shop card, scenes/ui/shop_hero.tscn):
## [art rect, front picture, front rect] in the 256×256 picture.
const STARTER_LAYERS := {
	&"starter_pack": [Rect2i(48, 30, 204, 204), "res://art/ui/v3/chars/art_goblin.png", Rect2i(4, 76, 148, 150)],
}
## What the product really gives (requirement 1.13.5), ≤ 200 characters.
const DESCRIPTIONS := {
	&"starter_pack": ["Шахтёр-гоблин и 5 000 монет. Один раз", "Goblin Miner and 5,000 coins. Once"],
	&"no_ads": ["Навсегда убирает рекламу: между экранами и баннер. Реклама за награду остаётся по желанию", "Removes ads forever: between screens and the banner. Reward ads stay optional"],
	&"gold_pickaxe": ["×2 монеты за каждый бой навсегда", "×2 coins for every battle forever"],
	&"coins_small": ["2 000 монет", "2,000 coins"],
	&"coins_bag": ["8 000 монет", "8,000 coins"],
	&"coins_chest": ["25 000 монет", "25,000 coins"],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var shop: ShopData = load(SHOP)
	var lines: PackedStringArray = ["id,price,title_ru,title_en,description_ru,description_en"]
	for p: ProductData in shop.products:
		if p.kind == ProductData.Kind.FREE:
			continue
		var desc: Array = DESCRIPTIONS.get(p.id, ["", ""])
		var desc_ru: String = desc[0]
		var desc_en: String = desc[1]
		lines.append(",".join([
			String(p.id), str(p.mock_price), _csv(_tr(p.name_key, "ru")), _csv(_tr(p.name_key, "en")),
			_csv(desc_ru), _csv(desc_en),
		]))
		_picture(p).save_png(OUT + "%s.png" % p.id)
	var f := FileAccess.open(OUT + "products.csv", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("products: ", lines.size() - 1)
	quit()


## The product art; the starter pack is drawn like its shop card: the coins
## pile with the goblin in front of it.
func _picture(p: ProductData) -> Image:
	var art := Image.new()
	art.load_svg_from_string(FileAccess.get_file_as_string(p.art.resource_path), 1.0)
	if not STARTER_LAYERS.has(p.id):
		return art
	var layers: Array = STARTER_LAYERS[p.id]
	var canvas := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var art_rect: Rect2i = layers[0]
	art.resize(art_rect.size.x, art_rect.size.y, Image.INTERPOLATE_LANCZOS)
	canvas.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), art_rect.position)
	var front_path: String = layers[1]
	var front_tex: Texture2D = load(front_path)
	var front: Image = front_tex.get_image()
	front.convert(Image.FORMAT_RGBA8)
	var front_rect: Rect2i = layers[2]
	var k: float = minf(float(front_rect.size.x) / front.get_width(), float(front_rect.size.y) / front.get_height())
	front.resize(roundi(front.get_width() * k), roundi(front.get_height() * k), Image.INTERPOLATE_LANCZOS)
	var at: Vector2i = front_rect.position + Vector2i(0, front_rect.size.y - front.get_height())
	canvas.blend_rect(front, Rect2i(Vector2i.ZERO, front.get_size()), at)
	return canvas


func _tr(key: String, locale: String) -> String:
	TranslationServer.set_locale(locale)
	return tr(key)


## A CSV field: quoted, inner quotes doubled.
func _csv(text: String) -> String:
	return "\"%s\"" % text.replace("\"", "\"\"")
