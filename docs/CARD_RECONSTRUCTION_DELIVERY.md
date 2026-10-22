# Draconia — painted-card reconstruction checkpoint

**Checkpoint:** `0.3.1-card-reconstruction`

This is an original native Godot 3D development game. Its eight civic buildings
have been reconstructed in Blender toward the original Draconia painted cards.
Those paintings remain unchanged. The runtime now uses the reviewed geometry,
with revised foundations, roads, entrances, river-wall openings and water levels.

This is a playable development slice and an editable art/code handoff. It has
not reached AAA quality or Heroes III's content breadth. The review documents
identify remaining art and implementation work rather than representing design
catalogs as completed gameplay.

## Choose what to open

| Package | Purpose |
| --- | --- |
| Linux native, Part01 and Part02 | Download both ZIPs, extract both into the same parent folder, merge their identical platform directory, then run `sh Start-Draconia.sh` inside it. The helper verifies both binary chunks, reconstructs `Draconia.x86_64`, verifies its full hash, then starts it. |
| Windows native, Part01 and Part02 | Download both ZIPs, extract both into the same parent folder, merge their identical platform directory, then double-click `Start-Draconia.cmd`. The helper reconstructs and verifies `Draconia.exe`. This is a cross-export; both Windows game execution and the Windows helper remain untested on Windows. |
| Godot Project ZIPs, parts 01 and 02 | Both parts are required. Extract both into the same parent folder and merge `Draconia/` to restore the complete editable code, scenes, runtime assets, current design documents and credits. Open `Draconia/project.godot` in standard Godot 4.7.2, allow imports to complete, then press F5. The .NET editor is unnecessary. |
| Card Reconstruction Workshop, parts 01 and 02 | All eight packed editable Blender scenes, authoring scripts, complete texture/preparation dependencies, original paintings and source/native review evidence. Both parts are needed for the complete workshop. |
| Verification ZIPs | Test harnesses, fixtures, actual captures, logs, failed attempts, revision-bound reports and the exact pre-reconstruction runtime backup. These are optional for playing and useful for an implementation review. |

Every downloadable ZIP is individually below 500,000,000 bytes. All are ordinary
ZIP containers, with no `.z01` volumes. The native ZIPs contain two binary chunks
because each verified executable is larger than the download limit. Both parts
for the chosen platform are required before the helper can assemble it. The
Godot, workshop and verification ZIPs contain complete source/evidence files and
need no binary reassembly. Exact sizes and checksums are in the delivery inventory.

The source, workshop and verification archives merge into one `Draconia/`
folder. For the complete editable handoff, extract both workshop parts first,
then both Godot Project ZIPs, then the verification ZIPs. This preserves the most
recent runtime documentation when a source-stage document has the same path.
The standalone native packages have their own platform folders. Their
`START-HERE.md` and this delivery guide provide the two-part setup instructions
for this checkpoint; follow those before the root README's general instruction
to run an extracted executable.

Allow **3 GB of free disk space** for the two native downloads, extracted chunks
and reconstructed executable of your chosen platform. Use a writable local
folder with the filesystem support stated in `START-HERE.md`. Linux assembly
requires a filesystem supporting hard links, such as ext4 or btrfs; FAT/exFAT
does not support this assembly method. These helpers
work locally and make no network request. They refuse to replace an existing
executable whose hash differs from the verified build. If assembly is interrupted
or fails, read the reported reason and the recovery instructions; do not rename
an incomplete chunk into an executable. The Windows helper uses the built-in
PowerShell hash/file utilities without changing execution policy.

To assemble and check without starting the game, use
`sh Start-Draconia.sh --verify-only` on Linux, or
`Start-Draconia.cmd --verify-only` in Windows Command Prompt. After successful
assembly, the verified executable can be launched directly. Keep its credits
and licenses beside it.

No original Heroes III installation or proprietary game data is needed. Keep
the included license and asset-credit files with redistributed packages.

## Play the current slice

The implemented protagonist is **Mara Veyne, a Hearthborn Oathwarden**. Exactly
one hero remains the campaign rule. Mara can develop attributes, build Dawnreach,
enter the Bellworn Vault alone, gather loot, equip items, and take repeatable
hunt contracts. Her class kit is Cleave and Ward, together with basic attack,
guard and dodge.

1. Open Character with **C**, inspect the three starting attribute points, and
   Apply an allocation if desired.
2. Open **Browse Town Works**, choose the Granary and Construct it. Its actual
   building appears immediately. Only one construction is allowed per town per
   day; the purchase itself advances no watches.
