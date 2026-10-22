> Historical v0.2 checkpoint. This page is retained as the record of that release; it does not describe the later class, attribute, or hunt implementation. The old command name `test_realm_rules.gd` below was a documentation error; its actual script is `tests/test_realm.gd`. See the current [verification page](VERIFICATION.md) for newer evidence.

# Draconia — Oaths of the Carpathians

**Version 0.2.0 — native Godot development build.** An original Eastern European high-fantasy strategy/action RPG built around exactly one chosen hero. This revision launches the Dawnreach town and Bellworn Vault action slice, with the new illustrated manuscript interface.

This is a working development slice. It does not yet match Heroes III's scope or production quality. The full nine-faction, 156-hero design is documented separately; those catalog entries are not 156 playable implementations.

## Play this version

Import `project.godot` into the standard **Godot 4.7.2** editor, let asset import finish, then press **F5**. The configured starting scene is `redesign.tscn`. No original Heroes III installation or data files are required. GDScript is used; the .NET editor is unnecessary.

For the packaged desktop builds, extract the full archive and launch `Draconia.exe` on Windows or `Draconia.x86_64` on Linux. The editor is not required for a desktop executable. Windows is cross-exported; Windows runtime behavior has not been verified in this environment.

```bash
godot --editor --path .
godot --path .
```

## What works now

- **One persistent hero:** Mara Veyne, with Health, Focus, inventory and equipment. The live 3D hero has twelve animation clips. The earned Vowkeeper sword and Bellworn Cowl have fitted 3D representations.
- **A dedicated 3D town:** Dawnreach has eight building choices, including a mutually exclusive Wharf/Water Gate river plot. A purchased building appears in its actual plot immediately. One construction is allowed per settlement/day; purchase itself consumes no watches.
- **An illustrated native interface:** painted resources and commands, a selected-building plate, a construction folio, a hero equipment folio with a live model and backpack, an oath ledger, expedition briefing and action bar. Source images, crop contracts and bounded art-review notes are in `assets/ui/manuscript/`.
- **A deterministic solo dungeon:** move, pursue and attack, guard, dodge, and use Cleave, Ember, Ward and Living Roots. Physical walls block movement; enemies use the same authoritative action model. Your companies remain in town unchanged.
- **Persistent consequences:** four watches/day, dawn income and upkeep, two finite oaths, rival recruitment/movement/neutral claims, expedition costs, retained wounds, defeat recovery, persistent defeated enemies and once-only loot.
- **Equipment and socket recipes:** sixteen item definitions, eleven equipment slots, one five-piece set definition and two ordered rune recipes. A completed Market sells finite ordinary socket bases, runes and amber. Set and unique traits affect actual combat calculations; equipment changes do not heal the hero.
- **Saved progress:** manual save plus autosave, including a valid in-progress action encounter. Town construction, cooldowns, statuses, loot claims and equipment survive the registered save/load flow.

## Start here

1. Open **Browse Town Works**, choose the Granary, and construct it. Watch it appear in Dawnreach.
2. Open **Oaths** and accept *Silence the Bell* before visiting the vault.
3. Open **Expedition** and enter the Bellworn Vault. Only Mara enters. Defeat the pack, physically collect the four rewards, and return to the entrance seal to leave.
4. Open **Hero**. Inspect the earned equipment, equip Vowkeeper and the Bellworn Cowl, and compare the item details and live 3D model.
5. To explore sockets, advance to a new day and build the Market after the Granary. The Realm panel then opens the market. Buy a Notched Ironblade and materials; select the weapon in the hero folio to insert owned runes. Cinder then Stone makes Hearthguard; Cinder then Gale makes Windscar.

## Controls

| Context | Control |
|---|---|
| Town buildings and panels | Left-click the illustrated controls |
| Hero folio / oath ledger / rest | I / J / R |
| Dungeon movement or target | Left-click ground, an enemy, loot or the exit |
| Selected action skill | Right-click |
| Cast a skill toward the cursor | 1–4 |
| Toggle directional guard | G |
| Dodge toward the cursor | Shift |
| Tactical pause / resume | Space |
| Dungeon camera distance | Mouse wheel |
| Town camera | Side arrows; mouse wheel over town |
| Menu / close panel | Esc |
| Manual save | Ctrl+S |

Loot and exit interactions automatically approach a legal interaction distance. Equipment changes are made in town. Common town construction does not advance the realm clock; resting advances one watch. Next Dawn stops at the next dawn or intervening oath deadline.

## Saves

The new development slice uses `draconia-action-save.json` and `draconia-action-autosave.json` in Godot's application-data directory. On startup, a valid autosave is restored. The menu provides manual save/load and New Chronicle. Starting again replaces the active autosave while retaining the manual save.

This format is separate from the retained legacy prototype's save. Invalid or unsupported state is rejected without replacing the active game. JSON integrity checks are compatibility/consistency checks, not a security or anti-cheat guarantee.

## Scope and verification

Read `docs/VERIFICATION.md` for the current evidence and its limits. The current rules suites contain 247 realm, 201 action and 73 item checks. The redesigned native interface route has 101 checks and seventeen captures across 1440×900, 1280×800 and 960×640. Equipment clearance and preview lifetime checks are separate targeted evidence.

The three-dimensional environment, final character surfaces and broader content remain under development. Full field-company combat, sieges, the complete hero/faction roster, full progression, campaign map, multiplayer and an editor are not complete in this slice. No claim of zero bugs, commercial success or Heroes III parity is made.

`docs/GAME_DESIGN.md` and `docs/HERO_ROSTER.md` describe the full original design; the complete PDF is included in the source distribution. `docs/CREATURE_ROSTER.md` contains 54 families and 108 exclusive promotions as production designs. The one-playable-hero constraint applies to all of them.

## Source structure

- `redesign.tscn`, `game/redesign/`: current native town/action implementation.
- `data/`: design catalogs, including the full hero and creature concepts.
- `assets/models/mara/`: accepted development rig, two fitted items and explicit integration contracts.
- `assets/ui/manuscript/`: original generated UI art, proportional crop definitions, prompts and QA.
- `tests/test_realm_rules.gd`, `test_action_rules.gd`, `test_item_rules.gd`, `render_redesign.gd`: current checks.
- `main.tscn` and other `game/` files: retained earlier prototype, not the configured entry point. Its documentation/evidence is explicitly archived under `docs/LEGACY_*`.

The separate optional art-source archives preserve the costly authoring material without being needed to run the game. They unpack into the same `Draconia/` project root.

## Build and attribution

Matching Godot 4.7.2 export templates are required. Native presets are **Windows Desktop** and **Linux** in `export_presets.cfg`. Exports exclude staging assets, authoring tools, research and test evidence. The historical Web preset is retained but is not the delivered native target.

```bash
mkdir -p builds/linux builds/windows
godot --headless --path . --export-release Linux builds/linux/Draconia.x86_64
godot --headless --path . --export-release "Windows Desktop" builds/windows/Draconia.exe
```

Keep `LICENSE.txt`, `ASSET_CREDITS.md` and `assets/licenses/` with redistributed builds. Original generated Draconia art is recorded separately from downloaded licensed assets. No proprietary reference-game artwork or game binaries are included.
