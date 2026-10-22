# DRACONIA — full production plan

**Status: planned work, not implemented content.** The user's target remains an original Romanian folklore strategy game with the breadth and completeness of Heroes III. The working build contains one campaign, one hero, ten creature types and two spells; [DEVELOPMENT_SCOPE.md](DEVELOPMENT_SCOPE.md) records that present state. This plan defines the larger game and its completion gates. It sets no completion dates and makes no claim that the proposed factions or systems already exist.

Draconia is fictional. Its factions combine Romanian folklore motifs with invented orders, creatures, places and characters; this roster is game design, not a claim of a single authoritative folklore tradition. The original-game investigation informs general structures; original executable code, proprietary art and copied scenarios are excluded.

## Production target

| Area | Target for the complete game |
| --- | --- |
| Factions and towns | Nine distinct factions; nine town presentations/build trees; seven dwellings with base and upgraded troops each |
| Creature content | 63 base creatures + 63 upgrades = **126 recruitable definitions**, plus a separate neutral-creature catalogue |
| Heroes | 18 classes, 54 named heroes, unique specialties, 32 secondary skills with three ranks, multiple simultaneous heroes |
| Magic and items | 72 spells across four schools; 120 equipment artifacts, 12 combination sets and 16 consumables |
| Scenarios | Nine faction arcs of four linked maps, a six-map concluding campaign, 24 standalone scenarios and a seeded random-map generator |
| Strategic opponents | Up to eight human/AI sides, fog-aware multihero planning, town conquest, recruitment, logistics and difficulty settings |
| Combat | Full army management, creature abilities, morale/luck, statuses, siege battles and war machines |
| Creation and multiplayer | Scenario/campaign editor, validated content packs, hotseat and network play, reconnect, replay and desync diagnostics |
| Presentation and delivery | Cohesive dark Carpathian world, wood/bronze frames and manuscript art, expanded native 3D environments, complete creature production, full audio and localization |

These are production content targets. Passing a count alone is insufficient: each definition needs art, rules, tooltips, audio where appropriate, AI support, save compatibility and tests.

## Nine faction identities and hero foundations

Each faction receives two hero classes and six named heroes, three per class. The names below establish its first two protagonists; the remaining 36 heroes need individual biographies, specialties and scenario roles during content production.

| Faction | Strategic identity and deliberate weakness | Two classes; first protagonists |
| --- | --- | --- |
| Cetățile Zorilor | Disciplined human hosts, formations and protection; expensive elite reinforcement, few flying options | Voievod / Păstrător de Jurăminte; Ileana and Radu |
| Poienile Ielelor | Forest mobility, healing and disruption; fragile ranged troops, vulnerable to sustained siege fire | Păzitor de Codru / Descântătoare; Doina and Sânziana |
| Școala Solomonarilor | Storm magic, prediction and controlled flying power; mana dependence and costly low-growth elites | Strajă a Turnului / Solomonar; Doru and Zamfira |
| Curtea Strigoilor | Attrition, fear and controlled recovery; slow economy and vulnerability to sunlight/ward effects | Boier Neviu / Chemător de Umbre; Vlad and Mara |
| Cetele Lunii | Fast hunters, pursuit and bounded night transformation; little ranged pressure and weak fortification attacks | Căpetenie a Haitei / Tălmăcitor al Lunii; Lupu and Codrina |
| Stăpânirile Zmeilor | Heavy assault, smithcraft and elite monsters; costly armies and poor early map coverage | Zmeu Domnesc / Făurar de Foc; Dragoș and Voica |
| Obștile Pietrei | Durable infantry, engineering and defensive economy; low mobility and no native flying troops | Cneaz al Pietrei / Meșter Runic; Toma and Stanca |
| Ținuturile Apelor | River travel, mist and battlefield control; reduced mobility advantages away from waterways | Cârmaci / Păstrătoare de Izvoare; Mircea and Ilinca |
| Târgurile Hotarului | Contracts, trade, ambush and curses; modest direct damage and costly broken contracts | Haiduc / Legător de Descântece; Bucur and Anca |

## Seven creature tiers and upgrades

Every row specifies one dwelling's base → upgraded recruitment. Roles describe proposed mechanics, not currently working abilities. Existing short unit keys are legacy identifiers and require explicit migration when replaced by faction-qualified IDs.

