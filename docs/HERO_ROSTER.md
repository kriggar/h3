# Draconia — one chosen hero, a full selection roster

**Revision:** 22 October 2026. **Status:** authored design catalogue, not implemented playable content. The machine-readable source is [hero_roster.json](../data/hero_roster.json). The naming lock is [NAMING_AND_ART_LOCK.md](NAMING_AND_ART_LOCK.md).

## The campaign rule

The player chooses exactly **one hero at campaign creation** and controls that person for the entire campaign. There is no later hero recruitment, protagonist swap, playable-heir succession, second player army leader or second detachment inside a dungeon. The chosen hero leads up to six field companies in the full design. Every dungeon interior contains the hero alone; companies wait outside unchanged.

The production target is **144 standard heroes, sixteen per faction, plus twelve story heroes: 156 authored concepts**. All records now carry one fixed class, race and faction ID. There are **twenty classes and eight races** across that roster. Story characters may be NPC rivals, council figures or candidates in authored campaigns; they do not join as a second player hero. The current runtime supports only Mara Veyne, a **Hearthborn Oathwarden of the Ashen Crown**, with **Cleave and Ward**. Her proposed **Answer the Bell** signature, racial package and Oathmarks class discipline remain design-only.

The internal `ileana` alias resolves to `mara_veyne`; it is not an additional character. The class column in every table below is generated from `hero_roster.json` and `class_catalog.json`. A descriptive role such as Oathblade or Gate Captain does not replace that canonical class. Changing attributes, equipment or a future talent loadout cannot change it.

## Five distinct identity layers

| Layer | What it determines | What it cannot silently grant |
| --- | --- | --- |
| Race / ancestry | Two proposed small passives and one situational trait | Another class's spells, faction loyalty, moral alignment or a second signature |
| Fixed class | Legal skill pool, weapon/discipline identity and class-scoped talent access | Every spell in the shared effect library or a change through respec |
| Faction | Starting political ties, services, recruitment and doctrine | Ownership of every member of an ancestry or universally superior damage |
| Individual hero | One personally authored signature, history and relational hooks | An extra controllable avatar or every classmate's signature |
| Player build | Attributes, class talents, legal prepared skills, gear and oaths | Unlimited points, off-class magic or mandatory army entry into dungeons |

Full production progression targets **one innate signature plus five class-legal prepared abilities**, six active slots at maturity. Basic movement, attacks, guard, dodge and interact remain outside those slots. The implemented Mara opening shows only her two supported skills; her unimplemented signature is not a functioning button. New slot milestones belong to the future class progression and do not authorize an arbitrary skill from another hero.

Steel, Hunt, Command, Rites, Storm and Oaths are shared **talent-design families**, restricted by each fixed class's catalog. They are not six unrestricted spell schools. The 120 planned skill entries across the twenty class catalogs remain design briefs, with only the explicitly listed supported skills having present rule implementations. Equipment, attributes and oaths may modify a legal action; they never bypass class permissions. See [CLASS_DESIGN.md](CLASS_DESIGN.md) and section 5 of [GAME_DESIGN.md](GAME_DESIGN.md).

The implemented four-attribute system is separate from the proposed thirty-point talent budget. Every signature needs a useful solo and field application, clear cost, counter and tested class synergy before acceptance. All 156 unique personal signatures, all eight racial packages and all class-resource disciplines below remain design-only even though their identity mappings and spell restrictions are enforced now.

## Eight race / ancestry briefs

These are original fantasy peoples. Broad Eastern European folklore informs the setting, but ancestry does not make a real culture an enemy faction. Values below are intentionally small design directions; exact durations and numbers need balance tests. Situational traits have explicit use limits and cannot be farmed by menu switching.

### Hearthborn

Human lineages with varied cultures; neither a faction nor a moral alignment.

- **Steady Breath — passive:** Focus regeneration begins one small declared interval earlier after a cast; no extra regeneration while casting.
- **Careful Hands — passive:** Ordinary bandaging channels tolerate one small movement adjustment without cancelling; incoming damage still interrupts.
- **A Familiar Hearth — situational:** At a recognized friendly refuge, one local recovery interaction costs less ordinary supply once per declared rest cycle; no free full heal or sellable reward.

### Veilkin

Otherworld-touched people of bargains, rhythm and altered perception, not universally forest citizens.

- **Light Step — passive:** The first brief brush slowdown after a recovery interval is softened; solid obstacles remain blocking.
- **Glamour Sense — passive:** Nearby glamour boundaries gain a clearer edge when deliberately inspected; this does not reveal concealed enemies automatically.
- **Keep the Measure — situational:** After moving through a visible sequence without taking a hit, gain one short resistance to a fear interruption; sequences and cooldowns are bounded.

### Gravebound

People whose lives continue under a death-related bond; still capable of kindness, appetite, law and disagreement.

- **Still Breath — passive:** Breath-pressure hazards build more slowly, but poison and ordinary damage still apply.
- **Remembered Pain — passive:** The UI retains a clearer recent-wound marker for eligible recovery; it grants no extra health by itself.
- **A Quiet Vigil — situational:** An uninterrupted vigil at a registered resting place grants one small finite ward for the next encounter; cannot refresh inside that encounter.

### Gloamkin

People with a restrained predatory transformation, unrelated to automatic clan membership or hostility.

- **Close Scent — passive:** A recently encountered wounded foe leaves a short local trace; no tracking through undiscovered rooms.
- **Sure Landing — passive:** Minor uneven-ground landing recovery is shortened slightly; combat leap commitments keep their minimum tells.
- **Held Hunger — situational:** Refusing to chase a routed eligible enemy steadies personal resolve once per encounter; no kill reward or automatic healing.

### Emberkin

Heat-marked lineages with diverse bodies and communities; neither fireproof nor obliged to the Dominion.

- **Warm Blood — passive:** Ordinary chill buildup is slightly slower; freezing hazards and direct frost damage remain relevant.
- **Forge Touch — passive:** Brief contact with minor hot props has a longer warning grace; combat fire and lava remain dangerous.
- **Banked Warmth — situational:** After leaving a real warm refuge, one small chill effect can be reduced by consuming stored warmth; it does not replenish from self-cast fire.

### Reedkin

Water-touched people whose homes and loyalties extend beyond the delta.

- **Shallow Step — passive:** Shallow-water movement penalties are modestly reduced; deep water restrictions remain.
- **Patient Lung — passive:** Noncombat underwater inspection grants a little more warning time, not indefinite underwater combat.
- **Read the Current — situational:** Deliberate inspection of connected local water reveals its flow and one obvious hazard boundary; no global enemy reveal.

### Cairnkin

Stone-linked people shaped by memory and craft, with individual loyalties rather than an inherited profession.

