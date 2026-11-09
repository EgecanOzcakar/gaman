"""Regenerates the five ambient binaural tracks in assets/audio/: a pure sine
in each ear, centred on a 200 Hz carrier and offset by the beat frequency
(left carrier - beat/2, right carrier + beat/2). 200 Hz is softer than the
original tracks' 440 Hz for long listening. Made in-house, so there is no
licence to track. Same format as the original tracks: 60 s, 44.1 kHz stereo, 64 kbps
MP3, peak 0.45.

Every frequency is a whole number of cycles in 60 s and both channels start
at phase 0, so each file loops seamlessly (the app plays them with
LoopMode.one). Needs numpy and ffmpeg.

    python3 tool/make_binaural.py
"""
import subprocess, tempfile, wave
import numpy as np

SR, DUR, CARRIER, PEAK = 44100, 60, 200.0, 0.45
# file -> beat Hz; keep in sync with `beats` in lib/providers/audio_provider.dart
TRACKS = {"delta": 2, "theta": 6, "alpha": 10, "beta": 20, "gamma": 40}

t = np.arange(SR * DUR) / SR
for name, beat in TRACKS.items():
    left, right = CARRIER - beat / 2, CARRIER + beat / 2
    assert (left * DUR).is_integer() and (right * DUR).is_integer(), name
    stereo = np.stack([np.sin(2 * np.pi * left * t),
                       np.sin(2 * np.pi * right * t)], axis=1) * PEAK
    with tempfile.NamedTemporaryFile(suffix=".wav") as f:
        with wave.open(f.name, "wb") as w:
            w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes((stereo * 32767).astype(np.int16).tobytes())
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", f.name,
                        "-codec:a", "libmp3lame", "-b:a", "64k",
                        f"assets/audio/{name}.mp3"], check=True)
    print(f"{name}.mp3: L {left:g} Hz, R {right:g} Hz (beat {beat} Hz)")
