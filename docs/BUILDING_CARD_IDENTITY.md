# Painted cards govern building design

## Authoritative reference and present status

The original painted building cards are the visual authority. **Keep those paintings in the interface; rebuild the Blender buildings to match them.** A render of a different building cannot replace the illustration to manufacture an identity match. This direction supersedes the earlier model-first card-render contract.

The locked source is `assets/ui/manuscript/buildings.png`: **1774 × 887 RGB**, a four-column, two-row sheet. Its SHA-256 is:

`f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be`

This file remains byte-identical to `Draconia/assets/ui/manuscript/buildings.png` in the frozen `Draconia-0.2-Godot-Project.zip`. It was never overwritten. The subsequent runtime lookup redirected its eight cells to rendered model PNGs; the current restoration removes that redirection.

The eight installed Blender buildings have now been reconstructed against the paintings and **reviewed for development integration**. Their silhouettes, materials, mechanisms and town placement received the bounded reviews recorded below. They are not final production art: `productionAccepted` remains false, and the original paintings remain unchanged. The superseded eight model designs and their source-identity, animation, material and lifetime checks are preserved as historical evidence for those tested versions. A technical match never establishes user approval of an art direction.

## Exact card mapping

The atlas uses **443.5 × 443.5** proportional cells. Preserve the fractional coordinates; integer assumptions shift later cells. The IDs below remain the gameplay/save IDs.

| ID | Display name | Atlas origin `(x, y)` | Size |
| --- | --- | --- | --- |
| `granary` | Granary | `(0, 0)` | `443.5 × 443.5` |
| `barracks` | Training Yard | `(443.5, 0)` | `443.5 × 443.5` |
| `market` | Market | `(887, 0)` | `443.5 × 443.5` |
| `smithy` | Smithy | `(1330.5, 0)` | `443.5 × 443.5` |
| `shrine` | Oath Hall | `(0, 443.5)` | `443.5 × 443.5` |
| `palisade` | Palisade | `(443.5, 443.5)` | `443.5 × 443.5` |
| `wharf` | Wharf | `(887, 443.5)` | `443.5 × 443.5` |
| `water_gate` | Water Gate | `(1330.5, 443.5)` | `443.5 × 443.5` |

`game/redesign/manuscript_art.gd::building(id)` returns the corresponding clipped `AtlasTexture`; unknown IDs return null. `BuildingCardButton` resolves that same painting by ID. The painting remains the face during hover, focus, press, selection and completed/unavailable states. The existing native button may highlight its frame and show a badge or status caption. It must not substitute a 3D viewport, rendered PNG, re-illustration or a differently shaped building.

`BuildingVisuals.definition(id)` exposes the same atlas path, locked hash, cell index and fractional region. Its `cardAuthority` is `original_painted_atlas`, and `cardRequiresModelProof` is false. `BuildingVisuals.card_path(id)` returns the atlas path; `card_texture(id)` returns the same cached painting as `ManuscriptArt.building(id)`. A scene path remains available independently for the constructed world model. The public status is `painted_card_authoritative_reconstruction_integrated`, with `modelStatus: reviewed_for_development_integration` and `productionAccepted: false`. These fields describe the reviewed development revision; they cannot gate a valid painting.

An obsolete rendered-card fingerprint cannot disable a valid painted card. Availability, costs, prerequisites, purchase effects and mutually exclusive plots come only from `RealmRules`. Card inspection spends no resources and advances no time.

## Price and rule boundary

The `RealmRules.BUILDINGS` block is byte-identical to the 0.2 checkpoint: 3,164 UTF-8 bytes, SHA-256 `792fe16f40ea6fa279702e57405db8c6052229747d824679d33f9044b580feff`. The restoration changes no gameplay definition.

| Building | Gold | Timber | Ore | Prerequisite |
| --- | ---: | ---: | ---: | --- |
| Granary | 600 | 5 | 0 | None |
| Training Yard | 800 | 4 | 4 | None |
| Market | 900 | 5 | 2 | Granary |
| Smithy | 1000 | 3 | 6 | Training Yard |
| Oath Hall | 750 | 2 | 3 | Granary |
| Palisade | 650 | 8 | 2 | None |
| Wharf | 900 | 6 | 3 | Market |
| Water Gate | 1100 | 4 | 6 | Palisade |

Wharf and Water Gate still compete for the same riverside plot. One town work may be completed per day, without advancing a watch. Descriptions and mechanical effects remain in the authoritative rules module rather than being copied into the art registry.

## Blender acceptance: painting to constructed building

Each building needs a side-by-side native review against its original cell at a comparable angle and readable scale. The painting stays unchanged throughout the review.