- **Grounded Heel — passive:** Small forced displacements are reduced slightly; heavy telegraphed pushes still require a response.
- **Stone Ear — passive:** Nearby unstable supports give an earlier noncombat warning when inspected; no hidden damage bonus.
- **Rest Against Stone — situational:** A safe camp beside valid stone can preserve one ordinary recovery supply once per rest cycle; combat cannot regenerate the supply.

### Stormmarked

People altered by a storm pact or birth event; an origin independent of ancestry politics and faction doctrine.

- **Pressure Sense — passive:** A scheduled weather transition gains a slightly earlier personal warning; the encounter schedule is unchanged.
- **Static Patience — passive:** Minor shock buildup decays slightly sooner out of harm; direct lightning damage remains.
- **Ground the Charge — situational:** A deliberate stationary guard on safe ground can consume one small accumulated shock status to steady the next aimed action; no recursive charge farming.

## Standard selection catalogue

Every row below corresponds to a unique record with fixed class/race/faction IDs and a full signature mechanic, limit/counter, solo use and army use in the JSON. The concise table makes the choices reviewable; it is not an acceptance checklist with automatic checkmarks.

### The Ashen Crown — Dawnreach

**Region:** The Ashen March. **Doctrine:** Organized defense and reciprocal civic oaths; doctrine belongs to the faction, not every member's ancestry.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Mara Veyne** · Hearthborn | Oathwarden | Oathblade | **Answer the Bell:** Plant a visible bell-mark; the first successful frontal guard inside it stores one response strike that Mara may release as a short cone. | One stored strike; leaving the mark loses it; flanking bypasses the setup. |
| **Alden Rook** · Hearthborn | Warlord | Gate Captain | **Turn the Gate:** Raise a temporary hinged shield screen and rotate it once to redirect the lane it blocks. | Screen has finite integrity, blocks allied shots too and can be flanked. |
| **Sera Flint** · Stormmarked | Oathwarden | Signal Warden | **Three Fires:** Place three small signal embers; activating one consumes the other two to send a single connecting fire pulse along their segments. | Requires setup and clear segments; each enemy can be struck only once. |
| **Bren Halwick** · Hearthborn | Warlord | Veteran Marshal | **Borrowed Courage:** Choose a threatened ally or self; its next successful guard creates a small rally zone at the contact point. | No trigger from harmless hits; one zone, short duration and no resurrection. |
| **Elin Ward** · Gravebound | Oathwarden | Remembrance Knight | **Kept Vigil:** Record a defended point, then channel to return a limited portion of health lost while holding it as recoverable vigor. | Only recent real harm; channel is interruptible; cannot restore lethal damage. |
| **Torren Vale** · Hearthborn | Oathwarden | Road Justiciar | **Stay Your Hand:** Challenge one melee enemy; a clearly marked attack it commits against someone else exposes its next recovery to interruption. | Does not force obedience or affect an uncommitted attack; bosses gain resolve. |
| **Nessa Crowe** · Veilkin | Warlord | Border Scout | **False Crossing:** Leave one moving decoy on a short recorded route while Nessa makes a separate visible reposition. | Decoy causes no damage, ends on contact and never redirects a committed area tell. |
| **Garran Holt** · Cairnkin | Oathwarden | Siege Keeper | **Brace the Breach:** Channel a short-lived brace onto an existing doorway, wall gap or personal shield to absorb a bounded incoming impact. | Requires a valid surface or equipped shield; fire and flanks bypass its main value. |
| **Lysa Rowan** · Hearthborn | Oathwarden | Mercy Herald | **Mercy's Interval:** Mark a retreating or staggered foe; refrain from harming it briefly to gain a small protective reserve. | Damage from the player's side breaks the interval; no repeat reward from the same foe. |
| **Dain Mercer** · Emberkin | Warlord | Sword Bailiff | **Measured Verdict:** Alternate two aimed cuts; landing both on different sides of the same target enables one narrow finishing thrust. | A missed cut or repeated side ends the sequence; no automatic critical strike. |
| **Asha Fen** · Reedkin | Warlord | Bridge Sentinel | **Take the Span:** Dash only along a short visible straight strip, stopping at the first hostile body and bracing at that endpoint. | Cannot cross walls, deep gaps or large blockers; turning is restricted after arrival. |
| **Orin Pell** · Hearthborn | Warlord | Quartermaster Knight | **Last Provision:** Deploy one supply bundle that restores a small recoverable reserve through an interruptible use action. | Finite encounter charge; cannot be sold, duplicated or used while taking damage. |
| **Vela Ash** · Stormmarked | Oathwarden | Cinder Confessor | **Ash Witness:** Mark the site of a hostile spell impact; convert its remaining harmless residue into one delayed retaliatory ember. | Requires surviving a real hostile spell; cannot copy its damage or trigger itself. |
| **Harlan Wren** · Hearthborn | Warlord | Pennant Duelist | **Open Standard:** Carry a visible pennant that trades personal guard strength for faster formation reform; furl it to regain a brief deliberate parry. | Cannot keep both modes; parry is timed and still vulnerable to ranged attacks. |
| **Mira Dawes** · Gravebound | Oathwarden | Oath Mediator | **Shared Watch:** Link to one ally or a personal ward; alternate which partner receives the next eligible small hit after a clear warning. | Transfer is capped, never recursive and can endanger the hero. |
| **Corven Hale** · Hearthborn | Warlord | Crown Ranger | **Royal Measure:** Shoot or throw a visible measuring tether; keeping its marked enemy inside a narrow distance band prepares one stronger aimed follow-up. | Broken line of sight or bad spacing removes readiness; no through-wall pull. |

### The Thornweald Court — Briarhollow

