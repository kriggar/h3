# Raven Hollow reference review — third-person reboot

Reviewed again on 22 October 2026. The exact `kriggar/raven-hollow` URL returns
404 through the connected GitHub API. The accessible related source,
[`kriggar/sangeroasa`](https://github.com/kriggar/sangeroasa), identifies Raven
Hollow as its town. Its inspected `master` remains pinned at
`3f9bd8da0a83c6b4b1028a49eaefe78d0980b041`.

The [README](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/README.md)
describes a single-player top-down Python/Pygame RPG. The inspected tree offers
no native 3D character rig or verified multiplayer backend to port. The related
[`raven-hollow-site`](https://github.com/kriggar/raven-hollow-site) is a presentation
site; screenshots and promotional claims do not establish server functionality.

## Patterns adopted independently

| Inspected source | Useful pattern in the new Godot implementation |
|---|---|
| `game/ui/hud.py`, `draw_wow_minimap` | Live minimap with actual entity positions |
| `draw_target_frame` | Selected enemy identity, level, health, and threat state |
| `draw_spell_bar` | Ability keys, cooldowns, costs, consumables, and XP |
| `draw_character_screen` | Equipment, character preview, and derived stats together |
| `try_unlock_skill` | Progression validation in rules, not cosmetic buttons |
| `game/items.py`, `build_item_tooltip_lines` | Rarity, slot, stats, and comparisons |
| `game/data/quests.py` | Intro quests that teach one mechanic at a time |

Sources: [HUD](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/ui/hud.py),
[items](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/items.py),
[quests](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/data/quests.py).

The new implementation does not derive item stats from artwork, freeze shared
simulation for local hit-stop, or reuse movement keys for abilities. The server
owns gameplay values; art presents those values.

## Rights and character

No top-level code license was found in the inspected reference tree. Its
[asset notice](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/assets/LICENSE.txt)
includes restrictions on the bundled 32rogues artwork. No code, sprites, music,
textures, or character files were imported from that repository.

Draconia retains its accepted `assets/models/mara/mara.glb`, licensed source
motions/materials, and independently implemented Godot systems. The corrected
camera requirement is **third-person**, not isometric.
