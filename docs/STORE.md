# Карточка игры в консоли Яндекс Игр

Картинки: `build/store/` (не в git, пересоздать — см. «Картинки» внизу).

## Общее

| Поле | Значение |
| --- | --- |
| Поддерживаемые платформы | Компьютер, мобильные (телефон и планшет) |
| Ориентация | Горизонтальная (в портрете игра просит повернуть экран) |
| Игра переведена на | Русский, English |
| Возрастной рейтинг | 6+ (мультяшные бои, без крови) |
| Категории | Казуальные, Аркады, Для мальчиков (стратегий и tower defense в списке Яндекса нет) |
| Теги | зомби, битвы, пиксельная графика, прокачка, армия, скелеты |
| Облачные сохранения | Да |

**Ключевые слова** (≤ 100): `битва, зомби, армия, стратегия, защита базы, прокачка, пиксель, скелеты, волны, босс`

**Комментарий разработчика** (для модерации):

> Язык определяется через SDK при запуске (environment.i18n.lang): русский для ru/be/kk/uk/uz, остальные — английский. В настройках (шестерёнка в меню) язык можно сменить вручную, выбор сохраняется. Реклама: rewarded — бустеры «×2 скорость» и «+15 еды» в бою и «×2 монеты» после боя (награда только после полного просмотра); interstitial — при выходе из боя. На время рекламы и при сворачивании игра на паузе, звук выключен. Прогресс — облачные сохранения SDK.

## Описание — русский

**Название** (≤ 50): `Mine Rush: битва кубов`

**Короткое описание** (≤ 70): `Собери армию кубических монстров и разрушь базу врага!`

**Описание для SEO** (≤ 160):
`Mine Rush — битва на одной линии: копи еду, выпускай зомби и лучников, отбивай волны врагов и разрушай его базу. Прокачка армии, боссы, 20 уровней.`

**Об игре** (≤ 1000):

> Mine Rush — весёлая битва кубических монстров на одной дороге! Твоя база слева, база врага справа, между ними — поле боя.
>
> Копи еду, выпускай бойцов и отбивай волны врага. Кубозомби держат строй, лучники-кости стреляют издалека, а желе-куб принимает на себя удары. В каждой волне враги идут пачкой, а в последней их ведёт огромный вожак. На 10-м и 20-м уровне тебя ждут боссы — Король зомби и Каменный голем.
>
> Добывай руду прямо на поле, бросай метеор в толпу врагов и следи за своей базой — чем целее она останется, тем больше звёзд и монет получишь.
>
> За монеты прокачивай армию: открывай новых бойцов, усиливай их, ускоряй добычу еды и укрепляй базу. 20 уровней на лугу и в пещерах, новые враги почти на каждом шаге.

**Как играть** (≤ 1000):

> Нажимай на карточки бойцов внизу экрана — они выходят из твоей базы и идут в бой (на компьютере — клавиши 1–6). Каждый боец стоит еды, еда копится сама.
>
> Нажимай на руду на поле — она даёт еду. Кнопка метеора (клавиша Q) бросает камень в выбранное место.
>
> Враги приходят волнами. Защищай свою базу слева и разрушь базу врага справа. Чем больше здоровья у твоей базы в конце, тем больше звёзд.
>
> После боя трать монеты на улучшения: сила армии, скорость еды, прочность базы, новые бойцы и их уровни. Если уровень не проходится — прокачайся и попробуй снова. Esc — пауза.

## Описание — English

**Name**: `Mine Rush: Cube Battle`

**Short**: `Build an army of cube monsters and smash the enemy base!`

**SEO**: `Mine Rush is a one-lane battle: gather food, send zombies and archers, hold off enemy waves and destroy their base. Upgrades, bosses, 20 levels.`

**About**:

> Mine Rush is a fun battle of cube monsters on a single road! Your base is on the left, the enemy base on the right, the battlefield in between.
>
> Gather food, send out fighters and hold off enemy waves. Cube zombies hold the line, bone archers shoot from afar, and the jelly cube soaks up hits. Each wave comes as a pack, and the last one is led by a huge leader. Bosses wait on levels 10 and 20 — the Zombie King and the Stone Golem.
>
> Mine ore right on the field, drop a meteor on enemy crowds and keep your base safe — the more of it survives, the more stars and coins you get.
>
> Spend coins on your army: unlock new fighters, level them up, speed up food and make your base tougher. 20 levels across meadows and caves, with new enemies almost every step.

**How to play**:

> Tap the fighter cards at the bottom — they leave your base and march into battle (keys 1–6 on PC). Each fighter costs food; food builds up by itself.
>
> Tap ore on the field for extra food. The meteor button (Q key) drops a rock where you choose.
>
> Enemies come in waves. Protect your base on the left and destroy the enemy base on the right. The more health your base keeps, the more stars you earn.
>
> After a battle spend coins on upgrades: army power, food speed, base health, new fighters and their levels. Stuck on a level? Upgrade and try again. Esc pauses the game.

## Картинки

- `build/store/icon_512.png` — иконка 512×512 (из `design/.../v2/brand/store_icon.svg`).
- `build/store/cover_800x470.png` — обложка 800×470 (`store_cover.svg`, по высоте, середина).
- `build/store/shot_*.png` — скриншоты 1920×1080: меню, улучшения, карта, бой. Снимаются `tools/shot.gd` с `--resolution 1920x1080`.
