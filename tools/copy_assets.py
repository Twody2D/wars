"""Copy non-unit art from Claude Design into art/ with import presets.

Copies projectiles, effects, UI, icons, HUD, bases, battlefields, decor, menu
screens, logos and the v2 UI kit. Skips store_* (catalog art), style_guide and
screen_* layout mockups. c2pa metadata is stripped.

Each copied file gets a seeded .import (only if missing) with the SVG scale
and compression from SPEC 11, so Godot imports it right the first time.

Usage: python tools/copy_assets.py
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DESIGN = ROOT / "design"
ART = ROOT / "art"

LOSSLESS = 0
LOSSY = 1

# (source dir relative to assets, target dir relative to art, svg scale, compress mode)
RULES: list[tuple[str, str, float, int]] = [
	("projectiles", "projectiles", 0.5, LOSSLESS),
	("fx", "fx", 0.5, LOSSLESS),
	("ui", "ui", 1.0, LOSSLESS),
	("ui/icons", "ui/icons", 0.5, LOSSLESS),
	("hud", "hud", 1.0, LOSSLESS),
	("bases", "bases", 1.0, LOSSLESS),
	("battle", "battle", 1.0, LOSSY),
	("battle/decor", "battle/decor", 1.0, LOSSLESS),
	("screens", "screens", 1.0, LOSSY),
	# UI redesign v2 (docs/PROMPTS.md «Редизайн v2»).
	("v2/buttons", "ui/buttons", 1.0, LOSSLESS),
	("v2/panels", "ui/panels", 1.0, LOSSLESS),
	("v2/upgrades", "ui/upgrades", 1.0, LOSSLESS),
	("v2/hud", "hud", 1.0, LOSSLESS),
	("v2/screens", "screens", 1.0, LOSSY),
	("v2/brand", "screens", 1.0, LOSSLESS),
]

# store_* — catalog art (uploaded to the console, not the game); screen_* — layout mockups.
SKIP_PREFIXES = ("store_", "style_guide", "screen_")
# how_to_play illustrations have crisp pixel edges — keep them lossless.
OVERRIDES: dict[str, tuple[float, int]] = {
	"how_to_play_1": (1.0, LOSSLESS),
	"how_to_play_2": (1.0, LOSSLESS),
	"how_to_play_3": (1.0, LOSSLESS),
}


def find_assets_dir() -> Path:
	for candidate in sorted(DESIGN.glob("*/assets")):
		if (candidate / "units").is_dir():
			return candidate
	sys.exit("design/*/assets not found")


def clean_svg(text: str) -> str:
	text = re.sub(r"<metadata>.*?</metadata>", "", text, flags=re.S)
	return text.replace(' xmlns:c2pa="http://c2pa.org/manifest"', "")


def seed_import(target: Path, scale: float, mode: int) -> None:
	imp = target.with_name(target.name + ".import")
	if imp.exists():
		return
	lossy = f"compress/lossy_quality=0.8\n" if mode == LOSSY else ""
	imp.write_text(
		'[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
		f"[params]\n\ncompress/mode={mode}\n{lossy}mipmaps/generate=false\nsvg/scale={scale}\n",
		encoding="utf-8",
		newline="\n",
	)


def main() -> None:
	assets = find_assets_dir()
	count = 0
	for src_rel, dst_rel, scale, mode in RULES:
		src_dir = assets / src_rel
		dst_dir = ART / dst_rel
		for src in sorted(src_dir.glob("*.svg")):
			if src.stem.startswith(SKIP_PREFIXES):
				continue
			dst_dir.mkdir(parents=True, exist_ok=True)
			dst = dst_dir / src.name
			dst.write_text(clean_svg(src.read_text(encoding="utf-8")), encoding="utf-8", newline="\n")
			s, m = OVERRIDES.get(src.stem, (scale, mode))
			seed_import(dst, s, m)
			count += 1
	print(f"copied {count} files into {ART.relative_to(ROOT)}")


if __name__ == "__main__":
	main()
