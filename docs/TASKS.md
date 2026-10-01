# TASKS — порядок работы для Claude Code

Правила — в `CLAUDE.md`, детали — в `docs/SPEC.md` (разделы указаны в скобках).
Одна задача за сессию-шаг. В конце задачи: критерии готовности отмечены, тесты зелёные, дано сообщение коммита.

Как давать задачу Claude Code:

```
Прочитай CLAUDE.md, docs/SPEC.md и docs/TASKS.md. Делаем задачу T<номер>.
Сначала коротко опиши план шагов, потом веди меня по ним.
```

---

## Фаза 0 — основа

### T00. Репозиторий и проект
- `project.godot`: имя, 1280×720, `canvas_items` + `expand`, Compatibility, строгие предупреждения GDScript как ошибки.
- Папки по структуре из `CLAUDE.md`; `.gdignore` в `design/`, `docs/`, `tools/`.
- `.gitignore` (`.godot/`, `build/`, `*.zip`, `*.tmp`), `.gitattributes` (`* text=auto eol=lf`, `*.png *.ogg *.webp binary`).
- `.githooks/commit-msg` (Conventional Commits + запрет `Co-Authored-By`, текст в `docs/PLAN.md` раздел 12), `README.md` с версией Godot и командой `git config core.hooksPath .githooks`.
- **Готово, когда:** проект открывается без ошибок, хук отклоняет `bad message` и сообщение с `Co-Authored-By`.
- Коммит: `chore: init godot project structure`

### T01. Облегчённый web-шаблон и экспорт (SPEC 15)
- Инструкция `docs/BUILD_TEMPLATE.md`: Python, SCons, emsdk нужной версии, команда `scons platform=web target=template_release optimize=size lto=full threads=no disable_3d=yes module_text_server_adv_enabled=no module_text_server_fb_enabled=yes build_profile=custom.build`.
- Пресет Web: свой шаблон, `web/custom_shell.html` (SPEC 16), без потоков, экспорт в `build/web/`.
- `tools/check_build.py`: проверяет `index.html` в корне, имена без пробелов/кириллицы, упаковывает `build/web/*` в `build/game.zip`, печатает размер и падает, если > 10 МБ.
- **Готово, когда:** пустая сцена экспортируется, zip ≤ 4 МБ, открывается в Chrome без ошибок в консоли.
- Коммит: `build: add lean web export preset and build check`

### T02. Тесты
- Поставить gdUnit4 в `addons/`, записать версию и SHA в `ADDONS.md`.
- Один smoke-тест, команда запуска в `README.md`.
- **Готово, когда:** `"$GODOT" --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests` зелёный.
- Коммит: `test: add gdunit4 and smoke test`

## Фаза 1 — ассеты

### T03. Конвертер юнитов из Claude Design (SPEC 11)
- `tools/split_units.py` (stdlib): для каждого `unit_*.svg`/`boss_*.svg` из `design/.../assets/` создаёт `art/units/<id>/<part>.svg` — тот же `viewBox`, только одна группа. Метаданные `c2pa` вырезать.
- Считает точки вращения по bbox группы (руки/ноги — верх-центр, голова — низ-центр, остальное — центр) → `art/units/<id>/pivots.json`.
- `tools/copy_assets.py`: копирует остальное (снаряды, эффекты, UI, иконки, базы, фоны, декор, логотипы) в `art/...` с чистыми именами; `store_*` и `style_guide` не копировать.
- Настройки импорта SVG — масштабы из SPEC 11 (через `.import` по умолчанию для папки или скрипт-пресет).
- **Готово, когда:** у зомби 7 частей, наложенные в одной точке дают исходного персонажа; `pivots.json` есть у всех.
- Коммит: `feat(tools): add svg unit splitter and asset import`

### T04. Сцена-визуал юнита и анимации (SPEC 10)
- `@tool` скрипт `scripts/battle/unit_visual.gd`: по `pivots.json` расставляет Sprite2D частей (position = pivot, offset = −pivot), порядок: LegBack, ArmBack, Body, Head, LegFront, ArmFront, Weapon, TeamAccent.
- Сцены `art/units/<id>/<id>_visual.tscn` для всех 6 юнитов и 2 боссов.
- AnimationLibrary `anim/humanoid.tres` (walk, idle, attack, hit, die) по таблице SPEC 10; `slime.tres`, `spider.tres`, `bomber.tres`.
- `team_color` (@export) → modulate `TeamAccent`.
- **Готово, когда:** в редакторе все 8 персонажей проигрывают все анимации, конечности крутятся в суставах без разрывов.
- Коммит: `feat(art): add unit visuals and animation libraries`

## Фаза 2 — бой

