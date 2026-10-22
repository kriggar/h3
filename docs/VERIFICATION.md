# Development verification — Draconia 0.3.2 hunt regions

**Latest source update:** [0.3.2 hunt locations and field guide](HUNT_REGIONS_V032.md) records the current rules gate and native dungeon review. The older records below retain their original source and asset scope; their totals are not added to the new gate. The 0.3.1 desktop exports remain historical executables.

This page covers `redesign.tscn` and the current `game/redesign/` rules. Evidence is attached to the recorded code/assets, not inferred from a version label. The immutable v0.2 action checkpoint has its own [historical verification](V0_2_VERIFICATION.md); the earlier hex campaign's 1,184 checks remain in [LEGACY_VERIFICATION.md](LEGACY_VERIFICATION.md). Neither historical total is added to the results below.

## Current building-art correction

On 22 October 2026 the user rejected replacing the original painted building cards with renders of the existing models. Eight reconstructed Blender models are now installed from individually reviewed source bytes. The original atlas is unchanged and remains the architectural authority. The historical 83-check model/card identity, 261-check hover and 77-check composition results below retain their exact technical scopes; they are not evidence of the current models or user approval. See [CARD_RECONSTRUCTION.md](CARD_RECONSTRUCTION.md) and the [explicit visual review](BUILDING_RECONSTRUCTION_REVIEW.md).

### Current reconstructed model and layout evidence

The [final candidate index](verification-logs/card-reconstruction/native-candidate-set-v1.json) binds all eight current GLBs, packed Blender scenes, manifests and 51 independently inspected current-model views. The index remains a frozen candidate-stage record after promotion; the [runtime integration record](verification-logs/card-reconstruction/runtime-integration.json) identifies the installed copies and actual runtime gate separately.

| Report | Recorded result | Current scope |
| --- | --- | --- |
| Granary v8 / Oath Hall v7 | 173 checks, zero failures, 12 captures | Final pair through normal Godot import and local work/rest/re-hover; source checks separately cover 91 evaluated Blender frames. |
| Training Yard v4 / Water Gate v5 / Smithy v5 / Wharf v4 | 317 checks, zero failures, 24 captures | These four final models and their actual imported geometry, materials and animation behavior. |
| Market v4 / Palisade v7 / Smithy v4 | 246 checks, zero failures, 18 captures | Market and Palisade records remain current; Smithy v4 is retained history, superseded by the v5 report above. |
| Card-specific elevated comparisons | Separate zero-failure camera reports | Additional architectural views for Market, Training Yard and Wharf; not additional motion coverage. |
| Final staged whole town | 168 checks, zero failures, eight captures | Exact final eight models, flat foundations, terrain-material roads, entrances, river banks/waterline, both exclusive riverside layouts and restored unbuilt state. Populated presentation fixture. |

The reports overlap, include revision-specific siblings, and must not be summed into a whole-game quality score. Source sweeps and camera-only reports are also distinct scopes. The [town handoff](verification-logs/card-reconstruction/town-layout-attempt03/integration-handoff.md) records the exact reviewed adapter into the real `BuildingVisuals` factory. The unchanged source catalog remains 3,164 bytes with SHA-256 `792fe16f40ea6fa279702e57405db8c6052229747d824679d33f9044b580feff`.

Earlier failed source and native attempts are retained. They exposed rail/hinge interference, banner support problems, absent raw-import mipmaps, terrain discontinuities, road triangles cutting slopes and a one-frame receiving-water lag. Later passes address those concrete defects without altering the original painting or rewriting earlier failures.

The actual runtime construction/save/reload gate passed **1,506 assertions, zero failures, eight real purchases, fifteen inspected 1440×900 captures and exit 0**. The [successful report](verification-logs/card-reconstruction/runtime-gameplay-attempt03/report.json) and [native log](verification-logs/card-reconstruction/runtime-gameplay-attempt03/native.log) bind the unchanged original atlas, all eight installed model hashes and seven runtime scripts. The explicitly funded QA realm uses real mouse-wheel/click navigation, costs, prerequisites, the one-per-day limit and unchanged watch accounting. Both exclusive river choices pass actual menu save/load routes; original painting pixels, model identity, hover/rest/re-hover and the restored town are checked. Its only logged warning is unsupported V-Sync on the virtual display. This is one controlled construction route, not earned campaign progression, production art or target-hardware performance acceptance.

