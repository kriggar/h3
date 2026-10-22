# Mara animation update — 0.4.1

Reviewed in native Godot 4.7.2, GL Compatibility, 22 October 2026.

This update rebuilds the player animation presentation around the accepted Mara
character. It adds authored air and interaction motion, fixes discarded blends
and accumulating bone offsets, connects gait to displayed movement, and adds
foot placement, stepping turns, layered reactions and contact-driven footsteps.
The realm remains authoritative for movement, damage, abilities and rewards.

## Native footage

- [Before and after, with matched scripted inputs](videos/animation-before-after.mp4).
  This is an isolated native motion-review stage, not a gameplay recording.
- [Actual in-game build](videos/gameplay-animation-review.mp4), with the production
  world, third-person camera and HUD. Inputs pass through the real solo Session
  and Realm. The overlay identifies the scripted input. There is no injected
  avatar pose, artificial action state or teleport in this recording.
- [Video comparison receipt](verification/animation-comparison.json).
- [In-game capture receipt](videos/gameplay-motion-review.json).

Both videos are silent, offline frame captures. Their encoded frame rates are
playback rates, not claims about real-time graphics performance. The sound sync
is verified separately with the actual controller and soundscape below.

## Character and asset integrity

The original model, materials, skeleton and twelve clips are unchanged:

```text
assets/models/mara/mara.glb
SHA-256: 8ada77b97e748814283fbf3f6efe960026674c0bf4ed04776610515c70fac94d
```

The supplementary library contains only animation curves for the same 53 bones.
It is 634,386 bytes and is included in the normal project ZIP. Blender is an
authoring tool; it is not required to import or play the game.

| Added source motion | Current use |
|---|---|
| Jump start | Articulated takeoff and knee tuck |
| Jump loop | Airborne continuation after the start clip |
| Jump land | Compression and recovery blended into permitted movement |
| Table-height pickup | Confirmed gathering and loot interaction |
| Head hit | Variation in the upper-body hit-reaction layer |
| Sprint | Included for future use; not selected at current player speed |

The motions come from the retained CC0 Quaternius Universal Animation Library
Standard source. Exact source hashes, retargeting, 53-bone mapping, native sole
calibration and license files are in [the asset provenance](../../assets/online/animations/PROVENANCE.json).
The [asset validation](../../assets/online/animations/VALIDATION.json) samples six
clips at 120 Hz, between calibration keys, including actual skinned boots and
blade geometry. Its 90,647 numeric checks include repeated per-bone assertions;
they are not 90,647 separate gameplay scenarios.

## What changed in play

### Stable pose evaluation and transitions

The former automatic AnimationPlayer processing reapplied its sampled pose after
the controller's manual blend. The rendered skeleton could therefore discard the
intended transition. The player now evaluates manually and owns the final pose.

Imported clips also omit some constant tracks. Each sample now begins from an
immutable rest pose, so an omitted spine channel cannot inherit and accumulate
the previous frame's turn or hit offset. A native review caught this as a torso
turning backwards; paired recovery tests now cover it.

Idle/walk/run use continuous pose weights and one normalized gait phase. Walk
and run contact phases are aligned, source stride lengths set the cadence, and
separate weight ramps plus a short gait-family crossfade soften speed changes.
A short acceleration filter prevents the remaining walk contribution from
racing through its cycle before the run pose arrives. A displayed stop freezes
phase immediately. No timer keeps the feet running against a stationary body.

### Movement, turning and contact

The world sends the avatar actual displayed velocity, acceleration, local travel
direction, turn rate, height and vertical motion. It extrapolates at most one
15 Hz snapshot interval and checks both prediction and smoothing against the
existing collision function. Packet stalls settle to zero displayed motion.
Teleports, respawns and a reset realm clock clear the motion history.

Holding RMB keeps facing separate from travel, enabling backpedalling and
strafing. Directional stride warping distributes pelvis/torso rotation, while
turns use alternating planted pivots and lifted steps. The turning foot lifts
before it moves horizontally or changes yaw, then lowers into its next contact.
The turn correction waits for the running pose to settle. Foot-yaw correction
also fades out when a nearly vertical toe has no reliable horizontal heading;
this removes a run-to-turn ankle flip found in the native video review.
The shoulder roll faces its actual displayed travel even while the actor's
network-facing correction is still settling.

Foot placement uses an analytical two-bone leg solve and world-space contact
anchors. The animation still supplies its knee bend, foot roll, swing and flight.
A 17-point support envelope per boot is selected from the real shipped mesh and
skinned at runtime to guard the heel/outsole against ground penetration. This
replaces the inaccurate assumption that the ankle or toe always has one fixed
distance from the sole. Ground sampling uses the existing terrain function.

### Jump, combat and interaction

Jumping uses its authored start, loop and landing. The start reaches its actual
ending pose before entering the matching loop. The realm's existing ballistic
trajectory supplies world height; animation does not apply a second world jump.
Foot anchors are disabled in the air. Landing compresses and recovers while
movement remains available, and its open-hand pose keeps the sword stowed.

Moving hits affect the upper body without replacing the running legs, restarting
gait or cancelling the server action. Moving attacks and casts retain their
lower-body travel through both entry and recovery. Teleport/respawn clears old
pose history as well as foot anchors. Death and rolls take over the full body,
including when they interrupt a moving attack. Mooncleave adds a wider torso-led arc to the retained strike;
it is a derived motion, not a newly authored second sword attack.

