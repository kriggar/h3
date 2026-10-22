# Buildings reconstructed from our painted cards

## Current instruction and status

The user's 22 October 2026 correction is decisive: construct in Blender what our original cards show. Do not repaint, regenerate or replace those cards to match existing models. The previous model/card-render direction is rejected. A technically valid export is not visual approval.

The original eight paintings are intact. The construction interface uses them at rest, hover and press. World-building motion remains an independent feature. All eight final reconstructions have now been visually reviewed and installed for development integration, with a separately reviewed town layout. Their source export manifests remain frozen candidate-stage records; the installed asset manifest records promotion separately. The design target remains a studio-presentable original game; this correction does not claim AAA completion or Heroes III parity.

## Locked reference

| Property | Value |
| --- | --- |
| Source | `assets/ui/manuscript/buildings.png` |
| Dimensions | 1774 × 887 pixels |
| Layout | 4 columns × 2 rows, 443.5 × 443.5 fractional cells |
| SHA-256 | `f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be` |
| Provenance | Original generated Draconia manuscript artwork, unchanged from retained v0.2 source |
| Allowed UI treatment | Framing, legible text, focus/hover border, tint-free placement of the unchanged cell |
| Disallowed substitute | Model render, live viewport, repainted architecture, card projected onto a box |

The drawing is an architectural brief, including the features it depicts. Its ink outlines and parchment belong to the illustration; the world uses actual modeled volumes and appropriate physical materials. The back and unseen interior require consistent authored construction. Neither invented back geometry nor differences in lighting excuse visible front-design drift.

## Required visible landmarks

| Cell / ID | Architectural locks | Details that must survive town scale |
| --- | --- | --- |
| 0 / `granary` | Raised timber barn on masonry piers; steep red gable; pierced front ventilation band; external stair to the long-side door | Diagonal floor supports, plank divisions, round ridge caps, multiple bound wheat sheaves and bulging grain sacks |
| 1 / `barracks` | Compact stone-and-log enclosure with four roofed timber watchtowers, taller rear tower, central arched gate | Pointed stakes, training target, weapon racks, elevated red heraldic flag |
| 2 / `market` | One dominant draped red-and-cream striped canopy, lower projecting awning and narrow side stall | Cloth sag/valances, hanging garlic/herbs, produce bins, baskets, crates and sacks |
| 3 / `smithy` | Stone gable, full red tile roof, open-front arched forge, square stone chimney, side log-store lean-to | Actual firebox, foreground anvil on stump, tools, stacked split logs and barrel |
| 4 / `shrine` | Secular Oath Hall; steep red roof, richly carved gable and rounded double-door portal, stone steps | Two long blue-and-gold heraldic banners, carved posts/brackets, exposed rafter tails and ridge beasts |
| 5 / `palisade` | Tall central decorated double gate between two roofed timber towers, short pointed-log wings and pointed stakes above the gate | Two slender plain-blue swallowtail banners with gold edging, cross braces, external angled defensive stakes and stone feet; do not reuse the Oath Hall griffin banners |
| 6 / `wharf` | Low broad plank pier, rope-wrapped piles, small rear shed, working cargo crane, moored clinker boat | Boat ribs/seats/oars, tether, cargo net, rope coils, barrels and crates |
| 7 / `water_gate` | Stone river arch between capped round turrets, crenellated wall, suspended portcullis and overhead hoist | Open channel with flowing water, side retaining gates, chain/hoist relationships and stone footings |

## Authoring and review sequence

1. Inspect the locked cell and record visible silhouette, proportions and distinctive features before modeling. The existing runtime model is not the design authority.
2. Author full 3D geometry in Blender, in metres with Z up and front −Y. Export maps this to Godot Y up/front +Z. Keep a ground-centred origin and explicit below-water geometry where needed.
3. Use local retained licensed PBR sources. Adjust material factors to the card's intended palette; keep grain and tile scale plausible. A texture must not counterfeit a missing doorway, boat, tower or roof form.
4. Render the real candidate with an aligned camera. Compare the painting and candidate side by side. Check proportion and silhouette before polishing minor detail. Record failures and iterate the model, leaving the painting untouched.
5. Inspect the exported scene in Godot. Verify its actual materials, normals, detail readability, entry clearance, selection bounds and plot integration. A Blender render alone is not evidence of runtime quality.
6. Exercise purposeful local hover motion, rest, re-hover and disposal. Hinges, ropes, cloth and mechanisms must remain attached and return to their canonical rest. A rigid whole-building wobble does not count as animation.
7. Exercise real construction and persistence. Keep the eight IDs, costs, prerequisites, effects and Wharf/Water Gate exclusivity unchanged. Verify the purchased model, original card and saved building agree.
8. Record the exact source, GLB and reference hashes with explicit disposition. The allowable dispositions are staged, needs rework, reviewed for development integration and production accepted. No automated check silently marks production acceptance.

