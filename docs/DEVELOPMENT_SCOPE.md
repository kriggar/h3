# DRACONIA — development scope

## What this build contains

**This is the first complete, playable campaign of an original Godot strategy game. It does not have the breadth, content volume, or feature completeness of Heroes of Might and Magic III.** The user's requested target remains a full Romanian folklore strategy game with comparable breadth and strategic depth. The current campaign is a foundation toward that target. The remaining systems, content and acceptance gates are specified in [PRODUCTION_PLAN.md](PRODUCTION_PLAN.md); completing this first campaign does not complete the full request.

The current campaign follows Ileana across a seeded 36 × 26 adventure map, with three towns, ten fixed encounters, four resource mines, twelve resource caches, two treasure chests, and three guarded oath sites. The player develops towns, recruits troops, explores under fog, fights tactical battles, restores the oaths, and defeats the final fortress. The rules have been exercised through three complete automated playthroughs using the same tactical rules as the interactive battle screen. See [campaign rules](../game/campaign_core.gd) and [campaign tests](../tests/test_campaign.gd).

The distinctive rule is an alternating **three daylight days and two nights**. Unrestored oaths increase enemy attack at night. Restoring the woodland, river, and mountain oaths reduces corruption, restores mana, weakens the fortress garrison, and eventually breaks the final seal. Night victories award 25% additional gold and experience. Restoring the woodland oath also allows the player to build a sacred grove and recruit Iele. These are implemented mechanics that affect battle calculations and campaign state.

## Feature matrix

| Area | Implemented in this build | Remaining for the larger production game |
| --- | --- | --- |
| Engine and presentation | Native Godot 4 project; 3D adventure and battle environments, terrain/cameras/lighting and downloaded scenery; one animated 3D Vârcolac model; other troops use animated billboards; wood/bronze frames and manuscript portraits | Complete coherent 3D creature roster, broader terrain/town art, production animation/effects, performance and presentation polish |
| Campaign content | One original campaign in the fictional Romanian-inspired realm of Draconia; a defined beginning, progression, and victory | Multiple linked scenarios, branching campaigns, additional stories and regional content |
| World map | Seeded terrain variations on a designed 36 × 26 layout; roads, bridges, terrain costs, fog, path previews, resource sites | Arbitrary map sizes, underground maps, sailing, teleport networks, complex adventure interactions, a full random-map generator |
| Hero management | One controllable hero, experience, ten levels, and three skills with three ranks each | Multiple recruitable heroes, hero classes, specialties, army transfers, taverns, broader skill development |
| Economy | Seven resources; daily town/mine income; spending validation; weekly recruitment growth | Markets, caravans, trade rules, event-driven economy, faction-specific production and broader economic balancing |
| Towns | Three towns and six building definitions; prerequisites, costs, one construction per town/day, recruit stock | Distinct faction town trees, seven-tier creature dwellings and upgrades, garrison/visiting-hero management, siege-specific town defenses |
| Units | Ten unit types, including Vârcolaci, Iele, Solomonari, Strigoi, and Balauri; six recruitable types | Multiple full factions with seven base tiers and upgrade branches; a much larger creature and ability catalogue |
| Army formation | Up to seven type stacks; recruitment merges matching types; persistent casualties | Manual stack splitting/reordering, transfers between heroes and towns, broad army-management tools |
| Tactical movement | Offset hex grid, speed-limited movement, occupancy and obstacles, flying movement | Double-width creatures, additional terrain effects, siege gates, a larger battlefield/obstacle catalogue |
| Tactical actions | Melee, ranged attacks, ammunition, long-range/melee shooting penalties, retaliation, wait, defend, withdrawal, battle AI | Morale/luck systems, extensive creature specials, siege engines, advanced statuses, broader tactical AI and difficulty options |
| Magic | A damage spell and a healing spell, mana, spell-power scaling, one hero spell per round | Schools and mastery, a large spell book, targeting categories, persistent buffs/debuffs, adventure magic, research and spell acquisition |
| Artifacts | An ancestral waystone grants a permanent spell-power reward | Inventory, equipment slots, artifact sets, consumables, a large item library |
| Enemy campaign activity | Ten fixed guarded encounters; battle AI; casualties persist after withdrawal/defeat | Opposing strategic players, roaming heroes, town capture/recapture, recruitment and economic planning by overworld AI |
| Oath/day-night system | Three guarded permanent wards, corruption, battle modifiers, night rewards, Iele unlock, sealed final fortress | More oath choices, faction interactions, encounter variety, narrative consequences, expanded testing across new campaigns |
| Defeat and recovery | Return to the home town; gold fee; movement exhausted; small recovery force after a total loss | Scenario-specific defeat rules, surrender/ransom options, stronger strategic consequence design |
| Persistence | Versioned JSON state, validation, migration from the earlier version-1 campaign, local save/load and import/export integration | Multiple named save slots, campaign-wide progress, migrations for future schemas, platform-specific save QA |
| Authoring tools | Campaign data is readable in GDScript; reproducible atlas-generation scripts and manifests | In-game scenario editor, terrain/object editing, campaign authoring UI, mod packaging and validation tools |
| Multiplayer | Single player only | Hotseat, network synchronization, lobby, reconnect, desync/replay tools, multiplayer balance |
| Audio and accessibility | Interface feedback, optional CC0 instrumental music and forest ambience, help/controls and readable status information | A larger soundtrack and soundscape, broader audio production, localization, accessibility settings and a wider device/input test matrix |
| Fidelity to Heroes III | Familiar strategy-game structures, independently implemented rules and original campaign | No claim of binary compatibility, exact original rules, original map/save loading, or exhaustive feature parity |

