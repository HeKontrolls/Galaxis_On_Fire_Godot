Original procedural sound effects for Galaxis on Fire.

Regenerate with `python tools/generate_audio.py` from the project root. This needs NumPy; Godot playback does not. Add `--demo` to create the short listening sequence in `tests/audio_showcase.wav`.

- 18 footsteps: grass, dirt/sand, stone, wood, snow, and water, three variations each.
- 12 mining impacts: dirt, stone/ore, wood, and leaves, three variations each.
- 6 tool whooshes: light and metal, three variations each.
- 3 pickup chimes.
- 1 seamless eight-second stereo rain bed.

Files use 44.1 kHz, 16-bit PCM WAV. Short effects have tapered boundaries and peak headroom. Rain is synthesized periodically with different left/right noise and small drop details. All sounds are created by the included deterministic generator; no downloaded recordings are used.
