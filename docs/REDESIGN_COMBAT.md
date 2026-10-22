# DRACONIA — action combat and single-hero progression

**Design revision:** 22 October 2026. **Authoritative direction:** a turn-based realm map with direct, real-time hero-led combat and dungeons. **Player character:** exactly one protagonist chosen at campaign creation, fixed for that campaign; Mara Veyne is the first implementation fixture. **Field force:** the chosen hero and up to six companies. **Status:** full production design plus the v0.3 rules/native solo slice: fixed class permission, levels/attributes, story Vault, repeatable hunts and item sales. Current PBR/animated-building-hover acceptance remains pending. Design targets are not implementation or completeness claims. Display names follow the project naming catalogue; stable internal IDs such as `ileana` and `wolf` remain adapters until a migration is warranted.

This revision replaces the earlier proposed hex-combat extension. The existing hex game remains a separately testable historical baseline. Its turn structure, seven-stack limit, two-spell system and sprite characters do not define the rebuilt game. New action encounters, army battles and dungeons use one compatible ruleset. All gameplay characters in the rebuild require full 3D rigs; billboard troops cannot pass the new art gate.

## 1. The game the player should feel

Mara Veyne personally enters the danger she chooses on the realm map. In a stone vault she raises Ward, steps outside a Gloamfang's announced leap, and commits Cleave during its recovery. Mara is an Oathwarden, not an all-spells character; a Pyromancer has a different kit in another campaign. At the river crossing, the same movement, hit detection, skills and damage rules apply, but her six companies give her an army to position. She orders guards to hold the wagons, marks an enemy shaman, and leads the mobile troops around a barricade. The player is not switching between an unrelated action minigame and an unrelated strategy game.

The realm map makes an expedition consequential: supplies, watches, town services, enemy plans and promises determine what can be attempted. Action combat supplies immediate movement, timing, aiming, projectiles, enemies, loot and build expression. Company orders supply formation, counters and a reason to care about the army. Folklore contracts supply investigation and consequences. Character progression gives one persistent person a developing identity.

**The central question:** what will Mara Veyne promise, how will she prepare, and how will she personally lead the people who trust her? The distinctive system is a living oath whose obligations connect the campaign, character build and battlefield. It is not simply a night-time damage multiplier.

### What each reference contributes

These are design interpretations, not copied implementations. Heroes supplies the relation between exploration, resources, towns, armies and consequential battles [S1]. Diablo II supplies actual direct action: mouse-directed combat, equipped skills, movement, projectiles and on-field loot, rather than item names alone [S2]. Warcraft III supplies hero/unit synergy, positioning, visible abilities and counters [S3]. WoW Classic supplies a persistent journey, discovery and regions with identities [S4]. The Witcher supplies a monster-hunter perspective and consequential resolutions [S5]. We do not import their characters, factions, code, art or exact formulas. Combining references is not evidence that the result will be fun; the validation gates below exist to test that.

## 2. Non-negotiable rules

1. **One chosen player hero.** The campaign begins with one choice from the available authored roster. That person remains the only independently controlled hero on the realm map and the direct-control character in action scenes. Production selection targets 144 standard candidates (16 per each of nine factions) plus 12 story concepts; see [HERO_ROSTER.md](HERO_ROSTER.md). There is no later protagonist swap or playable-heir succession. Every dungeon interior is solo: all companies remain outside, with their persistent roster unchanged by an empty solo result. Enemy leaders, companions and stewards do not become additional player heroes. The player may command companies, but not recruit extra hero avatars to collect the map.
2. **One action system.** A sword strike, arrow, ward, poison, collision and an eligible recovery effect mean the same thing in a dungeon, a contract and a large field battle. Scenario size changes composition, geometry and objectives, not the underlying combat mathematics.
3. **Personal action and army command both matter.** Mara Veyne creates openings, survives danger and chooses priority targets. Companies supply sustained frontage, damage, protection and objective control. Neither a passive aura bot nor a solo hero who makes troops irrelevant meets the design.
4. **Low command burden, high decision quality.** Companies have reliable standing orders. Normal play does not require selecting every soldier or refreshing six short-lived buffs. Mastery comes from timing, build preparation, formation and terrain, not compulsory hotkey repetition.
5. **No base construction during combat.** Town development occurs on the realm layer. Existing gates, barricades, siege engines and repairs can be scenario objects; an action battle does not open a second economy of workers and production queues.
6. **Readable cause and effect.** A hit, dodge, resistance, blocked path or failed cast has a visible reason. Numbers and states have inspectable rules. Animation must agree with hit windows and projectiles rather than concealing them.
7. **Defeat costs something recoverable.** Losses, time, injuries and supplies matter. Learned abilities, named gear and player understanding are not erased. Recovery creates another decision, not an obligation to repeat the tutorial for an hour.

## 3. Two clocks with a clear boundary

The **realm clock** advances in discrete watches and days. Travel, rest, investigation and entering a consequential encounter consume stated watch costs. Current common town construction completes immediately without spending watches and has a separate once-per-town/day limit. The strategic system previews that cost before commitment. Opening menus, reading a contract or spending ten minutes comparing boots does not move an enemy army.

The **action clock** runs in simulation ticks and seconds only while an action encounter is running. Attack windups, cooldowns, projectiles, status duration, channeling, objective timers and company orders use this clock. A displayed forty-second convoy evacuation means forty seconds of unpaused action, not forty seconds of real-world waiting and not forty realm watches.

The four realm watches are dawn, afternoon, dusk and night. Entering a normal battle commits its declared realm watch cost. Its result is applied once on exit. Fighting slowly or using command pause does not secretly consume more campaign days. A scenario with a deliberate time connection states it explicitly: for example, three sequential dungeon stages cost one watch each, while leaving to rest advances the realm and can let a rival act. Cooldowns cannot be refreshed by briefly opening the realm map or reloading the encounter.

Weather and daylight are determined by the realm encounter snapshot. A scheduled change during a long encounter is announced in the briefing and warned on screen before it occurs. Pausing freezes the scheduled change. Night progression is not driven by the rendering frame rate.

## 4. Direct control that is simple to learn

The default mouse-and-keyboard scheme uses left-click to move or interact, and left-click on a hostile target to approach and repeat basic attacks while the target remains valid. Holding the button can update the destination; a toggle option supports players who cannot hold it comfortably. Shift-click attacks from the current position. Right-click uses the selected active skill. The implemented Mara hotbar shows only Cleave and Ward, with keys 1 and 2. Future accepted classes show their own legal actions; the production maximum is one innate signature plus five class-legal prepared slots. Additional slots do not authorize another class's spells. Basic attack, move, guard, dodge and interact do not consume an active slot.

A ground-targeted skill shows range and footprint before release. A targeted skill identifies the chosen enemy or ally. Invalid casts show a short reason without spending resources. Target assistance prefers the enemy under the pointer and may offer a configurable small selection radius; it does not aim through walls or silently retarget a dangerous spell after commitment. A move click cancels an uncommitted approach, not a projectile already released.

The initial solo control vocabulary is move, attack, one damage skill, one defense and interact. Regroup appears with the first field company. The first encounter introduces these in context. Later class-specific abilities and the currently unimplemented personal signature need their own acquisition and teaching gates. Mara's two working actions do not expand into Ember or Roots because the shared engine can simulate those effects. Advanced details remain inspectable but need not occupy the screen at all times.

Input is expressed as abstract actions from the beginning: move, attack, cast-slot, guard, dodge, interact, select-company, issue-order, regroup and command-pause. Full controller support and additional accessibility settings are later implementation gates, not claimed current features. The architecture must not hard-code gameplay around mouse-button numbers. Blizzard's D2R accessibility discussion supports reducing repetitive input and making otherwise hidden outcomes visible [S6]; our controls and assistance rules are original choices.

### Command pause

Single-player command pause freezes **all authoritative action time**: actors, projectiles, damage ticks, cooldowns, animation progress relevant to action, enemy decision updates and objective timers. It does not heal Mara Veyne or let a buff expire harmlessly. The player can inspect, change standing orders and queue a small number of commands. On resuming, commands undergo normal legality checks; the queue does not guarantee that a target remains reachable after earlier actions move it.

The initial queue is one replaceable hero intent; the current rules slice implements that bound. The later company layer adds one pending order per company. A three-action hero queue is an optional usability experiment, not an accepted requirement. Replacing an order is free. A permanent paused banner and frozen-clock icon make the state clear. Camera inspection and UI tooltips remain available. Challenge presets may disable pause, but content balance must not assume expert actions per minute. Multiplayer pause rules require a separate agreement; no network implementation is implied by this single-player feature.

## 5. The action lifecycle

Each attack or ability is data with an anticipation period, commitment point, active window, recovery, range/shape, resource cost and cooldown. These timings are gameplay, not arbitrary animation labels. Initial ordinary sword timing is a test value: about 0.25 seconds anticipation, 0.15 active and 0.35 recovery. A heavy strike may telegraph for 0.65 seconds and leave a longer recovery. These numbers require normal-speed testing; they are not accepted merely because a simulator can execute them.

