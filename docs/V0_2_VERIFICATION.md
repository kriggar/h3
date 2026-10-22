> Historical v0.2 checkpoint. This page is retained as the record of that release; it does not describe the later class, attribute, or hunt implementation. The old command name `test_realm_rules.gd` below was a documentation error; its actual script is `tests/test_realm.gd`. See the current [verification page](VERIFICATION.md) for newer evidence.

# Current development verification — Draconia 0.2

This page applies to `redesign.tscn` and `game/redesign/`. The previous prototype's 1,184-check campaign evidence is retained in `LEGACY_VERIFICATION.md`; it is not added to the new slice's results.

## Executed rules checks

| Suite | Checks | Groups | Result |
|---|---:|---:|---|
| Realm rules | 247 | 14 | Zero failures |
| Deterministic action rules | 201 | 13 | Zero failures |
| Item rules | 73 | 5 | Zero failures |

The realm suite covers calendar transactions, paid town construction, once/day limits, exclusive plots, oaths, rival orders, solo encounter departure/return, physical encounter outcomes, reward identity, stable preview/grant rolls, save validation, and the finite market/socket-material route. The action suite covers movement/obstacles, attacks, guard, dodge, abilities, enemies, loot, extraction, pause, and strict in-progress persistence with the trusted realm encounter. The item suite covers identity, legal slots, derived stats, no-heal/no-stacking equipment changes, set bonuses, ordered sockets and JSON round trips.

A rule check is not a measured player experience, production balance pass, or exhaustive proof that no bug remains.

## Native interface and integrated route

The current `tests/render_redesign.gd` was run with Godot 4.7.2, native X11, the Compatibility renderer and Mesa llvmpipe. It uses actual viewport pixels and `Input.parse_input_event` for GUI/key input, with an isolated save directory. The accepted run completed **101 checks, zero failures, exit 0**, and saved **17 captures** at 1440×900, 1280×800 and 960×640, with zero reported control overflow.

It opens the illustrated construction folio, selects the Market and observes its missing prerequisite, returns to the Granary and purchases it with real resources, checks the native building, saves/reloads the town, opens equipment and oaths, accepts an oath, enters the solo dungeon, pauses/resumes, checks a visible blocking wall, resolves legal combat commands, saves/reloads an actual live encounter, approaches and collects all four once-only rewards, physically extracts, and equips the earned unique item. Companies remain unchanged and the two realm watches are charged correctly.

The combat route uses legal authoritative commands, but is an automated integration route rather than a complete human mouse-only playthrough. Layout detection does not replace visual review; full-size town, construction, combat, equipment and smaller-window captures were also inspected. Scrollable content is intentionally allowed to exceed its visible vertical region.

Evidence: `verification-logs/manuscript-ui-native.log`, `verification-logs/manuscript-ui-native.json`, and `screenshots/manuscript-ui/`. Source hashes accompany the native report.

## Targeted visual-resource and equipment checks

`verification-logs/hero-preview-lifetime.json` records the corrected preview teardown leak. Six immediate create/remove cycles previously left two 349,524-byte textures each; after removing the unused procedural sky from that preview, both immediate and normally rendered replacement cycles return to their baseline, with no orphan nodes. The native integration route also shuts down without leaked-texture errors.

The two fitted equipment proofs have separate **18-check** native evidence. The actual adapter sampled 25 roll states and 74 death states, checked repeated visual updates for nonaccumulating offsets, and kept the authoritative actor transform unchanged. Minimum observed cowl floor clearance was 6.78 mm during roll and 6.01 mm during death. The selected sword hides when required and creates one loose sword on death. This does not certify final cloth quality, every future armor combination, or a ballistic sword-drop animation.

The Mara v8 attack correction changes only the right-hand rotation track. All eleven other clips and the other attack channels remain unchanged. The development rig has twelve clips. Production material, cuff/collar, secondary braid motion, broad locomotion and optimization gates remain open.

## Art and UI acceptance limits

The new artwork is original generated project art, using the user's approved flat manuscript sheet only as a style reference. `assets/ui/manuscript/README.md` records dimensions, hashes, proportional crop boundaries and an independent visual review. No malformed-object or neighboring-cell contamination blocker was found in the reviewed sheets/crops. The full source hero figure remains rejected; only the previously reviewed hands-free portrait crop is used.

Buildings and item icons are illustrations, not proof that all their details exist on the current 3D models. Fine ink detail naturally disappears at small sizes. Ward and Guard currently share a shield symbol but have separate labels/hotkeys. No claim of 1,000 visual reviews or pixel-perfect universal rendering is made.

The visual direction is a working revision responding to the user's request. The broader 3D world still needs substantial production art. The completed UI pass does not establish Heroes III parity or completion of the full GDD.

## Reproduce

Run the three headless rules scripts using an isolated XDG data/config/cache location. The native harness deliberately requires its data path to begin with `/tmp/draconia-redesign-native`; do not substitute player save data. A working X11 display and OpenGL Compatibility renderer are required for actual screenshots.

```bash
godot --headless --path . --script res://tests/test_realm_rules.gd
godot --headless --path . --script res://tests/test_action_rules.gd
godot --headless --path . --script res://tests/test_item_rules.gd
```

On the tested Linux native run, the only driver warning was unsupported V-Sync mode switching. Audio was muted for deterministic capture; this is not a listening QA pass. Native Windows, other graphics vendors, screen readers, localization, long-duration campaign stability and multiplayer have not been verified here.

## Desktop checkpoint and presentation captures

The separately exported Linux 0.2 executable completed a fresh-data native 120-frame startup/render run with exit 0 and no script, rendering or leaked-resource diagnostics. The accepted renderer was X11 / OpenGL Compatibility / Mesa llvmpipe. Windows cross-export completed with exit 0, but Windows runtime behavior remains unverified.

The exported Linux headless startup also exits0, but short normal 10-frame and 30-frame forced quits report 8 leaked ObjectDB instances and 2 resources still in use. A targeted verbose short-quit diagnostic identifies Ogg playback/packet references from `chronicle.ogg` and `forest.ogg`. A 30-frame verbose run was clean; these results do not establish universally clean headless teardown. The native 120-frame run and the presentation harness have clean teardown. All attempts are preserved in `verification-logs/native-v02-exports.json` and its raw companion logs.

The final `render_manuscript_release.gd` presentation harness completed 12 checks with zero failures and five 1440×900 captures. It loads saves earned by the 101-check route, equips the earned cowl through the actual illustrated control and captures the town, construction folio, hero folio, oath ledger and live combat. The 12 presentation checks are recorded separately and are not added to the 101-check route. All five captures were inspected for framing, cropped controls and overlapping text. Evidence is in `verification-logs/manuscript-presentation.*` and `screenshots/manuscript-presentation/`.

The inherited virtual display had stopped before the rerun. Its proven-stale test lock/socket was removed and the same local-only portable Xvfb setup restarted. That initial display-unavailable attempt is retained separately. Neither this environment repair nor the exported-binary startup checks constitute a complete platform playthrough.
