# Draconia — Oaths of the Carpathians

## Integrated game design and production contract

**Revision:** 22 October 2026. **Working title:** Draconia — Oaths of the Carpathians. **Primary platform:** native desktop PC, built in Godot. **Current implementation focus:** the v0.3.1 card-reconstruction development slice: one persistent 3D town, a fixed Oathwarden, earned levels/attributes, the once-only story Vault, three repeatable hunt formations, physical loot, equipment/sales, and authoritative save/return transactions. The original painted cards remain unchanged and define the architecture built in Blender. All eight reviewed reconstructions and the corrected town placement are now installed for development integration; the previous mismatched models and rendered-card checks remain technical history. The actual-runtime construction/save/reload gate passes 1,506 assertions with zero failures, eight purchases and fifteen captures in an explicitly funded QA realm. Exported-binary startup, resource binding and normal-exit results remain separate, version-bound evidence in VERIFICATION.md. Broader art and content production remain unfinished.

This document defines the full intended game and the rules that keep its parts coherent. It is also an acceptance contract: a described system is not a completed feature until its rules, controls, presentation and persistence pass the evidence gate. The project is presently an early playable foundation with a new action-game slice in development. It is **not yet a complete game on the scale or quality of Heroes III**, and the large catalog totals below are production targets.

The latest user direction takes precedence over older design notes. This document supersedes the old proposals for nine seven-tier factions, eight factions/144 creature definitions, recruitable player heroes, seven army stacks, expanded hex combat, eighteen classes, and a four-spell Mara with unrestricted access to every talent family. The legacy campaign and hex engine remain preserved for reference and regression; the rebuild uses one chosen hero, six companies, four realm watches, real-time action, solo dungeons and actual 3D actors.

### Authority and related specifications

| Subject | Authoritative source |
| --- | --- |
| Settled player-facing names and approved illustration direction | [NAMING_AND_ART_LOCK.md](NAMING_AND_ART_LOCK.md) |
| Integrated game rules, scope and acceptance | This document |
| Detailed clock, rival economy, oaths and realm transactions | [REDESIGN_REALM.md](REDESIGN_REALM.md) |
| Detailed action, skills, companies, gear and combat contracts | [REDESIGN_COMBAT.md](REDESIGN_COMBAT.md) |
| All 156 authored protagonist concepts, fixed class/race mappings and signatures | [HERO_ROSTER.md](HERO_ROSTER.md) and [hero_roster.json](../data/hero_roster.json) |
| Twenty fixed classes, permitted skills and design-only disciplines | [CLASS_DESIGN.md](CLASS_DESIGN.md), [class_catalog.json](../data/class_catalog.json) and `HeroIdentity` |
| Implemented level/attribute and repeat-contract transactions | [ATTRIBUTE_PROGRESSION.md](ATTRIBUTE_PROGRESSION.md) and [HUNT_CONTRACTS.md](HUNT_CONTRACTS.md) |
| Current evidence and historical checkpoint boundaries | [VERIFICATION.md](VERIFICATION.md) |
| All 54 creature families and 108 exclusive promotions | Section 4 and [creature_roster.json](../data/creature_roster.json) |
| Models, rigs, environments, illustrations and acquisition accounting | [REDESIGN_ART_AND_ASSETS.md](REDESIGN_ART_AND_ASSETS.md) |
| Accepted character material revision and remaining production work | [CHARACTER_MATERIALS.md](CHARACTER_MATERIALS.md) |
| Bounded external character-sheet reference review | [RAVEN_HOLLOW_REVIEW.md](RAVEN_HOLLOW_REVIEW.md) |
| Actual current numerical behavior | The applicable versioned rules module and recorded tests |
| Asset provenance and rejected material | [ASSET_CREDITS.md](../ASSET_CREDITS.md), [IMAGE_QA_REJECTIONS.md](IMAGE_QA_REJECTIONS.md) |

No appendix may reintroduce another playable hero into an existing campaign. If a later numeric tuning change differs from a design example, the implementation record must explain the change and update the affected example. A visual preview, a list of names, an imported rig and a fully accepted playable unit are different deliverables.

## 1. The game in one sentence

**Choose one hero for an entire campaign, lead a persistent company of creatures across a living realm, build towns that can survive your absence, and enter dangerous places yourself to earn the power and obligations that reshape the world.**

The player's central scarce resource is personal presence. The hero can investigate a haunted mill, defend a grain convoy, negotiate a claim or confront a raiding host, but cannot be in all four places at once. Town councils, standing orders and binding agreements make those choices possible without adding more controllable heroes. A strong sword helps win a fight. A functioning town replaces losses. A trustworthy oath changes who will stand beside the hero when that town is threatened.

The game joins deliberate strategic planning to responsive action. On the realm map, travel and major commitments spend quoted watches. Inside a field encounter or dungeon, the player directly moves, attacks, guards, dodges and casts with the chosen hero. Up to six persistent companies accompany the hero in the field and follow understandable orders. In dungeons, the hero goes alone; the companies wait outside with their own state intact.

### Five design pillars

1. **One person, lasting consequences.** The protagonist is selected once. Identity, equipment, promises, relationships and injuries persist. Losing a fight does not become an excuse to switch to a fresh hero.
2. **Preparation earns opportunities; action decides their use.** Town development, route knowledge, counters and equipment matter. The player still has to move through a real arena, read threats and execute a plan.
3. **The army is a group of remembered companies.** Soldiers are recruited, trained, wounded and lost. Companies hold ground and create openings that one person cannot replace. They are commanded through six cards rather than dozens of mandatory individual selections.
4. **Oaths change systems.** A promise has visible terms, witnesses, a deadline when appropriate, a benefit and a consequence. A changed relationship can affect passage, trade, recruitment, defenses or a creature's behavior.
5. **The world visibly tells the truth.** A purchased building exists in the saved town. A closed gate blocks a route. A dead enemy stays dead. A stopped workshop looks stopped. A sword strike, its animation and its damage use the same action timeline.

### Easy to begin, difficult to master

The opening introduces move, attack, one damage skill, one defense and interact. The first town offers a handful of understandable plots, not nine technology trees. The forecast shows three important changes. A starting company uses a useful default order. Advanced players gain depth through timing, positioning, mixed armies, promotion branches, equipment interactions, negotiated terms and the opportunity cost of being somewhere else.

Depth must come from interacting decisions. A resource that only creates a compulsory click, a talent with no discernible use, or a contract whose consequence is a concealed penalty fails the design test. The player should be able to explain a loss and identify a different preparation or action that could have helped.

## 2. Reference influences and the original design boundary

The following are interpretations of the references requested by the user. Primary developer and publisher sources support the limited descriptions in the second column. The Draconia rules in the third column are original design choices, not claims that copying a feature proves quality.

| Reference | Relevant documented idea | Draconia application |
| --- | --- | --- |
| Heroes III and the Heroes series | The series connects exploration, resources, towns, armies and tactical battles; Ubisoft explicitly discusses Heroes III as an influence on that structure. [R1] | A readable adventure realm, memorable faction towns, creature recruitment and preparation that changes an encounter. The rebuild uses real-time action instead of reproducing the hex engine. |
| Diablo II | Direct action bindings, movement, attacks, ground-item interaction, distinct item categories and compatible ordered socket recipes. [R2, R3] | Solo dungeons, committed attacks and spells, physical loot, useful normal bases, magic/rare/set/unique gear, gems, runes and original recipes. |
| Warcraft III | Heroes grow, learn abilities and benefit nearby troops. [R4] | The chosen protagonist and six companies create reciprocal openings. This does not add multiple playable heroes. |
| WoW Classic | A character journey built around exploration and discovery in a persistent world. [R5] | Distinct regional dangers, landmarks, trainers and earned routes. It does not require subscriptions, raids or an MMO service. |
| The Witcher 3 | A professional monster-hunter role situated in a war-torn world. [R6] | Investigations and contracts connect supernatural threats to people, claims and choices; killing the creature is one possible conclusion. |
| Age of Empires II | Resources fund buildings, units and technologies; economic priorities support a military plan. [R7] | Clear counters, finite spending choices and inspectable production. Six company cards keep the scale manageable. |
| Manor Lords | Its developer describes organic settlements shaped by roads and landscape, with visible work and grounded materials. [R8] | Naturalistic 3D towns with recognizable services and believable work. Named plots preserve a strong dedicated town screen. |
| Crusader Kings II/III | Character personalities, relationships, claims and court politics supply different strategic stories. [R9] | Councils, claimant disputes, negotiated obligations and NPC succession affect the realm around the same protagonist. The player never changes to an heir. |
| Mount & Blade / Bannerlord | TaleWorlds discusses morale on the campaign map and battlefield. [R10] | Company cohesion, veteran identity, prisoners and explicit mercenary contracts connect battle conduct to later decisions. |
| Stronghold Crusader | Firefly presents castle sieges and distinct opponents within its castle-building strategy. [R11] | Built walls, gates and towers become functional geometry, access, cover, fire positions and supply constraints in actual assaults. |

No original game executable, commercial asset pack or copied faction catalog is required by this design. Bounded Heroes III investigation is recorded separately in [RE_FINDINGS.md](../research/RE_FINDINGS.md). It is research evidence, not a claim of complete reverse engineering or a source of permission to distribute another game's art or code.

## 3. Scope, counts and an honest implementation ledger

### Full production target

| Content or system | Required target | What the count means |
| --- | ---: | --- |
| Factions and regional identities | 9 | Nine coherent cultures, economies, army styles, town kits and political interests |
| Named faction capitals | 9 | One recognizable capital identity per faction, with functional town development |
| Base recruit families | 54 | Six families per faction, each with a different battlefield purpose |
| Exclusive promotion definitions | 108 | Two alternative promotions for each base family; a company chooses one branch |
| Total faction recruit definitions | 162 | 54 base forms plus 108 promotions; not 162 unrelated body rigs |
| Neutral creature definitions | 24 | Sixteen ordinary neutral types and eight major boss arcs |
| Total creature definitions | 186 | All require applicable rules, 3D presentation, animations, cards and acceptance |
| Campaign-start hero concepts | 156 | 144 regular identities, sixteen per faction, plus twelve story identities |
| Simultaneous player heroes | **1** | Fixed at campaign creation; no recruitment, swapping or playable succession |
| Accompanying field companies | 0–6 | Persistent rosters represented by six command cards |
| Hero in a dungeon | 1, with 0 companies | Army waits outside; solo results cannot erase it |
| Fixed hero classes | 20 | Every hero has one immutable class; two original classes per faction plus Vesper Rogue and Ironroad Thief |
| Race / ancestry packages | 8 | Independent identity and small proposed traits; not an alternate spell-permission system |
| Planned class-skill entries | 120 | Six authored IDs per class in the current catalog; design briefs, not 120 working skills |
| Shared effect-family briefs | 24 | A design vocabulary across six families; never a universal list every hero may learn |
| Authored innate hero signatures | 156 | One per hero concept, with only the chosen hero's signature active in that campaign |
| Implemented level progression | 30 levels | Earned XP, deterministic thresholds and cap; the first complete thirty-level progression route is verified |
| Implemented attribute budget | 90 points | Three at level one and three per earned level; four useful attributes, forty maximum investment each |
| Proposed talent budget | 30 points | Separate from attributes; class-scoped versions of 48 ordinary node briefs and six capstone briefs require implementation |
| Armor-set identities | 12 | Five armor pieces each; bonuses at two and four equipped pieces |
| Exceptional unique item targets | 24 | Original behavior-driven uniques, fulfilling the requested legendary role |
| Realm watches per day | 4 | Dawn, afternoon, dusk and night |

The 156 heroes are authored concepts, not a multiplication of randomly chosen names, hair and colors. Each offered identity needs a coherent origin, silhouette, starting relationships, starting play pattern and a tested introductory route. Shared ancestry bodies, animation families and ability systems can reduce production cost. They do not excuse presenting 156 unreviewed combinations as finished characters. The initial implementation supports Mara Veyne only; the final roster and selection system must be built deliberately.

### State of the new slice

| Area | Implemented and checked now | Still required before full acceptance |
| --- | --- | --- |
| Realm rules | Four watches, dawn income, construction, rest, finite market, two oaths, paid rival mustering and neutral frontier claims | Defended conquest, player interception, company deployment, supply consumption, full diplomacy and campaign routes |
| Fixed identity | All 156 class/race/faction mappings, twenty-class skill permissions, strict command/queued-cast enforcement and compatibility | A complete New Chronicle selection UI and playable implementations beyond Mara; all personal, racial and class-resource traits |
| Progression | Levels 1–30, four useful attributes, ninety-point budget, atomic preview/apply/reset, no healing, stale-revision and pending locks | Class talent trees, skill acquisition milestones, implemented signatures and production balance |
| Action rules | Direct movement, attacks, guard/dodge, collision, enemies, physical loot and extraction; Mara Cleave/Ward, separate Pyromancer Ember and Druid Roots fixtures | Six-company formations, broader objectives, siege combat, complete class kits and enemy families |
| Items and sale | Sixteen definitions, two recipes, five Bellworn set pieces, seeded validation, equipment, finite crafting supplies and actual unequipped-item sale | Full item ecosystem, twelve sets, twenty-four exceptional uniques and every fitted visual variant |
| Solo loop | Finite story Vault plus three registered repeatable formations; retained wounds/enemies/claims, physical pickup, exact XP and refreshed board on extraction | New dungeon geometry, varied boss/puzzle/contract content, broad human playtesting and compelling endgame |
| Native interface | Character draft/apply and equipment folios, real hunt/sale/forfeit controls; earned route: 181 checks/twelve captures and separate integrated folio: 60 checks/eleven captures | Broader access/input testing, full human-use review, production polish and target-hardware performance |
| Art | Development Mara PBR revision, two fitted textured earned items, unchanged original painted building cards, eight reviewed Blender reconstructions and corrected Dawnreach foundations/access/water placement | Remaining building detail, shared-texture and chain-rendering optimization, target-hardware profiling, close-camera character deformation, lower LODs, complete environment art, and the promised hero, armor, town and creature breadth |
| Legacy/checkpoint history | Separate hex campaign and immutable v0.2 action archives with preserved evidence | Neither establishes completion or testing of the current full design |

The current recorded rules regression passes **1,390 checks across six suites**, all with zero failures and exit 0: hunts 458, realm 247, progression 277, identity 134, items 73 and action 201. The independent native hunt/sale route passes **181 checks**, with twelve inspected captures at 1440×900, 1280×800 and 960×640. It performs real UI input, legal combat commands, earned progression, physical rewards, live save/resume, sale and explicit forfeiture. Class-specific feedback has separate 43-unit/55-native-check evidence. Scoped character/presentation evidence is separate: Mara: 245 native checks/ten captures, two equipment modules: 18 checks, six preview-lifetime cycles: 25 checks, and the integrated folio: 60 checks/eleven captures. The superseded model-render card proof has 83 checks/eight renders, and the previous town composition has 77 checks/seven captures; these do not establish a match to the original paintings. The restored painted-card interface passes 218 focused native checks with seven captures, including unchanged artwork during actual input and a real purchase. The later staged town uses all eight final reconstructions and passes **168 checks with zero failures and eight inspected captures**; it is a populated placement/access/water fixture, separate from the final production-path construction and save/reload gate. These counts are not a whole-game completion score. See [VERIFICATION.md](VERIFICATION.md) for exact revisions and limits.

The forty-six-completion route reaches level 30 through actual action outcomes; it is not a full campaign, varied endgame or human-enjoyment test. The earlier v0.2 101-check/17-capture route and twelve-check presentation pass remain historical evidence, not additional current-run checks. The rejected building designs have been replaced by reviewed development reconstructions; remaining art refinements and full production acceptance stay open. The character material pass retains its stated development scope. The sixty-check folio run predates the reconstructed buildings, the label-only change from “Ward strength” to “Additional Ward”, and the portable path for the same previously earned equipment fixture; its exact executed harness is retained. A subsequent native capture verifies the corrected label without being counted as a repeated sixty-check run. Software-rendered captures do not prove real-time target-hardware performance, and no native Windows runtime or Heroes III parity claim follows from these results.

## 4. The world and its nine powers