Before commitment, a move or guard command may cancel an attack. Resource costs are charged at the declared commitment point. Cancelling before commitment spends neither mana nor a completed cooldown, but a brief restart delay prevents fishing for instantaneous attacks. After a projectile is released or a melee active window begins, cancelling cannot undo the hit, refund the cost or produce another active window. Input may buffer one next action near the end of recovery. Animation speed bonuses must preserve a minimum anticipation window and cannot turn every attack into an unreadable instant event.

Melee uses a swept arc, capsule or authored shape against actor collision bodies during a specified active interval. A swing records which targets it has already struck. One slash cannot damage the same actor every simulation tick unless its definition explicitly describes a multi-hit channel. Ranged attacks release projectiles at a declared release tick; projectiles use swept collision so fast arrows cannot pass through thin targets between steps. Walls, cover, allies and pierce rules are data. Spell visuals never decide their own damage independently.

There is no hidden miss roll when a visibly valid ordinary melee or projectile collision occurs. Armor reduces damage; an active guard, dodge window, barrier or explicit evasion trait can prevent it and produces feedback. Random critical hits are not required in the initial slice. Later crit effects must remain readable and cannot be the only viable source of damage. This deliberately avoids presenting an apparent physical hit as a silent statistical miss.

## 6. Health, focus, guard and recovery

Mara Veyne has health and a spell/command resource labelled **Focus** in the action UI. Ordinary movement, basic attacks, guard and default company orders remain available at zero Focus. Focus has a visible regeneration rate and a short post-cast delay; expensive burst and support abilities can exhaust it. The first realm-connected test pool is 40, with 2 per second recovery after two seconds without casting. Boundary fixtures sometimes use 100 to isolate costs. Gear can increase the maximum; starting balance remains subject to native playtesting. Derived equipment bonuses cannot make every expensive skill free.

Guard reduces damage from a readable frontal arc while slowing movement. Heavy attacks marked as guard-breaking can interrupt it. It is a reliable alternative to a dodge for players who prefer deliberate positioning. Dodge has a short displacement, a clearly defined brief evasion interval and a limited charge/recharge budget. It cannot cross impassable walls or large occupied bodies. No separate mandatory stamina bar is introduced solely to penalize ordinary walking.

Healing consumables use a small visible expedition supply count, rather than an unlimited stack of instant full-heal bottles. Their healing is delayed or occurs over a short interval, with a cooldown preventing simultaneous spam. Safe camps and towns restore supplies according to the realm economy. Action Focus can recover without a consumable, but persistent wounds, supplies and realm watches retain expedition pressure. The exact relation of exit Focus to realm recovery is handled by the campaign adapter and must be consistent across repeated entry/exit.

A defeated ordinary soldier has one identity and one recorded fate. The result separates dead, recoverably wounded and living troops. Damage, healing and revival cannot manufacture new sellable recruits. Resurrection, if unlocked, restores only eligible original participants and has a strict per-encounter or casualty budget. Saving/loading cannot replenish that budget.

## 7. Six companies that act like an army

A company has one creature family/promotion, a roster of individual bodies, a formation anchor, a standing order, morale and an inspectable signature ability. The player issues a command to the company card; soldiers carry it out within formation and collision rules. No control mode asks the player to select seventy separate entities. Friendly troops yield locally to Mara Veyne so her movement does not feel trapped inside her own force, while enemy bodies and large obstacles retain meaningful blocking.

| Order | Behavior | Boundary that prevents frustration |
| --- | --- | --- |
| Escort Mara Veyne | Maintain a selected formation offset, engage nearby threats and return | Does not chase a fleeing enemy across the whole map |
| Hold ground | Defend an anchor and protect a defined radius | Ranged troops may adjust for line of sight within the radius; they do not abandon the anchor |
| Focus target | Attack a selected enemy/company/objective until invalid or recalled | A pursuit limit is visible; soldiers do not follow a suicidal target forever |
| Skirmish | Maintain preferred ranged distance while retaining formation cohesion | Stops before backing into unknown hazards or outside the assigned region |
| Fall back | Disengage toward a safe anchor; prefer movement and survival | Can still suffer pursuit damage; not an invulnerable teleport |

Regroup gives a clear global fallback: cancel pursuits and reform around Mara Veyne or a chosen rally point. A company card shows its order, strength, health distribution, morale, key cooldown and urgent problem. An obstructed company reports “path blocked” or “cannot reach firing position” rather than silently standing still. The player can inspect a specific soldier but does not need to manage its inventory.

Company signature abilities use sensible automatic conditions by default. A guard braces before a visible charge; archers prepare a volley when a target is exposed; a support unit cleanses an important afflicted ally. The player can change an ability policy to automatic, conserve or explicit use. The first slice should prove this with a few companies before multiplying the roster. Routine orders are not tied to hero mana; exceptional rallying or magical coordination uses a hero skill slot and resource cost.

### Preventing either side of the partnership from disappearing

Mara Veyne is mobile, precise and versatile. A full company holds ground, blocks a lane, intercepts a charge and supplies sustained output more effectively than one person. Hero damage should be a significant contribution, not most of a properly fielded army's damage. Initial balance reviews aim for roughly 20–35% of direct damage from Mara Veyne in a six-company reference battle, with substantial variation by build and encounter; this is an observation target, never a hidden runtime damage cap. Dungeon interiors are authored for Mara alone. Small field expeditions can bring fewer than six companies. Neither uses automatic scaling that makes preparation or bringing troops pointless.

Hero skills create finite opportunities: break armor for a volley, interrupt a shaman, protect a retreat, displace a threat from the wagons. Company actions can create opportunities for her in return: a spear formation stops a leap, a scout exposes a weak point, a ritualist wets a cluster for a storm spell. Identical auras use strongest-source-only rules. Effects are bounded by recipient count or area so recruiting more cheap bodies does not multiply a single cast without limit.

No mandatory build is required to issue good orders or access basic counters. An Oathwarden can obtain a legal tool for spirit defenses; a Stormcaller in a different campaign must still answer a resistant foe through its own basic tools and field troops. Class-scoped Command investment improves flexibility and efficiency; it does not make default company AI deliberately incompetent for other classes.

## 8. Damage, statuses, terrain and counterplay

Damage starts from an authored weapon/skill packet and a listed damage family. Physical armor and magical resistance have explicit bounded reduction curves; common resistance cannot exceed its documented cap. Temporary damage increases within the same category add rather than multiplying endlessly. A barrier absorbs a finite amount. Friendly and hostile actors use the same core functions. Difficulty does not secretly change the arithmetic after a battle begins.

| State | What it changes in action time | Response and limit |
| --- | --- | --- |
| Burning | Visible periodic fire damage | Rain/wet interaction and cleanse; strongest application refreshes within a duration cap |
| Poisoned | Sustained damage with a distinct icon/effect | Antidote/cleanse; bloodless enemies explicitly resist it; finite tick budget |
| Rooted | Stops translation while allowing valid attacks/guard | Short duration, cleansing, ranged response; cannot permanently lock a boss |
| Chilled | Slower movement and specified recovery | Warmth/cleanse/positioning; no invisible animation desynchronization |
| Staggered | Brief interruption of a committed attack or channel | A recovery-resistance window prevents continuous stagger chains |
| Exposed | Increased damage from a named family or next eligible hit | Short window, capped stacks, obvious mark; consumed according to the tooltip |
| Warded | Finite absorption pool with visible break | Burst or dispel; refresh replaces rather than infinitely adds |
| Frightened | A morale penalty or short retreat tendency for troops | Rally, leadership or bloodless immunity; no involuntary full-screen hero loss of control |

Bosses accumulate a visible resolve meter when controlled. Filling it interrupts or exposes a special attack; afterward the boss has a brief announced resistance interval. This replaces a binary choice between permanent crowd-control locking and total invisible immunity. Ordinary foes have simpler short lockout rules. Status time is integer simulation ticks; command pause ages nothing. Refreshing a status cannot reset a damage tick so frequently that it either deals infinitely fast damage or never deals damage at all.

Terrain is physically readable. Trees/rocks/walls affect navigation and line of sight. Low cover intercepts appropriate projectiles or provides a listed protection; it is not secretly a blanket resistance against every spell. Mud slows grounded movement. Water marks wet actors and interacts with storm/fire. Fire patches have clear edges and an entry/tick cadence. Height advantages require genuine visibility, not a free bonus because a texture is brown. A nav obstacle, visual obstacle and collision obstacle must agree in acceptance tests.

Weather is forecast or announced. Rain changes fire persistence and wet interactions; mist reduces comfortable sight/targeting distance while retaining critical telegraphs; a storm warns before lightning zones. Storm visuals cannot hide the enemy's own lightning warning. Night remains playable without a brightness exploit: objectives, hostile attacks and Mara Veyne retain priority outlines and contrast. The player may reduce environmental particles without losing mechanical information.

