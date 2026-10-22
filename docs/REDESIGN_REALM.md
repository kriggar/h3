# DRACONIA — the living realm

**Design specification, 22 October 2026; v0.3 source synchronization. Owner: realm/strategic rules.**

This document specifies the realm layer of the expanded game. It combines design targets with an explicitly bounded isolated implementation, not a claim that the full realm is already playable. It supplements [GAME_DESIGN.md](GAME_DESIGN.md) and the canonical nine-faction roster maintained by the project lead. Names follow [NAMING_AND_ART_LOCK.md](NAMING_AND_ART_LOCK.md); the roles below are behavioral roles, not additional factions. Section 19 records the exact current implementation and its evidence.

## 1. The promise and the constraint

**The player chooses one persistent protagonist for the entire campaign and leads up to six companies. That person's promises change the realm, and the realm changes what they must do next.** Mara Veyne is the first implemented protagonist and the example throughout this specification. The full design target is 156 campaign-start character concepts: 144 regular choices, sixteen per faction, plus twelve story choices. No campaign can recruit, swap to or inherit control of a second hero. Other roster identities may be NPCs, rivals or future-run choices. An enemy army can have a named commander. A town can retain a garrison. A convoy can follow an automatic route. None of these becomes another player hero.

The core decision is where Mara Veyne commits her personal presence. She can win the immediate battle, investigate the origin of a curse, negotiate an oath, or protect a settlement. She cannot personally do all four in the same day. Town governance, preparations and negotiated obligations let her influence what happens elsewhere without turning the game into simultaneous control of several heroes.

Strategic success should mean more than painting every location the player's color. A durable realm has safe routes, solvent settlements, defensible oaths, and people who can survive Mara Veyne's departure. A large army is useful, but cannot substitute for every one of those conditions.

### Non-negotiable rules

1. **One chosen playable hero, fixed for the campaign.** The new save contains one `hero` dictionary and at most six accompanying company IDs; it never contains a player-controlled hero array. A future selection screen fixes `chosenHeroId` at creation. The initial slice supports Mara only, with fixed Oathwarden/Hearthborn/Ashen Crown identity and Cleave/Ward permissions. Twenty classes, eight races and 156 unique personal signatures are cataloged; signatures, racial effects and class-resource traits are design-only. Companies receive standing orders and can be selected for commands in real-time combat, but never become independently controlled adventure heroes.
2. **Every troop has an origin.** Recruitment consumes treasury and stock. Transfers subtract from the source before adding to the destination. Recovery is funded and finite. Enemy losses persist.
3. **Every defended conquest has a battle.** If Mara Veyne participates, it uses the direct, real-time action encounter with optional single-player command pause. If only a garrison is present, it uses the same authoritative action rules under AI control. A strength estimate may inform an AI decision; it never awards a victory.
4. **Realm time is committed deliberately.** An action card shows its cost, deadline and known consequences before commitment. Camera movement, reading, selecting a town and comparing equipment do not advance time.
5. **Oaths are promises with terms.** Benefits, prohibitions, obligations and foreseeable failure consequences are visible when the player chooses. Mystery can conceal an explanation or a future discovery; it does not conceal the mechanical price of an accepted contract.
6. **Fog limits information for both sides.** A rival may know the location of a public settlement. It does not know Mara Veyne's unseen position, current army or next click.
7. **The player can recover from a setback without erasing it.** A lost mine changes income. A lost garrison remains lost. A broken oath leaves a recorded relationship or regional consequence. Recovery offers new choices rather than silently restoring the old state.
8. **The game explains its decisions.** The turn report can account for every resource change, casualty, capture, broken promise and visible enemy movement.

## 2. What exists and what this specification adds

The archived campaign has one playable protagonist, a designed 36 × 26 campaign, three towns, four mines, ten fixed guarded encounters, permanent troop casualties, seven resources, daily income, weekly recruitment, three restored wards and a three-day/two-night cycle. Fixed encounters use `BattleRules`; there is no working opposing overworld economy or moving strategic army yet. These facts are defined in [campaign_core.gd](../game/campaign_core.gd) and [battle_rules.gd](../game/battle_rules.gd), with the existing route exercised in [test_campaign.gd](../tests/test_campaign.gd).

This comparison describes the **archived starting baseline**, not the current v0.3 action slice. Section 19 and [VERIFICATION.md](VERIFICATION.md) record what is implemented now.

| System | Archived starting baseline | Proposed addition | Delivery gate |
| --- | --- | --- | --- |
| Protagonist | One Mara Veyne, one army | Deeper personal/realm choices; still one hero | No multihero control or player hero recruitment in any UI or save |
| Rivals | Fixed guards with persistent casualties | Paid recruitment, mobile armies, goals, contested holdings, retreat and defeat | A rival can take, defend, lose and retake a mine through actual state transitions |
| Settlements | Income, stock, six buildings | Garrison transfers, local orders, stability, occupation and route access | Town outcomes are possible while Mara Veyne is elsewhere, with auditable costs |
| Oaths | Three permanent restored wards | Optional binding terms, obligations and material consequences | An oath can be fulfilled, broken and repaired through different actions |
| Time | Day rollover and phase bonuses | Threat forecasts, obligation deadlines, supply and delivery schedules | No unexplained deadline loss or extra enemy turn after loading |
| Tactical stakes | Eliminate the opposing army | Hold a site, protect a convoy, break a siege, withdraw with survivors | Objective success preserves living opponents and applies only the agreed stakes |
| Persistence | Version 2, version-1 migration | Versioned strategic/realm subtrees, pending encounters, transaction ledger | Load at any interruption produces the same continuation as uninterrupted play |

The new combat design is **direct real-time control of Mara Veyne, six company cards with standing orders, and optional single-player command pause**. It includes action battles and dungeons in actual 3D environments. The previous hex engine is archival; the new realm design does not depend on hex coordinates, turn queues, sprite billboards or round-based spell limits. ActionRules now provides the authoritative solo outcome adapter with actual hero resources, individual enemy survivors, physical claims and objective/extraction facts. Field-company, defended-conquest and interrupted-rival-turn extensions still need implementation; solo acceptance does not prove them.

The influence of the reference games is translated into purposes: legible strategic preparation and counters, responsive hero action, an exploratory world with recognizable regional dangers, and contracts with lasting consequences. Draconia's proposed identity comes from the interaction of one protagonist, six persistent companies, functioning towns and binding oaths. Copying every subsystem from each reference would produce a crowded interface rather than a coherent game.

## 3. Play loops at four scales

### A decision within a day

Read the visible threat and obligation forecast; choose Mara Veyne's route; prepare equipment, class-legal skills and supplies; commit movement; resolve an encounter; allocate any remaining movement. A safe road is faster, but may be watched. A forest approach can cost more movement while avoiding an enemy's vision. The choice must be visible through route costs and known danger rather than a hidden probability roll.

### A day

Mara Veyne chooses which problem needs her presence. The player also issues at most one new civic order per owned town that day. Existing construction, recruitment and deliveries continue without requiring repeated clicks. Committing a watch begins opposing movement and resolves the consequences quoted by the action. Enemy attacks can interrupt with a real-time battle, after which the same opposing watch resumes. End Day advances only as far as the next required decision.

### A regional arc

Find the cause of a regional crisis; choose whose promise to accept; secure a route or settlement needed to uphold it; confront the creature or faction exploiting it; decide how the resulting protection is governed. The region remembers the chosen terms. The first three restored wards remain permanent story achievements; the obligations attached to governing their protection can change.

### A campaign

Create a viable network of refuges and agreements, resolve the three oath arcs, confront the final power and determine what kind of realm survives. A conquest route, a negotiated route and a protective stewardship route should require different sacrifices and encounter sequences. They share authored causal events and transparent rules; they do not merely change the color of the ending text.

## 4. Geography, presence and information

### Regions in the first campaign

Use three initial regional IDs independent of rendered terrain: `woodland`, `river` and `highland`. Each location has one region in the content catalog. Region borders are authored and visible on the map; they are not recalculated from which ground texture happens to show. The realm is a navigable 3D landscape, with actual settlements, roads, bridges, tree cover and elevations. A coarse navigation graph can support deterministic route decisions without being presented as a board of flat tiles.

Every important route has an authored ID, endpoints, traversability conditions and integer travel cost. The renderer maps that route to a 3D path. Save position as a route/waypoint and quantized progress, rather than depending on an animation's floating-point transform. The tactical/action scene can use a finer navigation mesh without changing the strategic journey cost. Loading reconstructs the same location and remaining journey.

| Region | Proposed chapter anchors | Strategic character | Primary tension |
| --- | --- | --- | --- |
| Woodland | Dawnreach, Borderwood Sawmill, the woodland oath | Home refuge, timber, cover and community obligations | Sustain military construction while keeping the forest promise |
| River | Ravenford, Whitebriar Abbey, Crownvein Mine, the river oath | Trade routes, crossings, recruitment and recovery | A distant victory can leave an essential crossing undefended |
| Highland | Glasscrag Cavern, the stone oath, the sealed citadel | Rare materials, exposed approaches, powerful enemies | Maintain a supplied expedition while preventing raids behind it |

### Three different forms of visibility

- **Explored geography** persists: the player remembers terrain and known public locations.
- **Current observation** is recomputed from Mara Veyne, functioning watchtowers and friendly settlements. It reveals a moving enemy's current position and visible composition.
- **Reports** are dated memories. A last-seen enemy marker is explicitly labeled with the day and an uncertainty radius; it is not a selectable present enemy and cannot be attacked at its old coordinate.

Observation is measured in authored route distance and actual world-space sight, not the old grid's tile count. Initial tuning should let Mara Veyne see a threat far enough ahead to make one meaningful watch decision. A watchtower should observe its crossing and approaches; it should not reveal a whole region merely because the map is small. Mountains and dense forest block or shorten observation according to the same declared sight rules used for rival factions. Until occlusion is implemented, the interface must not imply it.

