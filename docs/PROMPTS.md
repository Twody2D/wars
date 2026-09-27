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

Зачем: в каталоге Яндекса (подборка «Игры война») наши обложка и иконка теряются — у соседей крупные персонажи крупным планом, действие, яркий контрастный фон (Age of Heroes, «Битва за эволюцию», Mage Castle).

Как: **один промпт целиком** в Claude Design — лучше в тот же проект, где рисовались персонажи (он их помнит). В новом проекте — приложить к сообщению `design/Art sections 1 and 2 complete/assets/v2/brand/store_cover.svg` и SVG юнитов/боссов как образцы. Результат — PNG в `build/store/`: выбранные вариант обложки → `cover_800x470.png`, иконки → `icon_512.png`.

```
NEW TASK — STORE ART FOR "MINE RUSH" (cover + icon for the Yandex Games catalog)

This is MARKETING ART, not a game asset. The technical rules of the game assets
(flat fills only, no gradients, no filters, SVG only, neutral poses) DO NOT
apply here. Use anything that makes it look great: gradients, glow, light rays,
motion blur, particles, depth, perspective. Final delivery is PNG.

--------------------------------------------------------------------
1. THE GAME (for context)
--------------------------------------------------------------------
Mine Rush is a 2D side-view lane battle for kids 7–14 and casual players:
our base on the left, the enemy base on the right, armies of cute blocky
"voxel-cartoon" monsters walk toward each other along one road and fight in
waves. Our team color is BLUE #3A7BFF, the enemy's is RED #FF4A4A. Biomes:
a sunny meadow and a dark cave with blue crystals.

--------------------------------------------------------------------
2. THE CHARACTERS (keep them recognizable: same shapes, colors, faces)
--------------------------------------------------------------------
All built from cubes and rectangles, chibi proportions (big square head
~40% of height), square eyes, thick dark outline #1B1B2F, cute and funny,
never scary. Our fighters wear a BLUE team accent, enemies a RED one.
- Cube Zombie: sleepy green-grey blocky creature, torn orange pajama top,
  tongue sticking out, one ear bigger than the other; team headband.
- Bone Archer: skinny bone-white blocky skeleton, leafy green hood, short
  twig bow; team scarf.
- Jelly Cube: purple cube (lighter/darker faces), droplet on top, angry
  eyebrows; small team flag on top.
- Cube Spider: square teal body, four cube eyes, eight blocky legs; tiny
  team bandana.
- Goblin Miner: short green goblin, yellow helmet with a headlamp, pickaxe.
- Barrel Bomber: walking wooden barrel with big eyes, a lit fuse on top,
  stubby legs.
- BOSS Zombie King: the Cube Zombie 3x bigger and chunkier, a cooking pot as
  a crown, a log as a club. Enemy (red).
- BOSS Stone Golem: massive golem of grey stone blocks, glowing light-blue
  crystals, moss patches, huge fists. Enemy (red).
- Logo "MINE RUSH": chunky 3D block letters, as in our brand section
  (if you do not have it, draw bold 3D block letters in the same spirit).

--------------------------------------------------------------------
3. WHAT WE COMPETE WITH
--------------------------------------------------------------------
In the catalog the cover is shown ~400x235 px among other war games. The
winners all have:
- 1–3 characters HUGE and close-up, filling 60–80% of the frame;
- a frozen action moment: a weapon swing with a glowing trail, an explosion,
  a fireball/meteor, an arrow flying at the viewer;
- faces with strong emotion (battle roar, fierce grin, comic panic);
- a saturated, contrasting background — very popular: a diagonal split into
  two colors (our side BLUE vs enemy side RED) with a lightning crack between;
- little or no text.
Our current cover (small flat characters, lots of empty space) disappears
among them. Make ours the most eye-catching thumbnail on the page.

--------------------------------------------------------------------
4. STYLE
--------------------------------------------------------------------
Bold cartoon illustration in the spirit of mobile game ads: thick dark
outlines, cel shading with 2–3 tones per color, strong rim light, glow and
sparks, speed lines, flying cube debris and dust, dramatic low camera angle,
strong depth (big foreground, smaller background). Bright and friendly —
for kids, no blood, no gore. Not pixel-flat, not a game screenshot, no UI.

--------------------------------------------------------------------
5. COVER — 3 variants (A, B, C)
--------------------------------------------------------------------
Size: 1600x940 master + 800x470 export (the same image scaled).
- A "Clash": the Cube Zombie (blue, left, sword with a glowing blue trail)
  clashes with the Zombie King (red, right, log club); diagonal blue/red
  split background with a bright lightning crack in the middle; a burst of
  sparks exactly where the weapons meet.
- B "Charge": our army (Cube Zombie in front, Bone Archer, Jelly Cube,
  Cube Spider) charges from the left, the red horde with the Stone Golem from
  the right; a flaming meteor falls into the center; explosion of cubes and
  dust; the meadow on the left turns into the crystal cave on the right.
- C "Boss": the Stone Golem towers over the frame, glowing blue crystals,
  seen from a very low angle; in the foreground our small brave Cube Zombie
  with a sword and a Barrel Bomber with a lit fuse, seen from behind.
Rules for all three:
- logo "MINE RUSH" in the top area, at most ~20% of the image;
- keep the bottom-left 18%x18% and bottom-right 15%x15% free of important
  details (the catalog puts rating and age badges there);
- test by scaling down to 200x118 px: silhouettes, faces and the main action
  must still read clearly. Fix anything that turns into mush.

--------------------------------------------------------------------
6. ICON — 3 variants (A, B, C)
--------------------------------------------------------------------
Size: 512x512 (square, the catalog may round the corners — keep ~8% margin).
- A: the Cube Zombie's face close-up (~80% of the icon), fierce-funny grin,
  blue headband, sword raised; bright blue radial background with a glow.
- B: the Zombie King roaring, pot crown, close-up; hot orange/red radial
  background.
- C: Cube Zombie and Zombie King face to face, split blue/red background
  with a lightning crack.
No text (or a tiny "MR" at most). Must read at 64x64 px — test it.

--------------------------------------------------------------------
7. DELIVERY
--------------------------------------------------------------------
PNG files:
- store_cover_A.png, store_cover_B.png, store_cover_C.png (800x470)
- store_cover_A_master.png, ..._B_master.png, ..._C_master.png (1600x940)
- store_icon_A.png, store_icon_B.png, store_icon_C.png (512x512)
- catalog_preview.png: all covers at 400x235 and all icons at 128 and 64 px
  side by side on a white page, so we can pick the winner.
Then write in one line which cover and which icon you think will get the
most clicks, and why.
```

