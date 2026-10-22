#!/usr/bin/env python3
"""Reproduce Draconia's original, seeded spell Foley; no sampled source audio.

The generated WAV files are dedicated to CC0-1.0. Source code is project MIT.
All clips have a finite envelope, DC removal, 8 ms end fades, and a -9 dBFS
sample peak. The native feedback bus adds its own safety limiter.
"""
from __future__ import annotations
import array
import hashlib
import json
import math
from pathlib import Path
import random
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/audio/spells"
RATE = 44100
TAU = 2 * math.pi
CLIPS = {
    "cleave_draw": (.24, "cloth", 141),
    "cleave_release": (.38, "sweep", 142),
    "steel_contact": (.25, "thud", 143),
    "ember_cast": (.28, "kindle", 144),
    "ember_launch": (.43, "flame", 145),
    "ember_hit": (.56, "flare", 146),
    "ember_end": (.26, "cinder", 147),
    "ward_cast": (.24, "glass_rise", 148),
    "ward_raise": (.64, "bell", 149),
    "ward_absorb": (.32, "glass", 150),
    "ward_end": (.44, "glass_fall", 151),
    "roots_cast": (.38, "earth_rise", 152),
    "roots_bind": (.52, "wood", 153),
    "roots_end": (.30, "leaves", 154),
    "guard_ready": (.22, "cloth", 155),
    "guard_block": (.34, "steel", 156),
    "dodge": (.48, "roll", 157),
    "evade": (.21, "air", 158),
}


def synthesize(duration: float, kind: str, seed: int) -> list[float]:
    rng = random.Random(seed)
    result: list[float] = []
    low, very_low, phase = 0.0, 0.0, 0.0
    for n in range(round(duration * RATE)):
        t = n / RATE
        p = t / duration
        noise = rng.uniform(-1, 1)
        low += .12 * (noise - low)
        very_low += .018 * (noise - very_low)
        high = noise - low
        attack = min(1., t / .012)
        decay = math.exp(-5.0 * p)
        swell = math.sin(math.pi * p) ** 1.2
        sample = 0.
        if kind in ("cloth", "air", "sweep", "roll"):
            freq = 150. + 500. * (1-p) if kind == "sweep" else 90. + 170. * p
            phase += TAU * freq / RATE
            envelope = swell if kind != "roll" else math.sin(math.pi*p) ** 2
            sample = (low * 1.5 + high * .06 + math.sin(phase) * .045) * envelope
            if kind == "roll":
                sample += very_low * .9 * math.exp(-80 * (p-.63)**2)
        elif kind in ("kindle", "flame", "flare", "cinder"):
            phase += TAU * (78 + 210 * (1-p)**2) / RATE
            pulse = 1 + .35 * math.sin(TAU * (31*t + 13*t*t))
            env = swell if kind in ("kindle", "flame") else attack * decay
            sample = (low * 1.6 + high * .12 + math.sin(phase) * .12) * env * pulse
            sample += high * .21 * math.exp(-100 * (p-.13)**2)
        elif kind.startswith("glass") or kind == "bell":
            base = {"glass_rise":430., "bell":510., "glass":650., "glass_fall":580.}[kind]
            slide = (1+.22*p) if kind == "glass_rise" else (1-.35*p) if kind == "glass_fall" else 1.
            phase += TAU * base * slide / RATE
            sample = sum(math.sin(phase*ratio) * gain * math.exp(-p*rate)
                         for ratio,gain,rate in ((1,.48,3.3),(1.503,.25,5.2),(2.006,.11,6.7),(2.73,.05,9)))
            sample = sample * attack + high * .12 * math.exp(-30*p)
        elif kind in ("wood", "leaves", "earth_rise"):
            sample = very_low*2.1 * swell + low*.6*attack*decay
            for center, freq in ((.11,170),(.29,240),(.47,130),(.68,310)):
                local = max(0.,p-center)
                if p >= center:
                    sample += (.22*math.sin(TAU*freq*(t-center*duration)) + high*.12) * math.exp(-38*local)
            if kind == "leaves": sample += high * .11 * swell
        elif kind in ("thud", "steel"):
            sample = (math.sin(TAU * (140*t-65*t*t))*.55 + low*1.1) * attack * math.exp(-13*p)
            if kind == "steel":
                sample += sum(math.sin(TAU*f*t)*g*math.exp(-p*d) for f,g,d in ((1030,.26,5),(1733,.15,8),(2421,.08,13))) * attack
        result.append(sample)
    mean = sum(result)/len(result)
    result = [v-mean for v in result]
    for n in range(len(result)):
        result[n] *= min(1., n/(RATE*.003), (len(result)-1-n)/(RATE*.008))
    maximum = max(abs(v) for v in result)
    gain = (10 ** (-9/20)) / max(maximum, 1e-9)
    return [v*gain for v in result]


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    records = {}
    for name, (duration, kind, seed) in CLIPS.items():
        samples = synthesize(duration, kind, seed)
        pcm = array.array("h", (round(v*32767) for v in samples))
        if sys.byteorder != "little": pcm.byteswap()
        target = OUTPUT / (name + ".wav")
        pending = target.with_suffix(".wav.pending")
        with wave.open(str(pending), "wb") as out:
            out.setparams((1, 2, RATE, len(samples), "NONE", "not compressed"))
            out.writeframes(pcm.tobytes())
        pending.replace(target)
        peak = max(abs(v) for v in samples)
        records[name] = {"file":target.name, "sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
                         "sampleRate":RATE, "channels":1, "bits":16, "frames":len(samples),
                         "durationSeconds":len(samples)/RATE, "peakDbfs":20*math.log10(peak),
                         "clippedSamples":sum(abs(round(v*32767))>=32767 for v in samples),
                         "algorithm":kind, "seed":seed}
    manifest = {"schemaVersion":1,"author":"Draconia contributors","license":"CC0-1.0",
                "source":"Original procedural synthesis; no recordings or external samples.",
                "generator":"tools/build_spell_audio.py","generatorSha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                "clips":records}
    (OUTPUT/"manifest.json").write_text(json.dumps(manifest,indent=2,sort_keys=True)+"\n")
    (OUTPUT/"README.md").write_text("# Original spell sound effects\n\nThese finite sound effects were synthesized specifically for Draconia by `tools/build_spell_audio.py`. They contain no third-party recordings or samples. The WAV assets are dedicated to the public domain under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/); the synthesis source follows the project's MIT license.\n\nThe manifest records each deterministic seed, waveform hash, duration and measured peak. Every source clip peaks at −9 dBFS. Native playback uses spatial attenuation, finite voice limits, event deduplication, pause/mute controls and a separate −3 dBFS safety limiter. The effects remain a development sound pass, subject to listening and mixing review.\n")
    print(json.dumps({"clips":len(records),"output":str(OUTPUT),"clippedSamples":sum(r["clippedSamples"] for r in records.values())}))


if __name__ == "__main__": main()