1. **Silhouette and massing:** match the roof shapes and pitch, relative height/width, tower count, wall enclosure, footprint and large projecting elements. Do not replace a round turret with a square tower, an enclosed training yard with an open frame, or the illustrated gate with another plan.
2. **Visible construction:** match the placement and character of doors, stairs, platforms, arches, rails, braces, chimneys, stalls, canopies and mechanisms. Trace their physical connections and check that access paths work.
3. **Distinctive detail:** retain the painted building's identifiable heraldry, carving, trim, stock, sacks, grain bundles, tools, cargo and fittings where visible. Detail must serve the reference instead of adding unrelated decoration.
4. **Material and color:** preserve the illustrated red-clay roofs, timber, masonry, cloth and metal relationships. Photographic texture detail must support these identities. It must not erase the source palette or turn the painting into a different visual design.
5. **Context:** show how the Wharf meets the water and how the Water Gate spans its water opening. Distinguish environmental context from asset geometry, but do not use context to excuse a different building silhouette.
6. **Hidden surfaces:** complete unseen backs and interiors consistently with the visible construction. These are authored interpretations and must be labelled as such; the single painting does not prove unseen geometry.
7. **Animation:** author hinges and work cycles in Blender. Rest must return to the reviewed painted design; motion must preserve connected mechanisms and avoid collisions. Native checks must cover actual pointer-triggered town motion and a complete return to rest.
8. **Integration:** construct the accepted source through the existing factory and saved gameplay ID. Confirm collision/picking, plot placement, scale, visibility and the actual purchase transaction. Verify that no town instance silently swaps geometry or material after purchase.

The painting is a design target, not a request to fake three-dimensional correspondence with a flat billboard. The constructed town building remains a real Blender-authored 3D scene. Its authored world hover animation remains enabled. Card hover is a manuscript-interface interaction and retains the original picture.

## Current and historical evidence

The original painting-restoration checkpoint passed `tests/render_painted_building_cards.gd`: **218 checks, zero failures, exit 0**, with seven actual native captures at **1440 × 900**. It used actual GUI mouse input, the original atlas hash and exact eight-cell mapping. Every card retained identical picture-interior pixels before, during and after hover, and the exact original `AtlasTexture` after a click. No card preview viewport was created.

That checkpoint's actual Granary purchase matched the authoritative `RealmRules` transaction: **600 gold and 5 timber**, charged once, with no watch advancement and the existing one-building-per-day limit preserved. Its separate world hover animation started, advanced and returned to rest. That sample established the preserved mechanism only; the then-installed Granary geometry was rejected and has since been replaced. All seven captures were visually inspected. Its native log contains no script, resource or texture-leak diagnostic; it contains the known unsupported V-Sync warning from the test display.

The restoration evidence is recorded separately under `docs/verification-logs/painted-building-cards/`: raw report and log, process exit, seven captures, tested source snapshots and a bounded visual review. Do not add its assertions to prior suite totals or present old 3D-card results as new painting acceptance. This gate covers the restored interface and one real purchase; it does not certify new 3D art, every construction outcome, other resolutions or performance.

The separate public-API regression `tests/test_painted_building_api.gd` passed **104 checks in an isolated project with no 3D models, rendered-card PNGs or old render manifest**, and **95 checks in the full project**. Both exited 0 without engine warnings or errors and produced the same eight distinct cell-pixel hashes. It verifies the registered IDs, original atlas/hash, exact fractional regions, shared painting textures, invalid-ID rejection and independence from model-render provenance. These are overlapping runs of one API contract, not 199 unique features or a new visual acceptance gate. Reports, tested source snapshots and logs are in `docs/verification-logs/painted-building-public-api/`.

After runtime reconstruction promotion, the same two API variants were rerun against the updated development-status metadata: **104/0 and 95/0, both exit 0**, again with no engine warnings or errors. Their eight pixel hashes match each other and the original restoration checkpoint. The new records are in `docs/verification-logs/painted-building-public-api/reconstructed-runtime-v1/`; earlier reports remain unchanged. This repeat verifies that the new model status still cannot make paintings depend on models or historical render proof.

### Painting-led reconstructed revision

`docs/verification-logs/card-reconstruction/native-candidate-set-v1.json` binds the final eight candidate GLBs, packed Blender sources, authoring manifests, normally imported native rest signatures and independent review records. Its SHA-256 is `99dd463ff65e8f8af30794adf5780205c682b95439c13dfe36c05c3519526a5e`. The index preserves the pre-promotion state; its `runtimePromoted: false` records when it was written and must not be rewritten to simulate a later approval.

The final candidate review contains **51 inspected current-model native captures**: six views for each building and three additional elevated comparisons. Normal editor imports resolved the raw-import texture-sampling problem; the raw failed review remains preserved. Actual mouse-driven work cycles, exact rigid/morph rest and unchanged native geometry/material data were checked separately from visual judgment. Source-author 91-frame collision sweeps have their own bounded records. The report groups overlap and must not be summed into a count of unique game features.

The integrated town placement derives from `town-layout-attempt03/`, which recorded **168 checks, zero failures and eight captures** against the final model bytes. It addresses entrances, roads, the Wharf bank and the Water Gate's receiving water. The production adapter retains the factory, picking and authored-motion interfaces. Its technical placement result is not a claim of final art, exhaustive collision safety or performance certification.

Remaining visible limitations are recorded in each independent review: carving, heraldry, cloth, stock and masonry are less rich than the paintings; some backs and hidden mechanisms are authored interpretations; fire and water effects remain development art.