Attempt01 is retained as a failed harness route: its click helper missed a control below the ScrollContainer clip. Attempt02 is retained as a partial run, stopped after three successful purchase markers when its fixed time bound proved too short. Attempt03 uses actual GUI hit-testing and wheel navigation for readiness and a sufficient bound; the authored animation cycles, assertions, source files and model bytes stayed unchanged. Earlier failures and partial work are not counted as passing gameplay coverage. The post-integration public card API repeat separately passes **104 isolated checks and 95 real-project checks**, with identical original painting hashes and no warning/error diagnostics, under [reconstructed-runtime-v1](verification-logs/painted-building-public-api/reconstructed-runtime-v1/).

The restored painted-card UI passes **218 native checks, zero failures, exit 0**, with seven inspected 1440×900 captures. It preserves all eight original fractional atlas cells through real hover and click, with identical painting pixels before/during/after hover. A real Granary purchase spends exactly 600 gold and 5 timber once, advances no watch, and keeps the daily construction limit. The purchased world model's existing hover/reset still works. This focused run changes no rules, prices, atlas pixels or runtime GLBs. Its report, source snapshots and captures are in [painted-building-cards](verification-logs/painted-building-cards/review.json). It certifies that earlier restoration route; the reconstructed models have their own current evidence above.

## Current native exports and Linux startup/exit

The `0.3.1-card-reconstruction` checkpoint was imported and exported with the
recorded official Godot 4.7.2 executable. The editor import, Linux release
export and Windows Desktop release cross-export all exited 0 without blocking
diagnostics. The [frozen export report](verification-logs/native-v031-card-reconstruction-attempt01/exports.json)
binds the final integration record, original atlas, eight reconstructed models,
runtime source inventory, import settings and resulting executable bytes.
Every one of the 888 members in each embedded resource pack was checked by MD5
and SHA-256, with source/import bindings checked separately. No runtime input or
previous named build changed during those exports.

| Platform | Executable bytes | Recorded verification |
| --- | ---: | --- |
| Linux x86-64 | 637,845,344 | Actual exported executable started at the default entry, rendered its initial town, opened Menu through inspected mouse input, then used Save & Quit and exited 0 with a valid autosave. |
| Windows x86-64 | 673,498,160 | Successful cross-export and embedded-resource integrity only. Neither the executable nor its distribution launcher has been run on Windows. |

The Linux run used an isolated fresh user-data directory and cold shader cache,
X11, Compatibility rendering through Mesa llvmpipe, and the Dummy audio driver.
It loaded the normal undeveloped starting town, without a test script or forced
quit timer. Both the [startup capture](verification-logs/native-v031-card-reconstruction-attempt01/linux-native-01-startup.png)
and the open-menu capture were visually inspected before their click coordinates
were submitted. Save & Quit returned normally 2.846 seconds after its click;
the retained autosave has a nonempty realm and the expected save schema.

The [actual native log](verification-logs/native-v031-card-reconstruction-attempt01/linux-native-menu-quit.log)
has no script, resource or GPU-leak diagnostic. Its only warning is the virtual
display's unsupported V-Sync setting. The whole 135.285-second process duration
includes waits for human inspection and is not a performance benchmark.

This result certifies exact exported content, Linux startup/render and that
normal menu-exit route. It does not certify an exported full playthrough,
window-manager close, other Linux environments, Windows execution, target-GPU
performance, audible sound or production art quality. Archive packaging and
reassembly checks are recorded separately and do not expand the gameplay scope.

### Download-package integrity

Each desktop executable exceeds the 500,000,000-byte download limit, including
after the attempted ordinary single-ZIP compression. The accepted distribution
therefore uses two ordinary ZIPs per platform containing exact executable
chunks and a local SHA-256-checking assembly helper. The four final ZIPs are all
below that limit. Every archive's member list, CRC and per-file SHA-256 passed;
streaming the actual archived chunks back together reproduced each accepted
exported executable's exact full hash.

