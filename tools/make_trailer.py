"""Cuts the store gameplay video (Yandex: MP4, 16:9, height >= 400, <= 100 MB,
<= 28 s) out of the raw Movie Maker recording.

Input: build/store/raw.avi and build/store/events.json from
tools/record_trailer.gd (the recording has sound effects only, no music).
Output: build/store/trailer.mp4 — 1920×1080 H.264 + AAC: quick cuts anchored
to events, the slow parts sped up, big captions on a dark plate, the store
cover as an end card (build/store/end_card.png, saved by the recorder), one
continuous music track.

Needs imageio-ffmpeg and fonttools (captions use Rubik at weight 800 — the
variable font defaults to 300). Run: py -3.14 tools/make_trailer.py
"""

import json
import subprocess
from pathlib import Path

import imageio_ffmpeg
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "build" / "store"
FONT_SRC = ROOT / "art" / "fonts" / "rubik.ttf"
FONT = "build/store/rubik_800.ttf"
MUSIC = ROOT / "audio" / "music" / "battle.ogg"
MAX_SEC = 28.0

# (anchor event, offset s, raw length s, speed, caption, caption y in 1080p).
# "" — no caption. "meteor" means the first meteor cast; "end" is the end card.
SEGMENTS: list[tuple[str, float, float, float, str, int]] = [
    ("start", 0.2, 1.8, 1.0, "", 0),
    ("upgrades", 0.1, 2.2, 1.0, "Прокачивай армию", 900),
    ("wave_1", -0.2, 5.0, 1.5, "Отбивай волны врагов", 700),
    ("wave_2", 0.0, 4.0, 1.5, "Собери армию монстров", 700),
    ("meteor", -0.1, 2.7, 1.0, "Бросай метеоры!", 700),
    ("wave_3", -0.1, 3.5, 1.25, "Побеждай боссов!", 700),
    ("wave_3", 8.0, 5.4, 1.5, "", 0),
    ("over", -5.0, 4.9, 1.5, "Разрушь базу врага!", 700),
    ("over", 0.6, 2.2, 1.0, "", 0),
    ("end", 0.0, 2.4, 1.0, "Играй в Mine Rush!", 860),
]
MUSIC_VOLUME = 0.55
SFX_VOLUME = 1.0
FADE_OUT = 0.6


def main() -> None:
    font = ROOT / FONT
    if not font.exists():
        instancer.instantiateVariableFont(TTFont(FONT_SRC), {"wght": 800}).save(font)
    events: dict[str, float] = json.loads((STORE / "events.json").read_text(encoding="utf-8"))
    events["start"] = 0.0
    meteors = [t for name, t in events.items() if name.startswith("meteor")]
    if meteors:
        events["meteor"] = min(meteors)

    parts_v: list[str] = []
    parts_a: list[str] = []
    labels: list[str] = []
    total = 0.0
    for i, (anchor, offset, length, speed, caption, y) in enumerate(SEGMENTS):
        if anchor == "end":
            # Still image input 2, silent audio from anullsrc (input 3).
            v = (f"[2:v]trim=duration={length:.3f},setpts=PTS-STARTPTS,scale=1920:1080,fps=30,"
                 f"format=yuv420p,fade=t=in:d=0.25")
            a = f"[3:a]atrim=duration={length:.3f},asetpts=PTS-STARTPTS[a{i}]"
        else:
            start = events[anchor] + offset
            v = (f"[0:v]trim=start={start:.3f}:duration={length:.3f},setpts=(PTS-STARTPTS)/{speed},"
                 f"scale=1920:1080:flags=lanczos,format=yuv420p")
            a = (f"[0:a]atrim=start={start:.3f}:duration={length:.3f},asetpts=PTS-STARTPTS,"
                 f"atempo={speed},volume={SFX_VOLUME}[a{i}]")
        if caption:
            text_file = STORE / f"caption_{i}.txt"
            text_file.write_text(caption, encoding="utf-8")
            rel = text_file.relative_to(ROOT).as_posix()
            v += (f",drawtext=fontfile={FONT}:textfile={rel}:fontsize=92:fontcolor=white"
                  f":borderw=8:bordercolor=0x1B1B2F:box=1:boxcolor=0x1B1B2F@0.55:boxborderw=22"
                  f":x=(w-text_w)/2:y={y}:alpha='min(1,t/0.15)'")
        parts_v.append(v + f"[v{i}]")
        parts_a.append(a)
        labels.append(f"[v{i}][a{i}]")
        total += length / speed
    if total > MAX_SEC:
        raise SystemExit(f"trailer is {total:.1f} s, Yandex allows {MAX_SEC} s")

    n = len(SEGMENTS)
    graph = ";".join(parts_v + parts_a)
    graph += f";{''.join(labels)}concat=n={n}:v=1:a=1[vc][ac]"
    graph += f";[vc]fade=t=out:st={total - FADE_OUT:.3f}:d={FADE_OUT}[vout]"
    graph += (f";[1:a]atrim=duration={total:.3f},volume={MUSIC_VOLUME},"
              f"afade=t=out:st={total - FADE_OUT - 0.6:.3f}:d={FADE_OUT + 0.6}[m]")
    graph += ";[ac][m]amix=inputs=2:normalize=0[aout]"

    out = STORE / "trailer.mp4"
    cmd = [imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-y",
           "-i", str(STORE / "raw.avi"), "-i", str(MUSIC),
           "-loop", "1", "-i", str(STORE / "end_card.png"),
           "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
           "-filter_complex", graph, "-map", "[vout]", "-map", "[aout]",
           "-c:v", "libx264", "-preset", "slow", "-crf", "20", "-pix_fmt", "yuv420p", "-r", "30",
           "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", str(out)]
    subprocess.run(cmd, check=True, cwd=ROOT)
    print(f"{out.relative_to(ROOT).as_posix()}: {total:.1f} s, {out.stat().st_size / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
