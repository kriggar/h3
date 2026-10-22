# Spell feedback: native presentation contract

This is the implemented presentation pass for the four currently supported abilities, sword guard, and dodge. It is a development slice. It does not complete the planned class spell catalog or approve the game's full production art and sound mix.

## One source of gameplay truth

`game/redesign/action_rules.gd` owns accepted commands, commitment, hits, projectiles, status pools, expiry, recovery, and damage. `spell_feedback.gd` is a read-only adapter. It receives the real event batch through `consume(events, state)` and the current state/animated actors through `sync(state, visuals, camera)`. It never submits commands, advances the simulation, or applies a second damage source.

`DungeonStage.show_events()` forwards accepted events; `DungeonStage.sync_state()` updates the feedback after seeking the real character animations. `DungeonStage.set_sound_enabled(enabled)` is the shell's Sound-toggle interface. Loading a mid-cast or mid-status save reconstructs the current visible state without replaying the original cast sound.

All effect ages use the authoritative 30 Hz action tick. Tactical pause freezes projectiles, growth, trails, status feedback, and active audio voices. Muting stops current voices immediately; unmuting does not replay them. A cancelled windup clears its preparation cue. Rejected or merely queued commands do not produce execution effects.

## Class-specific visual promises

| Ability / action | Current legal proof fixture | What the native presentation actually shows |
| --- | --- | --- |
| Cleave | Mara Veyne, Oathwarden (`ileana`) | A vermilion pigment wake sampled from the actual animated sword's grip and blade tip. It follows the sword's trajectory; contact sparks and sound require the real damage event. It is not a separate projectile. |
| Ward | Mara Veyne, Oathwarden (`ileana`) | A blue kite with a four-lobed gold oath knot and blue wisps. It exists only while the finite Ward status exists, dims with its remaining pool, responds to actual absorption, and ends on depletion or expiry. |
| Ember | Vara Flint, Pyromancer (`vara_flint`) | One orange fire projectile with a bright core and trailing flame. Position and removal follow the registered projectile. Impact follows actual collision; burning embers require the actual burn status. A miss/removal gets a smaller extinguishing cue. |
| Living Roots | Cael Bracken, Druid (`cael_bracken`) | Three rising, twisting brown roots with olive leaves and pale green wisps on each actually rooted target. A brief ground disturbance marks the committed area; the binding follows the target's status and expires with it. No floating stone or persistent damage zone is implied. |
| Guard | Mara Veyne, Oathwarden | The real sword-ready animation, a restrained facing arc, and a contact response only when damage is actually blocked. It does not add an equipped shield or a magical Ward. |
| Dodge | Mara Veyne, Oathwarden | The authored roll over the existing 24-tick recovery, with small movement dust. The effect does not extend the rules' narrow invulnerability window. |

The Pyromancer and Druid native proofs currently reuse the hero test rig. Their canonical identities and class legality are real; their distinct production character art is not yet delivered. Mara's runtime kit remains Cleave and Ward. The manuscript ability icons are in `assets/ui/abilities/`.

## Audio and budgets

`tools/build_spell_audio.py` deterministically synthesizes 18 original finite WAV cues in `assets/audio/spells/`. No external recordings or samples are included. The assets are dedicated under CC0 1.0; the synthesis code follows the project's MIT license. The audio manifest records each seed, waveform SHA-256, duration, and measured peak.

Source clips peak at −9 dBFS, with edge fades and DC removal. Native playback uses a private spatial bus with a −3 dBFS hard limiter, a maximum of eight voices, at most four starts per action tick, per-cue/actor rate limiting, and event deduplication. Scene disposal frees the voices and the private bus. Presentation also caps transient bursts at 36 and blade history at ten samples. Continuous root/knot strokes are combined meshes rather than one draw per tiny segment.

The recorded native mix is measured for clipping and saved as evidence. Numerical headroom and a successful recording do not substitute for listening on representative speakers/headphones or a final mix with music, ambience, and the rest of the game.

## Verification

`tests/test_spell_feedback.gd` exercises the real rules with separate canonical Oathwarden, Pyromancer, and Druid fixtures. Its 43 checks cover accepted/rejected casts, finite Ward absorption, status-only bindings, actual projectile trajectory/collision, cancellation, pause, save reconstruction, duplicate events, Sound toggle, the voice budget, unchanged authoritative state, and bus disposal.

`tests/render_spell_feedback.gd` drives the actual native `DungeonStage`, the current 3D hero/werewolf rigs, and the real action events. Its 55 checks and 17 captures cover preparation, contact, follow-through, Ward absorption/depletion, projectile flight/impact, burn, root growth/pause/expiry, sword guard, and dodge recovery. It also records the actual mixed audio and a 30 fps engine movie. The report identifies test-fixture rig reuse explicitly.

The native proof uses Godot's Compatibility renderer with Mesa llvmpipe. A movie recorded at a fixed 30 fps demonstrates action timing on playback; it is not a real-time performance benchmark. The evidence retains the engine's actual recording time and renderer information. Still captures are 1440 × 900; the engine movie uses the project's 1280 × 800 viewport.

Final evidence is under `docs/verification-logs/spell-feedback/`. The unit and native counts are separate, and are not added to historical prototype test totals. See `visual-review.json` for the inspected frames, measured audio, source hashes, and limits of acceptance.

Run the presentation contract checks from the project root with isolated user-data directories:

```sh
env XDG_DATA_HOME=/tmp/draconia-spell-tests/data \
    XDG_CONFIG_HOME=/tmp/draconia-spell-tests/config \
    XDG_CACHE_HOME=/tmp/draconia-spell-tests/cache \
    /path/to/godot --headless --path . --script res://tests/test_spell_feedback.gd
```

Run the native harness with a working local display and isolated user-data directories:

```sh
env XDG_DATA_HOME=/tmp/draconia-spell-native/data \
    XDG_CONFIG_HOME=/tmp/draconia-spell-native/config \
    XDG_CACHE_HOME=/tmp/draconia-spell-native/cache \
    /path/to/godot --path . --rendering-method gl_compatibility \
    --rendering-driver opengl3 --resolution 1440x900 \
    --script res://tests/render_spell_feedback.gd \
    --write-movie /tmp/draconia-spell-feedback-native/native-feedback.avi \
    --fixed-fps 30
```

The native harness writes only its named `/tmp/draconia-spell-feedback-native` proof directory. It does not remove or replace a player's saved game. Audio and the future authored building-hover cycles are independent presentation modules.