The setting is original high fantasy with a Romanian-rooted heartland and distinct influences from neighboring Eastern European folklore traditions. People farm, trade, inherit, grieve and negotiate under supernatural pressures. A frightening creature can have intelligible needs without being harmless. A human patron can offer useful protection while making an unjust demand. Folklore is a source for research and interpretation, not a single interchangeable list of regional monsters.

All ordinary interface text uses English or readable invented fantasy names. Source-language terms may remain in research provenance. Working names have not undergone trademark clearance. The working title and names can change through a documented naming revision without changing persistent internal IDs.

| Faction / capital | Region and visual identity | Strategic and political character | Battlefield promise and vulnerability |
| --- | --- | --- | --- |
| **The Ashen Crown — Dawnreach** | The Ashen March; fortified courts, dark timber galleries, tilled fields and weathered heraldry | Local defense, agrarian production and reciprocal civic service; lords need village cooperation | Disciplined lines and rally support; strong when prepared, less comfortable chasing scattered threats |
| **The Thornweald Court — Briarhollow** | The Thornweald; living groves, pale cloth, carved boundary stones and wingless Veilkin | Sanctuary rights, herb routes and reciprocal forest bargains | Control, misdirection and mobile support; exposed on open approaches and against properly scouted pressure |
| **The Cloudspire Conclave — Stormcairn** | The Cloudspires; mountain schools, slate, exposed copper instruments and storm-lit heights | Weather knowledge, passage protection and dangerous research obligations | Prepared zones and coordinated elemental effects; casts can be interrupted and formations separated |
| **The Vesper Court — Duskharrow** | The Mourning Vale; bell towers, burial courts, iron and wine-dark cloth | Ancient claims, debt, inheritance and formal protection that may outlive its beneficiaries | Enduring lines, curses and night pressure; ritual sources and binding conditions create clear targets |
| **The Gloamfang Clans — Fangrest** | The Moonscar Peaks; mountain timber, stone, hides and hunting paths | Pack loyalties, restraint, seasonal hunting and disputed passage | Pursuit, flanks and committed leaps; telegraphed attacks expose recovery and organized spear lines resist them |
| **The Emberhorn Dominion — Cindervault** | The Copper Wastes; heavy foundations, furnaces, mineral surfaces and worked metal | Foundry output, prestigious works and the price of elite force | Heavy impact and durable specialists; high cost, space and supply needs punish careless deployment |
| **The Reedbound League — Reedhaven** | The Mirrorwater Delta; reed roofs, stilt houses, plank walks and water-dark timber | Ferries, food movement, flood rights and shared crossings | Wet-terrain control, flexible support and displacement; loses some advantages on dry exposed ground |
| **The Ironroad Compact — Crossmere** | The Ninefold Road; timber markets, layered awnings, travel equipment and guild signs | Contracts, information, caravans and negotiated freedom | Adaptable mixed specialists and practical counters; obligations and finite hiring pools constrain the roster |
| **The Deepcairn Pact — Stonewake** | The Understone Holds; engineered stone, braces, lamps, hoists and guarded underways | Ancestral debt, extraction limits, engineering and shared access | Passage defense, siege craft and deliberate advances; slow repositioning and limited open-ground reach |

No faction is a permanent moral alignment. Every regional arc should include a sympathetic local need, a faction interest and a foreseeable cost. The Vesper Court can honor a burial compact while an Ashen claimant abuses a tax right. A Thornweald sanctuary can protect refugees while restricting essential timber. Good outcomes require terms that people can actually sustain.

### Creature-family design

The central content catalog owns all fifty-four base family names and one hundred eight promotion names. The integration must not invent a second incompatible roster. Each faction's six families must collectively answer these roles: dependable front line, ranged pressure, mobility or flanking, support or control, a specialist that changes an objective, and a prestigious major threat. This is a coverage requirement, not six identical classes reskinned nine times.

A family specification records body/rig, company size, provision weight, recruitment site, attack language, role, counters, standing-order exceptions, day/night behavior and two promotion tradeoffs. Both promotions must change a useful decision. One can improve holding a narrow passage while the other trades durability for a field initiation; they cannot both simply be an unconditional increase to every stat.

Promotion preserves company and surviving-member identities. The purchase consumes the actual number of promoted members and declared materials at a valid service. It does not heal injuries, refill dead members or duplicate equipment. The dwelling's branch visibly changes. A later retraining service, if accepted, must quote its price, time and lost investment rather than offering a free switch before every encounter.

Creature labels such as Veilkin, Gravewights, Tempest Sages, Gloamfangs and Crownwyrms describe original families. Their actions should be readable from silhouettes and preparation. A teleport, possession, breath or burrow requires a legal destination and a counter; it is not permission to ignore terrain or show an effect without rules.

### The definitive fifty-four family roster

This is the named design catalog for the full game. Its machine-readable source is [creature_roster.json](../data/creature_roster.json). It contains exactly **54 base forms and 108 exclusive promotion forms**, with 162 unique IDs and names. Each row is one family; promotion A and B are alternatives, not successive tiers. None of these definitions is declared runtime-complete by this table. The JSON also records proposed body counts, recruitment sites, anatomy, watch conditions and counters.

The family roles below are original designs. Familiar folklore motifs inform their briefs, but no source is being cited as a rulebook for their combat behavior. Human or other ancestry membership does not require loyalty to the faction recruiting that company. Veilkin Envoys, for example, are one professional/ritual company family rather than every Veilkin person in the world.

#### The Ashen Crown — Dawnreach

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Hearthguard** — Affordable spear-and-shield line; protects a chosen approach. | **Oathguard** — A stationary front shares a finite brace against one incoming charge. Slower turning and longer reform after moving. | **Marchguard** — Can reform a shorter brace quickly after a legal advance. Less frontal absorption than Oathguard; cannot charge while braced. | Flank the brace or force movement with a visible hazard. |
| **Briarbow Hunters** — Bow pressure from a protected firing lane. | **Longwatch Archers** — A prepared stationary aim extends a straight accurate firing lane. Longer setup and exposed recovery when repositioning. | **Harrowshot Skirmishers** — Loose a shorter-range spread while making a small controlled reposition. Lower single-target force and less reach. | Close the distance or use hard cover; arrows require clear lanes. |
| **Redmane Riders** — Mounted flank pressure with a readable committed charge. | **Dawnlances** — A long clear approach concentrates the charge into a narrow first impact. Poor turning and long recovery after a failed charge. | **Roadward Cavaliers** — Shorter controlled charges can peel threats off an escorted ally. Lower burst and no long-lane impact bonus. | A braced spear front stops the charge; tight turns cost momentum. |
| **Bellwardens** — Close support that protects morale and interrupts a harmful condition. | **Cleansing Cantors** — Remove one eligible hostile status with a targeted channeled chant. Give up the larger morale response; no reward on an unaffected target. | **Rallying Wardens** — A completed bell cadence steadies a bounded nearby group of shaken allies. Cannot cleanse poison or revive casualties. | Pressure or interrupt the visible support channel. |
| **Oathhounds** — Fast domestic trackers that expose a recently encountered hidden threat. | **Trailhounds** — Maintain a short trace of a wounded target after it leaves ordinary sight. Lower interception durability; trace expires and stops at sealed transitions. | **Gatehounds** — Briefly intercept a hostile rushing within an assigned protection radius. Short pursuit leash and less tracking reach. | Durable fronts and area denial punish their small unprotected bodies. |
| **Dawncrest Griffins** — Rare winged shock creatures that threaten a flank. | **Stormcrest Griffins** — Intercept an airborne target through a visible climb and swoop. Longer grounded recovery and weaker attacks against a sheltered line. | **Ironcrest Griffins** — Commit to a heavy ground dive that displaces a small frontage. Reduced airborne agility; a missed dive leaves a wide punish window. | Prepared ranged lanes and a braced landing zone punish their commitment. |

#### The Thornweald Court — Briarhollow

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Thornlings** — Light living-wood line that binds a small frontage. | **Rootward Thornlings** — Plant into a narrow defensive brace that resists displacement. Must uproot before moving and lose the brace during that transition. | **Brushward Thornlings** — Move through traversable brush quickly and leave a short slowing trail. Lower frontal resilience; solid roots and walls still block. | Fire and repeated displacement break their preferred anchored front. |
| **Briarwitches** — Ranged seed and bramble pressure with deliberate cast preparation. | **Briarweavers** — Turn a small prepared patch into an interruptible movement bind. Less direct damage and a longer preparation window. | **Briarspikers** — Concentrate thorns into an aimed projectile that exposes an unguarded target. No persistent binding zone; shields and hard cover stop the shot. | Interrupt the cast or move out of the marked patch before it grows. |
| **Hollowstags** — Fast antlered flankers that use forest circulation. | **Miststags** — Make one short veiled reposition through legal soft terrain before reappearing. Lower impact; cannot pass a sealed wall or remain untargetable while attacking. | **Crownstags** — A straight antler charge briefly displaces light units. Longer recovery and worse turning than Miststags. | Spears and narrow blocked approaches stop their preferred angle. |
| **Veilkin Envoys** — Wingless spirit support built around rhythm and directed distraction. | **Veildancers** — A completed marked sequence briefly distracts eligible light enemies from an uncommitted action. No effect on committed attacks or resolved bosses; weaker ally protection. | **Veilsingers** — Maintain a small finite protective refrain on allies who remain in the circle. Stationary channel and no hostile distraction. | Break the formation rhythm by interrupting or leaving its marked area. |
| **Mosswardens** — Slow living-wood specialists that anchor an objective. | **Rootbound Wardens** — Anchor a broad root barrier that protects a small rear arc. Immobile while active and vulnerable around the ends. | **Sporewardens** — Release a bounded spore cloud that weakens living attackers crossing it. No physical barrier; bloodless enemies resist the biological effect. | Force them to move, flank the heart opening or use fire with care for nearby allies. |
| **Duskwood Wyrms** — Large forest serpents that shape approach lanes. | **Bramblewyrms** — Project a short bramble corridor that limits pursuit. Shorter reach and no broad mist protection. | **Moonleaf Wyrms** — Breathe a cooling mist that weakens distant aim across a declared zone. Lower direct damage; mist also affects allied shots through it. | Spread around their committed head direction and punish the recovery. |

#### The Cloudspire Conclave — Stormcairn

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Galeguard** — Mountain-trained front line that protects channels. | **Skyward Guard** — Angle a finite shield screen against incoming projectiles from one side. Less melee brace and slower movement while raised. | **Passward Guard** — Lock a narrow approach against light displacement and charges. No broad projectile screen; vulnerable to a second approach. | Displace them before their protection forms or attack the unshielded flank. |
| **Rookcallers** — Ranged handlers who mark a target with a bounded corvid attack. | **Stormrook Keepers** — A prepared marked strike carries one bounded shock between nearby enemies. Longer recall/cooldown and reduced pressure on isolated targets. | **Rimewing Keepers** — A bird pass chills one moving target and reveals its brief trail. Lower burst and no chain effect. | Shelter behind hard cover or interrupt the handler; birds are limited actors. |
| **Windstriders** — Light human skirmishers with a deliberate wind-assisted reposition. | **Guststriders** — Redirect once during a short legal ground dash. Less attack force and a longer escape cooldown. | **Stormrunners** — Turn a straight committed dash into a stronger arrival strike. Cannot redirect after commitment and has exposed recovery on a miss. | Pressure the landing and force a move before their escape is ready. |
| **Tempest Sages** — Weather casters who prepare useful zones rather than constant instant damage. | **Rainbinders** — Create a wet support zone that suppresses ordinary fire and prepares storm interactions. Little direct burst and can assist an enemy that benefits from water. | **Thunderbinders** — Channel a bounded lightning sequence through a prepared lane. Long commitment; scattered targets reduce its value. | Interrupt preparation, separate targets or leave the announced zone. |
| **Cloudhorn Beasts** — Massive mountain rams that break or shelter a narrow line. | **Copperhorn Rams** — A committed horn impact cracks an armored guard or finite ward. Weaker escort protection and long recovery against an empty lane. | **Snowhorn Keepers** — Hold a protective shoulder position beside a named ally or channel. Lower charge damage and short pursuit distance. | Make the ram turn or meet it with a braced line rather than its charge. |
| **Crownwyrms** — Prestigious winged storm creatures with directional breath. | **Thunder Crownwyrms** — Release a narrow conductive breath that rewards aligned wet targets. Less control over a broad area and a longer charge-up. | **Rain Crownwyrms** — Create a wide temporary rain front that changes fire and ranged interactions. Lower direct killing power; the water state can help either side. | Exploit the breath tell, spread targets and punish a grounded recovery. |

#### The Vesper Court — Duskharrow

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Gravewights** — Enduring revenant infantry with an inspectable binding condition. | **Oathwights** — Protect a nearby registered binding source with a finite shared defense. Reduced offensive pursuit and weaker outside the source radius. | **Barrowwights** — Commit a heavy strike that briefly exposes a guarding target. Lose the shared source protection and recover slowly on a miss. | Separate them from the declared binding support and attack their slow turns. |
| **Bonefletchers** — Brittle ranged ranks that threaten an exposed lane. | **Ashfletchers** — Place a small lingering ash patch with an arcing shot. Lower direct penetration and a longer reload. | **Marrowfletchers** — Aim a slow precise shot against one exposed armored target. No persistent zone and weak response to scattered close attackers. | Rush their brittle bodies or block their clean firing lane. |
| **Pall Riders** — Revenant cavalry that threatens a lane through a visible charge. | **Dirge Riders** — A clean flank charge adds a bounded morale shock to living targets. Lower sustained defense and reduced effect on bloodless enemies. | **Lantern Riders** — Reveal a nearby active glamour or ritual trace while escorting an ally. Less charge pressure and no large morale shock. | Brace the approach or force a tight turn; phase visuals do not remove collision. |
| **Veilmourners** — Clothed wraith support that channels memory or silence. | **Memory Mourners** — Restore a bounded portion of eligible recent nonlethal harm to a living bound ally. No resurrection or manufactured roster members; no silence effect. | **Silence Mourners** — Interrupt one real channel and briefly delay its restart. No damage recovery; boss resolve prevents repeated lockout. | Interrupt the chant or move outside its small marked area. |
| **Bloodbound Courtiers** — Elite dueling infantry that exploits an isolated target. | **Crimson Duelists** — A committed contact against a living target converts limited damage into finite vigor. Poor against bloodless targets and no unlimited healing from summons. | **Sable Arbiters** — Mark one broken formation or interrupted channel for a short exposure. Less personal sustain and a strict mark target limit. | Deny isolation, block the lunge and punish the short exposed recovery. |
| **Bell Colossi** — Slow ritual engines that project a small dangerous area. | **Toll Colossi** — A visible heavy toll shakes eligible living enemies in a bounded radius. Slow movement and little effect on fearless constructs. | **Gravesong Colossi** — A directed resonance damages finite wards and interrupts ritual sources. Narrower effect and less ordinary morale pressure. | Attack from separated angles and interrupt the long toll preparation. |

#### The Gloamfang Clans — Fangrest

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Packwardens** — Human and Gloamkin line fighters that protect the pack approach. | **Fangwardens** — Brace a short spear front against a large leap or charge. Slower pursuit and less ambush movement. | **Moonwardens** — Advance through traversable brush into a brief protective ambush stance. Lower frontal brace and no crossing solid obstacles. | Separate their supporting neighbors or force an exposed pursuit. |
| **Moontrackers** — Ranged hunters that mark one vulnerable escape route. | **Nightstalkers** — A careful mark preserves local pursuit information after a target disengages. Lower immediate damage and only one tracked quarry per company. | **Wolfshot Hunters** — A short-range coordinated volley pressures a moving unguarded target. Less reach and no extended tracking. | Use hard cover and pressure them before the marked shot is prepared. |
| **Rimewolves** — Fast quadruped pack flankers. | **Frostfang Wolves** — A successful committed bite briefly chills a moving target. Less raw chase damage and a bounded chill refresh. | **Dreadfang Wolves** — Pressure already shaken targets during a legal pursuit. Lower value against disciplined or bloodless fronts; cannot cause instant map-wide rout. | Keep a coherent front and deny them a surrounded target. |
| **Moonbinders** — Support keepers who manage the pack’s resolve and costly recovery. | **Howlbinders** — Steady a small shaken allied group or oppose one incoming fear effect. No direct health recovery or resurrection. | **Bloodbinders** — Transfer a bounded amount of their own health to an eligible nearby ally. The cost is real, cannot be lethal by default and cannot recurse through another transfer. | Interrupt the visible binding and force the support away from its pack. |
| **Gloamfangs** — Powerful bipedal shapeshifter flankers with telegraphed leaps. | **Riftfangs** — Make a longer committed leap toward a locked point and an exposed backline. Brittler defense and a wide punish window after a miss. | **Ironfangs** — Trade leap distance for a guarded short advance and stable holding stance. Lower chase burst and no long backline access. | Dodge the locked-point leap and punish its recovery; spears resist a frontal landing. |
| **Whitepelt Ancients** — Rare massive bear-like elders that hold or break a front. | **Winterhide Ancients** — A braced roar protects nearby allies from one displacement or fear pressure. Lower offensive reach and cannot protect units outside its small zone. | **Redclaw Ancients** — Commit a broad maul that punishes a tightly packed enemy front. Long recovery and reduced protective support. | Move around their slow facing and avoid the announced maul area. |

