# Fixed classes, races and individual champions

**v0.3 design/rules boundary.** The source catalog is [class_catalog.json](../data/class_catalog.json); all 156 champion mappings are in [hero_roster.json](../data/hero_roster.json). `HeroIdentity` enforces a chosen hero's canonical class/race/faction. This is not a character-selection screen: **only Mara Veyne is presently playable**.

Twenty fixed classes define distinct legal skill pools. The original two-per-faction plan is expanded by a Vesper Rogue and Ironroad Thief, without adding more heroes: the roster still contains 144 standard and twelve story identities. Every identity has a unique authored personal signature. Eight racial packages are independent of faction/class. All signatures, racial passives/situational traits and class-resource disciplines are **design-only**, including Mara's Answer the Bell, Hearthborn package and Oathmarks.

The supported-skills column means those action effects may be used by a canonical fixture of that class. It does not mean that class's complete kit, character, story or art is playable. Mara is an Oathwarden with Cleave/Ward. `vara_flint` tests Pyromancer Ember and `cael_bracken` tests Druid Living Roots. There is no release all-spells debug class.

## Authoritative class map

| Class | Home faction | Legal talent families | Current supported action skills |
| --- | --- | --- | --- |
| Warlord | The Ashen Crown | Steel / Command | Cleave |
| Oathwarden | The Ashen Crown | Steel / Oaths | Cleave, Ward |
| Ranger | The Thornweald Court | Hunt / Steel | None; design only |
| Druid | The Thornweald Court | Rites / Hunt | Living Roots |
| Spellblade | The Cloudspire Conclave | Steel / Storm | Cleave |
| Stormcaller | The Cloudspire Conclave | Storm / Rites | None; design only |
| Death Knight | The Vesper Court | Steel / Oaths | Cleave |
| Necromancer | The Vesper Court | Rites / Oaths | None; design only |
| Berserker | The Gloamfang Clans | Steel / Hunt | Cleave |
| Moon Witch | The Gloamfang Clans | Rites / Hunt | None; design only |
| Reaver | The Emberhorn Dominion | Steel / Command | Cleave |
| Pyromancer | The Emberhorn Dominion | Rites / Storm | Ember |
| Wayfinder | The Reedbound League | Hunt / Command | None; design only |
| Tidebinder | The Reedbound League | Rites / Storm | None; design only |
| Marshal | The Ironroad Compact | Command / Steel | Cleave |
| Runemage | The Ironroad Compact | Rites / Command | None; design only |
| Stoneguard | The Deepcairn Pact | Steel / Oaths | Cleave |
| Earthshaper | The Deepcairn Pact | Rites / Command | None; design only |
| Thief | The Ironroad Compact | Hunt / Command | None; design only |
| Rogue | The Vesper Court | Hunt / Steel | None; design only |

## Separate tools for a Thief and a Rogue

The **Thief** is an Ironroad infiltrator. Reconnaissance identifies real locks, traps, alternative entries and optional loot; a bounded tool supply opens an opportunity. A marked lock/container/target has a registered once-only result. False Sound diverts investigation, Smoke Bomb conceals an escape, Tripwire prepares a route and Escape Line uses a valid visible anchor. A Thief does not create items by repeatedly pickpocketing the same enemy. Mandatory campaign progression must retain an alternate route for other classes. Tools, objective support and escape remain useful when nothing can be stolen.

The **Rogue** is a Vesper precision combatant. A real flank, interruption or timed evasion opens one target; a short-lived opening can pay for a precise finisher and expires on a switch. Backstab needs an earned angle, Venom Edge uses bounded damage with explicit immunity, Hamstring cannot produce permanent boss control, and Throat Feint trades commitment against an enemy tell. The Rogue does not automatically gain the Thief's keys, tool economy or optional loot rights. Both are design-only now and have empty `supportedSkills` lists; neither borrows Ember, Roots or Ward as a temporary generic kit.

## Twenty class briefs

The six planned skills per class below are **120 authored catalog entries**, not 120 implemented abilities. Names identify design slots; exact costs, timing, acquisition, solo/field behavior, counterplay, UI, audio and native motion must pass their own acceptance gate. A shared talent family provides an effect vocabulary, not permission to learn every action associated with that label.

### Warlord

Command the fight through positioning, weapon pressure and rally orders.