**Region:** The Thornweald. **Doctrine:** Reciprocal forest bargains, misdirection and protected living places.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Eira Thist** · Veilkin | Ranger | Briar Dancer | **The Missing Step:** Mark two nearby steps, then exchange places with the unoccupied marker during a brief rhythm window. | Both endpoints need visible walkable ground; only one exchange and no wall crossing. |
| **Cael Bracken** · Hearthborn | Druid | Root Keeper | **Borrow the Root:** Anchor one enemy's shadow to a root; its movement stretches the tether until it breaks in a short slow. | No damage from standing still; strong displacement breaks it; bosses shorten the bind. |
| **Sylra Moth** · Veilkin | Druid | Glamour Weaver | **Lantern Veil:** Create a translucent veil that hides exact target selection beyond it while retaining visible silhouettes and area tells. | Does not block collision or projectiles; enemies can enter or use area attacks. |
| **Bram Alder** · Cairnkin | Ranger | Grove Guardian | **Living Buttress:** Raise two low root braces that intercept a finite number of low projectiles and leave a passable centre. | Tall or lobbed attacks bypass them; braces can be destroyed. |
| **Nyra Willow** · Reedkin | Druid | Dew Binder | **Gather the Dew:** Condense moisture from one wet patch into a finite healing mist, drying the source patch. | Requires an actual wet surface; interruptible channel and capped recovery. |
| **Oren Foxglove** · Hearthborn | Ranger | Bargain Archer | **Thorn Receipt:** Tag an enemy with a harmless thorn; the next real hostile action it completes leaves a destructible thorn token that can be shot to stagger it. | One token; the foe can move beyond token range or destroy it; bosses gain resolve. |
| **Fara Quill** · Veilkin | Druid | Wild Scribe | **Rewrite the Path:** Draw a short visible vine lane; allies travelling with its direction move freely through brush while enemies crossing it receive a brief slow. | Only brush changes, not walls or water; one lane and no slow stacking. |
| **Talen Briar** · Gloamkin | Ranger | Pact Hunter | **Scent of the Bargain:** Name a marked quarry; tracking its actual recent trail grants one short pursuit burst after a deliberate pause. | No detection through sealed rooms; burst ends on attack or broken trail. |
| **Iria Wisp** · Veilkin | Druid | Echo Singer | **Answering Note:** Sing a visible expanding ring; a second activation at the ring edge sends one return pulse inward. | Mistimed return is weak; solid cover interrupts the ring and no repeated hits. |
| **Dovan Moss** · Hearthborn | Ranger | Warden of Hush | **Quiet Ground:** Consecrate a small patch where hostile channel tells remain visible and cannot be concealed by fog or glamour. | Does not silence spells or prevent damage; staying inside limits movement. |
| **Sable Fern** · Gravebound | Druid | Autumn Keeper | **Falling Season:** Consume one existing burn or poison on a target to create a slower, weaker lingering hazard at its feet. | Consumes rather than duplicates the status; enemy can leave the patch. |
| **Lorin Reedleaf** · Reedkin | Druid | Brook Envoy | **A Fair Exchange:** Swap one removable boon on self with one removable ailment on a willing ally, converting incompatible effects into a modest ward. | Cannot transfer lethal damage, boss marks or create positive effects from nothing. |
| **Tessa Thorn** · Hearthborn | Ranger | Thorn Duelist | **Caught Blade:** Set a short parry that catches one melee strike and leaves a visible briar snag on the attacker. | Missed timing has recovery; ranged attacks bypass it; snag breaks after one displacement. |
| **Vael Moonseed** · Stormmarked | Druid | Night Gardener | **Moonseed:** Plant a seed that opens only after a nearby hostile spell passes; its blossom grants one small ward to the first ally reaching it. | One seed; it can be trampled and does not trigger from friendly spell spam. |
| **Rook Hazel** · Cairnkin | Ranger | Hollow Ranger | **Knock on Wood:** Strike a natural or placed wooden obstacle to send a narrow echo that reveals movement immediately behind it. | Reveals only a short local strip; no damage or permanent enemy tracking. |
| **Anwen Lark** · Veilkin | Ranger | Dance Marshal | **Leave a Place:** Order a brief formation gap; occupying its marked centre yourself produces a timed outward push against light foes. | Requires a real gap or personal anchor; heavy enemies resist; no unlimited repeated shove. |

### The Cloudspire Conclave — Stormcairn

**Region:** The Cloudspires. **Doctrine:** Prepared weathercraft, measured risk and mountain observation.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Veyra Gale** · Stormmarked | Stormcaller | Tempest Adept | **Split the Gust:** Fire a narrow gust, then choose left or right at its marked hinge to bend the remaining wave once. | One bend, reduced force after it and no cornering through walls. |
| **Nolan Skyre** · Hearthborn | Stormcaller | Weather Surveyor | **Pressure Line:** Place two pressure pins; crossing their line converts a following hostile projectile into a visible deflected arc. | One deflection per activation; heavy siege shots and area spells ignore it. |
| **Syla Crest** · Veilkin | Stormcaller | Cloud Binder | **A Pocket of Sky:** Lift a small dust cloud that reveals silhouettes and gently drifts in the current wind. | No invisibility or hard cover; rain disperses it sooner. |
| **Arden Coil** · Cairnkin | Spellblade | Storm Engineer | **Grounding Chain:** Lay a chain between self and a metal anchor; it drains one incoming shock into the ground but restricts movement. | Finite charge; breaking the tether loses it; fire and melee remain dangerous. |
| **Lysa Vane** · Stormmarked | Spellblade | Kite Duelist | **Windcatch:** Raise a short catch window; a projectile that would graze the outer guard creates one lateral movement charge. | Direct hits still hurt; charge has a short expiry and no wall crossing. |
| **Orren Pike** · Hearthborn | Spellblade | Peak Guide | **Find the Lee:** Designate a safe lee behind real cover; reaching it reduces one displacement effect and steadies the next aimed action. | Needs physical cover; enemies can approach from the exposed side. |
| **Mira Nimbus** · Reedkin | Stormcaller | Rain Keeper | **Rain in the Palm:** Collect nearby rain into a small projectile that bursts into a wet patch on contact. | Requires wet weather or a wet source; removes some source moisture and deals little damage. |
| **Caden Flintsky** · Emberkin | Spellblade | Thunder Smith | **Ring the Anvil:** Strike a placed metal token to release a short cone of concussive sound after a visible delay. | Token can be destroyed; one cone, heavy foes resist displacement. |
| **Aeri Dawn** · Veilkin | Stormcaller | High Scryer | **Stormglass:** Hold a lens on one enemy until its next attack begins, then mark the real committed direction for a short counter window. | Channel exposes the hero; mark does not change enemy behavior or guarantee a hit. |
| **Garrick Spire** · Cairnkin | Spellblade | Cliff Warden | **Ledge Oath:** Anchor to a visible solid point and refuse one forced displacement, converting part of its force into a finite guard reserve. | No protection from ordinary damage; anchor range is short and cannot bridge a fall. |
| **Sera Volt** · Stormmarked | Spellblade | Arc Runner | **Borrowed Spark:** Catch one weak electrical effect with a timed ward and carry its charge to a single contact strike. | Charge leaks quickly, harms an unguarded holder and cannot recharge itself. |
| **Tavin Rill** · Hearthborn | Stormcaller | Mist Cartographer | **Draw the Front:** Sketch a moving boundary that briefly parts fog along its route without removing weather elsewhere. | No damage or revealed enemies outside the narrow strip; one boundary. |
| **Eris Snow** · Gravebound | Stormcaller | Frost Witness | **Still the Drop:** Freeze one small wet patch into rough ice that slows turning more than straight movement. | Dry ground fails; fire thaws it; allies obey the same traction rule. |
| **Bela Kite** · Hearthborn | Spellblade | Sky Courier | **Carry the Call:** Send a visible wind-carried order token; the first allied company or personal ward it reaches gains one queued-action buffer. | Token can be intercepted; it changes readiness, not action speed or damage. |
| **Thoren Hail** · Emberkin | Spellblade | Hail Breaker | **Shatterfall:** Gather a short cone of airborne water or debris, then drop it into a narrow stagger zone. | Requires a material source; long tell and finite boss resolve contribution. |
| **Nara Peak** · Stormmarked | Stormcaller | Clear-Sky Herald | **The Quiet Eye:** Maintain a small calm circle where wind displacement is reduced while outer gusts continue normally. | Channel limits movement; no spell silence or damage immunity. |