Public settlement coordinates can be part of a faction's starting knowledge. Unit counts, treasury, unseen buildings and hidden orders are not. Scouts remember observations for three days, then downgrade them to unknown strength. Allied reports arrive at the next daily report, not through instant shared omniscience.

`get_visible_warbands(state)` is the sole UI view of current hostile armies. It includes only currently observed armies. A separate `get_intelligence_reports(state)` returns dated, explicitly uncertain sightings. Neither method exposes a hidden army's true destination, strength or exact current coordinates.

### Interception

Mara Veyne may deliberately intercept a visible hostile force at a reachable route position. An opposing force controlling a narrow crossing blocks that crossing unless its agreement permits passage or a legal alternate route exists. The pathfinder cannot silently move Mara Veyne through a hostile occupied approach. An enemy that encounters her while moving stops and creates a pending action encounter. Its unspent route progress is retained in the interrupted watch record, never spent twice.

There is no unconditional automatic attack from beyond a legal contact distance. Ranged strategic attacks, ambushes or interception zones require an explicit, previewed ability and a separate acceptance gate.

## 5. Days, watches and the opposing turn

**Accepted and implemented calendar:** four watches per day: dawn, afternoon, dusk and night. `RealmRules` stores one nonnegative integer `watchIndex`: day is `floor(watchIndex / 4) + 1`, and watch is `watchIndex % 4`. Day 1 dawn is index 0. The first rules slice implements dawn production, rest, dungeon commitment, deadlines and rival frontier movement on this clock; the broader interruptible journey and defended-conquest sequence below remains a delivery target. Common town purchases take no watches. A watch is a committed unit of strategic opportunity, not fifteen real-world minutes. A player can read, pause, plan or inspect a town indefinitely without an enemy taking a hidden turn.

| Watch | Realm purpose | Encounter implications |
| --- | --- | --- |
| Dawn | Daily production, upkeep and recovery settlement | Better visibility; nocturnal forces seek cover or use their declared daylight traits |
| Afternoon | Long journeys, construction, civic work | Clear observation and predictable route threats |
| Dusk | Final preparation, deliveries, twilight creatures | Transition warnings and changing sight conditions |
| Night | Risky movement, secret contracts, supernatural activity | Explicit creature behaviors and oath effects; useful opportunities as well as danger |

Travel quotes its cost in watches before commitment. A journey lasting two watches advances rivals at both boundaries and can be interrupted between them. A short local interaction can be free; a dungeon or major encounter quotes its commitment before entry. Real-time combat duration does not silently advance extra watches, and using command pause has no realm-time penalty. If a dungeon has an internal timer, its objective declares that timer separately.

The ordering below is the authoritative watch transition, not an animation order. A saved transaction records which phase has completed.

1. **Preflight.** Reject commitment if an encounter, mandatory oath choice or uncommitted result is pending. Show obligations due at this boundary, expected arrivals and observed threats. If the boundary crosses dawn, also show production, upkeep and supply changes.
2. **Close watch W.** Apply the player's committed action and evaluate obligations explicitly due at the end of W. Commit each once. An enemy action in the next watch cannot retroactively invalidate a deadline already fulfilled.
3. **Advance to W + 1.** Derive day and watch from an integer clock. Apply the announced light/weather state. If the chosen action was a rest, apply its actual recovery; do not grant full healing simply because the calendar advanced.
4. **Settle dawn, when applicable.** Snapshot ownership at dawn. Produce goods, pay upkeep, consume provisions and apply announced shortages. A holding captured later in this watch begins producing for the new owner at the next dawn. The same ordering applies to every faction.
5. **Complete scheduled work.** Finish paid construction, training or deliveries whose due watch has arrived. Worker production and recruitment pools follow their catalog schedules. A captured town never generates a retroactive day of work or week of recruits.
6. **Prepare rival orders.** Refresh faction observation and affordable plans. Pay for recruitment at valid holdings. Give each mobile army its per-watch route budget once. Create a stable, deterministic execution queue.
7. **Execute rival orders.** Advance the next army along a legal route. Resolve an unopposed claim, an AI-controlled action encounter against a garrison, or an interactive pending encounter with Mara Veyne. Save the queue and cursor at an interruption. After resolution, continue at that cursor; never restart the watch.
8. **Reconcile the realm.** Update holdings, regional consequences, deliveries, faction defeat and observation. Persist dated reports for observable actions. Do not reveal a secret event through the report's wording.
9. **Return control.** Present a concise report with expandable accounting. A multiwatch journey or End Day stops at any decision requiring the player, then resumes only after that decision is resolved.

Each boundary and its resumed segments share a stable `watchId`. Dawn settlement also has a stable `dayId`. Repeated signals, duplicate callbacks, saving during an attack and loading a pending encounter cannot settle income twice or run an enemy again. The UI always shows the current watch and the next cost before a click commits it. An obligation due at day D night closes at `4 × D − 1`; “through the end of day D” includes that watch and is evaluated before index `4 × D` begins.

### Attention budget and advance-to-event

The forecast surfaces **the three most important known changes**: an imminent attack or objective deadline, a shortage/recovery issue, then a useful arrival or completion. The full ledger remains available. Routine production is summarized, not opened as a modal four times a day.

`advance_to_event` advances to the next meaningful known boundary, up to the chosen maximum. It stops before committing a new attack, a binding choice, an expiring obligation requiring intervention, or an unapproved shortage. It can cross harmless watches and dawns in one action, while running every underlying rule and recording the same results as individual watch commits. A “continue journey” action uses the same mechanism. The user never has to click End Watch repeatedly just to see an already queued roof finish.

Stopping before an attack means before its encounter transaction is committed to an unchosen battle; it does not reveal a hidden army earlier than observation permits. If a previously unseen army is encountered along a committed route, the journey stops at legal contact and opens the encounter briefing with the remaining commitment recorded.

### Time policy for the first implementation

The legacy three-light/two-night cycle and 1,400 movement allowance remain archival compatibility behavior, not the new realm clock. Initial strategic AI can mobilize according to an authored watch schedule, visible and fixed at chapter start. It cannot be postponed because the player is losing or accelerated because the player is winning. The guided opening should show a rival preparing, provide at least one meaningful response watch, and then let its real force carry out the announced plan.

## 6. Settlements and the single-hero realm

### A dedicated 3D town screen

Entering a town opens its own persistent 3D scene, with selectable construction plots, recognizable buildings, visible services and a readable town panorama. It is a place the player develops, not merely an economy spreadsheet. Selecting an empty plot previews the available building, exact cost, prerequisite and mechanical change. A successful purchase commits the real building state and the model appears through a short reveal/construction animation. Reloading shows the same completed building; replaying the animation cannot pay the cost again.

**Accepted timing for the first slice:** common buildings complete immediately on a successful purchase; buying advances no watches. A settlement permits one construction or upgrade per day, stored as `lastConstructionDay`. The visible animation is presentation only. Later multiwatch monuments must declare their duration explicitly and are outside this first construction set.

| Stable building ID | Display name | Stable plot ID | Prerequisite | Purpose |
| --- | --- | --- | --- | --- |
| `granary` | Granary | `grain_yard` | None | Food capacity and production |
| `barracks` | Training Yard | `training_yard` | None | Recruitment capacity and training service |
| `market` | Market | `market_square` | Granary | Currency income and trade service |
| `smithy` | Smithy | `forge_yard` | Barracks | Equipment service and a declared expedition benefit |
| `shrine` | Oath Hall | `oath_court` | Granary | Safe recovery of health/mana and oath service |
| `palisade` | Palisade | `perimeter` | None | Actual town-defense/approach effect |
| `wharf` | Wharf | `riverside` | Market | Trade and food access |
| `water_gate` | Water Gate | `riverside` | Palisade | Stronger protected river approach |

The wharf and water gate are exclusive alternatives on one plot. A model key matching each building ID is stable for the scene renderer. The exact prices and applied numerical effects live in `RealmRules.building_catalog()`; UI descriptions read that source instead of duplicating prices. `preview_construction` validates without mutation; `construct_building` deducts all costs and commits `stage:'complete'`, `builtWatch` and level atomically. It rejects double purchase, unmet prerequisites, the occupied exclusive plot, insufficient resources, today's prior construction and pending encounter locks. Daily build limits survive saving.

The broader workforce/production design below is subsequent development. Its work queues do not override the explicitly immediate first-slice common buildings. Town services must operate through real APIs before their buttons are shown as available.

### A settlement has four distinct stores

1. **Recruitment stock:** people or creatures available to hire. They are not soldiers yet.
2. **Garrison:** paid companies physically assigned to defend the location.
3. **Storehouse:** provisions and assigned local construction materials.
4. **Treasury access:** whether the settlement can participate in the realm's connected economy.

These must not be conflated. A town with twenty available recruits and no paid company is militarily undefended. Recruitment consumes stock and currency and forms or reinforces a persistent company. It joins Mara Veyne's six-company expedition only while she is present; remote recruitment joins the local garrison or reserve. It never creates a second controllable field army. A garrison may contain more than six stored companies only if its settlement capacity explicitly allows it; each encounter deploys the format's declared limit, and reinforcements obey an authored rule rather than appearing for free.

### A town visibly does the work it reports

The settlement's 3D buildings, routes, workplaces and inhabitants reflect the authoritative simulation. A completed sawmill with assigned labor and access to timber produces the catalog's timber output. A roof model does not grant output before its construction is paid and complete. A forge without ore can visibly idle and reports “waiting for ore”; it cannot continue manufacturing behind a decorative work animation.