- **Fixed class ID:** `warlord`; **home faction:** The Ashen Crown.
- **Class-scoped families:** Steel / Command; **equipment identity:** swords, axes, polearms; medium or heavy armor.
- **Proposed discipline — Momentum:** Gain momentum by completing ordered advances or counters; spend it on a committed command. **Design only.**
- **Planned skill IDs:** `rallying_cut`, `hold_the_line`, `shield_breaker`, `forced_march`, `challenge`, `battle_standard`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Oathwarden

Protect a chosen space and turn a successful defense into a counterattack.

- **Fixed class ID:** `oathwarden`; **home faction:** The Ashen Crown.
- **Class-scoped families:** Steel / Oaths; **equipment identity:** swords, maces; medium or heavy armor.
- **Proposed discipline — Oath marks:** Sworn ground rewards guarding and measured retaliation; abandoning it gives up the stored benefit. **Design only.**
- **Planned skill IDs:** `cleave`, `ward`, `vowstrike`, `sanctuary_line`, `reckoning`, `unbroken_oath`.
- **Currently supported action effects:** Cleave, Ward. The rest of the class remains unimplemented.

### Ranger

Choose a quarry, shape its approach and strike from a prepared angle.

- **Fixed class ID:** `ranger`; **home faction:** The Thornweald Court.
- **Class-scoped families:** Hunt / Steel; **equipment identity:** bows, spears, paired blades; light or medium armor.
- **Proposed discipline — Quarry:** Tracking an actual target builds one bounded opening; changing quarry loses the old opening. **Design only.**
- **Planned skill IDs:** `marked_shot`, `barbed_snare`, `withdrawal`, `split_shot`, `brushwalk`, `hunters_patience`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Druid

Use living ground, roots and seasonal exchanges to change the battlefield.

- **Fixed class ID:** `druid`; **home faction:** The Thornweald Court.
- **Class-scoped families:** Rites / Hunt; **equipment identity:** staves, sickles; light armor.
- **Proposed discipline — Growth:** Cultivate visible patches, then consume their growth for control or recovery. **Design only.**
- **Planned skill IDs:** `roots`, `briar_shelter`, `sap_mend`, `thornburst`, `autumn_exchange`, `grove_awaken`.
- **Currently supported action effects:** Living Roots. The rest of the class remains unimplemented.

### Spellblade

Weave close weapon strikes with brief storm charges and precise repositioning.

- **Fixed class ID:** `spellblade`; **home faction:** The Cloudspire Conclave.
- **Class-scoped families:** Steel / Storm; **equipment identity:** swords, spears; light or medium armor.
- **Proposed discipline — Charge:** A completed weapon pattern prepares a charge; spend it on one named arcane follow-up. **Design only.**
- **Planned skill IDs:** `arc_cut`, `windstep`, `conductive_edge`, `catch_bolt`, `storm_lunge`, `overload_edge`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Stormcaller

Read a visible forecast and place wind, rain and lightning deliberately.

- **Fixed class ID:** `stormcaller`; **home faction:** The Cloudspire Conclave.
- **Class-scoped families:** Storm / Rites; **equipment identity:** staves, rods; light armor.
- **Proposed discipline — Pressure:** Wind and rain spells build a forecast; discharge it along telegraphed storm lanes. **Design only.**
- **Planned skill IDs:** `forked_bolt`, `gust_line`, `rainfield`, `grounding_rod`, `eye_of_storm`, `thunderhead`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Death Knight

Bind hostile pressure into finite debt and answer it through weapon combat.

- **Fixed class ID:** `death_knight`; **home faction:** The Vesper Court.
- **Class-scoped families:** Steel / Oaths; **equipment identity:** swords, axes; heavy armor.
- **Proposed discipline — Debt:** Intercept real harm to bank a capped counter; debt expires and cannot be farmed on allies. **Design only.**
- **Planned skill IDs:** `grave_cut`, `debt_brand`, `night_mantle`, `soul_tether`, `dread_advance`, `last_judgment`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Necromancer

Spend battlefield remains to command short-lived servants, curses and bone cover.

