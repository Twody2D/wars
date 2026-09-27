# Промпты для Claude Design

Промпты на английском: так модель точнее соблюдает технические требования (размеры, id групп, ограничения SVG). Проект игры и интерфейс остаются на русском.

## Как пользоваться

1. Создай в Claude Design новый проект и вставь **главный промпт** целиком.
2. Он просит сделать всё сразу, секция за секцией. Если модель остановится раньше (ответ длинный), она напишет `READY FOR SECTION N` — отправь **промпт продолжения** с этим номером.
3. Если какой-то ассет не понравился — **промпт правки** (в конце файла).
4. Экспортируй каждый артборд в SVG, имя файла = имя артборда. Раскладывай по папкам `art/` проекта (раздел «Куда класть» внизу).

---

## Главный промпт (вставить целиком)

```
You are the lead artist for a small 2D web game for kids (7–14) called [GAME TITLE].
It runs in the browser on PC and on phones, landscape only, base resolution 1280×720.
Genre: side-view lane battle (like classic "war" lane games): two bases on the left and
right, units walk toward each other along one lane and fight. Progression goes through
biomes. The game engine is Godot 4 and the build must be tiny (under 10 MB total),
so every asset must be simple, flat and light.

Produce ALL assets below in this one project, section by section, in order.
If you cannot finish everything in one reply, stop only after a fully completed
section and write exactly: READY FOR SECTION <next section number>.

=====================================================================
GLOBAL STYLE (apply to every asset)
=====================================================================
- Original blocky "voxel-cartoon" style: every shape is built from rectangles and
  cubes, chunky and cute, never scary. All characters and designs must be fully
  original — do not imitate any existing game's characters, mobs or logos.
- Chibi proportions: big square heads (about 40% of height), short bodies, expressive
  square eyes, funny faces.
- Thick dark outline: 3 px, color #1B1B2F, on every shape.
- Flat fills only. Each cube face = one base color + one darker side face + one small
  highlight. No gradients.
- Subtle pixel texture: a few 4×4 px squares in a slightly different shade on large faces.
- One shared palette of max 32 colors for the whole game. Team colors:
  player = blue #3A7BFF, enemy = red #FF4A4A (used only on the team_accent part).
- Light comes from the top-left.

=====================================================================
TECHNICAL RULES (Godot SVG import + small build)
=====================================================================
- Every asset is its own artboard, named exactly as the file name given below
  (lowercase, underscores, no spaces).
- SVG only, transparent background, simple paths and rectangles.
- Do NOT use: filters, blur, drop shadows, masks, clip-paths, gradients, patterns,
  embedded raster images, <text> elements (convert all text to paths), CSS styles.
  Use plain fill and stroke attributes only.
- Keep the node count low: merge shapes of the same color where possible.
- Characters: side view, facing RIGHT, neutral pose (standing straight, arms down).
- Character parts that animate must be separate top-level <g> groups with these ids:
  head, body, arm_front, arm_back, leg_front, leg_back, weapon (if any), team_accent.
  Back arm and back leg are 15% darker than the front ones.
  The top edge of each arm and leg is its joint (shoulder / hip) and must slightly
  overlap the body so no gap appears when the limb rotates up to ±35°.
- team_accent (a headband, scarf or small flag) is pure white #FFFFFF so the game can
  tint it blue or red.
- Next to each character, also show the same character "exploded" into its parts
  with labels (reference only, a separate artboard named <file>_parts).

=====================================================================
SECTION 1 — STYLE GUIDE  (artboard: style_guide, 1280×720)
=====================================================================
Show: the 32-color palette with hex codes, grouped as: shared, meadow biome,
cave biome; team colors; outline thickness; one sample button; the chosen
title/number font style (must support Cyrillic; draw sample digits 0–9 and
"Еда 25" as paths).

=====================================================================
SECTION 2 — UNITS  (each artboard 256×256, feet on y = 240, centered)
=====================================================================
unit_zombie — "Cube Zombie": cheap slow melee unit. Sleepy green-grey blocky
  creature in a torn orange pajama top, tongue sticking out, one ear bigger than the
  other, arms slightly forward. team_accent = headband.
unit_skeleton — "Bone Archer": ranged unit. Skinny bone-white blocky skeleton with a
  leafy green hood and a short bow made from a twig (weapon group). team_accent = scarf.
unit_slime — "Jelly Cube": tank unit. Semi-transparent-looking purple cube
  (use solid lighter/darker purple faces, no real transparency) with a droplet on
  top and angry eyebrows. Only groups: body, eyes, team_accent (small flag on top).
unit_spider — "Cube Spider": fast unit. Square teal spider body with four cube eyes.
  Instead of arms/legs use groups leg_1 … leg_8. team_accent = tiny bandana.
unit_goblin_miner — "Goblin Miner": thrower unit. Short green goblin in a yellow
  helmet with a headlamp, holding a pickaxe (weapon group). team_accent = armband.
unit_barrel_bomber — "Barrel Bomber": suicide unit that explodes at the enemy.
  A walking wooden barrel with big eyes, a lit fuse on top (separate group fuse),
  short stubby legs. team_accent = painted stripe.

=====================================================================
SECTION 3 — BOSSES  (each artboard 512×512, feet on y = 480)
=====================================================================
boss_zombie_king — the Cube Zombie but 3× bigger and chunkier, wearing a crown made
  from a cooking pot, holding a log as a club (weapon group).
boss_stone_golem — massive golem made of grey stone blocks with glowing light-blue
  crystals and patches of moss, huge fists (arm groups).

=====================================================================
SECTION 4 — PROJECTILES  (each artboard 64×64, centered, pointing right)
=====================================================================
proj_arrow (twig arrow), proj_pickaxe (spinning pickaxe), proj_rock (golem rock).

=====================================================================
SECTION 5 — BASES  (each artboard 384×384, ground at y = 370, entrance on the right)
=====================================================================
For each base draw 3 separate artboards: _intact, _damaged (cracks, missing blocks),
_destroyed (pile of blocks, small smoke puffs as flat shapes).
Flag = separate <g id="flag"> in pure white.
base_meadow_* — cozy hut made of logs and stone blocks, grass on the roof.
base_cave_* — mine entrance with a wooden frame, rails and two lanterns.

=====================================================================
SECTION 6 — BIOMES  (parallax layers, each 1280×720)
=====================================================================
For meadow and cave:
bg_<biome>_sky — full background, no transparency.
bg_<biome>_far — distant hills / cave walls, transparent top, tiles seamlessly
  left-right.
bg_<biome>_near — bushes and blocks along the bottom and top edges, transparent,
  tiles seamlessly left-right.
Keep the horizontal band y = 420…620 empty — units walk there.
lane_<biome> — seamless ground strip, 256×128, tiles left-right.
Decor, each 128×128: decor_tree, decor_bush, decor_rock, decor_flower (meadow);
decor_stalactite, decor_mushroom, decor_crystal, decor_ore (cave). decor_ore is
tappable in the game, so make it slightly shinier.

=====================================================================
SECTION 7 — EFFECTS  (sprite sheets: 6 frames of 128×128 in one row = 768×128)
=====================================================================
Frames go: start → peak → fade, last frame almost empty. Effect centered in each frame.
Built from small flat cubes.
fx_hit (white star burst), fx_explosion (orange cubes + grey smoke blocks),
fx_death_poof (grey cubes), fx_coin (spinning coin), fx_heal (green plus signs),
fx_meteor (falling burning block + impact).

=====================================================================
SECTION 8 — UI KIT
=====================================================================
Buttons, 9-slice friendly (corners 24 px must not distort when stretched),
each 128×128, three states each (_normal, _pressed, _disabled):
ui_btn_primary (green), ui_btn_secondary (blue), ui_btn_danger (red).
ui_panel (256×256, 9-slice, wooden-block window).
ui_unit_card (160×200): empty frame for a unit portrait, a price slot with a
  food icon, and a cooldown bar slot at the bottom.
ui_hp_bar_frame (192×32) + ui_hp_fill_blue + ui_hp_fill_red (same size).
Icons, each 96×96: icon_food (meat on a bone, blocky), icon_coin, icon_heart,
icon_sword, icon_lock, icon_star, icon_chest, icon_ad (little TV with a play
triangle), icon_pause, icon_settings, icon_sound_on, icon_sound_off, icon_close,
icon_globe (language), icon_hand_tap (tutorial pointer), icon_rotate_device
(phone turning from portrait to landscape with a curved arrow).
ui_key_badge (48×48, 9-slice): a small keyboard key cap, used on PC to show the
hotkey (1–6) in the corner of each unit card. Leave it empty — the digit is added
by the game.
The game runs on both PC and phones in landscape: all UI must stay readable at
1280×720 and be tappable with a thumb (touch targets at least 96×96 in-game).

=====================================================================
SECTION 9 — SCREENS & STORE ART
=====================================================================
logo_ru and logo_en (1024×384): [GAME TITLE] in chunky 3D block letters, as paths.
map_world (1280×720): a winding path from left to right through 6 biome zones
  (meadow, caves, desert, snow, volcano, sky islands). Leave 20 empty round spots
  on the path for level buttons.
bg_menu (1280×720): meadow scene with the Cube Zombie and the Bone Archer
  facing each other, room for the logo at the top.
store_icon (1024×1024): the Cube Zombie's head, big and funny, on a bright
  blue background. No text.
store_cover (1920×1080): two armies of our units charging at each other,
  dynamic diagonal composition, logo at the top. This is NOT a screenshot.

When everything is done, list all artboard names in a single table
(section, file name, size).
```

