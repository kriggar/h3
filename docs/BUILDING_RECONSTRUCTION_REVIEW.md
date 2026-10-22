# Painted building reconstruction review

## Decision and scope

The original Draconia building paintings are the architectural authority. The
Blender models have been reconstructed toward those paintings. The paintings
have not been regenerated, repainted, replaced with model renders, or projected
onto simple geometry.

This review records a development integration decision. It is not production art
acceptance, a claim of AAA quality, or a claim that the user has approved the
result. Source checks establish specific mechanical properties; visual review
establishes the correspondence described below. Neither establishes the quality
of the whole game.

The exact reference is `assets/ui/manuscript/buildings.png`, 1774 × 887 pixels,
with SHA-256
`f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be`.
Its eight cells retain their original fractional 443.5-pixel regions. Cards use
those cells throughout rest, hover, focus and press. A missing model or model
review record cannot silently replace or disable the painted card.

## Reviewed buildings

The revisions below refer to the final reconstruction candidates, not the
earlier installed models. Actual Blender previews and normally imported Godot
views were inspected against the unchanged painting. The comparison cameras
are chosen to expose the relevant features; the painting is not treated as an
exact recoverable camera projection.

| Building | Revision | Correspondence visible in the reviewed model | Remaining art refinement |
| --- | --- | --- | --- |
| Granary | 8 | Raised timber barn on six masonry piers, diagonal supports, steep red roof and ridge caps, four real front vents, long-side door and external stair, separate wheat sheaves, sewn grain sacks and barrels. | More varied weathering, less uniform roof wear, and finer organic detail in grain and fabric. |
| Training Yard | 4 | Compact stone-and-log enclosure, four roofed towers with a taller rear tower, arched central gate, pointed perimeter stakes, target, weapon racks and red heraldic flag. | More irregular masonry and timber wear; further close-view detail on equipment and heraldry. |
| Market | 4 | Dominant curved red-and-cream striped canopy, lower projecting awning, narrow side stall, tension ropes, valances, counters, hanging goods and individual produce containers. | Produce, herbs and fabric still need less regular shapes and finer surface work. |
| Smithy | 5 | Stone gable, full red roof, square chimney, actual recessed forge chamber, fire and grate, foreground anvil, tools and a side log-store roof. | Anvil and small props remain simplified; soot, smoke, local light and fire presentation need a wider art pass. |
| Oath Hall | 7 | Secular carved timber hall, steep red roof, rounded double-door portal, stone steps, two long blue-and-gold griffin banners, side windows and ridge beasts. | Ridge beasts and heraldic curves remain angular at close range; carving and cloth need finer finish. |
| Palisade | 7 | Decorated central double gate, two roofed timber towers, pointed-log wings, stakes visible over the gate, external defensive braces, stone feet and narrow blue swallowtail banners with gold edging. | Fine carving, wood damage and material variation remain below final production quality. |
| Wharf | 4 | Broad low plank pier, rope-wrapped piles, rear shed, crane and suspended net, cargo, open clinker boat with ribs, seats and oars. | More varied plank wear, cloth and rope finish; environmental water and shore presentation need continued polish. |
| Water Gate | 5 | Stone river arch between round capped turrets, actual high and low arrow slits, crenellations, suspended portcullis, overhead hoist, side retainers and stepped water. | Stone size, color and wear remain more regular than the painting; water presentation is a development implementation. |

The Oath Hall retains the historical internal ID `shrine` for save compatibility.
Its visible architecture and name describe a secular hall. The Training Yard
likewise retains the internal ID `barracks`.

## Corrections established by iteration

Door animation was inspected against actual evaluated geometry, rather than
only checking that an animation clip existed. Early Granary and Oath Hall
revisions had rails, brackets or hinge hardware passing through moving leaves.
The final revisions interrupt the obstructing rails, use offset pintles and
cranked hinge mounts, and provide low thresholds with measured leaf clearance.
Their fixed structure remains stationary during the local door motion.

Banner reviews corrected the Training Yard's flag attachment, the Oath Hall's
support clearance and heraldry, and the Palisade's silhouette. The Palisade uses
its own narrow plain swallowtails rather than borrowing the Hall's griffins.
Market revisions changed the actual canopy shape and folds. Smithy revisions
closed gaps in the recessed forge chamber. Water Gate revisions made the turret
slits actual openings and corrected mechanism and roof clearances.

