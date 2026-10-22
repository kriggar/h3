# Draconia — Oaths of the Carpathians

## Download and play in Godot

1. On this repository, select **Code → Download ZIP**.
2. Extract the **entire ZIP** into a writable folder on your computer.
3. Open the standard **Godot 4.7.2** editor. In the Project Manager, select
   **Import** and choose the extracted `project.godot` file, or drag that file
   into the Project Manager.
4. Open the project and let the first asset import finish.
5. Press **F5** or the **Run Project** button to play.

The repository contains the complete Godot source and runtime assets as
ordinary files. **Git, Git LFS, Blender, export templates, and additional
project ZIP parts are not required to play in the editor.** The standard
editor is sufficient; the .NET edition is unnecessary. Godot creates its
local `.godot` import cache during the first import, which can take a few
minutes. Keep the extracted folder writable and allow additional free space
for that cache.

**v0.3.1-card-reconstruction development source — playable slice.** An original native Godot strategy/action RPG built around exactly one chosen hero for an entire campaign. The current playable character is **Mara Veyne, a Hearthborn Oathwarden**. She develops through earned levels and equipment, builds Dawnreach, and enters solo expeditions while her companies remain outside.

**Current art direction, 22 October 2026:** the original eight painted building cards define the architecture. All eight Blender reconstructions are now installed from their individually reviewed source files, and the town's foundations, roads and riverside installations have been adapted around them. The original paintings remain unchanged at rest, hover and press. The previous model-render cards and mismatched buildings are historical work. This is development integration; production art and user acceptance remain open. See the [reconstruction contract](docs/CARD_RECONSTRUCTION.md) and [building-by-building review](docs/BUILDING_RECONSTRUCTION_REVIEW.md).

This is a working development slice, not a complete game matching Heroes III's breadth or production quality. The full design contains nine factions, twenty fixed classes, eight races and 156 authored hero concepts; only Mara is presently playable. Personal signatures, racial packages, class-resource traits, talent trees and the remaining protagonists are design work, not active bonuses hidden in this build.

The immutable **v0.2 desktop and source archives** predate the attributes, class enforcement and hunt loop described here. A new export requires a new recorded build; this page does not relabel those older executables as v0.3.

## Run the current source

Open `project.godot` in the standard **Godot 4.7.2** editor, allow asset import to finish, then press **F5**. The configured starting scene is `redesign.tscn`. GDScript is used; the .NET editor is unnecessary. No Heroes III installation, commercial game executable or original game data is required.

```bash
godot --editor --path .
godot --path .
```

For a packaged desktop checkpoint, extract its entire archive and launch `Draconia.exe` on Windows or `Draconia.x86_64` on Linux. Read that archive's version-specific notes. Windows packages are cross-exported; native Windows execution has not been verified in this environment. The exact Linux startup and normal-exit coverage belongs to each package's recorded export evidence.

## What works now