| Faction | Tier | Base → upgrade | Intended role |
| --- | ---: | --- | --- |
| Zorilor | 1 | Oștean → Scutier al Zorilor | Affordable shield infantry |
| Zorilor | 2 | Arcaș → Arcaș Domnesc | Reliable ranged fire |
| Zorilor | 3 | Străjer → Străjer de Fier | Hold adjacent allies' formation |
| Zorilor | 4 | Pândar → Pândar de Hotar | Limited-ammunition ranged skirmisher |
| Zorilor | 5 | Viteaz → Viteaz al Jurământului | Retaliation-resistant assault |
| Zorilor | 6 | Călăreț → Călăreț Domnesc | Mounted charge with distance scaling |
| Zorilor | 7 | Purtător de Stindard → Întrupare a Zorilor | Heavy living protector, bounded ward aura |
| Ielelor | 1 | Licurici → Licurici de Argint | Fragile flying distraction |
| Ielelor | 2 | Mlădiță Vie → Strajă de Rădăcini | Rooting ground infantry |
| Ielelor | 3 | Arcaș al Codrului → Arcaș al Frunzelor | Forest-adapted ranged fire |
| Ielelor | 4 | Sânziană → Sânziană a Verii | Limited healing and cleansing |
| Ielelor | 5 | Iele → Iele ale Vântului | Magical flight and positional disruption |
| Ielelor | 6 | Cerb Alb → Cerb de Argint | Fast flanking charge |
| Ielelor | 7 | Mumă a Pădurii → Mumă a Codrului Vechi | Durable forest guardian and area roots |
| Solomonarilor | 1 | Ucenic → Ucenic al Toiagului | Low-cost magic-resistant infantry |
| Solomonarilor | 2 | Pietrar → Pietrar Runic | Construct repair and line support |
| Solomonarilor | 3 | Corb → Corb Oracular | Flying reconnaissance and mark |
| Solomonarilor | 4 | Scrib → Scrib al Fulgerului | Ranged lightning with limited charges |
| Solomonarilor | 5 | Solomonar → Solomonar al Norilor | Ranged caster, carefully capped chain damage |
| Solomonarilor | 6 | Strajă de Nor → Strajă de Furtună | Heavy summoned defender |
| Solomonarilor | 7 | Balaur de Ploaie → Balaur al Furtunii | Flying storm attacker, expensive upkeep |
| Strigoilor | 1 | Rămășiță → Rămășiță Legată | Cheap undead attrition |
| Strigoilor | 2 | Clopotar Stins → Clopotar Funebru | Short-range sonic attack |
| Strigoilor | 3 | Strigoi → Strigoi Sângeros | Capped life drain against living targets |
| Strigoilor | 4 | Moroi → Moroi Întunecat | Flying harassment and fear |
| Strigoilor | 5 | Duh Funerar → Duh al Criptei | Flying disruption, low physical durability |
| Strigoilor | 6 | Boier Neviu → Voievod Neviu | Heavy infantry and local command aura |
| Strigoilor | 7 | Uriaș de Oase → Colos de Oase | Slow siege breaker, vulnerable to flame |
| Lunii | 1 | Urmăritor → Urmăritor Nocturn | Cheap scouting infantry |
| Lunii | 2 | Lup → Lup Cenușiu | Fast melee flanker |
| Lunii | 3 | Aruncător de Suliță → Sulițaș al Haitei | Limited ranged protection |
| Lunii | 4 | Prădător → Prădător de Umbre | Flank damage with clear positioning condition |
| Lunii | 5 | Pricolici → Pricolici Sălbatic | Pursuit and retaliation pressure |
| Lunii | 6 | Vârcolac → Vârcolac de Eclipsă | Bounded day/night transformation |
| Lunii | 7 | Fiară a Lunii → Fiară a Eclipsei | Large beast, fear-resistant assault |
| Zmeilor | 1 | Slujitor → Slujitor Solzos | Cheap screening infantry |
| Zmeilor | 2 | Arbaletier → Arbaletier de Aramă | Slow armor-piercing ranged fire |
| Zmeilor | 3 | Zmeu Tânăr → Zmeu al Stâncii | Durable melee attacker |
| Zmeilor | 4 | Liliac Uriaș → Liliac de Jar | Flying flank threat |
| Zmeilor | 5 | Zmeu Fierar → Zmeu al Nicovalei | Heavy support and armor repair |
| Zmeilor | 6 | Zmeu Domnesc → Zmeu Încununat | Elite melee challenge |
| Zmeilor | 7 | Balaur → Balaur cu Șapte Capete | Flying apex attacker, costly recovery |
| Pietrei | 1 | Miner → Miner Voinic | Cheap durable infantry |
| Pietrei | 2 | Praștiaș → Praștiaș de Cremene | Short-range stone missiles |
| Pietrei | 3 | Paznic de Mină → Paznic de Granit | Defensive front line |
| Pietrei | 4 | Berbec de Munte → Berbec de Fier | Ground charge and displacement |
| Pietrei | 5 | Meșter Runic → Meșter de Obsidian | Ranged rune support |
| Pietrei | 6 | Uriaș de Stâncă → Uriaș de Granit | Large infantry, obstacle breaking |
| Pietrei | 7 | Inimă de Munte → Colos al Muntelui | Very slow anchor and siege resistance |
| Apelor | 1 | Pescăruș → Pescăruș de Ceață | Flying scout, weak direct damage |
| Apelor | 2 | Vâslaș → Vâslaș al Deltei | Amphibious infantry |
| Apelor | 3 | Săgetător de Stuf → Săgetător al Bălții | Ranged ambush |
| Apelor | 4 | Știmă → Știmă a Izvorului | Ranged water magic and cleansing |
| Apelor | 5 | Șarpe de Apă → Șarpe de Vâltoare | Ground constriction and area denial |
| Apelor | 6 | Duh de Ceață → Duh al Negurii | Flying concealment support |
| Apelor | 7 | Balaur al Adâncului → Balaur de Vâltoare | Amphibious heavy monster |
| Hotarului | 1 | Spiriduș → Spiriduș Șiret | Cheap disruption and trap detection |
| Hotarului | 2 | Haiduc → Haiduc Codrean | Ranged ambusher |
| Hotarului | 3 | Căpcăun → Căpcăun de Fier | Slow, strong melee blocker |
| Hotarului | 4 | Zburător → Zburător al Amurgului | Flying harassment and dream mark |
| Hotarului | 5 | Descântătoare → Descântătoare a Pragului | Ranged caster and bounded curse |
| Hotarului | 6 | Paznic al Răscrucii → Paznic al celor Nouă Drumuri | Interception and movement control |
| Hotarului | 7 | Cel Fără Nume → Stăpân al Pragului | High-cost control monster |