### T05. Данные (SPEC 3, 4, 5)
- Ресурсы: `UnitData`, `WaveEntry`, `WaveData`, `LevelData`, `UpgradeData`, `BalanceData`.
- `data/units/*.tres` со значениями из SPEC 3, `data/balance.tres` из SPEC 4.
- Тесты: все юниты загружаются, числа в допустимых диапазонах.
- Коммит: `feat(data): add unit, wave, level and balance resources`

### T06. Симуляция боя без графики (SPEC 3)
- `scripts/battle/sim/`: `BattleSim` (тик с фиксированным dt), `SimUnit`, машина состояний Walk/Wait/Attack/Dead, выбор цели, снаряды, урон по базе, бомбер, лимит 20.
- Детерминированный RNG по seed.
- Тесты: ближний бьёт ближнего; лучник стреляет с 180; `Wait` за своим; бомбер взрывается и умирает; урон по базе; 500 боёв бот-против-бота всегда заканчиваются, мёртвых юнитов на поле нет.
- Коммит: `feat(battle): add headless battle simulation`

### T07. Сцена боя (SPEC 2)
- `scenes/battle/battle.tscn`: поле (заглушка), две базы, `y_sort`, пулы юнитов/снарядов/эффектов, узлы-визуалы синхронизируются с `BattleSim`.
- Смещение y ±12, базы меняют спрайт по HP (100–60% / 60–25% / <25%), тряска при ударе.
- **Готово, когда:** кнопкой отладки спавнятся юниты с обеих сторон, дерутся, умирают с эффектом, база разрушается.
- Коммит: `feat(battle): add battle scene with pooled units`

### T08. Экономика и панель (SPEC 4, 9)
- Еда: старт, доход, максимум; нижняя панель: счётчик еды, карточки юнитов (портрет, цена, бейдж клавиши на ПК, серая при нехватке/лимите, перезарядка 1 с).
- Клавиши `1`–`6` через `physical_keycode`.
- Руда: 2 блока, тап/клик +2 еды, перезарядка 4 с.
- Метеор: заряды, выбор точки, отмена `Esc`/ПКМ.
- HUD: HP базы, «Волна N/M», пауза.
- Тесты экономики.
- Коммит: `feat(battle): add food economy, unit cards, ore and meteor`

### T09. Бот и уровни (SPEC 5)
- `scripts/battle/bot.gd`: волны по `WaveData`, `counter_pick`, дожим после последней волны, босс.
- 20 уровней `data/levels/level_01..20.tres` по кривой SPEC 5.
- Бот-тестер (тест): простая стратегия игрока проходит уровни 1–5 и 11–15; уровень 20 без апгрейдов не проходится (сложность растёт).
- Коммит: `feat(bot): add scripted waves and 20 levels`

### T10. Победа, поражение, награды (SPEC 6)
- Экран `ui/result`: звёзды, монеты, «×2 за рекламу» (пока через мок), «Дальше», «Меню».
- Тесты расчёта наград и звёзд.
- Коммит: `feat(meta): add battle result and rewards`

## Фаза 3 — мета и меню

### T11. Сохранения (SPEC 13)
- `SaveService`: JSON, `schema_version`, валидация, резервная копия, миграции; автосохранение после боя и покупок.
- Тесты: битый JSON, лишние ключи, отрицательные монеты, старая версия схемы.
- Коммит: `feat(save): add validated local save`

### T12. Меню, улучшения, карта (SPEC 7, 8)
- `boot`, `menu/main` с таб-баром, `menu/upgrades`, `menu/map`, `ui/pause`, `ui/settings`.
- Формулы цен, «Эволюция», скорость боя ×1.5.
- Коммит: `feat(meta): add main menu, upgrades and level map`

## Фаза 4 — платформа

### T13. ПК и телефон (SPEC 9, 16)
- Адаптивные якоря, ограничение соотношения 2:1, `ui/rotate_overlay` в портрете, пауза и звук при потере фокуса.
- **Готово, когда:** в браузере при ресайзе окна от 800×600 до 2560×1080 ничего не обрезается; в DevTools-эмуляции телефона портрет показывает оверлей.
- Коммит: `feat(ui): add responsive layout and rotate overlay`

### T14. Yandex SDK (SPEC 14)
- Плагин (проверить код, `ADDONS.md`), `platform_yandex.gd` за интерфейсом `Platform`, облако в `SaveService`, rewarded/interstitial, `GameplayAPI`, pause/resume, язык, лидерборд.
- **Готово, когда:** в черновике Яндекс Игр реклама показывается, игра встаёт на паузу, награда выдаётся один раз, прогресс переживает перезагрузку.
- Коммит: `feat(platform): integrate yandex games sdk`

### T15. Локализация и звук (SPEC 12)
- `translations.csv` (ru/en) для всех текстов, выбор языка по SDK + вручную в настройках.
- Шина звука, SFX и музыка (плейсхолдеры, если звуков ещё нет).
- Коммит: `feat(i18n): add ru/en and audio bus`