Do not require per-person micromanagement. The player chooses a small number of priorities such as **food, recovery, industry or muster**. A deterministic allocator fills available worker slots according to that priority and a visible minimum-food rule. Advanced allocation can override individual workplaces, but the default keeps an ordinary town functioning. Workers shown walking to tasks are a presentation of these assignments; whether a cosmetic agent is temporarily offscreen does not change the resource ledger.

Each workplace definition has construction costs, an explicitly immediate or timed completion rule, worker slots, recipes, input capacity and output capacity. At dawn, compute production from assigned labor and available inputs; reserve inputs, then commit outputs once. Shared scarce inputs are allocated by the published priority order. Two workshops cannot both consume the same last unit of ore.

An illustrative starter chain is **woodlot → timber → repaired storehouse → larger protected food capacity**. Another is **quarry → stone → watchtower foundation → observed crossing**. The first playable town should make at least one such chain work visibly in 3D before more decorative buildings are added. The full catalog can add tools, iron, textiles, medicines and arcane materials only when their production and use create a distinct decision.

Population capacity, labor and recruitment are related but not interchangeable. Hiring a company consumes the settlement's eligible recruitment pool; any population/labor reduction is a published catalog rule. A supernatural company can have different recruitment terms. None of these differences exempts it from having a documented source and cost.

### Orders through the town council

The player may inspect and govern any owned town. Physical troop transfer into or out of Mara Veyne's army requires her presence. A council order uses one town order for that day and has a displayed resource and time cost.

| Order | Commitment | Result | Tradeoff |
| --- | --- | --- | --- |
| Recruit locally | Eligible stock, exact company/member cost, quoted training watches | A paid company forms or receives reinforcements in the local garrison | It does not accompany Mara Veyne until she visits |
| Fortify | Building costs and construction time | Stronger terrain/defense in the town's actual battle | Materials cannot also fund expansion |
| Provision | Gold/materials or local production, one day | Adds a specified quantity to the storehouse | Reduces other civic output for that day |
| Patrol | Assign a minimum local garrison, one day | Extends observation and lowers local raid disruption | Patrol troops remain assigned; their absence from a town battle is shown |
| Reassure | Gold and a day of civic attention | Restores a bounded amount of stability | No military output from that order |
| Arrange delivery | Goods, route and escort allocation | An automatic convoy with a real inventory and ETA | Goods leave the source immediately and can be delayed or lost |

The first native loop prioritizes working construction and the solo expedition; the next realm gate adds local garrison recruitment and transfers. Patrols, deliveries and richer orders are planned extensions, each requiring its own state and UI evidence. A button is not added until its order completes through real rules.

### Garrison transfers

`transfer_company(state, townId, companyId, direction)` validates ownership, Mara Veyne's presence, the six-company expedition limit and transaction locks. It moves the same persistent company ID atomically; it does not generate a fresh copy with restored health. Injuries, living membership, veterancy, promotion, equipment and standing order remain attached. Reinforcing a damaged company uses an explicit paid recruitment transaction rather than an implicit transfer of fictional full-health members.

Mara Veyne may travel alone if the action game supports it; an empty company roster is not automatically death or invalid state. The route preview must show the danger. Hero incapacitation and permitted recovery determine defeat, separately from whether all companies have fallen. Defenders consumed by a pending encounter cannot also leave through an open stale panel.

Remote recruitment uses the new faction/family catalog and technology gates. A family has its base form and two exclusive promotions; choosing a promotion is a paid, timed commitment at a valid facility. A veteran company retains identity and injuries through promotion. It cannot repeatedly change branches to heal for free or claim both branches' abilities. No free militia appears when a town changes hands.

### Stability and occupation

Each settlement has stability from 0 to 100; a region has a separate stability value summarizing local conditions and oath outcomes. The two values are not silently interchangeable. Proposed economic output is `floor(baseIncome × (0.5 + stability / 200))`. At stability 100 the current base income is unchanged. At stability 0 the settlement still produces half, giving a damaged realm a recoverable economic floor.

A conquest changes ownership immediately but gives one occupation day with no new recruitment. Existing surviving garrison units stay with their original faction or are recorded as prisoners under an explicit rule; they never switch colors automatically. Civilian recruitment stock persists, with a one-time, documented occupation loss if that rule is enabled. The captor cannot collect the same stock repeatedly by exchanging ownership.

Initial balance values to test: conquest lowers local stability by 20; a defended victory protecting civilians adds 5; a successful paid relief order adds 10; an unfulfilled regional oath subtracts the value printed in its contract, usually 10–20. Daily passive recovery is at most 2 while supplied and peaceful. Values are capped. Zero stability causes visible disruption and a warning, not an unannounced instantaneous rebellion.

Rebellion is an authored, forecast event after several consecutive days of severe instability. If it creates armed rebels, their troops consume a recorded local recruitment pool. It is not a hidden free army or a permanent generic punishment for owning many towns.

## 7. Economy, provisions and useful limits

### A small visible economy with deeper production choices

The legacy game's seven resource keys remain part of its compatibility data, not a constraint forcing the new game to carry seven currencies into its first screen. The starter region should expose only the resources it currently uses: currency, provisions, timber and stone are sufficient for the first functional town. The full catalog can introduce ore, tools, textiles, medicines and supernatural materials when their recipes and uses become available. The integrated content catalog settles exact names and IDs.

Currency buys services and wages. Physical materials exist in storehouses and deliveries. Realm-wide totals are an overview, not permission to build at a disconnected town with timber that is physically elsewhere. For the first slice, connected owned towns can use a simplified scheduled transport service with a quoted time and fee; explicit vulnerable convoys arrive only when their gameplay is implemented. Do not show a caravan moving if no real cargo or route state exists.

Each mandatory recipe has an obtainable source, a visible technology requirement and a recoverable alternate path if its first supplier becomes hostile. Civilian technology changes production or logistics; military technology unlocks counter roles, training and the family's exclusive promotions. Progress is not a hidden percentage bonus applied to every statistic.

Enemy factions use the same production, recruitment prices, training durations, wages and route costs. Difficulty may expose starting treasury, initial forces, strategic aggression or planning quality in the scenario setup. It may not silently multiply output, refill a defeated company, ignore supply, or inspect Mara Veyne through fog.

### Proposed provisions rule

Count expedition supply at company level, avoiding a click per creature. The catalog supplies a small provision weight per accompanying company, reflecting its actual nature. Hero consumption plus those weights gives the daily requirement. The interface primarily displays **days of safe travel**, with exact quantities available on expansion. The first slice does not need supernatural exemptions; later exemptions must have a clear recruitment or obligation tradeoff.

Default capacity is six days at the expedition's current requirement. Hiring a company recalculates remaining days; it never creates food. At a supplied friendly town, an enabled default automatically refills to the selected target, subtracting actual available stores or paying the displayed purchase price. If stores cannot meet both civilian minimums and the refill, show that conflict once before commitment. Do not require opening a transfer panel on every visit.

Consumption occurs once at dawn while away from a supplied refuge. Resting in a town uses its settlement provision rule and does not also deduct expedition food for the same people. The exact deduction and location are in the ledger. Supplies do not disappear as a function of real-world combat duration, idle UI time or command pause.

**Shortage rule for initial implementation:** one missed dawn produces a clear warning and prevents full recovery from ordinary field rest. A second consecutive missed dawn applies one bounded fatigue state with a declared travel/recovery cost. It does not stack each day, kill members, erase veterancy or reduce the food-producing jobs needed to recover. The next supplied safe rest removes it. This is an expedition setback, not a compounding death spiral.

At zero provisions, the player has an explicit **forage and camp** action in suitable terrain: spend one watch to obtain a bounded, catalog-defined ration and partial rest. It has a strategic opportunity cost because rivals act, but does not spawn a random mandatory fight every time. Barren or cursed terrain visibly lacks that option before the route is committed. Other responses are buying food, changing route, requesting a delivery, accepting a supply contract or withdrawing to a refuge. If a story siege includes lethal starvation, it is a separately announced objective with its own time limit, not a silent global rule.

Settlements maintain a minimum food priority by default. A civilian shortage lowers stability and prevents nonessential growth; it never reduces the food workforce automatically and then compounds its own shortage. Rationing, emergency imports or switching available labor to food are immediate visible responses. Automatic civilian starvation deaths are outside the first realm ruleset. An expanded survival model would need its own authored warnings and recovery tests.

Supply is accepted only if tests show meaningful route/preparation choices with infrequent routine intervention. The intended normal trip is several watches, shorter than the default carried reserve. If most sessions require repetitive forage clicks, remove or retune the consumption rule; do not call the busywork strategic depth. The first rival-turn slice can omit supply entirely and must not display an unenforced meter.

### Upkeep and expansion

Initial upkeep should be low enough that an earned early victory is useful, while making indefinite reserve accumulation expensive. Wages are a company catalog field rather than a fraction secretly derived from recruitment cost. A town's stationed companies use its visible settlement supply budget, with no duplicate expedition charge. Unpaid companies enter arrears; new hiring and paid promotions stop before existing members are lost. Any later refusal to deploy is announced with an exact deadline and a debt-resolution option. Permanent desertion is outside the first implementation until it can be shown not to cause a recovery spiral.

Conquest is limited through paid defense, restoration, supply and opportunity cost. Avoid an arbitrary global penalty merely because the player owns a fourth town. Large holdings should remain worthwhile when governed well.

## 8. Rivals that act for reasons

### Faction state

Each active rival has a catalog ID, a public name, a treasury, owned locations, recruitment stock, a diplomatic attitude toward the chosen protagonist, strategic priorities, observed intelligence, an active/defeated state, and one or more real company forces. The target catalog has nine factions, six creature families per faction, and a base form plus two exclusive promotions per family: 54 base families and 108 promotions, or 162 recruitable definitions. Twenty-four neutral definitions bring the creature target to 186. A scenario need not activate all nine simultaneously; a focused opening can use two active rivals and introduce others through settlements, contracts and later chapters. These totals are production requirements, not completed content.