#### The Emberhorn Dominion — Cindervault

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Cinderlings** — Small furnace-born infantry that fills gaps and handles works. | **Forge Cinderlings** — Perform limited battlefield repair on eligible friendly constructs or defenses. Lower attack pressure; repair consumes a finite encounter kit. | **Ash Cinderlings** — Rush an unguarded target with a short abrasive strike. Give up repair and remain fragile under a braced front. | Push them out of supportive works and use broad controlled attacks. |
| **Copperthrowers** — Heavy ranged throwers that threaten a clear short lane. | **Shardthrowers** — A thrown fragment bursts across a narrow nearby cone. Reduced single-target penetration and limited reach. | **Chainthrowers** — A hooked throw pulls one eligible light target a short legal distance. Longer cooldown; large or braced targets resist and walls stop displacement. | Move during the windup or pressure the slow reload. |
| **Furnace Hounds** — Fast heat-bound quadrupeds that chase openings. | **Coaljaw Hounds** — A committed bite leaves a finite burn on a vulnerable target. Reduced value in rain or against fire-resistant enemies. | **Bellows Hounds** — A short directed blast displaces light attackers from a protected ally. Lower sustained bite damage and no continuing burn. | Wet zones and a disciplined front reduce their favored pursuit. |
| **Ember Augurs** — Casters that manage heat and quenching zones. | **Kiln Augurs** — Build a slow persistent hot area that punishes stationary groups. Long warning and weak value against mobile or wet opponents. | **Quench Augurs** — End eligible ordinary fire and convert a limited heat state into finite protection. Little direct damage; cannot farm a recursive shield from allied self-casts. | Interrupt the preparation or move out of the marked thermal zone. |
| **Emberhorns** — Large horned humanoid champions with heavy committed strikes. | **Crown Horns** — Guard a named ally or objective with a wide finite shield posture. Slow forward pressure and reduced offensive reach. | **War Horns** — Commit to armor-breaking two-handed blows against a front or structure. No wide shield and long exposed recovery. | Exploit their turning and recovery; narrow support can isolate them. |
| **Furnace Drakes** — Wingless heavy reptiles that force opponents to respect breath direction. | **Basalt Drakes** — Retain a durable plated stance and a short armor-softening breath. Slow relocation and lower wide-area fire damage. | **Cinder Drakes** — Use a longer burning sweep after a visible turn and inhale. Lighter armor and a longer unprotected breath recovery. | Spread, leave the breath line and use wet terrain or recovery windows. |

#### The Reedbound League — Reedhaven

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Reedwardens** — Spear line trained to defend shallow crossings. | **Fordwardens** — Brace strongly across a narrow wet approach. Slow repositioning and less benefit away from the crossing. | **Fenwardens** — Reform quickly while moving through shallow water and mud. Weaker fixed brace and no deep-water immunity. | Draw them onto dry open ground or strike a second angle. |
| **Mirebow Stalkers** — Ranged pressure from reeds and broken banks. | **Reedshot Wardens** — A stationary covered aim gains a narrower protected firing posture. Slow relocation and no benefit in bare open ground. | **Eelshot Hunters** — A marked wet target enables one bounded conductive shot effect. Less ordinary dry-target damage and no unlimited chain. | Expose the firing position or use hard cover against the announced shot. |
| **Glassfin Sprites** — Small water spirits that reposition or rescue within a bounded reach. | **Slipstream Sprites** — Help one eligible ally make a short legal withdrawal along a marked path. Little damage and no teleport through a sealed obstacle. | **Undertow Sprites** — Pull one unbraced light enemy toward a nearby wet anchor. No ally rescue; heavy bodies and hard terrain resist. | Deny connected shallow water and interrupt the visible transfer. |
| **Mirror Oracles** — Water-touched support that reads and changes a small local state. | **Stillwater Oracles** — Cleanse one eligible condition and steady a limited recent wound. No burst damage; recovery cannot create health beyond the permitted budget. | **Stormwater Oracles** — Turn a prepared wet patch into a short interrupting pulse. No wound recovery and a clear delay before release. | Pressure the channel and separate allies from the marked pool. |
| **Bogback Turtles** — Slow armored objective bodies with tangible cover. | **Reedback Shelters** — Carry a low protective shell posture that shelters a small rear lane. Lower offensive impact and slow turning while sheltering. | **Mudback Breakers** — Commit to a short crushing push against a light front or structure. No sustained sheltered firing lane; long recovery after a miss. | Flank the body, use specialist penetration or force it to relocate. |
| **Deltawyrms** — Large amphibious serpents that change a crossing’s usable space. | **Floodwyrms** — Lay a temporary shallow-water corridor with a slow directed surge. Lower direct damage and water can help enemies too. | **Riftjaw Wyrms** — Lunge a short legal distance to threaten one large target. No broad terrain shaping and an exposed locked-point recovery. | Separate from their front, avoid the water pulse and punish the long body turn. |

#### The Ironroad Compact — Crossmere

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Guildblades** — Flexible paid infantry for a mixed expedition. | **Contract Blades** — Focus a selected enemy through a precise committed duel sequence. Lower escort durability and a bounded pursuit leash. | **Caravan Guards** — Protect a nearby wagon or ally with a short intercept and shield turn. Less single-target burst and no extended pursuit. | Exploit their specialized order rather than expecting universal superiority. |
| **Boltwardens** — Reliable crossbow lanes with explicit reload vulnerability. | **Longbolt Wardens** — Take a longer aim for a powerful straight shot. Slow reload and limited response at close range. | **Crankbow Wardens** — Trade penetration for quicker short-range controlled volleys. Shorter effective lane and poor value against heavy frontal armor. | Rush during reload or force movement away from a set firing lane. |
| **Roadstriders** — Light mounted scouts that pressure a flank and carry local information. | **Outriders** — Use a moving shortbow skirmish within an assigned boundary. Low impact against a braced armored front. | **Roadlancers** — Deliver a quick narrow charge then attempt a legal disengagement. Less ranged pressure and a punishable escape route. | Deny their turn space and protect ranged troops with a brace. |
| **Writbinders** — Contract ritualists who attach a clear temporary term to a target. | **Sealwrights** — Place one finite protective seal on an ally or objective. No hostile debt mark and a strict active-seal limit. | **Debtbinders** — Mark one enemy’s committed attack; a stated violation exposes its recovery. Cannot force the enemy’s choice or punish an action that never happened. | Break the marked condition or interrupt the seal preparation. |
| **Ironback Brutes** — Large hired labor-fighters that protect or break a physical lane. | **Gatebreakers** — Use a long committed tool strike against a defense or armored guard. Poor protection while recovering and weaker mobile escort. | **Ironback Porters** — Shield an escorted load and provide a bounded carried-supply capacity increase. Lower damage; capacity does not create provisions or allow a second army. | Kite their slow facing or attack the part of the formation they cannot cover. |
| **Waystone Engines** — Rare walking craft-constructs that carry a declared siege or ward role. | **Siegewalkers** — Set down to release a slow arcing strike at a defense or clustered position. Immobile during firing and no protective ward service. | **Wardwalkers** — Carry a finite moving shelter for a small convoy or channel group. Little direct damage and reduced speed while sheltering. | Pressure the exposed crew/core during setup and force relocation. |

#### The Deepcairn Pact — Stonewake

| Base family and purpose | Exclusive promotion A | Exclusive promotion B | Readable response |
| --- | --- | --- | --- |
| **Cairnguard** — Compact disciplined infantry that holds a narrow stone approach. | **Vaultguard** — Form a deep brace at a registered doorway or narrow front. Slow advance and less open-field turning. | **Ridgeguard** — Counter a large push with a short coordinated side-step and thrust. Weaker fixed doorway protection and a longer response cooldown. | Force relocation or attack around the anchored side. |
| **Flintshot Slingers** — Arcing ranged pressure that can exploit an exposed position. | **Sparkshot Slingers** — Aim a hard flint impact at a finite ward or brittle armor opening. Lower broad suppression and a longer aim. | **Echo Slingers** — A marked resonance shot briefly exposes a real channel or hidden local source. Less direct force; does not reveal the whole map. | Close the distance, use overhead protection or pressure the windup. |
| **Flintclaw Badgers** — Low quadruped flankers that use limited prepared excavation. | **Gougeclaw Burrowers** — Make a short delayed underground reposition between legal soft-ground points. Low surface defense and a visible emergence warning. | **Slateback Badgers** — Trade excavation reach for a short low braced intercept. Less backline access and slower pursuit. | Watch the marked emergence or force combat on unburrowable foundations. |
| **Echo Keepers** — Support readers of stone memory and local resonance. | **Memory Keepers** — Preserve a bounded recent recoverable wound and assist a declared repair action. No resurrection, free material creation or offensive rupture. | **Rift Chanters** — Prepare a short ground rupture that interrupts light enemies in a line. Long warning, no wound support and no effect through an invalid surface. | Interrupt the resonant channel or leave the clearly marked surface. |
| **Runeshell Guardians** — Heavy constructs that anchor a passage or punish close clustering. | **Bulwark Guardians** — Raise a finite frontal barrier while holding a fixed position. No ground shock and poor turning while raised. | **Faultguardians** — Release a slow local shock after a clearly braced windup. Less barrier protection and vulnerable recovery. | Attack the slow joints from another angle or use a specialist core disruption. |
| **Deepcairn Wurms** — Rare subterranean serpents that contest a confined route. | **Gemjaw Wurms** — A focused bite breaks a portion of a finite magical ward. Narrow impact and less area control. | **Ironcoil Wurms** — A slow visible coil controls a small lane and resists displacement. Lower burst, limited reach and no instant capture of large actors. | Exploit their long turn and the marked jaw commitment; block illegal burrow exits. |

The catalog deliberately mixes ordinary trained people, spirits, beasts and constructs. A large creature usually deploys in a small company: the current design briefs range from one engine/colossus to twelve ordinary front-line members. Those are performance and formation proposals, not recruitment statistics already balanced in play. A promotion preserves its family’s participant identity and capacity; new numeric values must be tested against its role and counter before activation.

Creature and hero catalogs share canonical faction IDs. Historical prototype keys such as `zorilor`, `fara_zori` and `luna_franta` remain explicit aliases in catalog metadata; they are not an automatic save migration. The existing wolf actor, for instance, is an interim rule/rig basis and does not instantiate all Rimewolf, Gloamfang and Ancient variants merely because they can share some motion.

## 5. One chosen hero, a fixed class, and personal progression

New Game will choose a scenario, difficulty and exactly one protagonist. That identity lasts for the whole campaign. There is no player hero recruitment, protagonist swap, second adventure leader, playable council member or heir succession. Other heroes can be rivals and NPCs, or choices in another campaign. The current playable identity is **Mara Veyne**, a **Hearthborn Oathwarden of the Ashen Crown**; the source keeps `ileana` as her historical internal alias, not a second hero.

All 156 authored concepts now have canonical `classId`, `raceId` and `factionId` fields. The future selection target is sixteen regular identities for each of nine factions plus twelve story identities. Their individual signatures, limits, solo/army use and fixed class mapping are in [HERO_ROSTER.md](HERO_ROSTER.md). Those concepts remain design-only apart from Mara's bounded starting implementation. The selection screen, 155 other playable characters and all personal/racial/class-resource trait effects are not delivered merely by storing their definitions.

### Five identity layers with separate authority

| Layer | Purpose | Permanent boundary |
| --- | --- | --- |
| Individual champion | History, relationships and one exclusive authored signature | One chosen person for the campaign; no copy of every classmate's signature |
| Class | Legal skill pool, weapon/discipline identity and allowed talent families | Fixed at creation; equipment, oaths and respec cannot grant off-class skills |
| Race / ancestry | Two proposed small passives and one situational trait | Independent of class/faction; never an inherited moral alignment or unrestricted magic |
| Faction | Starting ties, services, recruitment doctrine and obligations | A political affiliation, not ownership of all members of a race |
| Build | Four implemented attributes, equipment and future class talents/loadouts | Finite points and legal preparation inside that identity |

`HeroIdentity` and ActionRules enforce permission at command submission and queued-intent execution. A hidden or altered hotbar cannot give Mara Ember or Living Roots. Her actual skills are **Cleave and Ward**. The canonical Pyromancer fixture `vara_flint` may cast Ember, and the Druid fixture `cael_bracken` may cast Living Roots; those are separate test identities using a shared development presentation, not extra playable heroes. Unknown or conflicting identity fields are rejected. A set bonus can improve a legal Ward without teaching Ward to every class.

### Twenty classes, distinct disciplines

There are twenty classes: the original two-per-faction structure plus the **Vesper Rogue** and **Ironroad Thief**. This changes no hero count. Each catalog has six authored planned skill IDs: **120 distinct class-skill entries**, still design briefs. The six shared families—Steel, Hunt, Command, Rites, Storm and Oaths—organize effect/talent design and class synergies. They are not six unrestricted spell schools. All disciplines in the next table are proposed mechanics; none is an active class-resource system in the current build.

| Fixed class | Home faction | Class-scoped families | Proposed discipline and decision |
| --- | --- | --- | --- |
| Warlord | The Ashen Crown | Steel / Command | **Momentum:** Gain momentum by completing ordered advances or counters; spend it on a committed command. |
| Oathwarden | The Ashen Crown | Steel / Oaths | **Oath marks:** Sworn ground rewards guarding and measured retaliation; abandoning it gives up the stored benefit. |
| Ranger | The Thornweald Court | Hunt / Steel | **Quarry:** Tracking an actual target builds one bounded opening; changing quarry loses the old opening. |
| Druid | The Thornweald Court | Rites / Hunt | **Growth:** Cultivate visible patches, then consume their growth for control or recovery. |
| Spellblade | The Cloudspire Conclave | Steel / Storm | **Charge:** A completed weapon pattern prepares a charge; spend it on one named arcane follow-up. |
| Stormcaller | The Cloudspire Conclave | Storm / Rites | **Pressure:** Wind and rain spells build a forecast; discharge it along telegraphed storm lanes. |
| Death Knight | The Vesper Court | Steel / Oaths | **Debt:** Intercept real harm to bank a capped counter; debt expires and cannot be farmed on allies. |
| Necromancer | The Vesper Court | Rites / Oaths | **Remains:** Finite eligible remains power temporary summons; summoned deaths never produce more remains. |
| Berserker | The Gloamfang Clans | Steel / Hunt | **Fury:** Committed strikes build fury; spending it forces a readable recovery instead of endless chaining. |
| Moon Witch | The Gloamfang Clans | Rites / Hunt | **Moon phases:** A visible sequence alternates pursuit and restraint; each phase offers a different payoff. |
| Reaver | The Emberhorn Dominion | Steel / Command | **Impact:** Committed heavy attacks build fracture on a target; overcommitting leaves a long punishable recovery. |
| Pyromancer | The Emberhorn Dominion | Rites / Storm | **Heat:** Casting builds heat; vent it deliberately or suffer a predictable reduction in casting efficiency. |
| Wayfinder | The Reedbound League | Hunt / Command | **Route marks:** A few visible anchors enable repeatable movement tricks, with no teleportation through blocked ground. |
| Tidebinder | The Reedbound League | Rites / Storm | **Stored water:** Move water between connected patches; strong effects dry their source instead of appearing endlessly. |
| Marshal | The Ironroad Compact | Command / Steel | **Readiness:** Preparing an order costs time now to improve one later action; only one preparation may be banked. |
| Runemage | The Ironroad Compact | Rites / Command | **Inscribed charges:** Place a bounded number of visible runes; consume, reposition or combine them at real preparation cost. |
| Stoneguard | The Deepcairn Pact | Steel / Oaths | **Brace:** A timed brace catches one valid impact; carrying it slows turning until the stored force is released. |
| Earthshaper | The Deepcairn Pact | Rites / Command | **Resonance:** Valid stone anchors carry finite pulses; every obstruction preserves a readable path around it. |
| Thief | The Ironroad Compact | Hunt / Command | **Preparation:** Reconnaissance identifies real locks, traps and pockets. Spend a bounded tool supply to create an opening; each marked container or enemy can yield its registered stolen item only once. |
| Rogue | The Vesper Court | Hunt / Steel | **Openings:** A successful flank, interrupt or timed evasion opens one target. Spend that opening on a precise finisher; it expires on a target switch and cannot stack into an infinite stun. |