The remaining column is part of the full-production target. [PRODUCTION_PLAN.md](PRODUCTION_PLAN.md) makes that work concrete through nine faction rosters, seven base tiers and upgrades per faction, heroes, magic, artifacts, campaigns, strategic AI, sieges, editing, multiplayer and presentation. It distinguishes proposed content from working features and defines implementation order without inventing completion dates.

## Maintainable architecture

| File | Responsibility |
| --- | --- |
| [game/campaign_core.gd](../game/campaign_core.gd) | Authoritative adventure state, map generation, pathfinding, object interactions, economy, towns, skills, oaths, battle-result application, and save validation |
| [game/battle_rules.gd](../game/battle_rules.gd) | Shared tactical geometry, movement, damage, initiative, AI decisions, casualties, spells, and deterministic simulation |
| [game/battle.gd](../game/battle.gd) | Interactive battle controls and asynchronous action execution using the shared rules; native 3D SubViewport, terrain, scenery, camera projection, model/billboard animation and tactical overlays |
| [game/main.gd](../game/main.gd) | Application flow, panels, user commands, battle/campaign integration, persistence UI and victory presentation |
| [game/map_view.gd](../game/map_view.gd) | Adventure view controller, camera interaction, tile selection, path overlays and travel animation |
| [game/world_3d.gd](../game/world_3d.gd) | Native adventure terrain, water, roads, bridges, scenery, lighting and 3D camera rendering |
| [game/art.gd](../game/art.gd) | Runtime atlas/animation lookup and drawing helpers |
| [game/ui_theme.gd](../game/ui_theme.gd) | Shared fonts, palette, visual styling and UI construction helpers |
| [game/ui_frame.gd](../game/ui_frame.gd) | Textured wood/bronze frame styling shared by native panels and controls |
| [assets/animated/animations.json](../assets/animated/animations.json) | Frame rectangles, timing, anchors and display scaling for the ten animated unit atlases |

Campaign state consists only of JSON-compatible dictionaries, arrays, strings, booleans and numbers. Rendering objects, textures, nodes and RNG objects do not enter saves. Public rule functions validate the requested action before committing its costs and effects. Their `{ok, message, ...}` result gives the UI one authoritative outcome. Failed movement, recruitment, building and invalid battle-result requests are tested for unchanged state.

The core exposes static snake_case functions, while existing dictionary keys retain camelCase for compatibility, including `maxMana`, `maxMovement`, `builtDay`, `skillPoints` and `totalCost`. The save version is **2**. New save schemas should receive a deliberate migration and regression fixtures rather than silently reinterpreting old fields.

The battle handoff contains `{victory, retreated, army, mana, xp, enemyRemaining}`. The campaign core validates surviving troop counts, preserves casualties/mana, and owns campaign rewards and level-ups. Tactical `xp` is a battle estimate; the campaign pays its configured encounter reward, including any night multiplier. Presentation must not award it a second time.

Unit keys such as `griffin`, `wolf` and `knight` are stable data identifiers. Their displayed roles are Iele, Vârcolac and Cavaler. The corresponding art is a wingless forest spirit, an actual werewolf, and an armored foot soldier. Renaming a key requires a save/content migration. New content should use explicit identifiers and definitions rather than deriving mechanics from the picture filename.

## Verification and commands

Run from the project directory on Linux with a Godot binary available as `godot`. This project was checked with **Godot 4.7.2 stable**. The application suite creates and clears test saves; isolate all three XDG locations in a fresh directory and keep these exports inside a subshell:

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

