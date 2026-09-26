"""UI pieces in the v1 "wood & pixel" style (design screen_upgrades v1):
notched pixel corners, a darker lip at the bottom, a light glint top-left.
Colors and shapes are taken from the mockup; the game stretches them as
9-slice boxes (texture margins in scenes/ui/theme.tres).

Also cuts the tab icons (upgrades arrow, map) out of the mockup SVG.

Writes art/ui/wood/*.svg. Run: py -3.14 tools/gen_ui_wood.py
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "ui" / "wood"
MOCKUP = ROOT / "design" / "Art sections 1 and 2 complete" / "assets" / "screens" / "screen_upgrades.svg"
INK = "#1B1B2F"


def notched(x: float, y: float, w: float, h: float, n: float) -> str:
    """Rectangle with square pixel notches of size n in the corners."""
    r, b = x + w, y + h
    return (f"M{x + n} {y}H{r - n}V{y + n}H{r}V{b - n}H{r - n}V{b}H{x + n}V{b - n}H{x}V{y + n}H{x + n}Z")


def svg(w: int, h: int, body: str) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
            f'<g transform="translate(2 2)">{body}</g>\n</svg>\n')


def block(w: int, h: int, face: str, lip: str, glint: str | None, pressed: bool = False, notch: int = 8) -> str:
    """A button / tab: ink outline filled with the lip color, the face on top
    leaves `lip` px of it visible at the bottom. Pressed: face sits lower."""
    lip_h = 3 if pressed else 10
    top = 7 if pressed else 1.5
    body = f'<path d="{notched(0, 0, w, h, notch)}" fill="{lip}" stroke="{INK}" stroke-width="3"/>'
    body += f'<path d="{notched(1.5, top, w - 3, h - top - lip_h - 1.5, notch - 1.5)}" fill="{face}"/>'
    if glint:
        gy = top + 7
        body += f'<path d="M10 {gy}h40v5h-35v5h-5z" fill="{glint}"/>'
    return svg(w + 4, h + 4, body)


def card(w: int, h: int, frame: str, lip: str) -> str:
    body = f'<path d="{notched(0, 0, w, h, 8)}" fill="{frame}" stroke="{INK}" stroke-width="3"/>'
    body += f'<path d="M2 {h - 7}h{w - 4}v5.5h-{w - 4}z" fill="{lip}"/>'
    for cx, cy in ((4, 4), (w - 10, 4), (4, h - 10), (w - 10, h - 10)):
        body += f'<path d="M{cx} {cy}h6v6h-6z" fill="#A7ABBD"/>'
    return svg(w + 4, h + 4, body)


def panel(w: int, h: int) -> str:
    """Big wooden frame with a cream sheet inside (the upgrades panel)."""
    body = f'<path d="{notched(0, 0, w, h, 10)}" fill="#6E4526" stroke="{INK}" stroke-width="3"/>'
    body += f'<path d="{notched(2, 6, w - 4, h - 12, 6)}" fill="#A8703F"/>'
    body += f'<rect x="16" y="16" width="{w - 32}" height="{h - 32}" fill="#F2EEDF" stroke="{INK}" stroke-width="3"/>'
    body += f'<path d="M17.5 17.5h{w - 35}v6h-{w - 35}z" fill="#CFC6A8"/>'
    return svg(w + 4, h + 4, body)


def pip(face: str, shade: str) -> str:
    body = f'<rect x="0" y="0" width="24" height="18" fill="{face}" stroke="{INK}" stroke-width="3"/>'
    body += f'<path d="M1.5 12h21v4.5h-21z" fill="{shade}"/>'
    return svg(28, 22, body)


def cut_icon(name: str, x: float, y: float, w: float, h: float) -> None:
    """Copies the mockup shapes that start inside the box into a small SVG."""
    src = MOCKUP.read_text(encoding="utf-8")
    keep: list[str] = []
    for el in re.findall(r"<(?:rect|path)[^>]*>(?:</(?:rect|path)>)?", src):
        m = re.search(r'\bx="([\d.]+)"[^>]*\by="([\d.]+)"', el) or re.search(r'd="M\s*([\d.]+)[ ,]([\d.]+)', el)
        if m and x <= float(m.group(1)) <= x + w and y <= float(m.group(2)) <= y + h:
            keep.append(el)
    out = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{x} {y} {w} {h}">\n'
           + "".join(keep) + "\n</svg>\n")
    (OUT / name).write_text(out, encoding="utf-8")
    print(f"{name}: {len(keep)} shapes")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    styles = {
        # name: face, lip, glint, hover face
        "green": ("#6CCB4A", "#3F9A36", "#B4E86A", "#82DB60"),
        "yellow": ("#FFD23F", "#E0A800", "#FFFFFF", "#FFDD66"),
        "brown": ("#A8703F", "#6E4526", "#C99260", "#BA7F4B"),
        "red": ("#FF5A4E", "#B8323A", "#FFB0A8", "#FF7468"),
        "gray": ("#A7ABBD", "#7A7F96", None, "#A7ABBD"),
    }
    files: dict[str, str] = {}
    for name, (face, lip, glint, hover) in styles.items():
        files[f"btn_{name}_normal.svg"] = block(96, 72, face, lip, glint)
        files[f"btn_{name}_hover.svg"] = block(96, 72, hover, lip, glint)
        files[f"btn_{name}_pressed.svg"] = block(96, 72, face, lip, glint, pressed=True)
    files["card_wood.svg"] = card(120, 150, "#A8703F", "#6E4526")
    files["card_locked.svg"] = card(120, 150, "#7A7F96", "#565A6E")
    files["panel_wood.svg"] = panel(160, 160)
    files["pip_full.svg"] = pip("#6CCB4A", "#3F9A36")
    files["pip_empty.svg"] = pip("#CFC6A8", "#B3A987")
    for name, text in files.items():
        (OUT / name).write_text(text, encoding="utf-8")
        print(name)
    cut_icon("tab_icon_upgrades.svg", 872, 604, 48, 44)
    cut_icon("tab_icon_map.svg", 1120, 624, 64, 48)


if __name__ == "__main__":
    main()