The currently permitted action subset is intentionally small: Oathwarden Cleave/Ward; Pyromancer Ember; Druid Living Roots; Cleave alone in the partial Warlord, Spellblade, Death Knight, Berserker, Reaver, Marshal and Stoneguard fixtures. The other class lists have no implemented active skills. That permission table does not make the partial classes available in New Game. All twenty complete playstyles, equipment identities and planned skill IDs are detailed in [CLASS_DESIGN.md](CLASS_DESIGN.md).

**Thief and Rogue are different designs.** A Thief reads a physical space: locks, traps, patrol routes, keys and optional registered loot. Its finite tools and preparation open an alternate entry or escape, and each eligible container/target can yield its registered reward only once. Its six briefs are Lift Key, Disarm Trap, False Sound, Smoke Bomb, Tripwire and Escape Line. Mandatory progress must still have a route for a non-Thief; infiltration cannot create infinite extra loot or replace combat with a decorative button.

A Rogue reads a hostile target: facing, recovery, an interrupt or a timed evasion creates one short-lived opening. Changing targets loses it; spending it commits a precise attack. Its briefs are Backstab, Venom Edge, Hamstring, Throat Feint, Sidestep and Expose Weakness. Poison has finite ticks and explicit resistance; control cannot chain into permanent boss stun. A Rogue does not automatically gain Thief keys or tools. **Neither class has implemented skills yet**, and neither borrows Mara's shield or another caster's magic as a generic placeholder kit.

### Eight races and 156 individual signatures

| Race / ancestry | Original identity | Trait status |
| --- | --- | --- |
| Hearthborn | Human lineages with varied cultures; neither a faction nor a moral alignment. | Two small passives and one situational trait; design only |
| Veilkin | Otherworld-touched people of bargains, rhythm and altered perception, not universally forest citizens. | Two small passives and one situational trait; design only |
| Gravebound | People whose lives continue under a death-related bond; still capable of kindness, appetite, law and disagreement. | Two small passives and one situational trait; design only |
| Gloamkin | People with a restrained predatory transformation, unrelated to automatic clan membership or hostility. | Two small passives and one situational trait; design only |
| Emberkin | Heat-marked lineages with diverse bodies and communities; neither fireproof nor obliged to the Dominion. | Two small passives and one situational trait; design only |
| Reedkin | Water-touched people whose homes and loyalties extend beyond the delta. | Two small passives and one situational trait; design only |
| Cairnkin | Stone-linked people shaped by memory and craft, with individual loyalties rather than an inherited profession. | Two small passives and one situational trait; design only |
| Stormmarked | People altered by a storm pact or birth event; an origin independent of ancestry politics and faction doctrine. | Two small passives and one situational trait; design only |

The roster has 156 unique personal signature IDs with a trigger, outcome and counter; structural uniqueness is not implemented uniqueness. A signature must alter a real decision in solo and field play before acceptance. Mara's **Answer the Bell**, Hearthborn traits and Oathmarks discipline are authored but inactive. The character folio displays their status rather than adding invented critical-hit, dodge or racial bonuses. A selected person who appears elsewhere in a future scenario needs an alternate NPC role, so the protagonist cannot meet an unexplained duplicate.

### Implemented levels and four useful attributes

Mara's preserved base values are 120 Health, 40 Focus, 18 Attack, 2 Armor and 4.6 movement speed. ItemRules derives the effective values from those bases, allocated attributes, actual equipment and active set thresholds. Baseline attribute scores are ten, with no automatic base bonus for those ten points. The initial items can modify maxima without healing the current resource.

Levels run from **1 to 30**. The cumulative threshold for level `L` is `100 × (L − 1) + 25 × (L − 1) × (L − 2)`: level 2 at 100 XP, level 3 at 250, and level 30 at 23,200. Only registered successful outcomes grant their declared XP. A multi-level award grants the corresponding points once; excess XP at the cap is reported and discarded. Ordinary hits, damage ticks, a menu reopen, a defeat and repeated callbacks mint no XP.

There are **three spendable points at level one and three per later level**, ninety total. Each attribute can receive at most forty investments; its displayed score is ten plus investment. All four affect a supported rule:

| Attribute | Effect per invested point | Actual decision |
| --- | --- | --- |
| Might | +1 Attack | Shorter exposure through stronger legal weapon actions |
| Finesse | +0.04 movement speed | Real approach/escape speed; no invented critical-hit or dodge percentage |
| Vitality | +6 maximum Health | More capacity after normal recovery, not a free heal on allocation |
| Spirit | +2 maximum Focus and +1 finite Ward capacity | Sustain a legal skill budget and strengthen a legal Ward; no new skill permission |

Command and Luck are reserved until actual field/luck rules justify them; the current UI does not display spendable decorative versions. Attribute points are separate from the proposed thirty talent points below.

The Character folio (**C**) edits a draft with plus/minus controls, shows the full ItemRules before/after totals, then commits once with the expected revision. Unknown keys, fractions, overspending, over-cap investments and stale previews fail without mutation. Allocation is locked during a pending encounter or incapacitation/recovery. It spends no watches and cannot increase current Health or Focus. Reducing a maximum during reset clamps the current resource rather than granting a refill.

Attribute reset requires a friendly town and no pending encounter. It is free through level ten; afterward its gold cost is `min(1000, 50 × (level − 10))`. It refunds invested points, preserves earned level/XP, changes no identity, gives no healing and does not reopen story choices. Equipment/socket/sale changes advance the same relevant revision so a stale draft cannot overwrite an intervening result. See [ATTRIBUTE_PROGRESSION.md](ATTRIBUTE_PROGRESSION.md) for the exact view and transaction schema.

### Proposed talents and class-legal preparation

The talent design is not implemented. Its finite budget is thirty points, one at each level including level one; it is **not** the ninety-point attribute budget. The existing six-family library contains 48 ordinary node briefs and six capstone briefs, to be adapted into each fixed class's permitted families and named skills. A generic root-duration brief cannot appear as a usable Oathwarden talent. Cross-family hybrids are legal only inside that class's catalog; there is no eventual purchase of every spell school.

The proposal keeps ordinary nodes at one rank and one point. A class-adapted capstone costs three, requires level eighteen and five legal ordinary nodes in its family, and has a maximum of two active capstones. The tree still requires exact prerequisites, solo usefulness and class-specific tests before implementation. Resetting a future talent loadout must never change class/race/faction, fulfill an oath, heal, refund a committed cooldown or give an off-class action.

Full production loadout targets **one innate signature plus five class-legal prepared abilities**. A mature class kit supplies its own choices; the shared twenty-four effect briefs do not define a universal learning pool. The current Mara opening uses two implemented skills and leaves her unimplemented signature inactive. Later slot/acquisition milestones must be tested in that class's progression. Every accepted champion needs a useful solo response to movement, melee/ranged pressure and recovery; a command-oriented class cannot depend on forbidden dungeon companies or a random unique to become viable.

## 6. A clear loop across two clocks

### Realm clock

The source of truth is a nonnegative integer `watchIndex`. Day is `floor(watchIndex / 4) + 1`; phase is `watchIndex % 4`.

| Index within day | Watch | Planning role |
| --- | --- | --- |
| 0 | Dawn | Production, wages, provisions and due recovery settle once |
| 1 | Afternoon | Travel, civic work and prepared expeditions |
| 2 | Dusk | Final preparations, deliveries and twilight opportunities |
| 3 | Night | Distinct creature behavior, dangerous passage and secret contracts |

Production and upkeep happen only at dawn. Rivals can act at every committed watch. Camera movement, journal reading, equipment comparison, UI navigation and command pause cost no realm time. A local building purchase is immediate and costs no watch, but uses the settlement's one construction opportunity that day.

Travel, rest, investigation, negotiation and encounters quote their time before commitment. A dungeon's two-watch quote does not become three because a player reads a tooltip, pauses combat or takes longer to aim. An internal rescue timer is measured in action seconds and stated separately. A deliberate multi-stage dungeon can quote one watch per stage, but cannot invent an unseen ongoing realm-time meter.

### Watch transaction

1. Validate the chosen action and pending locks; show expected cost and known consequences.
2. Close the current watch and evaluate obligations due at its end.
3. Advance the integer clock exactly once.
4. At dawn, snapshot current ownership and settle production, upkeep and provisions once.
5. Complete scheduled work and prepare legal, affordable rival actions.
6. Execute the deterministic rival queue. An encounter saves its queue cursor and original participants.
7. Apply its eventual result once, resume that queue and reconcile holdings and reports.
8. Return control with the three most important known changes and an expandable ledger.

If a promise lasts eight watches from index zero, its due watch is seven. It remains achievable during watch seven and breaks when that watch closes. Saving at an interruption cannot pay a dawn twice or give an army an extra move. A captured holding starts paying its new owner at the next dawn; it does not retroactively produce resources.

The current module implements the calendar, dawn settlement, finite oaths, two-watch solo commitment and a smaller uninterrupted rival frontier step. Resumable defended attack queues remain a required extension before claiming a living conquest campaign.

### Attention cost

The main forecast surfaces at most three known changes, prioritized by a threat or deadline, a shortage/recovery problem, then an arrival or opportunity. An expandable ledger retains all accounting. Routine production does not open a modal four times per day.

Advance to Event runs the same watch rules as repeated manual actions and stops before a required intervention. The current slice stops at dawn or before an unfulfilled deadline closes. The full version also stops for legal contact, a threatened holding, an oath choice and an unapproved shortage. It must not reveal a hidden army merely because that army is about to move. Harmless time can pass in one deliberate action; End Watch repetition is not a difficulty mechanic.

## 7. Realm geography, exploration and travel

The realm is a continuous-looking 3D landscape of roads, woods, water, slopes and settlements. Deterministic strategic routes are authored beneath that presentation. Route IDs record endpoints, integer watch cost, access conditions and meaningful waypoints; rendered paths follow those definitions. Saved travel progress is quantized and does not depend on an interpolated character transform.

The opening uses woodland, river and highland region IDs. The broader game expands into the nine regional identities rather than pretending that nine capitals already exist in the historical small map. Each region needs recognizable danger, an economic interest, useful discoveries, at least one safe preparation point and a contract arc that can change later travel or politics.

There are three information states. Explored geography is remembered. Current observation reveals presently visible forces and their observable composition. Dated reports show where something was seen and how uncertain that information has become. A last-seen marker is not the current army and cannot be attacked at an old coordinate.

The full observation system considers authored route distances and actual terrain occlusion. Public capitals can be known from the beginning without revealing their treasury, garrison or hidden orders. Rivals use the same observation rules. The initial realm slice uses a bounded graph-distance approximation; it must not claim that mountains or trees already block information.

An intercepted route stops at a legal contact point. An enemy does not teleport into a fight from beyond that distance. Known dangerous shortcuts can trade time for risk, but the cost and nature of the risk must be inspectable. A guarded crossing can require permission, a valid alternate route or a real encounter. Movement never silently passes through a hostile army and awards a capture behind it.

Discovery rewards should include useful information: a safe ford, a creature's binding condition, a trainer, a refuge, a local claimant or a material needed for a chosen recipe. Optional high-danger sites remain high-danger instead of scaling automatically to the hero's level. The map communicates that danger through sightings, environmental clues and a clear warning when an inspected threat exceeds the current preparation.

## 8. Dedicated towns and visible construction

A town opens its own persistent 3D panorama. The player recognizes its keep, civic court, recruitment areas, market, storage, works and perimeter. Selecting a plot focuses the camera and shows a manuscript building card with actual price, prerequisite, effect and exclusion. Successful purchase commits the building first; a brief construction/reveal animation presents that saved result. Leaving and returning reconstructs the same model. Replaying an animation cannot deduct resources or grant output.

Common buildings complete immediately. One construction or upgrade is allowed per settlement per realm day, recorded as `lastConstructionDay`; buying does not advance a watch. A purchased model appears immediately through its short visual transition. Future multi-day monuments must state their duration before purchase and use saved stages; none are silently introduced into this initial rule.

### Initial common catalog

The table reproduces the current RealmRules catalog; exact costs and effects are read from that module by the interface.

| Building / stable plot | Prerequisite | Gold / wood / ore | Current rule effect |
| --- | --- | ---: | --- |
| Granary / `grain_yard` | None | 600 / 5 / 0 | +24 food capacity; +2 food each dawn |
| Training Yard / `training_yard` | None | 800 / 4 / 4 | +2 available recruits each dawn; +2 garrison company capacity |
| Market / `market_square` | Granary | 900 / 5 / 2 | +100 gold each dawn; legal market exchange |
| Smithy / `forge_yard` | Training Yard | 1,000 / 3 / 6 | +1 hero armor for an expedition departing from this town |
| Oath Hall / `oath_court` | Granary | 750 / 2 / 3 | Safe rest restores 20 additional health and 8 additional Focus |
| Palisade / `perimeter` | None | 650 / 8 / 2 | +1 approach-delay watch and +1 garrison capacity in preparation data |
| Wharf / `riverside` | Market | 900 / 6 / 3 | +80 gold and +1 food each dawn |
| Water Gate / `riverside` | Palisade | 1,100 / 4 / 6 | +1 approach-delay watch and +2 garrison capacity in preparation data |

Wharf and Water Gate occupy the same exclusive plot. The first is a trade choice; the second commits to defense. Their preview must explain the exclusion before spending. The current rules do not implement defended assaults, so the Palisade/Water Gate approach-delay values are registered preparation data, not evidence that siege behavior already works. Their later action effects must pass an actual attack test.

`preview_construction` never mutates. `construct_building` validates ownership, catalog identity, prerequisites, exclusive plot, treasury, daily limit and pending lock before deducting all costs and recording `stage:'complete'`, `builtWatch` and level. A rejected purchase leaves the state identical. Reloading cannot reset the daily allowance.

### From a scene to a functioning town

The full town has distinct stores: material inventory, uncommitted recruit stock, paid company rosters, and completed/queued work. Twenty recruits available at a yard are not twenty armed defenders. Hiring consumes gold, eligible stock and any declared equipment. It forms or reinforces a persistent local company. That company joins the hero only during a legal visit and transfer; remote recruitment does not create a second playable army.

Production becomes visible work as its rules are implemented. A forge has input metal, a worker/tool contact, output equipment and a stopped state when blocked. A granary displays storage and handling. A mill turns in relation to its water or wind. A disabled workshop does not keep emitting an active production signal. Cosmetic residents may use simplified schedules, but their animation cannot contradict mechanical status.

The full catalog adds six recruitment-family sites per faction and branch-specific upgrades, with regional architecture. Upgrading changes the actual building assembly, service and relevant stock; it is not a label on an unchanged shed. The art estimate of 72 civic/production assemblies means nine styles of eight functional roles, not seventy-two already implemented economic systems.

### Council priorities and local autonomy

Owned towns can receive an inspectable standing policy: replenish the local guard to a paid limit, prioritize food storage, repair a damaged approach, export surplus above a reserve, or suspend an operation to honor an oath. Orders quote cost limits and authorized consequences. The council executes within those bounds and reports an exception; it does not repeatedly ask the player to approve the same ordinary work.

