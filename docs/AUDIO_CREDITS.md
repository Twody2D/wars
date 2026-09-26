# Звуки и музыка — источники

Все файлы — **CC0** (общественное достояние): можно использовать в коммерческой игре, указывать авторов не обязательно (указываем из уважения). Сборка — `tools/import_sounds.py` (скачивает, режет, выравнивает громкость, пишет OGG в `audio/`).

| Файл в игре | Источник | Автор |
| --- | --- | --- |
| `music/battle.ogg` | [Battle Theme A](https://opengameart.org/content/battle-theme-a) | cynicmusic |
| `music/menu.ogg` | [Call to War](https://opengameart.org/content/call-to-war) | Umplix |
| `sfx/win.ogg` | [Medieval: Victory Theme](https://opengameart.org/content/medieval-victory-theme) (первые 6 с) | RandomMind |
| `sfx/lose.ogg` | [War Horns](https://opengameart.org/content/war-horns) (фрагмент) | Eldritch Grim |
| `sfx/hit_*.ogg` | [20 Sword Sound Effects](https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes) | StarNinjas |
| `sfx/shoot_*.ogg`, `sfx/spawn_*.ogg` | [RPG Sound Pack](https://opengameart.org/content/rpg-sound-pack) | artisticdude |
| `sfx/death_*.ogg` | [80 CC0 creature SFX](https://opengameart.org/content/80-cc0-creature-sfx) | rubberduck |
| `sfx/meteor.ogg` | [25 CC0 bang / firework SFX](https://opengameart.org/content/25-cc0-bang-firework-sfx) | rubberduck |
| `sfx/explosion.ogg` | [100 CC0 SFX](https://opengameart.org/content/100-cc0-sfx) | rubberduck |
| `sfx/ore_*.ogg` | [Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney |
| `sfx/coin_*.ogg` | [RPG Audio](https://kenney.nl/assets/rpg-audio) | Kenney |
| `sfx/click.ogg` | [Interface Sounds](https://kenney.nl/assets/interface-sounds) | Kenney |

Заменить звук: поменять строку в `SFX`/`MUSIC` в `tools/import_sounds.py` и запустить его; несколько файлов на один звук — варианты, игра выбирает случайный.
