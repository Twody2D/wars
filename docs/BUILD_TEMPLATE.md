# Облегчённый web-шаблон и экспорт

Стандартный web-шаблон Godot весит ~9 МБ в zip. Свой шаблон без 3D, физики, продвинутого GUI и лишних модулей укладывается в бюджет SPEC 15 (движок ~3.7 МБ). Собирается один раз на версию Godot; пересобирать только при смене версии или `custom.build`.

## Что нужно (Windows)

| Что | Версия | Где у нас |
| --- | --- | --- |
| Исходники Godot | тег `4.7.2-stable` (та же версия, что редактор) | `C:\PROGRAMS\godot-src` |
| Emscripten (emsdk) | 4.0.11 (версия из `platform/web/detect.py` / CI Godot) | `C:\PROGRAMS\emsdk` |
| Python + SCons | Python 3.x, `pip install scons` | `py -3.14 -m SCons` |

```powershell
git clone --branch 4.7.2-stable --depth 1 https://github.com/godotengine/godot.git C:\PROGRAMS\godot-src
git clone https://github.com/emscripten-core/emsdk.git C:\PROGRAMS\emsdk
C:\PROGRAMS\emsdk\emsdk install 4.0.11
C:\PROGRAMS\emsdk\emsdk activate 4.0.11
py -3.14 -m pip install scons
```

## Сборка (PowerShell, ~15 мин)

```powershell
& C:\PROGRAMS\emsdk\emsdk_env.ps1
cd C:\PROGRAMS\godot-src
py -3.14 -m SCons platform=web target=template_release optimize=size lto=full threads=no build_profile=C:\Pasha\Wars\custom.build -j12
```

Результат: `C:\PROGRAMS\godot-src\bin\godot.web.template_release.wasm32.nothreads.zip`. Этот путь прописан в `export_presets.cfg` (`custom_template/release`); на другой машине — поправить путь в пресете (Проект → Экспорт → Web → Свой шаблон).

## Профиль `custom.build`

- `disabled_build_options`: без 3D, физики, навигации, XR, продвинутого GUI (`disable_advanced_gui`: RichTextLabel, TextEdit, Tree, диалоги, PopupMenu…), кода совместимости (`deprecated`), лишних модулей (SVG, JPG, regex, сети, mbedtls…). Текст — `text_server_fb` (без HarfBuzz/ICU).
- `disabled_classes`: неиспользуемые 2D-узлы (тайлы, частицы, свет, скелеты, параллакс), AnimationTree, аудиоэффекты.
- SVG импортируются в текстуры на этапе импорта, модуль SVG в рантайме не нужен.
- **Если в игре появился новый тип узла/ресурса** — проверить, что он не выключен в `custom.build`, иначе в браузере будет ошибка «Cannot get class». Проверка — запуск экспорта в Chrome (ниже).

## Экспорт и проверка

```bash
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
python tools/check_build.py        # index.html в корне, имена файлов, build/game.zip ≤ 10 МБ
```

`build/.gdignore` не даёт Godot импортировать файлы экспорта. Локальный запуск: `python -m http.server 8060 -d build/web` → http://127.0.0.1:8060 (консоль браузера — без ошибок).

## Страница `web/custom_shell.html`

- Требования Яндекса (SPEC 16): нет выделения, контекстного меню, долгого тапа, прокрутки и зума страницы.
- Политика размера холста в пресете — «None»: размер холста задаёт страница. Холст на всё окно, но не шире 2:1, лишнее — чёрные поля; плотность пикселей не выше 2 (телефоны с DPR 3 дорого рисовать).
- В бою камера центрирует поле, фон повторяется зеркально за краями — поле до края экрана при любом соотношении от 4:3 до 2:1.
