"""Copy non-unit art from Claude Design into art/ with import presets.

Copies projectiles, effects, UI, icons, HUD, bases, battlefields, decor, menu
screens and logos. Skips store_* (catalog art), style_guide and the
screen_upgrades layout reference. c2pa metadata is stripped.

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
]

SKIP_PREFIXES = ("store_", "style_guide", "screen_upgrades")
# Logos are big (1024x384) — import at half size, lossless for crisp edges.
OVERRIDES: dict[str, tuple[float, int]] = {
	"logo_ru": (0.5, LOSSLESS),
	"logo_en": (0.5, LOSSLESS),
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