- **One fixed identity and an enforced class kit.** Mara uses Cleave and Ward, plus basic attack, guard and dodge. Ember belongs to a Pyromancer fixture and Living Roots to a Druid fixture; they are not selectable Mara spells. The rules reject off-class casts, including queued inputs, independently of the hotbar.
- **Earned levels 1–30 and four useful attributes.** Start with three points and earn three per level, for ninety total. Might increases Attack, Finesse movement speed, Vitality maximum Health, and Spirit maximum Focus and finite Ward capacity. The Character folio supports a draft, full derived-stat preview, atomic Apply, and a bounded safe-town reset. Allocation never heals or refills Focus.
- **A dedicated persistent 3D town.** Dawnreach offers eight building definitions, including the exclusive Wharf/Water Gate river plot. A purchased building appears in its saved plot immediately and activates its actual service. The reconstructed architecture follows the original cards; terrain cores, entrance approaches, road coverage, retaining-wall openings and water levels accommodate the actual models. One construction is allowed per town/day; buying itself consumes no watches.
- **The once-only Bellworn Vault story expedition.** Fight real actors, navigate matching visible collision, collect physical rewards, choose one registered item reward and extract. Enemy wounds, corpses and unclaimed story drops persist across legal retreat and return.
- **A repeatable hunt board.** Choose from The Briar Kennels, The Ashen Watch Cellar and Moonfang Underpass. Each registers its tier, pack, item rolls, gold and XP before entry. Successful extraction refreshes three offers; an unfinished contract keeps its actual enemies and claims. These are three formations in the same current vault arena, not three new dungeon environments.
- **Real loot, sets, sockets and a Market sale route.** Sixteen item definitions, eleven equipment slots, one five-piece set definition and two original ordered rune recipes. Hunts can award the remaining Bellworn pieces, normal socket bases, runes, a gem and existing accessories. A built friendly Market sells finite crafting supplies and buys a selected, owned, unequipped item at its stated fixed value.
- **A working manuscript interface and character folio.** Town works, original painted building cards, painted resources and commands, class/race/trait status, Character and Inventory tabs, actual equipment/set comparisons, a live 3D model with orbit/zoom, oath terms, expedition previews, forfeit warnings and sale confirmations. Mara has a development PBR material pass. Dawnreach uses eight reviewed Blender reconstructions with local working mechanisms; final building detail, environment and character art remain unfinished.
- **Persistent consequences and live saves.** Four watches/day, dawn accounting, two finite oaths, paid rival mustering/frontier claims, retained wounds and paid defeat recovery. Save/load retains the live action state, derived equipment, attribute allocation, unfinished hunt and once-only reward ledgers. Solo expeditions leave the waiting companies unchanged.

## Start here

1. Open **Character** or press **C**. Draft the initial three attribute points, inspect the actual before/after statistics, then Apply. Mara remains an Oathwarden whatever attributes you choose.
2. Open **Browse Town Works**, select the Granary and construct it. It appears in Dawnreach and enables the relevant prerequisite chain.
3. For the story route, accept **Silence the Bell** in **Oaths**, then open **Expedition**, read the chronicle expedition and enter the Bellworn Vault. Only Mara enters. Collect the four registered rewards and use the entrance seal to extract.
4. For repeatable progression, choose an available **hunt** on the expedition board. Entry and each re-entry cost two watches. Kill the registered pack, physically collect its drops and return. The next board appears only after a completed extraction. Uncollected hunt spoils are forfeited on completion; the warning lets you go back for them.
5. Open **Inventory** or press **I** to compare and equip earned items. The Vowkeeper sword and Bellworn Cowl have fitted, textured 3D visuals; every defined armor item does not yet have its final visible mesh.
6. On a later day, construct the Market after the Granary. Buy finite ordinary crafting supplies or sell an unequipped item to make space. Cinder then Stone in a Notched Ironblade makes Hearthguard; Cinder then Gale makes Windscar. Selling a socketed item also removes its inserted materials, as shown by the confirmation.

## Controls

| Context | Control |
| --- | --- |
| Town works, hunt board and panels | Left-click the actual controls |
| Character / Inventory | C / I |
| Oath ledger / rest | J / R |
| Live hero model | Drag to orbit; wheel to zoom |
| Dungeon movement, target, loot or exit | Left-click the relevant ground or object |
| Mara's class skills | 1 casts Cleave; 2 casts Ward |
| Selected legal skill | Right-click toward the cursor |
| Directional guard / dodge | G / Shift |
| Tactical pause / resume | Space |
| Dungeon camera distance | Mouse wheel |
| Town camera | Side arrows; wheel over the town |
| Menu / back | Esc |
| Manual save | Ctrl+S |

Loot and exit interactions approach a legal interaction distance. A spell or equipment item never grants another class's skill permission. Town purchases, allocation and sales do not advance watches; resting advances one watch. Next Dawn stops at dawn or an intervening oath deadline. Time spent reading, comparing equipment or pausing action does not silently advance the realm.

## Progress and saves

The slice uses `draconia-action-save.json` and `draconia-action-autosave.json` in Godot's application-data directory. A valid autosave restores on startup. The menu provides manual save/load and New Chronicle. Starting again replaces the active autosave while retaining the separate manual save.