### The Vesper Court — Duskharrow

**Region:** The Mourning Vale. **Doctrine:** Inheritance, memory, restraint and the obligations of long-lived houses.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Selene Dusk** · Gravebound | Rogue | Memory Duelist | **The Second Cut:** Record the arc of one missed melee swing, then release a weaker echo along that exact empty arc later. | The echo cannot track a new target or trigger another recording. |
| **Rovan Mourn** · Hearthborn | Death Knight | House Advocate | **Name the Debt:** Mark a foe that has just harmed an ally; intercepting its next attack converts part of the intercepted harm into a capped debt strike. | Must take or guard a real attack; no debt from environmental or friendly damage. |
| **Vessa Gloam** · Veilkin | Necromancer | Curtain Witch | **Close the Curtain:** Create a thin dark curtain that breaks target tracking only while actors are fully behind it. | Projectiles still travel through; stepping out restores visibility; finite integrity. |
| **Darian Veil** · Gravebound | Necromancer | Tomb Keeper | **Borrowed Silence:** Seal one corpse so its lingering hazard stops while a small ward is sustained at the corpse's location. | No corpse consumption or loot deletion; one seal and no active-enemy silence. |
| **Iona Ashveil** · Stormmarked | Necromancer | Funeral Bell | **Toll for the Living:** Sound a delayed ring; living allies inside when it returns gain resolve while hostile channels crossed by it receive a brief warning mark. | No immediate interrupt; sound-blocking walls stop it and it cannot stack itself. |
| **Lucan Rill** · Reedkin | Necromancer | Bloodless Physician | **Divide the Hurt:** Convert a bounded portion of one recent hit into three scheduled smaller harm ticks with visible countdowns. | Total harm remains, cannot be delayed twice and is not cleared by leaving combat. |
| **Marec Sable** · Hearthborn | Rogue | Night Bailiff | **The Closed Door:** Mark an existing doorway; the first enemy crossing it is briefly exposed from behind. | Does not lock the door; only one trigger and wide/open rooms counter it. |
| **Ysra Vell** · Gravebound | Necromancer | Relic Reader | **Hands of Yesterday:** Read one destroyed obstacle and briefly reconstruct its non-damaging cover shape. | Finite integrity; cannot restore a captured gate, seal an exit or duplicate salvage. |
| **Corin Latch** · Cairnkin | Death Knight | Vault Sentinel | **Locked Measure:** Declare a short range ring; guarding at its edge traps one incoming melee weapon in a brief recovery extension. | Precise spacing; does not disarm permanently and ranged foes ignore it. |
| **Nerys Vane** · Veilkin | Rogue | Mourning Dancer | **Black Ribbon:** Attach a visible ribbon to an enemy; circling it without being hit produces one short pull toward the ribbon's tangent. | Breaks on blocked line of sight, large distance or taking damage; heavy bodies resist. |
| **Odran Pale** · Gravebound | Necromancer | Last-Will Keeper | **A Written Exit:** Place a personal exit seal that permits one short return only while a channel completes unharmed. | No escape from death, no wall bypass and no realm extraction; destroyable seal. |
| **Asha Wane** · Emberkin | Necromancer | Ash Embalmer | **Cool the Brand:** Consume an active burn on self or ally to forge a finite brittle ward that breaks on a heavy hit. | Burn is removed, not copied; shield cannot absorb more than its listed pool. |
| **Velis Thorn** · Gloamkin | Rogue | Grave Hound | **Follow the Last Step:** Read the last movement segment of a recently defeated enemy and surge along part of it. | One surge per corpse, no teleport through walls, no loot consumption. |
| **Mira Noct** · Hearthborn | Death Knight | Night Contracter | **Witnessed Mercy:** Offer a marked wounded ordinary enemy a brief disengagement; if it leaves the circle, both sides lose its pursuit mark. | Bosses and mindless foes refuse; harming it breaks the offer and gives no reward. |
| **Dorel Ink** · Gravebound | Necromancer | Lineage Scribe | **Seal the Boast:** Mark one visible enemy boon; its next refresh instead shortens the current boon once. | Does not dispel on demand; inactive or unrefreshed boons counter it. |
| **Talia Grey** · Stormmarked | Death Knight | Dawn Exile | **Let Morning In:** Open a narrow directional beam that reveals glamour and gradually weakens temporary wards in its path. | Hero channels and turns slowly; physical armor and solid cover remain. |

### The Gloamfang Clans — Fangrest