The actual Linux helper was also run in `--verify-only` mode on extracted
delivered bytes. It restored the accepted executable with its executable bit,
reused an already identical output, rejected missing and corrupted Part02, and
refused to overwrite a different executable. An unrelated interrupted assembly
sentinel remained untouched. No game was launched by this packaging test.
Windows helper execution remains unverified. See the [multipart receipt](verification-logs/delivery-v031-card-reconstruction/native/release-native-multipart-v0.3.1-card-reconstruction.json)
and [actual Linux assembly cases](verification-logs/delivery-v031-card-reconstruction/native/linux-assembly-verification.json).

## Current rules regression

The recorded six-suite run used official Godot 4.7.2, headless, with fresh isolated XDG directories per suite. All six processes exited 0. The monitored rule/test sources were stable throughout the run and no script-error diagnostics were recorded.

| Actual script | Groups | Checks | Result |
| --- | ---: | ---: | --- |
| `tests/test_hunts.gd` | 9 | 458 | Zero failures |
| `tests/test_realm.gd` | 14 | 247 | Zero failures |
| `tests/test_progression.gd` | 11 | 277 | Zero failures |
| `tests/test_hero_identity.gd` | 6 | 134 | Zero failures |
| `tests/test_item_rules.gd` | 5 | 73 | Zero failures |
| `tests/test_action_rules.gd` | 13 | 201 | Zero failures |
| **Combined recorded rules run** | **58** | **1,390** | **Zero failures** |

The authoritative run inventory, commands, durations, source hashes and individual summaries are in [hunt-contracts.json](verification-logs/hunt-contracts.json). Raw output and command metadata are the `verification-logs/hunts-*.log` and `.run.json` companions. The correct realm script is `test_realm.gd`; `test_realm_rules.gd` in earlier prose was a documentation error.

The hunt suite covers three registered formations, stable item rolls across withdrawal/re-entry, actual persistent enemy attrition, distinct story/contract ledgers, once-only completion XP, capacity failure with no payment, finite sale transactions and real action outcomes. Its earned route completed forty-six hunts to reach level 30 at 23,200 XP, used all three formations, collected actual loot, equipped earned items, and paid watches to rest. The run used 26,087 action ticks, reached a minimum return Health of 81, retained 95 inventory instances and the bounded last 32 history records, then completed a forty-seventh contract without minting XP or attribute points at the cap. Its final clock was watch 279. These are deterministic automated-route facts, not production balance or human enjoyment findings.

Progression checks cover the cumulative XP curve, multi-level awards and overflow/cap, ninety total spendable attribute points, useful derived effects, no-heal allocation/reset, stale revision rejection, pending locks and genuine old-save migrations. Identity checks cover all 156 canonical mappings, twenty classes/eight races, immutable Mara identity, off-class rejection at submission and paused intent, unknown/conflicting IDs and legacy pending compatibility. The identity alias `ileana` is not a 157th champion.

The retained realm checks cover dawn accounting, paid construction, finite markets, rival treasury/neutral claims, observed information, finite oaths, real story combat and registered rewards. Item checks cover seeded instances, slots, set thresholds, recipes, JSON normalization and no bonus accumulation. Action checks cover movement, obstacles, timing, guard/dodge, class-appropriate ability fixtures, enemies, physical loot, extraction, pause and strict live persistence. No test count certifies a complete campaign or arbitrary legal input sequence.

## Earned native hunt, attributes and sale route

`tests/render_hunt_ui.gd` completed **181 checks, zero failures, exit 0**, with **twelve inspected captures** at 1440×900, 1280×800 and 960×640. It ran the actual Godot X11/Compatibility renderer through Mesa llvmpipe on a local virtual display, with isolated save data and the Dummy audio driver.

The harness sends real `Input` mouse/key events to the GUI. It buys the Granary and Market through their controls and legal day advancement, applies three real draft attribute points, opens the hunt board, enters a contract, and saves/restores the actual live action state. Combat uses legal authoritative commands and fixed action ticks. It returns from the uncollected-spoils warning without completing the run, physically collects three claims, legally extracts and earns level 2 at 120 XP. It opens the inventory, keeps an item once, then sells the earned Bellworn Treads for 32 gold through confirmation and verifies a round trip. It rests through the real control, clears another hunt, explicitly forfeits uncollected drops and earns level 3 at 280 XP with the board at generation 3. No outcome, XP, inventory or victory flag is injected. Waiting companies and the story ledger remain unchanged.