The first raw glTF diagnostic exposed missing mipmaps. Subsequent native reviews
used exact-byte fixtures imported through the normal Godot editor pipeline.
They did not hide the problem with a replacement runtime material. Earlier
failed reports remain preserved with their original inputs and results.

## Evidence and interpretation

`docs/verification-logs/card-reconstruction/native-candidate-set-v1.json` binds
all eight GLB files, editable Blender sources and manifests to their exact
normally imported native reports and inspected captures. It describes the
candidate stage and remains frozen as historical evidence after integration.

| Evidence | What it establishes | What it does not establish |
| --- | --- | --- |
| Painted-card native UI review | The original cells appear at rest, hover and press without a live-model substitution. | Final model quality. |
| Independent public card API review | Card paths, fractional regions and textures remain available independently of model proof files. | Gameplay construction or save behavior. |
| Source mechanical sweeps | The named checks against 91 evaluated source frames, including scoped clearance and attachment checks. | A general physics simulation or all possible future edits. |
| Native model reports | Correct imported model bytes, texture mipmaps, local hover/rest/re-hover behavior, unchanged mesh/material/clip sources and the recorded views. | Exact painting reproduction, production performance, or the whole town's behavior. |
| Whole-town review | Placement, access, terrain, river and selection behavior for the explicitly recorded arrangement and branch. | A complete campaign playthrough. |
| Actual runtime construction review | The recorded purchases, costs, daily restrictions, exclusivity, original cards, installed models, hovering and save/reload. | Unimplemented factions, towns or classes. |

Report counts overlap and apply to particular revisions. Camera-only reports
are not additional motion coverage. A multi-model report may retain a
superseded sibling revision; the per-building final index identifies which
record is current. Failed attempts are not relabeled as passed.

## Integration record

The previous installed model directory, import settings, manifest and relevant
runtime scripts are preserved in
`assets/staging/card-reconstruction/prior-runtime-installation/`.

The reconstruction export manifests intentionally remain staged-candidate
records. Installing reviewed bytes into the game is recorded separately in
`assets/models/towns/ashen_crown/manifest.json` and the runtime verification
record. Exporting from Blender never silently promotes or production-accepts a
building.

The final staging town passed 168 checks with zero failures and eight inspected
native captures. The project reviewer inspected all eight images and approved
the scoped placement corrections for development integration. Evidence is in
`docs/verification-logs/card-reconstruction/town-layout-attempt03/`.
The approved runtime adaptation is
`978c81cc357b9e3d3d497b917f0e6ffe516386c3a661361fae88cd34f108eb43`;
its separate diff removes the fixture loader and diagnostic-only data while
retaining the tested placement and presentation behavior.

The actual runtime construction review passed **1,506 assertions with zero
failures, eight real building purchases, fifteen inspected captures and exit
0**. Evidence is in
`docs/verification-logs/card-reconstruction/runtime-gameplay-attempt03/`.
The test used the real construction interface, actual mouse-wheel navigation
and an explicitly funded QA realm. It retained unchanged costs, prerequisites,
the daily cap and watch accounting, then saved and restored both legal river
branches through the game menu. Original painting pixels and exact installed
model sources were checked alongside live hover, rest and re-hover behavior.

The first attempt missed a control below a scrollable panel and is retained as
a failed harness route. The second was stopped as a partial run after three
purchases because its fixed timeout could not cover the complete route on the
software renderer. The final attempt corrected UI readiness and allowed enough
wall time while preserving the animation and assertion semantics. Neither
earlier attempt has been relabeled as a pass. The successful log contains only
the known unsupported virtual-display V-Sync warning.

The exact installed copies, final source hashes and linked runtime report/log
are bound in
`docs/verification-logs/card-reconstruction/runtime-integration.json`.
Exported-binary checks retain their own separate evidence. These scoped results
do not accept production art or establish a full-game performance budget.

## Remaining project quality gap

The rebuilt buildings correct a substantial architecture mismatch. The wider
environment still needs a coherent production art pass: terrain and vegetation,
the central keep and ambient houses, lighting, material variation, shore detail
and town-scale composition. The isolated buildings also retain the refinements
listed above. Target hardware profiling, deliberate LODs, extended save
compatibility tests, animation coverage and a production audio pass remain
separate work.

The playable project still contains one implemented hero, one capital and a
limited dungeon loop. The larger faction, hero, class and campaign catalogs are
design material. This reconstruction does not turn those catalogs into playable
content and must not be presented as a completed Heroes III-scale game.
