# DRACONIA — verification record

Recorded 22 October 2026. Engine used: **Godot 4.7.2 stable**, native Linux x86-64. This record separates rule tests, application integration, export/boot checks and visual/browser verification. Passing one category does not imply the others passed. All three normal suites, the fourteen-view visual pass, both native exports and the Linux boot checks were rerun against the final native 3D presentation. The earlier Web result is identified separately.

## Current status

| Check | Status at this checkpoint | What the result establishes |
| --- | --- | --- |
| GDScript parsing and resource/class import | Passed in the recorded native runs | Scripts needed by the test suites load and execute in the actual Godot engine |
| Editable-source portability | **Fresh import and headless boot: exit 0** | A clean copy of the packaging inventory opened without the development import cache; no missing resources or script errors |
| Campaign suite | **977 checks, 0 failures** | Campaign transactions, progression, persistence and three complete tested routes |
| Battle suite, revised 3D source | **81 checks, 0 failures; exit 0** | Tactical rules plus real asynchronous BattleScreen controls/controller behavior; no engine errors or warnings in the recorded log |
| Application suite, revised 3D source | **126 checks, 0 failures; exit 0** | Real scene and Main integration, including a final battle and victory presentation; no engine errors or warnings in the recorded log |
| Normal automated total | **1,184 checks, 0 failures** | Sum of the three normal suites: 977 + 81 + 126 |
| Optional fixture-generation variant | **979 campaign checks, 0 failures** | The same campaign suite with two additional fixture-generation checks; **not** a second set of 979 independent tests to add to the normal total |
| Final Linux release export and launch | **Export, headless boot and rendered boot: exit 0** | The final standalone executable starts outside the source directory, with its embedded game data; rendered boot used native X11/Mesa and had no script or shader errors |
| Final Windows cross-export | **Passed, process exit 0** | The final Windows package was produced on Linux; an actual Windows runtime was unavailable, so Windows execution/playthrough remains unverified |
| Earlier Web export | Passed after correcting the mobile texture import/export configuration | Godot produced the earlier Web package; this is an export result, not a browser playtest or a final 3D export check |
| Cloud-browser Web launch/playtest | **Blocked by environment; not passed** | The available browser lacks usable WebGL 2 and the attempted remote HTTP context is not secure; no successful Web gameplay result is claimed |
| Final native layout and render pass | **14 actual viewport captures, zero reported overflow; exit 0** | The final 3D presentation and manuscript interface rendered at 1440 × 900, 1280 × 800 and 960 × 600; no script or shader errors, one software-driver V-Sync capability warning |
| Revised native 3D battle views | Five actual Linux/Mesa captures inspected | Day/night, 1440 × 900, 1280 × 800 and 960 × 600, plus a turned/zoomed camera; one animated representative per stack, native animated Vârcolac, 3D terrain/scenery and shared manuscript UI |
| Revised battle projection/picking | **825 round trips, 0 failures; exit 0** | All 165 playable hex centers project back to the same cell in each of five configurations; this count is separate from the 1,184 normal checks |

Windows runtime execution and a successful browser playthrough remain unverified. The native captures establish rendered-view evidence on the inspected software-rendered Linux setup; they do not establish a broad hardware matrix or a complete human playthrough. Do not promote export success to runtime success. Raw normal-suite logs, exit codes and source hashes are retained in [verification-logs/summary.json](verification-logs/summary.json).

## Reproduce the native suites

From the project directory on Linux, with the standard Godot binary available as `godot`, use a new isolated data/config/cache directory for every run. The application suite intentionally creates and clears test saves and settings. These commands keep that activity separate from a player's chronicle and restore the caller's environment automatically when the subshell ends:

```bash
(
    set -eu
    draconia_test_root="$(mktemp -d /tmp/draconia-app-test.XXXXXX)"
    export XDG_DATA_HOME="$draconia_test_root/data"
    export XDG_CONFIG_HOME="$draconia_test_root/config"
    export XDG_CACHE_HOME="$draconia_test_root/cache"
    mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
    godot --headless --path . --editor --quit
    godot --headless --path . --script tests/test_campaign.gd
    godot --headless --path . --script tests/test_battle.gd
    godot --headless --path . --script tests/test_app.gd
)
```

Each test script exits with a nonzero status if its own checks fail. The first command imports assets and registers global GDScript classes. Retain the printed summary and stderr when recording a new run; an engine process returning successfully is not a substitute for checking the suite's summary.

The verified engine in the development workspace is:

```text
analysis-tools/godot/Godot_v4.7.2-stable_linux.x86_64
```