The twelve captures were inspected for readable offers, derived results, sale price, back/forfeit choices and smaller-window layout. No viewport control overflow was reported. Narrow boards intentionally scroll vertically. Actual menu input plus command-driven combat is an integrated automated route, not a complete human mouse-only playthrough or normal-speed animation acceptance.

Evidence: [hunt-ui-native.json](verification-logs/hunt-ui-native.json), [command/source record](verification-logs/hunt-ui-native.run.json), [raw native log](verification-logs/hunt-ui-native.log), and [hunt captures](screenshots/hunts/). Earned live, sale and two-completion save fixtures sit beside those reports. The run logged only the environment warning that V-Sync mode switching is unavailable; no script, GPU-leak or resource-leak diagnostic was found. A small town-footer bug observed in the captures was subsequently fixed by resetting the hint on `_show_town()`. That one-line presentation fix is later than the shell hash in this report and was not relabeled as a new full native run.

## Separate targeted presentation evidence

These are distinct, revision-bound tests. Their counts are not added to a single whole-game score.

| Proof | Recorded result | Exact boundary |
| --- | --- | --- |
| Class-specific spell feedback | 43 unit checks; 55 native checks; 17 captures; zero failures | Oathwarden Cleave/Ward, Pyromancer Ember, Druid Roots in separate canonical fixtures consuming real events; the other champions are not playable |
| Current Mara development PBR | 245 native checks; zero failures; ten captures | Actual imported v9 scenes, UV/maps/mipmaps, retained 53-bone rig and twelve clips; studio gear is a visual fixture |
| Current fitted sword/cowl adapter | 18 native checks; zero failures | Both actual registered modules, sampled roll/death controller ticks and real DungeonStage adapter; two visual items, not all armor |
| Current hero-preview lifetime | 25 native checks; zero failures; six cycles | Repeated create/render/dispose after the bounded four-scene cache and temporary-Sky fixes; stable 448,371,637 retained texture bytes after every close and zero orphan nodes |
| Historical PBR same-model building cards | 83 native checks; zero failures; eight building renders | Previously registered GLBs/rendered cards; provenance/geometry/material identity only. Superseded by the original-painted-card contract |
| Historical PBR building and live-card hover | 261 native checks; zero failures; eighteen inspected captures | Actual input on the previous town/card pairs, completion, rest, re-hover and disposal. Live model cards were subsequently removed |
| Previous Dawnreach town composition | 77 native checks; zero failures; seven inspected captures | 35 projected picks, yaw limits, small window, stairs, scene/scale and Water Gate; populated fixtures predating the art-direction correction |
| Integrated current character folio and town | 60 native checks; zero failures; eleven captures | Real draft/Apply/reset, no-heal behavior, rotation, save/load, class/trait/equipment/sets views, small layout and class-restricted encounter inspection; final town and prior earned-item inventory are explicit fixtures |
| Later save-and-audio shutdown regression | 81 native checks in eight groups; zero failures | Real atomic writer, realm/action state, Ogg streams and SpellFeedback ownership in a light fixture; heavy UI and terminal OS exit are substituted, and exported user exit remains a separate gate |

Spell feedback evidence is under [verification-logs/spell-feedback](verification-logs/spell-feedback/). The current character review is [character-pbr/native-report.json](verification-logs/character-pbr/native-report.json), with [visual disposition](verification-logs/character-pbr/visual-review.json) and [ten captures](screenshots/character-pbr/). The [current adapter/cache record](verification-logs/character-pbr/runtime-integration.json) links the eighteen-check equipment result and twenty-five-check lifetime result. The repeated-use repair retains four registered scene resources so reopening a preview does not create new RID-based prepared textures. Town and dungeon presentation also avoid allocating a temporary per-instance Sky before replacing it with the shared reflection Sky. Stable cached memory is not zero memory, and the six-cycle result is not an unlimited-duration leak guarantee.

