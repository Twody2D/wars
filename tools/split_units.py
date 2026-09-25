"""Split Claude Design unit/boss SVGs into per-part SVGs + pivots.json.

For every unit_*.svg / boss_*.svg in the design assets:
  art/units/<id>/<part>.svg   same viewBox, only one group, c2pa metadata removed
  art/units/<id>/pivots.json  pivot per part, rest rotation, draw order

Pivot: group transform="rotate(a cx cy)" gives (cx, cy) and rest angle a
(the transform itself is removed from the part). Otherwise by bbox:
arms/legs - top centre, head - bottom centre, everything else - centre.

Usage: python tools/split_units.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DESIGN = ROOT / "design"
OUT = ROOT / "art" / "units"

# Units render at 64 px (256 * 0.25); textures are imported at 0.5 and scaled
# down on the node for sharper edges on large screens.
IMPORT_SCALE = 0.5
DISPLAY_SCALE = 0.25
FEET_Y = {256: 240.0, 512: 480.0}

GROUP_RE = re.compile(r'<g id="([^"]+)"([^>]*)>(.*?)</g>', re.S)
ROTATE_RE = re.compile(r'rotate\(\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*\)')
SVG_OPEN_RE = re.compile(r"<svg[^>]*>")
RECT_RE = re.compile(r"<rect([^>]*)>")
PATH_RE = re.compile(r'<path[^>]*\sd="([^"]+)"')
ATTR_RE = re.compile(r'(\w+)="([^"]*)"')
TOKEN_RE = re.compile(r"[A-Za-z]|-?\d*\.?\d+(?:e-?\d+)?")
SIZE_RE = re.compile(r'viewBox="0 0 (\d+) (\d+)"')


def find_assets_dir() -> Path:
	for candidate in sorted(DESIGN.glob("*/assets")):
		if (candidate / "units").is_dir():
			return candidate
	sys.exit("design/*/assets/units not found")


def path_points(d: str) -> list[tuple[float, float]]:
	"""Points of an SVG path using only M/L/H/V/Z (abs + rel)."""
	points: list[tuple[float, float]] = []
	x = y = 0.0
	start = (0.0, 0.0)
	cmd = ""
	tokens = TOKEN_RE.findall(d)
	i = 0
	while i < len(tokens):
		t = tokens[i]
		if t.isalpha():
			cmd = t
			i += 1
			if cmd in "Zz":
				x, y = start
			continue
		if cmd in "MmLl":
			nx, ny = float(tokens[i]), float(tokens[i + 1])
			i += 2
			if cmd.islower():
				nx, ny = x + nx, y + ny
			x, y = nx, ny
			if cmd in "Mm":
				start = (x, y)
				cmd = "l" if cmd == "m" else "L"
		elif cmd in "Hh":
			v = float(t)
			i += 1
			x = x + v if cmd == "h" else v
		elif cmd in "Vv":
			v = float(t)
			i += 1
			y = y + v if cmd == "v" else v
		else:
			sys.exit(f"unsupported path command {cmd!r} in {d[:40]}")
		points.append((x, y))
	return points


def group_bbox(content: str) -> tuple[float, float, float, float]:
	xs: list[float] = []
	ys: list[float] = []
	for attrs in RECT_RE.findall(content):
		a = dict(ATTR_RE.findall(attrs))
		x, y = float(a.get("x", 0)), float(a.get("y", 0))
		xs += [x, x + float(a["width"])]
		ys += [y, y + float(a["height"])]
	for d in PATH_RE.findall(content):
		for px, py in path_points(d):
			xs.append(px)
			ys.append(py)
	if not xs:
		sys.exit("empty group")
	return min(xs), min(ys), max(xs), max(ys)


def pivot_for(part: str, bbox: tuple[float, float, float, float]) -> tuple[float, float]:
	x0, y0, x1, y1 = bbox
	cx = (x0 + x1) / 2
	if part.startswith(("arm_", "leg_")):
		return cx, y0
	if part == "head":
		return cx, y1
	return cx, (y0 + y1) / 2


def split(svg_path: Path) -> str:
	text = svg_path.read_text(encoding="utf-8")
	text = re.sub(r"<metadata>.*?</metadata>", "", text, flags=re.S)
	text = text.replace(' xmlns:c2pa="http://c2pa.org/manifest"', "")
	svg_open = SVG_OPEN_RE.search(text).group(0)
	size = int(SIZE_RE.search(svg_open).group(1))
	unit_id = svg_path.stem.removeprefix("unit_")
	out_dir = OUT / unit_id
	out_dir.mkdir(parents=True, exist_ok=True)

	parts: dict[str, dict] = {}
	order: list[str] = []
	for part, attrs, content in GROUP_RE.findall(text):
		rot = ROTATE_RE.search(attrs)
		if rot:
			rest = float(rot.group(1))
			pivot = (float(rot.group(2)), float(rot.group(3)))
		else:
			rest = 0.0
			pivot = pivot_for(part, group_bbox(content))
		part_svg = f'{svg_open}<g id="{part}">{content}</g></svg>\n'
		(out_dir / f"{part}.svg").write_text(part_svg, encoding="utf-8", newline="\n")
		parts[part] = {"pivot": [round(pivot[0], 2), round(pivot[1], 2)], "rest_deg": rest}
		order.append(part)

	data = {
		"id": unit_id,
		"size": size,
		"feet": [size / 2, FEET_Y[size]],
		"import_scale": IMPORT_SCALE,
		"display_scale": DISPLAY_SCALE,
		"order": order,
		"parts": parts,
	}
	(out_dir / "pivots.json").write_text(json.dumps(data, indent="\t") + "\n", encoding="utf-8", newline="\n")
	write_import_files(out_dir, order)
	return f"{unit_id}: {len(order)} parts ({', '.join(order)})"


def write_import_files(out_dir: Path, parts: list[str]) -> None:
	"""Seed .import files so Godot imports parts at IMPORT_SCALE (lossless)."""
	for part in parts:
		imp = out_dir / f"{part}.svg.import"
		if imp.exists():
			continue
		imp.write_text(
			'[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
			f"[params]\n\ncompress/mode=0\nmipmaps/generate=false\nsvg/scale={IMPORT_SCALE}\n",
			encoding="utf-8",
			newline="\n",
		)


def main() -> None:
	assets = find_assets_dir()
	sources = sorted((assets / "units").glob("unit_*.svg")) + sorted((assets / "bosses").glob("boss_*.svg"))
	sources = [p for p in sources if not p.stem.endswith("_parts")]
	for src in sources:
		print(split(src))


if __name__ == "__main__":
	main()
