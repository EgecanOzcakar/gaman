"""Regenerates assets/audio/chime.mp3: a rin-like bell synthesised from
inharmonic decaying partials, so the app ships no third-party audio to
license. Needs numpy and ffmpeg.

    python3 tool/make_chime.py
"""
import subprocess, tempfile, wave
import numpy as np

SR, DUR, F0 = 44100, 4.5, 660.0
# (frequency ratio, amplitude, decay seconds); the 1.003 partial beats
# slowly against the fundamental like a real bowl.
PARTIALS = [(1.0, 1.0, 2.6), (2.71, 0.45, 1.4), (5.15, 0.22, 0.8),
            (8.43, 0.10, 0.45), (1.003, 0.6, 2.8)]

t = np.arange(int(SR * DUR)) / SR
y = sum(a * np.exp(-t / d) * np.sin(2 * np.pi * F0 * r * t) for r, a, d in PARTIALS)
y *= np.minimum(1, t / 0.004)  # soft strike, no click
y = 0.6 * y / np.max(np.abs(y))

with tempfile.NamedTemporaryFile(suffix=".wav") as f:
    with wave.open(f.name, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((y * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", f.name,
                    "-codec:a", "libmp3lame", "-b:a", "96k",
                    "assets/audio/chime.mp3"], check=True)
