# Mine Rush

2D-битва на одной линии для Яндекс Игр. Правила работы — `CLAUDE.md`, геймдизайн — `docs/SPEC.md`, задачи — `docs/TASKS.md`.

## Окружение

- **Godot 4.7.2 stable** (Standard, не .NET), рендерер Compatibility.
- Переменная окружения `GODOT` — путь к консольной версии редактора, например:
  `C:\PROGRAMS\Godot\Godot_v4.7.2-stable_win64_console.exe`
- Git Bash, Python 3 (только stdlib, для `tools/`).

## Первый запуск после клонирования

```bash
git config core.hooksPath .githooks
```

Хук `commit-msg` проверяет Conventional Commits и запрещает строки `Co-Authored-By`.

## Тесты

```bash
"$GODOT" --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests --ignoreHeadlessMode
```

Флаг `--ignoreHeadlessMode` обязателен: без него gdUnit4 отказывается работать без окна. Отчёты пишутся в `reports/` (в git не попадают).