- **Fixed class ID:** `necromancer`; **home faction:** The Vesper Court.
- **Class-scoped families:** Rites / Oaths; **equipment identity:** staves, ritual blades; light armor.
- **Proposed discipline — Remains:** Finite eligible remains power temporary summons; summoned deaths never produce more remains. **Design only.**
- **Planned skill IDs:** `bone_lance`, `raise_thrall`, `withering_seal`, `bone_screen`, `siphon_memory`, `procession`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Berserker

Commit to close pursuit, build fury and choose when to release or restrain it.

- **Fixed class ID:** `berserker`; **home faction:** The Gloamfang Clans.
- **Class-scoped families:** Steel / Hunt; **equipment identity:** axes, greatswords, claws; light or medium armor.
- **Proposed discipline — Fury:** Committed strikes build fury; spending it forces a readable recovery instead of endless chaining. **Design only.**
- **Planned skill IDs:** `rending_arc`, `pounce`, `defiant_roar`, `blood_scent`, `hold_fury`, `red_moon`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Moon Witch

Use lunar marks, howls and predatory bargains to manipulate pursuit.

- **Fixed class ID:** `moon_witch`; **home faction:** The Gloamfang Clans.
- **Class-scoped families:** Rites / Hunt; **equipment identity:** staves, ritual blades; light armor.
- **Proposed discipline — Moon phases:** A visible sequence alternates pursuit and restraint; each phase offers a different payoff. **Design only.**
- **Planned skill IDs:** `moonbrand`, `hushing_howl`, `pale_orb`, `scent_veil`, `hunger_bargain`, `eclipse`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Reaver

Break a defended position with heavy blows and carefully timed intimidation.

- **Fixed class ID:** `reaver`; **home faction:** The Emberhorn Dominion.
- **Class-scoped families:** Steel / Command; **equipment identity:** axes, hammers, greatswords; heavy armor.
- **Proposed discipline — Impact:** Committed heavy attacks build fracture on a target; overcommitting leaves a long punishable recovery. **Design only.**
- **Planned skill IDs:** `armor_rend`, `stampede`, `hammerfall`, `chain_drag`, `dominating_shout`, `breach`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Pyromancer

Lay fire, manage its spread and consume heat for a controlled release.

- **Fixed class ID:** `pyromancer`; **home faction:** The Emberhorn Dominion.
- **Class-scoped families:** Rites / Storm; **equipment identity:** staves, rods; light armor.
- **Proposed discipline — Heat:** Casting builds heat; vent it deliberately or suffer a predictable reduction in casting efficiency. **Design only.**
- **Planned skill IDs:** `ember`, `cinder_line`, `flashover`, `heat_mirage`, `banked_flame`, `furnace_breath`.
- **Currently supported action effects:** Ember. The rest of the class remains unimplemented.

### Wayfinder

Set routes and anchors that turn difficult ground into an advantage.

- **Fixed class ID:** `wayfinder`; **home faction:** The Reedbound League.
- **Class-scoped families:** Hunt / Command; **equipment identity:** spears, bows, swords; light or medium armor.
- **Proposed discipline — Route marks:** A few visible anchors enable repeatable movement tricks, with no teleportation through blocked ground. **Design only.**
- **Planned skill IDs:** `cast_line`, `channel_dash`, `crossing_mark`, `harpoon`, `wake_guard`, `open_passage`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Tidebinder

Shape a finite supply of water into flow, mist and returning waves.

- **Fixed class ID:** `tidebinder`; **home faction:** The Reedbound League.
- **Class-scoped families:** Rites / Storm; **equipment identity:** staves, rods; light armor.
- **Proposed discipline — Stored water:** Move water between connected patches; strong effects dry their source instead of appearing endlessly. **Design only.**
- **Planned skill IDs:** `returning_wave`, `mist_screen`, `salt_seal`, `silt_bank`, `draw_water`, `floodgate`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Marshal

Combine disciplined weapon combat with portable tools and explicit orders.

- **Fixed class ID:** `marshal`; **home faction:** The Ironroad Compact.
- **Class-scoped families:** Command / Steel; **equipment identity:** swords, polearms, crossbows; medium or heavy armor.
- **Proposed discipline — Readiness:** Preparing an order costs time now to improve one later action; only one preparation may be banked. **Design only.**
- **Planned skill IDs:** `ordered_strike`, `portable_cover`, `rally_point`, `intercept`, `advance_order`, `decisive_order`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Runemage

Draw a small network of deliberate glyphs and trigger their interactions.

