# Mara Veyne — native 3D integration proof

This is one fully clothed adult female hero basis. The v9 revision is accepted
for **development PBR material integration**, with explicit character-art work remaining. It does not
complete the hero roster, the equipment catalog or all required character art.

`manifest.json` is the exact current version/hash contract. The stable model is
`res://assets/models/mara/mara.glb`; `sword.glb` is its matching loose weapon.

## Coordinates and scene contract

- Metres, **+Y up, +Z forward**, approximately **1.63 m** standing height.
- Feet offset **0**. Position the controller independently; animation cannot
  move through walls or decide damage, invulnerability or action commitment.
- Skeleton: `IleanaRig/Skeleton3D`, **53 bones**. The legacy rig name is an
  internal compatibility ID; the character's display name is Mara Veyne.
- AnimationPlayer: `AnimationPlayer`.
- Main/off-hand bones: `hand_r`, `hand_l`.
- Default held sword mesh: `IleanaRig/Skeleton3D/Mara_Sword`.
- 41,590 triangles, nine mesh objects, fourteen surfaces and thirteen materials.
  This is not yet the final combat LOD/material budget.

## Actual native clip names

| Clip | Seconds | Loop | Intended use |
|---|---:|---|---|
| `idle` | 2.5000 | Yes | Relaxed standing |
| `walk` | 1.3333 | Yes | In-place walk |
| `run` | 0.9167 | Yes | In-place run/jog |
| `attack` | 1.5417 | No | Sword attack; controller owns impact |
| `hit` | 0.3333 | No | Chest hit reaction |
| `death` | 2.4167 | No | Unarmed backward fall; release weapon first |
| `combat_idle` | 1.6667 | Yes | Bent-knee sword-ready stance for sustained guard |
| `cast_start` | 0.5417 | No | Raise the open casting hand |
| `cast_hold` | 2.0833 | Yes | Optional aim/channel hold |
| `cast_release` | 0.5000 | No | Genuine spell-release gesture |
| `cast_end` | 0.4167 | No | Lower the casting hand |
| `dodge` | 1.4583 | No | Genuine in-place forward roll |

The ready stance is distinct from idle, but it is not an authored shield-block
impact. Do not claim a missing block-impact clip has been completed.

The source clips were baked at 24 fps. Native imported loop flags and lengths
are recorded in the manifest. The source names and retarget mapping are kept
in the editable staging evidence.

### Rules and pacing

Seek or speed-match visual clips to the authoritative action timeline; never
use animation playback events as a second damage source. The initial sword
contact estimate is phase **0.44**, about **0.68 s** of the authored clip.
Gameplay may choose another event after actual camera inspection.

For spells, use `cast_start` during windup, optional `cast_hold` while aiming,
`cast_release` at commitment/recovery and `cast_end` before returning to idle.
Blend toward movement when the rules permit interruption. A cleave remains a
weapon action and uses `attack`, not the open-hand casting gesture.

At scale one, analytic near-ground foot velocities suggest about **0.89 m/s**
for walk and **4.77 m/s** for run at authored speed. These are starting points,
not proof that the game controller has no foot sliding. Multiply by visual
scale, match playback rate to movement speed and inspect in the actual world.

The full roll takes 1.458 s at source speed. Compressing it into 0.3 s is 4.86×
speed and loses readability. Roughly 0.8 s is a useful initial total visual
duration; invulnerability, displacement and get-up recovery remain separate
rules. The gameplay team determines and tests their exact windows.

## Weapon visibility and release

The casting and roll motions were authored unarmed. Hide or stow the held
weapon through `cast_start`, `cast_hold`, `cast_release`, `cast_end` and
`dodge`. Restore it after the state, subject to the actual equipment choice.

On death, **release/hide the held weapon once at state entry (t=0)**. Retaining
it through the unarmed source fall causes body/floor intersections. The model
contains no automatic gameplay or visibility-event tracks; the controller
must apply this policy, including after loading a saved action.

The loose `sword.glb` has its origin at the grip center and blade along local
**+Y**. `sword-socket.json` supplies the exact **bone-local matrix rows** for a
`hand_r` BoneAttachment3D. Construct Godot's Basis from the first three
**columns**, then its origin from the last column. This attachment was
verified against the held mesh in a native grip render. At release, preserve
the weapon's global transform before detaching or creating the loose prop.

## Registered earned equipment

`equipment/manifest.json` is the authoritative module contract. Exactly two
earned visual items are supplied:

| Equipment ID | Runtime scene | Attachment |
|---|---|---|
| `vowkeeper_sword` | `equipment/vowkeeper.glb` | Bone attachment on `hand_r`; hide the default sword |
| `bellwarden_hood` | `equipment/bellworn-cowl.glb` | Copy the named skinned mesh onto the existing `Skeleton3D`; retain the `Skin` and use `skeleton=NodePath("..")` |

The cowl preserves the face and braid. Do not retain a second animated
skeleton from its transport scene. Both modules are development integration
proofs; the rest of the equipment catalog remains unfinished.

### Visual ground clearance

The cowl's `visualGroundClearanceByClip` contains uniformly spaced offset
samples in metres at model scale one, measured in native Godot skin playback.
For the actual authored seek time `t`, calculate
`u=clamp(t/durationSeconds,0,1)*(sampleCount-1)` and linearly interpolate the
two adjacent samples. Unknown clips and unequipped modules return zero.
If several modules request an offset, take the maximum, not the sum.

`HeroAppearance.visual_clearance` implements this manifest contract. The
dungeon adapter stores the visual pivot's baseline Y once and sets its Y to
that baseline plus the sampled offset multiplied by model visual scale after
every animation seek. It never adds to the previous frame's position and
never moves the actor root, rules position, collision or ground markers.
Idle preview therefore has zero additional offset. The maximum authored
curve values are 0.074123 m for roll and 0.012550 m for death.

The native dungeon harness checks every controller tick of the 0.8 s roll
and the 2.417 s fall, repeated seeks, restoration to idle, unequipping and
one-time weapon release. Its report and captures live in
`assets/staging/ileana-mpfb-proof/evidence/runtime-equipment/`.

## Source and rights

- Body, eyes, brows, lashes and braid: MakeHuman community, **CC0**.
- Tunic, trousers and boots: RehmanPolanski's selected official MakeHuman
  *Suits 02* entries, **CC0**.
- Source motions: Quaternius, *Universal Animation Library Standard*,
  creator upload of 16 April 2025, **CC0**.
- Tool: MPFB 2.0.18, pinned commit
  `d0a32e57a7f915cb2f2b95410e2117648c7bbb7e`; **GPL-3.0-or-later tool code**
  is separate from **CC0 exported asset rights**. The tool is not required by
  the running game.
- Project-authored work: selected adult body proportions, material design,
  rig fitting, masks, retarget/floor/grip corrections and the sword geometry.
  Project release terms apply to new work; original asset licenses remain.

See the root `ASSET_CREDITS.md`, `assets/licenses/CC0-1.0.txt`,
`assets/licenses/MAKEHUMAN-CC0-ASSET-NOTICE.md`, and
`assets/licenses/QUATERNIUS-ANIMATION-NOTICE.txt`.

The unchanged selected downloads, per-member hashes, pinned tool source,
editable Blender files, scripts and actual native captures are preserved in
`assets/staging/ileana-mpfb-proof/`. That source/evidence area is excluded from
runtime imports and should not enter the native PCK.

## Qualified acceptance and open work

Two independent reviews accepted v6's body/clothing attachment and coherent
right-hand grip for integration. The v7 extension was inspected in actual
Godot front/three-quarter/action views, plus 24 fps native motion capture and
floor-grid contact sequences. The evidence distinguishes inspected poses from
untested gameplay/controller behavior. Later corrections are recorded by hash
and version rather than silently changing the earlier evidence.

V8 corrects only `attack/hand_r` rotation, with at most 15.533 degrees of
additional wrist pitch. The other eleven clips and every other numeric
animation channel are unchanged from v7. Both the starter blade and
Vowkeeper remain above ground in the retained 96 Hz source evaluation;
native low-swing/contact views were independently reviewed before promotion.

V9 adds licensed CC0 wool, linen, leather and metal PBR maps; original baked
skin microdetail; physical-scale UVs; restored neck coverage; and rounded
cloth binding. Original animation/node/skin data is preserved. The material
renderer now supplies cached, anisotropic mip filtering, including normal-map
renormalization. Its actual editor-imported native review passed 245 checks
with ten inspected images. The two fitted modules and loose sword share the
material library while retaining their original attachment and clearance
contracts.

The packed editable Blender snapshot is
`../source/characters/mara-pbr-v9/mara-pbr-v9.blend`. Exact source and material
hashes, transformations and review scope are documented in
[the character material guide](../../../docs/CHARACTER_MATERIALS.md) and
`manifest.json`.

Production work remains: uneven front collar/cowl edges, tunic hem and elbow
deformation, final face/eyes/hair identity, boot normal/roughness maps,
secondary braid movement, equipment combinations, authored lower LODs and
material consolidation. These accepted surface improvements do not establish
finished photorealistic character art or flawless continuous animation.