Troop transfers require the hero's presence and preserve the same company ID, health, veterancy, wounds and promotion. A transfer never provides a free heal. A company cannot occupy a town and the expedition simultaneously or leave while committed to an encounter. Reserve and deployed capacities are separately visible.

## 9. Economy, provisions and recovery without busywork

The starting economy uses four resources: gold, wood, ore and food. Initial stock is 2,400/16/14/24. Gold funds services and recruitment, wood supports buildings and repairs, ore supports equipment and durable works, and food provides the foundation for later expedition provisions. The existing first slice produces and stores food; it does not yet consume expedition provisions.

Additional resources enter only with a useful recipe and a visible source. Tools, medicines, textiles and supernatural materials can deepen later regional decisions. The first screen should not display dormant currencies that the player cannot use. Shared currency and local material stores need a clear distinction when transport is introduced. A UI aggregate cannot let goods teleport from an isolated town to a besieged one.

Daily production is deterministic and auditable. An input recipe cannot create output without its input. A mine changes owner on a legal capture and pays at the next dawn. Market prices and spreads are catalog data, with previews for exchange. Buying and immediately selling the same good cannot create currency. Scarcity may change trade terms through known regional state, never through an unexplained price adjustment aimed at the player's current wallet.

### Proposed full provision rule

Supply is a planning choice measured primarily as days of safe travel. Each company has a small provision weight; the hero contributes one. The ordinary expedition carries up to six days of its current daily requirement. Friendly towns offer automatic replenishment from their actual available stock when the hero departs, with the amount and payment visible. A player can lower the load, buy from a real caravan or use a different route. Adding a heavy creature changes both battle strength and the supply quote.

Consumption occurs once at dawn, independently of action duration. A two-watch dungeon does not charge extra because the player pauses. Stored food, carried provisions and delivered convoy cargo cannot all refer to the same inventory at once. Transfers deduct from the origin before adding to the destination.

The default shortage response is bounded and recoverable. The first missed dawn gives a clear warning and one fatigue step; subsequent missed dawns add steps to a cap of three. Each step reduces the declared maximum combat readiness/Focus allowance by a proposed ten percent and lowers company morale by a bounded amount. It does not kill workers, delete companies or remove basic movement, attacks and retreat. Reprovisioning and a safe rest remove the penalties through stated rules. Exact values are tuning proposals for the supply gate, not active code.

The penalty must be noticeable enough to make routes matter without creating a cycle in which being weak prevents obtaining food and every recovery attempt makes the army weaker. Safe refuge services, ordinary local work and negotiated aid remain possible when the player is poor. They consume time or create a disclosed obligation rather than fabricating elite recruits. If testing finds that supplies only create repeated compulsory visits, redesign the travel and carrying rules before adding more food types.

### Wages, expansion and debt

Paid companies have catalogued wages once wage rules are enabled; elite and mercenary forces cost more to maintain. The player sees projected balance before recruitment. A poor town can suspend nonessential services before collapsing its own recovery path. Debt has a named creditor, repayment rule and visible consequences. It cannot secretly increase every watch.

The current incapacitation recovery costs 200 gold and one watch at a friendly refuge. An unpaid portion becomes civic debt and is serviced from later income. The hero returns with one third of maximum health and zero Focus; no company is recreated. This support is implemented as a transaction, while broader capture/prisoner outcomes and every recovery branch still require their own scenario tests.

## 10. Companies, veterans, morale and prisoners

A company is a persistent family/promotion roster, not a single decorative mesh with an arbitrary stack count. In the full field engine each deployed body represents a real member. The initial content budget permits up to twelve active ordinary bodies per company, with smaller groups for large creatures. Six companies supply at most seventy-two friendly soldiers alongside the hero; extra reserves use announced reinforcement rules.

The company card shows living, wounded and dead members separately, formation/order, morale, readiness, promotion and one inspectable signature ability. An experience record belongs to the company and surviving members, not to a discarded temporary battle object. Reinforcing with inexperienced recruits has a stated effect on readiness; it does not erase veteran history or clone veteran members. Cosmetic names and battle honors can make that continuity visible without requiring management of every soldier's backpack.

### Standing orders

| Order | Default behavior | Limit |
| --- | --- | --- |
| Escort | Follow a formation offset, engage nearby threats, return | Does not chase a fleeing enemy across the arena |
| Hold | Defend an anchor; ranged members adjust locally for legal sight | Does not abandon a convoy or channel to maximize damage |
| Focus | Concentrate on a named target or objective | Pursuit boundary is visible and cannot ignore collision |
| Skirmish | Maintain a useful firing distance within an assigned area | Does not blindly retreat into unknown hazards |
| Fall back | Disengage toward a safe anchor, prioritize survival | Still vulnerable to legal pursuit and existing projectiles |

Ordinary orders cost no Focus. Automatic signature abilities use useful conditions and can be set to automatic, conserve or explicit. A player can improve a battle through timing without having to manually trigger every spear brace. Friendly troops yield locally to the hero while meaningful enemy blocking remains.

Morale is distinct from health. Casualties, isolation, an exposed flank, a fallen standard and a successful rally can change it through visible events. At a low threshold a company becomes shaken, with reduced willingness to advance. At a lower threshold it routs toward a legal exit. Rally can recover eligible nearby members after a cooldown or safe interval; it cannot teleport bodies back, resurrect losses or reset fear every frame. Faction traits change responses through explicit rules: a bloodless company may resist fear but depend on a vulnerable binding source.

Veterans should improve reliability and a narrow company specialty rather than scale all stats without limit. A veteran spear company is better at holding its promise; it is not automatically better than every counter-unit. Losing veterans matters, but replacing them is possible through ordinary recruitment and training. Training consumes actual stock, currency and time.

### Prisoners and mercenary obligations

Only eligible surviving routed or wounded actors become prisoners under a stated outcome rule. They retain origin, identity/count and condition. Capture is not an extra free duplicate added on top of enemy survivors. Prisoner transfers use the same unique-container rule as companies.

The player can ransom, exchange, release under terms or offer a supervised service contract where the culture and situation permit. Each choice states payment, relationship and security consequences. Recruitment is delayed, paid and stock-bounded, with morale or trust conditions; clicking a prisoner is not immediate free veteran conversion. A small declared prisoner capacity prevents unlimited portable wealth, and a friendly town can hold a recorded custody roster.

Mercenary contracts specify an advance, wage, term, renewal, prohibited targets and dismissal conditions. The company still counts toward six if it accompanies the hero. It cannot become a second controllable commander. An expiring contract appears in the forecast before its final watch; it cannot dissolve the army during an unannounced action timer.

These systems are full-design targets. The current isolated realm preserves small company records outside the dungeon; the action slice does not yet deploy or simulate them.

## 11. Politics through people, claims and councils

Politics connects relationships to usable realm decisions. A named person has a faction, house or community, public office, relevant interests, trust toward the protagonist, and remembered events. Trust and faction attitude are separate. A grateful ferryman may help despite a hostile league; a councilor can oppose a particular levy without becoming an enemy army.

A relationship change names its cause. “Kept the winter grain promise” and “released our prisoners” matter to relevant witnesses; a secret act does not become global knowledge automatically. The design avoids a single universal good/evil meter. Public reputation, personal trust and a specific debt have different scopes and durations.

### A small actionable council

The proposed council has four useful offices: Steward, Marshal, Envoy and Keeper. Each is an NPC assignment, never a playable hero. A Steward manages local production priorities and prepares budget warnings. A Marshal manages paid garrison plans and reports real threats. An Envoy prepares negotiated terms and tracks witnesses. A Keeper researches binding conditions, archives oaths and offers relevant clues.

Appointment changes a bounded policy or service and has a visible cost or relationship consequence. Offices do not stack dozens of hidden percentage bonuses. A councilor presents a recommendation with reasons and the actual action it would authorize. The player can accept, change limits or refuse. Dismissal preserves completed work and exposes any legitimate grievance; it does not retroactively steal previously earned resources.

### Claims and legitimacy

A claim is a structured assertion about a holding or right: claimant, target, basis, evidence, witnesses, opposed claims and a proposed settlement. Bases can include inheritance, a granted charter, restitution, continued local service or conquest. Discovering evidence can open negotiation or an alternative objective. It does not automatically transfer ownership.

Conquest can take physical control without resolving a claim. Occupation therefore affects local cooperation and the cost of maintaining that holding. A negotiated charter can grant tax rights, passage or recruitment while leaving ownership with its community. This gives the single protagonist influence beyond personal garrisoning. A claimant's later NPC succession changes who honors an agreement according to its terms, while the chosen player hero remains unchanged.

For example, a Vesper claimant presents an old burial charter over an Ashen mill town. The local council proves that protection was abandoned during a flood. The player can enforce the old right, negotiate restitution and limited ceremonial access, or reject the claim and prepare for a declared hostile response. The results change real tax/passages/relations and the encounter's objective, not only an ending paragraph.

Political complexity is introduced through one dispute at a time. The first claim screen needs a clear party, requested right, evidence, known cost and options. A genealogical encyclopedia is optional context, not a prerequisite for buying a granary.

## 12. Binding oaths, contracts and regional consequences

An oath is a saved agreement with explicit terms. It includes participants, witnesses, conditions, benefits, prohibitions, deadline where relevant, failure consequence and repair path. Accepting it is a transaction. The interface detects a known contradiction with an existing oath before acceptance; the player can renegotiate, refuse or deliberately choose the breach with its stated result.

Restoring one of the first campaign's three wards is a permanent story achievement. Governing the resulting protection can create continuing obligations. The player does not have to redo a completed restoration battle every few days to retain progress. A breach can suspend a conditional benefit, damage a relationship or open a new threat without erasing every previous success.

| Example oath | Immediate benefit | Obligation or cost | Consequence and recovery |
| --- | --- | --- | --- |
| Woodland sanctuary | Safe grove route and a negotiated Veilkin recruitment right | Reduce a named sawmill's extraction while active | Excess logging suspends that right and harms local trust; restitution and a restored boundary can repair it |
| Reconstruction charter | Full timber output and community work support | Deliver specified wood and gold by a visible watch | Failure reduces stability and delays a local service; renegotiation costs time or a different concession |
| River passage | A defended ferry and provision access | Protect a named convoy and honor its declared passage time | Lost cargo is real; compensate survivors or secure a replacement route instead of deleting the failure |
| Stone compact | An underway and engineered gate access | Maintain the shared entrance and respect extraction limits | A closed route changes travel and supply; repairing the works can reopen it |
| Burial accord | Night protection for a settlement | Recover named remains and prohibit a specified desecration | Breach changes the relevant night force's behavior and a witnessed claim, not every undead on the map |

Contracts follow investigation, preparation, confrontation and aftermath. Clues reveal an actionable fact: a source object, resistance, route, witness or alternative resolution. They cannot merely fill a progress bar while the same fight remains optimal. Where a nonviolent resolution exists, it must consume the required evidence or resource and produce its own concrete outcome. Where violence is unavoidable, understanding can still change the objective and collateral risk.

The current slice has two small registered obligations. Bread Before Winter requires a Granary within eight inclusive watches and rewards four food plus four woodland stability. Silence the Bell requires an extracted Vault clear within twelve watches and rewards 180 gold plus five stability. Their breach penalties are registered and paid once. They prove the deadline/condition/reward transaction, not the full diplomacy system.

## 13. Day, night and supernatural rules

The four-watch calendar changes opportunities and behavior, not only a screen tint. Each creature family states a day/night rule that can be understood and countered. A nocturnal hunter may gain a pursuit option at night but reveal a longer recovery after a failed leap. A bound dead company may retain health in daylight while losing a specific curse channel away from its source. A river spirit may depend more on wet terrain than on the clock.

Avoid a universal night statistic that merely makes every enemy stronger. At least some contracts, herbs, witnesses and safe paths should become available at night. Preparation includes light, shelter, information and binding terms. A ward's rule names which region, behavior or threat it affects; it does not erase all night danger everywhere.

Night remains readable. Hostile anticipation, objectives, the hero and important interactables retain controlled contrast. Optional outlines, subtitles and reduced particles preserve information. Increasing display brightness must not be the intended tactical solution. Weather also has a forecast or visible onset: rain, mist and storms can change fire persistence, sight or terrain, but environmental effects cannot hide enemy tells.

The first action slice receives the current watch in its encounter context and renders an authored scene. Broad family-specific day/night mechanics and changing realm weather remain planned; they must not be claimed from the mere presence of the context field.

## 14. Direct real-time action and shared field combat

The hero is directly controlled. A ground click requests a legal path. An enemy click requests approach and attack. Prepared abilities show target/range/footprint before commitment. Guard, dodge and basic attacks remain available at zero Focus. The first native control vocabulary is small; six company cards are introduced only when the player can use them.

Every action has anticipation, a commitment point, an active window, recovery, range/shape, cost and cooldown. The rules timeline owns those events. Animation consumes them; it does not cause a second damage event. Before commitment, a legal cancel preserves unspent resources but can impose a short restart delay. After release, an existing projectile or active hit cannot be undone for a refund. A buffered next intent is bounded and visible.

Collision and timing are meaningful. A visibly valid ordinary hit is not silently discarded by a hidden miss roll. Armor, an explicit guard, a dodge window, a finite ward or a named trait can reduce/prevent damage and produce feedback. Projectiles sweep their path and collide with the same obstacles that the native scene renders. A dodge cannot cross a sealed wall simply because the animation moves quickly.

### Optional single-player command pause

Pause freezes the authoritative action clock, AI, projectiles, cooldowns and status durations. The camera and tooltips remain usable. One replaceable hero intent can be queued in the first slice; later each company receives one pending order. The command is revalidated on resume. A permanent paused indicator makes the state unmistakable. Challenge presets may disable pause, but default content must not demand expert actions per minute.

Action time advances at thirty fixed ticks per second in the current model. Realm watches are separate. Rendering interpolates between rule states and can lower visual detail without changing the simulation. There is no claim yet of identical floating-point replay across every platform; supported-build seeds and scripted-input state hashes require explicit tests.

### Hero and army partnership

The hero is precise, mobile and versatile. Companies supply sustained output, screening, ground control and formations. In a full six-company reference encounter, an initial review target is roughly twenty to thirty-five percent of direct damage from the hero, with meaningful variation by build and objective. This is an observation target, never a hidden runtime cap. A hero skill can open a volley, interrupt a ritualist or protect a withdrawal; companies can stop a charge, expose a target or create a wet zone that makes the hero's next action useful.

Identical auras use a strongest-source or bounded stacking rule. Effects limit recipient count, area, duration and recursion. More cheap bodies cannot turn one support cast into unlimited damage or healing. A fallen soldier has one recorded identity and fate. Revival, if unlocked, applies only to eligible original participants and a finite encounter budget.

### Twenty-four shared effect briefs, restricted by class

| Design family | Four effect briefs | Distinct decisions |
| --- | --- | --- |
| Steel | Cleave; Shield Break; Riposte; Iron Advance | Arc and recovery; break guard; deliberate parry; slow protected pressure |
| Hunt | Marked Quarry; Piercing Shot; Snare; Shadow Step | Priority target; aimed lane; setup time; legal reposition |
| Command | Rally; Focus Volley; Hold the Line; Fighting Retreat | Morale; coordinated readiness; anchor commitment; survival over aggression |
| Rites | Ward; Roots; Cleanse; Boundary Seal | Finite shield; movement bind; actual dispel; protected channel space |
| Storm | Ember; Chain Lightning; Gust; Rain Call | Traveling burn; bounded jumps; displacement; wet/fire interaction |
| Oaths | Oathfire; Names Remembered; Shared Burden; Last Promise | Attuned strike; finite rescue; real transferred harm; costly protection |

This table is a retained effect-design vocabulary, not the authoritative learning list. A fixed class catalog decides which named actions can be learned and which family variants apply. Ward is legal for the Oathwarden even though a finite barrier is also a reusable Rites effect concept; the label never gives Mara Roots. Current Mara demonstrates Cleave/Ward; Ember and Roots are exercised by separate Pyromancer and Druid fixtures. The remainder and complete class kits remain design briefs. Every accepted action needs purpose, counterplay, timing, limits, UI, audio and motion. A command-oriented champion must remain viable solo without adding an unauthorized second hero or dungeon army.

