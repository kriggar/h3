# Draconia: naming and visual direction

Revision: 22 October 2026. This records the user's current direction. It supersedes the earlier literal translations and the two rejected close-up portraits. Names below are working original fantasy names; they have not undergone trademark clearance. Stable internal identifiers may retain historical spellings without appearing in the interface.

## Language and world

All player-facing names and text are English or invented fantasy names that are easy to read in English. The world has a Romanian heartland and draws on distinct Eastern European folklore traditions. It is high fantasy with grounded people, weathered settlements, dangerous bargains and consequential monster contracts. It does not use the named characters, setting, factions or artwork of the reference games.

The first implemented hero is **Mara Veyne**. The full design has 156 hero concepts: 144 standard choices (16 for each of nine factions) and 12 story characters. The player chooses exactly one hero at campaign start and controls that character for the entire campaign. There is no player hero recruitment, hero swapping, second playable army leader, or playable-heir succession. Other heroes supply future campaign choices, rivals and story characters. Counts are production targets, not completed content. The title remains **Draconia - Oaths of the Carpathians** as a working title.

| Faction | Capital | Regional name | Folklore/design root |
| --- | --- | --- | --- |
| The Ashen Crown | Dawnreach | The Ashen March | Fortified principalities, communal defense, oathbound nobility |
| The Thornweald Court | Briarhollow | The Thornweald | Enchanted woodland, dangerous dances, reciprocal forest bargains |
| The Cloudspire Conclave | Stormcairn | The Cloudspires | Weather sorcerers, mountain schools, bound sky creatures |
| The Vesper Court | Duskharrow | The Mourning Vale | Restless dead, immortal houses, blood and inheritance |
| The Gloamfang Clans | Fangrest | The Moonscar Peaks | Wolf transformation, pack loyalties, hunger and restraint |
| The Emberhorn Dominion | Cindervault | The Copper Wastes | Giant lords, bronze palaces, fantastic beasts and pride |
| The Reedbound League | Reedhaven | The Mirrorwater Delta | Water spirits, river communities, drowned memories |
| The Ironroad Compact | Crossmere | The Ninefold Road | Border towns, craft guilds, trade and negotiated freedom |
| The Deepcairn Pact | Stonewake | The Understone Holds | Stone memory, underground communities, patient engineering and ancestral debts |

Working creature names include **Gloamfangs**, **Veilkin**, **Gravewights**, **Tempest Sages**, and **Crownwyrms**. Research notes may record folklore source terms; the ordinary game interface uses the fantasy names.

## Authoritative illustration reference

The user explicitly supplied and selected the original character sheet, available at `upload/54a74735-e880-4bce-890a-0a3d41193e62.png`. Its project counterpart is `assets/generated/manuscript-portraits.png`.

Preserve the sheet's flat inked half-figures, crisp outlines, restrained hatching and shading, muted red/blue/green clothing, clear silhouettes and plain warm parchment. This style applies to character cards, creature cards, building illustrations and story panels. Manuscript craftsmanship is the reference, without halos, saint framing or religious ornament around a portrait.

The later gilded-arch portrait and painterly woodland bust were rejected by the user. They are not approved runtime assets. Style approval of the original sheet does not approve its anatomical defects: the original hero has an extra hand and must be corrected before reuse in the rebuild. See `IMAGE_QA_REJECTIONS.md` for the other blockers.

## 3D world and equipment

The actual world, towns, hero, creatures and combat use 3D geometry with animated rigs. A 2D card illustration is a UI asset and cannot stand in for an accepted 3D actor. The world is naturalistic in materials and scale, with visible fantastic creatures and magic. Gear changes must eventually update the hero's fitted 3D equipment; a tooltip alone does not satisfy that production gate.

## Rules settled by the user

- Exactly one hero chosen from the roster for the entire campaign; up to six companies in field battles.
- Direct real-time action combat, using one compatible engine for field battles and solo dungeons.
- Dungeons contain the hero alone. The army waits outside and keeps its own state.
- Dedicated 3D town views: buying a building visibly adds it to its persistent site. Upgrades visibly change it.
- Common town buildings complete immediately on purchase, with a short presentation animation and a persistent one-build-per-town-per-day limit.
- Diablo II-like loot structure: useful normal/socketed bases, magic, rare, set and unique items, gems, runes and original rune recipes. Exceptional uniques fulfil the requested legendary fantasy.
- Armor sets use five armor pieces and two/four-piece bonuses; mixed equipment remains viable.
- Every feature, panel, illustration and animation requires implementation, meaningful verification and native visual inspection before acceptance.

New user steering changes this document before it changes derived catalogs. New counts elsewhere are production targets, not implemented content claims.

## Additional influences requested

Crusader Kings II/III informs personal relations, noble houses, claims, councils and negotiated obligations. Mount & Blade / Bannerlord informs battlefield presence, company morale, veteran identity, prisoners and mercenary contracts. Stronghold Crusader informs functional walls, gates, towers, supply and castle economies. These are design interpretations. They must fit the one-hero campaign, visible town construction and shared action system. No feature is counted complete until its consequences actually work.
