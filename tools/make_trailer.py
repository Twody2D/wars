"""Cuts the store gameplay video (Yandex: MP4, 16:9, height >= 400, <= 100 MB,
<= 28 s) out of the raw Movie Maker recording.

Input: build/store/raw.avi and build/store/events.json from
tools/record_trailer.gd (1920×1080, sound effects only, no music).
Output: build/store/trailer.mp4 — 1920×1080 H.264 + AAC: gameplay from the
first frame, the whole screen (no zoom), smooth transitions between the
parts (xfade), the store cover as an end card, one continuous music track.

Needs imageio-ffmpeg. Run: py -3.14 tools/make_trailer.py
"""

import json
import subprocess
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "build" / "store"
MUSIC = ROOT / "audio" / "music" / "battle.ogg"
# End card: the store cover (Claude Design, 1600×940) if it is there, else the
# first frame of the recording.
COVER = STORE / "new" / "store_cover_A_master.png"
MAX_SEC = 28.0

# (anchor event, offset s, length s, transition into the NEXT part).
# "a|b" — anchor a, or b if a did not happen; "end" is the end card.
# m_ — meadow battle, c_ — cave battle. Transitions are ffmpeg xfade names.
SEGMENTS: list[tuple[str, float, float, str]] = [
    ("m_battle", 0.2, 4.2, "fade"),          # armies already on the field, cards pressed
    ("m_final", -0.3, 3.2, "fade"),          # "final wave", the Zombie King
    ("m_meteor", -0.3, 2.4, "fade"),         # meteor into the crowd
    ("m_broken", -1.0, 2.6, "fade"),         # the boss falls, the shield is gone
    ("m_over", -1.4, 3.6, "smoothleft"),     # the base falls, victory, stars
    ("upgrades", 0.1, 3.4, "smoothleft"),    # upgrades, new goblin and bomber
    ("c_battle", 0.3, 3.6, "fade"),          # cave: goblins and bombers
    ("c_final", -0.2, 2.8, "fade"),          # the Stone Golem
    ("c_over", -1.6, 3.8, "fade"),           # victory
    ("end", 0.0, 2.0, ""),
]
XFADE = 0.45
MUSIC_VOLUME = 0.55
SFX_VOLUME = 1.0
FADE_OUT = 0.6


def main() -> None:
    events: dict[str, float] = json.loads((STORE / "events.json").read_text(encoding="utf-8"))
    parts: list[str] = []
    for i, (anchor, offset, length, _) in enumerate(SEGMENTS):
        if anchor == "end":
            # Still image input 2, silent audio from anullsrc (input 3).
            v = (f"[2:v]trim=duration={length:.3f},setpts=PTS-STARTPTS,"
                 f"scale=1920:-2:out_range=tv,crop=1920:1080")
            a = f"[3:a]atrim=duration={length:.3f},asetpts=PTS-STARTPTS"
        else:
            found = [events[name] for name in anchor.split("|") if name in events]
            if not found:
                raise SystemExit(f"no event {anchor} in events.json")
            start = max(0.0, found[0] + offset)
            v = (f"[0:v]trim=start={start:.3f}:duration={length:.3f},setpts=PTS-STARTPTS,"
                 f"scale=1920:1080:flags=lanczos:in_range=pc:out_range=tv")
            a = (f"[0:a]atrim=start={start:.3f}:duration={length:.3f},asetpts=PTS-STARTPTS,"
                 f"volume={SFX_VOLUME}")
        parts.append(v + f",fps=30,settb=AVTB,format=yuv420p,setsar=1[v{i}]")
        parts.append(a + f",aformat=sample_rates=48000:channel_layouts=stereo[a{i}]")

    # Chain the parts: each transition overlaps the previous part's tail.
    v_prev, a_prev = "[v0]", "[a0]"
    elapsed = SEGMENTS[0][2]
    for i in range(1, len(SEGMENTS)):
        transition = SEGMENTS[i - 1][3]
        offset = elapsed - XFADE
        parts.append(f"{v_prev}[v{i}]xfade=transition={transition}:duration={XFADE}:offset={offset:.3f}[vx{i}]")
        parts.append(f"{a_prev}[a{i}]acrossfade=d={XFADE}[ax{i}]")
        v_prev, a_prev = f"[vx{i}]", f"[ax{i}]"
        elapsed = offset + SEGMENTS[i][2]
    total = elapsed
    if total > MAX_SEC:
        raise SystemExit(f"trailer is {total:.1f} s, Yandex allows {MAX_SEC} s")

    parts.append(f"{v_prev}fade=t=out:st={total - FADE_OUT:.3f}:d={FADE_OUT}[vout]")
    parts.append(f"[1:a]atrim=duration={total:.3f},volume={MUSIC_VOLUME},"
                 f"afade=t=out:st={total - FADE_OUT - 0.6:.3f}:d={FADE_OUT + 0.6}[m]")
    parts.append(f"{a_prev}[m]amix=inputs=2:normalize=0[aout]")

    out = STORE / "trailer.mp4"
    cmd = [imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-y",
           "-i", str(STORE / "raw.avi"), "-i", str(MUSIC),
           "-loop", "1", "-framerate", "30", "-i", str(COVER if COVER.exists() else STORE / "end_card.png"),
           "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
           "-filter_complex", ";".join(parts), "-map", "[vout]", "-map", "[aout]",
           "-c:v", "libx264", "-preset", "slow", "-crf", "20", "-pix_fmt", "yuv420p", "-r", "30",
           "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", "-t", f"{total:.3f}", str(out)]
    subprocess.run(cmd, check=True, cwd=ROOT)
    print(f"{out.relative_to(ROOT).as_posix()}: {total:.1f} s, {out.stat().st_size / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
