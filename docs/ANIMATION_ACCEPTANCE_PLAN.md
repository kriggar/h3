# Native animation acceptance plan

Revision: 22 October 2026. This is a bounded improvement and review plan, not a claim that all motion is flawless or that the production roster is animated. The current promoted Mara v8 model remains unchanged by this document.

## Preserve the verified baseline

[`assets/models/mara/manifest.json`](../assets/models/mara/manifest.json) records the actual 53-bone rig, 12 imported clips, source hashes, timing estimates and remaining production blockers. The v8 model and two earned equipment modules passed a development integration review. The retained evidence includes actual Godot grip, attack, cast, roll and death poses, weapon hiding/release, fitted cowl clearance, repeated-update stability, and independent still review. Those checks support their specific claims. They do not establish production-quality cloth, continuous foot planting or every transition.

The actor controller and combat rules own movement, collision, commitment and damage. A visual animation is evaluated against that state. Retargeting a new clip must not silently change reach, invulnerability, attack impact, recovery, stamina cost or save/load behavior. The current dodge separates its 0.8-second full presentation from the shorter movement and evasion windows. Authored root motion is useful reference data; it is not collision authority in this slice.

## Current motion and concrete gaps

| Gameplay use | Current source clips | Current boundary | Next acceptance evidence |
|---|---|---|---|
| Rest and travel | `idle`, `walk`, `run` | Real skinned motion; continuous controller gait still needs normal-speed review | Straight travel, small corrections, 90/180-degree turns, start/stop and obstruction at the actual game camera; planted feet must not visibly skate or teleport |
| Basic sword strike | `attack` | Wrist correction keeps starter blade and Vowkeeper above the floor in measured samples | Idle/run into attack, repeated legal attacks, hit interruption where allowed, correct impact and recovery at gameplay speed; neither blade floats or passes through the gripping palm |
| Guard | `combat_idle` | A distinct sword-ready stance; **no authored block-impact reaction** | Hold/release and guarded hit feedback without substituting a normal idle; a dedicated recoil is a separate missing asset |
| Empty-hand spell | `cast_start`, `cast_hold`, `cast_release`, `cast_end` | Actual casting motion with sword stowed/hidden | Hands, effect origin and release coincide; interruption, cancelled hold and recovery restore the right equipment exactly once |
| Dodge | `dodge` | A full roll, with the equipped cowl's sampled visual clearance | Normal-speed entry/get-up, both equipped/unequipped states, wall stop and direction changes; no accumulated visual offset or actor collision movement from the clearance sampler |
| Receiving a hit | `hit` | Short authored recoil | Legal interruption from locomotion/attack/cast and recovery to the surviving state; avoid repeated blend resets and frozen poses under rapid hits |
| Death | `death` | Full fall, one loose weapon and no held sword through the body in the inspected proof | Normal-speed contact, final settled pose, pause/save/load/restart; no duplicate weapons, rebound, foot sinking or pose reset |
| Loot, doors, shrine/service use | No dedicated accepted interact clips | Gameplay can be functional without claiming an authored interaction | A bounded reach/pickup/lever action with actual hand contact, compatible equipment policy and an interrupt rule |
| Direction changes and combat locomotion | No accepted dedicated start/stop/turn/strafe library | Reorienting the whole actor alone is not complete animation polish | Targeted transitions with contact-aware blending; acquire only the movements needed by implemented controls |

The current two visual equipment items are Vowkeeper and Bellworn Cowl. Their fit does not certify the proposed twelve armor sets, every possible item combination, other hero bodies, or the 54 base creature families. Each distinct anatomy and equipment envelope needs its own evidence.

## One ability, one visible promise

The user's “what you have is what you get” requirement applies to ability icons, character motion and effects together. Define a small authoritative feedback record for each implemented ability: semantic action, animation states, weapon policy, aim/target shape, telegraph interval, actual effect origin, release tick, impact and recovery. Derive the ability preview from the same native effect and character assets. An icon may simplify the view into the approved parchment style, but it must preserve the real action, element, direction and area; a generic fireburst must not advertise a sword arc or a protection stance.