## Редизайн меню v3: главное, улучшения, карта (27.09.2026)

Зачем: меню выглядит как прототип рядом с Age of Heroes и «Битвой за эволюцию». Нужен современный глянцевый казуальный интерфейс в их духе. Отправлять в **новый чат** Claude Design. Приложить:
1. Текущие экраны: `build/store/shot_menu_0.png`, `shot_upgrades_0.png`, `shot_map_0.png`, `shot_battle_0.png`.
2. Скриншоты меню конкурентов (главный экран, прокачка, карта уровней Age of Heroes и «Битвы за эволюцию»).
3. Логотип и персонажи: `design/Art sections 1 and 2 complete/assets/v2/brand/logo_ru.svg` и `store_cover.svg` (или новую обложку v3, если уже готова).

```
NEW TASK — REDESIGN THE MENUS OF "MINE RUSH": main screen, upgrades, level map.

Attached: our current screens (shot_menu, shot_upgrades, shot_map, shot_battle),
screenshots of competitor games, our logo and our characters.
Goal: a modern, beautiful, polished casual-mobile UI that fits right next to
the top war/army games in the Yandex Games catalog (see the competitor
screenshots), while keeping our characters and our logo.

--------------------------------------------------------------------
1. THE GAME
--------------------------------------------------------------------
Mine Rush is a 2D side-view lane battle for kids 7–14 and casual players, PC
and phones, LANDSCAPE only. Our blocky "voxel-cartoon" monsters (Cube Zombie,
Bone Archer, Jelly Cube, Cube Spider, Goblin Miner, Barrel Bomber; bosses Zombie
King and Stone Golem) fight the enemy army on one road. Between battles the
player spends coins on new fighters and upgrades. Team colors: ours BLUE
#3A7BFF, enemy RED #FF4A4A. Font in the game: Rubik ExtraBold (Cyrillic),
white with a dark outline — the game draws all text itself.

--------------------------------------------------------------------
2. WHAT IS WRONG NOW
--------------------------------------------------------------------
Flat pixel blocks, grey/brown dull colors, thin empty rows, the upgrade screen
looks like a spreadsheet, the map is six flat color stripes with a zigzag,
nothing glows, nothing invites a tap. It looks like a prototype.

--------------------------------------------------------------------
3. TARGET STYLE (like the competitors)
--------------------------------------------------------------------
- Glossy casual mobile-game UI: chunky rounded buttons with a bevel, a light
  top highlight and a darker bottom edge (3D "candy" look), clear pressed state.
- Rich saturated colors, soft gradients, gentle glows behind important things,
  depth: panels over a painted blurred-looking background scene.
- Cards with colored frames, ribbons for titles, shiny coin counter with a
  "+" button, red notification dot when something can be bought.
- Big friendly icons with volume (not flat pixel icons).
- The main action always obvious: a huge glowing PLAY button.
- Cute and bright, for kids; readable at 1280×720 and on a phone
  (touch targets at least 96×96 px at 1280×720, text at least 24 px).
- Keep our characters' look; UI can be smoother/rounder than the pixel art.

--------------------------------------------------------------------
4. SCREENS (each a 1280×720 mockup; also check a 1440×720 wide phone)
--------------------------------------------------------------------
Common to all three: top-left settings button (gear), top-right coin counter
(coin icon + "16 450" + "+" button), bottom tab bar with 3 tabs:
"Бой" (sword), "Улучшения" (arrow up), "Карта" (map) — active tab clearly
raised and bright, inactive tabs calmer, red dot on "Улучшения" when there is
something to buy.

A) MAIN ("Бой" tab)
- Painted meadow battlefield background with depth; our army on the left
  (Cube Zombie in front with a blue headband, Bone Archer behind), the enemy
  in the distance on the right (red accents) — feels like a battle is about
  to start.
- Logo "MINE RUSH" top center.
- "Уровень 7" on a ribbon/plate above a HUGE glowing green "Играть" button
  (sword icon), with a subtle pulse glow.
- Under it three stars of the current level (earned ones gold, others grey).
- A boss hint for boss levels: a small red plate "Босс: Король зомби".

B) UPGRADES ("Улучшения" tab)
Top: title ribbon "Улучшения".
Fighters — a row of 6 cards (Кубозомби, Лучник-кость, Желе-куб, Кубопаук,
Шахтёр-гоблин, Бочка-бомбер), each card:
- portrait window with the character on a soft radial background;
- name;
- stats: heart "66 › 72" and sword "9 › 10" (the next level value in green);
- level pips 1–5;
- price button: coin + "680" (green when affordable, grey when not);
- LOCKED card: darkened silhouette, lock, "1500" to unlock;
- MAX card: gold frame, "МАКС" instead of the price.
Army upgrades — cards or wide tiles with a big icon each:
"Сила армии +10%", "Производство еды +0.05/с", "Здоровье базы +5",
"Еда на старте", "Уровень бойца", "Скорость боя ×1.5":
icon, name, effect in green, level "ур. 3/10" with a progress bar, price
button with a coin. Must look like a shop of power-ups, not a table.
Special wide button "Открыть пещеры" (the next world), locked with the hint
"Пройди 10-й уровень, чтобы открыть пещеры".

C) MAP ("Карта" tab)
- A painted world map, scroll or single screen, 20 level nodes on a winding
  road: levels 1–10 in a sunny meadow, 11–20 in a crystal cave; after that
  a misty "Скоро" (coming soon) area teasing desert, snow and volcano.
- Level node states: passed (with 0–3 stars under it), current (bigger,
  glowing, bouncing arrow or our zombie standing on it), locked (grey + lock).
- Boss nodes 10 and 20: bigger, red, with the boss face (Zombie King, Stone
  Golem).
- Decorations: trees, rocks, crystals, tiny animated-looking details.

--------------------------------------------------------------------
5. TECHNICAL RULES (Godot 4 game, small web build)
--------------------------------------------------------------------
- Deliver every UI piece as a separate SVG (plus the 3 full-screen mockups as
  PNG for reference). Allowed in SVG: paths, rects, circles, fill, stroke,
  opacity, linear and radial gradients. NOT allowed: filters, blur, drop
  shadows via filter, masks, clip-paths, patterns, embedded images, <text>
  (the game draws all text), CSS. Fake shadows and glows with extra shapes
  and gradients.
- Buttons, panels, cards, ribbons, plates: 9-slice friendly — corners must
  not distort when stretched; write the corner size in px for each one.
- Buttons in states: _normal, _hover, _pressed, _disabled.
- Icons 128×128, transparent background.
- Backgrounds 1280×720 (menu, map), no transparency; the map may be 2560×720
  if it scrolls.
- Keep file sizes small: the whole game must fit in 10 MB.

--------------------------------------------------------------------
6. DELIVERY
--------------------------------------------------------------------
1. Three mockups: mockup_main.png, mockup_upgrades.png, mockup_map.png
   (1280×720), plus the same at 1440×720.
2. The UI kit as SVG files, named snake_case:
   btn_play_*, btn_green_*, btn_grey_*, btn_icon_*, tab_active, tab_inactive,
   coin_counter, badge_dot, ribbon_title, plate_level, card_unit,
   card_unit_locked, card_unit_max, card_upgrade, pip_empty, pip_full,
   progress_bar_frame, progress_bar_fill, level_node_passed,
   level_node_current, level_node_locked, level_node_boss, star_full,
   star_empty, bg_menu, bg_map;
   icons: icon_settings, icon_coin, icon_plus, icon_lock, icon_sword,
   icon_up, icon_map, icon_heart, icon_food, icon_base, icon_army,
   icon_speed, icon_start_food, icon_unit_level, icon_cave.
3. A table: file name, size, 9-slice corners (px), where it is used.
```