3. For the story vault, first accept **Silence the Bell** in **Oaths**, then open
   **Expedition**. Repeatable hunts are also offered on the expedition board.
   Only Mara enters; her companies remain outside. Left-click to move, attack,
   claim drops or use the extraction seal. **1** casts Cleave, **2** casts Ward,
   **G** guards, **Shift** dodges and **Space** toggles tactical pause. Aim
   directional actions toward the cursor.
4. Use **I** to compare and equip loot. Later build the Market after its Granary
   prerequisite. It provides finite crafting supplies and an explicit sale
   confirmation for owned, unequipped items.
5. **Next Dawn** advances realm time to the next dawn or an intervening oath
   deadline. The Wharf and Water Gate are mutually exclusive river-plot choices.
6. Use **Menu → Save & Quit** for an orderly autosave and exit. Manual save/load
   is also available; **Ctrl+S** writes the separate manual save.

The normal game starts with an undeveloped town. The actual-runtime pictures
labelled funded QA use buildings purchased through the real interface with
deliberately supplied test resources. Separate staged-layout and older town
composition pictures use populated presentation fixtures without campaign
purchases. Neither kind represents an earned campaign or the default starting
state; each report identifies which route produced its captures.

The separate Granary and Oath Hall comparison boards show the unchanged card
beside its normally imported 3D reconstruction. Their original candidate-stage
captions are retained. Those exact reviewed GLB files are now installed in the
runtime; production art acceptance remains open. The boards are model-review
views, not screenshots of a campaign purchase.

## Inspect the reconstruction

The fixed visual authority is
`assets/ui/manuscript/buildings.png` (1774 × 887 pixels), SHA-256
`f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be`.

The editable scenes are under
`assets/staging/card-reconstruction/<building>/<building>.blend` after workshop
extraction. They were opened and checked with Blender 4.5.14 LTS from an
independently extracted workshop. The source-stage manifests remain frozen as
candidate records. The installed runtime copies and their separate integration
decision are in `assets/models/towns/ashen_crown/manifest.json`.

Useful project documents:

- `docs/BUILDING_RECONSTRUCTION_REVIEW.md`: per-building correspondence,
  remaining art refinements and the integration boundary.
- `docs/CARD_RECONSTRUCTION.md`: the locked architectural contract.
- `docs/VERIFICATION.md`: actual test scopes and historical boundaries.
- `docs/BUILDING_ASSET_BUDGET.md`: installed scene/texture structure and bounded
  optimization opportunities; this is not a frame-rate or GPU-memory benchmark.
- `docs/GAME_DESIGN.md`: complete current design, with proposed systems clearly
  distinguished from implemented gameplay.
- `ASSET_CREDITS.md`: downloaded asset provenance and project-authored work.

## Verification boundary

The model set has individual source mechanical checks and normally imported
Godot comparisons. The final staged town passed 168 checks with zero failures
and eight inspected captures. The standalone workshop passed archive member,
CRC and hash checks, packed-scene opening, and isolated authoring dependency
checks for all eight constructors. These are distinct forms of evidence and
are not summed into a quality score.

The actual-game construction route passed **1,506 assertions with zero failures,
eight real purchases, fifteen inspected captures and exit 0**. It covers
unchanged prices, prerequisites, daily limits, both exclusive river choices,
original card pixels, exact installed models, local hover/rest/re-hover and
actual menu save/load. The count includes repeated identity and state checks;
it is not a count of unique game features. Earlier failed and partial harness
attempts remain preserved with their original results.

The actual exported Linux executable passed startup, rendering of the normal
undeveloped town, inspected Menu → Save & Quit input, a valid autosave and normal
exit 0. Its embedded resources were checked against the frozen source and
imports. This was an isolated X11/Compatibility run through Mesa software
rendering with Dummy audio. Windows was cross-exported successfully and its
embedded resources passed integrity checks; it has not been run on Windows.
Exact identities and the narrower test boundaries are recorded in the delivery
inventory and current `docs/VERIFICATION.md`. Target-GPU performance, audible
output and a complete human campaign playthrough remain outside this evidence.

Both platforms' actual archived chunks reconstruct to their accepted executable
hashes. The Linux Start helper also passed real extracted-byte assembly in
`--verify-only` mode, identical-output reuse, missing/corrupt-part rejection and
refusal to overwrite a different executable. The game was run separately for
the startup/menu-exit check above. The Windows helper was reviewed but not run.

The larger faction, hero, race and class catalogs are design material. The
current slice has one implemented hero, one capital and a limited dungeon
environment. More detailed building surfaces, the wider environment, additional
playable content, full armor visuals, production animation coverage, balance
and accessibility remain work to complete.