### Balance rules to implement and measure

Use provisional tier power weights **1 / 1.7 / 2.8 / 4.6 / 7.5 / 12.5 / 22** and weekly growth **16 / 12 / 9 / 6 / 4 / 3 / 2** as a common starting budget, then tune actual HP, damage, initiative, abilities and gold/material prices. These are design seeds, not measured balance. Each faction's complete weekly recruitment should start within 5% of the shared budget before terrain and specialty adjustments.

Each roster has at most two ordinary ranged and two flying tiers; support spells consume bounded charges. Upgrades retain dwelling growth and add roughly 25–40% evaluated combat value for a 35–60% price premium, subject to testing. Every strong ability needs a visible trigger, limit and counter. Undead immunity must have compensating liabilities. Amphibious troops remain usable on land. Night transformations cannot create permanent free troops or an unavoidable loss at dawn.

Balance gates cover all 36 faction pairings with equal-value early/mid/late armies, multiple terrain/hero/magic settings, and recorded deterministic seeds. Review win-rate asymmetries outside a provisional 40–60% band in symmetric benchmark scenarios; do not force every composition matchup into that band. Human playtests must also check map tempo, economy, counterplay and fun.

## Hero, magic and artifact catalogues

Heroes receive an individual specialty, portrait, biography, starting army and faction-compatible progression. Implement army splitting/merging, formation order, hero-to-hero exchange, town garrisons, tavern recruitment, dismissal/retreat, mounts/boats and quest journals. The 32 secondary skills cover command, economy, travel and magic; random offerings must allow a viable build without mandatory rerolls.