## 9. Enemy families and varied objectives

The full roster target is **nine factions, each with six base families and two mutually exclusive promotion variants per family**: 54 base definitions plus 108 promotion definitions, **162 recruitable definitions total**. Each company chooses a branch; it does not receive both promotion abilities for the same cost. The separate neutral catalogue has **24 types including eight bosses**. Canonical names and town dependencies belong to the realm/roster design; this document does not introduce a competing faction list.

A creature earns its place through a different battlefield job. Human guards hold and intercept; archers care about lanes and cover; raiders punish an exposed flank; Tempest Sages prepare readable storm zones; Veilkin bait, reposition and protect a grove; Gravewights force attention to curse/ritual sources; Gloamfangs telegraph leaps and coordinate pursuit; Crownwyrms control space with directional breath and recovery openings. These are family behavior goals, not claims that all 162 implementations exist.

Regular enemies should use no more than two core readable actions plus a trait at first encounter. Elite versions combine known actions or add one announced modifier. They do not receive an unreadable bag of random affixes. Boss phases change the problem—space, target priority, a threatened objective—rather than simply adding health. A dangerous attack must have anticipation, an identifiable safe response and a recovery that makes successful play rewarding.

| Encounter | Victory and failure | How its plan differs |
| --- | --- | --- |
| Field clash | Defeat or rout the opposing force; survive with Mara Veyne | Formation, counters, priority targets and preservation |
| Shrine restoration | Channel/hold a marked area until the ritual finishes | Some troops protect the channel while others intercept; killing everything is not the only solution |
| Moving convoy | Escort real wagons to an exit with stated cargo integrity | Route choice, screens, pursuit and selective disengagement |
| Captive rescue | Release captives and reach an extraction zone | Divide attention without a second hero; avoid indiscriminate area attacks |
| Break the rite | Interrupt or destroy named ritual sources before completion | Movement and target selection outweigh damage to endless summoned bodies |
| Settlement assault | Complete declared gate/stronghold objectives | Only this encounter kind may authorize conquest; a road victory does not capture a town |
| Boss contract | Resolve the named threat by the selected contract route | Clues reveal responses and alternatives; phase mechanics reuse action rules |

An objective victory may leave enemies alive. The result returns their actual survivors and morale; the realm resolves displacement, retreat or continued pressure. A cargo-success result cannot be converted into an annihilation or territorial capture. Partial cargo loss can lead to a partial contract outcome with an appropriate consequence, rather than forcing a reload.

### Example: winter grain at the crossing

The briefing shows two wagons, a wet route, an ambush family and a one-watch commitment. Mara Veyne brings guards, archers, mobile raiders and a support company. At normal speed, the first howl announces a flank; a ground indicator shows the Gloamfang's leap before it commits. The player can personally dodge/counter, order guards to screen the wagons, or spend Focus on Mara's legal Ward before intercepting. A Druid in another campaign can bind the pack with Roots; a Stormcaller has its own ford interactions and lightning risks. These are distinct class routes, not interchangeable spells on Mara. The wagons continue only while the path is safe. On success, surviving wolves retreat; cargo delivery changes the settlement's supplies and the relevant promise. No second ruleset or fake combat victory is involved.

## 9A. Solo dungeons: the Bellworn Vault contract

**Every dungeon interior is hero-only.** The six company cards collapse into a compact “companies waiting outside” indicator, and the interior never spawns a hidden detachment. Mara uses the same movement, collision, action timings, armor, equipment, statuses and projectiles as in field battles. There is no second character sheet, ARPG damage conversion or dungeon-only copy of her build. Entering and returning cannot change company membership or heal soldiers through an empty result.

The first complete playable route is a town preparation screen, the **Bellworn Vault**, a named threat, physical loot, extraction and a town comparison/equip decision. The current registered encounter costs **two realm watches**; that quote is visible before entry. The first three-enemy rules fixture exists to verify the controller and adapter and takes seconds under scripted inputs. It is not the finished room count, duration or intended difficulty of a production dungeon.

### Pacing and decisions

The production Bellworn Vault should take roughly 8–12 minutes on a first cautious visit, as an authored pacing target to measure rather than a current claim. Its entrance teaches contact and a safe withdrawal. A short split route offers a readable choice: a warded archive with an environmental clue and a modest resource, or a collapsed processional aisle with a more dangerous ranged encounter and an optional cache. Both reconnect before the named guardian. The clue reveals the guardian's vulnerable recovery or a noncombat resolution condition; it never becomes an invisible mandatory quest flag for ordinary damage.

Use changes of pace: anticipation in a quiet chamber; a two- or three-foe skirmish; a short inspection or mechanism; a stronger encounter with one new pattern; the boss and reward. Do not fill every metre with disposable enemies. A few enemies that force movement, aim, guard and target selection teach more than fifty indistinguishable health bars. The first elite combines a known melee tell with a locked-position leap; later rooms introduce ranged pressure or a hazard separately before combining them.

An optional cache is valuable but not required for the main route. Picking it up under danger takes a short channel. Loot inspection may pause, but collection still requires range and action time. A loot label never intercepts a necessary move/attack input. The exit remains known and shown; “cleared” means the threat is resolved, while “extracted” means Mara actually leaves with what she collected.

### Retreat, defeat and persistence

A voluntary retreat requires reaching the entrance or an unlocked exit and completing a vulnerable extraction channel. It preserves the enemies' actual remaining health and the identity of defeated actors. Damage on the extraction tick can interrupt it; lethal damage takes precedence. Unclaimed rewards from a defeated guardian remain associated with that corpse on a revisit. Already claimed rewards are omitted from the encounter registry and never regenerated. Loading or leaving does not restore the guardian to create another drop opportunity.

On defeat the realm applies its declared recovery rules and watch cost. Equipped/named gear and learned abilities remain owned; health recovery and any carried unsecured rewards must follow a visible policy, not an arbitrary scene reset. The player returns to a viable refuge with a recovery route and cannot become permanently unable to afford another expedition. No corpse-run loop is mandatory for the core campaign. Optional higher-risk contracts can add explicit cargo stakes, but cannot silently change the universal loss rule.

Rooms, investigation flags and remaining enemies persist by registered identity. The implemented hunt board creates registered contracts separately from the finite story Vault. Each costs two watches per entry/re-entry, retains its actual enemies/claims/rolls, and refreshes three offers only after real clear plus extraction. Three formations currently reuse the same arena, not three completed dungeon maps. [HUNT_CONTRACTS.md](HUNT_CONTRACTS.md) defines its exact budgets and persistence. Main progression rewards first discoveries and meaningful resolutions, with optional repeat content supporting experimentation instead of compulsory endless grind.

### Command and Oaths without an army

Future class-legal support investment cannot become dead points in a solo dungeon. These proposed contextual applications belong only to classes that actually own the ability and are disclosed before entry. They do not grant all of them to Mara:

| Ability family | Field application | Solo application and shared limit |
| --- | --- | --- |
| Rally | Restore bounded troop morale/vigor | Mara regains a modest amount of recoverable vigor and steadies her resolve; no resurrection or full heal |
| Focus volley | Coordinate ready allied ranged attacks at a mark | Mark and empower Mara's next eligible aimed hit; consumes the same mark once and cannot manufacture projectiles |
| Hold the line | Protect an anchor and nearby formation from displacement | A small personal anchor rewards holding a position and guarding; leaving ends the benefit |
| Fighting retreat | Help companies disengage to a rally point | Brief protection while moving toward an indicated fallback point; outgoing damage is reduced during the effect |
| Names remembered | Channel rescue of an eligible original soldier | Channel a bounded self-recovery reserve at a safe moment; no automatic postmortem revive |
| Shared burden | Redirect a bounded portion of ally harm to Mara | Link to a temporary protective ward that delays a bounded portion of her own damage; delayed harm is still owed |

Capstones and ordinary nodes improve the relevant shared parameters or state their contextual replacement. An army-only casualty talent gets a clearly specified solo recovery-budget benefit. It does not spontaneously summon soldiers, turn the dungeon into an army fight, or refund the entire build. Town respec remains an option for preference, not a mandatory tax on entering a dungeon. The current two-skill Oathwarden and separate class-specific spell fixtures do not implement this full support table; it remains a class-by-class production gate.

## 10. Twenty fixed classes and a class-scoped effect library

The immutable class defines the legal skill pool. The nine factions have twenty classes: two original classes each, plus the Vesper **Rogue** and Ironroad **Thief**. Every one of the 156 champion concepts is mapped in [HERO_ROSTER.md](HERO_ROSTER.md); [CLASS_DESIGN.md](CLASS_DESIGN.md) records all twenty playstyles, disciplines and six planned skills per class. The current catalog contains **120 distinct planned class-skill IDs**, not 120 implemented actions.