The editor invocation imports resources and registers global GDScript classes. The app test checks that its user-data path begins with `/tmp/draconia-app-test` before touching any save. Preserve that guard. The temporary test files remain for inspection, and the subshell leaves normal play's environment unchanged. Launch `godot --path .` outside this subshell to use ordinary player progress. See [VERIFICATION.md](VERIFICATION.md) for platform-specific results.

Current component-test evidence:

- **Campaign:** 14 groups, **977 checks, zero failures**. Covers deterministic/reachable map content; water, mountains, guards and diagonal corners; movement costs; one-time collection; income/growth; recruitment/build transactions; mana rest; night modifiers; ward/finale gating; casualties and recovery; skill choices; malformed save rejection; version-1 migration; and three complete campaigns.
- **Real tactical campaign runs:** seeds **711, 1337 and 2026** each won all ten battles, captured both additional towns and restored all three wards on day **10**, without injected resources, teleported travel or free reinforcements. They bought troops/buildings with campaign income, paid actual movement costs, applied real battle casualties, spent earned skills, and reloaded saves during the campaign and after victory.
- **Finale balance in those runs:** all three final battles took four rounds. Remaining army maximum-HP totals fell from 1,190 to 840, 1,040 to 700, and 1,100 to 745. These measurements demonstrate a winnable tested route with meaningful losses; they do not prove every player strategy or seed is balanced.
- **Tactical component/UI:** **81 checks, zero failures** reported by `test_battle.gd`, including manual spell/wait/withdrawal handling, the real asynchronous `BattleScreen` controller, and equality of seeded UI-controller/simulator casualties, mana and rounds.
- **Native application integration:** **126 checks, zero failures** reported by `test_app.gd`. It loads the real application scene and exercises button signals, map mouse input, town recruitment/building, resource movement, save validation/autoload, native file-dialog import/export callbacks, and actual introductory/final `BattleScreen` AI battles through Main's result handler. The legitimate final-approach fixture reaches the victory modal; its seeded final battle matches the shared simulator's survivors, mana and four-round result. This is application/controller integration coverage, not a completed cross-platform export test matrix.

A legitimate pre-final fixture can be regenerated by replaying the entire tested campaign:

```bash
godot --headless --path . --script tests/test_campaign.gd -- --write-fixture
```

This writes [tests/fixtures/final-approach.json](../tests/fixtures/final-approach.json) from the seed-711 run. With the optional fixture checks, the result is **979 checks, zero failures**. It contains a level-8 Ileana at the fortress on day 10, three earned wards, actual surviving troops, and no victory flag. This supports application integration tests without inventing completed quest state.

Automated rule/controller tests do not substitute for visual inspection, human usability testing, exported-build testing or a broad hardware matrix. A ten-day automated campaign is not a measured human completion time. User-visible application/export checks should be reported separately with their actual platform and result.

The revised battlefield has also been inspected in actual Linux/Mesa-rendered views at several sizes, in daylight and night conditions, and with the inspection camera turned. Its five capture configurations passed 825 projection-to-hex round-trip checks. This is separate geometric/view evidence, not another 825 campaign or combat tests. The scanned fortress in the final battle is scenery; siege mechanics remain in the production plan.

## Production implementation sequence

1. **Strengthen the first campaign:** complete application/export QA, gather player feedback, improve clarity, tune difficulty, and stabilize saves and deterministic fixtures.
2. **Build strategic depth:** introduce multiple heroes, army transfers, opposing overworld AI, reusable scenario data and additional town interactions. Preserve explicit action validation and add campaign-level scenarios for capture, defeat and recovery.
3. **Add coherent factions:** define each faction's seven tiers and upgrades, town tree, recruitment identity, specialties and licensed art before multiplying scenarios. Extend ability/spell systems through data and effect handlers.
4. **Broaden content and authoring:** spells, artifacts, additional campaigns, map-generation rules and a scenario editor. Treat content validation as part of the build.
5. **Implement multiplayer once deterministic state is stable:** use versioned actions, replayable state transitions and desync diagnostics, then add hotseat, network transport, lobby and reconnect features.

The expanded [production plan](PRODUCTION_PLAN.md) defines the full content target and measurable gates for this sequence. These stages organize the remaining work; they do not reduce the requested game to the current campaign.

Original game research is summarized in [RE_FINDINGS.md](../research/RE_FINDINGS.md). Downloaded-art attribution and adaptation licenses are recorded in [ASSET_CREDITS.md](../ASSET_CREDITS.md). No original Heroes III executable, archive, extracted art or text table is required by this Godot game.