## Бой v3: HUD и поле в стиле нового меню (27.09.2026)

Отправлять в **тот же чат** Claude Design, где сделан редизайн меню (`design/Mine Rush menu redesign/`), — он уже знает стиль и kit. Приложить `build/store/shot_battle_0.png` и `shot_battle_1.png`.

```
NEXT TASK — same style as the menu kit you just made: redesign the BATTLE
screen of Mine Rush — the in-game HUD and the battlefield. Attached: current
battle screenshots. Characters stay as they are (our pixel sprites walk on
the field); everything else can change.

LAYOUT (1280×720 base, also check 1440×720; the game camera is fixed):
- Units walk left→right on ONE road, feet at y≈390–420. Our base at x≈90,
  enemy base at x≈1190 (each ~192×192, entrance facing the road).
- Top HUD strip (y 0–80), bottom panel (y ≈ 560–720). The road and both
  bases must stay fully visible and uncluttered between them.

HUD (Russian text is drawn by the game, not in the SVG):
1. Top-left: base health (heart + "5") and coins earned this battle (coin + "120").
2. Top-center: level/wave plate "Ур. 7 · Волна 3/6" (stretches with text).
3. Top-right: pause button (icon button).
4. Bottom panel, left: food counter "25/30" with a big food icon and a thin
   fill bar (food regenerates).
5. Unit cards (up to 6 in a row, ~110×150): portrait window, food price
   plate, level tag "ур.2", hotkey badge 1–6 in the corner (PC), a cooldown
   overlay/bar, states: ready (bright, inviting), too expensive (dim),
   cooling down.
6. Right side: two ad boosters "×2" (speed) and "+15" (food), each with a
   small "watch ad" badge, used/disabled state; the big METEOR ability
   button (charges "1/2", radial or bar recharge, glowing when ready).
7. Base HP bars above the bases (blue ours, red enemy) with the number;
   ours has two star marks (thresholds for 3 and 2 stars).
8. Unit HP bars over units: tiny, blue/red.
9. Banner in the upper-middle: title + subtitle ("Финальная волна!" /
   "Босс: Король зомби"), normal and danger (red) versions.
10. Enemy base SHIELD: a translucent blue dome over the enemy base
    (while the boss is alive) — style it to match.
11. Pause window (Продолжить / Настройки / В меню) and Result window
    (Победа! / Поражение, 3 stars, coins, buttons "×2 монеты за рекламу",
    "Дальше", "В меню").

BATTLEFIELD (two biomes, same composition):
- MEADOW: sunny, painted, with depth: sky/hills far away, the road in the
  middle, grass, trees, bushes, flowers in front and behind. Bases: a cozy
  wooden hut with a flag (ours blue flag, enemy red flag), plus a damaged and
  a destroyed state of each.
- CAVE: dark cave with glowing blue crystals, rails, lanterns; mine-entrance
  bases in the same 3 states.
- ORE blocks: 2 tappable ore rocks near the road (below it) that give food —
  shiny, clearly tappable, plus an "empty/recharging" state.
- Keep the road readable: the units are small pixel sprites, so the ground
  under them must be calm and contrasting.

TECHNICAL: same rules as the menu kit — separate SVGs, gradients allowed, no
filters/blur/masks/clip-paths/embedded images/<text>; 9-slice friendly panels
with corner sizes; button states normal/hover/pressed/disabled. Backgrounds
bg_battle_meadow and bg_battle_cave 1440×720 (safe area = middle 1280), bases
~256×256 each state, ore 96×96 (+ recharging).

DELIVERY: mockups battle_meadow.png and battle_cave.png (1280×720 and
1440×720, with units, HUD and a banner), pause and result mockups, the SVG kit
in kit_battle/, and add the new pieces to manifest.json.
```