The full production loadout is **one personally authored innate signature plus five class-legal prepared abilities**. Mara is a Hearthborn Oathwarden with **Cleave/Ward** now; Answer the Bell, her racial traits and Oathmarks discipline remain design-only. Pyromancer `vara_flint` provides the legal Ember fixture; Druid `cael_bracken` provides Living Roots. Only Mara is playable in the current shell. Thief and Rogue are design-only with no supported active skills. Neither receives borrowed magic while its own tools are absent.

Steel, Hunt, Command, Rites, Storm and Oaths are shared design families, constrained by a class's catalog. They organize reusable effect/talent concepts; they do not give every hero permission to learn every row below. A finite barrier can be an Oathwarden action while its effect is also discussed under Rites. Gear, race, signatures and oaths cannot bypass `HeroIdentity.class_skills` or ActionRules' submission/queued-intent validation.

The retained twenty-four briefs describe reusable decisions and counters. They are not the final total for twenty classes or a universal prepared-skill pool. Each class variant needs named acquisition, exact timing, costs, solo/field behavior, counterplay, effects, audio and native motion. Basic movement, attack, guard, dodge and interaction remain outside skill slots.

| Design family / effect brief | Action and purpose | Counter or cost |
| --- | --- | --- |
| Steel — `cleave` | A committed frontal sweep, useful against an engaged line | Recovery and limited arc; flank the caster |
| Steel — `shield_break` | A short heavy blow that staggers a guarding target | Longer tell; poor efficiency against unguarded scattered foes |
| Steel — `riposte` | Brief deliberate parry window followed by a directed response | Mistiming leaves recovery; does not answer every ranged attack |
| Steel — `iron_advance` | Slow protected advance that pushes a narrow front | Turning and speed limits; vulnerable to flanks and hazards |
| Hunt — `marked_quarry` | Exposes a selected enemy to Mara Veyne and a limited number of allies | Target survives by disengaging; no map-wide damage multiplier |
| Hunt — `piercing_shot` | Aimed projectile through a short line of enemies | Aim/release commitment and collision; no automatic hits through walls |
| Hunt — `snare` | Placed trap with arming time and a visible triggered binding | Can be avoided or destroyed; limited active traps |
| Hunt — `shadow_step` | Short reposition to a legal visible destination, with an opening strike | Cannot cross sealed walls; attack payoff requires positional use |
| Command — `rally` | Restores morale and a bounded amount of recoverable vigor nearby | Not resurrection; diminishing value on unaffected troops |
| Command — `focus_volley` | Orders eligible ranged companies to a coordinated marked target | Requires line of sight/readiness; does not conjure ammunition |
| Command — `hold_the_line` | Establishes an anchor with brief resistance to displacement | Area commitment; moving away loses its benefit |
| Command — `fighting_retreat` | Supports an orderly company withdrawal toward a chosen rally point | Trades aggression for survival; cannot erase existing projectiles |
| Rites — `ward` | Finite personal or targeted protective barrier | Can be exhausted or removed; prevents no damage after breaking |
| Rites — `roots` | Aimed binding area that limits translation | Arming/impact warning; affected enemies can still use legal attacks |
| Rites — `cleanse` | Removes specified hostile effects from an ally or dispels a boon | Targeted choice and cooldown; no benefit from a no-op cast |
| Rites — `boundary_seal` | Temporary ground seal that slows hostile entry and protects a channel | Limited zones; destroyable/avoidable depending on the scenario |
| Storm — `ember` | Aimed fire projectile with a limited burn | Collision, wet mitigation and the opportunity cost of a damage-over-time spell |
| Storm — `chain_lightning` | Lightning jumps through a bounded set of nearby enemies | Spacing and grounding; each target hit once, declining damage |
| Storm — `gust` | Directional force that interrupts light foes and breaks formation | Large bodies resist displacement; terrain limits final positions |
| Storm — `rain_call` | Brief localized wet zone with fire suppression and storm interactions | Helps some enemies too; occupies a slot without direct burst |
| Oaths — `oathfire` | Reliable focused strike, altered by a declared active oath | Finite Focus cost; cannot inherit every oath simultaneously |
| Oaths — `names_remembered` | Rescue/revive a bounded eligible casualty with a vulnerable channel | Strict original-roster cap and budget; channel can be interrupted |
| Oaths — `shared_burden` | Temporarily transfers part of a chosen ally's incoming harm to Mara Veyne | Can endanger the hero; capped transfer, no recursive sharing loops |
| Oaths — `last_promise` | A major commitment that protects an objective/ally briefly | Long recovery/cooldown and a stated later cost; not unlimited invulnerability |

A future modifier changes a shape, trigger or tradeoff within a legal class action. A recolored projectile with identical best use does not justify another ability. The older seventy-two-spell and unrestricted twenty-four-spell proposals are superseded by twenty fixed class catalogs. Reusing an effect implementation does not erase distinct class triggers, commitments, counters or permissions.

## 11. Implemented levels/attributes and proposed class talents

**Implemented:** levels 1–30, earned cumulative XP, three attribute points at level one and three per later level, for ninety total. The threshold for level `L` is `100 × (L − 1) + 25 × (L − 1) × (L − 2)`; the cap is 23,200. Registered successful story/hunt outcomes award XP once. Retreat, defeat, damage events and duplicate callbacks do not. An award can cross several thresholds; cap overflow cannot mint more points.

The hero preserves base 120 Health, 40 Focus, 18 Attack, 2 Armor and 4.6 speed. Four attributes start at score ten with zero investment; at most forty points may be invested in one. ItemRules computes effective base + attribute + gear + set totals once.

| Attribute | Real effect per point | Boundary |
| --- | --- | --- |
| Might | +1 Attack | Uses actual attack calculations; no tooltip-only power |
| Finesse | +0.04 movement speed | Changes movement, not invented critical/dodge chances |
| Vitality | +6 maximum Health | Allocation does not fill the extra capacity |
| Spirit | +2 maximum Focus and +1 finite Ward capacity | Does not teach Ward or another off-class spell |

The Character folio previews full before/after ItemRules values, then commits a whole draft against an expected revision. Invalid keys, fractional/negative values, overspending, cap breaches and stale drafts fail atomically. Allocation/reset is locked in a pending encounter or recovery. Allocation spends no watches and does not heal/refill. Reset requires a friendly town: free through level ten, then `min(1000, 50 × (level − 10))` gold. It changes no hero/class/race/faction or story promise. A shrinking maximum clamps the current resource. Inventory comparisons include real rolled gear, sockets, set totals and trait tradeoffs; they do not hardcode unrelated critical/dodge values. See [ATTRIBUTE_PROGRESSION.md](ATTRIBUTE_PROGRESSION.md).

**Planned separately:** thirty class-talent points, one at each level including the first. The six-family library has 48 ordinary node briefs and six capstone briefs, adapted into each class's permitted families and named actions. Ordinary nodes have one rank/cost one. Proposed capstones cost three, require level eighteen and five legal ordinary nodes in their family, with at most two active. A class cannot spend points in unrelated families merely to gain another class's skills. These are not ninety attribute choices and are not implemented buttons.

| Shared family | Node-design vocabulary, subject to class adaptation | Proposed capstone concept |
| --- | --- | --- |
| Steel | Arc, recovery, guard stability, counter reach, impact, advance, armor use, finishing opening | Unbroken Steel: a deliberate defense empowers one committed legal martial action |
| Hunt | Quarry, trap preparation, aimed lanes, pursuit, escape, concealment, scouting, limited tools | Grey Tracker: one bounded transfer of a quarry opportunity, never an infinite chain |
| Command | Rally, reform, coordinated readiness, anchor, retreat, recovery, preparation, supply | Living Banner: completing a useful order supports a different order; spam grants nothing |
| Rites | Legal barriers/binds, cleansing, safe channels, glyph shape/durability, concentration | A class-specific ritual capstone with bounded zones/upkeep; no universal Ward/Roots package |
| Storm | Forecast, legal fire/lightning/wind/water interactions, aim, discharge, adaptation | Storm Conductor: a bounded secondary interaction requiring real preparation |
| Oaths | Attunement, protected ground, rescue/debt, burden, channel, response, sanctuary | A class-specific oath/debt capstone with real harm-transfer and encounter bounds |

Acquisition must provide practical solo counters without mandatory random uniques. Every class tree needs exact prerequisites and legal action references. A Roots modifier cannot appear as an Oathwarden benefit; a necromantic remains system cannot be disguised as a generic mana perk. Future talent resets retain the no-heal/no-cooldown-refresh/fixed-identity invariants.

### Concrete future builds within fixed classes

**Mara's crossing defense — Oathwarden, Steel/Oaths.** Answer the Bell plus Cleave, Ward, Vowstrike, Sanctuary Line and Reckoning is a full-design example. She commits to defended space and answers real pressure; scattered ranged foes and abandoning the anchor reduce her payoff. Only Cleave/Ward currently work. Guards and archers are future field partners, never hidden dungeon participants.