No enemy commander becomes recruitable or controllable by the player. Negotiating with a commander changes an agreement or that faction's behavior, not the number of player heroes.

### The nine canonical powers in the realm

Names and capitals below are fixed by the integrated design. The economic and diplomatic roles are proposals for that design's synthesis, not additional creature definitions. Every faction still follows the common accounting and encounter rules.

| Faction | Capital | Proposed strategic distinction | Concrete settlement/oath interaction |
| --- | --- | --- | --- |
| Ashen Crown | Dawnreach | Agrarian protection, civic labor, disciplined defense | Tax relief leaves less currency for recruitment but funds local recovery and improves a town's willingness to support Mara Veyne |
| Thornweald Court | Briarhollow | Sanctuary rights, controlled forestry, protective routes | A forest charter trades unrestricted timber output for safe passage and a defined recruitment agreement |
| Cloudspire Conclave | Stormcairn | Knowledge, forecasting, rare-material dependence | A paid observation station gives a reliable weather forecast; maintaining it becomes a visible resource obligation |
| Vesper Court | Duskharrow | Night influence, ceremonial claims, fortified occupation | A burial compact can protect a settlement at night while binding Mara Veyne to a restitution task; violating it changes specific night behavior |
| Gloamfang Clans | Fangrest | Mobile hunting forces, border pressure, vulnerable supply routes | Respecting an agreed hunting corridor changes where its warbands travel; breaking it gives them a public reason to target the violating holding |
| Emberhorn Dominion | Cindervault | Fuel-and-ore industry, durable defenses, expensive specialist forces | An ore contract unlocks a workshop service but can obligate delivery during a siege or shortage |
| Reedbound League | Reedhaven | River trade, ferries, food distribution, crossing control | A passage oath secures a bridge or ferry while requiring Mara Veyne to keep its convoy route open |
| Ironroad Compact | Crossmere | Caravans, contracts, information, flexible commerce | A market can fund a rival as well as Mara Veyne; exclusive trade offers a better price while closing another diplomatic option |
| Deepcairn Pact | Stonewake | Underways, engineering, ancestral debt and durable defense | An access charter opens a mountain supply route while requiring measured extraction and maintenance of the shared gate |

For the first chapter, use one occupying power and one mobile raiding power as the active rivals, with a third faction offering a meaningful agreement. The isolated rules slice registers Vesper Court and Gloamfang Clans frontier forces; their larger conquest behavior remains planned. The other capitals belong to the larger world, not to an assertion that nine cities already exist in the legacy 36 × 26 map.

### Roles and goals

| Army role | Primary goals | Reasons to change goal |
| --- | --- | --- |
| Scout | Observe a crossing, locate a reported force, confirm a mine's banner | Enemy contact, obsolete report, required withdrawal |
| Raider | Cut a valuable exposed route, seize an undefended mine, intercept a known convoy | Strong local defense, depleted supplies, a safer valuable target |
| Occupation force | Take and garrison a town or important crossing | Threat to home, insufficient assault strength, treaty terms |
| Defender | Reinforce a threatened holding and prevent recapture | Threat resolved, another friendly holding in immediate danger |
| Oath hunter | Exploit a specific breach or disrupt an active obligation | Contract completed, target no longer exists, actor defeated |

A role is a planning preference, not permission to ignore movement or create units. The chosen goal records `kind`, `targetId`, last-known coordinates, selection day and a human-readable explanation. A visible intent can say “moving toward the quarry” or “returning to reinforce.” A goal based on private faction knowledge is not shown to the player until there is evidence to infer it.

### Deterministic planning

For each army, generate legal candidate goals from its faction's knowledge. Reject unreachable goals, treaty violations forbidden by the faction's current policy, and goals requiring nonexistent supplies. Score the remaining goals by strategic value, travel time, known defenders, current obligations and risk. Break equal scores by a seed-derived stable tie and then army ID.

Suggested initial ordering:

1. Escape an immediately overwhelming observed threat when a legal retreat exists.
2. Defend an owned town threatened within one day's observed movement.
3. Fulfill an active, affordable faction obligation or exploit an openly broken promise.
4. Attack Mara Veyne when observed, reachable and the faction judges the engagement acceptable.
5. Capture or raid an exposed valuable holding.
6. Return to a valid recruiting location when the army is depleted.
7. Scout an unresolved frontier or hold position.

A strength estimate helps compare options. It combines living troop counts, known unit capabilities, terrain, supplies and observed commander bonuses. It never consumes the combat RNG, never knows hidden equipment, and never determines casualties. If an attack is selected, the full battle engine resolves it.

Enemy priorities should be distinct: one faction protects trade agreements, another values sacred sites, another takes exposed holdings opportunistically. Do not give every faction the same nearest-player chase behavior. The first implementation needs two contrasting policies and a trace showing why each chosen goal was legal.

### Movement and recruitment

All armies obey traversability, bridges, route costs, blocking forces and guarded sites. They cannot teleport across a river to maintain pressure. Recruits enter a mobile force only at a valid owned recruitment location; otherwise they enter that location's garrison. A newly formed company has a visible muster event and a unique persistent ID. Its cost and initial members are removed from actual stock and treasury.

A faction may combine its own forces only when they meet, respecting deployment limits. Combining transfers existing company IDs and retires the empty force ID. A company cannot simultaneously appear in a garrison, a mobile force and an encounter's available reserve. The initial implementation can forbid arbitrary company splitting and expose a maximum of three mobile forces per rival to keep watches readable. Increasing that limit later requires an attention/performance test, not merely a larger array bound.

### Capture and battle

An undefended mine can change ownership without combat; the report calls it an unopposed claim. A guarded town, army or convoy cannot. A garrison encounter invokes the new shared action simulator with the correct companies, terrain, commander profile and deterministic encounter seed. It runs real attacks, abilities, collision/navigation rules, objectives and casualties under AI policy; its returned persistent company states replace both committed forces.

If Mara Veyne is present, the same encounter becomes a pending interactive battle. Automatic resolution, if offered to the player, runs the same action rules under AI control; it is not a separate easier formula. After a stalemate or encounter time limit, neither side receives a fabricated victory. The declared encounter rule determines withdrawal or continued occupation of the original positions, preserving surviving troops.

### Defeating a faction

A rival is strategically defeated only when it has no active field army, no defended holding and no legal recruiting base. Treasury alone does not summon a new army on an arbitrary tile. A defeated faction may remain a narrative or diplomatic identity; a later return must be an authored event with a visible, funded origin and its own scenario conditions.

The final story fortress remains sealed until the three restored wards are earned. Mobile forces may defend its approaches, but no rival can accidentally complete Mara Veyne's story gate or mark the whole campaign won through an off-screen conquest.

## 9. Oaths, diplomacy and regional consequences

### Restoration and governance are separate

The first campaign's woodland, river and stone restorations remain permanent. A player never loses an earned ward because an unrelated mine changed owner overnight. After restoration, a governance choice can bind a continuing obligation. Breaking that obligation changes its promised benefit, the signatories' attitude or regional conditions; it does not pretend that the earlier boss was never defeated.

Each oath card states:

- Who offers it and which region/settlement it concerns.
- The benefit gained now and any benefit that depends on continued compliance.
- The exact action or state required, its deadline and whether the deadline includes today.
- Costs and prohibited actions.
- What counts as success, breach, negotiated release or repair.
- Known faction and regional consequences, including whether a rival can exploit them.

No open-ended instruction such as “keep the forest safe” is a machine rule. A valid term is “keep the named grove supplied and free of hostile occupation through the end of day 12,” with a map marker and the relevant state exposed.

### Three example dilemmas for the existing map

These are proposed quest contracts, not existing content.

**Woodland: timber or sanctuary.** After the woodland oath, Mara Veyne can accept a sanctuary charter: the sawmill produces one less wood per day while the charter is active, and the grove provides a specified Veilkin recruitment benefit and regional protection. Alternatively she can accept a reconstruction charter: ordinary timber output remains, but a fixed wood-and-gold relief delivery must reach the nearby settlement by a stated day. Both choices can support a healthy realm. One trades continuing income; the other commits a short-term expedition or delivery. Breaking either charter suspends only its conditional benefit and creates a defined repair task.

**River: protected crossing or free passage.** The river community offers supplies and a defended crossing in exchange for safe passage for a named convoy. A rival offers a truce if Mara Veyne allows its pilgrims through. These promises are compatible only if their stated passage times and cargo terms do not conflict. The interface detects an actual conflict before the second oath is accepted. A player can negotiate a revised time, refuse one party or knowingly break an existing promise with its visible cost.

**Stone: bind or bargain with the dead.** The stone restoration can be governed as a binding seal, requiring recurring rare material but weakening local night raids, or as a negotiated burial pact, requiring a specific restitution quest while permitting limited spectral passage. The first route stresses the treasury; the second creates a tactical/narrative obligation. Neither route gives a hidden universally superior ending. The consequences arise in route safety, creature behavior, recruitment access and faction trust.

### Attitude and agreements

Attitude is an integer from −100 to +100. It is not a universal friendship bar: a faction also stores remembered reasons and active agreements. A gift cannot erase a sworn betrayal by simply adding enough points. Thresholds unlock negotiations, not automatic obedience.

Treaties have explicit scopes: nonaggression, passage through specified locations, trade, ransom or a shared timed objective. A nonaggression pact does not silently grant map vision or shared recruitment. Refusal to sign is not itself a breach. Violations are deterministic events tied to the responsible action, with one penalty per violation ID.

