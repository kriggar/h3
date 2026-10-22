# Draconia — The Blackbriar March

**A native Godot third-person multiplayer RPG foundation.** One controlled hero,
an authored Eastern European fantasy borderland, deliberate sword combat, quests,
loot, character progression, and private realms. This is the replacement of the
earlier strategy/isometric runtime.

The accepted **Mara player model and all twelve source animation clips are
unchanged**. The active camera, world, interface, simulation, quests, progression,
and multiplayer session flow have been rebuilt around her.

![Actual native Godot gameplay](docs/online/screenshots/02-thornwatch-third-person.png)

## Download, import, play

1. [Download the complete project ZIP](https://codeload.github.com/kriggar/h3/legacy.zip/refs/heads/main).
2. Extract it into a writable folder.
3. In **Godot 4.7.2** (the tested version), choose **Import** and select the
   extracted `project.godot`. Wait for the first asset import to finish.
4. Press **F5**. Enter a character name and select **Enter the March**.
5. Walk to **Captain Elric**, beside the left watchhall, and press **F**.

All runtime models, textures, fonts, icons, and sounds are included. There are no
Git submodules, Git LFS pointers, runtime downloads, package-manager installs,
Blender requirements, or API keys needed to play. This uses native **GL
Compatibility**, not a browser wrapper.

## Controls

| Input | Action |
|---|---|
| W / A / S / D | Move relative to the camera |
| Hold left mouse + drag | Orbit the camera |
| Hold right mouse + drag | Orbit and steer the character |
| Mouse wheel | Zoom |
| Space | Physical jump using the existing movement pose |
| Tab / left-click an enemy | Select a hostile target |
| F | Speak, gather, or collect nearby personal spoils |
| 1 | **Swordfall** — targeted sword strike |
| 2 | **Mooncleave** — forward area sweep |
| 3 | **Iron Vow** — heal and temporary damage reduction |
| 4 | **Wayfarer's Step** — directional roll and a brief evade window |
| 5 | **Rowan Draught** — consume a carried healing potion |
| C | Character, equipment, and attribute points |
| I / B | Satchel and equipment |
| J / L | Quest journal |
| Enter | Realm chat; Enter sends, Escape cancels |
| Escape | Close a panel or open the game menu |

The world continues while menus are open. Use **Save & Return to Realms** or
**Save & Quit** to leave cleanly. Progress also saves periodically. The third-person
camera uses a collision-aware spring arm.

## What is playable

The region contains **Thornwatch**, the old forest road, the eastern emberbloom
wood, and the ruined seat of the **Hollow King**, a cursed varcolac. The three
authored quest chapters are:

1. **The Road of Teeth:** defeat the duskfang pack and earn Thornwatch Steel.
2. **A Light Against the Briar:** recover emberblooms and earn a Rowan Signet.
3. **The Hollow King's Due:** defeat the elite and claim the Fang of the Hollow
   King. Eligible contributors receive their own rewards.

There is one playable **Highlander Vanguard**, using the retained character. The
build includes three service/story NPCs, three enemy types, a named boss, five
hotbar actions, seven equipment definitions across weapon/chest/ring slots,
healing consumables, a merchant, personal loot, levels up to 20, and two spendable
attribute points per level. Equipment currently changes statistics; the accepted
character's visible outfit remains the same.

The interface includes the actual animated character in its portrait and equipment
sheet, player and target frames, a live minimap, objectives, cooldowns and costs,
item comparison tooltips, a combat/event log, actual connected-player frames, and
realm chat. Eight new painted icons and nine original synthesized sounds are bundled.

Four environment surfaces are prepared from user-supplied ground photographs:
packed earth, grass/clover, pebble paths, and weathered mineral stone on ruins.
They are applied with world-scale tiling, mip filtering, and soft terrain blends;
the exact sources and editing prompts are recorded in
[`assets/online/terrain/`](assets/online/terrain/README.md).

![Actual character sheet](docs/online/screenshots/03-character-sheet.png)

## Play together

One player selects **Host a Realm**. Others select **Join a Realm** using that
host's IP address and matching UDP port; the default is **24572**. For two instances
on one computer, use `127.0.0.1`. The realm allows **four adventurers total**,
including the listen-server host.

The server decides movement, enemy AI, damage, cooldowns, loot ownership, quest
rewards, equipment, and progression. Clients submit intentions and receive
confirmed snapshots. Network tests use independent native Godot processes.

For a dedicated host:

```bash
godot --headless --path /absolute/path/to/project -- --server --port=24572
```

A dedicated host has no local hero; players join it through the same interface.
Direct internet connections require the host's UDP port to be reachable. This
build does not configure routers, matchmaking, public accounts, or hosted shards.
Use it as a private realm with people you trust.

### Saves

Solo and hosted characters have separate saves beneath Godot's application user
data directory, in `blackbriar/`. The host keeps realm progression. Clients retain
an opaque reconnect key; using the same address/port and the same client user data
restores that host-owned profile. Names do not grant ownership of another hero.
Reconnect keys are not included in world snapshots.

Level, XP, currency, attributes, equipment, quests, and consumables persist.
Characters arrive safely in Thornwatch when entering a realm. Enemies, gathering,
and unclaimed loot start fresh when a realm restarts. This is not yet a continuously
hosted persistent MMO world.

## Verification and scope

See [the release review](docs/online/RELEASE_REVIEW.md) for exact results, native
screenshots, corrected issues, and reproducible commands. The new tests are
independent of the retired strategy-game tests. The network scenario exercises
two simultaneous remote clients and a server restart; four-player capacity is a
configured limit, not a load-test claim.

This is a **playable multiplayer RPG foundation**, not a finished AAA MMORPG or
an assertion of bug-free production quality. It does not yet contain multiple
complete regions, a class/race roster, dungeons, raids, a full visual armor catalog,
mounts, crafting, guilds, public authentication, or MMO-scale services. NPC and
creature art, terrain detail, an authored jump animation, sound design, equipment
appearance, deformation/secondary motion, and target-hardware performance still
need production work. The next milestone should deepen this region and its combat
before expanding content count.

## Project layout

- `online.tscn` / `game/online/main.gd`: shipped F5 entry and session menus.
- `game/online/catalog.gd`: content, terrain, and shared collision data.
- `game/online/realm.gd`: authoritative game simulation.
- `game/online/session.gd`: solo, ENet host/join, saves, and chat.
- `game/online/world.gd`, `scenery.gd`, `avatar.gd`: third-person presentation.
- `game/online/hud.gd`, `ui_*.gd`: native interface.
- `assets/models/mara/`: exact accepted character and dependencies.
- `assets/online/`: new icon atlas and sound assets.
- `tests/online/`: rules, network workers, UI, and rendered acceptance.

The earlier game remains in Git history at
[`4d24215`](https://github.com/kriggar/h3/tree/4d2421509561755f76c577ac6d7ba7c53f55a2b9).
Its strategy shell, town cards, arenas, sprite UI, and active tests are removed
from this version. Licensed raw art is reused in the new authored environment.

Raven Hollow supplied interaction/interface references. Its accessible Pygame
source was inspected; no unlicensed code or assets were copied. See the
[source review](docs/RAVEN_HOLLOW_REVIEW.md). Original code follows the
[MIT license](LICENSE.txt); third-party art keeps its own terms in
[asset credits](ASSET_CREDITS.md) and `assets/licenses/`.