**Banked furnace — Pyromancer, Rites/Storm.** The chosen Pyromancer's own signature plus Ember, Cinder Line, Flashover, Heat Mirage and Banked Flame uses placement, heat management and timed release. Strong zones demand preparation/limits; a resistant foe still needs a basic-action answer. This is a different champion/campaign, not Mara learning fire after an attribute reset. Only Ember has a current legal fixture.

**Living passage — Druid, Rites/Hunt.** The Druid's signature plus Roots, Briar Shelter, Sap Mend, Thornburst and Autumn Exchange spends finite cultivated growth on movement control or recovery. Consuming a patch gives up another use; it cannot maintain indefinite roots or free healing. Only Roots has a current legal fixture.

**Prepared entry — Thief, Hunt/Command.** A personal signature plus Lift Key, Disarm Trap, False Sound, Smoke Bomb and Escape Line exchanges finite tools/reconnaissance for access or withdrawal. Registered containers pay once; mandatory story access retains another route. The separate Rogue uses flank/interrupt/evasion openings and precise finishers, not the same tool or loot rights. Both complete kits are design-only.

## 12. Equipment, set identity and Diablo II-style loot

The loot foundation deliberately follows the distinction between an interesting base, an affix roll, a set relationship and a unique rule. Blizzard's original item and rune documentation describes that structural reference [S8–S10]. Draconia uses original names, recipes, formulas, silhouettes and acquisition paths. A drop is not merely a larger item-level number that invalidates everything from the previous region.

### Eleven slots, five visible set pieces

| Slot IDs | Function | Visual/equipment constraint |
| --- | --- | --- |
| `head`, `chest`, `hands`, `legs`, `feet` | Five armor pieces; set membership lives here | Catalogued 3D equipment IDs select fitted meshes/attachments on the hero rig |
| `cloak` | Travel, elemental or positional utility | A visible fitted cloak; physics quality cannot obscure action tells |
| `main_hand` | Weapon family, base damage and action timings | Weapon attachment, grip and matching motion family are required |
| `off_hand` | Shield, focus or legal secondary implement | A two-handed main weapon occupies this slot; incompatible items cannot quietly contribute stats |
| `amulet` | A focused defensive or ability interaction | Catalog attachment where visible; gameplay remains clear even when small on screen |
| `ring_1`, `ring_2` | Flexible affix and build support | Shared unique-group restrictions prevent equipping the same restricted named effect twice |

A set has five armor pieces and activates at **two and four equipped pieces**. The fifth can have good individual stats but does not unlock a compulsory fifth-piece super bonus. Two pieces of one set and two of another, a four-piece core with a distinctive fifth item, and mostly well-rolled rares must all be useful choices. Set count is based on unique equipped instances and compatible slots; duplicate IDs and unequipped stash items never count. Switching items cannot heal the hero, refill Focus or refresh a cooldown.

The renderer uses `equipmentId`, not guesses from item display text. A new chest mesh must fit the active rig and animation family; clipping hands, missing boots, broken shoulder motion or a different skeleton cannot be excused by a correct inventory icon. Visible changes are a real art gate. Weapon families require distinct reach/timing and coherent animations. A bow cannot be accepted with a sword swing. A secondary weapon-set toggle can follow the first weapon gate, but needs a real transition and cannot reset skill state or double-count affixes.

### Item qualities and why each remains useful

| Quality | Proposed item structure | Reason to keep it |
| --- | --- | --- |
| Normal, including socketed bases | Authored base stats and socket capacity; no random magical affixes | The right base, weapon timing, requirements and sockets support a recipe or inexpensive upgrade |
| Magic | One or two compatible rolled affixes | A focused strong property can beat a poorly matched rare; easy early comparison |
| Rare | A bounded combination of several compatible affixes, initially three to five | Flexible combinations support hybrids, resistance gaps and specialized builds |
| Set | Fixed family identity plus narrow roll ranges and two/four-piece interactions | A coherent play pattern with a real slot opportunity cost |
| Unique | Named authored behavior, fixed identity and bounded rolls | Changes a skill or rule with a tradeoff; not automatically stronger in every stat |

The **24 exceptional named items** are uniques, not a sixth “legendary” rarity that universally replaces the others. Crafted and socket-recipe results retain declared identities and compatibility; crafting is an acquisition process rather than permission to bypass caps. A useful normal socket base can be more exciting than an irrelevant rare. A useful rare can remain equipped beside a unique through the final region.

Affixes belong to categories with exclusions and hard numeric bounds. A roll stores its affix ID, tier, rolled value and published range. The same-category offensive bonuses add before a bounded final modifier; procs have eligibility rules and internal limits. A damage proc cannot recursively trigger itself, generate Focus from its own secondary tick, or count one hit several times because the visual spawned extra particles. Resistances, action-speed floors and shield replacement are explicit. Not every affix needs a novel system: dependable health, Focus, armor or a specialist resistance can fill a real gap without hidden scaling.

| Original affix concept | Effect and useful decision | Limit |
| --- | --- | --- |
| Watchfire | Successful frontal guard strengthens the next ward | One short trigger window, strongest finite shield replacement |
| River-written | A final lightning jump can bridge a slightly wider wet gap | Final jump only; no revisits, declining damage |
| Long-road | A useful regroup briefly reduces mud slowdown | No benefit from repeated identical orders; solo fallback applies to a legal retreat action |
| Quietus | Interrupting a real channel weakens the next hostile channel briefly | Boss resolve protection remains; no payoff from a nonexistent cast |
| Shepherd's | Removing a real ailment grants a small recovery | No benefit on unaffected targets |
| Bramble-bound | A root ends in a short slow | Cannot renew hard control indefinitely |
| Copper Edge | A physical hit is efficient against a finite ward | Specialist value instead of a universal damage multiplier |

### Twelve set targets and twenty-four unique targets

The full-game target is **two five-piece sets per path: twelve set identities**, plus **four unique behavior concepts per path: twenty-four named uniques**. Names, equipment IDs, art and exact values belong to the root-owned catalogue. The table below defines distinct mechanical briefs, not twenty-four implemented items or additional display canon.

| Path | Set A: two-piece direction → four-piece behavior | Set B: two-piece direction → four-piece behavior | Four unique behavior briefs |
| --- | --- | --- | --- |
| Steel | Efficient deliberate guard → next committed strike gains a short opening | Stable forward armor → a slow advance leaves one protected retreat lane | Cleave trades damage for ward; riposte changes arc at a longer recovery; shield-break transfers some force to adjacent guard; heavy blade delays the hit but cracks armor |
| Hunt | Reliable mark duration → a resolved marked quarry transfers one weaker mark | Trap preparation → a sprung trap opens a limited reposition window | Piercing shot gains one bend at lower damage; snare becomes a trip line at higher setup time; quarry reveal improves aim but removes bonus range; step leaves a short decoy without damage |
| Command | Rally/resolve efficiency → a useful different order gains a bounded follow-up | Anchored protection → a legal fallback preserves one readiness benefit | Volley becomes a narrower synchronized shot; rally exchanges vigor for Focus; anchor moves slowly but protects less; retreat creates an interruptible rear guard ward |
| Rites | Ward efficiency → ward break produces one short protective response | Seal duration → two smaller compatible seals replace one large seal | Ward converts some capacity into delayed recovery; roots trade radius for a longer bind; cleanse can remove one boon at added Focus cost; seal follows briefly but loses its stationary protection |
| Storm | Controlled burn → an earned ignition exposes a short lane | Weather preparation → bounded wet interactions shape a final strike | Ember splits once with reduced per-projectile force; chain lightning trades jumps for one stronger last jump; gust trades distance for width; rain shortens fire duration but also dampens the caster's fire |
| Oaths | Recovery discipline → one successful eligible rescue protects the next channel | Oath attunement → a kept encounter obligation changes one finishing action | Oathfire changes its damage family at a cost; remembered names shorten one channel with a smaller recovery; shared burden delays rather than removes some harm; last promise anchors protection and constrains movement |

Every set supports a solo interpretation where needed. Set stats alone cannot compel a Command player to field companies inside a dungeon. A nominal full set is not accepted until all five visible equipment variants, both bonus thresholds, mixed-set validation and an actual play use are complete. Bonuses that merely multiply all damage by a huge amount fail the brief.

### Concrete first loot and an earned choice

The Bellworn Vault registry offers a named weapon, a set piece and one choice after the named guardian. **Vowkeeper** (`oathkeeper_blade`) carries `cleave_ward`: Cleave's base damage is multiplied by **0.85**, and actual successful contacts grant **8 finite ward per enemy**, capped at **24**, with **one ward application per cast**. An existing stronger ward wins; there is no recursive shield trigger. This behavior is implemented and covered by the action rules tests. It creates a defensive martial choice instead of an unconditional upgrade.