### Enemies and objectives

Early enemies use two readable core actions plus a trait. Elites combine known threats or add one announced modifier. Boss phases change a problem—space, target priority, a ritual, a threatened person—rather than only adding health. Every major attack needs a tell, a legal response and an opening after a successful response.

Field victory can mean a rout, protected convoy, completed ritual, freed captives, interrupted rite or captured defensive objective. Each encounter declares what authorizes the realm consequence. Saving a convoy does not annihilate surviving attackers. Winning on a road does not capture the town behind it. A time limit does not turn an unresolved fight into an invented victory.

## 15. Solo dungeons and the Bellworn Vault

Dungeons contain the chosen hero alone. Companies remain at an entrance or designated staging point and retain their own persistent health and membership. They do not contribute hidden attacks, suffer abstract dungeon casualties or disappear because `companySurvivors` is empty. The same action rules, hero equipment and control grammar apply as in the field; the participant set differs.

### First complete loop

1. Inspect Dawnreach, accept a finite obligation if desired, buy a legal building and prepare equipment.
2. Read the Bellworn Vault briefing: two realm watches, solo participation, named stakes and extraction requirement.
3. Commit departure. The realm creates one pending transaction and advances exactly the quote.
4. Enter the real 3D arena, fight the authored group through normal action commands and navigate collision.
5. After the final enemy falls, remain in the cleared scene to inspect and collect actual dropped rewards.
6. Reach the legal exit and complete extraction.
7. Apply actual hero resources, enemy survivors and valid claims once, return to the origin and inspect/equip earned items.

The initial Vault contains two ordinary melee creatures and one larger leap attacker, with stable actor IDs. Realm actor data currently uses a shared wolf-family behavior basis; three actor instances do not represent three completed bestiary families. Their current health values are 45, 45 and 100, with a declared authored layout.

The arena spans x −10 to 10 and z −12 to 12. A dividing wall has a four-meter center doorway. Rectangles `[-10,-3,8,0.9]` and `[2,-3,8,0.9]` define its solid parts; two columns use `[-6,2,1.4,1.4]` and `[4.6,2,1.4,1.4]`. Entry is `[0,9]`, exit `[0,10]`, and the initial hero spawn is `[0,8]`. Native low/cutaway stone geometry must match those exact rules rectangles. A render-only wall or an invisible collision column fails acceptance.

### Persistence and replay

The last kill enters `cleared`; it does not close the scene or automatically scoop every drop. Victory requires legal extraction. Withdrawal while enemies remain is retreat and preserves their actual health. Dead registered actors remain dead on a revisit and can initialize any still-unclaimed registered drop. Fully resolved rewards cannot respawn for farming.

The first reward group contains Vowkeeper, Bellworn Cowl, a single choice between Mistglass Pendant and Watcher's Knot, and 240 gold. The choice is permanent for that registered reward. The protagonist must physically reach the drop and interact. The realm creates the permitted instance through ItemRules; the result cannot supply arbitrary stats or extra currency. An accepted Silence the Bell oath pays its separate 180 gold only when its condition is actually met.

The story Vault remains finite. Its unique drops, original serial, location clear flag and oath condition are separate from repeatable contracts. The full dungeon design still needs authored routes, interactable clues, optional chambers, traps with counterplay, varied bosses and exits. No corpse or claimed story reward is reset to manufacture repeatability.

### Implemented repeatable hunt board

The current board offers three curated contracts at a time, registered before departure. They use the same native Vault arena and existing Gloamfang behaviors with distinct packs and placements. This is three formations, not three new environments or procedural dungeon generation.

| Contract | Tier-one pack | Completion XP | Physical gold drop |
| --- | --- | ---: | ---: |
| The Briar Kennels | Two melee Gloamfangs and one leaping keeper | 120 | 150 |
| The Ashen Watch Cellar | Four melee Gloamfangs across the chambers | 135 | 165 |
| Moonfang Underpass | One melee scout and two leaping hunters | 150 | 180 |

Each contract also registers two item drops: one from a seven-entry gear rotation and one from a four-entry rune/gem rotation. Gear includes a normal socket base, the four Bellworn pieces outside the story cowl, Mistglass Pendant and Watcher's Knot. Materials are Cinder, Stone, Gale and Amber. The story-exclusive Vowkeeper and Cowl are excluded. Rolls derive from world seed, persistent contract ID and reward ID, never attempt number, so withdrawal and reload do not reroll an unclaimed item.

A board's tier is the hero's earned level when the board is created. Its offers remain fixed while it is active. At tier `t`, enemy maximum Health is `round(base × (1 + 0.045 × (t − 1)))`, Attack adds `floor((t − 1) / 3)`, and Armor adds `floor((t − 1) / 5)`. Completion XP adds `25 × (t − 1)` and the gold drop adds `20 × (t − 1)`. These values are transparent prototype tuning, not an accepted endgame scale or a universal live level-scaling rule.

Choosing a contract locks it until successful extraction. Entry requires the hero at a friendly town and costs exactly two watches; each re-entry quotes and pays another two. Retreat/defeat retain actual enemy Health, corpses, collected claims and fixed rolls, with no completion XP. Physically claimed items/gold are retained under the existing recovery policy; they cannot be collected again. Action duration and pause spend no extra watches.

Only an actual cleared pack plus legal exit awards the registered XP once and creates the next three offers. Uncollected hunt drops are forfeited; the UI requires an explicit choice to return for them or leave. A warning's Back action does not apply an outcome. At level 30, successful contracts still close/refresh and grant collected loot but add no XP or points. Recent history retains 32 entries; the implementation has explicit generation/attempt bounds rather than unbounded save growth.

The 128-instance pack reserves room for all remaining registered item drops before charging departure. A new hunt normally requires two free slots. A capacity failure costs no watches, selects no replacement contract and changes no state. A built friendly Market provides a legal sale route. The 458-check hunt suite earned level 30 through forty-six actual contract completions, then completed a cap run. The native 181-check route earned two completions, level 3, a real sale and a new board. These proofs establish transaction/progression functionality, not long-term content variety or human enjoyment. [HUNT_CONTRACTS.md](HUNT_CONTRACTS.md) defines the full implemented contract.

## 16. Loot, equipment and original rune recipes

Loot has several useful identities. A normal base can have the right weapon timing, requirements and sockets. A magic item can offer one or two focused properties. A rare supplies a bounded combination of compatible affixes. A set rewards a chosen combination. A named unique changes a behavior with a tradeoff. None is merely the next mandatory color in a linear replacement ladder. The structural reference is Diablo II; names, recipes, formulas, art and acquisition are original. [R3]

### Persistent equipment

| Slots | Role |
| --- | --- |
| `head`, `chest`, `hands`, `legs`, `feet` | Five visible armor pieces and set membership |
| `cloak` | Visible travel or defensive utility |
| `main_hand`, `off_hand` | Legal weapon/shield/focus combination and matching action family |
| `amulet` | Focused utility or build interaction |
| `ring_1`, `ring_2` | Flexible support, with unique-group restrictions where required |

Equipment refers to stable inventory instance IDs. ItemRules owns catalog identity, compatible slots, seeded rolls, sockets, recipes and derived stats. A result payload contains a permitted item ID and claim identity, not arbitrary rolls. JSON reload must preserve the instance and reject a substituted definition or forged affix. Equipped items must exist, fit the slot and not occupy multiple slots through a duplicate reference.

There are twelve five-piece set targets, two associated with each progression path. Bonuses activate at two and four equipped pieces, preserving room for mixed sets, rares and a distinctive fifth item. There is no compulsory five-piece super bonus. The current catalog implements all five definitions of The Bellworn Vigil, with two-piece +4 armor/+10 maximum Focus and four-piece +8 Ward capacity. Only the Cowl is in the story Vault reward group. The repeatable hunt gear rotation now provides legal acquisition of the other four definitions; this does not mean all five have finished visible 3D equipment.

Twenty-four exceptional unique targets provide the requested legendary fantasy. Their value comes from a changed decision rather than an unrestricted damage multiplier. Vowkeeper currently adds attack but makes Cleave deal fifteen percent less direct damage; successful contacts grant eight finite Ward per enemy, capped at twenty-four and applied once per cast. A stronger existing Ward wins. This gives a defensive martial alternative and prevents a recursive shield exploit.

### Sockets and crafting

Normal socketed bases, three initial runes and one gem exist in the current catalog. A socket operation consumes the actual material instance, validates capacity and compatibility, records the inserted material and recomputes the derived recipe. Ordered recipes require the exact allowed base and sequence. A gem supplies its declared property without completing a rune recipe.

The two current original recipes use the two-seat Notched Ironblade. **Hearthguard** requires Cinder then Stone and adds two armor plus four Ward capacity. **Windscar** requires Cinder then Gale and adds two attack plus 0.2 movement speed. The individual inserted rune properties also apply through the same ItemRules derivation. These recipes and values are local catalog facts, not copied recipes.

The first rules-backed acquisition path requires a completed friendly Market and the hero physically present. Its finite supply stock is two Notched Ironblades, four of each Cinder/Stone/Gale Rune, and four Cut Amber gems. It sells no rare, set or unique equipment and does not restock in this slice. Price is five times the catalog value: an Ironblade is 120 gold, each rune 50 and amber 40. Buying a base plus Cinder and Stone therefore costs 220 gold before socketing Hearthguard. Each purchase deducts stock/currency once and receives a deterministic instance ID; stock and purchase serial survive reload. Tests earn this crafting route through actual purchases and legal socket operations. The current native hunt/sale route exercises the built Market and real sale confirmation; sockets and the full set of material combinations retain their separate rule/presentation boundaries.

Later affixes use declared categories, exclusions, ranges and caps. Effects cannot trigger themselves recursively, count the same active window repeatedly or refund more resource than they cost. Equip/respec operations cannot heal, refresh a cooldown or duplicate a socket material. The renderer uses `equipmentId` to select fitted geometry and the correct grip/motion family; a tooltip change alone does not pass visible equipment acceptance.

### Implemented item sale

The Market also buys a chosen owned, valid, unequipped item while the hero is physically present at that friendly town and no encounter/recovery is pending. The preview names the exact instance, fixed catalog-value gold payment and expected revision. Confirmation removes that item and its inserted materials, pays once, advances the revision and spends no watches. Equipping, changing gear or repeating a stale confirmation cannot duplicate payment. The original reward remains claimed after sale. Crafting supplies cost five times catalog value and have finite stock; the hunt refresh does not restock the shop. No salvage system, variable merchant economy or purchasable rare/unique shop is implied.

### Reward pacing

The opening guarantees a usable normal kit, one understandable unique, one set introduction and one informed choice. Random rolls refine a build without blocking essential counters or mandatory progress. Later regions offer clear acquisition families—contracts, specialist vendors, exploration, bosses and crafting—so a player can pursue a goal without a hidden best-drop spreadsheet. Finite story rewards remain finite. The implemented hunt board states its two-watch cost, locked contract, retained losses, deterministic rolls, extraction-only XP and refresh/forfeit conditions. Its small reward rotation is a first usable progression route. Broader contracts must add genuinely different objectives and spaces rather than demand that this formation loop stand in for a complete campaign.

## 17. Rival powers, fair planning and contested holdings

Rivals have actual treasury, production, recruitment stock, companies, locations, intentions and information. They use the same costs and legal routes as comparable player forces. Difficulty may declare starting resources, force quality, aggression or planning depth. It cannot silently refill losses, ignore wages, see the hero through fog or postpone an attack because the player is losing.

A deterministic planning step evaluates affordable goals: defend a threatened holding, secure an observed unclaimed resource, contest a valuable route, fulfill an agreement, recover a damaged force, or attack an observed opportunity. A force's path and action tie-breaks are stable for a seed and state. Strength estimates help decide whether to fight; they never decide the winner of a defended encounter.

Every troop originates from paid recruitment or a declared scenario starting roster. Recruitment requires stock, resources and an eligible place. Casualties persist and wounded members remain unavailable until a valid recovery process. An army away from home cannot add members simply because the daily AI function runs. Enemy objectives can include withdrawal, preservation and negotiation; fighting to extinction is not its only valid behavior.

### Contact, conquest and queue resumption

An undefended site can change control through a legal unopposed claim. A site containing the hero, a paid garrison or a defending army requires a real action encounter. Interactive contact creates a pending transaction for the player. A remote garrison encounter runs the same shared action rules under AI control when that capability is implemented. If the engine cannot simulate it, the transaction remains unresolved; an estimate must not fabricate a result.

An opposing watch stores the ordered force IDs, cursor, remaining route budget and active encounter. Applying a result resumes the next legal action, rather than restarting the watch and moving every force twice. Ownership changes only for the declared conquest stakes. Surviving attackers and defenders are transferred to legal locations or captivity according to outcome, never deleted because a non-elimination objective was completed.

A faction is militarily defeated only when its actual remaining holdings and mobile forces meet the scenario's defeat condition. A politically subordinated faction may retain towns under an agreement. Both states are explicit. No off-screen rival can accidentally complete the protagonist's story ward or set campaign victory by taking an unrelated fortress.

### What works now

Two first-slice rivals pay from their own treasuries and finite stock, recruit at home, move along authored routes and claim neutral unguarded resources. Vesper Court mobilizes at watch twelve, Gloamfang Clans at watch sixteen. The visible view excludes private treasury/stock and distant forces. Income from a claimed mine goes to its actual owner at later dawns. These rules are tested. They currently avoid defended claims; defended attacks, interception, town capture/recapture and full opposition remain delivery requirements.

### Restraining runaway advantage

Use understandable pressure: distance, paid garrisons, limited protagonist presence, occupation cooperation, wages, supply, mutually exclusive infrastructure and rival agreements. A new conquest cannot instantly provide a full loyal army and retroactive output. Expansion can be worthwhile while creating a new defense or legitimacy problem.

Coalitions require observable shared interests, communication and a warning; they are not an invisible universal punishment for success. A losing rival may negotiate because it has real remaining assets, not receive an unlimited rescue army. A strong player should feel stronger. The goal is to preserve meaningful decisions, not force every campaign back to an artificial fifty-fifty win chance.

## 18. Functional castles and sieges

The full town defense layer uses stable perimeter segments, gate plots, tower positions and access points. Walls connect through authored snapping rules around the town; the first implementation does not require arbitrary freeform voxel construction. A wall segment has saved material, current/max integrity, connection state and a collision/cover representation. A gate has open/closed/damaged state and a legal passage. Towers have real defender access and firing origins.

The persistent town creates the assault layout. A purchased Palisade cannot turn into an unrelated stone castle when a battle begins. Destroyed segments remain damaged afterward. Repairs consume materials and the stated civic opportunity; an animation cannot quietly restore integrity. An upgrade changes appearance, access and rules together.

Defenders occupy legal firing positions, with projectiles blocked by actual geometry. A gate opened for a sortie creates a real path for both sides. A breach changes navigation. Assault devices need a defined role, crew/placement, attack cadence, collision and destruction state. No projectile can shoot through a closed gate merely because the target is on its threat list.

Siege supply is part of the same clock. Blockade prevents specified deliveries, consumes actual reserves at dawn and produces a forecast. The player may attempt relief, a sortie, negotiation, evacuation or assault. The action scene's objective can be to break a blockade, hold a gate, evacuate civilians or capture the stronghold. Each resolves only its registered stakes.

Sieges are not implemented in the new slice. Acceptance requires an actual town purchase, a resulting physical defense, a battle affected by that defense, destruction/repair, casualties, a saved outcome and a native revisit. A camera shot of a fort fails that gate by itself.

## 19. Campaign structure, failure and replay

The first campaign centers on three regional oath restorations leading to a sealed final power. The opening establishes Dawnreach, the Vault, local needs and two emerging rivals. Woodland, river and highland arcs each teach a new strategic problem while returning to the shared action and oath rules. Later chapters connect the nine powers without placing nine unexplained technology trees on the opening screen.

