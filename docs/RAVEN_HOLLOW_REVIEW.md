# Raven Hollow reference review

## What was inspected

The requested URL was `https://github.com/kriggar/raven-hollow`. The repository
lookup made during this session returned 404. Related public work was found
under `kriggar/sangeroasa`, with the Raven Hollow presentation site in
`kriggar/raven-hollow-site`. The inspected game source was pinned to commit
`3f9bd8da0a83c6b4b1028a49eaefe78d0980b041`; this review does not silently
identify a different repository as the original requested one.

The selected source files use Python and Pygame surfaces. They are useful
references for character-sheet information, item tooltips and combat
feedback, but are not a source of Godot scenes or production 3D character
rigs. The review retained selected files outside the distributable project
for read-only inspection. No source code or image assets from that repository
are included in Draconia's runtime or source archives.

## Decisions for Draconia

| Observed pattern | Decision in our implementation | Status |
|---|---|---|
| Character information and equipment slots presented together | A manuscript folio surrounds the actual Godot character with eleven equipment slots, derived attributes and explicit item comparisons | Implemented for Mara |
| Class-specific spell presentation | Mara's hotbar and action rules allow only the supported Oathwarden skills; class identity is authoritative below the interface | Implemented; twenty-class roster is largely design-only |
| Item tooltips show rarity, slot, statistics and set identity | Show the actual seeded instance, affected slot, stat difference and equipped-set thresholds | Implemented for the bounded item catalog |
| Skill-tree state distinguishes locked, available and owned | Keep our planned class trees readable with explicit prerequisites and point costs | Design-only; no implemented twenty-class talent-tree claim |
| Combat feedback has a dedicated presentation layer | Our original Godot feedback maps actual committed ability events to matching icon, VFX and sound without duplicating rules damage | Implemented for the current four effect fixtures; Mara uses two |
| Generated item power can depend on sprite/image metrics | Reject that dependency: item definitions and seeds determine power; artwork depicts the resulting item | Implemented authoritative item rules |

These are common interface and rules concepts interpreted in Draconia's own
art direction and architecture. The implementation is original GDScript; it
is not a port of the inspected Python functions.

## Why the character sheet is a native 3D folio

The user asked for this functionality in our own style. The resulting view
uses warm parchment, dark engraved framing, painted icons and a live 3D
character. Rotation and zoom operate on the actual rig. Equipping Vowkeeper
or the Bellworn Cowl changes the same registered model assembly used in the
dungeon. Other item definitions can affect statistics without implying that
all fitted armor meshes are complete.

Attribute allocation is a draft until Apply. The preview derives the result
through the same item/progression rules as combat. Reset quotes its actual
cost; spending or resetting points never heals the hero. Combat inspection
pauses the action and locks changes that require town. The collection panel
distinguishes collected pieces, equipped pieces and active set thresholds.

The current progression, identity, hunt and item rules have independent
evidence in [VERIFICATION.md](VERIFICATION.md). This reference review is not
itself a gameplay test or a claim of completed character systems.

## Reuse boundary

No repository-wide code license was found in the inspected metadata. The
selected asset notice identifies Seth Boyles's **32rogues** artwork and
contains restrictions on redistribution and use with generative AI or
machine-learning projects, as well as NFT/blockchain exclusions. Those
assets were not imported, transformed or redistributed. A public repository
alone was not treated as permission to ship its contents.

Draconia instead uses its own authored interface, its original equipment and
building geometry, and separately recorded licensed material/character
sources. [ASSET_CREDITS.md](../ASSET_CREDITS.md) lists those sources.

## Pinned source references

- [Game repository at the inspected commit](https://github.com/kriggar/sangeroasa/tree/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041)
- [HUD and character-interface source](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/ui/hud.py)
- [Item inspection and sprite-derived item generation](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/items.py)
- [Combat feedback layer](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/combat/feedback.py)
- [Gameplay math](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/game/gameplay_math.py)
- [Selected asset license notice](https://github.com/kriggar/sangeroasa/blob/3f9bd8da0a83c6b4b1028a49eaefe78d0980b041/assets/LICENSE.txt)

These references identify the observed code and notice, rather than granting
rights beyond their actual terms.
