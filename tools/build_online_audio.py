#!/usr/bin/env python3
"""Reproduce the original synthesis used by the Blackbriar development build.

No sampled commercial music, voices or game sound effects are used.
Requires numpy; the generated WAV assets are bundled, so players need no tools.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/online/audio"
RATE = 22050
RNG = np.random.default_rng(420107)


def write(name, samples, loop=False):
    samples = np.asarray(samples, dtype=np.float64)
    if samples.ndim == 1:
        samples = np.column_stack([samples, samples])
    peak = max(1.0, float(np.max(np.abs(samples))) / 0.86)
    samples = np.clip(samples / peak, -0.9, 0.9)
    path = OUT / (name + ".wav")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes((samples * 32767).astype("<i2").tobytes())
    return {"file": path.name, "seconds": len(samples) / RATE, "loop": loop,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def noise(n, smooth=8):
    return np.convolve(RNG.normal(0, 1, n), np.ones(smooth) / smooth, mode="same")


def chime(duration, notes, amplitude=.14):
    t = np.arange(int(RATE * duration)) / RATE
    sound = np.zeros_like(t)
    for i, f in enumerate(notes):
        u = np.maximum(t - i * .13, 0)
        mask = t >= i * .13
        sound += mask * amplitude * np.minimum(u * 70, 1) * np.exp(-u * 2.5) * (
            np.sin(2 * np.pi * f * u) + .25 * np.sin(2 * np.pi * f * 2.01 * u))
    sound[-220:] *= np.linspace(1, 0, 220)
    return sound


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    # Loop joins are periodic in both harmonic beds and modulation.
    duration = 24
    t = np.arange(RATE * duration) / RATE
    freqs = np.fft.rfftfreq(len(t), 1 / RATE)
    spectrum = RNG.normal(size=len(freqs)) + 1j * RNG.normal(size=len(freqs))
    spectrum /= np.maximum(freqs, 40) ** .8
    spectrum[freqs < 45] = 0
    spectrum[freqs > 5500] = 0
    wind = np.fft.irfft(spectrum, n=len(t))
    wind /= max(np.max(np.abs(wind)), .00001)
    wind *= (.10 + .045 * np.sin(2*np.pi*t/duration))
    birds = np.zeros_like(t)
    for when, length, frequency in [(2.0,.32,2300),(2.5,.18,2700),(9.0,.28,1900),(16.0,.4,2500),(16.6,.22,2250)]:
        start, n = int(when * RATE), int(length * RATE)
        u = np.arange(n) / RATE
        birds[start:start+n] += .018 * np.sin(np.pi*np.arange(n)/n)**2 * np.sin(2*np.pi*(frequency*u+450*u*u))
    manifest.append(write("briar_air", np.column_stack([wind+birds, np.roll(wind,1370)+birds*.65]), True))
    # Quiet original sustained D minor / B flat / C / A colour, 32-second loop.
    duration = 32
    t = np.arange(RATE * duration) / RATE
    music = np.zeros((len(t),2))
    chords = [(146.832,220,293.665,349.228),(116.541,174.614,233.082,293.665),
              (130.813,196,261.626,329.628),(110,164.814,220,293.665)]
    for k, chord in enumerate(chords):
        start, n = int(k*8*RATE), int(8*RATE)
        u = np.arange(n)/RATE
        envelope = np.sin(np.pi*np.arange(n)/n)**1.6
        for j, f in enumerate(chord):
            tone = np.sin(2*np.pi*f*u + .025*np.sin(2*np.pi*4.7*u))
            tone += .2*np.sin(2*np.pi*f*2*u) + .07*np.sin(2*np.pi*f*3*u)
            music[start:start+n,0] += .035*envelope*tone*(.8 if j%2 else 1)
            music[start:start+n,1] += .035*envelope*tone*(1 if j%2 else .8)
    manifest.append(write("watchfire_theme",music,True))
    n = int(.42*RATE); t = np.arange(n)/RATE
    envelope = np.sin(np.pi*np.arange(n)/n)**1.5
    manifest.append(write("blade",noise(n,2)*envelope*.34 + .06*np.sin(2*np.pi*(950*t-850*t*t))*envelope))
    n = int(.25*RATE); t = np.arange(n)/RATE
    manifest.append(write("impact",(.26*np.sin(2*np.pi*(130*t-140*t*t))+.28*noise(n,4))*np.exp(-t*22)*np.minimum(t*450,1)))
    n = int(.34*RATE); t = np.arange(n)/RATE
    manifest.append(write("step",noise(n,14)*np.exp(-t*24)*np.minimum(t*400,1)*.75))
    manifest.append(write("ward",chime(1.3,[293.665,440,587.33])))
    manifest.append(write("reward",chime(1.1,[440,554.365,659.255],.1)))
    manifest.append(write("level",chime(2.2,[293.665,349.228,440,587.33],.12)))
    manifest.append(write("heal",chime(.85,[349.228,523.251],.09)))
    (OUT/"manifest.json").write_text(json.dumps({"source":"Original mathematical synthesis for this project",
        "generator":"tools/build_online_audio.py", "quality":"development sound design", "sample_rate":RATE,
        "assets":manifest},indent=2)+"\n")
    print(json.dumps({"assets":len(manifest),"bytes":sum(p.stat().st_size for p in OUT.glob('*.wav'))}))


if __name__ == "__main__":
    main()