Closing the window or choosing **Menu → Save & Quit** records the current autosave and releases audio before exiting. Gameplay stays frozen during that operation. If writing or flushing the save fails, Draconia remains open with an error and retains the previous save; the separate manual save is unchanged. Forced termination by the operating system cannot provide this orderly save-and-exit behavior.

The current action ruleset has **save version 4**. Genuine earlier action saves from versions 1–3 migrate with their earned inventory and claims retained. An old pending encounter remains the exact registered transaction; migration does not reroll rewards, heal Mara or replace a committed snapshot. Already committed legacy effects can finish, while new illegal class casts are rejected. This action format is separate from the archived hex campaign's saves. Invalid state is rejected without replacing the active game. Local save validation is an integrity/compatibility check, not a cryptographic anti-cheat guarantee.

## Verification and limits

[VERIFICATION.md](docs/VERIFICATION.md) records the actual run boundaries. Six rules suites pass **1,390 checks, zero failures**: hunts 458, realm 247, progression 277, identity 134, items 73, action 201. The separate native hunt/sale route passes **181 checks**, with twelve inspected captures at 1440×900, 1280×800 and 960×640. It uses real GUI input, legal combat commands, earned levels, physical loot, live save/resume, actual sale and explicit spoils forfeiture. Class-specific spell presentation has separate 43-unit/55-native-check evidence. The later integrated character-folio/town route passes sixty native checks with eleven captures; its saved equipment and populated panorama are clearly labeled fixtures. Its report preserves the later label-only “Additional Ward” correction and portable fixture-path change. These counts are not completion percentages.

The repeated-contract rules route earned level 30 through forty-six real completions and tested another run at the cap. This proves a bounded usable progression loop; it does not establish an enjoyable full campaign, broad dungeon variety or production balance. Automated native capture on Mesa software rendering is not a frame-rate benchmark, complete human playthrough or native Windows test. Building reconstruction, placement and actual construction have separate revision-bound evidence; earlier tests are not silently treated as a run of the new geometry. Production art, target-hardware performance and full continuous motion review remain open.

### Current development art

Mara's material revision contains four runtime GLBs and fourteen shared PBR maps, backed by a packed editable Blender snapshot of approximately 60.87 MB. The base character has 41,590 triangles, fifty-three bones and twelve retained clips. Its actual imported-scene review passed **245 checks with ten captures**. The two earned equipment modules separately pass eighteen adapter checks. These are accepted development assets, with remaining neckline, cowl-edge, deformation, hair, boot-map and LOD work recorded in [CHARACTER_MATERIALS.md](docs/CHARACTER_MATERIALS.md).

Dawnreach's eight current reconstructed scenes total **408,644 triangles** across the complete asset set, with three-second local Hover clips and authored RESET poses. They retain individual packed editable Blender scenes, embedded GLBs, exact source manifests, original painting comparisons and bounded mechanical/native reports. Their characteristic entrances, roofs, towers, heraldry and props were reviewed against the locked atlas. The final staged town passed **168 checks with zero failures and eight inspected captures**, covering the corrected foundations, access and river installations. The separate actual-runtime route passed **1,506 assertions, zero failures, eight purchases and fifteen inspected captures**, including both exclusive river choices and menu save/reload. Its explicitly supplied test funds, unchanged rules, source bindings and bounded scope are recorded in [VERIFICATION.md](docs/VERIFICATION.md).

The old 113,860-triangle set and its **83-check** rendered-card proof, **261-check** hover run and **77-check** town-composition run remain historical evidence of the rejected architectural direction. They are not current visual approval. The new models still need the close-detail refinements recorded in the [review](docs/BUILDING_RECONSTRUCTION_REVIEW.md); the keep, ambient houses, terrain, vegetation, shoreline, lighting and other eight faction environments remain unfinished. The [asset structure inspection](docs/BUILDING_ASSET_BUDGET.md) records cross-building image duplication and Water Gate chain complexity as optimization work, without treating file structure as a measured frame-rate or memory budget.

