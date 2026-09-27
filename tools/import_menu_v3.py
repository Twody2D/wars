"""Copies the menu redesign v3 from Claude Design into the game.

design/Mine Rush menu redesign/kit/*.svg  -> art/ui/v3/*.svg and
kit_battle/*.svg -> art/ui/v3/battle/*.svg (C2PA metadata stripped: ~6 KB per
file that Godot does not need);
design/.../assets/*.png (characters for the menu)  -> art/ui/v3/chars/;
kit/map_nodes.json  -> the map node centres, printed for scenes/menu/main.tscn.
Also writes two soft ground shadows (radial gradients) for the menu characters.

Run: py -3.14 tools/import_menu_v3.py
"""

import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "Mine Rush menu redesign"
OUT = ROOT / "art" / "ui" / "v3"
CHARS = ["zombie_blue", "zombie_red", "skeleton_blue", "skeleton_red", "slime_blue",
         "spider_blue", "art_goblin", "art_barrel", "king_face", "golem_face"]

SHADOW = """<svg xmlns="http://www.w3.org/2000/svg" width="160" height="32" viewBox="0 0 160 32">
<defs><radialGradient id="g" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="{c}" stop-opacity="{a}"/><stop offset="1" stop-color="{c}" stop-opacity="0"/>
</radialGradient></defs><ellipse cx="80" cy="16" rx="80" ry="16" fill="url(#g)"/></svg>
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "chars").mkdir(exist_ok=True)
    (OUT / "battle").mkdir(exist_ok=True)
    total = 0
    for kit, out in (("kit", OUT), ("kit_battle", OUT / "battle")):
        for svg in sorted((SRC / kit).glob("*.svg")):
            text = svg.read_text(encoding="utf-8")
            text = re.sub(r"<metadata>.*?</metadata>", "", text, flags=re.S)
            text = text.replace(' xmlns:c2pa="http://c2pa.org/manifest"', "")
            (out / svg.name).write_text(text, encoding="utf-8", newline="\n")
            total += len(text.encode("utf-8"))
    for name in CHARS:
        shutil.copyfile(SRC / "assets" / f"{name}.png", OUT / "chars" / f"{name}.png")
        total += (OUT / "chars" / f"{name}.png").stat().st_size
    (OUT / "shadow_dark.svg").write_text(SHADOW.format(c="#0A1E14", a="0.4"), encoding="utf-8", newline="\n")
    (OUT / "shadow_red.svg").write_text(SHADOW.format(c="#C81E28", a="0.45"), encoding="utf-8", newline="\n")
    print(f"art/ui/v3: {total / 1024:.0f} KB")
    nodes = json.loads((SRC / "kit" / "map_nodes.json").read_text(encoding="utf-8"))["nodes"]
    print("map_nodes = PackedVector2Array(" + ", ".join(f"{n['x']}, {n['y']}" for n in nodes) + ")")


if __name__ == "__main__":
    main()