**Region:** The Moonscar Peaks. **Doctrine:** Pack bonds, transformation discipline and committed pursuit.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Raska Fen** · Gloamkin | Berserker | Pack Pathfinder | **The Near Hunt:** Choose a quarry and show its local pursuit boundary; crossing that boundary inward grants one brief lunging attack. | No tracking outside known ground; leaving the boundary loses readiness. |
| **Eren Wolfmere** · Hearthborn | Moon Witch | Moon Restraint | **Hold the Hunger:** Store a small portion of eligible basic-attack damage as hunger, then spend it on either a self ward or a short pounce. | Mutually exclusive spend, capped storage and no gain from objects or secondary procs. |
| **Sivra Fang** · Gloamkin | Berserker | Circle Breaker | **Through the Teeth:** Lunge at a gap between two enemies and strike outward on landing if the gap remains walkable. | Blocked gap stops early; no passage through large bodies; long recovery on failure. |
| **Boran Ridge** · Cairnkin | Berserker | Den Warden | **Stand at the Den:** Mark a small den boundary; the first enemy entering each marked side is checked by a brief body brace. | One check per side and limited duration; ranged pressure bypasses it. |
| **Nessa Moon** · Veilkin | Moon Witch | Howl Listener | **Answer Before Dawn:** Listen through a short channel; reactivate when a marked enemy begins a heavy attack to release a focused interrupting howl. | Mistiming wastes the charge; bosses gain resolve and solid cover muffles it. |
| **Varric Ash** · Emberkin | Berserker | Fang Smith | **Hot Bite:** Heat the next close strike so it damages a ward efficiently but briefly lowers the hero's own guard stability. | One contact, poor value against an unwarded target and no recursive burn. |
| **Elra Moss** · Reedkin | Moon Witch | Pack Mender | **Lick the Wound:** Channel beside an ally or alone to recover only a portion of the most recent nonlethal wound. | Cannot recover old or lethal damage; moving or a new hit interrupts. |
| **Toren Gloam** · Gloamkin | Berserker | Night Flanker | **Outside the Ring:** Mark an enemy's facing; staying outside its forward arc charges one short flank strike. | Facing updates until commitment; taking a frontal hit clears charge. |
| **Mara Thornfell** · Hearthborn | Moon Witch | Clan Envoy | **The Open Palm:** Briefly lower the weapon to calm one frightened allied unit or self, then gain a defensive follow-up if no attack was made. | No damage during the gesture; cannot calm mindless units or erase all morale loss. |
| **Kellan Scar** · Gloamkin | Berserker | Blood Tracker | **A Trail Paid For:** Mark a wounded enemy's actual path with visible scent points; consuming one by crossing it accelerates the next basic approach. | Each point works once; no health generation and no pursuit through sealed geometry. |
| **Veyla Hush** · Gravebound | Moon Witch | Winter Howler | **The Soundless Howl:** Create a delayed fear edge that turns light enemies away from its centre for a brief step. | Bloodless foes resist; hero bosses are never forced offscreen; one displacement. |
| **Dain Briarjaw** · Gloamkin | Berserker | Pounce Duelist | **Land Lightly:** Aim a short pounce that gains a guard window only if the landing avoids hostile bodies and hazards. | No free guard on a damaging landing; walls block travel and charge is limited. |
| **Iris Soot** · Stormmarked | Moon Witch | Moonfire Keeper | **Pale Pursuit:** Send a slow visible moonfire orb toward a quarry's last recorded position; touching its trail grants a brief pursuit ward. | Orb never homes after release; one ward per actor and finite recipients. |
| **Garron Reed** · Reedkin | Moon Witch | Marsh Stalker | **Still Scent:** Remain still briefly in shallow water to conceal the next movement start, then leave a visible wake. | Ends on attack or leaving water; no invisibility while dealing damage. |
| **Lena Redvale** · Hearthborn | Moon Witch | Oath of the Pack | **No One Behind:** Name a real wounded ally or a personal fallback marker; moving toward it grants one resistance to interruption. | Only while approaching, no damage bonus, no teleport or invulnerability. |
| **Orik Frostfang** · Cairnkin | Berserker | Stonejaw Champion | **Catch the Charge:** Brace into one announced charge and redirect its endpoint slightly sideways if timing succeeds. | Does not negate all damage; heavy bosses only lose some momentum; flank attacks win. |

### The Emberhorn Dominion — Cindervault

**Region:** The Copper Wastes. **Doctrine:** Large bodies, forged authority, heat and costly displays of power.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Zara Cinder** · Emberkin | Reaver | Forge Heir | **Tempered Answer:** Absorb one guarded heat packet into the weapon, then choose a narrow cutting release or a broad low-damage shock. | Finite stored heat; charge decays, no gain from friendly repeated casts. |
| **Brenna Copper** · Hearthborn | Reaver | Bronze Captain | **A Weight of Law:** Plant a heavy standard that slows both sides turning within its short radius while allies can voluntarily leave. | No movement imprisonment; ranged attacks and outside angles counter it. |
| **Korven Horn** · Emberkin | Reaver | Giant's Envoy | **Knee of the Mountain:** Deliver a delayed downward blow that leaves a temporary low ridge and a clear step-around path. | Long anticipation, destructible ridge, no sealing exits or spawning siege walls. |
| **Sira Coal** · Gravebound | Pyromancer | Ash Reader | **What the Fire Left:** Read one burned patch and pull its remaining heat into a slow ember that follows the patch's longest edge. | Requires an existing burn zone; consumes it and cannot bend through walls. |
| **Dalen Bronzewick** · Cairnkin | Reaver | Foundry Keeper | **Forge Clamp:** Place an obvious clamp that grips the first light hostile crossing it until it is struck or times out. | One clamp, visible and destructible; heavy bodies trigger a brief slow instead. |
| **Vara Flint** · Stormmarked | Pyromancer | Furnace Caller | **Draw the Breath:** Pull loose fire into a short inhaled charge, then exhale it in a cone with range determined by the charge. | Stationary channel, finite heat source and fire resistance matter. |
| **Arik Gild** · Hearthborn | Reaver | Pride Duelist | **A Public Challenge:** Mark a nearby foe and narrow personal guard to its direction; landing a timed counter exposes that foe to the next ally hit. | Unmarked attackers exploit the narrow guard; one follow-up consumes exposure. |
| **Nerra Glass** · Veilkin | Pyromancer | Mirrorglass Adept | **Cracked Reflection:** Raise a fragile reflective pane that redirects one low-energy projectile at an aimed new angle. | Pane breaks on melee or heavy projectiles; reflected damage is reduced. |
| **Tovan Ember** · Emberkin | Pyromancer | Coal Runner | **Cinder Footpath:** Lay a short trail while moving; activate its far end to send a weak burning pulse back toward the start. | Trail length capped; water breaks it and each enemy is hit once. |
| **Mira Kiln** · Reedkin | Pyromancer | Steam Warden | **Quench:** Apply a small water burst to one hot surface, making short-lived steam that blocks precise targeting for both sides. | Requires heat; no damage immunity and projectiles retain physical collision. |
| **Garrik Goldash** · Cairnkin | Reaver | Vault Breaker | **Fault in the Plate:** Study one armored target at close range, then strike a visible seam to reduce only its frontal guard integrity temporarily. | Study can be interrupted; no permanent armor deletion and moving out of range resets it. |
| **Lysa Redglass** · Hearthborn | Reaver | Arena Marshal | **Give Ground:** Declare a narrow retreat strip; each deliberate backward guard step stores one limited forward shove. | Small storage cap; attacking cancels further storage; no wall-crossing knockback. |
| **Orven Pyre** · Gravebound | Pyromancer | Last Ember | **An Ember Kept:** Bank one surviving fire mote in a personal ward; manually breaking the ward releases a weak area flash. | Breaking sacrifices remaining protection; no free flash on repeated refresh. |
| **Selka Brass** · Stormmarked | Pyromancer | Chain Artificer | **Copper Circuit:** Connect two temporary metal stakes; a shock crossing one stake travels once to the other at reduced strength. | Finite integrity, visible links and no recursive circuits; allies also obey conductive hazards. |
| **Dorin Warmstone** · Emberkin | Pyromancer | Hearth Protector | **The Shared Hearth:** Create a small warm resting point that removes chill gradually while the hero guards its edge. | No immediate full cleanse, no healing under constant incoming damage and finite lifetime. |
| **Veyna Crownscale** · Gloamkin | Reaver | Wyrm Handler | **Bow to the Flame:** Use a low stance to bait a beast's next uncommitted breath aim, then roll aside and mark the exposed neck. | Cannot redirect committed breath; failure is dangerous and humanoid foes ignore it. |

