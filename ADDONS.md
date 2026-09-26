# Сторонние аддоны

| Аддон | Версия | Источник | Коммит (SHA) | Лицензия | В экспорт |
| --- | --- | --- | --- | --- | --- |
| gdUnit4 | 6.2.1 | https://github.com/godot-gdunit-labs/gdUnit4 (тег `v6.2.1`) | `08ffc7c65b61b1b2edd545616061a99973c13ce1` | MIT | нет |

## Рассмотрены и не используются

- **godot-yandex-games-sdk** (BasilYes, v0.3.0, `937c9c7b2ddae6e86a67b4d11454c88104d4ea7f`, MIT) — просмотрен по SPEC 14 (26.09.2026). Не взят (решение Twody): нет событий `game_api_pause`/`resume`, нет обработки ошибок и таймаутов (игра может зависнуть на загрузке данных), нетипизированный код, свой экспортный плагин правит `index.html` в обход `custom_shell.html`. Вместо него — свой мост: `window.YG` в `web/custom_shell.html` + `scripts/platform/platform_yandex.gd`.