A treaty does not create a player-controlled ally hero. Allied help is a stated delivery, a town defense contribution, safe passage, intelligence, or an independently controlled faction action whose limits were agreed.

### Rival exploitation

A rival can plan around public consequences. If the sanctuary charter forbids logging, an opportunist may seize a different timber source. If Mara Veyne promises a convoy's arrival on day 12, a faction that learned the promise may watch its known route. The rival cannot know a secret acceptance through the save state alone; the contract specifies who witnessed it.

An enemy cannot select a goal against a nonexistent or already completed obligation. The obligation's status changes atomically before the next AI planning step. Reports explain the visible connection: “The raiders moved toward the crossing after the passage pact was announced.”

## 10. Battles with consequences beyond extermination

The encounter specifies its stakes before combat. The action result records objective outcomes and hero survival separately; an objective can succeed while living opponents remain.

| Encounter | Tactical objective | Success changes | What success does not do |
| --- | --- | --- | --- |
| Interception | Eliminate or force the hostile army to withdraw | Clear the current path; preserve or remove the actual opposing force according to survivors | It does not capture an unrelated town |
| Town assault | Defeat the garrison and satisfy the capture condition | Transfer the town; apply occupation; retain survivors | It does not convert living hostile troops into friendly recruits |
| Oath-site defense | Hold the named site for the declared duration and contest rules | Fulfill the defense clause; force a surviving attacker back to a legal retreat position | It does not delete a surviving enemy army or restore an unrelated ward |
| Convoy defense | Preserve the convoy until escape or relief | Deliver the surviving cargo fraction and satisfy the relevant clause | It does not grant the full cargo if part was destroyed |
| Fighting withdrawal | Keep a stated part of the army alive and reach an exit | Preserve eligible troops, concede the stated position | It does not count as territorial conquest |

The combat module is designing the new objective engine for direct action combat. Site defense and convoy protection should initially appear in a small number of authored encounters. Their exact objective IDs, timings and contest rules come from that module; this document does not retain the old hex-grid objective schema.

For a successful defense with surviving attackers, the campaign stores those survivors, spends their action and displaces them to a legal retreat position determined from their approach path. If no legal retreat exists, use an explicit surrender/capture rule; never teleport the army to a hidden random position. A defeated convoy loses actual goods from an inventory that was already removed from the source.

Any combat-estimated experience remains informational. Campaign rewards come from a single encounter reward policy. A pending encounter has a stable reward/commit ID, so duplicate result callbacks cannot pay twice.

### Solo dungeons and The Bellworn Vault

**Dungeons contain only Mara Veyne.** Her companies remain at the entrance or a designated safe staging location. They do not appear as followers inside, contribute attacks, take simulated dungeon casualties or disappear because the action result's company list is empty. Field/army encounters can deploy the six companies; dungeon encounters deliberately use a different participant selection.

The first native slice follows **town → The Bellworn Vault → physical loot choices → town**. The registered location ID is `bell_crypt`; the proposed quoted expedition cost is two watches, independent of how quickly the player fights or how often they pause. The briefing names that cost, known enemy types, the exit condition and the fact that companies remain outside. The transaction records the departure town for return/recovery.

The crypt has a finite authored enemy group and a clear extraction condition. Killing the last foe opens the cleared state and permits loot collection; it does not silently close the scene before the player can inspect drops. A victory result occurs after legal extraction. Retreat at the entrance while foes remain preserves the actual surviving enemies and Mara Veyne's current health/mana. A future revisit uses those survivors; it does not refill the original monster group for free farming.

Loot follows the new item's Diablo-II-inspired category foundation: ordinary/socketed gear, magic, rare, set and named unique items, with runes, gems and original recipes provided by the item catalog. “Legendary” denotes an exceptional named unique in this design, not a mandatory extra tier. The realm stores items by stable instance ID and equipment references those instances. It never invents random stat fields supplied by a result payload.

The registered reward record declares the allowed item or bounded choice, its source actor/objective and any currency amount. Action results return a claim ID derived from `encounterId + '/' + rewardId`, and an item instance ID derived from that claim and item ID. Resolution validates the claim against the pending reward definition, applies it once and records it. A duplicate callback, repeated exit or reload cannot duplicate a sword, pay the same gold cache twice, or claim both alternatives of a choose-one reward.

Initial action outcome schema from the combat module is `{schemaVersion:1, encounterId, kind, resolution, reason, elapsedTicks, heroState:{hp,maxHp,mana,maxMana}, companySurvivors, enemySurvivors, casualties, lootClaims, objective:{type,completed,progress,target,extracted}}`. `resolution` is `victory`, `defeat`, `retreat` or `partial`. The realm validates this against its registered encounter and translates the facts into persistent consequences. For `kind:'dungeon'`, `companySurvivors:[]` is required and leaves all stationed companies unchanged.

## 11. Concrete turn examples

### Example A: capture, income and recapture

At the start of day 5, Mara Veyne owns the quarry, which pays its two ore at rollover. A visible raider reaches it later in the opposing phase. No garrison is assigned and Mara Veyne is elsewhere, so the mine changes banner as an unopposed capture. The two ore already earned remain in the player's treasury; there is no retroactive subtraction.

On day 5 the mine's panel says “Enemy held; next output: 2 ore to its current owner at the next rollover.” Mara Veyne reaches it with movement remaining. If the raider stayed to guard it, interception creates a real battle; if it departed and left no defenders, the claim is unopposed. If Mara Veyne retakes the mine before End Day, she receives the next two ore on day 6. Both capture records remain in the log, and the rival cannot collect the same production a second time.

### Example B: defending through preparation

Mara Veyne is preparing for the mountain oath. The monastery has eight archers in its garrison, while six more remain available in recruitment stock. The player pays to hire four locally, leaving two in stock and twelve paid archers defending. The map shows a known enemy army two travel days away.

The enemy arrives while Mara Veyne is absent. The shared action simulator resolves the paid archer company against the enemy's actual paid force. The town view represents those archers as members of a persistent company, not twelve independent strategic pieces. The report contains survivors, losses and ownership. A defender victory leaves the surviving garrison; an attacker victory transfers the town and leaves only its surviving troops. The report never says “your town resisted” without a battle result and casualty ledger.

### Example C: a promise changes the route

On day 8 Mara Veyne accepts a convoy oath due at the end of day 11. The card shows a three-day route and the goods deducted from the source. A known rival blocks the shortest crossing. The player may accompany the convoy, clear the crossing, negotiate passage, or select the longer route and renegotiate the deadline before accepting it. Waiting until day 11 to discover the route cannot fit is not the intended puzzle; the commitment preview already shows the risk.

The convoy is attacked on day 10 while Mara Veyne is within its escort range. A real-time convoy-defense encounter opens with the declared objective. Objective success with 60% cargo health delivers 60% of the goods under the declared contract. The surviving enemy army withdraws with its remaining creatures. A clause requiring at least 50% delivery is fulfilled; a separate optional reward for complete delivery is not paid.

### Example D: losing home is serious but not instant erasure

The enemy captures Dawnreach while Mara Veyne still controls the monastery and leads a viable army. The campaign continues. Income, recruitment and home-region observation change. The monastery becomes her nearest valid refuge; her original home remains a recapture objective. Restored wards and completed personal quests persist.

If Mara Veyne is subsequently incapacitated and has no owned refuge, funded rescue agreement or explicitly available recovery contract, the campaign enters the scenario's terminal defeat state. Losing all companies while Mara Veyne survives is a dangerous solo state, not automatic hero death. A final modal explains the exact loss condition. If a refuge remains, recovery uses its finite stores and a visible cost; it does not generate a new free company roster forever.

## 12. Defeat, recovery and preventing a runaway leader

### Defeat conditions

Losing all towns is not immediately terminal while Mara Veyne survives and has a legal path to recovery. Losing an encounter objective is not identical to being incapacitated. Terminal defeat occurs when the scenario's explicit conditions leave an incapacitated Mara Veyne without permitted recovery, or an openly stated primary objective is irreversibly lost. A scenario can include a defended-person or timed-catastrophe loss, but it must be shown as a primary objective from the point it becomes binding.

### Recovery

Offer a bounded choice: withdraw surviving companies to a valid refuge, pay a ransom from actual resources, invoke a rescue agreement, or begin a stated recovery contract. The destination is selected from legal owned/allied refuges; it is not hard-coded to the original home after that town has fallen. Recovery commits a quoted number of watches; rivals act during them, and losses/injuries persist. A recovery levy uses settlement stock and a once-per-period allowance with its cost shown. The former free emergency force must not become an unlimited farm. A recovery contract cannot immediately require the army or resource that the loss just removed without providing an attainable alternative.

### Constraints on snowballing

- New towns need real paid garrisons; Mara Veyne cannot be everywhere.
- Occupation reduces immediate output and recruitment, then recovers through actual investment.
- Strong armies need upkeep and supply; their long expedition has a visible logistical cost.
- Agreements can secure flanks at the price of obligations rather than requiring permanent conquest.
- Rivals can coordinate through disclosed treaties or public responses to aggression, not a hidden universal anti-player coalition.
- A faction with fewer holdings can retreat, negotiate and use terrain, but receives no invisible replacement army.
- Primary rewards are finite. Repeated ownership exchanges do not repay first-liberation rewards or reset collectible caches.

The player who makes consistently good decisions should gain an advantage. The aim is to create new responsibilities for that advantage, not to erase success with rubber-band statistics.

## 13. Campaign structure and replayability

Preserve the first campaign's identity: Mara Veyne starts at Dawnreach; the woodland, river and mountain oaths lead toward the sealed citadel; the finale requires the three earned restorations. Expanding the realm layer changes the route and consequences without invalidating those achievements.

Replayability comes from alternate oath terms, rival priorities, declared starting situations, encounter objectives, weather sequences, equipment builds and regional events. Terrain variants alone are insufficient. Each variation must preserve reachable resources, at least one recovery route, a valid path to every mandatory objective and enough information to make deadlines fair.