Historical rendered-card evidence is [building-cards/pbr-animated-v1/native-report.json](verification-logs/building-cards/pbr-animated-v1/native-report.json), with [visual review](verification-logs/building-cards/pbr-animated-v1/visual-review.json) and the exact manifest. Both that rendered-card run and the earlier static-card run predate restoration of the original paintings; neither certifies the current painted-card reconstruction. Shared reflection-lighting calibration and replacement-lifetime tests remain their own 62-check and 21-check evidence under [pbr-lighting](verification-logs/pbr-lighting/).

### Historical actual-input building and live-card hover

The previous promoted eight-building set passed **261 checks, zero failures, exit 0**, with **eighteen inspected native captures**. Actual `InputEventMouseMotion` events traveled through GameShell and the real town/construction-folio controls. Each previous town model and live card started its authored work clip, completed naturally, returned to its exact captured transforms and blend weights, and restarted on re-hover. Closing an animated folio disposed its live viewport. Unknown, stale and disabled source proofs received actual pointer input and created no live viewport. Live-model cards were later removed to restore the original paintings; this remains historical behavior.

The native card review sampled eighteen current-morph bounds per building; all stayed in the recorded 384×384 card framing with nonempty transparent output and no edge clipping. Those samples are distinct from the retained ninety-one-source-frame envelope. The application ran at 1440×900 with the frozen perspective TownStage revision. All eight GLBs and the building/input modules remained unchanged during the run. Independent character and dungeon edits are disclosed in the before/after source record and are not certified by this building test.

This was a deliberately populated, read-only presentation fixture. It did not spend construction resources, earn the buildings or certify target-hardware frame rates. The native Compatibility/Mesa log contains only the virtual driver's unsupported V-Sync warning; no script, shader, resource or texture-leak error was recorded. See the [report](verification-logs/building-hover/pbr-animated-v1/report.json), [review and source boundaries](verification-logs/building-hover/pbr-animated-v1/review.json), [raw log](verification-logs/building-hover/pbr-animated-v1/native.log), [eighteen captures](verification-logs/building-hover/pbr-animated-v1/captures/) and [building identity contract](BUILDING_CARD_IDENTITY.md). The separate eighty-three-check still-card gate establishes the same final model provenance; its count is not merged with hover checks.

### Integrated current character folio

The current main-project folio run completed **60 checks, zero failures and eleven inspected native captures**, with only the virtual driver's unsupported V-Sync warning. It exercises the actual draft/undo/Apply controls, useful derived-stat changes without healing, view rotation/reset, invested-character save/load, safe-town allocation reset, class/race/trait and equipment/set views, the 960×640 layout, encounter entry, Mara's exactly Cleave/Ward hotbar, rejection of an off-class cast, and read-only combat inspection with pause restoration. Its recorded TownStage hash is the frozen composition revision below.

The fixture qualifications matter: the equipped rewards were earned by a prior v0.2 native route and are loaded unchanged; this run does not earn them again. The final seven-building panorama is deliberately populated for composition. The test does not turn a fixture into construction or combat evidence. See the [native report](verification-logs/hero-folio-v03/native-report.json), [run/source record](verification-logs/hero-folio-v03/run.json), [exact executed harness](verification-logs/hero-folio-v03/tested-harness.gd.txt) and [eleven captures](screenshots/hero-folio-v03/).

Two later presentation/portability edits are explicit: “Ward strength” was corrected to **“Additional Ward”**, because the displayed number is the equipment/attribute bonus; no rule changed. The rerunnable harness now reads `res://tests/fixtures/earned-v02-equipment.json` instead of its original temporary path, using the exact same fixture bytes (SHA-256 `4044dee9467859f615bed10d898eaae1f36ba795844bf82457bb5d79921c24f3`). The preserved tested harness and source hashes retain the actual sixty-check boundary. A subsequent native capture was rendered and inspected with the corrected label, exit0 and only the virtual V-Sync warning; its exact capture/hash and separate picture log are retained in the same evidence folder. This is label verification, not a repeated sixty-check run.

### Historical frozen town composition evidence

The visual review accepted this Dawnreach composition **for the development iteration**. The frozen TownStage SHA-256 is `88193633eb45d3c4a4d01966e22cc020140984ee6884930aedf3d1363cf9e4b6`. The camera uses a 42-degree perspective, target `(0,4,-4)`, offset `(16,27,63)` and the existing ±0.23-radian orbit; its native SubViewport uses 4× MSAA. `PLOTS` is byte-for-byte unchanged, and purchased GLBs, registered scene paths and wrapper scales are retained.

