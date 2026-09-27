# Mine Rush UI kit — file table

9-slice corners: T / R / B / L in px of the source SVG. "—" = not stretched.

| File | Size (px) | 9-slice corners | Where it is used |
|---|---|---|---|
| btn_play_normal.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| btn_play_hover.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| btn_play_pressed.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| btn_play_disabled.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| btn_green_normal.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| btn_green_hover.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| btn_green_pressed.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| btn_green_disabled.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| btn_grey_normal.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| btn_grey_hover.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| btn_grey_pressed.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| btn_grey_disabled.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| btn_icon_normal.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| btn_icon_hover.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| btn_icon_pressed.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| btn_icon_disabled.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| btn_purple_normal.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| btn_purple_hover.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| btn_purple_pressed.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| btn_purple_disabled.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| btn_play_glow.svg | 640×300 | — | Soft glow behind btn_play; pulse scale 0.95↔1.08, alpha 0.6↔1 |
| plate_max.svg | 180×72 | 28 / 30 / 38 / 30 | Replaces the price button on a maxed card (“МАКС”) |
| tab_active.svg | 248×118 | 34 / 36 / 44 / 36 | Selected bottom tab: raised 20px, icon 64px + label 26px |
| tab_inactive.svg | 232×102 | 32 / 34 / 42 / 34 | Unselected bottom tab: icon 56px + label 24px |
| tabbar_bg.svg | 800×100 | 44 / 44 / 0 / 44 | Dark plate behind the 3 tabs, anchored to the bottom edge |
| coin_counter.svg | 260×72 | 33 / 36 / 39 / 66 | Top-right coin plate: icon_coin 64px over the left socket, value text 34px, icon_plus 60px overlapping the right end |
| badge_dot.svg | 40×40 | — | Red “something to buy” dot on tabs / buttons (top-right corner, bob 2px) |
| ribbon_title.svg | 520×104 | 0 / 100 / 0 / 100 (3-slice, stretch width only) | Screen title (“Улучшения”); text 38px centered on the band (y 10–76) |
| plate_level.svg | 300×72 | 28 / 30 / 34 / 30 | “Уровень 7” plate above the Play button; text 34px |
| plate_boss.svg | 340×60 | 26 / 28 / 32 / 28 | Boss hint “Босс: Король зомби” under the stars (boss levels only); text 26px |
| card_unit.svg | 196×256 | 116 / 30 / 36 / 30 | Fighter card (Улучшения). Portrait window y 17–105; name 24px @ y110; stats @ y140; pips @ y172; price button 164×60 @ y198 (overhangs 8px) |
| card_unit_locked.svg | 196×256 | 116 / 30 / 36 / 30 | Locked fighter: sprite drawn black at 55% alpha + icon_lock 64px, unlock price button |
| card_unit_max.svg | 196×256 | 116 / 30 / 36 / 30 | Maxed fighter: gold frame, plate_max with “МАКС” |
| card_upgrade.svg | 402×134 | 28 / 28 / 34 / 28 | Army power-up tile: icon_well + icon 72px left, name 24px, effect 24px green, level bar, price button right |
| icon_well.svg | 96×96 | — | Soft round socket behind icons on card_upgrade / cave button |
| progress_bar_frame.svg | 200×32 | 16 / 16 / 16 / 16 | Level bar frame; “ур. 3/10” 24px centered on top of it |
| progress_bar_fill.svg | 194×26 | 13 / 13 / 13 / 13 | Fill inside the frame (inset 3px); width = frame×progress, min width 26 |
| pip_empty.svg | 22×22 | — | Fighter level pip (not reached); row of 5, gap 6 |
| pip_full.svg | 22×22 | — | Fighter level pip (reached) |
| star_full.svg | 56×56 | — | Earned star (main screen 56px, map 26px) |
| star_empty.svg | 56×56 | — | Not-earned star |
| icon_coin.svg | 128×128 | — | Currency everywhere (coin counter 64px, prices 34px) |
| icon_plus.svg | 128×128 | — | “+” (buy coins) at the end of the coin counter, 60px |
| icon_lock.svg | 128×128 | — | Locked cards, locked nodes (badge 30px), cave button |
| icon_sword.svg | 128×128 | — | Tab “Бой”, Play button, attack stat (26px) |
| icon_up.svg | 128×128 | — | Tab “Улучшения” |
| icon_map.svg | 128×128 | — | Tab “Карта” |
| icon_heart.svg | 128×128 | — | HP stat (26px), base health |
| icon_food.svg | 128×128 | — | “Производство еды” |
| icon_base.svg | 128×128 | — | “Здоровье базы” |
| icon_army.svg | 128×128 | — | “Сила армии” |
| icon_speed.svg | 128×128 | — | “Скорость боя ×1.5” |
| icon_start_food.svg | 128×128 | — | “Еда на старте” |
| icon_unit_level.svg | 128×128 | — | “Уровень бойца” |
| icon_cave.svg | 128×128 | — | “Открыть пещеры”, cave world |
| icon_settings.svg | 128×128 | — | Settings button (60px on btn_icon) |
| level_node_passed.svg | 104×112 | — | Passed level; number 34px on the face (center 52,48); stars 26px below |
| level_node_current.svg | 156×168 | — | Current level (bigger, glow; pulse glow + map_arrow bob); number 44px (center 78,72) |
| level_node_locked.svg | 104×112 | — | Locked level; grey number 34px + lock badge |
| level_node_boss.svg | 164×184 | — | Boss levels 10 and 20: red frame; the game draws the boss head sprite (Король зомби / Каменный голем) centered on the face (82,80), ~80px wide |
| map_arrow.svg | 64×76 | — | Bouncing pointer above the current node (bob 10px, 0.8s) |
| bg_menu.svg | 1440×720 | — | Main-screen background. 1440×720 so wide phones (20:9) are covered; center 1280×720 is the safe area (crop 80px each side at 16:9) |
| bg_map.svg | 2560×720 | — | World map, scrolls horizontally. Meadow x 0–1150 (levels 1–10), crystal cave x 1150–2230 (11–20), mist “Скоро” x 2230–2560. Node centers in map_nodes.json |

Extras: map_nodes.json (level node centers on bg_map), manifest.json (same data as this table).