The first expanded scenario should support three authored strategic routes:

1. **Protector:** invest in safe settlements and convoy defenses; obtain dependable supplies and civilian cooperation.
2. **Conqueror:** capture rival production and pay to hold it; confront stronger military responses and occupation costs.
3. **Oathkeeper:** use negotiated passage and difficult binding promises to reach the required sites with fewer territorial holdings.

These are play patterns, not character classes selected at the start. A player can change course when the realm changes, accepting the actual consequences of previous promises.

A victory record should report final region conditions, fulfilled and broken obligations, surviving allies, controlled settlements and Mara Veyne's principal choices. It must not score morality through one concealed “good” number. Later chapters can consume specific recorded facts rather than attempting to infer them from total reputation.

## 14. Data contract and public API

### Authority and module boundaries

- The new action-campaign facade owns action validation, encounter transactions and campaign rewards. The existing `campaign_core.gd` remains a legacy baseline until an explicit adapter and migration are accepted; it is not silently rewritten to reinterpret old saves.
- A future extracted strategic planner owns rival goals, movement, treasury/stock and resumable attack queues. The current bounded frontier implementation lives inside `game/redesign/realm_rules.gd`; no new `strategic_rules.gd` is claimed to have delivered defended conquest. Rules modules do not own scene nodes or assets.
- The new `action_rules.gd` is the current authoritative real-time solo action simulation. The old `battle_rules.gd` and hex screen are archived gameplay, retained only for legacy replay/compatibility and regression evidence. Strategic code must not create a second damage or victory formula.
- The root-owned content/realm catalog supplies faction IDs, regions, oath definitions, objective kinds and valid references. Runtime saves contain state and stable IDs, not executable scripts or arbitrary effect expressions.
- Main and map views consume view models and submit actions. A UI panel cannot mutate treasury, ownership or armies directly.

Avoid preload cycles: pass canonical definitions or use an explicitly supplied battle resolver at the orchestration boundary. In particular, `Campaign facade → StrategicRules → ActionRules → Campaign facade` must not become a static initialization loop.

### New ruleset, separate from legacy saves

Use a distinct action ruleset identifier and its own schema version. Do not call a fundamentally different hero/action game “version 3” while silently interpreting the old stack rules differently. The isolated prototype module is `game/redesign/realm_rules.gd`, with a `RealmRules` class; legacy `CampaignCore` is untouched. A future importer is an explicit transaction with an original-save backup and a migration report.

This is an illustrative structural outline, not a complete valid save. Current action schema version 4 is separate from legacy hex saves. Exact fields/validation are owned by RealmRules, ActionRules, ItemRules and HeroIdentity; omitted subtrees cannot be filled with arbitrary JSON.

```json
{
  "ruleset": "draconia_action_v1",
  "version": 4,
  "seed": 711,
  "watchIndex": 0,
  "hero": {"id": "ileana", "classId": "oathwarden", "raceId": "hearthborn", "factionId": "ashen_crown", "state": "alive", "locationId": "dawnwatch", "level": 1, "xp": 0, "progression": {}},
  "companies": {},
  "expeditionCompanyIds": [],
  "resources": {},
  "settlements": {},
  "locations": {},
  "routes": {},
  "rivals": {},
  "obligations": [],
  "agreements": [],
  "regions": {"woodland": {"stability": 80}, "river": {"stability": 60}, "highland": {"stability": 40}},
  "turn": {"id": "watch:0", "phase": "complete", "remainingArmyIds": [], "activeArmyId": ""},
  "pendingEncounter": null,
  "history": []
}
```

The company registry stores each persistent company once. `expeditionCompanyIds` has at most six unique references. Garrison and enemy-force containers also contain references, not independent copies. An encounter snapshots committed company data for resolution while locking the source references. Temporary summoned actors belong to encounter runtime and do not become persistent companies merely because they survived an animation.

A rival record contains a canonical faction ID, treasury/resources, attitude, policy, recruiting locations, observed intelligence, paid mobile force IDs and a monotonic next-ID counter. A mobile force contains company IDs, a legal route position, remaining route budget, a goal, a mobilization watch and its last-acted watch. A settlement stores owner, workers, workplace assignments, real stock, garrison IDs, paid work queue, local stability and occupation end watch.

Scenario content supplies valid location and route IDs, production recipes, canonical faction definitions, technology gates and objective/stakes definitions. The save stores runtime values and stable references; it cannot invent a new resource type, production formula or executable effect.

### Pending encounter transaction

```json
{
  "id": "encounter:12:force:2:0",
  "kind": "interception",
  "initiator": "rival",
  "committedWatch": 12,
  "returnWatchId": "watch:12",
  "interactive": true,
  "heroSnapshot": {},
  "playerCompanies": [],
  "enemyCompanies": [],
  "sceneId": "river_crossing",
  "objectiveDefinitionId": "crossing_defense",
  "stakesDefinitionId": "keep_crossing",
  "context": {"watch": "dawn", "weather": "mist", "regionId": "river"},
  "seed": 12345,
  "sourceForceId": "force:2",
  "defendedLocationId": "river_crossing",
  "approachRouteId": "crossing_east"
}
```

The full snapshot is created by the realm facade, not assembled by Main. It records the committed combatants, context, seed and consequences. Persistent companies cannot change while locked. Presentation receives copies. Saving preserves the transaction; loading resumes the same encounter instead of creating another opposing action.

Ordinary mutable realm actions fail clearly while an encounter is pending. Camera, journal, settings and saving remain available. A stale or duplicate result ID is rejected without mutation. A noninteractive garrison encounter still needs the real action simulator; if no resolver is connected, it remains an unresolved transaction rather than receiving an estimated victory.

### Generic action outcome boundary

The realm requires the following facts, irrespective of the combat module's eventual field spelling:

| Fact | Required meaning |
| --- | --- |
| Encounter identity | Exact pending transaction ID and action ruleset/version |
| Hero survival | Alive, incapacitated or another explicitly defined state; separate from objective success |
| Persistent company survivors | Same company IDs and legal remaining membership/injury states; no duplicated members or free promotion |
| Enemy survivors | All remaining persistent hostile companies, even on a successful defensive objective |
| Hero resources | Remaining health, mana and resolve under the shared action limits |
| Objective outcomes | Definition ID, actual completion/failure reason and measured progress/cargo state where applicable |
| Exit condition | Objective completion, withdrawal, incapacitation or time limit; not an ambiguous boolean |
| Reward facts | Valid earned events, discovered loot IDs or cargo; the campaign computes the allowed payment once |

No realm code may infer annihilation from a generic `victory` boolean. A successful defense can displace surviving attackers; a failed objective can still leave Mara Veyne alive. The action module's bounded validator owns legal encounter results; the realm also checks those results against its locked snapshots and declared stakes before committing ownership, obligations or rewards.

### Current methods and explicitly proposed extensions

| Method | Current contract / status |
| --- | --- |
| `create_realm(seed, setup={})` | Implemented: one Mara, waiting companies, authoritative clock and registered scenario. |
| `advance_watch` / `advance_to_event` / `forecast` | Implemented clock, top-three forecast and next dawn/deadline; future attack interruption is not implied. |
| `get_visible_warbands` / `get_realm_overview` | Implemented bounded frontier observation and overview with hidden-state filtering. |
| `get_intelligence_reports` | Proposed dated sightings, not a current public function. |
| `building_catalog` / `preview_construction` / `construct_building` | Implemented no-watch purchase, prerequisites, exclusive plot and once/day limit. |
| `supply_catalog` / `purchase_supply_item` | Implemented finite ordinary supplies at a built friendly Market. |
| `preview_item_sale` / `sell_item` | Implemented owned unequipped-instance sale, catalog value, revision and no watch cost. |
| `attribute_catalog` / `progression_view` | Implemented four attributes, XP thresholds, points, revision and locks. |
| `preview_attribute_allocation` / `allocate_attributes` | Implemented full-stat draft preview and atomic no-heal commit. |
| `preview_attribute_reset` / `reset_attributes` | Implemented bounded friendly-town reset without identity/XP change or healing. |
| `begin_encounter(state, request)` | Implemented finite story Vault; field interception remains proposed. |
| `hunt_board` / `begin_hunt` | Implemented three offers, fixed active contract and two-watch solo entry/re-entry. |
| `preview_reward` / `resolve_encounter` | Implemented registered preview and atomic solo results; future field stakes need verified adapters. |
| `transfer_company` / `recruit_company` / `issue_town_order` | Proposed player company/training/order services, not current controls. |
| `accept_obligation` / `rest` / `trade` / `recover` | Implemented bounded registered oath, recovery and town services. |
| `serialize` / `deserialize` | Implemented bounded action JSON v4, genuine versions 1–3 migration and live compatibility. |

The initial implementation covers only the subset proven by its focused tests; unimplemented methods are not presented as working controls. There is no compatibility promise that the old `end_turn` or `resolve_battle` call can drive the action ruleset without an adapter. Old tests continue to exercise the old engine under its own rules.

### Safely extensible oath fields

An obligation is a bounded record: `id`, `definitionId`, `choiceId`, `regionId`, `factionId`, `acceptedWatch`, `dueWatch`, `status`, `progress`, `witnessFactionIds`, `resolutionId`. The catalog defines progress keys and their ranges. A save cannot supply an arbitrary script path, objective type, deadline rule, reward amount or effect expression. Benefits and consequences are looked up from the definition and choice ID.

Statuses are `active`, `fulfilled`, `broken`, `released` or `repaired`; transitions are explicit. A fulfilled/broken/released record remains in history. Repair creates a linked event rather than rewriting the original breach as if it never happened. Limit the first chapter to five simultaneous obligations. Keep a bounded historical representation so a long campaign cannot exceed its save-size cap through repetitive reports.

