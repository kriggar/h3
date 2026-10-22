# DRACONIA — Oaths of the Carpathians

An original, single-player strategy campaign built in **Godot 4.7.2**, inspired by the adventure-map and tactical-battle structure of Heroes III and set in a fictional Romanian folklore realm.

Lead Ileana from Cetatea Zorilor, gather resources, develop three towns, recruit an army, and restore three ancient oaths before confronting the Balauri of Cetatea Nopții. Three daylight days alternate with two nights. Broken oaths strengthen the night host; restored oaths protect your army and weaken the final fortress. Iele, Vârcolaci, Solomonari and Strigoi are part of the playable campaign.

**This release contains one complete campaign. It does not yet match Heroes III's breadth or feature completeness.** There is one controllable hero, ten unit types, six recruitable types, ten fixed encounters, six building definitions and two combat spells. The requested full-production target remains a game with comparable breadth: nine original factions, complete seven-tier upgrade trees, strategic enemy heroes, extensive magic and artifacts, campaigns, an editor and multiplayer. Those systems are planned, not implemented in this build. See the [current scope and architecture](docs/DEVELOPMENT_SCOPE.md) and the concrete [production plan](docs/PRODUCTION_PLAN.md).

Adventure and battle use **native Godot 3D environments**, with terrain, cameras, lighting, trees, rocks and buildings. The tactical Vârcolac uses a skinned, animated 3D model; the other troop types currently use animated sprite billboards, one representative per stack. Dark wood and bronze frames, manuscript portraits and readable status panels surround the playfield. This is a mixed character presentation with an interim sprite roster, not a complete 3D creature production.

## Run the source project

