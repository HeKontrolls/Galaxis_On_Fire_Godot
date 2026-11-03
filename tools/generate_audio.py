"""Create Galaxis' original procedural effects. Requires Python and NumPy.

Run from any directory; generated PCM WAVs are loaded directly by Godot.
Seeds are local and fixed, so regeneration reproduces every sound.
"""
from pathlib import Path
import sys
import wave

import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"


def noise(n, low, high, rng):
    frequencies = np.fft.rfftfreq(n, 1 / RATE)
    spectrum = np.fft.rfft(rng.standard_normal(n))
    # Smooth rolloffs avoid ringing at hard frequency cutoffs. FFT synthesis
    # is periodic, which also gives the long rain bed a seamless loop.
    shape = 1 / np.sqrt(1 + (frequencies / high) ** 6)
    shape *= 1 / np.sqrt(1 + (low / np.maximum(1, frequencies)) ** 6)
    value = np.fft.irfft(spectrum * shape, n=n)
    return value / max(0.01, np.std(value))


def envelope(t, decay, attack=0.003):
    return (1 - np.exp(-t / attack)) * np.exp(-t * decay)


def finish(value, peak=0.68):
    # Remove DC, keep consistent headroom, and taper the boundary samples to
    # zero so individual footsteps and impacts never click at start/stop.
    value = value - np.mean(value)
    fade = min(700, len(value) // 5)
    value[:90] *= np.linspace(0, 1, 90)
    value[-fade:] *= np.linspace(1, 0, fade)
    return value * peak / max(0.01, np.max(np.abs(value)))


def footstep(material, variant):
    rng = np.random.default_rng(1100 + variant + 71 * list(MATERIALS).index(material))
    t = np.arange(int(RATE * 0.19)) / RATE
    f = {"grass": 115, "dirt": 100, "stone": 195, "wood": 145, "snow": 95, "water": 125}[material]
    body = np.sin(2 * np.pi * (f * t - 60 * t * t)) * envelope(t, 36)
    grit = noise(len(t), 700, 6500, rng) * envelope(t, 27)
    value = body * 0.65 + grit * 0.23
    if material == "grass":
        value += noise(len(t), 1800, 9000, rng) * envelope(t, 22) * 0.17
    elif material == "stone":
        value = body * 0.5 + grit * 0.18 + np.sin(2 * np.pi * 830 * t) * envelope(t, 65) * 0.14
    elif material == "wood":
        value = body * 0.65 + np.sin(2 * np.pi * 370 * t) * envelope(t, 50) * 0.25 + grit * 0.06
    elif material == "snow":
        crunch = noise(len(t), 400, 4500, rng)
        value = body * 0.2 + crunch * envelope(t, 20) * 0.44
    elif material == "water":
        value = body * 0.16 + noise(len(t), 500, 9500, rng) * envelope(t, 21) * 0.40
        value += np.sin(2 * np.pi * (600 * t + 1200 * t * t)) * envelope(t, 34) * 0.11
    return finish(value)


def impact(material, variant):
    rng = np.random.default_rng(4200 + variant + 71 * list(IMPACTS).index(material))
    t = np.arange(int(RATE * 0.24)) / RATE
    grit = noise(len(t), 900, 8500, rng)
    if material == "stone":
        value = grit * envelope(t, 36) * 0.2
        for f, gain in [(440, 0.55), (1370, 0.15), (2510, 0.07)]:
            value += np.sin(2 * np.pi * (f + rng.uniform(-25, 25)) * t) * envelope(t, 30 + f / 80) * gain
    elif material == "wood":
        value = np.sin(2 * np.pi * 155 * t) * envelope(t, 26) * 0.65
        value += np.sin(2 * np.pi * 480 * t) * envelope(t, 44) * 0.2 + grit * envelope(t, 32) * 0.13
    elif material == "leaf":
        value = grit * envelope(t, 19, 0.012) * 0.6
    else:
        value = np.sin(2 * np.pi * (90 * t - 50 * t * t)) * envelope(t, 35) * 0.4
        value += noise(len(t), 180, 5500, rng) * envelope(t, 25) * 0.44
    return finish(value, 0.74)


def swing(metal, variant):
    rng = np.random.default_rng(6200 + variant + 50 * metal)
    t = np.arange(int(RATE * (0.17 if metal else 0.20))) / RATE
    air = noise(len(t), 400 if metal else 220, 7000 if metal else 4500, rng)
    value = air * np.sin(np.pi * t / (len(t) / RATE)) ** 2
    value *= 0.7 + 0.3 * np.sin(2 * np.pi * 22 * t)
    return finish(value, 0.48)


def pickup(variant):
    t = np.arange(int(RATE * 0.23)) / RATE
    value = np.zeros_like(t)
    for delay, frequency, gain in [(0, 880, 0.6), (0.055, 1320, 0.45)]:
        at = np.maximum(0, t - delay)
        frequency *= [1, 1.05946, 1.12246][variant]
        tone = np.sin(2 * np.pi * frequency * at) + 0.12 * np.sin(2 * np.pi * 2 * frequency * at)
        value += tone * envelope(at, 25, 0.002) * gain
    return finish(value, 0.46)


def rain():
    n = RATE * 8
    t = np.arange(n) / RATE
    channels = []
    for seed in [9191, 9292]:
        rng = np.random.default_rng(seed)
        hiss = noise(n, 250, 9500, rng) * 0.16
        softer = noise(n, 110, 1800, rng) * 0.04
        drops = np.zeros(n)
        for _drop in range(120):
            start = rng.integers(n)
            at = np.arange(int(RATE * 0.06)) / RATE
            drip = rng.standard_normal(len(at)) * envelope(at, 100, 0.001) * rng.uniform(0.03, 0.14)
            np.add.at(drops, (start + np.arange(len(at))) % n, drip)
        modulation = 0.9 + 0.06 * np.sin(2 * np.pi * t / 8) + 0.04 * np.sin(2 * np.pi * t / 2)
        channels.append(np.tanh((hiss + softer + drops) * modulation))
    result = np.stack(channels, axis=1)
    return result - np.mean(result, axis=0)


def write(name, data, folder=OUT):
    assert np.all(np.isfinite(data)) and 0.005 < np.max(np.abs(data)) < 0.98
    pcm = np.round(data * 32767).astype("<i2")
    with wave.open(str(folder / f"{name}.wav"), "wb") as stream:
        stream.setnchannels(2 if data.ndim == 2 else 1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())


MATERIALS = ["grass", "dirt", "stone", "wood", "snow", "water"]
IMPACTS = ["dirt", "stone", "wood", "leaf"]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for material in MATERIALS:
        for variant in range(3):
            write(f"step_{material}_{variant}", footstep(material, variant))
    for material in IMPACTS:
        for variant in range(3):
            write(f"mine_{material}_{variant}", impact(material, variant))
    for metal in [False, True]:
        for variant in range(3):
            write(f"swing_{'metal' if metal else 'light'}_{variant}", swing(metal, variant))
    for variant in range(3):
        write(f"pickup_{variant}", pickup(variant))
    write("rain_loop", rain())
    print(f"Generated 40 WAVs at {RATE} Hz with verified finite samples and unclipped headroom.")
    if "--demo" in sys.argv:
        pieces = []
        def add(value, duration):
            if value.ndim == 1:
                value = np.repeat(value[:, None], 2, axis=1)
            padded = np.zeros((int(RATE * duration), 2))
            padded[:min(len(value), len(padded))] = value[:len(padded)]
            pieces.append(padded)
        for material in MATERIALS:
            for variant in range(2):
                add(footstep(material, variant) * 0.7, 0.38)
        for material in IMPACTS:
            add(impact(material, 0) * 0.82, 0.45)
        for metal in [False, True]:
            add(swing(metal, 0) * 0.42, 0.4)
        for variant in range(2):
            add(pickup(variant) * 0.55, 0.35)
        bed = rain()[:RATE * 3] * 0.7
        fade = int(RATE * 0.3)
        bed[:fade] *= np.linspace(0, 1, fade)[:, None]
        bed[-fade:] *= np.linspace(1, 0, fade)[:, None]
        add(bed, 3.0)
        write("audio_showcase", np.concatenate(pieces), ROOT / "tests")
        print("Wrote tests/audio_showcase.wav: footsteps, mining, swings, pickups, rain.")


if __name__ == "__main__":
    main()