The root-owned oath catalog/module can expose `create_state(scenarioId)`, `validate_state(raw, realm)`, `evaluate_deadlines(realm, closingWatch)`, `apply_event(realm, event)` and `view_model(realm)`. Unknown schema versions fail closed. The realm does not copy unknown JSON fields into a supposedly validated state.

## 15. Validation, compatibility and durable saves

### Structural limits

Carry forward the strict bounded validation of the legacy project, using the new ruleset ID. Validate every integer as finite and whole, every enum against a known set, every ID against its registry, and every position against a valid location/route and quantized progress range. Bound total forces, companies, membership, histories, active obligations, queued actions and file size. No saved path escapes the project; no string is interpreted as GDScript or a formula.

### Cross-field consistency

- Exactly one player protagonist exists. The current slice accepts historical `ileana`, mapped to Mara Veyne and canonical Oathwarden/Hearthborn/Ashen Crown identity. Future selection fixes one canonical identity for the campaign; reset never changes it.
- The expedition has zero to six unique company references. A solo, living Mara Veyne can be valid; an incapacitated protagonist requires an explicit pending recovery or defeat state.
- Each persistent company belongs to exactly one available container: expedition, garrison, reserve, enemy force or another explicitly modeled state. A locked encounter snapshot does not create a second available copy.
- A town's public banner agrees with its actual faction ownership. Occupation, labor, stock and garrison refer to that same town.
- A pending force exists, has the committed company states, occupies a legal contact position and appears at most once in the interrupted queue.
- A completed watch has no remaining queue or unresolved transaction. Dawn accounting records agree with `watchIndex` and cannot be advanced by editing a derived day label.
- Recruitment, production, transfers and rewards have unique commit IDs in their transaction scope. Unfinished training does not produce a deployable company.
- Enemy knowledge is separate from truth. The player-facing view never leaks raw rival goals, treasury or positions outside observation.
- Losing Dawnreach is a valid strategic event; it does not violate a hard-coded loader condition. Recovery uses currently valid refuges.
- First-liberation rewards and story milestones remain separate from current ownership, preventing repeated capture payments.
- Persistent equipment and item IDs are unique. Encounter loot cannot duplicate an owned item or exceed its registered reward.
- Level matches bounded cumulative XP; invested plus unspent points equals three times level. Four investments stay within caps; pending snapshots retain committed statistics.
- A hunt board has three registered offers, at most one unfinished contract, stable actors/rewards and bounded attempts/history. Story claims remain separate; sold items do not reopen claims.

### Action v4 migration and separate legacy hex saves

Current action version 4 accepts genuine earlier action versions 1–3. Missing identity/progression derives canonically; earned inventory/claims remain, and the registered hunt board does not reset the story Vault. Existing pending snapshots stay exactly committed; earned progression applies when safe instead of substituting new Health/Focus limits. Already committed old effects may finish, but illegal new/queued class casts are rejected. Earned historical fixtures cover migration, not just synthetic version-label edits.

Preserve the existing hex loader and campaign as a separate legacy ruleset. Its version-1 migration remains available and its version-2 saves remain readable. Do not overwrite a legacy file with the new ruleset or claim that changing the version number constitutes conversion.

A future **explicit importer** can convert earned progress only after there is a documented mapping for all old troop keys, skills, resources, wards, towns and story flags. It keeps the original save, produces a new file and reports each translation. If a seven-stack legacy army would exceed six companies, retain the excess in a valid reserve under its own identity; never discard creatures or combine unrelated families silently. If the new content lacks a faithful mapping, stop import with a precise explanation and leave the original campaign playable.

An imported campaign must not resurrect defeated guardians, reset collected rewards, create a new initial army or remove completed wards. Newly introduced rivals receive an announced adaptation grace period, with positions that do not overlap Mara Veyne. A completed legacy victory remains a completed legacy campaign; importing it must not suddenly turn the ending into an unannounced invasion.

New action-campaign fixtures are earned through real action rules and realm transactions. The existing pre-final fixture and three complete legacy routes remain historical regression evidence for the archived engine. Their ten-day victories do not prove that the new real-time game, six-company balance or living realm is complete.

## 16. UI information and interaction

Keep the adventure map as the main place where choices connect. The right column shows Mara Veyne, her army and current supply state; the lower event strip reports the latest meaningful consequence. A realm panel is an overview and command surface, not a replacement for visible locations.

### Required views

| View | Must show | Must not imply |
| --- | --- | --- |
| Enemy army card | Current/last-seen distinction, faction, visible composition, estimated threat, inferred intent, last observation day | Exact hidden orders, treasury or unseen reinforcements |
| Town card | Banner, garrison, recruit stock, income, stability, active order, supply access | That available recruits are already defending |
| Route preview | Quoted watches and the exact arrival boundary, observed blockers and known supply/refuge points | Guaranteed safety through unexplored areas |
| Oath ledger | Terms, due date, progress, witnesses, reward at risk, consequence and repair option | A generic morality score standing in for the actual promise |
| End Day preview | Due obligations, expected income/upkeep, known arrivals, relevant phase change | Secret enemy moves or certainty beyond available intelligence |
| Turn report | Changes with reasons, casualties, captures, fulfilled/broken terms and links to affected places | An unexplained “realm unrest +10” without a source |
| Battle briefing | Exact objective, battlefield/weather, stakes, committed forces and withdrawal consequence | That every success destroys the enemy army |

An intercepted End Day opens the battle briefing and resumes the enemy turn after completion. The main controller must not automatically advance another day on return. If the save loads with `pendingEncounter`, show that briefing directly after the campaign view has initialized. Essential controls remain available at the established 960 × 640 minimum for the current action interface; threat or obligation text must not cover the map's clickable destination.

## 17. Implementation sequence and acceptance gates

### Gate R0 — one complete new native loop

Before realm breadth, implement the isolated four-watch clock, immediate persistent town construction, one registered solo crypt, real hero survival/resources, valid item claims and save/load. The old game remains playable and unchanged. This gate is the first **town → solo dungeon → loot → town** loop, not proof that the entire living realm is implemented.

Each feature passes **build → automated rule/controller tests → actual native inspection → accept or rework**. Inspect the native scene after buying a building, reloading, entering the solo crypt, collecting a choose-one item and returning. The model must appear from real completed state; only Mara Veyne appears inside the dungeon; inventory and hero health must match the actual encounter. Review three important forecast entries and the town interaction at the supported minimum size. A headless pass alone cannot accept presentation or usability.

### Gate R1 — living opponents, no new supply burden

Implement versioned strategic state, two contrasting active rival policies, deterministic movement, actual economy/recruitment, current visibility, player interception, garrisons, capture/recapture, pending encounter resume and valid terminal recovery/defeat. Preserve the first campaign's story gates and one-hero model. Do not add provisions, a full diplomacy tree or procedural quests at this gate.

Required evidence:

1. Two identical seeds and action sequences yield identical goals, movement, recruitment, battle seeds and final state.
2. A rival reaches a mine by legal movement, captures it, receives exactly the next eligible income, and loses it to a legitimate player recapture.
3. A defended town changes ownership only after the shared action simulator returns the appropriate outcome; both sides retain exact persistent company survivors.
4. Mara Veyne is attacked during End Day, a battle is saved/loaded, and the remaining rival queue executes exactly once afterward.
5. An observed enemy disappears from the current-position view when it leaves observation; the last-seen report is dated and cannot be attacked as if current.
6. Recruitment fails without enough treasury/stock, never exceeds the company formation limits, and cannot occur on an arbitrary field position.
7. A retreating enemy returns with its survivors, not its original force. A defeated army never reappears without a paid new formation.
8. Both factions can be defeated through loss of bases and armies. No faction spawns from treasury alone after losing every legal base.
9. A player who loses home but retains another refuge continues; a player with no force or permitted refuge reaches an explained terminal defeat.
10. Version-1 and version-2 saves preserve their earned army, resources, skills, wards and ownership. Malformed action-ruleset states and duplicate callbacks leave state unchanged.
11. A complete campaign regression earns all three wards and resolves all adapted story encounters using real travel, economy and action-combat casualties while handling any strategic encounters that occur.
12. Actual UI/controller tests open a hostile army, trigger an End Day attack, resume its queue and show a capture/recapture result. Pure rules tests alone do not satisfy this gate.

### Gate R2 — binding choices

Implement one full oath arc in each region, each with two materially different terms, visible deadlines, faction witnesses, breach and repair. Add the small catalog of objective encounters after the combat module verifies their result semantics. Test a successful obligation, a deliberate breach, a conflicting second promise, a repaired breach and an enemy response based on public information.

### Gate R3 — towns sustain the expedition

Introduce settlement stability, local orders, provisions, route deliveries and finite recovery. Rebalance the whole first campaign under those costs. Measure whether the player has useful preparation choices rather than frequent mandatory resupply clicks. A convoy must contain real cargo, move along a legal route, and lose or deliver exactly that inventory.

### Gate R4 — campaign breadth and durable replay

Expand the canonical faction roster into additional scenarios, add authored alternate paths and carry specific consequences between chapters. Create tools to validate reachability, obligations, economic prerequisites and recovery routes. Run seeded campaigns across different strategic choices and publish actual failure/recovery outcomes, not only an optimal winning path. Every accepted addition repeats the native feature gate; later breadth does not waive visual or usability inspection.

### Tests owned by the realm layer

Existing `tests/test_realm.gd` verifies the bounded current subset. Future suites must add defended capture/recapture, company/garrison combat, interception/queue resume and earned complete-campaign routes when those systems exist. Progression, identity and hunts now have separate meaningful suites; their counts do not establish unimplemented strategic outcomes. Existing campaign and app suites remain useful; assertions tied to superseded behavior must be updated deliberately and documented. No test may inject a victory flag, delete enemy stacks or grant unearned resources and then describe the result as a completed gameplay route.