`test_app.gd` exits before loading the application unless `OS.get_user_data_dir()` begins with `/tmp/draconia-app-test`. The fresh directory above satisfies that guard. Do not remove the guard or substitute a player's save directory. No cleanup command is included; temporary evidence remains available for inspection. This procedure is Linux-specific. A native Windows test runner needs an equally isolated data-location strategy before its application suite can be claimed as verified.

## Campaign coverage

[test_campaign.gd](../tests/test_campaign.gd) runs fourteen groups. It covers seeded map reproducibility and routes to all thirty destinations; impassable terrain, bridges, guard blocking and diagonal corners; movement affordability and fog; one-time resources and mines; recruitment and building transaction rollback; prerequisites, stock, mana rest and weekly growth; the three-day/two-night cycle; battle-context modifiers; guarded oaths and Iele recruitment; final-fortress gating; casualties, recovery and reward protection; level/skill choices; save validation; and version-1 migration.

The three complete playthroughs use **the actual `BattleRules.simulate` implementation shared with the interactive tactical game**. They do not mock victories. The route pays movement, waits for real days, collects resources, spends real gold/stock/building materials, resolves actual casualties/mana, spends earned skill points and reloads a midcampaign save. It does not inject money, teleport the campaign hero or invent reinforcements.

| Campaign seed | Result | Day | Encounters won | Wards | Final battle rounds | Army maximum-HP total before → after finale |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 711 | Victory | 10 | 10 | 3 | 4 | 1,190 → 840 |
| 1337 | Victory | 10 | 10 | 3 | 4 | 1,040 → 700 |
| 2026 | Victory | 10 | 10 | 3 | 4 | 1,100 → 745 |

All three runs capture the additional two towns, complete the campaign objectives and reload the final victory save. The HP totals measure surviving creature count × maximum creature HP after combat, not a continuous wounded-stack HP measurement across the whole campaign. The tested results show a successful planned route with meaningful final casualties. They do not prove that every army composition, route, map seed or player tactic wins.

### Legitimate final-approach fixture

```bash
godot --headless --path . --script tests/test_campaign.gd -- --write-fixture
```

This variant regenerates [final-approach.json](../tests/fixtures/final-approach.json) after replaying seed 711's nine preceding battles and normal campaign progression. It adds two checks, bringing that invocation to **979**, rather than changing the normal 977-check count.

The fixture contains day 10/night, level 8, all three earned wards, zero corruption, Ileana at `(30, 8)`, 60 mana and `victory: false`. Her survivors are 29 Oșteni, 26 Arcași, 7 Cavaleri, 2 Străjeri and 5 Solomonari. The fortress contains 4 Balauri, 27 cursed spirits and 36 Strigoi. This is a reproducible earned state used for integration testing, not manually fabricated quest completion.

## Battle and application coverage

[test_battle.gd](../tests/test_battle.gd) checks hex geometry and reachability, speed and occupied cells, flying movement, attack/defense modifiers and caps, partial creature health, healing without resurrection, retaliation limits, ranged engagement/ammunition/distance rules, initiative/wait, results, and introductory-battle balance across twelve seeds. It also creates the actual `BattleScreen`, exercises manual spell/wait/withdrawal behavior, and runs its asynchronous AI controller. The seeded controller and simulator agree on survivor counts, mana and rounds.

[test_app.gd](../tests/test_app.gd) loads the real application scene. It exercises actual button signals, map mouse input, beginning/resuming the chronicle, modals, day transitions, resource movement, recruitment/building, saving, malformed imports, autoload and native file-dialog import/export callbacks. It runs introductory and final battles through the actual `BattleScreen` and Main's result handler, then checks the campaign state and victory modal. File-dialog callback coverage is not a claim that a human navigated every operating-system dialog.

For final battle seed 721 from the earned fixture, the interactive controller produces the expected four-round victory: 13 Oșteni, 20 Arcași, 6 Cavaleri and 5 Solomonari survive; combat ends with 40 mana. Campaign level-up processing may subsequently increase mana. The test compares Main's complete resolved campaign state with the result of applying the same outcome through `CampaignCore`, rather than checking only a victory banner.

## Export and visual checks

The editable project was also checked independently of the development import cache. The packaging script's exact source inventory was copied to a fresh directory: 523 files, 309,004,416 bytes, with matching SHA-256 hashes. Godot imported that clean copy and then started the game headlessly, both with exit 0. Import reported one non-blocking warning about ignored legacy ambient material metadata in a retained OBJ; game startup reported no errors or warnings. The [source-portability report](verification-logs/source-portability-report.json), inventory and raw logs preserve the commands and evidence. The final source archive additionally contains the evidence produced by this gate.

