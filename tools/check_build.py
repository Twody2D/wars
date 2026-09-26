"""Checks the web export and packs it for Yandex Games (SPEC 16, T01).

- build/web/index.html must exist (Yandex 1.22: index.html in the zip root);
- file names: ASCII only, no spaces (Yandex 1.21);
- packs build/web/* into build/game.zip (files at the zip root);
- prints sizes and exits with 1 if the zip is over the budget (CLAUDE.md: 10 MB);
- no scene or script uses a class cut out of the web template (custom.build) —
  such nodes turn into empty placeholders only in the browser.

Run: python tools/check_build.py [--max-mb 10]
"""

import argparse
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "build" / "web"
ZIP = ROOT / "build" / "game.zip"
MB = 1024 * 1024


def disabled_classes_used() -> list[str]:
    profile = ROOT / "custom.build"
    if not profile.is_file():
        return []
    disabled = set(re.findall(r'"([A-Z][A-Za-z0-9]+)"', profile.read_text(encoding="utf-8")))
    found: list[str] = []
    for pattern, rx in (("*.tscn", r'type="([A-Za-z0-9]+)"'), ("*.tres", r'type="([A-Za-z0-9]+)"'),
                        ("*.gd", r"([A-Z][A-Za-z0-9]+)\.new\(")):
        for path in ROOT.rglob(pattern):
            rel = path.relative_to(ROOT).as_posix()
            if rel.startswith(("addons/", "build/", "design/", "tests/", "tools/", ".godot/")):
                continue
            for cls in set(re.findall(rx, path.read_text(encoding="utf-8", errors="ignore"))) & disabled:
                found.append(f"{rel}: {cls}")
    return sorted(found)


def bad_name(name: str) -> bool:
    return " " in name or not name.isascii()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-mb", type=float, default=10.0)
    args = parser.parse_args()

    errors: list[str] = []
    if not (WEB / "index.html").is_file():
        errors.append(f"no index.html in {WEB}")
    if (WEB / "sdk.js").exists():
        errors.append("build/web/sdk.js found: the fake Yandex SDK must not be shipped (delete it)")

    for hit in disabled_classes_used():
        errors.append(f"class disabled in the web template (custom.build): {hit}")

    files = sorted(p for p in WEB.rglob("*") if p.is_file()) if WEB.is_dir() else []
    if not files:
        errors.append(f"no files in {WEB}")
    for p in files:
        rel = p.relative_to(WEB).as_posix()
        if bad_name(rel):
            errors.append(f"bad file name (space or non-ASCII): {rel}")

    if errors:
        for e in errors:
            print("ERROR:", e)
        return 1

    ZIP.unlink(missing_ok=True)
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in files:
            z.write(p, p.relative_to(WEB).as_posix())

    with zipfile.ZipFile(ZIP) as z:
        for info in sorted(z.infolist(), key=lambda i: -i.compress_size):
            print(f"{info.compress_size / MB:8.2f} MB  {info.file_size / MB:8.2f} MB raw  {info.filename}")

    size = ZIP.stat().st_size / MB
    print(f"{ZIP.relative_to(ROOT).as_posix()}: {size:.2f} MB (budget {args.max_mb:g} MB)")
    if size > args.max_mb:
        print("ERROR: zip is over budget")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
