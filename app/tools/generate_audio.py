"""Generate original, deterministic music and effects for the game.

Run from any directory: python3 tools/generate_audio.py
The same four-bar melody is used by both eras and by the true ending.
"""

from array import array
import math
from pathlib import Path
import random
import wave

RATE = 24000
BEAT = 60 / 96
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
RNG = random.Random(1926)


def frequency(midi: int) -> float:
    return 440.0 * (2 ** ((midi - 69) / 12))


def tone(buffer: list[float], midi: int, start: float, length: float,
         volume: float, kind: str) -> None:
    freq = frequency(midi)
    first = int(start * RATE)
    count = min(int(length * RATE), len(buffer) - first)
    if first < 0 or count <= 0:
        return
    for index in range(count):
        t = index / RATE
        if kind == "box":
            env = (1 - math.exp(-45 * t)) * math.exp(-4.8 * t)
            wave_value = (
                math.sin(2 * math.pi * freq * t)
                + 0.48 * math.sin(2 * math.pi * freq * 2.01 * t)
                + 0.18 * math.sin(2 * math.pi * freq * 3.02 * t)
            )
        elif kind == "piano":
            env = (1 - math.exp(-24 * t)) * math.exp(-2.0 * t)
            wave_value = (
                math.sin(2 * math.pi * freq * t)
                + 0.34 * math.sin(2 * math.pi * freq * 2 * t)
                + 0.1 * math.sin(2 * math.pi * freq * 3 * t)
            )
        else:
            env = (1 - math.exp(-12 * t)) * math.exp(-1.25 * t)
            wave_value = math.sin(2 * math.pi * freq * t)
        buffer[first + index] += volume * env * wave_value


def write_wav(name: str, samples: list[float], peak: float = 0.82) -> None:
    maximum = max(max(abs(value) for value in samples), 0.001)
    gain = peak / maximum
    tail = min(int(RATE * 0.09), len(samples) // 2)
    encoded = array("h")
    for index, sample in enumerate(samples):
        fade = 1.0
        if index < tail:
            fade = index / tail
        elif index >= len(samples) - tail:
            fade = (len(samples) - index - 1) / tail
        encoded.append(int(max(-1, min(1, sample * gain * fade)) * 32767))
    with wave.open(str(OUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(encoded.tobytes())


def add_delay(samples: list[float], seconds: float, gain: float) -> None:
    offset = int(seconds * RATE)
    for index in range(len(samples) - 1, offset - 1, -1):
        samples[index] += samples[index - offset] * gain


melody = [
    (72, 76, 79), (81, 79, 76), (77, 81, 84), (83, 79, 76),
    (74, 77, 81), (79, 76, 72), (76, 79, 84), (83, 81, 79),
    (72, 76, 79), (81, 84, 79), (77, 81, 84), (83, 79, 76),
    (74, 77, 81), (79, 76, 72), (76, 74, 72), (71, 74, 72),
]
chords = [
    (48, 52, 55), (45, 48, 52), (41, 45, 48), (43, 47, 50),
    (50, 53, 57), (48, 52, 55), (41, 45, 48), (43, 47, 50),
] * 2
duration = len(melody) * 3 * BEAT
past = [0.0] * int(duration * RATE)
future = [0.0] * int(duration * RATE)

for bar, notes in enumerate(melody):
    base = bar * 3 * BEAT
    for beat, midi in enumerate(notes):
        start = base + beat * BEAT
        tone(past, midi, start, 1.3 * BEAT, 0.18, "box")
        tone(future, midi - 12, start, 2.0 * BEAT, 0.19, "piano")
    root, third, fifth = chords[bar]
    tone(past, root, base, 1.5 * BEAT, 0.11, "box")
    tone(future, root - 12, base, 2.3 * BEAT, 0.14, "piano")
    for beat in (1, 2):
        for midi in (root + 12, third + 12, fifth + 12):
            tone(past, midi, base + beat * BEAT, 0.8 * BEAT, 0.029, "box")
            tone(future, midi, base + beat * BEAT, 1.5 * BEAT, 0.027, "pad")

add_delay(future, 0.22, 0.18)
true_theme = [0.68 * p + 0.66 * f for p, f in zip(past, future)]
write_wav("bgm_1926.wav", past, 0.6)
write_wav("bgm_2126.wav", future, 0.52)
write_wav("bgm_true.wav", true_theme, 0.72)


def effect(name: str, seconds: float, sample_fn) -> None:
    data = [sample_fn(index / RATE) for index in range(int(seconds * RATE))]
    write_wav(name + ".wav", data, 0.68)


effect(
    "se_timeshift", 0.8,
    lambda t: (math.sin(2 * math.pi * (1060 * t - 510 * t * t)) * math.exp(-3 * t)
               + RNG.uniform(-1, 1) * 0.13 * math.sin(math.pi * t / 0.8)),
)
effect(
    "se_unlock", 0.75,
    lambda t: sum(
        math.sin(2 * math.pi * frequency(midi) * max(0, t - delay))
        * math.exp(-8 * max(0, t - delay))
        * (1 if t >= delay else 0)
        for midi, delay in ((76, 0), (79, 0.12), (84, 0.25))
    ),
)
effect(
    "se_locked", 0.25,
    lambda t: math.sin(2 * math.pi * 95 * t) * math.exp(-26 * t)
              + RNG.uniform(-1, 1) * math.exp(-40 * t) * 0.27,
)
effect(
    "se_carve", 0.45,
    lambda t: RNG.uniform(-1, 1) * (0.5 + 0.5 * math.sin(2 * math.pi * 35 * t))
              * math.sin(math.pi * t / 0.45),
)
effect(
    "se_gear", 0.5,
    lambda t: (math.sin(2 * math.pi * 730 * t)
               + 0.4 * math.sin(2 * math.pi * 1380 * t))
              * math.exp(-12 * t),
)
effect(
    "se_wind", 0.8,
    lambda t: math.sin(2 * math.pi * 290 * t)
              * math.exp(-32 * ((t * 6) % 1))
              * 0.65,
)
effect(
    "se_tick", 0.28,
    lambda t: RNG.uniform(-1, 1) * math.exp(-75 * t)
              + 0.2 * math.sin(2 * math.pi * 480 * t) * math.exp(-20 * t),
)
effect(
    "se_door", 1.25,
    lambda t: math.sin(2 * math.pi * (110 + 85 * t) * t)
              * math.sin(math.pi * t / 1.25) * 0.6
              + RNG.uniform(-1, 1) * 0.11 * math.sin(math.pi * t / 1.25),
)
effect(
    "se_whisper", 1.2,
    lambda t: RNG.uniform(-1, 1) * 0.15
              * math.sin(math.pi * t / 1.2)
              * (0.5 + 0.5 * math.sin(2 * math.pi * 5 * t)),
)
chime = [0.0] * int(3.4 * RATE)
for index, midi in enumerate((72, 76, 79, 84)):
    tone(chime, midi, index * 0.65, 1.3, 0.34, "box")
write_wav("jingle_chime.wav", chime, 0.8)

print(f"Generated {len(list(OUT.glob('*.wav')))} WAV files in {OUT}")