### The Reedbound League — Reedhaven

**Region:** The Mirrorwater Delta. **Doctrine:** Shared waterways, mobile defense, tides and negotiated passage.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Nera Tide** · Reedkin | Tidebinder | Current Speaker | **The Returning Wave:** Send a shallow wave outward; its return follows the same route and briefly slows enemies moving against it. | No wall crossing, weak on dry raised ground and one effect per pass. |
| **Alden Marsh** · Hearthborn | Wayfinder | Ferry Captain | **A Rope Between:** Throw a rope to a visible anchor; allies can cross its short shallow-water route without the usual current drift. | Cannot bridge deep impassable water; anchor can be destroyed and route is narrow. |
| **Syla Mere** · Veilkin | Tidebinder | Mirror Duelist | **Leave a Reflection:** Place a reflection at a real wet patch that repeats only the hero's next guard facing, creating one small directional ward. | No attack copy, dry ground fails and the ward has finite capacity. |
| **Varron Silt** · Cairnkin | Tidebinder | Bank Warden | **Raise the Silt:** Build a low temporary bank from muddy ground that redirects shallow runoff and blocks low shots. | No free stone wall, dry rock fails, bank erodes and allies are affected. |
| **Eris Fenlight** · Stormmarked | Tidebinder | Reed Lantern | **A Light Below:** Sink a lantern into water to reveal moving bodies and traps within a small connected wet area. | Not a global reveal; opaque sealed pools remain separate and lantern is destroyable. |
| **Bela Ford** · Hearthborn | Wayfinder | Water Bailiff | **Declare Passage:** Mark a short corridor; the first hostile stopping inside it becomes exposed, while moving through avoids the effect. | No effect on passing enemies; finite duration and one exposure. |
| **Tessa Drift** · Reedkin | Wayfinder | Wake Runner | **Ride the Wake:** Use the recent path of a moving large actor as a short speed lane, ending with a controlled stop. | Needs a real moving actor; lane decays quickly and does not pass through its body. |
| **Orin Drowned** · Gravebound | Tidebinder | Memory Diver | **Bring Back a Breath:** Channel at water or a prepared flask to restore a small exhausted Focus reserve over time. | One bounded reserve per encounter; interrupted channel and no health resurrection. |
| **Mara Rush** · Hearthborn | Wayfinder | Delta Scout | **Split the Reed:** Cut a narrow path through reeds, leaving a visible return marker that shortens one later retreat along it. | Vegetation only, limited length; enemies can use the path too. |
| **Kellan Pool** · Gloamkin | Wayfinder | Otter Knight | **Under the Spray:** Dive through a short shallow-water strip and emerge in a guarded crouch. | No use in dry rooms or deep forbidden water; emergence is fixed and punishable. |
| **Vela Brine** · Reedkin | Tidebinder | Salt Binder | **Taste of Salt:** Apply a visible salt ring that weakens one removable glamour or regeneration effect when its bearer crosses it. | No effect on ordinary armor; one crossing trigger, ring can be washed away. |
| **Dain Rill** · Emberkin | Wayfinder | Steam Envoy | **Mist and Iron:** Heat a wet shield to vent a short steam fan when a frontal hit lands. | Requires a shield and wet state; consumes wetness, finite proc and no chain burns. |
| **Anra Swan** · Veilkin | Tidebinder | River Arbiter | **Two Banks:** Mark two small safe-bank zones; alternating between them earns one short cleanse of movement impairment. | Must physically travel; marks have limited distance and cannot cleanse boss bonds. |
| **Toren Reedlock** · Cairnkin | Wayfinder | Lock Keeper | **Open the Sluice:** Release a small registered water store to push light bodies along a visible channel. | Consumes a real scenario or carried charge; no infinite water, heavy bodies resist. |
| **Lysa Dawnwater** · Hearthborn | Wayfinder | Rescue Oarswoman | **Take My Hand:** Throw a short rescue line to a willing ally or personal anchor and pull the nearer partner a limited distance. | Clear line, consent, weight limit and vulnerable channel; no pulling through obstacles. |
| **Nolan Glassmere** · Stormmarked | Tidebinder | Stillwater Seer | **Break the Surface:** Wait beside a calm wet patch to reveal the direction of the next nearby hostile projectile before release. | Only one warning, no guaranteed dodge and moving water interrupts observation. |

### The Ironroad Compact — Crossmere

