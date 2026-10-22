# Attribute progression — implemented rules

This module extends the native action slice after the immutable v0.2 checkpoint. It implements level and attribute arithmetic, transactions, save migration, and combat effects. It does not represent a complete level-1-to-30 campaign or a completed talent tree.

## Player rules

The single chosen protagonist begins at level 1 with three unspent points. Each new level grants three more. Level 30 is the cap, so the full lifetime budget is 90 points. Each score starts at 10 and can receive at most 40 invested points. Baseline scores do not add bonuses to the existing starter stats.

| Attribute | Effect per invested point |
| --- | --- |
| Might | +1 Attack; weapon attacks and Attack-scaling abilities use the result. |
| Finesse | +0.04 movement speed, applied to actual fixed-step movement. |
| Vitality | +6 maximum Health. |
| Spirit | +2 maximum Focus and +1 finite Ward absorption. |

Increasing a maximum never heals wounds or restores Focus. Level-up also preserves current pools. Safe rest can later fill the larger capacity. Item bonuses, completed rune recipes, and active set bonuses compose through `ItemRules.derive_stats`; no second attribute formula lives in the character sheet.

The cumulative XP threshold for level **L** is `100 × (L − 1) + 25 × (L − 1) × (L − 2)`. Level 2 requires 100 XP; level 30 requires 23,200. Award processing can cross several levels at once. Stored XP is capped, discarded overflow is reported, and no extra points appear after level 30.

The registered first Bellworn Vault extraction grants 120 XP. Duplicate callbacks and later visits to its persistent corpses grant no additional XP. Other repeatable dungeon progression is a separate content task; this implementation does not silently respawn the story reward.

## Transactions and reset

Allocation previews are read-only and return complete before/after ItemRules totals. Applying a draft costs points atomically. It spends no gold or realm watches. Unknown attributes, fractional or negative points, excessive investments, and unaffordable drafts fail without mutation.

The UI should pass the preview's revision to Apply. Allocation, reset, XP gain, and actual equipment/socket changes invalidate old revisions. A no-op re-equip does not. This prevents a preview containing old set or recipe bonuses from being applied as if it were current.

Allocation and reset are unavailable during a pending encounter or while the hero is incapacitated. Reset additionally requires the hero to be physically present in a friendly town. Reset is free through level 10. Above level 10 it costs `min(1,000, 50 × (level − 10))` gold. It refunds only previously invested points, does not advance time, and clamps current Health/Focus if the new maximum is lower. It never restores either pool. Reloading cannot bypass the point budget, fee, or revision checks.

## API contract

`RealmRules.attribute_catalog()` returns rows with `id`, `name`, `description`, `effects`, `base`, and `maxInvestment`.

`RealmRules.progression_view(state)` returns `level`, `xp`, `maxLevel`, `levelFloorXp`, `nextLevelXp`, `xpIntoLevel`, `xpToNextLevel` (remaining XP), `levelSpanXp`, `atCap`, `unspent`, `revision`, `allocations`, `attributes` (10 plus investments), `canAllocate`, `lockReason`, and `resetCost`. At the level cap, remaining XP and span are both zero.

`preview_attribute_allocation(state, changes)` accepts nonnegative point increments by attribute ID and returns `ok`, `message`, full `before`/`after` stat dictionaries, `pointCost`, `pointsRemaining`, and `revision`. `allocate_attributes(state, changes, expected_revision)` revalidates and commits the transaction.

`preview_attribute_reset(state)` includes `goldCost`, `refundedPoints`, `pointsRemaining`, and the complete stat comparison. `reset_attributes(state, expected_revision)` revalidates town ownership, physical presence, available gold, current investments, and revision before committing.

XP award processing is an internal authority helper called by registered outcome resolution. There is no UI action that accepts an arbitrary XP grant.

## Persistence and evidence

The initial progression change advances realm save version 1 to version 2. Authentic native v1 town, earned-equipment, and live-combat saves are checked before migration. Existing XP determines the new level and unspent budget. Inventory, equipment, wounds, Focus, companies, and the entire pending encounter dictionary are preserved. A legacy pending action can resume against its original registry; new points cannot alter it mid-encounter.

The v2 state validates the exact four allocation keys, whole bounded values, `spent + unspent = level × 3`, consistent XP/level, bounded revisions/reset counts, real item instances, and cached derived totals. The fractional movement total is canonicalized to four decimal places so strict pending-snapshot validation survives a JSON round trip.

Before class-identity integration, the isolated runs recorded **277 progression checks**, **247 existing realm checks**, and **73 existing item checks**, all passing. The progression suite includes actual melee damage, measured movement distance, finite Ward damage absorption, old live-action continuation, and a legal invested starter clear/extraction. That earned route reached level 2 with 120 XP, three new unspent points, 71 Health, and six Focus. Boundary fixtures test level-30 arithmetic and reset prices; they are not a full campaign playthrough. See `verification-logs/attribute-progression.json` and its raw logs for source hashes, exact commands, and limitations.

The later 181-check native hunt/sale route exercises the real Character draft/Apply controls, earned levels, equipment and saved continuation at three sizes. That bounded route does not certify every future talent panel, production art or normal-speed performance. Attributes never change identity or implement the proposed talent trees. See [VERIFICATION.md](VERIFICATION.md).

## Subsequent fixed-identity integration

Realm save version 3 adds Mara's fixed `oathwarden` class, `hearthborn` race, and `ashen_crown` faction, with only Cleave and Ward prepared. Both v1 and v2 saves migrate. Existing pending encounter dictionaries remain exactly unchanged, including an authentic v2 invested movement snapshot and a v2 committed-Ember snapshot. An already released legacy projectile finishes; new off-class commands are rejected. An old uncommitted forbidden windup cannot release or spend Focus, and an obsolete paused request is explicitly discarded.

Class permissions are checked in `ActionRules.create` and `ActionRules.submit`, independently of the hotbar. Conflicting class, race, faction, hero aliases, or prepared lists are rejected. Attribute resets cannot change identity. Fire and nature regression cases use the actual registered Vara Flint/Pyromancer and Cael Bracken/Druid identities.

The subsequent identity gate passed 134 identity, 277 progression, 201 action, 247 realm, and 73 item checks: 932 total, zero failures. See `verification-logs/hero-identity.json`. Catalog validation covers 156 canonical champions and distinct signatures, 20 assigned class concepts, eight races, and nine factions. Only Mara is selectable in the implemented campaign; the other champion choices, personal signatures, racial packages, and unsupported class mechanics remain explicit design targets. Thief and Rogue are separate concepts with different intended tools and combat roles; neither receives unimplemented borrowed magic.

## Current contract extension

Action save version 4 now adds a separately persisted repeatable hunt board and sale transactions. Its migration preserves the earlier progression and identity invariants, including unchanged pending snapshots. The current six-suite regression has 1,390 checks, including 277 progression and 134 identity checks; the initial version-two/version-three evidence above remains the history of those increments. [HUNT_CONTRACTS.md](HUNT_CONTRACTS.md) documents actual repeated completion XP, the 23,200-XP cap route and fixed reward persistence.