The presets are `Windows Desktop`, `Linux` and `Web` in [export_presets.cfg](../export_presets.cfg). Matching Godot 4.7.2 export templates are required. Example release commands, after creating the destination directories:

```bash
godot --headless --path . --export-release "Windows Desktop" builds/windows/Draconia.exe
godot --headless --path . --export-release "Linux" builds/linux/Draconia.x86_64
godot --headless --path . --export-release "Web" dist/index.html
```

The final Linux and Windows release exports both completed with process exit 0 after the 3D environments and manuscript interface were frozen. Their byte sizes and SHA-256 hashes are recorded in [native-release-exports.json](verification-logs/native-release-exports.json). The exporter logs contain local TCP-listener creation errors caused by the sandbox's socket restriction; packing completed, and no script or resource export error was reported. The final Linux executable then passed both a headless boot and a rendered X11/Mesa boot from fresh isolated directories outside the source tree, using its embedded game data. The headless runtime log is clean; the rendered runtime reports only the software driver's unsupported V-Sync-setting warning. No Windows runtime was available to execute the Windows package, so Windows startup, input, audio, saving and campaign play remain unverified.

The final software-rendered layout pass captured fourteen actual Godot viewports at 1440 × 900, 1280 × 800 and 960 × 600, with zero reported overflow. It covers the title, adventure, world overview, recruitment, construction, encounter, battle, retreat result and final night encounter. The screenshots in [screenshots/](screenshots/) are actual native output from the final 3D environments and wood/bronze manuscript interface. Their paths, dimensions and hashes are recorded in [layout-report.json](verification-logs/layout-report.json); the complete renderer output is [native-render.log](verification-logs/native-render.log). The pass returned exit 0 and no script or shader errors. Mesa's software driver reported that changing V-Sync mode was unsupported. These captures establish inspected layout and rendering, not a complete human campaign playthrough or a graphics-hardware compatibility matrix.

The revised battle was rendered separately through Godot's Compatibility renderer on Mesa llvmpipe. Five actual captures cover daylight, night at the fortress, three window sizes and a turned/zoomed inspection camera. Inspection prompted larger troop representatives, softer daylight, full forest foliage, removal of decorative grass triangles and one clearly separated representative per stack. The Vârcolac is an animated skinned 3D model; the remaining troop types use animated Sprite3D billboards. The terrain, trees, rocks, fortress backdrop, lighting and camera are native 3D. The fortress backdrop does not implement siege mechanics.

The same capture run projected and selected all 165 playable hex centers in each configuration, producing **825 round trips with zero mismatches**. This verifies those camera/hex transformations and does not add to the normal gameplay-suite count or establish every possible mouse target. The reproducible capture script, raw renderer log and image hashes are in [battle-3d-projection.gd](verification-logs/battle-3d-projection.gd), [battle-3d-projection.log](verification-logs/battle-3d-projection.log) and [battle-3d-projection.json](verification-logs/battle-3d-projection.json). The renderer log contains one V-Sync capability warning from the software driver; it reports no script error. Run the capture script with a working graphical display and the Compatibility renderer; it is not a headless image test:

```bash
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script docs/verification-logs/battle-3d-projection.gd
```

The script writes captures under `/tmp/` and does not load or alter player autosaves. Visual captures do not substitute for a human campaign playthrough, listening tests, or tests on additional graphics drivers and displays.

The earlier Web package was successfully produced after its texture configuration was corrected. The available cloud browser could not provide the required usable WebGL 2 context, and the attempted remote HTTP launch also lacked a secure context. This is an environment-limited browser check, not a successful playtest and not proof that the export is universally broken. The Web preset remains in the editable source; no final browser-played 3D release is claimed. A supported WebAssembly/WebGL 2 browser, HTTPS or localhost hosting, and a complete round of save/audio/input/gameplay checks are still required. See [Godot's Web export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Downloaded animation QA is recorded in [assets/animated/source/qa-report.json](../assets/animated/source/qa-report.json): all ten PNGs decode, their hashes/frame bounds are checked, and the advertised states contain distinct animation frames. The two audio files were probed and fully decoded; their provenance is in [assets/audio/manifest.json](../assets/audio/manifest.json). File integrity is separate from the native rendered-view inspection and listening tests.

## Limits of this record

This first campaign has a substantial native rules/controller test set. It has not been demonstrated to have Heroes III feature parity, exact original mechanics, a broad device/GPU/browser compatibility matrix, long-term save compatibility across unplanned future versions, exhaustive human playtesting, or production-scale balancing. No measured human completion-time claim is made. The original-game reverse-engineering evidence and its separate limits are documented in [RE_FINDINGS.md](../research/RE_FINDINGS.md).
