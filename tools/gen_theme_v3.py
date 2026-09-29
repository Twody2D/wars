"""Writes scenes/ui/theme_v3.tres — the glossy menu style v3 (art/ui/v3 from
tools/import_menu_v3.py, Claude Design "Mine Rush menu redesign").

The theme sits on the menu root (scenes/menu/main.tscn); anything it does not
define falls through to the project theme (scenes/ui/theme.tres, wood v1), so
the battle, pause and result keep their look until their own redesign.

Defines: Label (white, dark outline and a drop shadow like the mockup's
text-shadow), Button = green buy button, GreyButton (can't afford), PlayButton,
IconButton (settings), PurpleButton (open the caves, ×2 coins), BlueButton,
PauseButton, BoosterButton (battle), TabButton / TabActive
(bottom tabs, kit_shop: 4 tabs), PriceButton / PriceBigButton / AdButton /
CloseButton (shop, kit_shop; the text and the currency icon are child nodes), MapNode (flat, the level node draws itself), SoftLabel (light
lilac, inactive tabs), GreenLabel (next value / effect), ArrowLabel ("›").
Nine-slice margins come from kit/manifest.json ("top / right / bottom / left").

Run: py -3.14 tools/gen_theme_v3.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_theme import Theme, color  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "scenes" / "ui" / "theme_v3.tres"
V3 = "res://art/ui/v3/"
OUTLINE = color("#1E1B3A")
WHITE = "Color(1, 1, 1, 1)"


def slice_(top: float, right: float, bottom: float, left: float) -> tuple[float, float, float, float]:
    """manifest order (CSS border-image) → StyleBoxTexture order (l, t, r, b)."""
    return (left, top, right, bottom)


def button(t: Theme, type_: str, kind: str, tm: tuple[float, float, float, float],
           cm: tuple[float, float, float, float], disabled: str | None = None, folder: str = V3) -> None:
    l, top, r, b = cm
    pressed_cm = (l, top + 3.0, r, b - 3.0)
    states = {"normal": cm, "hover": cm, "pressed": pressed_cm, "disabled": cm}
    for state, margins in states.items():
        tex = f"{folder}btn_{kind}_{state}.svg"
        if state == "disabled" and disabled:
            tex = f"{V3}btn_{disabled}_normal.svg"
        sid = t.tex_box(f"{type_.lower()}_{state}", tex, tm, margins)
        t.set(f"{type_}/styles/{state}", f'SubResource("{sid}")')
        if state == "pressed":
            t.set(f"{type_}/styles/hover_pressed", f'SubResource("{sid}")')
    if type_ != "Button":
        t.set(f"{type_}/base_type", '&"Button"')


def main() -> None:
    t = Theme()
    t.set("Label/colors/font_color", WHITE)
    t.set("Label/colors/font_outline_color", OUTLINE)
    t.set("Label/colors/font_shadow_color", OUTLINE)
    t.set("Label/constants/outline_size", "7")
    t.set("Label/constants/shadow_offset_x", "0")
    t.set("Label/constants/shadow_offset_y", "4")
    t.set("Label/constants/shadow_outline_size", "7")
    t.set("SoftLabel/base_type", '&"Label"')
    t.set("SoftLabel/colors/font_color", color("#DDE3FF"))
    t.set("GreenLabel/base_type", '&"Label"')
    t.set("GreenLabel/colors/font_color", color("#7CFF5A"))
    t.set("ArrowLabel/base_type", '&"Label"')
    t.set("ArrowLabel/colors/font_color", color("#B8C3FF"))
    t.set("CreamLabel/base_type", '&"Label"')
    t.set("CreamLabel/colors/font_color", color("#FFF3D6"))
    t.set("LilacLabel/base_type", '&"Label"')
    t.set("LilacLabel/colors/font_color", color("#F1E9FF"))

    for state in ("font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color",
                  "font_focus_color", "font_disabled_color"):
        t.set(f"Button/colors/{state}", WHITE)
    t.set("Button/colors/font_outline_color", OUTLINE)
    t.set("Button/constants/outline_size", "7")
    t.set("Button/constants/h_separation", "6")
    t.set("Button/constants/icon_max_width", "34")
    t.set("Button/font_sizes/font_size", "28")
    t.subs.append('[sub_resource type="StyleBoxEmpty" id="empty"]')
    t.set("Button/styles/focus", 'SubResource("empty")')

    # Price buttons 164×66 / 136×66: the face is the top ~44 px, the rest is the 3D edge.
    button(t, "Button", "green", slice_(28, 30, 38, 30), (12.0, 3.0, 12.0, 20.0), disabled="grey")
    button(t, "GreyButton", "grey", slice_(28, 30, 38, 30), (12.0, 3.0, 12.0, 20.0))
    button(t, "PlayButton", "play", slice_(42, 44, 52, 44), (34.0, 18.0, 34.0, 34.0))
    t.set("PlayButton/font_sizes/font_size", "62")
    t.set("PlayButton/constants/icon_max_width", "80")
    t.set("PlayButton/constants/h_separation", "16")
    button(t, "IconButton", "icon", slice_(32, 34, 42, 34), (22.0, 17.0, 22.0, 33.0))
    t.set("IconButton/constants/icon_max_width", "60")
    button(t, "PurpleButton", "purple", slice_(32, 34, 42, 34), (0.0, 0.0, 0.0, 0.0))

    # Battle (kit_battle): blue secondary button, pause, ad boosters.
    battle = V3 + "battle/"
    button(t, "BlueButton", "blue", slice_(28, 30, 38, 30), (12.0, 3.0, 12.0, 20.0), folder=battle)
    button(t, "PauseButton", "pause", slice_(28, 30, 38, 30), (0.0, 0.0, 0.0, 0.0), folder=battle)
    button(t, "BoosterButton", "booster", slice_(28, 30, 62, 30), (0.0, 0.0, 0.0, 0.0), folder=battle)

    # Shop (kit_shop): price buttons with a slot for the currency icon on the
    # left (kept out of the stretch), the rewarded-ad button, the red close button.
    shop = V3 + "shop/"
    button(t, "PriceButton", "price", slice_(26, 26, 30, 56), (0.0, 0.0, 0.0, 0.0), folder=shop)
    button(t, "PriceBigButton", "price_big", slice_(30, 30, 36, 66), (0.0, 0.0, 0.0, 0.0), folder=shop)
    button(t, "AdButton", "ad", slice_(26, 26, 30, 26), (0.0, 0.0, 0.0, 0.0), folder=shop)
    button(t, "CloseButton", "close", slice_(30, 30, 40, 30), (0.0, 0.0, 0.0, 0.0), folder=shop)

    # Bottom tabs (kit_shop, 4 tabs): the active tab is bigger and raised by the scene.
    tab_slice = slice_(32, 34, 42, 34)
    for state, tex in (("normal", "tab_inactive"), ("hover", "tab_hover"), ("pressed", "tab_pressed"),
                       ("hover_pressed", "tab_pressed"), ("disabled", "tab_inactive")):
        sid = t.tex_box(f"tabbutton_{state}", f"{shop}{tex}.svg", tab_slice, (0.0, 0.0, 0.0, 0.0))
        t.set(f"TabButton/styles/{state}", f'SubResource("{sid}")')
    t.set("TabButton/base_type", '&"Button"')
    sid = t.tex_box("tabactive", f"{shop}tab_active.svg", slice_(34, 36, 44, 36), (0.0, 0.0, 0.0, 0.0))
    t.set("TabActive/base_type", '&"Button"')
    for state in ("normal", "hover", "pressed", "hover_pressed", "disabled"):
        t.set(f"TabActive/styles/{state}", f'SubResource("{sid}")')

    t.set("MapNode/base_type", '&"Button"')
    for state in ("normal", "hover", "pressed", "hover_pressed", "disabled"):
        t.set(f"MapNode/styles/{state}", 'SubResource("empty")')

    head = f"[gd_resource type=\"Theme\" load_steps={len(t.ext) + len(t.subs) + 1} format=3]\n\n"
    body = head + "\n".join(t.ext) + "\n\n" + "\n\n".join(t.subs) + "\n\n[resource]\n" \
        + "\n".join(sorted(t.props, key=lambda s: s.split(" = ")[0])) + "\n"
    OUT.write_text(body, encoding="utf-8", newline="\n")
    print(OUT.relative_to(ROOT).as_posix())


if __name__ == "__main__":
    main()
