---
name: godot-web-game
description: Создание и ведение 2D-игры на Godot 4 под веб (Яндекс Игры, ПК + телефон) — старт нового проекта, настройки project.godot, строгая типизация GDScript, структура папок, тесты gdUnit4, облегчённый web-шаблон движка (custom.build), экспорт, хук коммитов, headless-скрипты и подводные камни Godot. Использовать при создании нового Godot-проекта, настройке экспорта или когда что-то странно ломается в Godot.
---

# Godot 4 2D для веба

> В этом репозитории шаблоны уже внедрены: хук — `.githooks/commit-msg`, профиль — `custom.build`, сборка шаблона — `docs/BUILD_TEMPLATE.md`, правила — `CLAUDE.md`.

Опыт Mine Rush (Godot 4.7.2, Compatibility, 09.2026). Для SDK и модерации — скилл `yandex-games`.

## Файлы скилла

| Файл | Что это |
| --- | --- |
| `templates/project_CLAUDE.md` | Шаблон `CLAUDE.md` для нового проекта — заполнить и положить в корень |
| `templates/commit-msg` | Хук Conventional Commits + запрет Co-Authored-By. Положить в `.githooks/`, `git config core.hooksPath .githooks` |
| `templates/custom.build` | Профиль облегчённого web-шаблона (без 3D, физики, продвинутого GUI) |
| `templates/BUILD_TEMPLATE.md` | Как собрать свой web-шаблон движка (emsdk + SCons, ~15 мин) |

## Старт нового проекта

1. `git init`, хук коммитов, `.gitignore` (`.godot/`, `build/`, `*.tmp`), `project_CLAUDE.md` → `CLAUDE.md`.
2. `project.godot`:
   - `renderer/rendering_method="gl_compatibility"` (и `.mobile`) — WebGL2, работает везде.
   - Окно 1280×720, `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"` — интерфейс привязывать к краям через якоря, тогда 4:3…2:1 и sticky-баннер не ломают вёрстку.
   - Строгая типизация как ошибки: `gdscript/warnings/untyped_declaration=2`, `unsafe_property_access=2`, `unsafe_method_access=2`, `unsafe_cast=2`, `unsafe_call_argument=2`.
3. Структура: `addons/` (gdUnit4), `anim/`, `art/`, `audio/`, `data/` (баланс в `.tres`), `scenes/`, `scripts/{autoload,battle/sim,data,platform,ui}`, `tests/`, `tools/` (`.gdignore`), `web/custom_shell.html`, `docs/` (`.gdignore`), `design/` (исходники арта, `.gdignore`, только читать).
4. Автозагрузки: `Events`, `GameState` (прогресс + сохранение), `Platform` (скилл `yandex-games`), `Audio`.

## Принципы кода

- Всё видимое — сценами `.tscn` (Twody открывает их в редакторе), настраиваемое — `@export` и ресурсы `.tres` в `data/`. Никаких магических чисел в скриптах.
- Логика боя — чистые классы без узлов (`sim/`), гоняется в тестах без сцены; отрисовка подписана на её сигналы.
- В бою без `instantiate()`/`queue_free()` — пулы для юнитов, снарядов, эффектов.
- Тексты только `tr("KEY")`, переводы в `localization/translations.csv` (keys,ru,en). Заглушки в сценах перезаписываются кодом.
- Тема UI (`Theme .tres`) на корневых узлах экранов; вариации (`theme_type_variation`) вместо ручных стилей.

## Подводные камни (все ловили на практике)

- **Variant → типизированная переменная**: `var x: Foo = dict["k"]` — ок, а `foo(dict["k"])`, `int(dict["k"])`, `x as Control` из Variant — ошибка компиляции (unsafe). Сначала положить в типизированную локальную переменную.
- **Скрипты `-s res://tools/x.gd`** (extends SceneTree): автозагрузки появляются только на первом `_process`, не в `_init`. Типы классов, которые ссылаются на автозагрузки (`BattleHud` → `Audio`), в таком скрипте не упоминать — компиляция упадёт; брать как `Object`/`Node` и вызывать через `call()`.
- **Размер контейнера после смены шрифта** обновляется только в следующем кадре: `get_combined_minimum_size()` сразу после `add_theme_font_size_override` врёт. Мерить текст шрифтом: `font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)`.
- **Не удалять `.import` файлы** при перегенерации ассетов — у ресурсов сменятся UID, сцены потеряют ссылки. Перезаписывать только сами файлы, потом `"$GODOT" --headless --path . --import`.
- **Movie Maker** пишет в размере окна из настроек проекта, `--resolution` игнорирует. Для 1080p — временный `override.cfg` в корне: `[display]` + `window/size/window_width_override=1920`, `window/size/window_height_override=1080`; удалить после записи. `--fixed-fps 30` — без пропусков кадров; время в скрипте считать кадрами (`delta` масштабируется `Engine.time_scale`).
- **Класс вырезан из web-шаблона** (`custom.build`) → в браузере «Cannot get class», в редакторе всё работает. `check_build.py` ищет такие классы в сценах; новый тип узла — проверить профиль.
- Потеря фокуса окна ставит игру на паузу и глушит звук — в скриптах записи/скриншотов снимать паузу и размьючивать шину каждый кадр.
- `JavaScriptBridge.eval` — только с константными строками (лучше `get_interface`).

## Команды

```bash
G="$GODOT"   # C:\PROGRAMS\Godot\Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --path . --import                                   # переимпорт ассетов
"$G" --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests --ignoreHeadlessMode   # тесты
"$G" --headless --path . --export-release "Web" build/web/index.html  # экспорт
py -3.14 tools/check_build.py                                        # проверка + build/game.zip
"$G" --path . --resolution 1920x1080 -s res://tools/shots.gd         # кадры для проверки глазами
```

Длинные файлы писать инструментом Write, а не heredoc в Bash (heredoc ломается на длинном содержимом). Заголовок коммита ≤ 72 символов — иначе хук отклонит.

## Бюджет веба

Цель zip ≤ 10 МБ: свой web-шаблон (движок ~4.4 МБ в zip вместо ~9), SVG → текстуры на импорте, OGG моно для SFX, музыка ~64 кбит/с. Холст с `devicePixelRatio` не выше 2.
