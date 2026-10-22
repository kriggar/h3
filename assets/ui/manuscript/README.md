# Draconia manuscript UI artwork

## Provenance and intended style

These four PNGs were created for Draconia with the built-in image-generation
tool, under project direction. The project's user-approved
`assets/generated/manuscript-portraits.png` was the **style-only reference**:
crisp ink contours, restrained painted shading, muted red/blue/green and warm
parchment. They are original generated project artwork, not downloaded game
assets or a reuse of the Heroes III interface. This provenance category does
not relabel them as third-party CC0 art or engine code covered by Godot's MIT
notice.

The images contain objects, architecture, heraldry and page decoration. They
introduce no new human figure. The existing portrait used by the UI remains
the separately approved head-and-shoulders crop, `Rect2(738,700,342,234)`, from
the original portrait sheet; the anatomy rejection of its full figure remains
in force. Secular heraldry and manuscript ornament are intentional. There is
no halo or saint framing around a character.

## Measured files and crop contract

Dimensions below were read from the actual PNG files, not inferred from a
generation request. All four files are RGB with an opaque parchment ground.

| File | Actual pixels | Layout | SHA-256 |
|---|---:|---|---|
| `buildings.png` | 1774 × 887 | 4 columns × 2 rows | `f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be` |
| `symbols.png` | 1254 × 1254 | 4 × 4 | `a830b2d6aa1d2795303e9b2da156f95ac73db6bfce25c2ad897ccd370faefd0b` |
| `equipment.png` | 1254 × 1254 | 4 × 4 | `266060a57ba39a4e53d14cc2d50f09e114b2849dd8364b51e4dbb46414b00da4` |
| `folio.png` | 1536 × 1024 | One page frame, not a tiled icon atlas | `23e3d45e9e138e2144d4f12f2dc9e803c3520252426126fbcd1c191ffcfdd1f8` |

`game/redesign/manuscript_art.gd` supplies the semantic cell order and uses
proportional AtlasTexture boundaries with filtering clipped to the region.
Cells are 443.5 pixels square for buildings and 313.5 pixels square for the
two icon sheets. Preserve fractional boundaries; integer cell assumptions
would gradually shift the final row/column. The folio's separate crest region
is `Rect2(657,0,220,224)`. A replacement source image or crop change needs a
fresh native review. The source PNGs remain intact.

## Independent visual review — 22 October 2026

An independent asset reviewer compared all four complete sheets against the
approved portrait sheet, then inspected the actual native captures
`03-equipment.png` and `07-vault-combat.png`, both **1440 × 900**. The reviewed
capture SHA-256 prefixes were `ac6b3f715b462ad5` and `8e2f2fca79e6dc18`.

No new malformed-object rejection or neighboring-cell contamination was
found in those sheets and displayed crops. Buildings, weapons, empty armor,
resources and action symbols have readable silhouettes. The gauntlets, boots,
sword fittings and architectural connections show no conspicuous extra part
or disconnected component at the inspected scale. The inked treatment and
palette agree with the approved style. This is a bounded visual finding, not
an assertion that every pixel or future UI state is defect-free.

Meaningful limits remain:

- At roughly 46–62 pixels, engraving, fingers, masonry and trim resolve as
  texture; labels carry the precise meaning. Do not require miniature detail
  to communicate a rule or item property.
- Ward and Guard currently share a shield symbol. Their labels and key hints
  distinguish them; the artwork alone does not.
- Equipment pictures are **slot/category icons**, not exact depictions of each
  3D item. The ornate blue hood and illustrated sword do not certify that all
  embroidery or blade details exist on the equipped model.
- Faint empty-slot labels approach the lower contrast limit against the worn
  paper. Smaller screens, different scaling and other display conditions
  still need review; these two captures do not establish them.
- The folio supplies a decorative frame and paper ground. It does not prove
  modal layout, keyboard focus, hover states, localization, animation or the
  completeness of the game's broader art catalog.

Disposition: suitable for the inspected native UI integration, with the
limits above. No PNG or UI code was changed during this review.

## Authoritative painted building cards