**Bellworn Cowl** (`bellwarden_hood`) is the initial set piece. The first catalogue implementation specifies a two-piece bonus of **+4 armor and +10 maximum Focus**, with the four-piece effect adding **8 finite capacity to Ward**. The action model reads the derived `wardBonus` rather than counting raw inventory IDs itself. Owning one hood does not grant either threshold; equipping additional earned pieces is necessary. More elaborate set behavior remains subject to the production briefs above.

The choice reward is **Mistglass Pendant** (`mist_amulet`, magic) or **Watcher’s Knot** (`sentinel_ring`, rare). The comparison panel must show the actual catalogue rolls and slot effects before selection. It cannot invent a better reward after the player chooses. Once the claim is made, the other option becomes unavailable for that registered reward. A rare and a magic item can therefore present a real build choice without pretending the color alone decides it.

### Sockets, gems and original inscription recipes

Socket compatibility is explicit on the base. A gem supplies a predictable small effect by slot; a rune supplies its own declared effect and may participate in a discovered inscription recipe. Recipes specify allowed base families, exact socket count, quality rules, ordered components and resulting behavior. The initial proposal restricts inscription recipes to compatible normal bases, so a generic socketed magic item does not silently satisfy the recipe. The UI previews compatibility and the proposed result before consuming materials. Exact socket limits and all recipes are original catalogue data, not copied Diablo combinations.

A base is meaningful through attack profile, requirements, material identity and sockets; upgrading it cannot make an incompatible animation family work. Normal gems/runes remain useful through transparent limited conversions or crafting, without requiring an auction economy. Recipes are learned through exploration, a service or a contract and remain in a visible journal. A player can pursue a known useful recipe without consulting an external wiki. Unsocketing has an explicit cost and retention/destruction policy shown before confirmation; no silent loss of a unique component.

### Deterministic drops, inventory and ownership

An encounter uses its stored seed and drop-table version. Item rolls are fixed when their registered reward is created, not when the player repeatedly opens a tooltip. An item instance has a stable identity and stores its roll seed and resolved values. A save does not reroll affixes. A reward claim identifies its source encounter/reward; applying the same result twice cannot create another copy. Choosing one reward resolves one branch of that claim. Live action code returns registered claims; the realm/item layer validates, creates and owns instances.

The production inventory has a finite declared capacity, a town stash, sorting/filtering and clear equipment comparison. The current cap is 128 inventory instances. Before a hunt, RealmRules reserves space for every still-unclaimed item reward; capacity failure spends no watches and mutates no contract. A town stash, material stacking, sorting/filtering and different carried/stored limits remain production decisions. The existing cap is not a functioning thirty-six-slot inventory or finished stash UI. Loot filters can hide known low-value labels while preserving a show-all toggle and always identifying quest rewards. Filter presets should teach what they hide and let the player keep useful socket bases visible.

Compare raw base, affixes, current rolls/ranges, requirements, socket contents, set thresholds and any changed skill behavior. A single green damage arrow is insufficient for a weapon that loses damage and gains protection. Sale is implemented with a built friendly Market, physical hero presence, no encounter/recovery, an owned valid unequipped item, catalog-value price and matching revision. Confirmation removes that instance and socket contents once, preserves the reward claim and spends no watches. Salvage and unsocket are separate proposed transactions, not working buttons. Town stash and return-to-dungeon corpse loot support experimentation without infinite bag pressure. No bulk action consumes a protected named reward without explicit selection.

The current ItemRules module is authoritative. A bounded instance uses:

```text
ItemInstance {
  instanceId, itemId, baseId, equipmentId, slot,
  quality: normal | magic | rare | set | unique,
  requiredLevel, rollSeed,
  affixes: [{id, stat, tier, value}],
  sockets: {capacity, contents: [{itemId}]},
  setId, uniqueId, recipeId, identified
}
```

Display names are localized catalogue fields. `equipmentId` maps to tested 3D appearance. The two ring slots share the catalog's uniqueness restrictions; current instances use `uniqueId`, not an invented stored `uniqueGroup`. The inventory accepts stable instance IDs, never an untrusted dictionary that directly adds arbitrary combat stats. Action snapshots receive derived `hp/maxHp/mana/maxMana/attack/armor/speed/traits/wardBonus`; temporary action statuses do not leak into permanent item rolls.

## 13. Living oaths, consequences and anti-grind

An oath has a beneficiary, a benefit, an obligation, a warning and a way to repair or renegotiate it. A forest oath can grant Veilkin support and safe paths while forbidding exploitation of named sacred woods. A river oath can improve supply and weather preparation while obliging aid to both banks. A mountain oath can enable stormcraft while demanding participation in a dangerous night rite. The player reads the concrete cost before accepting; there is no surprise moral tax on an unrelated button.

Battle abilities can respond to an active oath, but one build cannot equip every oath's strongest rule simultaneously. A secondary influence gives a smaller declared benefit. A fulfilled promise changes a place, service or relationship. A broken promise can create an investigation, hostile faction response or repair contract rather than merely reducing a global happiness number. Neither an entire folklore people nor a real Eastern European community is treated as inherently evil.

The full campaign should reward discovery, authored resolution and meaningful contracts, including a demanding negotiated route. The current hunt prototype awards registered completion XP after clear plus legal extraction and has an explicit tier/reward curve. Its recorded forty-six-contract level-30 route is a functionality proof, not production anti-grind pacing. Damage, healing, summons and status ticks do not separately award experience. A thoughtful negotiated resolution grants comparable progression to a similarly demanding fight. Enemy armies do not grow invisibly every time the player waits or levels up; strategic threats have finite resources, plans and telegraphed movement.

Town growth is useful but not linearly self-multiplying in every dimension. Services, limited recruitment pools, travel and local obligations force priorities for one hero. Dangerous optional regions remain dangerous until the player is prepared, while returning to an earlier region should reveal earned strength. Universal automatic scaling that erases both danger and progress is outside the design.

On defeat, the campaign applies a declared watch/supply consequence, returns Mara Veyne to a refuge and records casualties or recoverable wounded. Named gear and learned abilities remain. A bounded fallback force prevents a bankrupt soft lock and cannot be farmed or sold for profit. Recovering supplies can become a new objective. Retreat requires reaching or channeling at a valid exit unless a scenario explicitly offers an emergency withdrawal; it is not an invulnerable menu teleport at any instant.

## 14. Presentation, animation and readability

Every gameplay character in the new build uses a full 3D rig. Temporary capsules may verify technical collision locally but cannot pass feature acceptance. The old sprite troops are historical prototype assets. A skinned file with clip names is insufficient: actual deformation, full body, feet, attachments, transitions and action timing must be inspected in the native renderer.

Each playable weapon/action family needs idle, start/stop, locomotion, attack anticipation/active/recovery, hit reaction, appropriate cast or release, guard/dodge where used, and defeat. Company models need coherent movement, attack, ranged/cast and morale/retreat states. A unit with no bow-release animation cannot be accepted as a finished archer. Material tint alone cannot make distinct promotions readable; weapon silhouette, armor, stance or authored effects must carry the distinction.

An authoritative rules event drives the visual sequence. Foot planting must match ground and speed; turning must not twist a planted torso through an impossible angle; projectiles must leave the hand/weapon at the release time; damage and hit reaction occur when the active shape reaches the target. Root motion may inform presentation, but it cannot move an actor through authoritative walls or alter the result at different frame rates. A dead actor cannot continue emitting damaging projectiles from a looping animation.

Visual priority is Mara Veyne and immediate threats, then the objective, selected company and ordinary battlefield activity. Enemy heavy attacks use consistent shape/edge/colour conventions and sound, with patterns not dependent solely on colour. Particle brightness, camera shake and impact pauses have limits. Weather, foliage and loot cannot hide the safe response. Screen shake and decorative effects can be reduced without removing telegraph information. Large spells should feel forceful without making every basic attack equally loud; the importance of readable effects under varying light is also discussed by Blizzard's VFX developers [S7].

### UI acceptance per panel

The current HUD contains Health/Focus, Mara's two legal skill slots, objective and compact threat/loot information. Production expands toward one signature plus five class-legal prepared actions and six company cards only in field encounters. Solo dungeons keep the army outside. It does not permanently display an encyclopedia, inventory, tactical grid and kingdom economy over the battlefield. Character, spell/talent, company, inventory and contract panels pause or obey an explicit menu rule and return focus correctly. Each panel needs real input tests, useful empty/error states, readable smaller-window layouts and a way back without losing commands or a pending result.

A new feature is accepted only after rules, UI and animation are tested together at normal speed. Watching a scene at twenty-times speed establishes automation behavior, not animation quality. A generated screenshot is not evidence of a working panel. Foliage and portraits are not substitutes for animated gameplay characters.

## 15. Performance and simulation budgets