**Region:** The Ninefold Road. **Doctrine:** Trade, practical engineering, professional companies and local freedom.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Dara Cross** · Hearthborn | Marshal | Free Company Captain | **Terms of Advance:** Set an advance marker and a fallback marker; switching between them grants one brief formation-stability window. | No repeated reward from unchanged markers; window protects order, not health. |
| **Brenna Lock** · Cairnkin | Marshal | Field Engineer | **Folded Cover:** Unfold a portable low screen that can be packed again only while undamaged and out of danger. | One screen, finite integrity and no resource duplication after destruction. |
| **Cael Tinker** · Hearthborn | Thief | Clockwork Skirmisher | **The Late Bolt:** Set a spring bolt to fire after a visible short countdown along an aimed line. | Single shot, destroyable mechanism and no auto-tracking after placement. |
| **Sera Wayglass** · Veilkin | Thief | Road Illusionist | **Wrong Signpost:** Place a decoy route marker that briefly attracts one uncommitted scouting enemy's investigation. | Cannot compel a committed attacker or boss; no damage and short duration. |
| **Orven Flintlock** · Emberkin | Runemage | Powder Warden | **Measured Fuse:** Lay a short slow fuse to a small concussive charge; shorten it manually at the risk of staying nearby. | Visible, wetness extinguishes it, finite charge and no friendly immunity to force. |
| **Tessa Ledger** · Hearthborn | Marshal | Contract Marshal | **Paid in Readiness:** Select a company or self and suspend one offensive action to bank a single faster preparation of a different action. | Cannot reduce commitment below the readable floor; no same-action spam. |
| **Garran Axle** · Cairnkin | Marshal | Wagon Guard | **Turn the Wheel:** Rotate a real wagon or portable wheel shield a short angle to intercept one announced attack lane. | Requires an existing movable object; slow turn and exposed rear remain. |
| **Mira Knott** · Reedkin | Thief | Line Runner | **Quick Rig:** Attach a short trip line between two legal nearby anchors. | One line, visible to attentive foes, breaks after a trigger and heavy bodies resist. |
| **Nolan Brand** · Stormmarked | Runemage | Signal Artificer | **Copper Messenger:** Send a slow signal spark to a visible point; arriving grants one precise aim cue to the next eligible attack there. | Destroyable, bounded lifetime and no magical projectile duplication. |
| **Rook Fenner** · Gloamkin | Thief | Bounty Tracker | **The Living Warrant:** Mark a wounded ordinary enemy for capture; a qualifying nonlethal stagger makes it surrender instead of dying. | Requires an eligible foe and safe control; bosses refuse and attacks can still kill it. |
| **Elra Patch** · Hearthborn | Runemage | Field Chirurgeon | **Hold Still:** Place a finite dressing on self or ally; it restores recent recoverable harm only if the recipient avoids attacking briefly. | Damage or attacking delays it; no resurrection or old-wound reset. |
| **Varric Bridge** · Gravebound | Marshal | Road Witness | **A Promise Recorded:** Mark one defended civilian or object; intercept its next eligible hit to gain a bounded protective reserve. | Reserve requires actual protection and can occur once; cannot farm friendly hits. |
| **Lena Spoke** · Hearthborn | Marshal | Mounted-Craft Veteran | **Running Start:** Build a short charge while moving on a clear route, then release it as a controlled stopping strike. | No horse is conjured; obstacles reset charge and a missed stop leaves recovery. |
| **Dorian Penn** · Veilkin | Marshal | Guild Negotiator | **A Moment's Terms:** Offer a brief local disengagement to one wavering eligible foe; both sides lose offensive readiness during acceptance. | No boss mind control, visible refusal and damage breaks negotiation. |
| **Asha Rivet** · Emberkin | Runemage | Armor Fitter | **Loose the Joint:** Temporarily release part of the hero's armor to gain a precise sidestep, then restore it with a short vulnerable fastening action. | Lower armor persists until fastening; cannot reset dodge cooldown. |
| **Tovin Bell** · Hearthborn | Marshal | Road Herald | **Make Way:** Sound a directional call that makes friendly bodies yield along a short corridor and marks a fallback point. | No enemy displacement or teleport; yielding keeps each body within legal terrain. |

### The Deepcairn Pact — Stonewake

**Region:** The Understone Holds. **Doctrine:** Stone memory, underground engineering and intergenerational debts.

| Hero / ancestry | Fixed class | Role | Innate signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Dorna Stonewake** · Cairnkin | Earthshaper | Memory Mason | **Remember the Wall:** Trace a fallen wall's real footprint and raise a temporary spectral outline that slows crossing rather than blocking it. | Requires registered ruins, one outline, no siege restoration or exit sealing. |
| **Kellan Underhill** · Hearthborn | Stoneguard | Tunnel Warden | **Sound the Roof:** Strike a support point to reveal a nearby unstable ceiling pocket that can be triggered once after a clear warning. | Only authored pockets; no arbitrary cave-ins, friendly danger and visible escape area. |
| **Veyra Cairn** · Cairnkin | Earthshaper | Ancestral Listener | **The Stone Remembers:** Read the last hostile movement across a small stone patch and project its fading trail. | Local and historical information only; no prediction or through-wall targeting. |
| **Bram Deepwell** · Reedkin | Stoneguard | Cistern Keeper | **A Measured Flood:** Release a stored vessel into a small downhill wet lane with a delayed shallow push. | Finite carried water, follows slope and cannot flood an entire map. |
| **Sera Flintdeep** · Stormmarked | Earthshaper | Resonance Adept | **Strike the Note:** Place a resonance pin in stone; a timed second strike releases one short cone through exposed connected stone surfaces. | No travel through sealed walls; mistiming is weak and pin is destroyable. |
| **Orrik Bedrock** · Cairnkin | Stoneguard | Pillar Guard | **Shoulder the Vault:** Brace beneath a valid support or personal shield to absorb one displacement and spread a small remaining impulse nearby. | Ordinary damage remains; surrounding allies feel the impulse too and no repeated lock. |
| **Mira Basalt** · Emberkin | Earthshaper | Deep Forge Envoy | **Banked Heat:** Warm a stone token, then choose to carry it as a small chill ward or place it as a weak heat hazard. | Both modes share one finite heat budget; no stacking two copies. |
| **Toren Hushstone** · Gravebound | Earthshaper | Burial Archivist | **Keep the Names:** Seal one registered casualty's location so its eligible recovery timer pauses while the hero guards nearby. | Only existing recoverable casualties; moving away resumes time and no resurrection from ashes. |
| **Nyra Shale** · Veilkin | Stoneguard | Vein Scout | **Find the Seam:** Reveal a narrow walkable seam around a local obstacle and mark its legal route for a short time. | Does not create new passages or bypass locked doors; route remains contested. |
| **Garran Ore** · Cairnkin | Earthshaper | Weight Binder | **Set the Balance:** Place two weighted anchors; enemies pushing one away cause the other to gain a brief stronger brace. | Finite shared mass, no infinite force, anchors are destructible and stationary. |
| **Elin Hollow** · Hearthborn | Stoneguard | Lantern Delver | **A Light to Return To:** Place a lantern that marks a safe route already traversed; reaching it while pursued grants one short guard-ready state. | No healing, no unexplored-route reveal and one readiness trigger. |
| **Varric Cleft** · Gloamkin | Stoneguard | Chasm Hunter | **Across the Crack:** Leap across a small registered traversable crack and land with a directional strike if the endpoint is clear. | Cannot cross deep forbidden gaps, closed gates or occupied landings; long recovery. |
| **Nessa Hammer** · Cairnkin | Stoneguard | Debt Collector | **Return the Weight:** Catch a heavy guarded impact in a limited counterweight, then release it as a slow shove along the same axis. | Stored force decays; direction cannot freely retarget, ranged harassment bypasses it. |
| **Dain Quartz** · Stormmarked | Earthshaper | Crystal Surveyor | **Split the Beam:** Set a small crystal that bends one eligible light or storm ray along a preselected new direction. | Single use, reduced force and strict angle; cannot multiply projectiles. |
| **Lysa Thrum** · Reedkin | Earthshaper | Understream Guide | **Hear the Water:** Sense a nearby connected water channel and briefly reveal its current direction and moving threats touching it. | No knowledge outside connected local water; cannot target through stone. |
| **Corren Slate** · Hearthborn | Stoneguard | Pact Adjudicator | **The Unbroken Line:** Draw a short stone-dust boundary; deliberately holding it through one heavy tell grants a single protective pulse. | The hero must remain exposed inside; ordinary hits do not farm charges and the line is finite. |