---

## Промпт продолжения

Подставь номер секции, на которой модель остановилась.

```
Continue with SECTION <N> and all sections after it, following exactly the same
GLOBAL STYLE and TECHNICAL RULES as before. Same stopping rule:
stop only after a fully completed section and write READY FOR SECTION <next>.
```

---

## Промпт правки одного ассета

```
Redo <artboard name>. Keep the global style, palette, size, group ids and all
technical rules. Change: <что не так, по-английски, например: "make the head
20% bigger and the expression happier; the bow is too thin">.
```

---

## Промпт для новых биомов (после релиза)

```
Using the same style guide, palette rules and technical rules, create everything for
the <desert | snow | volcano | sky islands> biome: 2 new units (256×256, same group ids),
1 boss (512×512), base in 3 states (384×384), 3 parallax layers + lane + 4 decor items,
and any new projectiles. New units: <описание по-английски>.
```

---

## Куда класть в проекте

| Префикс артборда | Папка в проекте |
| --- | --- |
| `unit_*`, `boss_*` | `art/units/<имя>/` — одна SVG на юнита; части берём из групп |
| `proj_*` | `art/projectiles/` |
| `base_*` | `art/bases/` |
| `bg_*`, `lane_*`, `decor_*` | `art/biomes/<биом>/` |
| `fx_*` | `art/fx/` |
| `ui_*`, `icon_*` | `art/ui/` |
| `logo_*`, `map_*`, `bg_menu` | `art/screens/` |
| `store_*`, `style_guide`, `*_parts` | `store/` и `art_source/` — **вне** экспорта игры (в папке лежит пустой файл `.gdignore`) |

