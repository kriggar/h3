# Draconia — painted-card Blender workshop

This is the editable art workshop for eight **current reconstruction candidates**. It is not a playable game build or a claim of production-ready art. The separate Draconia project supplies the game, town scene and native review harness.

The unchanged original painted cards are the design authority. Reconstruct their architecture in Blender; do not replace them with model renders, alter them to excuse a mismatch, or project them onto substitute geometry.

## Open the work

Extract **every numbered Workshop ZIP into the same directory**. Each is an ordinary ZIP, not a split-volume archive. Their complementary contents merge under **Draconia/**, preserving the paths used by the full project. A part can be inspected independently, but all parts are required for the complete rebuild inputs. Each ZIP is strictly smaller than 500,000,000 bytes.

Open a packed scene in **Blender 4.5.14 LTS**:

| Building | Editable scene under Draconia/ | Internal ID |
| --- | --- | --- |
| Granary | assets/staging/card-reconstruction/granary/granary.blend | granary |
| Training Yard | assets/staging/card-reconstruction/barracks/barracks.blend | barracks |
| Market | assets/staging/card-reconstruction/market/market.blend | market |
| Smithy | assets/staging/card-reconstruction/smithy/smithy.blend | smithy |
| Secular Oath Hall | assets/staging/card-reconstruction/shrine/shrine.blend | shrine |
| Palisade | assets/staging/card-reconstruction/palisade/palisade.blend | palisade |
| Wharf | assets/staging/card-reconstruction/wharf/wharf.blend | wharf |
| Water Gate | assets/staging/card-reconstruction/water_gate/water_gate.blend | water_gate |

Each scene has its corresponding embedded GLB, original materials and UVs, local moving parts, authored clips, actual Blender preview, and source-bound manifest. Blender uses metres, Z up and front −Y. Export maps this to Godot/glTF Y up and front +Z.

The authored **hover** cycle lasts three seconds at 30 fps, frames 1–91. **RESET** specifies rest; the final hover frame returns to the initial pose. Only the purposeful parts move: doors, supported cloth, bellows, cargo or gate machinery. This is authored motion, not worker AI or a physical construction simulation.

Use a working copy before editing or regenerating. The authoring entry points deliberately overwrite their own staged candidate files. They never promote a model into the game's runtime directory.

## Painted reference

**assets/ui/manuscript/buildings.png** is the original 1774 × 887, four-column, two-row atlas. Its exact SHA-256 is:

~~~text
f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be
~~~

Read its cells left to right: Granary, Training Yard, Market, Smithy; then Oath Hall, Palisade, Wharf, Water Gate. The fractional cell size is 443.5 × 443.5 pixels. Keep the full original image intact. The export helper refuses to proceed if its hash changes.

The drawing specifies visible silhouette, materials, architecture and landmarks. Its illustrative perspective is not a surveyed dimensional plan; rear walls and unseen internal supports are authored interpretations. That limitation does not excuse changing a round turret into a square one, substituting a different banner or omitting the depicted boat.

## Regenerate a candidate

From the extracted **Draconia/** directory:

~~~bash
blender --background --factory-startup --disable-autoexec --threads 4 --python-exit-code 1 --python assets/models/source/towns/card_reconstruction/granary.py
~~~

Substitute another building's internal ID. The current scripts construct real mesh geometry, assign the retained PBR maps, author local motion, export GLB, save the packed Blender scene and render a review image. No network download is required. Keep **--python-exit-code 1**: Blender can otherwise print a Python exception and still return exit code zero.

The exact transitive source versions of **common.py**, **palette.py**, **ornament.py** and **refinement.py** are retained. The first three helpers stay independent of later per-building changes. Importing the shared helper does not clear a scene or start an export; a building explicitly initializes its own authoring scene.

Two linen derivatives are intentionally distinct:

- The existing Mara neutral-linen image supplies the base for several canvas, rope and dyed-cloth materials. Its preparation script, provenance and **complete original input set** are retained under assets/models/source/characters/. The script also processes other character materials; those inputs are needed to run the unchanged preparation script.
- The brighter Granary sack image is a separate building bake under assets/models/source/towns/card_reconstruction/prepared/. Its preparation JSON records the original photograph, measured gain, color-space treatment, authored variation, output hash and source-script hash. Run **prepare_sack_linen.py** with Blender if regenerating that derivative.

The original source images and painted cards are not changed by either material preparation. Blender scenes pack the images they consume. GLBs embed their buffers and images; the archive verifier checks the actual container rather than assuming that a GLB suffix guarantees self-containment.

## Verification and preserved evidence

**workshop-inventory.json** at the extracted project root records every archived input's size and SHA-256, the eight candidate hashes, GLB dependency checks, current matching source-mechanics reports, and the selected native evidence paths. **workshop-receipt.json**, supplied beside the ZIPs, records the finished ZIP sizes/hashes and the actual Blender packaging audit.

The packaging audit:

1. Checks candidate manifests against the exact source, scene, GLB and preview bytes.
2. Reads each GLB's JSON and BIN chunks, validates buffer/image ranges, rejects external model dependencies, and checks the hover/RESET contract.
3. Requires a successful bounded source-mechanics report bound to each current scene and GLB.
   It also checks the selected final native index against all eight current artifact hashes, its report/review hashes and the exact inspected captures. Overlapping report counts are not added together as unique tests.
4. Reads every archived member to verify its SHA-256, size and ZIP CRC.
5. Extracts the complete workshop into a temporary directory and checks every extracted member again.
6. Opens all eight extracted Blender scenes without auto-execution, verifies that used file images are packed and have preserved source bytes, and rejects linked external Blender libraries.
7. Executes each actual construction entry point using only the extracted inputs. The expensive export/render call is replaced **only inside this disposable dependency check**. This demonstrates construction-input closure; it is not a fresh render, byte-identical re-export, renewed animation acceptance or visual approval.
8. Rechecks the original inputs before publishing the finished archive names. A changing source or failed check leaves an explicitly unfinished attempt rather than a success receipt.

Current source inspectors live beside the authoring modules. Their original reports remain intact. Some reports and manifests intentionally retain the original machine's absolute provenance paths. The package verifier resolves their project-relative suffixes without editing the evidence. To rerun those source inspectors at a new location, regenerate the candidate in a working copy first; regeneration writes local manifest paths.

Specific historical comparison inputs are included because current inspectors use them:

| Retained input | Purpose |
| --- | --- |
| Training Yard iterations/native-review-v2/barracks.glb and its manifest | Verify preservation of the exported door geometry, transforms and animation curves |
| Smithy iterations/03/manifest.json | Compare the forge correction's overall bounds |
| Smithy iterations/04/smithy.glb and its manifest | Prove that the later roof pass changed only the intended material factors |
| Wharf iterations/03/wharf.glb and its manifest | The equivalent roof-only byte comparison |

These old inputs are historical references, not the current candidate models. Complete redundant iteration trees, automatic Blender backups, generated import caches and duplicate downloaded ZIPs are omitted. The extracted original material maps and their source/archive provenance remain.

The two included native comparison scripts require the corresponding **full Draconia project** and its import fixtures. They are preserved for review and merging; this Blender workshop deliberately does not duplicate all gameplay code, runtime assets or the Godot engine.

## Limits still requiring review

Technical checks are separate from comparing the actual model with its painting. The manifest and selected native report describe the exact tested revision; a prior report does not automatically approve a later model. Current candidates are not declared production accepted.

The remaining gates include whole-town placement, road and doorway access, river and bank integration, camera readability, final material/detail quality, and target-device draw-call/LOD budgets. The Water Gate's origin is a bank datum; its negative water/channel extent must not be used as a whole-object grounding point. Town terrain and the shared river must accommodate the authored cascade. Finite source collision checks exclude narrowly identified fitted hinge attachments; they are not a physical bearing simulation.

The models have detailed original geometry, but small props and cloth remain authored game assets. PBR, exact hashes and large check totals do not by themselves establish photorealism or studio readiness.

## Licensing and provenance

Retain **LICENSE.txt**, **ASSET_CREDITS.md** and **assets/licenses/**. The MIT source-code grant does not relabel downloaded artwork. The architectural PBR maps are retained creator-supplied **CC0** assets from Poly Haven and ambientCG, with exact metadata, source URLs, notices and hashes. The material derivatives retain their source provenance.

The broader project credits and license folder also describe assets not used by this narrow workshop. They are preserved as notices, not as a claim that every referenced character, sound or font is included here. The original painted atlas and new Blender construction are original Draconia project artwork; no proprietary Heroes III art is included.

For this workshop, the current authority and review contract are **docs/CARD_RECONSTRUCTION.md** and this README. Any retained description of the earlier model-to-card rendering workflow is historical; it must not override the original paintings.

## Repackage a frozen working copy

Create a plan without writing an archive:

~~~bash
python tools/package_card_workshop.py --output /absolute/path/outside/Draconia/workshop-plan --evidence docs/verification-logs/card-reconstruction/CURRENT_SOURCE_REPORTS
~~~

After all eight owners' sources are frozen, use a **fresh** output directory, supply the exact current source/native evidence directories with repeated **--evidence** options, and add:

~~~text
--build --blender /absolute/path/to/blender
~~~

Include the final **native-candidate-set** JSON index and every report/capture directory it references among those evidence options. The script refuses to build if any candidate lacks a matching successful current source report or if the native index, reports or inspected captures refer to different bytes. Every finished archive stays below the strict size cap. Extraction of all numbered parts restores the same **Draconia/...** paths used by the project and the workshop sources.