Proposed initial desktop content limits are **Mara Veyne plus up to 72 active friendly soldiers** (six companies, at most twelve active bodies each), **up to 96 active enemies**, and a hard total of **192 gameplay actors** including civilians, summons and objective attendants. Large creatures consume more spatial budget and normally have smaller company sizes. Each active body represents one real roster participant, not a disguised stack of hundreds. Additional campaign reserves can enter through announced reinforcement points within the limit; they are not silently compressed into one body's damage.

Initial caps also include 128 active damaging projectiles, 24 persistent gameplay zones and bounded status lists per actor. Decorative particles have a separate scalable budget. Spawning over a gameplay cap must defer or reject through an explicit rule, never drop an important enemy invisibly. A projectile limit cannot make an enemy's attack cost disappear while losing the projectile. Content authors should stay below hard caps in normal play.

The current model advances at **30 fixed ticks per second**, with rendering and interpolation independent. This cadence is a rules choice, not a measured real-time performance achievement on production hardware. Spatial buckets limit nearby collision/target queries. Pathfinding uses cached local routes and a bounded update budget rather than running a complete search for every actor every frame. Animation LOD, mesh LOD and culling reduce visual cost without changing simulated hits, morale or objectives.

Acceptance targets must name hardware, renderer, resolution and scene. The initial aim is stable normal-speed input and simulation at 1080p on a specified midrange desktop, with scalable visuals and no accumulating tick backlog. The team must measure the agreed machine before claiming 60 fps or a minimum specification. Cross-platform bit-identical replay is not assumed merely because the clock is fixed; arithmetic, tie-breaks, RNG and state hashes require their own tests.

## 16. Isolated action rules and realm integration

The rebuild lives under `game/redesign/`. The historical `battle_rules.gd` and `battle.gd` remain separate. **Implemented module:** `game/redesign/action_rules.gd`, `class_name ActionRules`, with meaningful headless tests in `tests/test_action_rules.gd`. Root-owned native scenes present the same rules; the realm and item modules own persistence and equipment. Broader company/objective systems described above remain future increments.

`ActionRules` has no scene-tree or animation dependency. Its state contains JSON-compatible dictionaries/arrays/numbers; ground-plane positions are `[x,z]`. The renderer interpolates positions and consumes action events, never applying damage from an animation callback. The public interface is:

```text
ActionRules.create(encounter: Dictionary) -> Dictionary
ActionRules.submit(state: Dictionary, command: Dictionary) -> Dictionary
ActionRules.advance(state: Dictionary, steps: int = 1) -> Array
ActionRules.get_actor(state: Dictionary, actor_id: String) -> Dictionary
ActionRules.snapshot(state: Dictionary) -> Dictionary
ActionRules.outcome(state: Dictionary) -> Dictionary
ActionRules.serialize(state: Dictionary) -> String
ActionRules.deserialize(encoded: String, registered_encounter: Dictionary) -> Dictionary
ActionRules.restore(snapshot: Dictionary, registered_encounter: Dictionary) -> Dictionary
ActionRules.equivalent(first: Dictionary, second: Dictionary) -> bool
```

`create` accepts the realm aliases `id`, `heroSnapshot`, `playerCompanies`, `enemies`, `lootRewards`, `objective`, `seed`, and optional `arena`. Direct test aliases `encounterId` and `hero` also work. For this first solo slice, `playerCompanies` must be empty, and the only implemented objectives are `dungeon_clear` and `elimination`. Unsupported objectives or supplied companies invalidate setup instead of being silently ignored. The later company engine expands this explicit contract.

The arena has `bounds:[minX,minZ,maxX,maxZ]`, `entry`, `exit`, and bounded circular/rectangular obstacles. Registered enemies have stable IDs, type, behavior, position, current/max health and derived combat stats. Behavior is currently melee, ranged, a telegraphed leap attacker, or a passive fixture. A persisted enemy at zero health starts as a corpse, contributes to clear progress and emits any still-unclaimed registered loot. The realm can omit already claimed rewards on revisit.

`submit` returns `{ok,reason}` and validates ownership, target, cost, cooldown, commitment and spatial legality before mutation. Actual commands are `move`, `attack`, `cast`, `guard`, `dodge`, `interact`, `exit`, and `pause`. Move/cast/dodge use `pos:[x,z]`; attack/interact use `targetId`; a choice pickup supplies `choiceId`. The engine implements `cleave`, `ember`, `ward` and `roots`, but a cast must be legal for the canonical class: Mara has only `cleave|ward`; caster fixtures have their own allowed subset. Guard may supply a facing point. A rejected command spends nothing. While paused, one validated replaceable hero intent can be queued; it is checked again on resume.

`advance` consumes up to 600 requested fixed ticks per call at 30 Hz. It returns queued events and empties the event buffer; pause/finish do not advance the clock. Important events include `action_started` with windup/commit/end tick and a hostile telegraph flag, `action_committed`, `action_cancelled`, `damage` with blocked/absorbed/applied amounts, `projectile_spawned`, `projectile_hit`, `projectile_removed`, `status_applied`, `status_expired`, `actor_died`, `loot_dropped`, `loot_claimed`, `objective_changed`, `encounter_cleared`, and `finished`. The presenter can inspect the actor's `action`, `animState`, `animStartedTick`, facing, health, cooldowns and statuses. Presentation is not a second authority.

The four class-specific action implementations demonstrate cone damage, traveling fire/burn, a finite shield and a binding area across separate identities. They are not four selectable Mara actions. The current dodge occupies 24 ticks (0.8 seconds), travels up to three metres over its first 18 ticks, and uses the final six ticks for recovery. Its evasion window remains only ticks 1–5 and its cooldown is 120 ticks. Extending the authored roll's readable recovery therefore does not extend invulnerability. An attack or leap begun by the rules retains its attack animation state throughout commitment; an empty movement path cannot overwrite it with idle.

Native animation and panel acceptance remain separate from rules verification. The action suite verifies 13 groups/201 checks, including an earned starter Vault run. The separate identity suite has six groups/134 checks and progression eleven groups/277 checks, all within the 1,390-check six-suite run. These records do not certify every full-design feature. Later results must cite their actual run and revision.

### Live action persistence

The save stores the actual action model, not merely the dungeon entrance. `serialize` returns a JSON string with precise numeric formatting. `deserialize` or `restore` requires the realm's validated pending encounter and returns an empty dictionary on rejection. The validator checks the exact actor registry and immutable item-derived stats, arena, numeric bounds, action/timer shapes, supported statuses, projectile source/damage, corpse/drop consistency, permitted item choices, stable claim IDs and result/objective consistency. Unknown resource fields and duplicate claims are rejected. A dead guardian's remaining registered loot persists; already claimed rewards cannot be manufactured by reopening the encounter.

A valid restore preserves tick, commitment/recovery, projectile travel, periodic-damage cadence, wards, cooldowns, paused/queued intent, corpses, physical loot, claims and partial extraction. Legacy pending snapshots remain unchanged during action-save migration: a committed old effect can finish, but illegal new/queued class casts are rejected. Unknown or contradictory canonical identity is invalid. Focus regeneration uses integer tick accumulation, and saved Vector2 fields normalize to simulation precision to avoid JSON decimal drift. Tests resume before release, during flight, during a burn, while paused, during pickup and during extraction, then compare actual continuation. This is bounded local-state validation, not a cryptographic proof that a user has never edited health within legal bounds.

Use `equivalent` on the before/after snapshot dictionaries to compare restored state. It ignores the transient event queue and treats numerically equal JSON integers and floats as equal, while checking every persisted value without an arbitrary numeric tolerance. Raw JSON string equality is unsuitable: a valid parser may represent `122` as `122.0` without changing the action or its continuation. The native save/resume harness uses this semantic comparison.

Latest combined evidence is [hunt-contracts.json](verification-logs/hunt-contracts.json), with [hunts-action_rules.log](verification-logs/hunts-action_rules.log) and its command metadata. Earlier action reports retain their historical revisions. The command uses isolated XDG directories and does not read or delete a player's normal save:

```bash
env XDG_DATA_HOME=/tmp/draconia-action-test-data \
  XDG_CONFIG_HOME=/tmp/draconia-action-test-config \
  XDG_CACHE_HOME=/tmp/draconia-action-test-cache \
  /path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --headless --path /path/to/voievod --script res://tests/test_action_rules.gd
```

### Result boundary with the realm

A result contains `schemaVersion`, `encounterId`, `kind`, `resolution`, `reason`, `elapsedTicks`, `heroState`, `companySurvivors`, `enemySurvivors`, `casualties`, `lootClaims`, and `objective`. Current resolutions are `victory`, `defeat`, and `retreat`; `partial` is reserved for authored objectives. Hero state contains current/max health and Focus. Enemy survivors retain ID/type/current/max health/company ID. The objective records type, completion, progress/target and extraction. Dungeon victory requires both clear and physical extraction; clear alone leaves time to collect loot.

