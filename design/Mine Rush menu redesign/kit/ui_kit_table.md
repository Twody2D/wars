# Mine Rush UI kit — file table

9-slice corners: T / R / B / L in px of the source SVG. "—" = not stretched.

| File | Size (px) | 9-slice corners | Where it is used |
|---|---|---|---|
| kit/btn_play_normal.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| kit/btn_play_hover.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| kit/btn_play_pressed.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| kit/btn_play_disabled.svg | 400×136 | 42 / 44 / 52 / 44 | Main screen “Играть”; text 56px + icon_sword 72px on the face |
| kit/btn_green_normal.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| kit/btn_green_hover.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| kit/btn_green_pressed.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| kit/btn_green_disabled.svg | 180×72 | 28 / 30 / 38 / 30 | Price / buy buttons (affordable), unlock buttons |
| kit/btn_grey_normal.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| kit/btn_grey_hover.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| kit/btn_grey_pressed.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| kit/btn_grey_disabled.svg | 180×72 | 28 / 30 / 38 / 30 | Price button when the player can’t afford it |
| kit/btn_icon_normal.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| kit/btn_icon_hover.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| kit/btn_icon_pressed.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| kit/btn_icon_disabled.svg | 104×110 | 32 / 34 / 42 / 34 | Round-square icon button (settings gear, back, pause); icon 60px centered on face |
| kit/btn_purple_normal.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| kit/btn_purple_hover.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| kit/btn_purple_pressed.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| kit/btn_purple_disabled.svg | 300×100 | 32 / 34 / 42 / 34 | “Открыть пещеры” world button (disabled = locked look) |
| kit/btn_play_glow.svg | 640×300 | — | Soft glow behind btn_play; pulse scale 0.95↔1.08, alpha 0.6↔1 |
| kit/plate_max.svg | 180×72 | 28 / 30 / 38 / 30 | Replaces the price button on a maxed card (“МАКС”) |
| kit/tab_active.svg | 248×118 | 34 / 36 / 44 / 36 | Selected bottom tab: raised 20px, icon 64px + label 26px |
| kit/tab_inactive.svg | 232×102 | 32 / 34 / 42 / 34 | Unselected bottom tab: icon 56px + label 24px |
| kit/tabbar_bg.svg | 800×100 | 44 / 44 / 0 / 44 | Dark plate behind the 3 tabs, anchored to the bottom edge |
| kit/coin_counter.svg | 260×72 | 33 / 36 / 39 / 66 | Top-right coin plate: icon_coin 64px over the left socket, value text 34px, icon_plus 60px overlapping the right end |
| kit/badge_dot.svg | 40×40 | — | Red “something to buy” dot on tabs / buttons (top-right corner, bob 2px) |
| kit/ribbon_title.svg | 520×104 | 0 / 100 / 0 / 100 (3-slice, stretch width only) | Screen title (“Улучшения”); text 38px centered on the band (y 10–76) |
| kit/plate_level.svg | 300×72 | 28 / 30 / 34 / 30 | “Уровень 7” plate above the Play button; text 34px |
| kit/plate_boss.svg | 340×60 | 26 / 28 / 32 / 28 | Boss hint “Босс: Король зомби” under the stars (boss levels only); text 26px |
| kit/card_unit.svg | 196×256 | 116 / 30 / 36 / 30 | Fighter card (Улучшения). Portrait window y 17–105; name 24px @ y110; stats @ y140; pips @ y172; price button 164×60 @ y198 (overhangs 8px) |
| kit/card_unit_locked.svg | 196×256 | 116 / 30 / 36 / 30 | Locked fighter: sprite drawn black at 55% alpha + icon_lock 64px, unlock price button |
| kit/card_unit_max.svg | 196×256 | 116 / 30 / 36 / 30 | Maxed fighter: gold frame, plate_max with “МАКС” |
| kit/card_upgrade.svg | 402×134 | 28 / 28 / 34 / 28 | Army power-up tile: icon_well + icon 72px left, name 24px, effect 24px green, level bar, price button right |
| kit/icon_well.svg | 96×96 | — | Soft round socket behind icons on card_upgrade / cave button |
| kit/progress_bar_frame.svg | 200×32 | 16 / 16 / 16 / 16 | Level bar frame; “ур. 3/10” 24px centered on top of it |
| kit/progress_bar_fill.svg | 194×26 | 13 / 13 / 13 / 13 | Fill inside the frame (inset 3px); width = frame×progress, min width 26 |
| kit/pip_empty.svg | 22×22 | — | Fighter level pip (not reached); row of 5, gap 6 |
| kit/pip_full.svg | 22×22 | — | Fighter level pip (reached) |
| kit/star_full.svg | 56×56 | — | Earned star (main screen 56px, map 26px) |
| kit/star_empty.svg | 56×56 | — | Not-earned star |
| kit/icon_coin.svg | 128×128 | — | Currency everywhere (coin counter 64px, prices 34px) |
| kit/icon_plus.svg | 128×128 | — | “+” (buy coins) at the end of the coin counter, 60px |
| kit/icon_lock.svg | 128×128 | — | Locked cards, locked nodes (badge 30px), cave button |
| kit/icon_sword.svg | 128×128 | — | Tab “Бой”, Play button, attack stat (26px) |
| kit/icon_up.svg | 128×128 | — | Tab “Улучшения” |
| kit/icon_map.svg | 128×128 | — | Tab “Карта” |
| kit/icon_heart.svg | 128×128 | — | HP stat (26px), base health |
| kit/icon_food.svg | 128×128 | — | “Производство еды” |
| kit/icon_base.svg | 128×128 | — | “Здоровье базы” |
| kit/icon_army.svg | 128×128 | — | “Сила армии” |
| kit/icon_speed.svg | 128×128 | — | “Скорость боя ×1.5” |
| kit/icon_start_food.svg | 128×128 | — | “Еда на старте” |
| kit/icon_unit_level.svg | 128×128 | — | “Уровень бойца” |
| kit/icon_cave.svg | 128×128 | — | “Открыть пещеры”, cave world |
| kit/icon_settings.svg | 128×128 | — | Settings button (60px on btn_icon) |
| kit/level_node_passed.svg | 104×112 | — | Passed level; number 34px on the face (center 52,48); stars 26px below |
| kit/level_node_current.svg | 156×168 | — | Current level (bigger, glow; pulse glow + map_arrow bob); number 44px (center 78,72) |
| kit/level_node_locked.svg | 104×112 | — | Locked level; grey number 34px + lock badge |
| kit/level_node_boss.svg | 164×184 | — | Boss levels 10 and 20: red frame; the game draws the boss head sprite (Король зомби / Каменный голем) centered on the face (82,80), ~80px wide |
| kit/map_arrow.svg | 64×76 | — | Bouncing pointer above the current node (bob 10px, 0.8s) |
| kit/bg_menu.svg | 1440×720 | — | Main-screen background. 1440×720 so wide phones (20:9) are covered; center 1280×720 is the safe area (crop 80px each side at 16:9) |
| kit/bg_map.svg | 2560×720 | — | World map, scrolls horizontally. Meadow x 0–1150 (levels 1–10), crystal cave x 1150–2230 (11–20), mist “Скоро” x 2230–2560. Node centers in map_nodes.json |
| kit_battle/hud_counter.svg | 160×58 | 26 / 30 / 32 / 54 | Top-left counters: base health (icon_heart 48) and coins this battle (icon_coin 48); value 30px |
| kit_battle/wave_plate.svg | 340×60 | 26 / 30 / 32 / 56 | Top-center “Ур. 7 · Волна 3/6”; icon_wave_flag 40 in the left socket; text 28px; stretches with text |
| kit_battle/icon_wave_flag.svg | 128×128 | — | Wave plate icon (40px) |
| kit_battle/btn_pause_normal.svg | 84×90 | 28 / 30 / 38 / 30 | Pause button, top-right (hit area 96×96); icon_pause 44 centered on face |
| kit_battle/btn_pause_hover.svg | 84×90 | 28 / 30 / 38 / 30 | Pause button, top-right (hit area 96×96); icon_pause 44 centered on face |
| kit_battle/btn_pause_pressed.svg | 84×90 | 28 / 30 / 38 / 30 | Pause button, top-right (hit area 96×96); icon_pause 44 centered on face |
| kit_battle/btn_pause_disabled.svg | 84×90 | 28 / 30 / 38 / 30 | Pause button, top-right (hit area 96×96); icon_pause 44 centered on face |
| kit_battle/icon_pause.svg | 128×128 | — | Pause glyph |
| kit_battle/panel_bottom.svg | 1280×148 | 40 / 40 / 0 / 40 | Bottom battle panel, full screen width, bottom edge flush (y 572–720) |
| kit_battle/food_well.svg | 150×132 | 24 / 24 / 24 / 24 | Food block: icon_food 64, “25/30” 30px, food bar |
| kit_battle/food_bar_frame.svg | 126×18 | 9 / 9 / 9 / 9 | Food regen bar frame |
| kit_battle/food_bar_fill.svg | 122×14 | 7 / 7 / 7 / 7 | Food bar fill (inset 2px), width = frame × food/max |
| kit_battle/card_battle_ready.svg | 110×156 | 108 / 20 / 26 / 20 | Unit card, ready (bright). Portrait y 12–100; price_plate @ (16,112); level_tag top-right; hotkey_badge top-left |
| kit_battle/card_battle_dim.svg | 110×156 | 108 / 20 / 26 / 20 | Unit card: too expensive or cooling down (price text turns red when too expensive) |
| kit_battle/price_plate.svg | 78×32 | 0 / 16 / 0 / 16 | Food price on a card: icon_food 26 + number 22px |
| kit_battle/level_tag.svg | 50×26 | 10 / 10 / 10 / 10 | “ур.2” tag, top-right corner of a card; text 17px |
| kit_battle/hotkey_badge.svg | 32×32 | — | PC hotkey 1–6 (dark number 20px), top-left corner of a card |
| kit_battle/card_cd_overlay.svg | 94×90 | 10 / 10 / 10 / 10 | Cooldown shade over the portrait; height = remaining cooldown; bright bottom edge |
| kit_battle/card_cd_bar_frame.svg | 94×12 | 6 / 6 / 6 / 6 | Cooldown bar under the portrait |
| kit_battle/card_cd_bar_fill.svg | 90×8 | 4 / 4 / 4 / 4 | Cooldown bar fill |
| kit_battle/btn_booster_normal.svg | 96×128 | 28 / 30 / 62 / 30 | Ad boosters “×2” (icon_speed) and “+15” (icon_food): icon 56 on top, value 26px in the bottom strip; badge_ad top-right |
| kit_battle/btn_booster_hover.svg | 96×128 | 28 / 30 / 62 / 30 | Ad boosters “×2” (icon_speed) and “+15” (icon_food): icon 56 on top, value 26px in the bottom strip; badge_ad top-right |
| kit_battle/btn_booster_pressed.svg | 96×128 | 28 / 30 / 62 / 30 | Ad boosters “×2” (icon_speed) and “+15” (icon_food): icon 56 on top, value 26px in the bottom strip; badge_ad top-right |
| kit_battle/btn_booster_disabled.svg | 96×128 | 28 / 30 / 62 / 30 | Ad boosters “×2” (icon_speed) and “+15” (icon_food): icon 56 on top, value 26px in the bottom strip; badge_ad top-right |
| kit_battle/badge_ad.svg | 40×34 | — | “Watch ad” badge on boosters and ad buttons |
| kit_battle/btn_meteor_normal.svg | 160×176 | — | METEOR ability (disabled = charging); icon_meteor 96; charge_plate at bottom |
| kit_battle/btn_meteor_hover.svg | 160×176 | — | METEOR ability (disabled = charging); icon_meteor 96; charge_plate at bottom |
| kit_battle/btn_meteor_pressed.svg | 160×176 | — | METEOR ability (disabled = charging); icon_meteor 96; charge_plate at bottom |
| kit_battle/btn_meteor_disabled.svg | 160×176 | — | METEOR ability (disabled = charging); icon_meteor 96; charge_plate at bottom |
| kit_battle/meteor_ring_track.svg | 176×176 | — | Recharge ring track around the meteor button (TextureProgressBar under) |
| kit_battle/meteor_ring_fill.svg | 176×176 | — | Recharge ring fill (radial clockwise progress) |
| kit_battle/meteor_glow.svg | 260×260 | — | Glow behind a ready meteor (pulse) |
| kit_battle/charge_plate.svg | 70×32 | 0 / 16 / 0 / 16 | Meteor charges “1/2” (22px) |
| kit_battle/icon_meteor.svg | 128×128 | — | Meteor button icon |
| kit_battle/hp_bar_base_frame.svg | 150×24 | 12 / 12 / 12 / 12 | Base HP bar above each base; number 20px centered |
| kit_battle/hp_bar_base_fill_blue.svg | 144×18 | 9 / 9 / 9 / 9 | Our base HP fill (inset 3px) |
| kit_battle/hp_bar_base_fill_red.svg | 144×18 | 9 / 9 / 9 / 9 | Enemy base HP fill |
| kit_battle/hp_star_mark.svg | 26×40 | — | Star threshold marks on our base bar (3★ / 2★); tick ends on the bar |
| kit_battle/hp_unit_frame.svg | 36×9 | 4 / 4 / 4 / 4 | Tiny HP bar over a unit (10px above the head) |
| kit_battle/hp_unit_fill_blue.svg | 33×6 | 3 / 3 / 3 / 3 | Our unit HP fill |
| kit_battle/hp_unit_fill_red.svg | 33×6 | 3 / 3 / 3 / 3 | Enemy unit HP fill |
| kit_battle/banner_normal.svg | 620×124 | 0 / 120 / 0 / 120 (3-slice) | Wave banner (upper middle): title 40px on the band, subtitle 24px on the dark strip |
| kit_battle/banner_danger.svg | 620×124 | 0 / 120 / 0 / 120 (3-slice) | Danger banner (boss / final wave) |
| kit_battle/shield_dome.svg | 300×260 | — | Enemy base shield while the boss is alive (scale to ~256 wide, bottom on the ground); pulse alpha 0.8↔1 |
| kit_battle/window_panel.svg | 560×440 | 44 / 44 / 52 / 44 | Pause and result windows (dim the battle behind with #0A0C28 @ 60%) |
| kit_battle/ribbon_win.svg | 520×104 | 0 / 100 / 0 / 100 (3-slice) | “Победа!” title |
| kit_battle/ribbon_lose.svg | 520×104 | 0 / 100 / 0 / 100 (3-slice) | “Поражение” title |
| kit_battle/rays_burst.svg | 720×720 | — | Rotating light rays behind the victory window (0.1 turn/s) |
| kit_battle/btn_blue_normal.svg | 180×72 | 28 / 30 / 38 / 30 | Blue secondary button (“Настройки”) |
| kit_battle/btn_blue_hover.svg | 180×72 | 28 / 30 / 38 / 30 | Blue secondary button (“Настройки”) |
| kit_battle/btn_blue_pressed.svg | 180×72 | 28 / 30 / 38 / 30 | Blue secondary button (“Настройки”) |
| kit_battle/btn_blue_disabled.svg | 180×72 | 28 / 30 / 38 / 30 | Blue secondary button (“Настройки”) |
| kit_battle/icon_play.svg | 128×128 | — | “Продолжить” / “Дальше” |
| kit_battle/icon_home.svg | 128×128 | — | “В меню” |
| kit_battle/ore_meadow.svg | 96×96 | — | Tappable gold ore near the road (gives food); bob 3px + sparkle |
| kit_battle/ore_meadow_empty.svg | 96×96 | — | Mined-out ore while recharging (ore_ring above) |
| kit_battle/ore_cave.svg | 96×96 | — | Tappable crystal ore (cave) |
| kit_battle/ore_cave_empty.svg | 96×96 | — | Crystal ore recharging |
| kit_battle/ore_ring_track.svg | 44×44 | — | Recharge ring above an empty ore (track) |
| kit_battle/ore_ring_fill.svg | 44×44 | — | Recharge ring fill (radial progress) |
| kit_battle/base_meadow_blue_intact.svg | 256×256 | — | Our meadow base (intact); door faces the road (right); draw ~192px, center x≈96 |
| kit_battle/base_meadow_red_intact.svg | 256×256 | — | Enemy meadow base (intact); mirrored, center x≈1184 |
| kit_battle/base_cave_blue_intact.svg | 256×256 | — | Our mine-entrance base (intact) |
| kit_battle/base_cave_red_intact.svg | 256×256 | — | Enemy mine-entrance base (intact) |
| kit_battle/base_meadow_blue_damaged.svg | 256×256 | — | Our meadow base (damaged); door faces the road (right); draw ~192px, center x≈96 |
| kit_battle/base_meadow_red_damaged.svg | 256×256 | — | Enemy meadow base (damaged); mirrored, center x≈1184 |
| kit_battle/base_cave_blue_damaged.svg | 256×256 | — | Our mine-entrance base (damaged) |
| kit_battle/base_cave_red_damaged.svg | 256×256 | — | Enemy mine-entrance base (damaged) |
| kit_battle/base_meadow_blue_destroyed.svg | 256×256 | — | Our meadow base (destroyed); door faces the road (right); draw ~192px, center x≈96 |
| kit_battle/base_meadow_red_destroyed.svg | 256×256 | — | Enemy meadow base (destroyed); mirrored, center x≈1184 |
| kit_battle/base_cave_blue_destroyed.svg | 256×256 | — | Our mine-entrance base (destroyed) |
| kit_battle/base_cave_red_destroyed.svg | 256×256 | — | Enemy mine-entrance base (destroyed) |
| kit_battle/bg_battle_meadow.svg | 1440×720 | — | Meadow battlefield. Road y 372–446 (feet 390–420); safe area x 80–1360; bases/ore/units on top |
| kit_battle/bg_battle_cave.svg | 1440×720 | — | Cave battlefield: crystals, mine timbers, lanterns, rails behind the road. Road y 372–446; safe area x 80–1360 |

Extras: kit/map_nodes.json (level node centers on bg_map), kit/manifest.json (same data as this table).