The three restored wards remain earned achievements. Their governing agreements determine access, support and the final approach. A conquest route secures resources and creates occupation obligations. A negotiated route trades rights and requires keeping promises. A stewardship route preserves communities and routes at the cost of some immediate extraction. These should create different playable sequences and final support, not only three textual labels after the same mission.

The broad campaign is finite and authored. Replay comes from the chosen protagonist, faction relationships, promotion branches, regional terms, route order, rival priorities, item plans and scenario variation. Seeded layouts or events may vary within validated reachability and obligation constraints. Random generation cannot place a mandatory item behind its own prerequisite or start a deadline the hero cannot meet.

### Failure states

| Failure | Persistent consequence | Recovery or endpoint |
| --- | --- | --- |
| Retreat from a dungeon | Actual hero resources and enemy health; only valid collected claims retained | Reprepare at a refuge, return to surviving enemies and unclaimed drops |
| Hero incapacitation with a valid refuge | Recovery cost, time and temporary weakness | Same protagonist recovers; no fresh replacement hero or free army |
| Company defeat | Dead and wounded members remain recorded | Paid reinforcement, recovery and changed composition |
| Lost mine or town | Lost income/service/access; real ownership change | Negotiate, recapture or adapt the route |
| Broken oath | Named relationship/benefit/stability consequence | Authored restitution, revised terms or deliberate new alliance |
| Captivity in an authored scenario | Recorded custody and a bounded escape/ransom route | Same chosen hero returns through an actual resolution |
| No legal refuge/continuation or final scenario loss | Campaign defeat under the stated mode | Review causes; reload a chosen save or begin another campaign |

The default game provides recovery without erasing the mistake. A separate ironman or permanent-death option can be a later explicit mode, never a surprise rule or a route to controlling an heir. Local saves and autosaves should support experimentation. Winning requires the final objective and declared campaign conditions, not merely a high level or a strong inventory.

### Two concrete examples

**An actual first-slice route.** At day one dawn, Mara accepts Silence the Bell and buys the Granary. The purchase spends 600 gold and five wood, appears as a completed building and consumes that day's construction opportunity. Entering the Vault commits two watches, ending at dusk. A recorded real action run defeated all three actors, physically collected four claims and extracted with 71 health and ten Focus after 507 action ticks. The realm retained both companies, paid 240 gold plus the valid 180-gold oath reward, recorded the clear and added three item instances to the three starters. The result applied once. This is evidence for that tested route, not a promise that every player's fight has those casualties.

**A planned full-realm dilemma.** At day five dawn a quarry pays its owner two ore. A visible raider reaches it in the afternoon and claims it unopposed because its paid garrison was moved to a convoy. The player can redirect the protagonist, negotiate passage from the Reedbound League or finish the convoy oath before returning. If the raider remains, recapture requires a real battle. The already paid two ore are not removed retroactively; the next dawn pays the actual owner. Delaying the response may save the promised grain while losing another day's metal. The log explains both consequences. This scenario becomes accepted only after real attack, recapture and deadline tests exist.

## 20. Interface, readability and accessibility

The interface target has a strong crafted identity: carved dark wood, aged bronze, restrained gold framing and clear parchment inner pages. The approved original reference uses flat inked half-figures, crisp outlines, restrained hatching, muted clothing colors and warm unornamented parchment. Manuscript art belongs in cards and story panels. The world and actors remain actual 3D. Rejected gilded-arch portraits, painterly busts and anatomically defective illustrations cannot be substituted as approved art. The working manuscript interface revision includes a town works folio, painted resources and commands, a Character/Inventory folio with live 3D orbit/zoom, real attribute previews, class/race/trait status, equipment comparisons and set checklists, plus a hunt board and explicit sale/forfeit confirmations. Its visual direction is still under user review, and production art remains unfinished. Approval of the flat manuscript reference is a direction for the new interface, not approval of the current running screen.

### Main screens

| Screen | Immediate information | Primary actions |
| --- | --- | --- |
| Realm | Watch/day, four current resources, hero/companies, top-three forecast, selected location | Travel preview, inspect, town, journal, advance to event |
| Town | Persistent panorama, selected plot, actual costs/effects, daily construction status | Build/upgrade, recruit/transfer, trade, rest, council services |
| Character / Inventory | Fixed class/race, trait status, level/XP, points, Health/Focus, actual gear/set totals | Implemented draft/apply/reset, compare/equip/socket/sell; future class preparation/talents must remain labeled unavailable |
| Expedition board | Three registered hunts, fixed tier/rewards/time, current contract, story entry and pack capacity | Choose or re-enter a legal hunt, inspect the story briefing, understand retained losses and spoils forfeiture |
| Company | Living/wounded roster, promotion, morale, order, upkeep | Legal transfer/reinforcement, standing order, promotion |
| Oath/claim | Parties, evidence, terms, witnesses, deadline, conflicting obligations | Accept, negotiate, refuse, inspect repair route |
| Action | Hero resources, active skills, objective, threats; six company cards only in field | Move/attack/cast, guard/dodge, orders, pause, interact/exit |
| Outcome | Actual survival, casualties, objective, loot and authorized realm consequence | Apply once, review ledger, return or recovery |

Each panel has real empty, disabled, pending and error states. A disabled purchase explains the missing condition. Inventory comparison shows actual rolled values and the affected slots. A rare item does not automatically display a green upgrade arrow because of its color. The result panel distinguishes “objective completed” from “all enemies dead” and shows surviving opponents where appropriate.

Controls are remappable. Keyboard focus, mouse selection and escape/back behavior are tested in the actual scenes. Font scale, contrast, subtitles, color-independent status marks, reduced camera shake, reduced flashes/particles and a persistent pause indicator are required. Information cannot rely solely on red/green or tiny floating numbers. Supported desktop sizes must preserve action controls and scrollable panel content rather than clip them behind decoration.

Audio communicates an event and its source: a hostile windup, guard contact, ward break, low resource, objective change or legal purchase. Critical warnings have visual equivalents. Music supports exploration, tension and aftermath without becoming a permanent maximum-volume battle loop. Separate music, effects and UI controls preserve usability.

## 21. Art, animation and material truth

Naturalistic world art uses grounded scale, readable silhouettes, weathered materials and restrained atmospheric lighting. Forests form coherent masses with believable understory; towns sit on roads and terrain rather than a noisy tabletop. Fantasy belongs in anatomy, motion, rituals and unusual architecture while people and tools retain credible weight and contact. Night and fog cannot remove the information necessary to play.

Every gameplay character requires a genuine 3D mesh/rig and appropriate motion. Sprite sheets remain historical assets and can inform cards or archival scenes; they do not meet the rebuild's actor gate. A translated static body is not accepted locomotion. An idle clip does not prove attack, hit, cast or death. Every promised equipment change requires a fitted assembly and correct hand/foot/body contact.

The art plan distinguishes definitions, unique meshes, rigs, master clips, retargeted clips, state bindings and illustrations. One promotion can share a rig while still requiring equipment, material, animation binding, effects and a card. Eight ancestry bases and approximately twelve reusable creature rig families are planning assumptions to validate against the final catalog, not downloaded complete libraries. A serpent, quadruped, wingless spirit and humanoid cannot be accepted through a single mismatched retarget.

The current motion-library inventory contains forty-six source records including a T-pose, with forty-two changing in sampled poses. Those are acquisition facts, not a complete actor library. The true 3D werewolf remains an interim creature basis, not the finished 186-creature catalog.

**Mara's accepted development material revision** contains four runtime GLBs and fourteen shared PBR maps, with an approximately 60.87 MB packed editable Blender snapshot. The base model is 41,590 triangles with fifty-three bones and twelve retained clips. The imported-scene review passed 245 native checks with ten captures, covering the actual UV/material/mipmap path and preserved rig/clip contract. The Vowkeeper and Bellworn Cowl are two fitted, textured earned-item assemblies; their current adapter passes eighteen checks including sampled roll/death clearance without moving the rules actor. This does not complete the other armor visuals or the other 155 protagonists. The material sources, exact resource evidence and remaining neckline, cowl rim, tailored deformation, face/hair, boot-map and LOD work are documented in [CHARACTER_MATERIALS.md](CHARACTER_MATERIALS.md).

The runtime preparation fix retains a bounded set of four registered scene resources and prepared textures. Six actual preview create/render/dispose cycles pass twenty-five checks and retain exactly 448,371,637 texture bytes after every close, with zero orphan nodes. Avoiding a transient per-instance Sky before assigning the shared reflection Sky closes the separately observed teardown defect. The fixed cache remains resident; this is evidence against repeated growth on that route, not zero memory use, an unlimited-duration leak guarantee or a target-GPU memory budget.

**Dawnreach now uses eight reviewed reconstructions of the original paintings.** Granary, Training Yard, Market, Smithy, Oath Hall, Palisade, Wharf and Water Gate are installed from their frozen Blender exports, totaling 408,644 triangles across the complete set. They retain three-second local Hover clips and authored RESET poses. Current construction cards use the locked original atlas at rest, hover and press. The previous mismatched eight-model set totaled 113,860 triangles; its eighty-three-check rendered-card proof, prior work/rest/re-hover report and seventy-seven-check town composition remain historical evidence of those revisions. The restored painted-card UI has its separate 218-check report. Individual reconstructed-model reviews and the final 168-check/eight-capture staged town pass are recorded in [CARD_RECONSTRUCTION.md](CARD_RECONSTRUCTION.md) and [BUILDING_RECONSTRUCTION_REVIEW.md](BUILDING_RECONSTRUCTION_REVIEW.md). The town retains its 42-degree perspective, continuous valley terrain, curved river, distant woodland, smaller keep and sixteen approach treads. Its corrected flat foundation cores, terrain-material roads, actual entrance spurs, clear Market/Smithy work areas, Wharf access/waterline and supported Water Gate inlet/channel/outlet are reviewed for development integration. The staged panorama is a populated visual fixture. The separate installed-runtime gate passes 1,506 assertions with zero failures, eight real purchases, fifteen captures and exit 0, using actual UI construction and both saved riverside branches with deliberately supplied test funds. Exported-binary results are recorded separately in VERIFICATION.md. None of these records establishes production-art acceptance or earned construction in a populated fixture.

This is **one development capital and one playable hero**. The corrected foundation boundaries, entrance access and river levels do not finish the wider environment: terrain repetition, bespoke path wear, shoreline detail, wetness, shallows and water/stone style still need production work. Lighting is one fixed daylight setup, and ambient village/vegetation reuse remains visible. Final character deformation, environment detail, continuous normal-speed motion review, lower LODs and target-hardware performance remain open. Development acceptance records a useful integrated revision without calling it photorealistic final art or nine finished faction capitals.

### Animation acceptance

| Subject | Required evidence |
| --- | --- |
| Hero locomotion | Idle, start/stop, walk/run, turn and dodge at normal speed; feet grounded and controls responsive |
| Weapon actions | Anticipation, grip, contact/release, recovery, interruption and death during an action |
| Magic | Cast preparation/release, actual effect origin, interruption, correct state and bounded readability |
| Gear | Complete sets and supported mixed slots through movement, attacks, casts and death; no exposed seams or hidden hands |
| Companies | Individual facing, formation motion, action cadence, hit/death/rout/rally without synchronized sliding |
| Creatures | Anatomy-specific gait, turning, attacks, special tells, ground contact and defeat |
| Town work | Tool and hand contact, input/output props, useful activity and truthful idle/blocked states |
| Fortifications | Gate/path synchronization, accessible towers, damaged geometry and visible repairs |

Source acquisition records creator, source URL, license, version/hash, modifications and obligations. Reusable downloads need both rights and appropriate quality. Generated illustrations and textures are inspected for anatomy, artifacts, legibility and seamless use where required. A generated scenic picture cannot be shown as evidence of native gameplay. All presentation approval is tied to an exact resource version and actual use.

## 22. Architecture, save authority and result transactions

The rebuild lives under `game/redesign/`. The existing CampaignCore and hex modules stay untouched unless an explicit legacy maintenance task requires a change. The new save uses `ruleset:'draconia_action_v1'`, currently version **4**. Genuine earlier **action** versions 1–3 migrate within that ruleset. The archived **hex campaign** has a separate version-one/version-two loader and is not converted by this migration. Any future hex-to-action import is explicit, backed up and reported; old stacks are never silently reinterpreted as companies.

### Ownership

| Component | Authority |
| --- | --- |
| `RealmRules` | Clock, resources, locations, construction, obligations, company registry, rival state, encounter registration and accepted outcomes |
| `ActionRules` | Fixed-tick movement, actions, AI, collision, damage, statuses, objectives and physical loot claims |
| `ItemRules` | Curated definitions, seeded items, legal equipment/sockets/recipes and one base/attribute/gear/set stat derivation |
| `HeroIdentity` | Canonical hero/class/race/faction mapping and legal supported class skills |
| `HuntRules` | Deterministic contract templates, offer registration, tiers, packs and reward definitions; RealmRules commits transactions |
| Content catalog | Stable faction/family/hero/building/quest/objective IDs and bounded definitions |
| Native scenes | Input, camera, rendering, animation and UI; they submit commands and display returned state |

There is one damage authority and one cost/reward authority. A scene does not add gold because an animation completed. An item panel does not duplicate combat formulas. Cosmetic randomness uses a separate source so a swaying tree cannot change enemy behavior or a loot roll.

### Current realm state

The new state has one `hero` dictionary, a unique company registry and at most six `expeditionCompanyIds`. Resources use `gold`, `wood`, `ore` and `food`. Settlements store `buildings`, `lastConstructionDay`, stock and owner. The state also contains locations/routes, rivals, regions, obligations/agreements, the current turn, a pending encounter, resolved IDs, loot claims and a bounded history. The current protagonist's internal ID remains `ileana` for continuity and resolves to canonical `mara_veyne`, with fixed `oathwarden`/`hearthborn`/`ashen_crown` IDs. `hero.level`, `hero.xp` and a bounded `progression` dictionary store four allocations, unspent points, revision and reset count. A separate versioned hunt subtree stores generation, three registered offers, active contract, attempts, persistent actors/claims and bounded history; it never reuses the story location's once-only ledger.

Inventory entries contain stable `instanceId`, `itemId`, `baseId`, quality, set/unique/equipment IDs, slot, level requirement, roll seed, bounded affixes, socket contents, recipe ID and identified state. Equipment stores references to those instances. `baseStats` remains separate from derived equipment values, so loading or equipping twice cannot compound a bonus.

The source APIs are:

```text
RealmRules.create_realm(seed = 711, setup = {}) -> Dictionary
RealmRules.calendar(state) -> Dictionary
RealmRules.building_catalog() -> Array
RealmRules.preview_construction(state, settlement_id, building_id) -> Dictionary
RealmRules.construct_building(state, settlement_id, building_id) -> Dictionary
RealmRules.supply_catalog() -> Array
RealmRules.purchase_supply_item(state, settlement_id, item_id) -> Dictionary
RealmRules.preview_item_sale(state, settlement_id, instance_id) -> Dictionary
RealmRules.sell_item(state, settlement_id, instance_id, expected_revision = -1) -> Dictionary
RealmRules.attribute_catalog() -> Array
RealmRules.progression_view(state) -> Dictionary
RealmRules.preview_attribute_allocation(state, changes) -> Dictionary
RealmRules.allocate_attributes(state, changes, expected_revision = -1) -> Dictionary
RealmRules.preview_attribute_reset(state) -> Dictionary
RealmRules.reset_attributes(state, expected_revision = -1) -> Dictionary
RealmRules.hunt_board(state) -> Dictionary
RealmRules.begin_hunt(state, contract_id) -> Dictionary
RealmRules.advance_watch(state) -> Dictionary
RealmRules.advance_to_event(state, max_watches = 4) -> Dictionary
RealmRules.accept_obligation(state, definition_id, choice_id) -> Dictionary
RealmRules.rest(state, settlement_id = "dawnwatch") -> Dictionary
RealmRules.begin_encounter(state, request) -> Dictionary
RealmRules.preview_reward(state, reward_id, item_id = "") -> Dictionary
RealmRules.resolve_encounter(state, encounter_id, outcome) -> Dictionary
RealmRules.serialize(state) -> String
RealmRules.deserialize(text) -> Variant
```

Invalid commands return a clear failure and leave state unchanged where a transaction is promised. Current catalogs and supported operations are explicit; the UI must not draw a functioning-looking button for an unimplemented garrison transfer or siege service.