---

## Смена камеры: поле 3/4 (отправить в тот же проект Claude Design)

```
Keep all units, bosses, projectiles, fx, UI kit and icons exactly as they are.
The camera concept changes: the battlefield is now seen from a 3/4 top-down angle
(ground seen from above at ~45°), while units stay in side view. Redo these assets:

1. battle_meadow and battle_cave (1280×720, one flat image each, no parallax):
   a horizontal dirt/stone lane from x=160 to x=1120 at y=330…450, ground around it
   seen from above at 3/4 angle, grass/cave floor texture. Leave the lane clear.
   Leave the bottom 160 px calm (UI panel goes there) and the top 60 px calm (HUD).
2. Decor for 3/4 top-down (each 96×96, separate files, placed by the game around
   the lane): trees, bushes, rocks, flowers (meadow); stalagmites, mushrooms,
   crystals (cave); ore_block (tappable, slightly shiny, 64×64).
3. Bases in 3/4 top-down view, 192×192, 3 states each (_intact, _damaged,
   _destroyed): base_meadow_* (log-and-stone hut), base_cave_* (mine entrance).
   Player base faces right; the game mirrors it for the bot. Flag = white <g id="flag">.
4. hud_bottom_panel (1280×160, 9-slice friendly), booster cards 112×132
   (booster_speed: hourglass "x2", booster_food: meat "+15") each with a small
   TV-play badge in the top-right corner, ability button 112×112 (meteor),
   wave counter panel 200×64.
5. screen_upgrades (1280×720 reference mockup) with: unit unlock cards row,
   "Food production" row, "Base health" row, big "Evolve" button, bottom tab bar
   with 3 tabs (battle, upgrades, map). Layout only.
6. map_world (1280×720): top-down world map, a winding path through 6 biome zones
   left to right with 20 empty circular level slots. No characters on it.
Same GLOBAL STYLE and TECHNICAL RULES as before.
```

