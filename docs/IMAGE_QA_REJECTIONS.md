# Draconia redesign — independent image review

**Review date:** 2026-10-22. **Disposition:** preserve the current files as historical prototype evidence; the rejected cells and crop contract below must not be promoted into the redesign. This is an inspection record, not a claim that the current game has been corrected.

The review opened the original PNGs at full resolution, inspected temporary enlarged crops of hands, weapon contacts, linked arms, animal legs and worker scenes, and compared the icon layout with the equal-cell extraction in `game/art.gd`. No original image or game code was changed. Enlargements were for inspection only; they are not new artwork.

## Blocking findings

| ID | File and exact subject | Observation | Required correction and acceptance evidence |
| --- | --- | --- | --- |
| IMG-001 | `assets/generated/manuscript-portraits.png`; row 3, column 3, Ileana; nominal cell `(724,724,362,362)` in the 1448×1086 atlas | Three distinct hands appear around the lower-right weapon area: a high hand around a grip, a second hand immediately below it, and the opposite-sleeve hand across the lower diagonal blade/scabbard. The arms cannot account for all three. | Reject this portrait. Create a head-and-shoulders portrait of the same adult heroine with no hands or weapons in frame. Inspect face, hair, ears, neckline and shoulder anatomy at full resolution and at the actual portrait-card size before accepting. |
| IMG-002 | `assets/generated/manuscript-scenes.png`; row 1, column 1, logging/ox scene; nominal cell `(0,0,768,341.333)` in the 1536×1024 atlas | The ox has extra or merged leg-like forms. The near and far legs cannot be traced into a clean four-limb anatomy, especially around its hindquarters and forelegs. A second animal is not clearly established to explain them. | Reject the ox depiction. Regenerate a simpler side-on four-legged ox or a logging composition without a foreground animal. Trace each limb from shoulder/hip to hoof and verify the yoke, cart shafts, rope and load connect plausibly. |
| IMG-003 | `assets/generated/manuscript-scenes.png`; row 2, column 2, Iele dance; nominal cell `(768,341.333,768,341.333)` | The linked-dance contact geometry is incoherent: one central hand meets another figure's arm, while the extended lower hands do not form a readable joined pair. The problem is interaction geometry; no extra limb needs to be alleged. | Reject the linked-hand composition. Either regenerate three clearly separated figures with simple gestures, or require separately traceable pairs of hands and arms in a simpler dance. Preserve the wingless forest-spirit design. |
| IMG-004 | `assets/generated/ui-icons-v2.png`; the equal 4×4 atlas contract in `DraconiaArt.ui_icon()` | The PNG is 1247×1261, giving cells 311.75×315.25. Actual object rows do not obey those boundaries. Last-row objects begin above y945.75, so the shield, backpack, banner and astrolabe lose upper details when extracted. The keep and crossed swords also extend above their row's y630.5 boundary. This is a crop/layout failure, independent of anatomical quality. | Reject the current equal-grid extraction contract. Generate approved individual transparent icons and pack them mechanically with explicit rectangles and gutters, or define validated per-icon rectangles for intact objects. Inspect all 16 actual extracted icons at 32, 48 and 64 pixels against light and dark UI surfaces. |

Coordinates are source-pixel references, not proposed replacement crop values. Fractional cell sizes reflect the current equal division. For IMG-004, changing rectangles alone is acceptable only if each complete object can be isolated without including its neighbor; the review has not certified such a rectangle set.

## Scope of the inspection

The full twelve-portrait sheet and six-scene sheet were reviewed. Enlarged crops additionally covered the archer's bow grip and drawing hand, Solomonar's raised hand, the armored swordsman's hands, Ileana's weapon area, the Iele dance, the logging ox, keep workers and the army assembly scene. The current icon PNG and its extraction implementation were inspected together.

No further obvious gross extra-limb defect was identified in the other portraits at the inspected resolution. This is a limited observation, not approval of every finger, contact or historical detail. Tiny keep workers and distant army figures still require acceptance in their final native panel. The remaining scenes, decorative crest, terrain materials and older image set have not passed a complete redesign art gate merely because they are absent from this rejection list.

## Provenance of the reviewed versions

| Asset | SHA-256 at review |
| --- | --- |
| `manuscript-portraits.png` | `9a774ec0336a7f99a40650cfc4c631b554db317cc81b8032ffb53dee558b328e` |
| `manuscript-scenes.png` | `8c61f3fddb71c90d4d9997e8289bf94fffb530e6249a93acaf0af46a4bee66ed` |
| `ui-icons-v2.png` | `3cf1a618e44451572c4c89c2985214d143088d1742f5cfab06f53369054c5a62` |

The generation prompts and original paths are recorded in `assets/generated/generation-prompts-v2.json`. Replacements must receive new files and hashes; do not silently overwrite the evidence associated with these findings.

## Gate for every replacement

1. **Define:** name the subject, use, crop, scale, intended anatomy and material style before generating.
2. **Build in staging:** retain the prompt, source output and proposed crop. Generated imagery supplies UI illustration, concepts or material inputs; it does not replace rigged world characters.
3. **Inspect anatomy and contact:** count visible limbs and digits where resolvable; trace joints; check hands against grips, arrows against bow strings, feet against ground, straps against bodies and connected objects against one another. If an occlusion makes a critical contact unreadable, simplify the pose.
4. **Inspect the actual panel:** show the real texture/crop in the native Godot UI at supported resolutions and scale settings. Confirm contrast, object completeness, readable silhouette and no neighboring atlas leakage.
5. **Accept or rework:** a reviewer records the exact hash, scene/panel, observation and disposition. A successfully generated image, passing PNG decode or test count is not visual acceptance.

The historical source checkpoint may contain these rejected images because it preserves the working prototype. It must not be described as an approved art release for the redesigned game.

## Limited portrait crop use

The user subsequently reselected the original atlas as the authoritative illustration style. This approves the flat inked/colored parchment direction, while the full Ileana/Mara cell remains anatomically rejected. A head/shoulders-only UI crop may be reviewed and accepted as its own resource/use without asserting that the rejected hands or the full figure passed. The runtime panel still needs real-engine legibility and crop inspection. New painterly woodland bust directions are rejected.

**Reviewed crop:** `Rect2(738, 700, 342, 234)` in the original 1448×1086 portrait atlas. This crop shows the full head, braid, shoulders and upper chest without hands, weapons or an adjacent figure. Its anatomy and framing pass this limited static review. It does not approve the full source figure; final native UI legibility remains a separate gate. The first attempted nominal cell crop clipped the top of the hair and a taller crop caught a hand, so the final explicit rectangle replaces an equal-grid assumption.
