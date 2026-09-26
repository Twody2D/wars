"""Placeholder sounds (SPEC 12): synthesized chiptune SFX and two music loops.

Writes audio/sfx/*.wav and audio/music/*.wav (22050 Hz, mono, 16-bit);
Godot compresses them on import (QOA). Replace with real sounds later —
file names are the contract with scripts/autoload/audio.gd.

Run: python tools/gen_sounds.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).resolve().parent.parent / "audio"
rng = random.Random(7)


def osc(kind: str, phase: float) -> float:
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "triangle":
        return 4.0 * abs(p - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "noise":
        return rng.uniform(-1.0, 1.0)
    return math.sin(2.0 * math.pi * p)


def tone(dur: float, f0: float, f1: float | None = None, kind: str = "square",
         vol: float = 0.5, attack: float = 0.005, decay: float = 1.0) -> list[float]:
    """A sweep f0 → f1 with an attack and an exponential-ish decay."""
    f1 = f0 if f1 is None else f1
    n = int(dur * RATE)
    out: list[float] = []
    phase = 0.0
    held = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        phase += f / RATE
        env = min(1.0, i / max(1, attack * RATE)) * (1.0 - t) ** decay
        if kind == "noise":
            # Sample-and-hold noise: the pitch sets how often it changes.
            if int(phase) != int(phase - f / RATE):
                held = rng.uniform(-1.0, 1.0)
            out.append(held * env * vol)
        else:
            out.append(osc(kind, phase) * env * vol)
    return out


def mix(*parts: list[float]) -> list[float]:
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def seq(*parts: list[float]) -> list[float]:
    out: list[float] = []
    for p in parts:
        out += p
    return out


def silence(dur: float) -> list[float]:
    return [0.0] * int(dur * RATE)


def write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples))
    print(f"{path.relative_to(ROOT.parent).as_posix()}: {path.stat().st_size / 1024:.1f} KB")


def note(name: str) -> float:
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    semis = names[name[0]] + (1 if "#" in name else 0) + (int(name[-1]) - 4) * 12
    return 440.0 * 2 ** (semis / 12)


def sfx() -> None:
    d = ROOT / "sfx"
    write(d / "hit.wav", mix(tone(0.08, 180, 60, "square", 0.45, decay=2), tone(0.06, 3000, 800, "noise", 0.35, decay=2)))
    write(d / "shoot.wav", tone(0.14, 1100, 280, "square", 0.3, decay=1.5))
    write(d / "explosion.wav", mix(tone(0.55, 900, 60, "noise", 0.6, decay=1.6), tone(0.4, 90, 40, "triangle", 0.5, decay=1.2)))
    write(d / "death.wav", tone(0.3, 420, 70, "triangle", 0.5, decay=1.2))
    write(d / "spawn.wav", seq(tone(0.06, 330, 440, "square", 0.3), tone(0.1, 520, 700, "square", 0.3, decay=1.5)))
    write(d / "coin.wav", seq(tone(0.06, note("B5"), kind="square", vol=0.3, decay=0.3), tone(0.16, note("E6"), kind="square", vol=0.3, decay=1.2)))
    write(d / "ore.wav", mix(tone(0.09, 1400, 1100, "triangle", 0.45, decay=2), tone(0.04, 6000, 3000, "noise", 0.25, decay=2)))
    write(d / "meteor.wav", mix(tone(0.9, 300, 3000, "noise", 0.35, attack=0.4, decay=0.6), tone(0.9, 700, 200, "sine", 0.2, attack=0.3, decay=0.5)))
    write(d / "win.wav", seq(*[tone(0.12, note(n), kind="square", vol=0.3, decay=0.5) for n in ["C5", "E5", "G5"]],
                             tone(0.45, note("C6"), kind="square", vol=0.3, decay=1.0)))
    write(d / "lose.wav", seq(*[tone(0.2, note(n), kind="triangle", vol=0.45, decay=0.4) for n in ["G4", "E4", "C4"]],
                              tone(0.5, note("C3"), kind="triangle", vol=0.45, decay=1.0)))
    write(d / "click.wav", tone(0.04, 1800, 1200, "square", 0.2, decay=2))


def track(bpm: float, chords: list[list[str]], melody: list[str], lead: str, bass: str, drums: bool) -> list[float]:
    """One bar per chord; melody = eighth notes ("-" = rest)."""
    beat = 60.0 / bpm
    eighth = beat / 2
    bars: list[list[float]] = []
    for bar, chord in enumerate(chords):
        root = note(chord[0])
        parts: list[list[float]] = []
        # Bass: root on every beat, fifth on the offbeat.
        b: list[float] = []
        for k in range(4):
            b += tone(eighth, root / 2, kind=bass, vol=0.28, decay=0.6)
            b += tone(eighth, root / 2 * 1.5, kind=bass, vol=0.2, decay=0.8)
        parts.append(b)
        # Lead: 8 eighths per bar.
        m: list[float] = []
        for k in range(8):
            n = melody[(bar * 8 + k) % len(melody)]
            m += silence(eighth) if n == "-" else tone(eighth, note(n), kind=lead, vol=0.14, decay=0.7)
        parts.append(m)
        # Arpeggio of the chord, quiet, sixteenths.
        a: list[float] = []
        for k in range(16):
            a += tone(eighth / 2, note(chord[k % len(chord)]), kind="triangle", vol=0.06, decay=0.5)
        parts.append(a)
        if drums:
            dr: list[float] = []
            for k in range(8):
                if k % 4 == 0:
                    dr += mix(tone(eighth, 120, 40, "sine", 0.4, decay=3), silence(eighth))
                elif k % 4 == 2:
                    dr += tone(eighth, 5000, 2000, "noise", 0.18, decay=3)
                else:
                    dr += tone(eighth, 9000, 7000, "noise", 0.06, decay=4)
            parts.append(dr)
        bars.append(mix(*parts))
    return seq(*bars)


def music() -> None:
    d = ROOT / "music"
    calm = [["C4", "E4", "G4"], ["A3", "C4", "E4"], ["F3", "A3", "C4"], ["G3", "B3", "D4"]] * 4
    calm_melody = ("E5 - G5 - E5 D5 C5 - A4 - C5 - E5 - D5 - "
                   "F5 - E5 - D5 C5 A4 - G4 - B4 - D5 - G5 -").split()
    write(d / "menu.wav", track(100, calm, calm_melody, "triangle", "triangle", drums=False))
    fight = [["A3", "C4", "E4"], ["F3", "A3", "C4"], ["G3", "B3", "D4"], ["E3", "G#3", "B3"]] * 4
    fight_melody = ("A4 A4 C5 A4 E5 - D5 C5 F4 A4 C5 A4 F5 - E5 C5 "
                    "G4 B4 D5 B4 G5 - F5 D5 E5 - B4 - G#4 - E4 -").split()
    write(d / "battle.wav", track(140, fight, fight_melody, "square", "square", drums=True))


if __name__ == "__main__":
    sfx()
    music()
