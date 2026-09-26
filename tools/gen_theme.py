"""Writes scenes/ui/theme.tres — the game theme in the v1 "wood & pixel" style
(art/ui/wood from tools/gen_ui_wood.py). Type variations used by the scenes:

  Button (green), GoldButton (yellow), SecondaryButton (brown), DangerButton (red),
  IconButton (brown, square), TabButton (brown), TabGreen (the Battle tab),
  TabActive (yellow, pops up), DebugButton;
  Panel/PanelContainer (wooden frame, cream sheet), CardPanel / LockedCard
  (unit cards), RowPanel (white row), PortraitWindow / PortraitLocked (sky
  window of a unit card), PlatePanel (cream plate under the pips), BandPanel
  (dark wood of the bottom tab bar), PillPanel (dark counter);
  Label (white, ink outline), InkLabel (ink on light), AccentLabel, TitleLabel.

Run: py -3.14 tools/gen_theme.py
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "scenes" / "ui" / "theme.tres"

INK = "Color(0.105882, 0.105882, 0.184314, 1)"
WHITE = "Color(1, 1, 1, 1)"


def color(hex_: str) -> str:
    h = hex_.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.6g}, {g:.6g}, {b:.6g}, 1)"


class Theme:
    def __init__(self) -> None:
        self.ext: list[str] = []
        self.ext_ids: dict[str, str] = {}
        self.subs: list[str] = []
        self.props: list[str] = []

    def res(self, path: str, type_: str = "Texture2D") -> str:
        if path not in self.ext_ids:
            rid = f"{len(self.ext) + 1}_{Path(path).stem}"
            self.ext_ids[path] = rid
            self.ext.append(f'[ext_resource type="{type_}" path="{path}" id="{rid}"]')
        return self.ext_ids[path]

    def tex_box(self, sid: str, tex: str, tm: tuple[float, float, float, float],
                cm: tuple[float, float, float, float], expand_top: float = 0.0) -> str:
        l, t, r, b = tm
        cl, ct, cr, cb = cm
        lines = [f'[sub_resource type="StyleBoxTexture" id="{sid}"]',
                 f"content_margin_left = {cl:.1f}", f"content_margin_top = {ct:.1f}",
                 f"content_margin_right = {cr:.1f}", f"content_margin_bottom = {cb:.1f}",
                 f'texture = ExtResource("{self.res(tex)}")',
                 f"texture_margin_left = {l:.1f}", f"texture_margin_top = {t:.1f}",
                 f"texture_margin_right = {r:.1f}", f"texture_margin_bottom = {b:.1f}"]
        if expand_top:
            lines.append(f"expand_margin_top = {expand_top:.1f}")
        self.subs.append("\n".join(lines))
        return sid

    def flat(self, sid: str, bg: str, border: int, margins: tuple[float, float, float, float]) -> str:
        l, t, r, b = margins
        lines = [f'[sub_resource type="StyleBoxFlat" id="{sid}"]',
                 f"content_margin_left = {l:.1f}", f"content_margin_top = {t:.1f}",
                 f"content_margin_right = {r:.1f}", f"content_margin_bottom = {b:.1f}",
                 f"bg_color = {color(bg)}"]
        if border:
            lines += [f"border_width_left = {border}", f"border_width_top = {border}",
                      f"border_width_right = {border}", f"border_width_bottom = {border}",
                      f"border_color = {INK}"]
        self.subs.append("\n".join(lines))
        return sid

    def set(self, key: str, value: str) -> None:
        self.props.append(f"{key} = {value}")

    def button(self, type_: str, kind: str, tab: bool = False, base: str | None = "Button") -> None:
        """Normal / hover / pressed / disabled boxes for one color."""
        w = "res://art/ui/wood/"
        tm = (14.0, 14.0, 14.0, 18.0)
        cm = (18.0, 8.0, 18.0, 16.0)
        cm_pressed = (18.0, 12.0, 18.0, 10.0)
        n = self.tex_box(f"{kind}_normal", f"{w}btn_{kind}_normal.svg", tm, cm)
        h = self.tex_box(f"{kind}_hover", f"{w}btn_{kind}_hover.svg", tm, cm)
        p = self.tex_box(f"{kind}_pressed", f"{w}btn_{kind}_pressed.svg", tm, cm_pressed)
        if base:
            self.set(f"{type_}/base_type", f'&"{base}"')
        self.set(f"{type_}/styles/normal", f'SubResource("{n}")')
        self.set(f"{type_}/styles/hover", f'SubResource("{h}")')
        self.set(f"{type_}/styles/pressed", f'SubResource("{p}")')
        self.set(f"{type_}/styles/hover_pressed", f'SubResource("{p}")')
        if not tab:
            self.set(f"{type_}/styles/disabled", 'SubResource("gray_normal")')

    def write(self) -> None:
        head = f"[gd_resource type=\"Theme\" load_steps={len(self.ext) + len(self.subs) + 1} format=3]\n\n"
        text = head + "\n".join(self.ext) + "\n\n" + "\n\n".join(self.subs) + "\n\n[resource]\n" \
            + "\n".join(sorted(self.props, key=lambda s: s.split(" = ")[0])) + "\n"
        OUT.write_text(text, encoding="utf-8", newline="\n")
        print(OUT.relative_to(ROOT).as_posix())


def main() -> None:
    t = Theme()
    w = "res://art/ui/wood/"
    font = t.res("res://art/fonts/rubik_extrabold.tres", "FontVariation")
    t.set("default_font", f'ExtResource("{font}")')
    t.set("default_font_size", "26")

    # Disabled look shared by every button.
    t.tex_box("gray_normal", f"{w}btn_gray_normal.svg", (14.0, 14.0, 14.0, 18.0), (18.0, 8.0, 18.0, 16.0))

    t.button("Button", "green", base=None)
    for state in ("font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"):
        t.set(f"Button/colors/{state}", WHITE)
    t.set("Button/colors/font_disabled_color", "Color(0.92, 0.92, 0.95, 1)")
    t.set("Button/colors/font_outline_color", INK)
    t.set("Button/constants/outline_size", "8")
    t.set("Button/constants/h_separation", "10")
    t.set("Button/font_sizes/font_size", "32")
    t.subs.append('[sub_resource type="StyleBoxEmpty" id="empty"]')
    t.set("Button/styles/focus", 'SubResource("empty")')

    t.button("GoldButton", "yellow")
    t.button("SecondaryButton", "brown")
    t.button("DangerButton", "red")
    t.button("IconButton", "brown")

    # Bottom tabs: brown, the Battle tab green, the open one yellow and taller.
    t.button("TabButton", "brown", tab=True)
    t.set("TabButton/font_sizes/font_size", "26")
    t.button("TabGreen", "green", tab=True)
    t.set("TabGreen/font_sizes/font_size", "26")
    active = t.tex_box("tab_active", f"{w}btn_yellow_normal.svg", (14.0, 14.0, 14.0, 18.0),
                      (18.0, 8.0, 18.0, 16.0), expand_top=18.0)
    t.set("TabActive/base_type", '&"Button"')
    for state in ("normal", "hover", "pressed", "hover_pressed"):
        t.set(f"TabActive/styles/{state}", f'SubResource("{active}")')
    t.set("TabActive/font_sizes/font_size", "26")

    t.flat("debug", "#1B1B2F", 0, (6.0, 2.0, 6.0, 2.0))
    t.subs[-1] = t.subs[-1].replace(f"bg_color = {color('#1B1B2F')}", "bg_color = Color(0.105882, 0.105882, 0.184314, 0.8)")
    t.set("DebugButton/base_type", '&"Button"')
    t.set("DebugButton/constants/outline_size", "0")
    t.set("DebugButton/font_sizes/font_size", "14")
    for state in ("normal", "hover", "pressed", "disabled"):
        t.set(f"DebugButton/styles/{state}", 'SubResource("debug")')

    panel = t.tex_box("panel", f"{w}panel_wood.svg", (24.0, 26.0, 24.0, 24.0), (32.0, 30.0, 32.0, 28.0))
    t.set("Panel/styles/panel", f'SubResource("{panel}")')
    t.set("PanelContainer/styles/panel", f'SubResource("{panel}")')
    card = t.tex_box("card", f"{w}card_wood.svg", (14.0, 14.0, 14.0, 16.0), (10.0, 10.0, 10.0, 14.0))
    t.set("CardPanel/base_type", '&"PanelContainer"')
    t.set("CardPanel/styles/panel", f'SubResource("{card}")')
    locked = t.tex_box("card_locked", f"{w}card_locked.svg", (14.0, 14.0, 14.0, 16.0), (10.0, 10.0, 10.0, 14.0))
    t.set("LockedCard/base_type", '&"PanelContainer"')
    t.set("LockedCard/styles/panel", f'SubResource("{locked}")')

    for name, bg, border, m in (("RowPanel", "#FFFFFF", 3, (14.0, 8.0, 14.0, 8.0)),
                                ("PortraitWindow", "#9FDCFF", 3, (4.0, 4.0, 4.0, 4.0)),
                                ("PortraitLocked", "#A7ABBD", 3, (4.0, 4.0, 4.0, 4.0)),
                                ("PlatePanel", "#F2EEDF", 3, (8.0, 5.0, 8.0, 5.0)),
                                ("BandPanel", "#6E4526", 3, (0.0, 0.0, 0.0, 0.0)),
                                ("PillPanel", "#2B2740", 3, (10.0, 4.0, 18.0, 4.0))):
        sid = t.flat(name.lower(), bg, border, m)
        t.set(f"{name}/base_type", '&"PanelContainer"')
        t.set(f"{name}/styles/panel", f'SubResource("{sid}")')

    t.set("Label/colors/font_color", WHITE)
    t.set("Label/colors/font_outline_color", INK)
    t.set("Label/constants/outline_size", "8")
    t.set("InkLabel/base_type", '&"Label"')
    t.set("InkLabel/colors/font_color", INK)
    t.set("InkLabel/constants/outline_size", "0")
    t.set("AccentLabel/base_type", '&"Label"')
    t.set("AccentLabel/colors/font_color", "Color(0.623529, 0.890196, 0.345098, 1)")
    t.set("AccentLabel/font_sizes/font_size", "26")
    t.set("TitleLabel/base_type", '&"Label"')
    t.set("TitleLabel/font_sizes/font_size", "48")
    t.write()


if __name__ == "__main__":
    main()
