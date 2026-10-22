# Repeatable solo hunt contracts

## Implemented scope

The current action prototype has a working repeatable expedition loop alongside its original, once-only Bellworn Vault story expedition. Mara remains the sole playable hero. Her class is Oathwarden, her supported abilities are Cleave and Ward, and her stationed companies never enter or take casualties from a solo hunt.

The board offers three curated contracts at a time. Each uses the existing native vault arena and existing Gloamfang actors, with different registered pack compositions and placements. They are not three newly built dungeon environments or a finished procedural dungeon system.

| Contract | Actual pack at tier 1 | Completion XP | Collected gold |
| --- | --- | ---: | ---: |
| The Briar Kennels | Two melee Gloamfangs and one leaping keeper | 120 | 150 |
| The Ashen Watch Cellar | Four melee Gloamfangs spread through the chambers | 135 | 165 |
| Moonfang Underpass | One melee scout and two leaping hunters | 150 | 180 |

Every contract also registers two item rewards: one gear item from a seven-entry rotation and one rune or gem from a four-entry rotation. The gear pool contains the socketed Notched Ironblade, four Bellworn pieces other than the story cowl, the Mistglass Pendant, and Watcher's Knot. Materials are Cinder, Stone, Gale, and Amber. The story-exclusive Vowkeeper and Bellworn Cowl are excluded. All rewards use actual `ItemRules` catalogue definitions and deterministic instance rolls; no displayed item is a decorative promise.

## Time, commitment, and return

The hero must physically be in a friendly town to depart. Entry costs exactly two realm watches, quoted on the card. The watches advance before action begins, using normal dawn production, rival recruitment, and obligations. Combat duration, pauses, and native rendering frames spend no additional realm watches.

Choosing a contract locks that contract until successful completion. Retreat and defeat preserve its actual enemy health, dead actors, collected rewards, and registered item rolls. Re-entry costs another two watches and creates a new attempt identity, while retaining the same contract identity and seed. Other offers remain visible but cannot replace the active contract.

The action engine must report clearing the pack and legally extracting before the realm awards completion XP. A kill alone does not give the contract's XP. A surviving partial withdrawal or a defeat gives no completion XP. Items and gold physically collected before either outcome remain collected under the existing expedition rules. Defeat uses the ordinary paid refuge recovery; it does not reset enemy losses or regenerate companies.

Successful extraction closes the contract, pays only the registered completion XP, and registers the next three offers. Spoils not physically collected are forfeited. The native shell asks for confirmation before completing a cleared hunt with remaining drops. Choosing to return for the spoils does not apply an outcome or modify the realm.

The Bellworn Vault's story location, original encounter serial, clear flag, claim ledger, and unique rewards remain separate. A hunt cannot mark that story complete, manufacture a story reward, or satisfy the vault-specific oath.

## Registered difficulty and progression

A new board's tier is the hero's earned level at the moment that board is registered. Existing unfinished contracts retain their tier; equipping a better item, loading, withdrawing, or gaining a level elsewhere does not reroll them.

For tier `t`, from 1 through 30:

- Maximum enemy Health is `round(baseHealth × (1 + 0.045 × (t − 1)))`.
- Enemy Attack adds `floor((t − 1) / 3)` to the template's base Attack.
- Enemy Armor adds `floor((t − 1) / 5)` to the template's base Armor.
- Contract XP adds `25 × (t − 1)` to the template's base XP.
- Collected gold adds `20 × (t − 1)` to the template's base gold.

The existing level system remains authoritative: levels 1–30, cumulative cap 23,200 XP, and three spendable attribute points per level including the initial three. Only `RealmRules` applies XP, using the registered contract; an outcome-supplied XP field cannot choose an award. At the cap, completed hunts still refresh the board and grant actually collected loot, while awarding zero additional XP or attribute points.