## 18. Open decisions for the whole-game design

1. Which later factions and named commanders enter each regional arc? The first isolated slice uses Vesper Court and Gloamfang Clans; the full roster and chapter claims follow the nine-faction catalog.
2. Which exact oath branches become canonical for the first regional arcs? The examples above establish mechanical requirements, not final narrative text.
3. Does the first expanded campaign enable supply at Gate R3, or keep it optional until a second scenario? The decision should follow tested travel and interruption frequency.
4. Which additional field-objective, company-survivor and persistent-injury rules extend the verified solo result? Clear/extraction/retreat/defeat is settled; convoy, defended conquest and time-limit stalemate need their own adapters and evidence.
5. What are the initial economic/upkeep and mobilization values after testing real rival turns? All values must be displayed or discoverable; none should depend secretly on whether the player is winning.

These decisions do not block the isolated first-loop and deterministic-clock work. They do block claiming that the full living realm is finished or balanced. The implementation should grow through the gates above while keeping one chosen protagonist for the entire campaign, real opposing decisions, and consequences that remain true after the next save or battle.

## 19. Implemented v0.3 slice and evidence

The sources are [realm_rules.gd](../game/redesign/realm_rules.gd), [hunt_rules.gd](../game/redesign/hunt_rules.gd), ItemRules, HeroIdentity and ActionRules. The action ruleset is `draconia_action_v1`, save **version 4**, with genuine earlier action v1–v3 migration. The archived hex campaign remains separate. Only Mara is playable. Fixed class/race/faction permission is enforced; every personal signature, racial trait package and class-resource discipline remains design-only.

### Town, realm and story foundation

Implemented: the four-watch calendar; once-per-dawn player/rival accounting; paid stock-limited rival recruitment; authored-route movement toward neutral frontier resources; unopposed claims; graph-distance observation; top-three forecast; next-dawn/deadline advancement; two finite oaths; eight immediate construction definitions with atomic prerequisite/exclusive-plot/once-day limits; Market exchange, rest and Smithy preparation; solo story Vault; actual survivor/claim application; bounded saves and paid recovery.

Initial resources are 2,400 gold, 16 wood, 14 ore and 24 food. Mara's base is 120 Health, 40 Focus, 18 Attack, 2 Armor and 4.6 speed before actual gear/attribute/set derivation. Starter items are catalog instances. Waiting companies contain six spearmen and four archers. Vesper Court and Gloamfang Clans pay their own treasury/stock before marching, mobilizing at watches 12 and 16. They do not defeat defended targets through estimates. Field-company simulation and resumed opposing attacks remain pending.

The story Bellworn Vault costs two watches and supplies `playerCompanies:[]`; waiting companies stay unchanged. Bounds are `[-10,-12,10,12]`, walls `[-10,-3,8,0.9]` / `[2,-3,8,0.9]`, columns `[-6,2,1.4,1.4]` / `[4.6,2,1.4,1.4]`. Native geometry and collision use those same obstacles. Pending saves cannot replace actors, hero statistics, geometry or rewards. Enemy wounds/corpses and unclaimed drops survive retreat/revisit.

Story rewards remain Vowkeeper, Bellworn Cowl, a choice of Mistglass Pendant or Watcher's Knot, and 240 physical gold. Silence the Bell can separately pay 180 gold if accepted and fulfilled. The first extracted story clear grants 120 XP once. Its serial, location clear flag and claims never reset with the hunt board. The retained realm suite's earned story route used 507 action ticks, returned with 71 Health/10 Focus, collected four physical claims, retained both companies and spent two watches. This is automated-route evidence, not a production dungeon duration.

### Levels, attributes and fixed identity

Levels 1–30 use cumulative threshold `100 × (L − 1) + 25 × (L − 1) × (L − 2)`, capped at 23,200 XP. Three points initially and three per earned level give ninety spendable attribute points. Four scores start at ten; each may receive forty investments. Might adds +1 Attack, Finesse +0.04 actual speed, Vitality +6 maximum Health, and Spirit +2 maximum Focus/+1 finite Ward capacity per point. Command/Luck are not inert spendable placeholders.

`progression_view` exposes level/XP bounds, points, revision, allocations, displayed attributes and locks. Preview uses complete ItemRules before/after statistics. Apply rejects unknown/fractional/over-budget/over-cap/stale values atomically; pending encounter or recovery locks changes. Allocation never heals, refills, changes identity or spends watches. A friendly-town reset is free through level ten, then costs `min(1000, 50 × (level − 10))`; it refunds investment and clamps shrinking maxima. Thirty-point class talent trees are separate and unimplemented.

Mara is canonically Oathwarden/Hearthborn/Ashen Crown and casts Cleave/Ward only. Action submission/paused intent reject off-class spells. Ember belongs to a Pyromancer fixture; Roots to a Druid fixture. Twenty classes/eight races/156 unique signatures are mapped, with one fixed hero per campaign. Respec, race and gear cannot turn the effect library into a universal spell list. A committed legacy effect may finish without rewriting its pending snapshot, but cannot authorize another illegal cast.

### Repeatable hunt loop

Three offers register at the hero's earned level: **The Briar Kennels**, **The Ashen Watch Cellar**, **Moonfang Underpass**. These are three actor formations in the same current Vault arena, not three dungeon environments. Each has one gear drop, one material drop, physical gold and registered completion XP. Story-exclusive Vowkeeper/Cowl are excluded; the rotation supplies the other Bellworn pieces, normal socket base and existing accessories.

Entry requires a friendly town and costs two quoted watches. Only one contract can remain unfinished; re-entry pays two watches again but retains enemy Health, corpses, claims, tier and rolls. The persistent contract seed does not depend on attempt count. Retreat/defeat give no completion XP; physically collected items/gold remain claimed under the recovery policy. Actual clear plus legal exit grants registered XP once, forfeits uncollected spoils after explicit warning, and registers the next board. Action duration/pause costs no watches. Level-cap completion can refresh and collect normally without extra XP/points.

For tier `t`, enemy Health is `round(base × (1 + 0.045 × (t − 1)))`, Attack adds `floor((t − 1)/3)`, Armor adds `floor((t − 1)/5)`, XP adds `25 × (t − 1)` and gold adds `20 × (t − 1)`. A board stays fixed until completion. Its tier is not silently recalculated when gear changes or a save reloads. The 128-instance pack must have room for all remaining item rewards before departure charges time. History retains 32 recent records with explicit generation/attempt limits. [HUNT_CONTRACTS.md](HUNT_CONTRACTS.md) contains full templates, APIs and validation.

The recorded route earns level 30 through forty-six real completions using all three formations, earned gear and paid rest watches, then completes another run at the cap. This proves a working bounded loop, not varied endgame, human enjoyment or a complete campaign balance pass.

### Finite crafting supplies and sale

A built friendly Market with the hero present sells two normal socket bases, four each of Cinder/Stone/Gale Rune and four amber gems. It never restocks in this slice, including on hunt refresh. Prices are catalog value ×5; base + Cinder + Stone costs 220 gold and can legally form Hearthguard. It sells no rare, set or unique gear.

The Market buys a selected valid owned unequipped instance at catalog value, with exact preview and expected revision. Sale requires no pending expedition/recovery, removes the instance plus socket contents, pays once, preserves its claim record, increments revision and spends no watches. A stale callback or sell/re-entry cycle cannot duplicate payment. Salvage and unsocket are not implemented. `preview_reward` and grant share a constructor: world/story-location/reward or world/hunt-contract/reward fixes the roll independently of attempts.

### Exact evidence and limits

[hunt-contracts.json](verification-logs/hunt-contracts.json) records **1,390 checks / zero failures**, all exits 0, isolated writable XDG directories and stable rule/test hashes:

| Suite | Groups | Checks | Scope |
| --- | ---: | ---: | --- |
| Hunts | 9 | 458 | Contracts, real attrition/results, tier/loot/XP, sale/capacity and earned level-cap route |
| Realm | 14 | 247 | Calendar, construction, frontier rivals, oaths, real story rewards, finite supplies and preview consistency |
| Progression | 11 | 277 | Thresholds/budget/effects, no-heal transactions, locks, revisions and historical saves |
| Identity | 6 | 134 | Twenty classes/eight races/156 mappings, invalid identity, legal casts and legacy pending behavior |
| Items | 5 | 73 | Instances, slots, sets, sockets, derived-resource invariants |
| Action | 13 | 201 | Solo movement/combat, pause, physical claims, extraction and live persistence |

The independent native hunt/sale route passes **181 checks**, with twelve inspected captures at 1440×900, 1280×800 and 960×640. Real GUI events and legal commands earn two completions, level 3, a live reload, actual sale, explicit forfeiture and a refreshed board. No outcomes/XP are injected. Spell feedback has separate 43-unit/55-native-check evidence; eight static building cards have an 83-check proof. [VERIFICATION.md](VERIFICATION.md) preserves those exact boundaries. Old v0.2 101-check/17-capture evidence stays historical.

Still planned: selection/playable content beyond Mara; all personal/racial/class-resource effects and class talents; full nine-faction/162-recruit content; company deployment/reinforcements/transfers; defended capture/recapture and interrupted attacks; provisions/starvation; actual wall/gate/tower sieges; councils/claims/prisoners/diplomacy; broad campaign and dungeon routes; fully accepted 3D art/motion for the catalog. Character PBR and animated building-hover reviews remain pending. Food production/storage and catalog defense preparation do not prove supply consumption or an actual assault. No real-time performance, native Windows runtime, full-game or Heroes III parity claim follows from these totals.