The test ran official Godot 4.7.2 with the native X11/Compatibility renderer and Mesa llvmpipe. All user data was isolated; ordinary player saves were neither read nor changed. Seven completed buildings and the exclusive Water Gate variant were deliberately populated **visual fixtures**, not claimed construction or campaign victories. The seven captures show the starting town, populated panorama and world-only image, both orbit limits, 960×640 and Water Gate. Actual MouseMotion work/rest/re-hover testing is the separate completed 261-check gate above.

Preserved evidence: [native report](verification-logs/town-composition/report.json), [raw log](verification-logs/town-composition/native.log), [command and source hashes](verification-logs/town-composition/run.json), [exact harness](verification-logs/town-composition/render_town_composition.gd), [visual review and remaining work](verification-logs/town-composition/review.md), [copy/hash inventory](verification-logs/town-composition/preserved-evidence.json), and [seven captures](screenshots/town-composition/). Original temporary paths are retained in the raw report; the preservation inventory maps them to the checked-in evidence. The only logged diagnostic was unsupported V-Sync mode switching on the virtual driver; no script, shader, orphan, resource or GPU leak diagnostic occurred.

## Save and shutdown validation

An initial cold-start exported Linux run with `--quit-after 120` reported eight retained objects and two resources. A warm diagnostic did not reproduce it; a second cold run did, identifying both looping Ogg playback chains. The original records remain under [native-v03](verification-logs/native-v03/) and [shutdown diagnosis](verification-logs/native-v03-shutdown-diagnosis.json). A clean intervening run was not used to erase the failed evidence.

GameShell now handles normal window close and **Save & Quit** through one idempotent path. It freezes gameplay, lets a committed deferred encounter resolution finish, and writes the existing atomic autosave. Both the write result and post-flush error are checked before rename. Failure restores processing, retains the previous save and live audio, and shows a deduplicated error inside an open menu without changing combat pause state. Success stops and clears owned audio, disposes its players, and allows live engine frames for playback references to release before quitting. Stale requests are cancelled if the shell leaves the tree during either wait; ordinary disposal restores the prior tree quit policy.

The focused native source fixture passed **eight groups, 81 checks, zero failures, exit 0**. It covers normal/muted Ogg audio, repeated menu/window requests, a failed open, a real `/dev/full` failure after opening, an exact live Ward/dungeon save, deferred retreat resolution, repeated scene disposal and cancellation at both awaits. The first revision also exposed a pending-first-physics spatial WAV reference; the final test uses the actual SpellFeedback controller and verifies its voice and bus cleanup. No script, playback-timeout, object, resource or rendering-leak diagnostic remained; only unsupported virtual-driver V-Sync was logged. See the [report](verification-logs/audio-lifetime/report.json) and [raw native log](verification-logs/audio-lifetime/native.log), bound to GameShell SHA-256 `c6714ad142891dcffff99168f31b9462e0ca2d748ae1d2bccc2af082158f809d`.

This fixture substitutes heavy town/UI construction and terminal `SceneTree.quit`; it uses the actual save, action, realm and audio code. The later exported-binary normal window/menu-close results are recorded separately. Dummy audio validates ownership and lifetimes, not speaker output. Engine-forced `--quit-after` bypasses the application's orderly close request and is not certified by this gate. These later shell changes do not relabel the earlier sixty-check folio or 261-check building-hover runs as tests of the new quit path.

## Historical design-document verification

The retained earlier design PDF contains **82 pages**, rendered from its recorded full game design and hero-roster sources. It predates the corrected card authority and is not distributed as the current art contract. Its historical extraction found all 2,186 source blocks, all 156 hero names and all 162 recruit names. All pages were rasterized and reviewed across seven contact sheets, with full-size inspection of the cover, contents, dense tables and final appendix layouts. No text outside the safe page bounds, missing rows, clipping or overlap was observed. The narrow role/name columns retained normal text wrapping. The brief roster introduction on page 13 and final acceptance text on page 82 deliberately left whitespace. Poppler exited 0; its Fontconfig cache warnings are preserved separately from the successful embedded-font rendering. See the [source hashes, extraction and visual-review record](verification-logs/design-pdf.json). This validates that document's recorded completeness and presentation, not implementation of its proposed systems. Current design content is in `GAME_DESIGN.md` and the current art contract is `CARD_RECONSTRUCTION.md`.