A solo result has empty `companySurvivors`; **that means companies did not participate, not that the waiting army died**. The realm adapter uses encounter kind and original participating IDs. The normalized result cannot invent town capture, watches or arbitrary loot. A claim has `claimId`, `rewardId`, `kind`, `itemId` and stable `instanceId` where relevant; its ID derives from the registered encounter/reward. Registered choice options are enforced, and the realm applies each valid claim once.

RealmRules supplies `create_realm`, story `begin_encounter`, registered `hunt_board`/`begin_hunt`, and shared `resolve_encounter`. Its pending encounter preserves origin, declared watch commitment, original participants and permitted rewards. Action duration does not change the quote. A future objective victory with enemies alive must preserve those survivors and carry explicit registered stakes. Only a registered assault consequence authorizes settlement capture. No legacy hex `rounds` field is presented as elapsed action time.

Loot inspection calls the read-only `RealmRules.preview_reward(state, reward_id, item_id = "")`. It returns `{ok, instance, reason}` for a registered item, `{ok, gold, reason}` for currency, or an explicit failure reason. Fixed items can omit `item_id`; a choice requires an allowed option. Grant validation uses this same function, so the inspected affixes and earned instance agree. The item's roll seed derives from the realm seed, location ID and registered reward ID, independently of the encounter attempt. Retreating, saving or returning to an unlooted corpse cannot reroll the reward. Encounter-specific claim and instance IDs remain unique, and the location's claimed-reward registry prevents another visit from granting the same reward again. The realm suite retains 14 groups/247 checks for this story boundary. Hunts use persistent contract identity, never attempt number; nine groups/458 checks cover stable rolls, attrition, extraction XP, sale/capacity and the earned cap route. The native hunt route has 181 checks/twelve captures, including a real sale and explicit forfeiture. See [VERIFICATION.md](VERIFICATION.md).

### Separate native feedback and integration evidence

Class-specific icons, visual effects and sound cues consume authoritative events. Their separate proof has 43 unit checks and 55 native checks/seventeen captures, using Oathwarden Cleave/Ward, Pyromancer Ember and Druid Roots at the actual 30 Hz action cadence. Presentation adds no second damage source and does not make other champions selectable. Evidence: [verification-logs/spell-feedback](verification-logs/spell-feedback/).

The 181-check hunt/sale harness uses real GUI Input events plus legal combat commands and fixed ticks. It earns two completions, level 3, physical and deliberately forfeited rewards, a sale and live save/resume. It is not a normal-speed human mouse-only playthrough, full campaign or performance benchmark. Current character PBR and animated building-hover reviews remain pending; counts cannot approve changed materials or every future motion.

## 17. Build in complete, reviewable slices

**Slice A — the body and the blade.** One full 3D Mara Veyne rig, click-to-move, collision, one basic melee weapon, guard/dodge, one melee foe, one projectile foe, health, death and exit. Validate actual foot contact, turning, hit windows, projectile release/collision and normal-speed control before adding a talent tree. This is a control/combat proof, not a completed game.

**Slice B — town, solo expeditions, loot and return.** Current integration includes legal two-skill Mara, real items, a unique tradeoff, sets, story choice, physical collection/extraction, attributes, repeat hunts, sale, live save/return and persistent enemies. Separate canonical caster fixtures exercise their own legal spells. Keep every company outside. Validate normal-speed action and complete native UI flow before calling this a playable dungeon slice.

**Slice C — one company, then six and a field expedition.** First prove one company with escort/hold/fallback, formation, safe hero yielding and readable orders. Expand to six with real rosters, enemy family roles, wounds/casualties, a shrine/convoy objective and registered realm consequences. Field expeditions and solo dungeons continue to share action rules and gear; companies never enter dungeon interiors.

**Slice D — class progression and build diversity.** Levels and four attributes now work. Add twenty class-scoped kits/trees, individual signatures, racial/class disciplines, broader gear and sets through earned acquisition; the shared families are not universal spell permission. Verify several coherent builds and a recovery route. A list of definitions is not completion: every accepted ability needs effects, counterplay, UI and animation evidence.

**Full production target.** Complete the nine factions/162 recruitable definitions, 24 neutral types/eight bosses, authored regions/towns/contracts, strategic opposition, scenario tools and other agreed full-game systems. All gameplay characters and actions meet the 3D animation gate. The first action slice does not reduce this target or certify Heroes-scale completeness.

## 18. Acceptance ledger: prove, inspect, accept or rework

| Area | Required evidence before acceptance |
| --- | --- |
| Damage and timing | Recorded tests for hit windows, once-per-swing targets, projectile sweeps, armor/resistance caps, guard arcs, cancel/commit costs and death during an action |
| Statuses | Apply/refresh/expiry, pause freeze, cleanse/immunity, tick cadence, boss resolve, shield break and bounded revival tested at boundaries |
| Movement | Reachable clicks, blocking/slide behavior, no wall crossing, legal dodge/teleport destinations, company cohesion and blocked-path feedback |
| Orders and AI | Stable standing orders, pursuit limits, no repeated-order resource exploit, objective-aware decisions and predictable focus target changes |
| Objectives and result | Victory/partial/defeat/retreat, simultaneous outcomes, surviving enemies, real cargo/captives, exactly-once loot and realm application |
| Buildcraft | Legal preparation, finite points, prerequisites, respec/resource invariants, bounded affix stacking and useful basic counters for multiple archetypes |
| Deterministic tests | Fixed seeds and scripted inputs reproduce supported-build state hashes; tests check behavior, not a mirrored copy of implementation |
| Native controls | Real scene input, pause/resume, target selection, invalid action messages, menus, smaller-window layout and result callbacks |
| Animation | Full rigs; normal-speed footage/captures of feet, contacts, release frames, hit reactions, transitions, defeat and all accepted abilities |
| Performance | Actual hardware/renderer/resolution and actor/projectile counts recorded; no unsupported frame-rate claim |
| Human play | A new player understands the first fight, can explain a failure, can issue useful company orders, and can recover without a wiki |

Every feature has a named owner, a status (`proposed`, `implemented`, `verified`, `accepted` or `rework`) and links to actual evidence. Automated checks are reported by recorded suite and assertions, not padded to a round number. A clean test suite does not establish animation quality, and an attractive frame does not establish working rules. If a panel or mechanic fails its gate, revise it before treating it as accepted content.

## Primary sources and boundaries

The proposals and numerical budgets in this document are original design decisions. The sources below support only the limited reference descriptions, not claims that our combination is proven. Historical developer posts describe their own games and then-current design intentions. No substantial source text is reproduced.

- **[S1] Ubisoft, Heroes of Might and Magic: Olden Era unveiled at Gamescom:** exploration/resources/towns/armies and tactical battle structure, with explicit Heroes III inspiration. https://news.ubisoft.com/en-au/article/62HpoWQkAIVogVkoVk8JuJ/heroes-of-might-and-magic-olden-era-unveiled-at-gamescom
- **[S2] Blizzard, The Arreat Summit — Diablo II controls:** action-button assignment, movement, ranged attacks and on-ground item interactions. https://classic.battle.net/diablo2exp/basics/controls.shtml
- **[S3] Blizzard, Warcraft III — Hero Basics:** persistent hero growth, abilities and benefits to nearby troops. Our design deliberately retains only one playable hero. https://classic.battle.net/war3/basics/heroes.shtml
- **[S4] Blizzard, World of Warcraft Classic official overview:** persistent journey, classes and discovery as experience goals; no MMO requirement is inferred. https://worldofwarcraft.blizzard.com/en-us/classic
- **[S5] CD Projekt RED, The Witcher 3 official overview:** monster-hunter role and consequential choices. https://www.thewitcher.com/us/en/witcher3
- **[S6] Blizzard, Making Diablo II: Resurrected more accessible:** reducing repetitive input, configurable bindings and feedback for hidden outcomes. https://news.blizzard.com/en-gb/article/23700733/how-were-making-diablo-ii-resurrectedtm-more-accessible-to-everyone
- **[S7] Blizzard, Diablo IV Quarterly Update — December 2021:** combat VFX readability and synchronizing action with presentation. https://news.blizzard.com/en-us/article/23746639/diablo-iv-quarterly-updatedecember-2021

- **[S8] Blizzard, The Arreat Summit — Items:** base items and distinct magic/rare/set/unique roles. https://classic.battle.net/diablo2exp/items/
- **[S9] Blizzard, The Arreat Summit — Rune Words:** ordered components, compatible bases and socket counts in the reference game. Draconia recipes and values are original. https://classic.battle.net/diablo2exp/items/runewords.shtml
- **[S10] Blizzard, The Arreat Summit — Socketed Items:** sockets as a customization structure with different insertable categories. https://classic.battle.net/diablo2exp/items/socketeditems.shtml

Bounded original Heroes III executable/resource investigation remains documented separately in [RE_FINDINGS.md](../research/RE_FINDINGS.md). It is not a claim of complete decompilation, action-game compatibility, balance or production completeness.