- **Fixed class ID:** `runemage`; **home faction:** The Ironroad Compact.
- **Class-scoped families:** Rites / Command; **equipment identity:** staves, rune tools; light or medium armor.
- **Proposed discipline — Inscribed charges:** Place a bounded number of visible runes; consume, reposition or combine them at real preparation cost. **Design only.**
- **Planned skill IDs:** `rune_bolt`, `binding_glyph`, `warding_glyph`, `relay_mark`, `inscribed_snare`, `grand_circuit`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Stoneguard

Brace at a chosen boundary and convert a heavy impact into a measured counter.

- **Fixed class ID:** `stoneguard`; **home faction:** The Deepcairn Pact.
- **Class-scoped families:** Steel / Oaths; **equipment identity:** hammers, axes, shields; heavy armor.
- **Proposed discipline — Brace:** A timed brace catches one valid impact; carrying it slows turning until the stored force is released. **Design only.**
- **Planned skill IDs:** `stone_sweep`, `brace`, `fault_strike`, `pillar_stance`, `counterweight`, `unbroken_wall`.
- **Currently supported action effects:** Cleave. The rest of the class remains unimplemented.

### Earthshaper

Manipulate stone seams, resonance and temporary terrain without sealing every route.

- **Fixed class ID:** `earthshaper`; **home faction:** The Deepcairn Pact.
- **Class-scoped families:** Rites / Command; **equipment identity:** staves, hammers; light or medium armor.
- **Proposed discipline — Resonance:** Valid stone anchors carry finite pulses; every obstruction preserves a readable path around it. **Design only.**
- **Planned skill IDs:** `stone_lance`, `raise_ridge`, `resonance_pin`, `quartz_lens`, `weight_anchor`, `mountains_answer`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Thief

Infiltrate dangerous spaces, solve physical obstacles and use limited tools to secure optional treasure before escaping.

- **Fixed class ID:** `thief`; **home faction:** The Ironroad Compact.
- **Class-scoped families:** Hunt / Command; **equipment identity:** short blades, slings, light crossbows; light armor and tool belt.
- **Proposed discipline — Preparation:** Reconnaissance identifies real locks, traps and pockets. Spend a bounded tool supply to create an opening; each marked container or enemy can yield its registered stolen item only once. **Design only.**
- **Planned skill IDs:** `lift_key`, `disarm_trap`, `false_sound`, `smoke_bomb`, `tripwire`, `escape_line`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

### Rogue

Isolate a dangerous opponent, attack from an earned angle and spend a brief opening on precise melee pressure.

- **Fixed class ID:** `rogue`; **home faction:** The Vesper Court.
- **Class-scoped families:** Hunt / Steel; **equipment identity:** paired daggers, short swords, hand crossbow; light or medium armor.
- **Proposed discipline — Openings:** A successful flank, interrupt or timed evasion opens one target. Spend that opening on a precise finisher; it expires on a target switch and cannot stack into an infinite stun. **Design only.**
- **Planned skill IDs:** `backstab`, `venom_edge`, `hamstring`, `throat_feint`, `sidestep`, `expose_weakness`.
- **Currently supported action effects:** none. The rest of the class remains unimplemented.

## Identity, progression and save acceptance

Attribute allocation and safe-town reset change investment only. They cannot change the chosen hero, class, race or faction. The four implemented attributes produce supported statistics through ItemRules; the future thirty-point talent system is separate and limited to that class's allowed families/skills. A set bonus may improve a legal Ward, but cannot teach it to a class that lacks permission.

Action submission and queued-intent execution both validate class skills, not only the UI. Unknown identities and conflicting `id`/`heroId`/explicit class/race/faction values fail. Valid older action saves derive canonical missing identity fields. An already committed old cast can finish without rewriting its pending snapshot; an illegal new cast cannot be introduced afterward. Genuine old-save fixtures, pause/resume and forbidden casts are covered by the 134-check identity suite in [hunt-contracts.json](verification-logs/hunt-contracts.json).

Before offering another champion at New Chronicle, implement its complete starting action kit, solo counters, personal signature, actual racial effects, class discipline, gear/motion family, story relationships, acquisition, save transitions and recovery route. Structural uniqueness of 156 signatures is necessary but does not prove balance or production quality. No second playable hero is added inside any existing campaign.