## Редизайн v2: читаемость, меню, улучшения, состояния кнопок (26.09.2026)

Отправить в тот же проект Claude Design. Название — Mine Rush (одно для ru и en).

```
Keep all units, bosses, projectiles, fx, battle backgrounds, bases, decor, HUD and
the map exactly as they are. This is a UI redesign pass. Main goals:
(1) readable on a phone, (2) calmer, less busy screens, (3) every button has
visible hover / pressed / disabled states.

=====================================================================
STYLE (same as before, restated)
=====================================================================
- Original blocky "voxel-cartoon" style, kids 7–14, chunky and cute.
- Outline 3 px #1B1B2F. Flat fills: base color + one darker side + one highlight.
  No gradients. Light from top-left. Same 32-color palette.
- Team colors: player #3A7BFF, enemy #FF4A4A.

=====================================================================
READABILITY RULES (new, apply to every UI asset)
=====================================================================
- Base resolution 1280×720, but on phones the game is shown at ~40% of that size.
  So: body text ≥ 26 px, button labels ≥ 32 px, titles ≥ 44 px, numbers/prices ≥ 36 px
  (in 1280×720 coordinates). Touch targets ≥ 96×96 px.
- LESS DETAIL: no rivets, no plank lines, no double borders, no nested frames.
  One outer outline + one flat fill per panel. Empty space is good.
- Strong contrast: light text on dark fills or dark text on light fills, never
  text on a busy picture. Backgrounds behind UI must be calm and low-contrast.
- Buttons are EMPTY (no text baked in): the game draws the label with its own
  bold rounded Cyrillic font. Mockups may show text only to explain layout.

=====================================================================
TECHNICAL RULES (same as before)
=====================================================================
- Each asset = its own artboard named exactly as the file name (lowercase,
  underscores). SVG only, transparent background, plain fill/stroke attributes.
- No filters, blur, shadows, masks, clip-paths, gradients, patterns, raster images,
  <text> (text only in mockups and logos; logos: text converted to paths), CSS.
- 9-slice friendly: panels and buttons have a plain center and corners ≤ 16 px so
  they stretch without distortion.

=====================================================================
SECTION A — BUTTONS v2 (each 240×96, 9-slice)
=====================================================================
ui_btn_primary_{normal,hover,pressed,disabled}   — green
ui_btn_secondary_{normal,hover,pressed,disabled} — blue
ui_btn_danger_{normal,hover,pressed,disabled}    — red
ui_btn_gold_{normal,hover,pressed,disabled}      — yellow/gold, for "buy for coins"
- normal: flat face + darker 8 px bottom edge (3D block feel).
- hover: face 12% lighter + thin white inner highlight on top — clearly different.
- pressed: bottom edge gone, face moved down 6 px (pushed in).
- disabled: desaturated grey, no highlight.
ui_tab_{active,inactive,hover} (280×88) — bottom tab bar buttons; active tab is
  bright and 8 px taller, inactive is a muted dark version (must still be readable).
ui_btn_icon_{normal,hover,pressed} (96×96, round-cornered square) — for gear,
  pause, close icons placed on top.

=====================================================================
SECTION B — PANELS AND CARDS v2
=====================================================================
ui_panel_v2 (256×256, 9-slice) — ONE flat dark-navy fill (#2B2740-ish), 3 px outline,
  rounded 12 px corners. No wood, no rivets.
ui_card_v2 (256×256, 9-slice) — lighter version for items inside a panel.
ui_card_v2_locked — same, darker, for locked items.
ui_level_pips (5 small squares 20×20 in a row, filled/empty versions:
  ui_pip_full, ui_pip_empty) — to show upgrade level 3/5 without text.
ui_price_tag (160×64, 9-slice) — gold pill for "coin icon + price".

=====================================================================
SECTION C — UPGRADE ICONS (each 96×96, simple, big shapes, readable at 40 px)
=====================================================================
upgrade_army_power (sword + up arrow), upgrade_food_rate (meat + clock),
upgrade_base_hp (hut + heart), upgrade_start_food (meat + flag),
upgrade_battle_speed (hourglass ×1.5), upgrade_unit_level (star + up arrow).

=====================================================================
SECTION D — MAIN MENU v2
=====================================================================
bg_menu_v2 (1280×720): same world as bg_menu but CALM: lower contrast, fewer
  clouds and blocks, soft sky; the middle band y=260…480 and the bottom band
  y=560…720 are plain and darker so buttons pop. Keep the two mascots (zombie left,
  skeleton right) but smaller and at the sides, not behind buttons.
screen_menu_v2 (1280×720, mockup): logo top center; big "Play" primary button in the
  center (400×130) with level label above it; bottom tab bar (3 tabs: Battle,
  Upgrades, Map); coins top-right; round gear button top-left. Nothing overlaps.

=====================================================================
SECTION E — UPGRADES SCREEN v2 (mockup 1280×720 + the pieces above)
=====================================================================
screen_upgrades_v2: calm dark panel on a dimmed background.
- Top row: 6 unit cards (180×200 each): big portrait, name (26 px), level pips,
  one price button at the bottom (gold "coin 50" or grey "locked in caves").
- Below: upgrades as a clean grid of 3 columns × 2 rows, each tile 380×120:
  icon on the left (72 px), name (28 px) and ONE short effect line (e.g. "+10%"),
  level pips, gold price button on the right. No long descriptions.
- Coins top-right, tab bar at the bottom, gear top-left — none of them overlapping
  the panel (panel spans y=100…560).

=====================================================================
SECTION F — OTHER SCREENS (mockups 1280×720, reuse pieces above)
=====================================================================
screen_settings_v2: panel with sound toggle (icon on/off), language row
  (globe + "Русский" / "English"), close button.
screen_pause_v2: Continue / Restart / Sound / Menu.
screen_result_v2: Win/Lose title, 3 stars, "+coins", "×2 coins (ad)" button with the
  TV badge, Next, Menu.
how_to_play_1, how_to_play_2, how_to_play_3 (each 400×260, simple illustrations,
  no text): 1) finger tapping a unit card → unit walks out; 2) finger tapping a
  shiny ore block → meat +1; 3) finger tapping the meteor button, then a target on
  the lane → rock falls on enemies.

=====================================================================
SECTION G — HUD PIECES WITHOUT BAKED TEXT
=====================================================================
The game draws all numbers with its own font, so remove drawn digits/letters:
booster_speed_v2, booster_food_v2 (112×132): same card (hourglass / meat icon +
  TV-play badge top-right) but the bottom label box is EMPTY (plain light fill,
  the game writes "×2" / "+15" there). Same simplification rules: fewer details.
ability_button_v2 (112×112): meteor button, calmer, empty space at the bottom for
  the "1/2" counter.
wave_counter_panel_v2 (200×64): flag icon on the left, plain empty area for text.

=====================================================================
SECTION H — TITLE AND STORE ART (game title: MINE RUSH)
=====================================================================
The game is called "Mine Rush" in every language (no translation).
logo_ru and logo_en (600×225, identical): "MINE RUSH" in the same blocky
  pixel-letter style as the current logo (two lines: MINE / RUSH), text as paths.
  "MINE" in stone-grey/ore colors, "RUSH" in warm orange; must not resemble any
  existing game logo.
store_icon (512×512): mascot face + short title, readable at 64 px, not a screenshot.
store_cover (1920×1080): mascots, lane battle scene, title; not a screenshot.

---

## Обложка и иконка v3: кликабельные (27.09.2026)

Зачем: в каталоге Яндекса (подборка «Игры война») наши обложка и иконка теряются — у соседей крупные персонажи крупным планом, действие, яркий контрастный фон. Разбор соседей: Age of Heroes, «Битва за эволюцию», Mage Castle, стикмены с раздвоенным красно-синим фоном. Отправить в тот же проект Claude Design, результат — PNG. Положить в `build/store/` вместо `icon_512.png` и `cover_800x470.png`.

```
New task for Mine Rush: a store COVER and ICON that win clicks in the Yandex
Games catalog. This is marketing art, not a game screen and not a screenshot.