## Twelve story heroes

These people have stronger authored narrative premises, not permission to break the one-protagonist rule. A campaign can select one, portray another as a rival/councillor, or omit them. Story selection requires that scenario's full quest, relationship and recovery support; a name in this table is not an unlock.

| Hero / faction / ancestry | Fixed class | Role | Signature and decision | Limit / counter |
| --- | --- | --- | --- | --- |
| **Avel Thorncrown** · The Thornweald Court · Veilkin | Druid | Exiled Regent | **An Empty Throne:** Place a conspicuous empty seat; enemies that voluntarily investigate it reveal their next intended target for a short window. | Does not compel bosses, creates no damage and fails under direct pressure. |
| **Soren Blackbell** · The Vesper Court · Gravebound | Death Knight | Bellworn Vault Warden | **The Bell Unstruck:** Hold a bell stroke in reserve; release it when an enemy crosses a marked line to interrupt one non-boss channel. | Reserve limits movement and expires; early release wastes the interrupt. |
| **Ivara Stormfall** · The Cloudspire Conclave · Stormmarked | Stormcaller | Fallen Weather-Seer | **The Broken Forecast:** Predict one of two visible storm lanes; the correct choice creates a calm strip and the wrong one leaves normal danger. | No hidden random coin flip; clues precede selection and only one strip forms. |
| **Merek Goldhorn** · The Emberhorn Dominion · Emberkin | Reaver | Dispossessed Heir | **A Crown Set Down:** Abandon a personal guard reserve into a visible crown marker that allies can defend to share its remaining capacity. | Hero loses the reserve, total capacity is conserved and marker can be broken. |
| **Ravna Moonless** · The Gloamfang Clans · Gloamkin | Moon Witch | Oath of Restraint | **The Hunger Refused:** Decline a marked finishing blow to bank one finite recovery opportunity after the foe disengages or surrenders. | No reward if allies kill it during the offer; eligible foes only and no repeat farming. |
| **Edrin Ninekeys** · The Ironroad Compact · Hearthborn | Thief | Road-Founder Pretender | **One Door Open:** Spend a carried contract token to unlock one registered optional combat route already discovered by the hero. | Cannot open story seals or escape from anywhere; finite authored tokens. |
| **Selka Stillmere** · The Reedbound League · Reedkin | Tidebinder | Keeper of Drowned Names | **A Name Above Water:** Raise one eligible submerged memory marker that reveals a local hazard's safe sequence and then fades. | Specific authored memories, no universal puzzle skip or combat immunity. |
| **Ardan Hearthless** · The Ashen Crown · Gravebound | Oathwarden | Uncrowned Protector | **No Throne but Shelter:** Declare one defended refuge object; sacrifices to personal damage create a bounded integrity ward on it. | Only registered destructible objectives; personal damage cost remains until ward expires. |
| **Dova Deepname** · The Deepcairn Pact · Cairnkin | Earthshaper | Last Archivist | **Debt of the Mountain:** Choose one existing defensive structure and absorb a portion of its next damage as delayed personal harm. | Conserves damage, cannot kill an absent hero silently and has a strict transfer cap. |
| **Neris Waylost** · The Ironroad Compact · Veilkin | Marshal | Map Without a Home | **A Road Remembered:** Record a short legal movement route and replay it as guided movement with one timed guard at its end. | Not teleportation, obstacles can stop replay and attacks still connect en route. |
| **Vaela Cindersong** · The Emberhorn Dominion · Stormmarked | Pyromancer | Ash-and-Rain Envoy | **Two Voices:** Alternate a fire note and a water note on the same visible zone to choose steam concealment or a weaker scalding pulse. | Order matters, each consumes real Focus, allies share concealment and no endless proc loop. |
| **Corvin Dawnless** · The Vesper Court · Hearthborn | Death Knight | Claimant of the Last Watch | **The Witness Remains:** Record one legitimate objective action; later repeat its support consequence at reduced strength while standing at the recorded location. | Cannot duplicate loot, capture, resurrection or progress; only an authored finite support effect. |

## Relationships, companies and fortifications

The requested Crusader Kings influence belongs to claims, council responsibilities, obligations, marriage/kinship where appropriate and relationships among people. Those systems create choices for the single protagonist; they never silently create a second playable heir or an army-collecting hero loop. Each hero needs personal relationships and plausible access to political life before its campaign is authored. This catalogue supplies roles and faction/ancestry differences, not completed family trees.

The requested Bannerlord influence belongs to company morale, named veterans, captives, mercenary terms and the cost of personal battlefield leadership. A signature that captures an eligible enemy must produce a real registered prisoner with custody, ransom/release and political consequences. A routed survivor remains alive; a capture flag cannot be both a corpse loot reward and a prisoner sale. No signature creates sellable soldiers or infinite recovery recruits.

The requested Stronghold Crusader influence belongs to real persistent defenses: gates, walls, towers, firing positions, breaches and supply. Hero engineering signatures can temporarily support or exploit those objects. They cannot reconstruct a captured town for free, seal every exit, place an unlimited combat base or reset a destroyed fortification by leaving the scene. Authored scenario geometry declares valid anchors and destructible objects.

## Acceptance and content pacing

This catalogue is a long-term production target. Implementation starts with a small coherent set of fully tested protagonists, then grows without relabelling the unimplemented remainder as complete. Each signature must have:

1. An exact action/effect definition with costs, readable timings, target rules, valid solo use and valid field use.
2. Meaningful rules tests: one successful use, a counter/failure, boundary conditions, pause/replay consistency and no reward or proc duplication.
3. An actual full 3D rig/weapon family, correct feet, attachments, telegraph, contact/release frame, recovery, hit reaction and defeat.
4. Native input and UI evidence, including rejected-action reasons, tooltip/gear interactions and a normal-speed encounter.
5. A legal progression path, acquisition-independent counters, relationships and a recovery route without compulsory endless grinding.
6. Measured balance against a reference solo contract and field objective, with no hero rendering companies irrelevant.

The roster deliberately records `implementationStatus: design_only` on every complete hero concept and `status: design_only` on every signature. Mara has a bounded playable base kit, but that is not acceptance of her full concept. Runtime identity validation and class permissions are implemented; the personal/racial/class-resource trait effects are not. Automated validation checks counts, uniqueness, required fields, faction membership and ancestry membership. Passing that structural validation does not prove fun, combat balance, animation quality or production completeness.
