# CLAUDE.md — правила проекта «Mine Rush»

Этот файл читается Claude Code автоматически. Здесь правила работы; что строим — в `docs/SPEC.md`, в каком порядке — в `docs/TASKS.md`.

## Проект в двух строках

2D-битва на одной линии для Яндекс Игр (ПК + телефон, горизонтальная ориентация). Игрок копит еду, покупает юнитов и отбивается от волн бота, потом разрушает его базу; за монеты между боями прокачивается.

## Источники правды

| Файл | Что там | Приоритет |
| --- | --- | --- |
| `docs/SPEC.md` | Геймдизайн, цифры, экраны, требования Яндекса | 1 |
| `docs/TASKS.md` | Задачи по порядку с критериями готовности | 1 |
| `design/Art sections 1 and 2 complete/` | Готовые SVG из Claude Design (только читать) | — |
| `docs/PROMPTS.md` | Промпты для Claude Design | справочно |
| `docs/PLAN.md` | Старый черновик. При расхождении верны SPEC и TASKS | 3 |

Если в SPEC чего-то не хватает — спроси, а не придумывай молча. Мелкие решения (имена переменных, порядок узлов) принимай сам и упоминай в ответе.

## Режим работы

- **Claude Code пишет код в файлы сам** (решение Twody от 25.09.2026), после каждой задачи кратко объясняет ключевые места. Twody играет в сборку и присылает правки.
- Всё видимое делать сценами `.tscn`, которые Twody может открыть в редакторе.
- Формат ответов: коротко, по пунктам, код + суть. «Почему» — одной строкой; подробно — только если спросят.
- Одна задача из `TASKS.md` за раз. В конце задачи: чек-лист критериев готовности. Текущее состояние и решения — в `TODO.md`.

## Git

- Conventional Commits: `feat`, `fix`, `refactor`, `perf`, `test`, `build`, `docs`, `chore`; scope из списка: `battle`, `bot`, `data`, `save`, `platform`, `meta`, `ui`, `art`, `audio`, `i18n`, `balance`, `tools`.
- **Никогда не добавлять `Co-Authored-By` и любые упоминания Claude в коммиты и PR.**
- **Коммитит Claude Code сам** после каждого рабочего шага (хук `.githooks/commit-msg` проверяет формат). Не пушит без прямой просьбы (remote `origin` = github.com/Twody2D/wars).
- Dependabot не используем. GitHub Actions / CI не создаём — сборка и загрузка в Яндекс Игры вручную.

## Окружение

- Windows, Git Bash. Godot 4.x stable (точная версия — в `README.md`, путь к бинарнику — переменная окружения `GODOT`).
- Python 3 — только для `tools/`. Сторонние пакеты можно (Twody, 26.09.2026), ставить `py -3.14 -m pip install --user`; сейчас — `imageio-ffmpeg` для звука.
- Ни Docker, ни VPS, ни WSL.

## Технические правила

- GDScript со строгой типизацией: все переменные, параметры и возвраты с типами. Предупреждения `untyped_declaration`, `unsafe_*` включены как ошибки.
- Рендерер **Compatibility**. Базовое разрешение 1280×720, stretch `canvas_items`, aspect `expand`, соотношение сторон ограничено 2:1.
- **Editor-first:** всё настраиваемое — через `@export` и ресурсы `.tres` в `data/`, сцены собираются в `.tscn`. Никаких «магических чисел» в скриптах — баланс в `data/`.
- Логика боя (`scripts/battle/sim/`) не зависит от узлов отрисовки — её можно гонять в тестах без сцены.
- Пул объектов для юнитов, снарядов, эффектов: в бою нет `instantiate()`/`queue_free()`.
- Все обращения к Yandex SDK — только через автозагрузку `Platform`. В редакторе и тестах работает `platform_mock.gd`.
- `JavaScriptBridge.eval` — только с константными строками.
- Тексты только через ключи локализации (`tr("KEY")`), языки ru/en.
- Бюджет сборки: **zip ≤ 10 МБ** (цель 9). Любой новый ассет — с оглядкой на размер.
- Имена файлов в `res://` — латиница, `snake_case`, без пробелов.

## Структура

```
res://
├── addons/            # gdUnit4, Yandex SDK (версии и SHA — ADDONS.md)
├── anim/              # AnimationLibrary: humanoid.tres, slime.tres, spider.tres, bomber.tres
├── art/               # импортируемая графика (копии из design/, чистые имена)
├── audio/
├── data/              # units/*.tres, levels/*.tres, upgrades/*.tres, balance.tres
├── design/            # исходники Claude Design — .gdignore, не трогать
├── docs/              # .gdignore
├── localization/      # translations.csv
├── scenes/            # boot, menu/*, battle/*, ui/*
├── scripts/
│   ├── autoload/      # Events, GameState, SaveService, Platform, Audio
│   ├── battle/        # узлы боя + sim/ (чистая логика)
│   ├── data/          # классы ресурсов
│   ├── meta/          # апгрейды, награды, карта
│   ├── platform/      # platform_base.gd, platform_yandex.gd, platform_mock.gd
│   └── ui/
├── tests/             # gdUnit4: unit/, integration/
├── tools/             # python-скрипты конвертации (.gdignore)
└── web/               # custom_shell.html
```

## Проверка перед «готово»

1. Проект открывается без ошибок и предупреждений.
2. Тесты gdUnit4 зелёные: `"$GODOT" --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests --ignoreHeadlessMode`.
3. Для задач с экспортом: zip `build/web` ≤ 10 МБ, `index.html` в корне.
4. Нет ошибок в консоли браузера при запуске экспорта.