The original `buildings.png` atlas is the visual authority for all eight
buildings. Its locked hash and fractional 4 × 2 mapping above remain unchanged
and match the frozen 0.2 source archive. The later model-first card-render
policy is superseded: **keep the paintings in the interface and rebuild the
Blender buildings to match them**.

`manuscript_art.gd::building(id)` returns the corresponding original
`AtlasTexture`. The actual `BuildingCardButton` keeps that painting during
hover, focus and press; its frame may highlight, but it never substitutes a
3D render or live viewport. The town's separate authored 3D hover/work cycle
remains available. Price, prerequisites, effects, purchase limits and saved
IDs remain owned by `RealmRules` and are unchanged.

The public `BuildingVisuals` registry also returns this original atlas and its
exact cell metadata. Its `card_texture` delegates to the same painting cache;
neither it nor `card_path` requires a model scene or old rendered-card proof.
Historical render paths and fingerprint helpers remain diagnostic only.

The installed eight Blender buildings have now been reconstructed from these
cards and reviewed for development integration. Public metadata records
`painted_card_authoritative_reconstruction_integrated`,
`modelStatus: reviewed_for_development_integration` and
`productionAccepted: false`. The original paintings remain the unchanged
authority. The superseded model/render and animation reports remain preserved
as historical technical evidence, not proof of user art approval.
See `docs/BUILDING_CARD_IDENTITY.md` for the exact crop table, the painting-to-
Blender review criteria, the new native GUI gate and the historical evidence
boundary. No PNG pixels have been changed by this restoration.

The earlier focused native restoration gate passed **218 checks with zero failures**
and exit 0, with seven inspected 1440 × 900 captures. All eight card interiors
kept identical rendered pixels through hover, each click retained the exact
atlas cell, and a real Granary purchase preserved its existing cost and time
rules. That checkpoint tested the earlier models' mechanism and does not
approve a later 3D building revision. Raw
evidence is in `docs/verification-logs/painted-building-cards/`.

A separate API check passed 104 assertions in an isolated project without any
model scenes or historical rendered-card files, and 95 overlapping assertions
in the actual project. Both returned identical eight-cell pixel hashes with
zero failures. This verifies public lookup independence; it is not another
model-art acceptance. Evidence is in
`docs/verification-logs/painted-building-public-api/`.

The same 104/95-assertion API variants were repeated after reconstruction
promotion against the explicit development-only registry status. Both passed
without warnings or errors; all cell hashes still match the restoration
checkpoint. The new immutable records are in its
`reconstructed-runtime-v1/` subdirectory. This is repeat evidence for one
lookup contract, not additional unique features.

The final painting-led Blender candidate index is
`docs/verification-logs/card-reconstruction/native-candidate-set-v1.json`.
It binds all eight exact sources and 51 inspected current-model native views,
while keeping visual limitations distinct from technical motion/source
checks. Whole-town placement has a separate 168-check/eight-capture report.
The separate post-installation construction/save/reload gate has now passed
**1,506 recorded assertions, zero failures and exit 0**, with eight actual
purchases and **15 inspected native captures at 1440 × 900**. It constructed
the six common buildings through the real interface, then used an actual
saved chronicle to test the two mutually exclusive riverside branches.
Unchanged prices, prerequisites, daily limits, blocked transactions, exact
saved-state/model restoration and actual town hover/work/rest/re-hover were
verified against the frozen runtime sources. Every original painting retained
its exact atlas/crop and identical interior pixels through card hover; no
live viewport was substituted.

Evidence is preserved under
`docs/verification-logs/card-reconstruction/runtime-gameplay-attempt03/`,
including the raw report/log, source snapshots, saved branch bytes and all
15 captures. The populated Granary and Oath Hall views explicitly use a
funded QA fixture. The log has no script, resource or leak diagnostic, only
the test display's unsupported V-Sync warning. Earlier harness-navigation
and time-budget attempts remain separately recorded; they are not added to
the passing count. This bounded integration result does not establish
campaign earnings, performance, other resolutions or final production art.
No generated image, model render or live 3D viewport replaces these cards.