### Pending encounter

The realm registers an ID, kind, origin, quoted watches, committed watch, return turn, hero snapshot, original participants, enemy actors, scene, geometry, context, objective, stakes, seed and permitted loot rewards. Presentation receives a copy. The source participants remain locked until resolution. A solo encounter has `playerCompanies:[]` and separate waiting company IDs. A hunt additionally carries its persistent `contractId`, unique attempt ID and registered XP/stakes, while using the standard solo `dungeon_clear` ActionRules objective. The native renderer does not invent a hunt result or spawn a new unregistered drop table.

`ActionRules.create` accepts that dictionary, then `submit` validates commands and `advance` consumes fixed ticks. `outcome` returns the normalized result only after a finished resolution. The current result contains schema version, encounter ID/kind, resolution, elapsed ticks, hero state, company survivors, enemy survivors, casualties, loot claims and objective progress/completion/extraction.

The realm first validates the complete result against the pending transaction. It rejects an unknown/duplicate encounter, impossible resource limits, unknown actors, invalid survivor health, mismatched objectives, duplicate reward, wrong choice, extra currency or an arbitrary item definition. It then commits hero resources, actual survivors and valid claims together and records the result ID. A second callback has no effect. The local trusted action engine remains the source of the result; validation is not a claim of a network anti-cheat system.

For a dungeon, an empty company survivor list means no company participated. The realm deliberately leaves all waiting company records untouched. Future field objectives must preserve surviving opponents even when the objective succeeds; only registered assault stakes may capture a town.

### Saving and compatibility

Saves use bounded JSON-compatible data and stable identifiers, never executable effects. Load checks numeric ranges, array lengths, identity references, item validity, company ownership/container uniqueness, building prerequisites/timing, oath state, reward history and pending snapshot geometry. JSON's numeric normalization is handled semantically so legitimate integer-valued saves load without accepting malformed numeric values.

Saving a pending encounter restores the same seed, participants, quote and reward set. ActionRules now also exposes `serialize`, `deserialize` and `restore` for a live action snapshot, validated against the trusted registered encounter. Its rules tests retain moving projectiles, statuses, queued intent, claims and extraction state rather than restarting a fight. The current native hunt route saves/restores an actual live encounter and later a completed sale/board state. This is bounded route evidence, not all possible save points. Write saves atomically with a recoverable prior version; do not overwrite a valid campaign after rejecting a malformed new file. Version-one/two/three action migration uses genuine historical fixtures. Missing identity/progression fields derive canonically, earned equipment and story claims persist, and existing pending snapshots remain unchanged. Already committed old effects may finish, but newly submitted or queued illegal class skills cannot run. Earned progression applies when the pending transaction is safely resolved rather than rewriting its registered Health/Focus limits.

Reward previews and grants call the same realm helper. Item roll seeds derive from the persistent world, location and reward identity, not from the encounter-attempt serial. Retreating and re-entering may create a new combat transaction ID, but cannot reroll an unclaimed corpse item or change the choice after preview. Current realm regression tests cover that exact story boundary. Hunt rolls use world/contract/reward identity rather than attempt serial, and their separate tests verify the same preview/grant and corpse-revisit invariants.

## 23. Performance and production budgets

The initial full-field target is the hero plus up to seventy-two friendly bodies, up to ninety-six enemies, and a hard ceiling of 192 gameplay actors including civilians, summons and objective attendants. Large creatures use smaller companies. Initial additional caps are 128 damaging projectiles and twenty-four persistent gameplay zones. These are design budgets to benchmark, not measured achievements.

Use spatial queries, bounded path updates, animation LOD, mesh LOD and culling. Visual detail may scale down without removing an important collision, telegraph, actor or objective. A gameplay cap must defer or reject a spawn through an explicit content rule, not silently omit an enemy whose attack cost was already charged. Typical encounters should stay below hard limits.

Target stable responsive play at 1080p on a named midrange desktop, with scalable settings. Actual minimum specifications and frame-rate claims require a recorded engine version, renderer, hardware, resolution, actor counts and representative stress scene. A headless test or static frame does not prove sixty frames per second. Native software-render captures can verify composition and state, but do not substitute for target-hardware performance testing.

The production plan should budget complete families, not raw definition throughput. Each accepted family requires rules, model/rig, motions, materials, effects, audio, card, recruitment/promotion service and actual play evidence. The nine town kits, eight ancestries, twelve armor sets and 156 concepts are substantial work; no credible completion schedule follows simply from counting downloaded files.

## 24. Build, test, inspect, accept or rework

Every feature moves through the same gate. Its record names an owner, requirements, dependencies, exact revision, test evidence, native inspection and disposition. Status is one of **proposed**, **implemented**, **verified**, **accepted** or **rework**. “Verified” can identify the rules portion; full acceptance additionally requires normal-speed native use and the relevant visual checks.

| Gate | Required work | Concrete rejection condition |
| --- | --- | --- |
| Define | Player purpose, costs, outcomes, content IDs, edge cases and acceptance cases | A button or asset has no meaningful implemented purpose |
| Build | Actual rule, controls, presentation and saved state | Scene-only purchase, fake combat result, placeholder action or duplicated authority |
| Test | Meaningful normal, boundary, failure and reload cases | Duplicate rewards, changed clock, lost companies, cost charged on failure |
| Inspect natively | Real input and normal-speed scene at supported sizes/cameras | Clipping, bad grip, unreadable tell, blocked control, invisible collision |
| Play | A person can understand, use, fail and recover through the feature | Success depends on hidden information or an unimplemented workaround |
| Accept or rework | Record evidence and exact resource/code version | File existence, total test count or an attractive isolated render presented as complete quality |

### High-risk acceptance cases

| Feature | Required proof |
| --- | --- |
| Single chosen hero and class | Selection fixes hero/class/race/faction; save/reload and reset preserve them; no service adds a second hero or off-class skill |
| Levels and attributes | Earned thresholds/cap, ninety-point accounting, four real effects, full preview/apply, stale rejection and no healing |
| Repeatable hunts and sale | Registered packs/rolls, retained losses, exact entry cost, extraction-only XP, once-only rewards, forfeiture, atomic full-pack failure and one real sale |
| Town purchase | Preview, buy, visible model, actual mechanical effect, leave/revisit, reload and duplicate-click protection |
| Clock | Manual and advance-to-event paths agree; one dawn settlement; inclusive deadlines; no extra watch from pause or a duplicate callback |
| Solo dungeon | Companies absent in arena and unchanged afterward; actual enemy health and physical loot; legal retreat, defeat and extraction |
| Equipment | Legal slots, exact seeded rolls, visible fitted gear, set thresholds, mixed builds and no refill/duplication exploit |
| Field company | Formation, order, collision, morale, retreat, wounds and real casualty persistence |
| Rival conquest | Paid force moves legally, attacks through actual simulation, captures, loses and retakes a holding; fog and queue resume remain correct |
| Oath/claim | Terms shown, conflicting promise detected, actual fulfillment/breach, witnesses, consequences and a valid repair route |
| Siege | Purchased geometry affects a real assault; breach/gate access/projectiles work; damage/repair persist |
| Save portability | Clean source import, rules/asset references intact, malformed rejection, versioned migration and native boot |
| Full campaign | Several earned strategic routes and setbacks with real outcomes, not a scripted injected victory |

### Delivery sequence

**Gate A — the body and blade.** Accept one clothed 3D hero, one creature, readable movement/collision, basic attack, guard/dodge, damage/death and exit. Correct grip, feet, anticipation and camera first. A rig import alone does not pass.

**Gate B — town, solo expeditions, loot, return.** The rules/native integration now covers real construction, Mara's legal Cleave/Ward kit, physical drops, a unique tradeoff, sets, choice, attributes, repeatable hunts, sale, live persistence and recovery boundaries. Complete the open art and normal-speed human-use gates before treating the loop as production accepted. Separate canonical Pyromancer/Druid fixtures exercise their legal spell presentation without giving Mara those abilities.

**Gate C — one company, then six.** Prove escort/hold/fall-back, hero yielding, formation and persistent casualties with one company; then expand to six, contrasting roles and one non-elimination objective. Dungeons remain solo.

**Gate D — a living contested region.** Add complete opposing turns, interception, defended capture/recapture, local recruitment/transfers, visible intent, one oath dispute and a repair route. No fake auto-resolve. Validate a player setback and recovery as well as an optimal win.

**Gate E — functional town defenses and political choices.** Tie purchased walls/gates/towers to actual assaults, supply and repair. Add useful council offices, a claim dispute, prisoner/mercenary terms and objective-specific consequences.

**Gate F — class progression and faction breadth.** Levels and four attributes are implemented; complete class-scoped talents, signatures, racial effects, skill acquisition and broader equipment paths, then expand by accepted faction families and regional kits. Review counters across promotions and mixed recruitment. Every new hero concept offered at New Game needs its own accepted identity, gear/motion and starting route.

**Gate G — full campaign and replay tools.** Deliver the nine powers, all target creature and hero definitions, authored regional arcs, alternate routes, scenario validation, accessibility, performance, packaging and durable saves. Earlier test totals do not waive this work. The full game is accepted only when those systems can be played together.

The roadmap has dependency gates rather than invented calendar promises. If an early control or art gate fails, rework it before multiplying content around that flaw. The user's full target remains intact; the first slice is a way to prove the foundation, not a substitute for it.

## 25. Design risks, decisions and the next concrete work

| Risk | Design response | Evidence needed |
| --- | --- | --- |
| Too many influences create a crowded game | One presence constraint, one action engine, one clock and a small first vocabulary | First-time player can explain the loop and make a useful first-day choice |
| One hero cannot answer every simultaneous threat | Forecast, finite rival plans, town autonomy, agreements and recoverable losses | Several viable responses; no mandatory teleport or second hero |
| Hero replaces the army, or army plays the game alone | Objective roles, bounded synergy, company screens and precise hero tasks | Full-field observation across different builds and composition |
| Solo dungeons invalidate command builds | Solo-compatible basic tools and meaningful alternative preparation | All accepted archetypes complete at least one varied solo route |
| Large roster is only cosmetic variation | Role/counter/promotion briefs and full-family acceptance | Each definition has a distinct useful purpose and complete presentation |
| Politics becomes opaque percentage management | Named causes, concrete rights, four useful offices and readable terms | A player predicts an agreement's material consequence |
| Food becomes repetitive tax or a death spiral | Days-of-travel display, automatic legal resupply, bounded nonlethal fatigue | Travel choices remain useful; recovery is possible from poor states |
| Town construction is decorative | Saved plot/level controls actual service and assault geometry | Buy-to-model-to-effect-to-reload tests and native inspection |
| Loot undermines every other choice | Useful normal/rare/set/unique roles, original finite recipes, caps | Multiple coherent earned builds and no dominant universal item |
| Animation and rules drift | Rule-owned timeline, exact collision and versioned visual bindings | Hit/release/cancel/death tests plus normal-speed inspection |
| Save fixes corrupt old campaigns | Separate ruleset and explicit migration | Preserved legacy load path and validated new state |

The corrected building checkpoint retains separate model, town-layout, actual-runtime and exported-binary evidence with exact source and package identities. The actual-runtime construction/save/reload route now passes; the remaining production work includes close-detail art, a coherent wider environment and measured performance on target hardware. The unchanged paintings, eight reviewed building exports and scoped town-placement correction are already integrated for development; remaining detail and wider environment work are not silently accepted by that milestone. Gate A/B evidence does not waive normal-speed human-use review or unfinished environment and actor work. Subsequent system work includes one real field company and objective-aware outcomes, followed by the rival defended-encounter queue. The fifty-four families, 108 promotions and 156 protagonist identities have named design catalogs; numerical implementation, model/animation production and playable acquisition remain unfinished. UI, art and rules consume those shared IDs. Faction-specific town works and the broader loot acquisition map are authored content work, not implicit features of existing schemas.

## 26. Sources and implementation evidence

The original rules, numbers, budgets and examples in this GDD are project proposals or local implementation facts. The following primary references support only the limited influence descriptions. Historical developer material is treated as a description of its own game or stated design intention, not as current feature verification for Draconia. Sources were checked on 22 October 2026. No substantial source text is reproduced.

- **R1 — Ubisoft:** [Heroes of Might and Magic: Olden Era unveiled at Gamescom](https://news.ubisoft.com/en-au/article/62HpoWQkAIVogVkoVk8JuJ/heroes-of-might-and-magic-olden-era-unveiled-at-gamescom). Series exploration/town/army/battle relation and stated Heroes III influence.
- **R2 — Blizzard:** [The Arreat Summit: Controls](https://classic.battle.net/diablo2exp/basics/controls.shtml). Diablo II action bindings, movement and ground-item interactions.
- **R3 — Blizzard:** [The Arreat Summit: Rune Words](https://classic.battle.net/diablo2exp/items/runewords.shtml). Distinct item compatibility and ordered socket recipes in the reference game. Draconia recipes are original.
- **R4 — Blizzard:** [Warcraft III: Hero Basics](https://classic.battle.net/war3/basics/heroes.shtml). Hero progression, abilities and troop benefits.
- **R5 — Blizzard:** [Taking Your First Steps in World of Warcraft Classic](https://news.blizzard.com/en-us/article/23317716/taking-your-first-steps-in-world-of-warcraft-classic). Character journey, exploration and world discovery.
- **R6 — CD Projekt RED:** [The Witcher 3 official overview](https://www.thewitcher.com/us/en/witcher3). Monster-hunter role and a war-torn open-world setting. No product-update claims are needed by this design.
- **R7 — World's Edge:** [Getting Started with Age of Empires II](https://www.ageofempires.com/learn-to-play/getting-started-aoe2/) and [Military & Economy](https://www.ageofempires.com/learn-to-play/military-and-economy-aoe2/). Paid buildings/units/technology and strategic economic choices.
- **R8 — Slavic Magic:** [Manor Lords developer overview](https://manorlords.com/). Stated naturalistic settlement/work and formation design aims; not an audit of the latest build.
- **R9 — Paradox Interactive:** [Crusader Kings III official feature overview](https://www.paradoxinteractive.com/games/crusader-kings-iii/about), [character introductions](https://www.paradoxinteractive.com/media/press-releases/paradox-interactive/crusader-kings-iii-welcomes-new-players-with-new-introductions), and [Crusader Kings II: Holy Fury](https://www.paradoxinteractive.com/games/crusader-kings-ii/add-ons/crusader-kings-ii-holy-fury). Character-led strategic variety, claims, court relationships and the distinction from the reference's dynastic succession. Draconia keeps one selected player protagonist.
- **R10 — TaleWorlds:** [Bannerlord Dev Blog 15/10/19](https://www.taleworlds.com/en/Games/Bannerlord/Blog/128) and [Morale](https://www.taleworlds.com/en/News/314). Morale design across campaign and battle; our prisoner/contract rules are original proposals.
- **R11 — Firefly Studios:** [Stronghold Crusader HD official press kit](https://fireflyworlds.com/press/sheet.php?p=Stronghold+Crusader+HD). Constructed fortresses, working economies and opponent-design reference. Draconia's exact wall/gate/tower rules remain its own planned implementation.

Local source evidence:

- [realm_rules.gd](../game/redesign/realm_rules.gd), [test_realm.gd](../tests/test_realm.gd), and [recorded realm result](verification-logs/realm-rules.json).
- [action_rules.gd](../game/redesign/action_rules.gd) and [test_action_rules.gd](../tests/test_action_rules.gd).
- [item_rules.gd](../game/redesign/item_rules.gd) and [test_item_rules.gd](../tests/test_item_rules.gd).
- [REDESIGN_ART_AND_ASSETS.md](REDESIGN_ART_AND_ASSETS.md) for exact acquisition, rig and license evidence.
- [VERIFICATION.md](VERIFICATION.md) for the separately recorded historical native/legacy gates. Historical passes are not silently relabeled as action-rebuild acceptance.

This GDD is a working production contract. Changes require a named decision, affected rules/content, migration implications where relevant, and a new acceptance check. The fixed single-hero campaign, real 3D presentation, visible persistent town construction and truthful outcomes remain mandatory throughout those changes.