1. Install the **standard Godot 4.7.2 editor** from the [official Godot download site](https://godotengine.org/download/). This project uses GDScript; the .NET editor is not required.
2. Extract the whole project folder. Keep `project.godot`, `main.tscn`, `game/` and `assets/` together.
3. In Godot's Project Manager, choose **Import**, select `project.godot`, and open the project. Allow the first asset import to finish.
4. Press **F5** to run the configured project. Alternatively, open `main.tscn` and press **F6** to run that scene.
5. Begin or resume the chronicle from the title screen.

You do not need an original Heroes III installation, its executable, or its data archives to play DRACONIA. Mouse and keyboard are the primary controls. Sound is optional and can be enabled through the title/menu controls.

From a terminal in this directory:

```bash
godot --editor --path .
godot --path .
```

If your Godot executable has another name or is not on `PATH`, substitute its full path.

## Your first campaign

1. **Prepare at Cetatea Zorilor.** Visit the nearby home town to recruit troops and construct buildings. Each town permits one building per day. Oșteni and Arcași provide affordable numbers; the barracks unlock Străjeri, and the Solomonar tower opens magic troops and full-mana rest.
2. **Follow roads and claim income.** Click a destination to inspect its route, then click it again or use the travel button. Long routes advance as far as the day's movement allows. Roads and bridges matter; forests, hills and snow cost more movement. Collect caches and claim mines for income on subsequent days.
3. **Restore the oaths.** Read Piatra Străbunilor to reveal their locations. Each oath has an actual battle. The woodland oath also lets you dedicate a sacred grove and recruit Iele.
4. **Choose when to fight.** Daylight grants defense. Night strengthens enemies while corruption remains, but pays 25% more victory gold and experience. Each restored oath reduces that threat permanently.
5. **Develop Ileana and her host.** Spend earned level-up choices on attack, movement or spellcraft. Liberate Poiana Corbilor and Mănăstirea Albă for additional income, recruitment and a refuge for mana recovery. New recruits arrive each week.
6. **Break the final seal.** All three oaths must be restored before Cetatea Nopții can be attacked. Preserve troops and mana for its Balauri. Defeat returns Ileana home with a recovery fee; a total army loss receives a small replacement force, so you can rebuild.

### Controls

| Adventure action | Control |
| --- | --- |
| Inspect/select destination | Left-click a tile or location |
| Confirm travel | Click the selected destination again, or use its travel button |
| Pan / zoom | Drag the map / mouse wheel; arrow keys / `+` and `−` also work |
| Find Ileana | `H` |
| End day | `E` |
| Grid | `G` |
| Towns / chronicle | `T` / `J` |
| Back, clear selection, menu | `Esc` |
| Save | `Ctrl+S` or `Cmd+S` |

In battle, click a reachable hex to move or an enemy to attack. The target list also selects attacks. Ranged units cannot shoot while adjacent to an enemy; ammunition and distance affect shooting. `W` waits, `D` defends, and `A` toggles automatic battle control. Arrow keys select a hex and `Enter` acts on it. `Esc` cancels a selected spell. The **Withdraw** button requires a second confirmation.

Use the mouse wheel over the battlefield to change the inspection distance. Hold the right or middle mouse button and drag to turn the battlefield camera. Camera movement changes the view without changing troop positions or movement rules.

Ileana may cast one spell per round without spending the active troop's action. **Oathfire** costs 5 mana and damages an enemy stack. **Mend** costs 4 mana and repairs wounds in a surviving friendly stack; it does not resurrect fallen creatures. The battle result applies real casualties and mana use to the adventure campaign.

## Preserve your progress

The active chronicle saves after completed campaign actions and battle resolution. In-progress tactical turns are not a separate save state. On startup, the game attempts to restore its valid active autosave.

- Open **The Chronicle** menu and use **Save progress** to save manually.
- Use **Export save file** for a portable `Draconia-Day-….json` backup. Keep that file outside the game folder before replacing the installation or moving to another device.
- Use **Import save file** to restore it. A valid imported save becomes the active chronicle; malformed saves leave current progress unchanged.
- **Start a new chronicle** replaces the active autosave. Export the current one first if you want to return to it.

Native autosave is `user://draconia-save.json` in Godot's application-data location, not in the source project. The sound setting is saved separately. For a Web build, persistence depends on browser storage; clearing site data or using a private session can remove progress. Exported JSON is the portable backup. See [Godot's web persistence documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#using-cookies-for-data-persistence).

## Build Windows, Linux or Web

Install the **matching Godot 4.7.2 export templates** through the editor's export-template manager. Open **Project → Export** and select a preset from `export_presets.cfg`.

| Preset | Default output |
| --- | --- |
| `Windows Desktop` | `builds/windows/Draconia.exe` |
| `Linux` | `builds/linux/Draconia.x86_64` |
| `Web` | `dist/index.html` plus its accompanying WebAssembly/data files |

For command-line exports, create the output directories first, then run:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --export-release "Windows Desktop" builds/windows/Draconia.exe
godot --headless --path . --export-release "Linux" builds/linux/Draconia.x86_64
godot --headless --path . --export-release "Web" dist/index.html
```

Keep all generated Web files together and serve them through a web server; opening the HTML with `file://` is not the intended launch method. Use a WebAssembly/WebGL 2-capable browser and HTTPS for hosting, or localhost for local development. This preset is single-threaded. Platform requirements and hosting behavior are described in the [official Godot Web export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

**Export success and gameplay verification are separate.** The current check results, including the cloud browser's WebGL/secure-context limitation and outstanding platform checks, are recorded in [VERIFICATION.md](docs/VERIFICATION.md). Do not treat an exported file as evidence that it has been played on every target platform.

## Tests and development

Run the native suites from this project directory on Linux. The application suite writes and clears test autosaves, so use a fresh isolated directory. This subshell keeps the test environment separate from normal play:

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

The app suite refuses a user-data path outside `/tmp/draconia-app-test…`. Do not remove that guard or point tests at a player's data directory. These commands leave temporary test files available for inspection; they do not delete or replace normal progress. This recorded test procedure is Linux-specific, separate from playing or exporting the Windows build.

The normal suites currently total **1,184 checks: 977 campaign, 81 battle and 126 application checks**, all passing in the recorded native runs. They include three complete tactical campaign simulations, real BattleScreen controller execution, application/save integration and a real final-battle-to-victory path. [VERIFICATION.md](docs/VERIFICATION.md) explains their coverage and limits.

Campaign rules and content are in `game/campaign_core.gd`; tactical rules are shared by the UI and simulator in `game/battle_rules.gd`. The application, map renderer, battle screen, art helpers and theme are separate modules. Save state is JSON-compatible and versioned. [DEVELOPMENT_SCOPE.md](docs/DEVELOPMENT_SCOPE.md) records the present architecture; [PRODUCTION_PLAN.md](docs/PRODUCTION_PLAN.md) defines the remaining content and system work with acceptance gates.

## Code, artwork and research licenses

Original DRACONIA source code and original documentation are provided under the **MIT License** in [LICENSE.txt](LICENSE.txt), copyright Draconia contributors.

Downloaded assets retain their own licenses:

- Flare-derived unit artwork and its repacked/composited adaptations: **CC BY-SA 3.0**.
- The Poly Haven models and ground textures, Yughues forest models, Daniel Andersson houses, Paul Wortmann shack, br-n518 Vârcolac model/animations and downloaded music/forest ambience: **CC0 1.0**.
- Cinzel and EB Garamond fonts: **SIL Open Font License 1.1**.

Read [ASSET_CREDITS.md](ASSET_CREDITS.md), the bundled notices in `assets/licenses/`, and the audio/animation provenance manifests before redistributing assets. The source-code MIT license does not replace those terms. Generated manuscript portraits, illustrations and UI materials are recorded in `assets/generated/generation-prompts-v2.json`; the earlier project illustrations are recorded in `assets/generated/generation-prompts.json`. The manuscript UI direction is documented in [ART_DIRECTION.md](docs/ART_DIRECTION.md), with actual native screenshots in `docs/screenshots/`.

This game uses the **MIT-licensed Godot Engine**: [official engine license and notices](https://godotengine.org/license/), with its [third-party component notices](https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt).

The REA installation, native investigation tools and reference repositories remain outside this game's runtime. No VCMI, Heroes III or Wesnoth source code, original Heroes III art, or older Wesnoth-based browser assets were copied into the native Godot project. [RE_FINDINGS.md](research/RE_FINDINGS.md) records exactly which original files and bounded procedures were inspected and what remains unverified.