## Фаза 5 — финал

### T16. Графика поля 3/4
- Подключить новые ассеты из Claude Design (поле, декор, базы 3/4, панель, бустеры, карта) вместо заглушек.
- Коммит: `feat(art): add 3/4 battlefield art`

### T17. Бустеры за рекламу (SPEC 4)
- Скорость ×2 и +15 еды, по разу за бой, подписанные кнопки, пауза во время показа.
- Коммит: `feat(battle): add rewarded boosters`

### T18. Обучение и баланс (SPEC 5)
- Подсказки на уровне 1, проход всех 20 уровней, правка чисел только в `data/`.
- Коммит: `chore(balance): tune levels 1-20`

### T19. Релиз
- Экспорт, `tools/check_build.py` (≤ 10 МБ), чек-лист SPEC 16, ручная проверка на ПК и телефоне, загрузка zip в черновик.
- Коммит: `chore(release): v1.0.0` + тег `v1.0.0`.

## После релиза

### T20. Магазин и инап-покупки
Дизайн: `design/Mine Rush menu redesign/` — `Screen Shop.dc.html`, `Tab Bar.dc.html`, `kit_shop/` (SVG), `mockups/mockup_shop*.png`, `mockup_main_tabs4*.png`. Перенести **точно как в макете** (как меню и бой v3: копия в `art/ui/v3/shop/` скриптом `tools/import_menu_v3.py`, тема `theme_v3.tres`, сцены `.tscn`). Правила Яндекса — скилл `yandex-games` (раздел «Инап-покупки», `requirements.md` 1.13).
- **Вкладки:** 4-я вкладка «Магазин» первой слева (`Магазин · Бой · Улучшения · Карта`), новый tab bar под 4 вкладки; «+» у счётчика монет открывает магазин; красная точка на вкладке, когда готовы бесплатные монеты.
- **Товары** (ID = ID в консоли Яндекса, данные — ресурс в `data/shop/`, не магические числа):
  | ID | Тип | Выдаёт |
  | --- | --- | --- |
  | `starter_pack` | разовый, постоянный (не consume) | открыть `goblin_miner` + 5 000 монет |
  | `no_ads` | постоянный (не consume) | не показывать interstitial; rewarded остаются |
  | `gold_pickaxe` | постоянный (не consume) | ×2 монеты за бой (в `Rewards`) |
  | `coins_small` / `coins_bag` / `coins_chest` | расходуемые | 2 000 / 8 000 / 25 000 монет |
  | `free_coins` | rewarded-реклама, не инап | +500 монет, раз в 15 мин (время в сохранении, `Time.get_unix_time_from_system`) |
- **Мост** (`web/custom_shell.html`, `window.YG`): `getCatalog(cb)` → JSON товаров (`id`, `price`, `priceValue`, `priceCurrencyCode`, URL картинки валюты `getPriceCurrencyImage('medium')`), `purchase(id, cb)` → `'ok', token` / `'fail'`, `getPurchases(cb)` → JSON `[{productID, purchaseToken}]`, `consume(token)`. Каждый вызов отвечает callback'ом и по таймауту.
- **Platform:** `get_catalog()`, `purchase(id)` + сигналы `purchased(id)` / `purchase_failed(id)`, `get_purchases()`; `PlatformMock` — всё покупается сразу (для редактора и тестов).
- **Выдача:** одна функция `GameState.grant_product(id)`; для расходуемых — выдать, сохранить (в том числе в облако), потом `consume`. **При каждом запуске** (boot, после облака): `get_purchases()` → необработанные расходуемые выдать и потребить, постоянные (`no_ads`, `gold_pickaxe`, `starter_pack`) — восстановить флаги. Без этого модерация не пройдёт.
- **Цена:** «<цена> <валюта>» из каталога + иконка валюты из SDK (загрузить картинку по URL в `TextureRect` через `HTTPRequest`; при ошибке — только текст с кодом валюты). Свою иконку яна не рисовать.
- **Окна:** «Покупка получена!» (арт товара, лучи, «+8 000»), «Магазин недоступен» (SDK офлайн / каталог пуст), предложение «Набор новичка» один раз после победы на 3-м уровне.
- **Тексты:** все ключи в `translations.csv` (ru/en), названия товаров совпадают с консолью.
- **Тесты:** выдача каждого товара, повторный запуск не выдаёт постоянные дважды, `no_ads` отключает interstitial, `gold_pickaxe` удваивает награду, таймер `free_coins`.
- Коммиты: `feat(meta): shop screen`, `feat(platform): in-app purchases`.
- **Только на ПК Twody** (в облаке нельзя): проверить экран глазами (скриншоты `tools/store_shots.gd`), экспорт + `tools/check_build.py`, тестовые покупки в черновике. Twody: запрос на подключение покупок в консоли, товары с этими ID, названиями и ценами.