The proposed **72-spell catalogue** contains twelve combat and six adventure spells per school. Names below define the authoring list; every spell still needs targeting, costs, mastery effects, AI evaluation, animation and tests.

- **Soare / Sun — combat:** Oathfire, Dawn Shield, Sun Lance, Courage, Radiant Edge, Cleanse, Daybreak, Sacred Ground, Banner of Resolve, Mirror Ward, Judgment, Last Light. **Adventure:** Consecrate, Reveal Oath, Safe Road, Dawn Beacon, Bless Harvest, Break Seal.
- **Codru / Forest — combat:** Mend, Root Snare, Briar Wall, Pollen Sleep, Barkskin, Thorn Volley, Wild Step, Summer Grace, Stag Charge, Living Grove, Dispel Venom, Forest Rebirth. **Adventure:** Woodland Passage, Find Spring, Call Scouts, Grow Bridge, Quiet Camp, Speak to Grove.
- **Furtună / Storm — combat:** Spark, Gust, Chain Lightning, Rain Veil, Hail, Thunderclap, Windstride, Storm Ward, Static Bond, Cyclone, Cloud Host, Skyfire. **Adventure:** Fair Wind, Summon Boat, Far Sight, Mountain Wind, Storm Passage, Recall Beacon.
- **Umbre / Shadow — combat:** Dread, Wither, Mist Shroud, Silence, Night Mark, Drain, False Double, Slow Heart, Grave Chains, Eclipse, Soul Prison, Borrowed Life. **Adventure:** Veil Caravan, Read Tracks, Haunt Mine, Shadow Step, Dream Message, Unbind Curse.

Resurrection, summons, teleportation, mind control and economic spells require explicit persistence/ownership rules. Multiplayer information rules apply to scouting spells. The day/night cycle and corruption remain common systems, with faction-specific responses and visible tradeoffs; the full game adds oath choices without allowing softlocks.

| Equipment rarity | Planned count | Initial named designs to specify |
| --- | ---: | --- |
| Common | 48 | Shepherd's Bell; Rowan Brooch; River Compass; Iron Oath Ring; Hunter's Boots; Woven Sash |
| Uncommon | 36 | Cloak of the Codru; Stormglass; Haiduc's Bow; Silver Spur; Wardstone Buckle; Lantern of Crossroads |
| Relic | 24 | Solomonar's Staff; Crown of Quiet Waters; Seven-Knot Girdle; Sunsteel Blade; Moonbound Pelt; Chronicle of Ash |
| Legendary | 12 | Crown of the Nine Oaths; Heart of the Mountain; Star of Sânziene; Mirror of the First Dawn; Seal of the Deep; Throne's Last Ember |

Complete the remaining named item definitions within those counts. Add twelve combination sets assembled from the 120 items, with no double-counted set pieces, plus sixteen consumables. Equipment slots, backpack capacity, trading, set conflict rules, cursed-item removal and reward generation need one data schema and inspection UI. Avoid unlimited resource loops and compulsory single-item builds.

## Campaigns, world systems and opponents

The nine four-map faction arcs are **The Broken Dawn, The Silent Groves, The Stolen Storm, The Unquiet Court, The Hungry Moon, The Brass Crown, The Mountain's Heart, The Drowned Roads,** and **The Ninth Bargain**. The six-map concluding arc, **The Oaths of Draconia**, joins their consequences. That is 42 planned campaign maps; existing campaign content is a reusable foundation, not 42 finished maps. Add 24 standalone scenarios spanning small duels, alliances, exploration and eight-side conquest.

World support must include surface/underground layers, scalable maps, boats and landing sites, portals, mines, markets, external dwellings, quests, events, neutral diplomacy, guarded passages and victory/loss conditions. Campaign transitions carry explicitly permitted heroes, skills, artifacts and choices. Scenario validation detects unreachable objectives, broken portals, invalid ownership and quest cycles. Seeded random generation must prove starting-area access and resource fairness before accepting a map.

Overworld AI controls several heroes, recruits and builds under the same spending rules, scouts without hidden-information access, assigns exploration/defense/attack roles, estimates danger, exchanges armies and pursues objectives. Difficulty changes decision quality and optional disclosed bonuses. It must recover from blocked goals and finish full games without deadlocks or endless turns.

