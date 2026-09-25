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