## Files and historical evidence

New modules live under `assets/models/source/towns/card_reconstruction/`. `common.py` supplies import-safe geometry/material/export support with explicit initialization. It never promotes a model to runtime. Each building writes a packed editable `.blend`, embedded `.glb`, manifest and actual Blender previews under `assets/staging/card-reconstruction/<id>/`.

The previous `build_ashen_crown.py`, editable master and source-bound reports are retained. The prior 83-check rendered-card identity proof, 261-check hover run and 77-check composition run establish their stated technical behavior only. They predate and do not satisfy this corrected visual contract. The earlier release candidates and PDF likewise require a new review before publication.

## Review record

All eight buildings have editable reconstruction sources, individual painting
comparisons and relevant mechanical/native reviews. The final source set and
town layout are installed for development integration. None is claimed as
production accepted. The work includes multiple preserved revisions and failed
attempts; current exact hashes and remaining art refinements are documented in
[BUILDING_RECONSTRUCTION_REVIEW.md](BUILDING_RECONSTRUCTION_REVIEW.md). The
actual construction/save/reload gate is separate from isolated model review.

The installed-runtime gate now passes 1,506 assertions, zero failures, eight
real purchases, fifteen inspected native captures and exit 0. It uses an
explicitly funded QA realm and the actual construction/save/load interface,
including both exclusive river branches. Its final report is
`docs/verification-logs/card-reconstruction/runtime-gameplay-attempt03/report.json`.
This verifies the recorded construction route and source identity; it does not
convert the development art decision into production acceptance.

The restored painted-card interface has a separate 218-check native report
under `docs/verification-logs/painted-building-cards/`. The first normal-import
Granary/Oath Hall pair passed 173 technical checks, and five further candidates
passed 391. Those results apply to the exact recorded revisions. They did
**not** approve visual fidelity: the comparisons caused further revisions to
roof scale/color, carving, heraldry, the Smithy's forge chamber, and the
Palisade's banner and stake silhouette.

The first raw-GLTF diagnostic exposed absent mipmaps and tiny RESET matrix
round-trip differences. Its failed assertions and images are retained.
Normal Godot editor import of exact-byte, export-excluded test fixtures
provided the correct texture sampling. No replacement runtime material or
painted-card edit was used to hide the diagnostic problem.

The source-bound town audit in
`docs/verification-logs/card-reconstruction/town-integration-audit.md`
identifies concrete placement work: road/counter and road/anvil conflicts,
Granary stair support/access, river-wall access, Wharf deck/waterline
alignment, Water Gate inlet/foundations, and selection footprint heights.
The town must be corrected around these reconstructed buildings; simplifying
a correct card-defined building to fit an old plot is not a remedy.

That placement correction is now recorded in
`docs/verification-logs/card-reconstruction/town-layout-attempt03/`: 168 native
checks, zero failures and eight inspected captures. The work includes
continuous flat-core terrain blends, roads in the terrain material, real
entrance spurs, clear Market/Smithy work areas, a Wharf wall opening and stair,
the boat's waterline, a supported Water Gate basin/channel, and matching
selection footprints. These are populated presentation fixtures. The runtime
model copies and separate construction test are bound in
`docs/verification-logs/card-reconstruction/runtime-integration.json`.

Subsequent comparisons, failed attempts, source checks, actual native
captures and explicit visual dispositions belong in
`docs/verification-logs/card-reconstruction/`. Retain the tested revision
and its input hashes when a later revision is authored. Do not silently
relabel a previous failure as passed or add camera-only checks to motion
coverage.