## Current art, platform and content limits

Mara's PBR revision retains its **development integration** scope. The previous Dawnreach building direction is **rejected**; the eight installed reconstructions follow the original paintings and have a separate development-only disposition. This is not finished photorealistic art or approval of an entire production roster. The base character has 41,590 triangles, fifty-three bones and twelve retained clips; four runtime GLBs share fourteen new PBR maps, and a packed editable Blender snapshot is approximately 60.87 MB. The current eight-building asset set totals 408,644 triangles and includes three-second local Hover clips plus RESET poses. Its exact revisions and remaining refinements are recorded in [BUILDING_RECONSTRUCTION_REVIEW.md](BUILDING_RECONSTRUCTION_REVIEW.md). See also [CHARACTER_MATERIALS.md](CHARACTER_MATERIALS.md) and [CARD_RECONSTRUCTION.md](CARD_RECONSTRUCTION.md).

Remaining character work includes the neckline/cowl edge, tailored deformation, face/hair identity, secondary motion, boot maps, lower LODs and material consolidation. The town still has repeated terrain textures, comparatively uniform paths, simple shoreline/water transitions, a fixed daylight setup and reused ambient village/vegetation assets. The placement correction does not close these production art limits. One Dawnreach panorama does not establish nine completed faction capitals. One playable Mara, twelve clips, two fitted earned items and an interim Gloamfang model do not establish 156 playable heroes or completed armor/creature rosters.

The three repeatable hunts reuse the current Bellworn Vault geometry with different actor formations and tiered registered values. They are not three unique dungeon maps, a procedural campaign, or proof of compelling endgame. Only Mara is playable; signatures, racial packages, class-resource traits and talents remain design-only. Field-company combat, defended conquest, siege gameplay and the full campaign remain unimplemented in this action slice.

Software-rendered native captures test layout and integration, not real-time frame-rate performance on target hardware. No native Windows runtime, additional graphics-vendor pass, full accessibility audit, localization pass, multiplayer or long-duration human campaign test is recorded here. The immutable v0.2 Linux executable had a clean native 120-frame launch but a documented short headless-teardown warning; those exact export limits remain in its historical page. A new v0.3 export/boot gate must be recorded separately before distributing it as a tested binary.

## Reproduce without touching player saves

Use a fresh temporary parent and set all three XDG directories. The following runs only the six rules suites; it does not delete any ordinary user save:

```bash
draconia_test_root=$(mktemp -d /tmp/draconia-v03-rules.XXXXXX)
(
  export XDG_DATA_HOME="$draconia_test_root/data"
  export XDG_CONFIG_HOME="$draconia_test_root/config"
  export XDG_CACHE_HOME="$draconia_test_root/cache"
  for suite in test_hunts test_realm test_progression test_hero_identity test_item_rules test_action_rules; do
    godot --headless --path . --script "res://tests/$suite.gd" || exit "$?"
  done
)
```

The native hunt harness deliberately requires its isolated data location to begin with `/tmp/draconia-hunt-native`. It needs a working X11 display and the Compatibility renderer. Use a fresh harness directory; never substitute a player's application data.

```bash
draconia_native_root=$(mktemp -d /tmp/draconia-hunt-native.XXXXXX)
env XDG_DATA_HOME="$draconia_native_root/data" \
  XDG_CONFIG_HOME="$draconia_native_root/config" \
  XDG_CACHE_HOME="$draconia_native_root/cache" \
  godot --path . --display-driver x11 --rendering-method gl_compatibility \
  --audio-driver Dummy --script res://tests/render_hunt_ui.gd
```

The test writes its documented captures to its fixed temporary capture path. These commands are reproduction instructions, not an additional executed run. Read [HUNT_CONTRACTS.md](HUNT_CONTRACTS.md) and [ATTRIBUTE_PROGRESSION.md](ATTRIBUTE_PROGRESSION.md) for the implemented transaction details.