Six current hero-preview open/render/close cycles pass **25 checks** with zero orphan nodes and the same **448,371,637 retained texture bytes** after every close. The fixed cache is intentionally resident; this is bounded repeated-use evidence, not zero memory usage or a validated target-GPU budget. See the [runtime integration record](docs/verification-logs/character-pbr/runtime-integration.json). The [Raven Hollow review](docs/RAVEN_HOLLOW_REVIEW.md) records the inspected source and the originally implemented interface decisions; item statistics remain authoritative rule data.

A later focused shutdown regression passes **81 checks in eight groups**, including actual Ogg/SpellFeedback ownership, a live dungeon snapshot, repeated and cancelled quit requests, and a real post-open write failure. It fixes the observed audio lifetime and incomplete-save replacement risks. Its lightweight native fixture is separate from the exported application's window/menu exit checks and from audible-output testing; see [audio-lifetime/report.json](docs/verification-logs/audio-lifetime/report.json).

Still outstanding: selectable implementations of the other heroes/classes, racial and personal traits, class talent trees, a complete campaign map and political simulation, field-company battles, defended conquest, sieges, broad enemy/environment content, full armor visuals, target-hardware performance and broad accessibility. No Heroes III parity, bug-free guarantee or complete-game claim is made.

The complete design is [GAME_DESIGN.md](docs/GAME_DESIGN.md), with [HERO_ROSTER.md](docs/HERO_ROSTER.md), [CLASS_DESIGN.md](docs/CLASS_DESIGN.md), and [CREATURE_ROSTER.md](docs/CREATURE_ROSTER.md). The previously generated 82-page PDF predates the corrected card authority and is not the current art contract. Its historical layout review remains in [design-pdf.json](docs/verification-logs/design-pdf.json); a revised document must be rebuilt and reviewed before release.

## Source structure

- `redesign.tscn`, `game/redesign/`: current native town/action implementation.
- `realm_rules.gd`, `hunt_rules.gd`, `item_rules.gd`, `hero_identity.gd`, `action_rules.gd`: authoritative transactions, contracts, items, fixed identity and action rules.
- `data/class_catalog.json`, `data/hero_roster.json`: twenty class definitions and all 156 canonical hero mappings, with explicit design status.
- `tests/test_realm.gd`, `test_hunts.gd`, `test_progression.gd`, `test_hero_identity.gd`, `test_item_rules.gd`, `test_action_rules.gd`: current rules suites.
- `tests/render_hunt_ui.gd`: the current earned native hunt/sale route; earlier and targeted presentation harnesses retain their own scopes.
- `assets/models/mara/`, `assets/models/towns/`, `assets/ui/manuscript/`: model and interface assets with provenance and integration contracts.
- `main.tscn` and other historical `game/` modules: archived earlier campaign/hex prototype, not the configured entry point. Its evidence is under `docs/LEGACY_*`; the later v0.2 action checkpoint is preserved under `docs/V0_2_*`.

This repository contains all files required to import and run the current Godot project. Editable Blender authoring material and historical verification archives are maintained separately; they are optional development records and are not prerequisites for the GitHub download. References to those separate archives in historical documents describe the earlier checkpoint distribution.

## Build and attribution

Matching Godot 4.7.2 export templates are required. Native presets are **Linux** and **Windows Desktop** in `export_presets.cfg`. Exports exclude staging assets, authoring tools, research and test evidence. The historical Web preset is not the delivered native target.

```bash
mkdir -p builds/local/linux builds/local/windows
godot --headless --path . --export-release Linux builds/local/linux/Draconia.x86_64
godot --headless --path . --export-release "Windows Desktop" builds/local/windows/Draconia.exe
```

These commands create new local exports; they do not overwrite or re-certify immutable v0.2 archives. Keep `LICENSE.txt`, `ASSET_CREDITS.md` and `assets/licenses/` with redistributed builds. Original generated Draconia art is recorded separately from downloaded licensed assets. Proprietary reference-game artwork and owned game binaries are excluded.