Review each complete chain in the running engine: select card → aim/telegraph → commit → visible release/contact → hit or miss → recovery. Check a miss, an obstructed target and an interrupted action as well as the successful case. A timer assertion alone cannot prove the weapon/effect lines up. A beautiful isolated icon cannot approve the animation. The current spell-feedback follow-on is a separate implementation task, not completed by this plan.

## Practical review pass

1. **Define.** Record the exact rules state, source clip, equipment policy, expected contacts and gameplay-speed mapping. Keep the old GLB and manifest hashes as a rollback baseline.
2. **Build in Blender.** Inspect the imported rig's rest axes and scale; retarget only the necessary channels; fix hand grip and shoulder/elbow behavior on the actual clothed model. Preserve the body, garment masks and accepted motions unless a change is deliberate.
3. **Test rules and export.** Verify the same gameplay ticks before/after. Export metres, +Y up, +Z forward with explicit clip names. Check clip duration, loop mode, track paths, missing bones and equipment sockets on a fresh Godot import.
4. **Inspect actual native motion.** Capture normal-speed sequences at the regular action camera and a neutral close camera, with starter gear and the two earned items. Use slow scrubbing only to diagnose a visible problem; it does not replace the normal-speed pass. Include front, side and back views where a garment or weapon can hide contact problems.
5. **Accept or rework the specific change.** Name remaining defects and preserve before/after captures. Do not count passing metadata assertions as independent visual approvals. Reject extra/deformed anatomy, floating grips, blade-floor/body penetration, broken neck/shoulder silhouettes, detached clothing and an unexplained pose snap.

Exercise the same transition sequence at normal frame rate and with a deliberately reduced render frame rate while rules ticks remain fixed. The important result is stable visual timing and state recovery, not a large number of repeated screenshots. Foot-contact thresholds should be judged against on-screen scale, ground slope and movement speed; establish and record those bounds from actual footage rather than inventing a universal millimetre guarantee.

## New motion sources: verified candidates, no silent upgrade

The current retarget used the pinned April 2025 Standard source retained with the project. On the creator's primary [Universal Animation Library page](https://quaternius.itch.io/universal-animation-library), the 23 January 2026 update fixes a sword-swing elbow twist, the 4 February update corrects 24-to-30 fps export timing, and the June update adds root-motion versions and synchronizes directional steps. The creator declares CC0 and offers a free Standard subset; broader and editable-source editions are separately priced. These changes are a reason to evaluate a candidate, not evidence that the current Mara clips were replaced or that all advertised motions are in the free subset.

The primary [Universal Animation Library 2 page](https://quaternius.itch.io/universal-animation-library-2) declares CC0 and lists combat, farming, fishing and other actions. Its 28 September 2026 update repairs sword-light end frames that did not match recoveries. The Standard archive is free; the full source edition is paid. A useful next bounded evaluation is a block reaction plus one interaction or turn/stop motion, only if those actual clips exist in the free archive. No new archive was downloaded for this review. Preserve the downloaded version, source URL, license, SHA-256 and original files if that evaluation is later authorized and performed.

## Town animation boundary

The current eight original Ashen Crown Blender buildings are a static base-geometry pass. Separate doors, banners, crane boom and portcullis groups reserve useful motion boundaries; they are **not authored work-cycle animations**. Production life should be state-driven: a smith's tool contacts the anvil, a grain worker's carried sack transfers at the store, the wharf's rope stays attached to its load, guards follow walkable routes, and occupied buildings alone emit activity. Model motion, smoke, water, cloth and worker clips each need native inspection at the town camera. A looping floating prop cannot be labeled a believable worker or production cycle.

Town camera detail and runtime cost must also be bounded: use a small number of visible workers, shared rigs and materials, distance-based animation update rates, real model LODs and consistent wind. The final panorama must be profiled with its actual inhabitants and effects. No present static model review closes that performance or animation gate.
