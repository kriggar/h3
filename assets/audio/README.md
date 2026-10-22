# Draconia optional background audio

Two Ogg Vorbis stereo loops, 44.1 kHz, total 1.32 MB. Exact original credits,
license evidence, duration and SHA-256 records are in `manifest.json` and
the project's `ASSET_CREDITS.md`.

- `forest.ogg`: Chris Castiglione / alienistcog's CC0 bird ambience, 9.36 s.
- `chronicle.ogg`: RandomMind's CC0 *Medieval: The Bard's Tale* instrumental
  loop, 57.73 s, transcoded from the original looping WAV without timing edits.

## Godot integration

Create stopped `AudioStreamPlayer` nodes. After the player explicitly enables
audio, set each loaded `AudioStreamOggVorbis.loop = true` and start it. Suggested
starting levels are `-24 dB` for the birds and `-20 dB` for the music. A short
fade on enable/disable helps transitions. The player's choice should control
subsequent playback. These assets do not require autoplay on entering a scene.

The original music WAV can be reproduced from the manifest URL and encoded:

```sh
ffmpeg -i Loop_The_Bards_Tale.wav -c:a libvorbis -q:a 5 chronicle.ogg
```

Both resulting files were checked with ffprobe and fully decoded with ffmpeg.