Sieges add destructible walls, a gate, towers, moat/hazard rules, catapult and other war machines, attacker/defender deployment, flying/teleport interactions, retreat/surrender and town capture. Army management adds large creatures, explicit statuses, morale/luck and a shared effect system. AI, simulator, replay and interactive combat must resolve the same rules.

## Authoring, multiplayer and maintainable implementation

Move campaign/faction definitions into validated data assets with stable IDs, localization keys and separate visual references. Keep authoritative state JSON-compatible; introduce versioned command validation, deterministic RNG streams and state hashes before networking. Split the present campaign core by responsibility only when new systems require it, preserving public behavior and regression fixtures.

Build a native scenario editor for terrain/layers, roads/rivers, town/hero/object placement, armies, rewards, quests, triggers and victory conditions. Add undo/redo, play-from-editor, content validation, preview images and versioned scenario/campaign packages. Editable content packs must declare dependencies and licenses; imported data must not execute arbitrary scripts by default.

Implement hotseat first, then up-to-eight-player LAN/online lobbies, turn ownership, synchronized battles, authoritative action validation, disconnect/rejoin, host-loss policy, save/resume and replays. Record action logs and state hashes so desync reports identify the first divergent turn. Test version mismatch, malformed commands, latency, interruption and information leakage. Transport success alone is not multiplayer completion.

Presentation work extends the implemented native 3D adventure and battle environments into a coherent dark Carpathian world. The current tactical Vârcolac has a skinned 3D model; the other troop types use interim animated billboards. Produce the complete faction creature roster with readable silhouettes and consistent animation, then expand towns, terrain, weather, lighting and camera polish. Preserve clear tile/hex selection and strategic readability. Keep wood/bronze UI frames and manuscript art at accessible contrast and text sizes. Commission or source appropriately licensed animations, portraits, effects and interfaces with complete provenance. Build a regional score, creature/action audio, ambience, mixer controls, subtitles and reduced-motion options; support English and Romanian text first.

## Implementation sequence and acceptance gates

| Gate | Required result before marking complete |
| --- | --- |
| 1. Preserve the working foundation | Existing 1,184 normal checks pass; exported first campaign is playable; saves migrate; raw logs and visual evidence are retained; test storage never uses player saves |
| 2. Data and strategic rules | Stable faction/hero/item/scenario schemas; multiple heroes and garrisons; transfers, markets, boats/layers; atomic commands; deterministic save/replay migrations |
| 3. Full tactical rules and three factions | Zorilor, Ielelor and Strigoilor each have 14 working creatures and complete town trees; statuses, mastery, siege and AI use the shared effect system; every ability has tests and counterplay |
| 4. All nine factions and catalogs | All 126 recruitable definitions, 54 heroes, 32 skills, 72 spells, 120 equipment items, 12 sets and 16 consumables are implemented, documented and validated; matchup/economy reports reviewed |
| 5. Complete strategic opponents | AI finishes seeded multihero games on every map size and faction; no hidden-information cheating unless explicitly configured; bounded turn times; defeat and conquest regression scenarios |
| 6. Editor and scenario production | Editor round-trips maps losslessly; authored and random maps pass validation; all 42 campaign maps and 24 standalone scenarios have tested objectives, transitions and legal asset provenance |
| 7. Multiplayer and resilience | Hotseat and network games complete with up to eight sides; reconnect/save/resume and replay agree on state; invalid commands rejected; latency and desync tests produce actionable evidence |
| 8. Visual, audio and accessibility production | Native 3D presentation and complete faction art/audio are integrated; layout, selection, lighting, sound mix, localization, controls and accessibility pass representative human reviews |
| 9. Release acceptance | Full campaigns completed by human testers; native Windows/Linux runtime tests and supported-browser tests where shipped; performance/save migration/installation/license checks; no unresolved progression blockers |

Each gate produces reviewable evidence: code and content manifests, test scenarios, reproducible seeds, balance reports, exported packages and recorded limitations. Counts and automatic checks supplement human playtesting. The present [verification record](VERIFICATION.md) applies to the first campaign only; planned gates must not be described as passed until their work and evidence exist.
