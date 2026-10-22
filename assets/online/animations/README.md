# Mara supplementary animation library

`mara_extended.tres` adds six licensed motions to the accepted Mara character.
It contains bone animation curves only. The existing `mara.glb`, 53-bone rig,
meshes, textures, materials and original twelve clips remain unchanged.

```gdscript
const EXTENDED = preload("res://assets/online/animations/mara_extended.tres")
animator.add_animation_library("extended", EXTENDED)
animator.play("extended/jump_start")
```

All tracks address `IleanaRig/Skeleton3D:<bone>`, relative to the existing
AnimationPlayer root. Every clip explicitly supplies position, rotation and
scale for all 53 bones so a preceding animation cannot leave a stale pose.
The controller still owns movement, jumping, collision, damage and sound events.

| Runtime name | Seconds | Loop | Held sword | Source motion / use |
|---|---:|---|---|---|
| `extended/jump_start` | 1.333333 | No | Hide | `Jump_Start`; crouch, takeoff and knee tuck |
| `extended/jump_loop` | 2.500000 | Yes | Hide | `Jump_Loop`; subtle airborne pose cycle |
| `extended/jump_land` | 1.250000 | No | Hide | `Jump_Land`; contact compression and stand-up |
| `extended/interact` | 0.833333 | No | Hide | `PickUp_Table`; left-hand waist/table-height pickup |
| `extended/hit_head` | 0.416667 | No | Show | `Hit_Head`; head/upper-body hit response |
| `extended/sprint` | 0.666667 | Yes | Show | `Sprint_Loop`; forward-leaning sprint with flight |

## Timing and integration

The first jump-start pose is already crouched. Blend into it; most takeoff
motion occupies the first 0.2 seconds. Maximum knee tuck is near normalized
phase **0.253**. The last start pose aligns with the airborne loop. Neither
clip contains the gameplay character's ballistic trajectory.

Landing starts at contact. Its deepest measured native pelvis compression is
at phase **0.163**, approximately **0.204 seconds**. Keep this impact readable,
then allow recovery to blend into movement as gameplay permits. Playing the
whole 1.25-second source recovery as an uninterruptible lock would feel slow.

The interaction reaches furthest forward with the left hand near phase
**0.315**. It suits a reach/pickup gesture. It is not a kneeling harvest or
digging animation, and no inventory reward should be emitted by this asset.

Sprint's measured near-floor foot speed is approximately **7.46 m/s** at
authored speed and scale one. It is an optional high-speed pose source; adding
it does not change the server's movement speed. Match playback rate to actual
velocity and check the result in the integrated camera. The native 35 mm
near-floor windows are left **0.069–0.181**, right **0.644–0.669** and
**0.694–0.719**. The two right windows describe one stance with a small height
threshold crossing. Do not emit a second footstep from that crossing.

Full exact durations, phase windows, source names and correction amounts are
in `PROVENANCE.json`. Jump windows there are measured relative to the actor
origin; an airborne actor is not touching the world floor merely because a
foot is near its local zero plane. Use actual grounded state for contact audio.

## Retargeting and validation

The retained Quaternius Standard source is CC0. The exact source and target
hashes, authoring input hashes, 52-bone source mapping plus Root, and original
license notices are recorded in `PROVENANCE.json`. The supplemental pack does
not include a replacement model or the source mannequin.

`tools/bake_mara_extended.py` reads the final editable Mara rig and the licensed
source motions, transfers calibrated global rotations, retains the reviewed
right-hand grip where armed, and exports a temporary skeletal transfer GLB.
`tools/extract_mara_extended.gd` verifies the original native rig, preserves
the authored key times, closes the small sprint endpoint mismatch, and
calibrates floor clearance against the actual shipped boot skin. The temporary
carrier triangle is discarded; the runtime resource contains no geometry.

The original glTF import default of 30 fps does not preserve every 24 fps
source contact key. The extractor uses an intermediate 120 fps import, then
retains original motion keys and compact constant tracks. Only the small root
clearance curves keep dense samples. Sprint receives a constant offset to
preserve its intentional airborne portion.

`tests/online/extended_motion_probe.gd` checks native playback at 120 samples
per second, halfway between the calibration keys. It evaluates the original
skinned boots and sword, checks finite normalized bone transforms and loop
seams, and captures six actual native pose sheets. The accepted asset pass
has positive boot clearance in all six clips: minimum **1.117 mm**. The two
armed clips keep their blades at least **0.686 m** above the local floor.
See `VALIDATION.json` for hashes, individual results and test limits.

The existing tunic stretches across deeply flexed legs. This pack improves
motion and integration; it does not add cloth simulation or alter the mesh.
The retained Standard source has no authored strafing, backward locomotion,
turn-in-place, or second unique sword attack. Those are not attributed to it.