Swordfall, Mooncleave and Iron Vow retain their authoritative impact clocks:
0.48, 0.50 and 0.55 seconds. The controller does not cause damage or award loot.
Action identity uses the snapshot's authoritative time minus action elapsed time,
so even a delayed first packet for a repeated ability starts the correct motion.

Gathering/looting animations begin only after confirmed success and target the
correct actor. Rejected and wrong-owner interactions do not play the reach.
The retained death clip holds its ending pose and resets correctly on respawn.

Footstep sounds now follow each foot entering strong contact, with hysteresis
to prevent duplicate sounds while a foot stays planted. A landing produces one
quiet contact sound. Idle, airborne, dead, teleported and stopped actors suppress
steps. This reuses the existing sound assets and audio pool.

## Verification

| Gate | Result | Evidence |
|---|---:|---|
| Animation controller | 46 checks passed | [Controller receipt](verification/animation-controller.json): pose ownership, source integrity, continuity across six gait phases, sixteen run-to-turn cases, actual skinned-boot geometry, air/landing, paired hit/facing recovery, impact timing, death/respawn. |
| Realm → World presentation | 43 checks passed | [Motion receipt](verification/animation-motion-presentation.json): actual 60 Hz realm / 15 Hz snapshots, collision, stalls, jump telemetry, direction and confirmed interaction routing. |
| Movement/action integration | 24 checks passed | [Integration receipt](verification/animation-movement-regressions.json): delayed repeated abilities, realm restart, reverse diagonals, reset, moving attacks, direct attack-to-death/roll transitions and real backward-input roll alignment. |
| Contact audio | 18 checks passed | [Audio receipt](verification/animation-footsteps.json): real 60 Hz avatar contact sequence, cadence, duplicates, landing and suppression. |
| Existing world contract | 97 checks passed | [World receipt](verification/animation-world.json): original character/clips, animation policies, targeting, interaction range, enemy contact and camera obstruction. |
| Actual rendered solo entry | 55 checks passed | [Native receipt](verification/animation-native-acceptance.json), [scenario receipt](verification/animation-solo-acceptance.json): shipped entry, gameplay, UI, save/re-entry and two viewport sizes. |
| Actual in-game motion recording | 320 frames, 650 assertions passed | [Capture receipt](videos/gameplay-motion-review.json): real realm movement/jump, accepted abilities and visible actor in the production world. Counts include repeated per-frame assertions. |
| Fresh project import and launch | Passed; 20 launch/quit checks | [Cold-import receipt](verification/animation-cold-import.json), [source manifest](verification/animation-cold-source-manifest.json): 438 source files, no existing Godot cache, all runtime assets included, actual solo entry and window-close route. |
| Save & Quit | 21 checks passed | [Menu-quit receipt](verification/animation-menu-quit.json): actual pause-menu route, saved profile, stopped input, released audio streams and normal engine exit. |

The 60 Hz controller test measures fully planted intervals separately from
contact acquisition and release. A rigid-plant result must not be interpreted as
the speed of the entire swing or compared directly to the old controller, which
had no explicit plant weights. The matched video comparison also reports an
identical low-toe-height proxy for both builds, with sample counts and percentiles.

The final controller's six-phase walk-to-run gate measured a maximum first-frame
bone rotation of 0.506 radians (29.0°) at 24 fps; idle-to-walk measured 13.3°.
Sixteen run-to-turn cases, covering eight gait offsets and both turn directions,
measured a maximum world-space foot rotation of 32.2° per frame at 24 fps. The
native review had previously exposed a 115.7° flip followed by a 127.8° reversal.
The planted-turn 90th-percentile toe drift was 0.0079 m/s in its 60 Hz scenario.
These are bounded measured scenarios, not universal guarantees for every input,
frame rate, latency or terrain configuration.

The final controller, motion/action checks, comparison capture and clean-import
receipt record source hashes. The final gameplay recording also records its
production sources before and after capture. The 55-check entry/UI acceptance
was run during the update; the final motion-specific passes and native videos
cover the subsequent gait and action-transition corrections.

### Reproduce

From the project folder, with Godot 4.7.2 on the command line:

```bash
godot --headless --path . --script res://tests/online/animation_controller_tests.gd
godot --headless --path . --script res://tests/online/test_motion_presentation.gd
godot --headless --path . --script res://tests/online/animation_movement_regressions.gd
godot --headless --path . --script res://tests/online/footstep_audio_tests.gd
godot --headless --path . --script res://tests/online/world_scene_tests.gd
```

The native recording runners are `tools/animation_review.py` and
`tools/gameplay_motion_review.py`. Their `--help` lists Godot, output folder and
optional Xvfb arguments. Each creates isolated save/config/cache directories;
recording does not overwrite a player's normal profile.

## Remaining production work

The directional gait and turns are procedural adaptations. Custom authored
strafe, backpedal, turn, stop and combat-transition clips would improve style and
silhouette further. There is no claim of a complete motion-capture library.
The original tunic still stretches during deep leg flexion; this update does not
repair its mesh weights or add cloth, braid, hair or facial simulation. Equipment
appearance, enemy/NPC art, additional combat actions, hardware profiling and
long-duration network play remain part of the larger game's production work.

This is a substantial player-animation upgrade to the playable RPG foundation.
It is not a claim that the whole project has reached finished AAA quality.