This is transparent initial tuning. It is not a claim of balanced endgame, broad encounter variety, or a finished campaign. The accepted automated route reached level 30 through 46 actual completions, using all three pack layouts, legal combat inputs, equipment earned on that route, and paid realm watches for rest. It then completed one further contract at the cap. This establishes that the progression loop is usable and bounded; it does not establish long-term human enjoyment or production balance.

## Inventory space and selling

The pack has a 128-instance limit. Before departure, the realm reserves enough free slots for every remaining registered item reward in the selected contract. A new hunt normally requires two free slots. A retreat after claiming one item requires one remaining slot on re-entry. Failed capacity checks spend no watches and do not change the active contract.

A completed friendly Market provides a small, functional way to make space. The hero must be physically in that town and have no pending expedition or recovery. Only an owned, valid, unequipped item can be sold. Selling pays the catalogue's fixed `value`, removes exactly that instance and any sockets it contains, advances the item transaction revision, and spends no realm watches. Existing crafting supplies are purchased at five times that value, so buying and selling them cannot multiply money. The original finite purchase stock does not restock when a hunt refreshes.

Selling never removes a reward's claim record. A sold hunt item cannot reappear through re-entry or a duplicate outcome. The UI presents the exact sale price and a keep-item option before final confirmation. No salvage system, variable merchant pricing, auction economy, or rare-item shop is implied.

## Public integration APIs

### Board and departure

`RealmRules.hunt_board(state)` is read-only and returns:

```text
generation, activeContractId, canChoose, lockReason,
offers, completedHistory, packSlotsFree
```

Each `offers` row contains:

```text
id, name, description, tier, quotedWatches,
xpReward, effectiveXpReward, goldReward,
rewardPreview, status, remainingEnemies, enemyCount,
attempts, canEnter, lockReason, completionNotice
```

`rewardPreview` contains actual deterministic item names, quality, statistics, roll seed, and catalogue ID, or an exact fixed gold amount. A preview does not create an owned instance. `effectiveXpReward` accounts for the current XP cap. `canEnter` and `lockReason` are the authoritative per-card availability fields.

`RealmRules.begin_hunt(state, contractId)` returns `{ok, message, pendingEncounter}` on success and a failure with no mutation otherwise. The registered encounter remains compatible with `ActionRules.create` and its ordinary live serialization API:

```text
kind: "dungeon"
contractId: persistent offered contract ID
id / encounterId: unique attempt ID
heroSnapshot: exact fixed hero, derived equipment and attribute state
playerCompanies: []
stationedCompanyIds: unchanged company IDs
enemies: persistent individual actors and remaining health
lootRewards: only still-unclaimed registered rewards
objective: {type: "dungeon_clear"}
objectiveDefinitionId: "hunt_clear"
stakesDefinitionId: "hunt_extraction"
sceneId: "bell_crypt"
seed, xpReward, committedWatch, quotedWatches, returnWatchId,
originLocationId, locationName, context, arena
```

The contract ID uses `hunt:{worldSeed}:{generation}:{slot}`. An attempt appends `:attempt:{attemptNumber}`. Stable item rolls depend on world seed, contract ID, and reward ID; they do not depend on attempt number. A claim uses the current encounter ID and registered reward ID, and its owned item instance adds the item ID.

`RealmRules.preview_reward(state, rewardId, itemId = "")` returns the exact pending reward instance or exact gold value. The grant path uses the same function, so previewed rolls and earned rolls agree.

### Resolution

Use the existing `RealmRules.resolve_encounter(state, encounterId, ActionRules.outcome(actionState))`. Its existing fields remain available. Hunt resolution additionally reports `huntCompleted` and `huntGeneration`; XP fields remain `xpGained`, `levelsGained`, and `level`.

The validator checks the registered contract, current attempt, hero resource limits, real actor identities, nonincreasing enemy health, objective progress and extraction, solo-company constraints, exact reward sources and amounts, unique claim IDs, item capacity, and bounded gold. Application occurs on a deep copy and commits once. A duplicate or stale callback cannot claim twice or replace a newer attempt. These are native game-state integrity checks; they are not a cryptographic anti-cheat system against someone rewriting the executable or every related field of a local save.

