"""Game sounds from CC0 packs (SPEC 12): downloads the sources, trims them,
evens out the loudness and writes OGG Vorbis into audio/sfx and audio/music.

Every source is CC0 (public domain) — list and links in docs/AUDIO_CREDITS.md.
Downloads are cached in build/audio_src (not in git). Re-running is safe.

Needs ffmpeg from the pip package imageio-ffmpeg:
    py -3.14 -m pip install --user imageio-ffmpeg
Run: py -3.14 tools/import_sounds.py
"""

import subprocess
import urllib.request
import zipfile
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "build" / "audio_src"
OUT = ROOT / "audio"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

OGA = "https://opengameart.org/sites/default/files/"
KENNEY = "https://kenney.nl/media/pages/assets/"
# name -> URL; .zip files are unpacked into a folder of the same name.
SOURCES: dict[str, str] = {
    "kenney_impact.zip": KENNEY + "impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip",
    "kenney_interface.zip": KENNEY + "interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip",
    "kenney_rpg.zip": KENNEY + "rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip",
    "sword_clash.zip": OGA + "sword_clash_-_starninjas_0.zip",
    "rpg_pack.zip": OGA + "rpg_sound_pack.zip",
    "creatures.zip": OGA + "80-CC0-creature-SFX_0.zip",
    "bangs.zip": OGA + "25-CC0-bang-sfx.zip",
    "sfx100.zip": OGA + "100-CC0-SFX_0.zip",
    "kenney_jingles.zip": KENNEY + "music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip",
    "childrens_march.mp3": OGA + "Children%27s%20March%20Theme.mp3",
    "minstrel_dance_loop.wav": OGA + "Loop_Minstrel_Dance_0.wav",
    "war_horns.wav": OGA + "war_horns.wav",
}

# out name -> list of (source path inside the cache, start sec, max length sec, gain dB).
# Several sources = variants, Audio picks one at random.
SFX: dict[str, list[tuple[str, float, float, float]]] = {
    # Swords clashing (a unit's melee hit).
    "hit": [(f"sword_clash/sword_clash.{i}.ogg", 0.0, 0.45, -4.0) for i in (1, 2, 3, 4, 5)],
    # Arrow / thrown pickaxe whoosh.
    "shoot": [("rpg_pack/RPG Sound Pack/battle/swing.wav", 0.0, 0.3, -5.0),
              ("rpg_pack/RPG Sound Pack/battle/swing2.wav", 0.0, 0.3, -5.0),
              ("rpg_pack/RPG Sound Pack/battle/swing3.wav", 0.0, 0.3, -5.0)],
    "explosion": [("sfx100/explosion.ogg", 0.0, 0.8, -1.0)],
    # Monsters: short hurt cries when a unit falls.
    "death": [(f"creatures/hurt_0{i}.ogg", 0.0, 0.5, -7.0) for i in (1, 2, 3, 4, 5)],
    # A unit joins the army: sword drawn.
    "spawn": [("rpg_pack/RPG Sound Pack/battle/sword-unsheathe.wav", 0.0, 0.5, -8.0),
              ("rpg_pack/RPG Sound Pack/battle/sword-unsheathe2.wav", 0.0, 0.5, -8.0)],
    "coin": [("kenney_rpg/Audio/handleCoins.ogg", 0.0, 0.5, -6.0),
             ("kenney_rpg/Audio/handleCoins2.ogg", 0.0, 0.5, -6.0)],
    "ore": [(f"kenney_impact/Audio/impactMining_00{i}.ogg", 0.0, 0.4, -4.0) for i in (0, 1, 2)],
    # Meteor impact: a cannon shot.
    "meteor": [("bangs/cannon_01.ogg", 0.0, 1.3, 0.0)],
    # Twody: the victory must be short and light — an orchestral pizzicato jingle.
    "win": [("kenney_jingles/Audio/Pizzicato jingles/jingles_PIZZI07.ogg", 0.0, 1.4, -2.0)],
    # Defeat: a war horn call.
    "lose": [("war_horns.wav", 0.4, 3.0, -2.0)],
    # A wave is coming: a short horn call.
    "wave": [("war_horns.wav", 0.4, 1.8, -5.0)],
    # Hits on a (wooden) base: planks, not swords.
    "base_hit": [(f"kenney_impact/Audio/impactPlank_medium_00{i}.ogg", 0.0, 0.4, -3.0) for i in (0, 1, 2)],
    "click": [("kenney_interface/Audio/click_002.ogg", 0.0, 0.2, -6.0)],
}