WHAT WE COMPETE WITH (catalog thumbnails ~400×235 px, next to each other):
- one to three characters HUGE and close-up, filling 60–80% of the frame;
- a frozen action moment: a sword swing with a glowing trail, a fireball,
  an explosion, an arrow flying at the viewer;
- faces with strong emotion (angry roar, fierce grin, panic);
- saturated, contrasting background; very popular: a diagonal split into two
  colors (our army BLUE vs enemy RED) with a lightning/crack between them;
- little or no text. Our flat, small-character cover disappears among them.

STYLE: bold vector cartoon illustration — thick dark outlines (#1B1B2F),
cel shading with 2–3 tones per color, rim light, glow and sparks, speed lines,
flying debris. Keep our characters recognizable (same shapes, colors, bandana
colors, faces) but draw them big and dynamic, with depth and perspective.
Not pixel-flat, not a screenshot, no UI.

COVER (deliver 800×470 exactly + a 1600×940 master; 3 variants):
- Variant A "Clash": the Cube Zombie (blue bandana, our side, left) swings a
  big glowing sword at the Zombie King (red, enemy, right); diagonal
  blue/red split with a lightning crack in the middle; sparks where the
  weapons meet.
- Variant B "Charge": our army (zombie, bone archer, jelly cube, spider) runs
  at the viewer from the left, the enemy horde and the Stone Golem from the
  right; a meteor with a fire trail falls in the center; dust and explosion.
- Variant C "Boss": the Zombie King towers over the scene, low camera angle,
  our tiny brave zombie with a sword in the foreground, back to us.
- Logo "MINE RUSH" (our logo from the brand section) in the top area, at most
  ~20% of the image; the rest is characters and action.
- Safe zones: keep the bottom-left 18%×18% and bottom-right 15%×15% free of
  important details (the catalog draws the rating and age badges there).
- Must read at 200×118 px: check by scaling down — silhouettes and the main
  action must stay clear.

ICON (deliver 512×512; 3 variants):
- One face, close-up, filling ~80%: the Cube Zombie with an angry-funny grin
  and a sword, OR the Zombie King roaring.
- Bright radial background (blue or orange), glow behind the head.
- No text, or at most a tiny "MR". Must read at 64×64 px.

Deliver PNG exports named store_cover_A/B/C.png (800×470),
store_cover_A/B/C_master.png (1600×940), store_icon_A/B/C.png (512×512),
and a sheet showing all of them next to each other at catalog size.