### Sale

```text
preview_item_sale(state, settlementId, instanceId)
  -> {ok, message, instanceId, name, gold, revision}

sell_item(state, settlementId, instanceId, expectedRevision = -1)
  -> {ok, message, gold, instanceId, revision}
```

Pass the preview's revision into final confirmation. A changed equipment or attribute revision invalidates that quote. Both functions recheck ownership, location, equipped status, Market availability, and transaction bounds.

## Persistence and limits

The action realm schema is now version 4. Versions 1, 2, and 3 remain readable. Migration adds one fresh board at the hero's earned current level, while preserving original pending encounter dictionaries exactly. Six authentic earlier-version fixtures cover town state, earned equipment, live movement, a previously committed off-class projectile, and a legal Oathwarden Ward. Existing class migration rules still allow already committed legacy effects to finish without authorizing new off-class skills.

The persistent board stores its version, generation, registered tier, active contract, three full offer records, and a rolling completion history. Each offer stores its immutable definition, remaining enemy Health, attempt and last-applied attempt counters, claimed reward IDs, and claim IDs. Validation regenerates immutable content from world seed, generation, slot, and tier, then checks the explicitly mutable fields.

History retains the newest 32 completed contracts. Generation is bounded to 1,000,000 and attempts per contract to 10,000; a full archive is explicitly rejected before departure. Save size, item count, money, and progression limits retain the existing realm bounds. These limits prevent unbounded persistence growth; they are not presented as a million distinct authored locations.

## Verification

The clean rule regression is recorded in `docs/verification-logs/hunt-contracts.json` and the adjacent `hunts-*.log` files. It contains 1,390 checks with zero failures:

| Suite | Checks |
| --- | ---: |
| Hunt contracts | 458 |
| Existing realm rules | 247 |
| Attribute progression | 277 |
| Fixed hero identity and class permissions | 134 |
| Item rules | 73 |
| Action rules | 201 |

The hunt suite includes all three earned starting completions; actual partial-loot retreat; actual incapacitation and recovery; re-entry without corpse revival or item rerolls; duplicate callbacks; failed outcome atomicity; strict registered-save rejection; six authentic earlier-schema migrations; a built Market, stale sale quote, fixed-price sale and exact 128-item boundary; and the actual 46-contract route to the level cap. No fake outcome or injected XP is used for the earned routes. Synthetic, valid full-pack instances are isolated to the explicitly labelled capacity-boundary test.

Run a rule suite with the official Godot binary and fresh writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` directories:

```bash
godot --headless --path /path/to/Draconia --script res://tests/test_hunts.gd
```

Native GUI acceptance is a separate harness, `tests/render_hunt_ui.gd`, using real `Input` clicks and actual Godot viewport captures. It passed 181 checks with zero failures and produced 12 inspected captures at 1440×900, 1280×800, and 960×640. The report, exact run command, raw engine log, and genuine live/earned saves are stored under `docs/verification-logs/hunt-ui-native*` and `hunt-native-*`; captures are in `docs/screenshots/hunts/`.

That native route purchases the Granary and Market through real controls, commits the initial three attribute choices, takes the first contract, saves and resumes its live fight, clears the pack through legal commands, cancels a spoils-forfeit warning, physically collects all three drops, and extracts for level two. It then selects the earned item in the pack, exercises both the keep and sell choices, verifies the exact sale, saves and restores the resulting campaign, and rests through the normal town control. A second different contract is actually cleared; the explicit leave-spoils choice forfeits its uncollected drops while correctly granting the registered 160 XP, reaching level three at 280 total XP and refreshing generation three.

The native log has no script errors or GPU/resource-leak diagnostics. Its sole warning is the virtual display's unsupported V-Sync setting. The captures have no viewport overflow; narrow contract boards deliberately use vertical scrolling. A small existing presentation issue was reported separately: the town's status footer can retain the previous dungeon's input hint after return. The interface and production art remain subject to user review; this acceptance route does not certify finished materials or the full campaign.