# out name -> (source, end sec, fades). Looped by Audio. Twody: light, not
# serious. A source made as a loop needs no fades (they would dip at the seam).
MUSIC: dict[str, tuple[str, float, bool]] = {
    "menu": ("minstrel_dance_loop.wav", 0.0, False),
    "battle": ("childrens_march.mp3", 63.9, True),
}


def fetch() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    for name, url in SOURCES.items():
        path = CACHE / name
        if not path.exists():
            print("download", url)
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req) as r:
                path.write_bytes(r.read())
        if name.endswith(".zip"):
            folder = CACHE / name.removesuffix(".zip")
            if not folder.exists():
                with zipfile.ZipFile(path) as z:
                    z.extractall(folder)


def find(rel: str) -> Path:
    """Source file by its path; zip folders may have an extra top folder."""
    path = CACHE / rel
    if path.exists():
        return path
    head, _, tail = rel.partition("/")
    hits = list((CACHE / head).rglob(tail.rsplit("/", 1)[-1]))
    if not hits:
        raise FileNotFoundError(rel)
    return hits[0]


def peak_db(path: Path, start: float, length: float) -> float:
    out = subprocess.run([FFMPEG, "-hide_banner", "-ss", str(start), "-t", str(length), "-i", str(path),
                          "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True).stderr
    for line in out.splitlines():
        if "max_volume:" in line:
            return float(line.split("max_volume:")[1].split("dB")[0])
    return 0.0


def convert(src: Path, dst: Path, filters: list[str], channels: int, quality: float) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([FFMPEG, "-v", "error", "-y", "-i", str(src), "-af", ",".join(filters),
                    "-ac", str(channels), "-ar", "44100", "-c:a", "libvorbis", "-q:a", str(quality), str(dst)],
                   check=True)
    print(f"{dst.relative_to(ROOT).as_posix()}: {dst.stat().st_size / 1024:.1f} KB")


def sfx() -> None:
    for old in (OUT / "sfx").glob("*"):
        if old.suffix in (".wav", ".ogg") or old.name.endswith(".import"):
            old.unlink()
    for name, variants in SFX.items():
        for i, (rel, start, length, gain) in enumerate(variants):
            src = find(rel)
            # Peak to -1 dB, then the per-sound gain so the mix is even.
            boost = -1.0 - peak_db(src, start, length) + gain
            fade = min(0.08, length / 4) if length < 2 else 0.8
            filters = [f"atrim=start={start}:duration={length}", "asetpts=PTS-STARTPTS",
                       "silenceremove=start_periods=1:start_threshold=-45dB",
                       f"volume={boost:.2f}dB", f"afade=t=out:st={max(0.0, length - fade):.3f}:d={fade:.3f}"]
            suffix = f"_{i + 1}" if len(variants) > 1 else ""
            convert(src, OUT / "sfx" / f"{name}{suffix}.ogg", filters, 1, 4)


def music() -> None:
    for old in (OUT / "music").glob("*"):
        if old.suffix in (".wav", ".ogg") or old.name.endswith(".import"):
            old.unlink()
    for name, (rel, end, fades) in MUSIC.items():
        src = find(rel)
        filters = ["anull"]
        if end > 0.0:
            filters = [f"atrim=end={end}", "asetpts=PTS-STARTPTS"]
        if fades:
            # Short fades at both ends so the loop point does not click.
            filters += ["afade=t=in:d=0.05", f"afade=t=out:st={end - 0.6:.2f}:d=0.6"]
        # Same loudness for every track.
        filters.append("loudnorm=I=-17:TP=-1.5:LRA=11")
        convert(src, OUT / "music" / f"{name}.ogg", filters, 2, 2)


if __name__ == "__main__":
    fetch()
    sfx()
    music()