The post-installation `tests/render_reconstructed_town.gd` gate passed **1,506 recorded assertions, zero failures and exit 0**, with **eight real purchases and 15 inspected native captures at 1440 × 900**. It used actual mouse movement, wheel navigation and button input through `GameShell`. The six common buildings were constructed first; a real saved chronicle then provided the two legal branches for Wharf and Water Gate. Each purchase matched the complete authoritative realm transaction and its unchanged explicit price. The gate also verified prerequisite, duplicate, daily-limit and exclusive-choice rejection; normal dawn changes; actual menu save/reload; the exact restored model set; and release of the replaced town scene.

All eight cards retained the original atlas, fractional crop and identical picture-interior pixels before, during and after hover. All eight constructed scenes matched the independently reviewed runtime GLB and native geometry/material/rest signatures. Actual world-pointer hover started the authored three-second work cycle, completed to exact rigid/morph rest and worked again on re-entry, without changing the realm or substituting the painted card. The tested runtime sources and model bytes stayed frozen throughout. The native log contains only the test display's known unsupported V-Sync warning, with no script, resource or leak diagnostic.

The complete report, log, exit code, source snapshots, exact saved branches, 15 captures and independent visual review are preserved in `docs/verification-logs/card-reconstruction/runtime-gameplay-attempt03/`. The report SHA-256 is `bc1d99deba61545f8e22d5402ebcb82e3c7b9188a8c2c1845c607f7a82c124a3`; the native log SHA-256 is `d0131bca5b7d630d5adbdfacd667a839c8d9e1c82f57e2ffc568df02cee93c70`. Captures 08 and 13 show a populated town with the selected Granary or Oath Hall painting and its constructed model together. Every filename and the report identify the controlled funded QA fixture. This is not evidence of campaign-earned resources, performance, every resolution or final production art. The assertion count includes repeated checks across UI states and saved branches; it is not a count of unique features.

Earlier attempts remain intact. Attempt 01 exposed a harness navigation error: a sidebar control was inside the window but outside its scroll clip. The corrected route uses actual wheel input and native GUI hit-testing. Attempt 02 was stopped after approximately 718.57 seconds because its fixed 900-second wall limit could not cover the remaining software-rendered sequence; it produced no complete report and is neither a passing gate nor a newly observed product failure. The successful attempt retained the same assertion semantics and authored animation timings, removed redundant settling frames in favor of concrete GUI readiness, and ran with a 2,400-second bound. No gameplay or asset change was needed for those harness corrections.

Historical records remain intact:

- `docs/screenshots/manuscript-presentation/Draconia-Construction-Folio.png` shows the earlier actual 1440 × 900 Town Works interface with the paintings. SHA-256: `38d5c0074c6850624de4d98f1b17f87a665223807f4d7a20979509b0f7ee0ec1`.
- `docs/verification-logs/building-cards/pbr-animated-v1/` records the old 83-check model-to-render identity gate. It proves those particular renders came from those particular model sources, **not** that the models matched the painting.
- `docs/verification-logs/building-hover/pbr-animated-v1/` records the old 261-check / 18-capture town-and-3D-card interaction gate. Its 3D card substitution is superseded. Its frozen logs, source snapshots and mechanism observations are not rewritten.
- `assets/ui/buildings/ashen_crown/` and its manifest retain the superseded rendered PNG outputs for provenance. They are no longer runtime building-card artwork.
- `BuildingCardStudio`, the render builder and the old hover harness remain historical/diagnostic tools. Do not run them as the current painted-card acceptance gate or use their outputs to replace `buildings.png`. A small legacy introspection method keeps the old harness parseable; it has no role in painting display, availability or input.
- `BuildingVisuals.CARD_ROOT`, `MANIFEST_PATH`, `historical_render_fingerprint` and `record_matches_source` describe only that preserved model-to-render provenance. The deprecated `source_fingerprint` alias is retained for old diagnostic tools. None of these methods gates or loads current painted cards, and their records explicitly do not establish art acceptance.

Run the original restoration GUI check with isolated data, or use the reconstruction integration harness after installing the reviewed runtime models. For the latter, choose a fresh attempt directory:

```sh
env XDG_DATA_HOME=/tmp/draconia-reconstructed-town/example-attempt/data \
    XDG_CONFIG_HOME=/tmp/draconia-reconstructed-town/example-attempt/config \
    XDG_CACHE_HOME=/tmp/draconia-reconstructed-town/example-attempt/cache \
    /absolute/path/to/godot --path . \
    --rendering-method gl_compatibility --audio-driver Dummy \
    --script res://tests/render_reconstructed_town.gd -- \
    --out=/tmp/draconia-reconstructed-town/example-attempt
```

The native renderer and the isolated user-data prefix are required. The new harness refuses stale model bytes and an existing report, uses an explicitly funded QA realm, and never uses or deletes a player's saves. It constructs six common buildings, saves that valid state, then buys each exclusive riverside choice on a separate saved branch. This is not evidence of campaign-earned resources. Further geometry, material, card or source changes need their own recorded visual review; a passing source hash alone is not an art-acceptance decision.
