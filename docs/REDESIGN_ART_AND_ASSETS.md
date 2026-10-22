# DRACONIA — art, animation and asset production design

**Design revision:** 2026-10-22. **Scope:** the ground-up redesign, separate from the preserved first-campaign prototype. Counts below describe production requirements and estimates, not finished content. The old seven-tier, multi-army expansion is superseded. The current canon is nine factions with six base creature families and two promotion branches, plus a large hero-choice catalog; only one chosen hero is playable in a campaign.

## 1. The visual contract

Draconia follows exactly one chosen playable hero for an entire campaign, with Mara Veyne as the first adult female production basis, through a turn-based realm and real-time action encounters. The player directly moves and fights with her, prepares six of twenty-four active abilities, develops approximately forty-eight skill nodes, and commands six field companies with optional tactical pause. Town reserves and diplomacy support that expedition. Animation must communicate the hero's actions and company cooperation without requiring base construction during a fight.

The world and every visible world character are **fully 3D**. Heroes, ordinary troops, animals, monsters and bosses use real meshes and appropriate rigs. Sprite3D characters and camera-facing rendered creature sheets are unacceptable final substitutes. Generated still images belong in manuscript illustrations, concepts and material authoring inputs. A painted character image is not a rigged character asset.

The art direction combines naturalistic Carpathian landscapes and lived-in rural building work with secular medieval painted miniatures inside the interface. Preserve the ink, tempera and paper craftsmanship of manuscript art, but use grounded people and practical equipment: **no halos, saint framing, gold arches behind heads or religious icon treatment in portraits and UI illustrations**. The authoritative supplied style reference is `upload/54a74735-e880-4bce-890a-0a3d41193e62.png`, matching the original `manuscript-portraits.png`: flat inked half-figures, crisp outlines, restrained shading, muted red/blue/green and blank warm parchment. The later painterly busts and woodland backdrops are rejected style directions. The original sheet’s style is approved while its Mara Veyne hand anatomy remains rejected; correcting anatomy must preserve the approved illustration language. This framing decision is not a historical ban on every religious building type. Terrain has convincing scale, dark wet earth, broken rock, layered forest canopies and readable paths. Buildings show structure: timber frames support roofs, stone walls have thickness, doors have clearance, watermills connect to moving water, and workers can reach their stations. Faction identity comes from architecture, equipment, posture, ornament and social activity as well as color.

The palette uses aged wood, limestone, muted wool, linen, leather, tarnished iron and restrained copper. Magical light is locally legible and tied to an action. Persistent spectacle must not hide ground hazards, silhouettes or loot. The reference games inform grounded landscape, readable counters, company synergy, region discovery, build choices and folklore investigation; their proprietary art, logos, models and character designs are not source material for the asset library.

Mara Veyne needs a stable identity across her 3D face, equipment view, dialogue image and manuscript portrait. Her design is an adult traveler and commander with practical clothes, visible craft and credible equipment weight. The new portrait is head-and-shoulders, without hands or weapons in frame. Faction costumes use original Romanian-inspired treatment; no historical reconstruction claim should be attached without the corresponding research.

### Readability before ornament

At the normal action camera, the player must identify Mara Veyne, hostile threats, company role, attack anticipation and a safe route without zooming. A promotion changes a meaningful silhouette element, weapon or stance; a recolor alone is insufficient. Counter roles use redundant cues: polearm reach, shield mass, bow stance, cavalry body size, caster gesture and a clear company symbol. Unit identity must remain understandable in grayscale and when faction colors are similar.

At close inspection, anatomy and materials must withstand scrutiny. Decorative complexity never excuses an extra hand, broken weapon grip or foot that passes through the ground. Every production asset and panel follows **define → build → rules test → actual engine inspection → accept or rework**. Passing import, file count or automated tests does not grant visual acceptance.

## 2. Nine factions, capitals and regional art kits

Display names now follow the invented, English-readable naming canon. The playable hero is **Mara Veyne**; legacy `ileana` file/ID names may remain for compatibility. Faction, capital and regional names below follow `NAMING_AND_ART_LOCK.md`, which remains the naming authority. Creature display vocabulary includes Gloamfangs, Veilkin, Gravewights, Tempest Sages and Crownwyrms.

The canonical creature catalog is nine factions with six base unit families each. Each family has two mutually exclusive promoted variants. This gives **54 base definitions + 108 promoted definitions = 162 recruitable definitions**. Add **24 neutral types, including eight major bosses**, for **186 creature visual definitions**. The separate identity catalog targets **156 hero design concepts**: 144 standard choices (sixteen per faction) plus twelve story characters, with exactly **one chosen playable hero for the whole campaign**. Those concepts are not 156 downloaded models or 156 unique skeletons. Plan modular body bases across eight ancestries, then review each identity’s silhouette, equipment and portrait independently. Mara Veyne is the first rig proof; no other hero art is being claimed complete.

| Faction | Capital | Region | Proposed architecture and material identity | Motion and ambient identity |
| --- | --- | --- | --- | --- |
| The Ashen Crown | Dawnreach | The Ashen March | Limewashed stone, dark timber galleries, red-brown wool, woven sun ornament; settled farmland surrounding a defended court | Disciplined shield turns and banner signals; carts, grain handling, watch changes and smithing |
| The Thornweald Court | Briarhollow | The Thornweald | Timber shelters built around living trees, pale linen, carved grove stones and controlled leaf ornament | Wingless Veilkin move through deliberate dance and uncanny gliding transitions; canopy wind, moths, herb preparation and ritual gestures |
| The Cloudspire Conclave | Stormcairn | The Cloudspires | Mountain masonry, steep roofs, exposed copper instruments and weathered blue-gray cloth | Measured casting preparation, coordinated storm releases; ropes, rain chains, weather instruments and cloud shadows |
| The Vesper Court | Duskharrow | The Mourning Vale | Dense stone courts, bell towers, burial textiles, dark iron and aged wine-red accents | Unsettling pauses and deliberate recovery; bells, candle flames, hanging cloth and funerary work rather than constant flashing magic |
| The Gloamfang Clans | Fangrest | The Moonscar Peaks | Rough timber, mountain stone, hide shelters, bone fasteners and narrow hunting paths | Tracking, scenting, short explosive lunges and readable transformations; patrols, smoking racks, dogs and wind over exposed ridges |
| The Emberhorn Dominion | Cindervault | The Copper Wastes | Heavy stone foundations, worked copper, furnace light, blackened timber and mineral surfaces | Weighty strikes with visible commitment; bellows, hammer work, cranes, sparks and cooling metal |
| The Reedbound League | Reedhaven | The Mirrorwater Delta | Stilt houses, reed roofs, plank walks, water-dark timber and pale river cloth | Amphibious transitions and flowing attacks; rowing, nets, mills, current, ripples and birds |
| The Ironroad Compact | Crossmere | The Ninefold Road | Dense timber markets, layered awnings, roadside shrines, travel gear and restrained imported ornament | Quick hands, feints and clear contract gestures; loading stalls, counting goods, repairing equipment and caravan departures |
| The Deepcairn Pact | Stonewake | The Understone Holds | Subterranean stone halls and exposed mountain works, engineered timber braces and weathered metal; preserve original silhouettes | Weighty labor and defended passages; hoists, hauling, ventilation, lamps and guarded gates |

These are proposed visual treatments for the canonical names. The authoritative creature definitions now live in `data/creature_roster.json` and `docs/CREATURE_ROSTER.md`; hero identity concepts live in `data/hero_roster.json`. Those catalogs are design-only content, not evidence of completed art. Freeze a silhouette board for each faction before producing its full set, and compare all nine boards together so shared materials do not erase identity.

## 3. Counted production inventory

An asset **definition**, **mesh**, **rig**, **animation clip**, **assembled scene** and **illustration** are different accounting units. A promoted spearman may reuse a body and rig but still requires an identifiable equipment assembly, portrait, effects, clips, audio and tested action bindings. A town assembled from modules is not a new unique mesh for every building state.

### Characters and presentation

| Deliverable | Derivation | Production target | Accounting rule |
| --- | --- | ---: | --- |
| Hero identity concepts | Confirmed selection-catalog target | 156 | One playable choice per campaign; every offered identity needs an approved silhouette, equipment view, portrait and animations before being called playable |
| Hero ancestry bases | Modular production target | 8 | Reusable topology/rig families where anatomy permits; proportions and clothing deformation still need review |
| First hero compatibility basis | Mara Veyne, one adult female | 1 | Current acquisition/proof task only; face, braid, outfit, equipment sockets and collision contract |
| Base recruitable visual families | 9 factions × 6 families | 54 | Distinct base body/equipment assemblies; compatible families may share anatomy and topology |
| Promotion appearance kits | 54 families × 2 branches | 108 | Two role-readable variants per family; mutually exclusive in game, both must exist as assets |
| Recruitable visual definitions | 54 + 108 | 162 | Complete scene/material/animation bindings and a stable content ID for each |
| Ordinary neutral creatures | 24 neutrals − 8 bosses | 16 | Not faction recolors counted a second time without an actual new definition |
| Major neutral bosses | Eight major boss arcs | 8 | Each requires its own silhouette, attack language, arena interactions and phase states |
| Combat creature cards | 162 recruits + 24 neutrals | 186 | Individually readable manuscript miniatures; reuse composition only when the variant distinction remains obvious |
| First hero active-ability symbols | Current ability target | 24 | Each has prepared, unavailable, active and cooldown UI states; these are states, not 96 new illustrations |
| First hero skill-node symbols | Approximate current progression target | 48 | May share a framed symbol grammar; final count follows the skill catalog |
| Faction heraldry and capital cards | 9 factions × one of each | 9 + 9 | Heraldry must read on banners, map ownership and company cards |
| Regional entry illustrations | 9 regional kits | 9 | Separate framing from capital cards; no fake in-engine screenshot |

The earlier twelve-family rig estimate is provisional. The canonical catalog now requires compatible humanoid profiles; small and large living-wood bipeds; canine, badger and bear quadrupeds; horses, deer and rams; tortoises; full-body wingless Veilkin and wraiths; winged quadruped griffins and Crownwyrms; wingless drakes; serpents; and articulated construct engines. No arachnid family is currently planned. Confirm a named rig, proportions, gait and equipment clearance for every family before freezing the exact shared-rig count. Similar topology does not prove that a bear, badger and wolf can share the same motion, or that a wingless drake can reuse a flying dragon unchanged. Specialist boss extensions remain separate work. None of these planned rig profiles is counted as an acquired asset.

For Mara Veyne's equipment, the confirmed design target is **twelve armor sets** (two per progression path), each with **five visible armor pieces**, giving **sixty set-piece definitions**, plus **twenty-four legendary items**. Two-piece and four-piece bonuses are rules/UI states, not extra armor models. Reserve modular head, torso, hands, legs and feet slots, plus main-hand, off-hand and cloak attachment points. A legendary item may occupy an existing slot, but its promised visual identity must appear on the actual 3D hero. Item rolls and affixes can share geometry; a different numeric roll is not a new model. The hero's twenty-four abilities do not require twenty-four unrelated body rigs.

Each armor module inherits the accepted body proportions, seam boundaries, vertex-weight conventions and material scale. Keep hidden-body masks per slot combination so a cuirass does not expose a cut-out neck when a hood is removed. Fit headwear around the face and braid; attach cloak, scabbard and weapon sockets to documented bones. Hands must grip the weapon instead of letting it float near the palm. Review all twelve complete sets and supported mixed-slot combinations through idle, full stride, dodge, attack, casting, hit and death. Reject skin poking through cloth, overlapping rigid plates, exposed seam gaps, hidden hands and weapons intersecting the face or ground. The initial compatibility proof contains one linen/wool outfit and a sword; it does not claim that the complete equipment catalog exists.

### Towns and regions

| Deliverable | Derivation | Initial production estimate | Reuse and state policy |
| --- | --- | ---: | --- |
| Shared rural construction modules | One common kit | 48 modules | Foundations, floors, walls, roofs, stairs, galleries, fences and doors |
| Faction construction modules | 9 styles × 24 modules | 216 modules | Distinct rooflines, walls, gates, shopfronts and ornaments; reuse common structural standards |
| Capital landmarks | 9 capitals | 9 landmarks | A recognizable silhouette from approach and in the capital UI |
| Recruitment-site assemblies | 9 factions × 6 unit families | 54 sites | Base and two promotion appearances give 162 assembled visual states; not 162 standalone sculpted buildings |
| Civic/production assemblies | 9 factions × 8 functional sites | 72 sites | Proposed stations for food, timber, stone/metal, trade, storage, craft, worship/research and defense; exact gameplay buildings remain a design dependency |
| Workstation interaction sets | One per production site | 72 setups | Actor placement, tool, input pile, output pile, action loop and blocked/idle state |
| Landmark locations | 9 regional kits × 3 signature sites | 27 locations | Establish regional discovery and folklore identity |
| Lair/contract location assemblies | 9 regional kits × 6 layouts | 54 layouts | Shared cave/ruin/forest modules with authored entrances, clues and combat circulation |
| Regional dressing objects | 9 regional kits × 12 distinctive props | 108 props | Local shrines, markers, fences, tools and ritual remains |
| Common world props | Shared kit | 96 props | Containers, carts, tables, doors, camp gear, tools and road furniture |
| Trees | 12 species/forms × 3 shapes | 36 meshes | Young/mature/broken variants where appropriate; season is a material/state layer |
| Shrubs and understory | 10 families × 2 shapes | 20 meshes | Include clear traversable edges and cover silhouettes |
| Ground-cover clusters | Shared and regional mix | 16 cluster types | Grass, fern, reeds, leaf litter and small plants with controlled overdraw |
| Rock and cliff forms | Shared geological kit | 12 primary forms | Regional materials and scale variants; authored walkable silhouettes |
| Terrain material families | 9 regional kits × 4 key surfaces | 36 material sets | Albedo/normal/roughness/height where justified; blends do not count as unique source photographs |
| Investigation clue types | 9 regional kits × 10 local types | 90 clues | Tracks, broken equipment, ritual traces and remains; visual form must match quest meaning |
| Regional atmosphere configurations | 9 regional kits × day/night × calm/adverse | 36 configurations | Reuse controlled wind, lighting, precipitation and audio components |

Town counts describe art capacity, not an assertion that seventy-two different production rules are already designed. A capital can display a small subset of buildings at a time. Each building family should have construction, active, idle/blocked and damaged presentations assembled from shared pieces and local effects. Smoke must stop or change when the production state says it should; workers must not hammer forever beside a blocked workshop while the UI reports inactivity.

Spell, technology, item, contract and named-NPC catalogs are not all fixed yet. Use explicit formulas: one distinct icon per rule identity; one effect recipe per readable action outcome; one scene/card per authored contract beat that needs illustration. Start the VFX budget at **24 hero ability recipes**, plus an estimated **32 shared effect modules** and **8 boss effect packages**. These are not eighty complete spells. A missile, impact and status aura are reusable parts of a single action. Do not recycle the old seventy-two-spell total as settled redesign scope.

### Persistent 3D town-building contract

Every capital has a dedicated persistent 3D town scene. A purchase creates its actual building on a named authored plot, and an upgrade visibly changes that building. The visual state is derived from saved town data, so leaving the screen, loading a save or switching towns cannot reset it. A purchase animation alone is insufficient.

Author faction-specific landmarks and plot silhouettes around a controlled camera composition. Important buildings remain selectable and identifiable behind walls, trees and later upgrades. Provide focus views and occluder handling instead of letting a large keep permanently hide a recruitment plot. Test the fully built town as well as its starting state.

Each purchased structure needs a readable construction reveal: foundations or scaffold state, workers/material activity where appropriate, and a completed state. If rules complete construction instantly, keep that reveal brief and purely presentational; if rules use a timer, show actual saved progress. Save/reload must restore the correct state and must not charge resources or replay completion rewards again.

Completed services show their role: a working forge has correctly positioned hammer/bellows action, a mill rotates with a visible water/wind relationship, a market has handled goods, and a recruitment yard shows training. Disabled, blocked or damaged services change their activity. Promotion branches visibly change the relevant dwelling or training area, with distinct equipment/ornament rather than only a label in the menu.

Acceptance requires buying, upgrading, leaving, revisiting, saving and loading the same town in the actual engine; comparing the saved building IDs with visible plot instances; checking every plot from the normal camera; and checking that construction/service animation never hides the purchase result. All nine capital styles eventually need this gate. The existing fort/house/prop kit can prove state persistence and camera layout but is not nine completed faction art sets.

### Noble cards and functional castle defenses

Council and noble presentation uses the same approved flat inked parchment style as the user’s original sheet. Every named person offered in a council, succession, loyalty or diplomacy panel needs an identifiable portrait and compact heraldic/name treatment. Define living, unavailable, appointed and deceased presentation states without redrawing the entire face. Count one portrait per identity, with reuse across panels; the final named-noble count is a central content-catalog dependency. The 156 hero concepts require their own approved identity portraits, with choice portraits for the playable selection catalog, but a council card does not make its subject a second playable hero.

Castle defenses need functional 3D art, not decorative wall silhouettes. Budget an initial eight reusable defense module roles per faction—wall section, corner, gatehouse, tower, stair/access, protected firing position, moat/bridge transition and repair/construction state—giving seventy-two style-role assemblies across nine factions. This is an estimate to validate against the rules. Author clear projectile origins, defender access, obstruction/collision volumes, damaged states and visible repairs. Gate and bridge animation must match path blocking; towers must aim and fire from actual openings; defenders must not stand inside parapets. Test the normal camera, crowded assaults, save/reload and changed wall connectivity. Add siege-device rigs only for defined gameplay roles, with crew/tool contact and reload/impact timing; do not claim a full siege game from an animated gate.

## 4. Animation matrix and workload

Every combatant must have genuine motion appropriate to its anatomy. A static body translated across the ground does not meet locomotion acceptance. A looping idle is not evidence that attack, hit and death work. Rig reuse reduces authoring cost; every body, armor set and promoted variant still needs deformation review.

| Subject/state family | Minimum motion coverage | Important transitions and review |
| --- | --- | --- |
| Hero neutral locomotion | Idle variants, walk, run, start, stop, turn in place, directional dodge | Immediate response to click movement; stop without skating; stable camera-relative targeting |
| Hero melee | Weapon-ready stance, basic strikes, heavy/special attack, recover, guard/parry where designed | Anticipation → active contact → recovery; hands remain on the grip and feet support the strike |
| Hero ranged | Nock/load, draw/aim, release, reload, recover | Arrow leaves the correct socket at the action's release; bow string and fingers align; no reused pistol pose masquerading as a bow |
| Hero magic | Cast start, hold/channel, release, interrupted cast, recover | All twenty-four abilities bind to explicit action timelines; six prepared slots do not imply six total clips |
| Hero reactions | Light hit, heavy stagger, knockdown/get-up if designed, death, contextual victory | Facing and displacement remain consistent with the rules; no accidental invulnerability from animation length |
| Hero exploration | Interact, inspect clue, collect, open, kneel, talk, mount/dismount if mounts enter scope | Hand contacts and reach are aligned to actual world props; scale changes cannot break the animation |
| Humanoid companies | Idle, walk/run, turn, attack, ranged/cast for role, hit, stagger, death, rout, rally, celebrate | Company members face targets individually without synchronized robot loops; formation and collision stay authoritative |
| Quadrupeds and beasts | Idle/sniff, walk, run, turn, attack, threat preparation, hit, death | Correct gait, planted paws/hooves, spine range and grounded attack recovery |
| Flying units | Ground/perch idle if relevant, takeoff, sustained flight, bank, attack, hit, landing, death/fall | No abrupt altitude jump; wingless spirits use intentionally different motion and effects |
| Serpents/dragons | Idle, body locomotion, turn, attacks, breath/cast preparation, hit, death | Body-chain deformation, terrain clearance, multiple heads and effect sockets require bespoke work |
| Bosses | Complete ordinary states plus each phase, telegraph, interrupt, special attack, transition and defeat | Each major threat can be read from the real camera before it hits; phase visuals correspond to actual state |
| Town inhabitants | Walk, carry, turn, greet, talk, sit/stand, inspect, rest; assigned work loops | Carrying objects use attachments and hand contact; people have destinations and do not walk through work surfaces |

A baseline combat body requires at least ten common state bindings: two idle variants, walk, run, two turn directions, two hit reactions and two death variants. Add the actual attack, cast, ranged, route/rally and special states for its role. Across 186 creature definitions that is **at least 1,860 common state bindings**, not 1,860 independently authored clips.

An initial clip-authoring budget is approximately **612 curated or authored creature/first-hero master clips**: twelve rig families × twenty common clips (240), fifty-four base families × two signatures (108), one hundred eight promotions × one branch-specific action or alternate (108), sixteen ordinary neutrals × two signatures (32), eight bosses × eight signature/phase clips (64), and sixty additional hero-specific clips beyond shared motions (60). This is a production estimate, not a source download count. A promotion that genuinely shares its action may reuse a clip after review; a complex boss may require more. Recalculate after the roster and combat design are frozen.

The first fully authored hero should initially budget around one hundred usable clips/state variations, including the shared core. Distinguish a newly authored clip from a retargeted copy and from a state binding. Neither resaving the same motion under dozens of names nor counting a T-pose as gameplay animation demonstrates progress.

### Town, landscape and UI motion

| System | Required behavior | Reduced-cost/reduced-motion behavior |
| --- | --- | --- |
| Production work | Repeating labor cycles with input/output props, tool contact, breaks and a visible stopped state | Reduce distant actor update rate; retain meaningful production status |
| Smoke, steam, fire | Local emitters tied to ovens, forges, damage and weather; restrained sparks | Fewer particles and softer flicker; no rapid full-screen lighting pulses |
| Water | River current, mill rotation, shoreline ripples, waterfall motion and boat wake where used | Simpler flow materials; keep current direction and hazard boundaries legible |
| Banners, cloth, foliage | Wind direction shared across cloth and canopy, restrained secondary motion | Lower amplitude and update rate; no forced camera movement |
| Ambient life | Birds, livestock, insects and distant workers with local schedules | Fewer ambient actors; do not remove gameplay-critical enemies or clues |
| Construction | Observable material stages, worker access, partial structure and completion transition | Stage swaps can replace complex sequences at distance, with the same final state |
| UI panels | Brief opening/closing, hover/focus feedback, selected company emphasis and clear cooldown progress | Instant transitions or short fades; no parchment wobble, zoom pulse or decorative looping around reading text |
| Damage/ability feedback | Small impact response, readable hit effect and optional camera impulse | Disable shake, blur and flashes; preserve the attack anticipation and impact information |

Everything that is alive, active or affected by wind/water needs appropriate motion. Stone walls and resting tools do not need arbitrary movement. The world should feel inhabited, not uniformly oscillate. Reduced motion is a saved, visible setting that suppresses ornamental movement without changing timings, difficulty or information access.

## 5. Action timing, animation events and root motion

The authoritative combat action owns its timeline, costs, target validation, collision and hit result. An action defines anticipation, active window and recovery, along with cancel rules, projectile release and any movement allowance. Animation is chosen and timed to that contract. A call-method track may request sound, dust or a visible weapon trail; it must not be the only source of damage application. Otherwise skipped frames, tactical pause, animation blending or an offscreen actor can change the rules.

Use stable action/event IDs and idempotent presentation events such as `foot_left`, `foot_right`, `weapon_contact`, `projectile_release`, `cast_release` and `recover_complete`. A hit is emitted once by the simulation and consumed once by presentation. Seeking, accelerating an animation or replaying a clip cannot deal damage twice. Pausing freezes the simulation and action progress consistently while allowing menus and selection inspection.

For the first implementation, locomotion is in place and the character controller owns translation. Match playback rate to actual speed within an authored safe range. Root-motion clips can later drive an allowed movement request, but the controller still resolves collision, terrain and authoritative position. A blocked lunge must not tunnel through a wall or make the mesh detach from its collider. Godot exposes root-motion position/rotation separately from the visual track; the chosen integration needs a specific test, not an assumption that enabling a property solves collision. [S8]

Attack-speed modifiers must be bounded by readable anticipation and reliable events. If a build exceeds the animation's acceptable rate, use a deliberately authored faster attack or alter its cadence; do not compress every strike into unreadable frames. Validate clips with weapon sockets, shield thickness, cloak motion and all equipment variants. A motion that looks correct on an unarmed mannequin may fail with a long spear or rigid cuirass.

## 6. Concrete sources and present acquisition

The strongest coherent route identified is a shared, naturalistic human body and garment pipeline, a curated neutral humanoid motion library, and a consistent PBR environment library. No single verified free pack supplies the complete Carpathian roster, original architecture and all required creature animation.

| Source | Verified terms and useful content | Decision |
| --- | --- | --- |
| Quaternius Universal Animation Library Standard | Creator-hosted CC0 humanoid motions, with Godot GLB and FBX versions. The free upload describes forty-five animation entries; the larger 120+ catalog is a different offering. [S1–S3] | **Downloaded once into staging.** Reuse motions after retargeting and review. The yellow mannequin is technical preview geometry, not final character art. |
| MakeHuman / MPFB core and system assets | Official core assets use CC0; tool code has separate GPL/AGPL terms. Official system inventory lists female body/proxy, braid, eyes, clothes and footwear. [S12–S14] | Verified source route for one fully clothed adult female compatibility basis. A model is not accepted until the staged export and camera review pass. |
| MakeHuman suits02, selected entries | Official inventory individually marks RehmanPolanski's tunic, pants and boots CC0. The pack contains other unrelated costumes that are not appropriate to Draconia. [S15] | Use only the three named garments as a fit/rig foundation, then author an original regional treatment. Do not adopt the full themed pack indiscriminately. |
| Poly Haven | CC0 models, materials and HDRIs; existing fort, rocks, barrel and chest provide reusable environment sources. [S4, S5] | Naturalistic material/source library, not a complete animated medieval town. Some existing assets need architectural adaptation and performance review. |
| ambientCG | Official asset license is CC0, including downloadable material files. [S6] | Candidate for future consistent ground/plaster/wood material families; no additional pack acquired in this task. |
| br-n518 werewolf | CC0 model with seven stated motions; current converted model has a real skinned body. [S11] | Interim nonhuman pipeline reference. Its low-detail appearance and incomplete action vocabulary do not satisfy final Vârcolac production. |
| Daniel Andersson houses and Yughues forest | Existing credited CC0 sources, retained with local conversion evidence. [S17, S18] | Reuse candidates for background structures/forest after style and LOD acceptance, not evidence that nine capitals are built. |
| Current Flare-derived sprites | Existing local provenance identifies CC BY-SA 3.0 artwork and adaptations. [L1] | Historical prototype only. Expansion of the sprite roster does not advance the fully 3D character requirement. |

### Staged animation pack: measured inventory

Directory: `assets/staging/quaternius-universal-animation-library-standard-2025-04-16/`.

The creator-hosted ZIP is **14,541,205 bytes**, SHA-256 `18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2`. Its Godot GLB is **6,671,104 bytes**, with one skinned mesh and **53 joints**. Static inspection found **46 animation records: 45 excluding the T-pose**. Native Godot 4.7.2 import exposed all forty-six, and forty-two changed bone poses between samples. The T-pose and three firearm aiming poses were static at those samples. [L2]

After excluding the T-pose, six firearm entries and driving, **38 candidate records** remain; two are root-motion alternates, leaving **36 distinct candidate actions**. Candidate baseline clips include idle, walk, jog/sprint, sword attack, simple casting, hit and death. The package does not contain complete bow, crossbow, shield/spear, horse or creature libraries. Native import strips `_Loop` from source clip names; the inventory records both names. No production-character retarget is implied by the source-rig test.

The retained snapshot comes from a creator submission dated 2025-04-16; no semantic version is embedded in the archive. Current creator pages describe later rig and timing revisions. Preserve the exact hash and audit timing/rest pose instead of silently treating this copy as the latest release. Original archive, creator notice, full CC0 text, download records, clip inventory and native QA report are retained. Staging stays outside runtime resource use.

## 7. Mara Veyne basis and practical character pipeline

The first character gate is one adult female body, fully clothed in tunic, trousers and boots, with a restrained braid and original regional garment treatment. Set an explicit adult age and practical proportions; do not infer a particular person's face or reproduce a commercial-game heroine. The initial result is a compatibility and silhouette basis, not production-ready Mara Veyne.

The selected legal source path is MPFB's CC0 core/system body, eyes and braid plus the individually listed CC0 tunic/pants/boots. MPFB's tool license is separate from exported asset rights. Its documented workflow creates a rig before adding clothing so garments receive rigging; its export-copy process can remove helpers and hidden body geometry while retaining the editable source. [S12–S16] User-contributed assets outside these selected entries need their own license check.

### Acquired and reviewed first basis

The bounded acquisition is now concrete. Official **MPFB 2.0.18**, pinned to commit `d0a32e57a7f915cb2f2b95410e2117648c7bbb7e`, builds an explicitly adult female body with a 53-bone game rig. Thirty selected CC0 source members provide eyes, brows, lashes, a braid, and RehmanPolanski's tunic, trousers and boots. Individual ZIP members were retrieved from the official archives with CRC and SHA-256 evidence; no full archive hash is claimed for archives not downloaded in full. Tool code remains GPL-3.0-or-later, while these body/accessory/garment assets remain CC0. The editable source, unchanged downloaded inputs, scripts and license evidence are in `assets/staging/ileana-mpfb-proof/`.

The promoted **v8 is accepted only for development integration proof**. Two independent reviews accepted v6's actual Godot grip, idle, attack, running, death and action-camera images. The right hand encloses the hilt, clothing and boots stay attached, and no extra or detached limb was found in the inspected poses. V7 appended six genuine motion clips; v8 changes only the attack's right-wrist rotation to clear both supported blades from the ground. The stable path is `assets/models/mara/mara.glb`. It uses metres, +Y up, +Z forward, approximately 1.63 m standing height and feet offset zero. The rig retains its legacy internal name `IleanaRig`; the display identity is Mara Veyne. Its 39,262 triangles and fifteen material surfaces are a proof inventory, not approval against the final combat LOD/material budget.

Twelve native clips now exist: `idle`, `walk`, `run`, `attack`, `hit`, `death`, `combat_idle`, `cast_start`, `cast_hold`, `cast_release`, `cast_end` and `dodge`. They are retargeted from the staged Quaternius source, with floor correction and a fitted right-hand grip. The casting and forward-roll motions are genuine separate actions. Native clip lengths, exact promoted hash and weapon visibility requirements live in `assets/models/mara/manifest.json`. Damage, dodge distance, interruption and cooldown remain controller/rules responsibilities. The roll is in-place animation and cannot decide collision or invulnerability.

The held sword must be stowed or hidden for casting/rolling, and released or hidden at death, because those source motions were authored unarmed. A matching loose sword mesh supports a controller-owned drop. The sustained `combat_idle` stance supports a visible sword-ready guard state; it is not an authored shield-block impact. An absent impact reaction must remain an explicit open requirement rather than being called complete.

Exactly two earned visual modules now have a native integration proof: **Vowkeeper**, a project-authored 1,088-triangle sword on `hand_r`, and **Bellworn Cowl**, a project-authored 5,288-triangle fitted hood/capelet using the same 53-bone skeleton. The item manifest maps `vowkeeper_sword` and `bellwarden_hood` to their scene, attachment, base-mesh hiding and clip-clearance data. The hood preserves the face and braid. The attack correction changes one rotation channel only; the other eleven clips and all other attack channels remain unchanged.

The cowl's native 96 Hz clearance envelope is sampled at the actual authored seek time. It changes only a visual child's Y relative to its stored baseline, never the actor root, collision, rules position or ground markers. In the actual dungeon adapter, all 25 roll controller samples and 74 fall samples kept the cowl above ground; minimum observed clearance was 6.78 mm and 6.01 mm respectively. Eighteen focused native checks also verified no accumulated offset after repeated updates, unchanged rules state, correct weapon hiding, exactly one loose sword on death, idle baseline restoration and curve removal when the hood is unequipped. The original captures and report are retained in `assets/staging/ileana-mpfb-proof/evidence/runtime-equipment/`. This proves the two registered modules, not every gear combination or a complete armor set.

**Production blockers remain:** flat proof cloth materials, faceted/ragged cuff and collar mask boundaries, a plain starter blade, static braid, unfinished face/identity refinement, full armor-set switching and mixing, no authored low LOD and too many material surfaces. Native stills do not establish movement pacing; analytic gait estimates and recorded native playback are evidence inputs, and continuous controller movement still requires foot-slide review at its chosen speed. This is one acquired body and rig proof, not fulfillment of the 156-character identity catalog or 186-creature catalog.

### Reproducible pipeline

1. Pin the tool version and download sources. Record source URLs, hashes, embedded notices and selected member paths. Preserve the raw inputs and work on a separate collection.
2. Construct the adult base and add the rig before fitting garments. Keep shoulders, elbows, wrists, hips, knees and ankles anatomically credible. Dress the entire figure before presentation renders.
3. Fit garments to the body, then inspect under a deep knee bend, raised arms and wide stride. Correct skin weights and clearance. Do not hide a bad elbow by making a sleeve enormously thick.
4. Author a coherent original treatment: linen underlayer, dark red-brown wool tunic, woven trim, worn leather boots, restrained metal fasteners and practical travel layers. Keep embroidery scale and fabric roughness consistent. Later armor modules must preserve the same underlying identity.
5. Create a clean export copy: bake shape and visibility masks deliberately, remove helper/control geometry, normalize transforms and retain only useful deform bones. Preserve the editable rig in the source collection. Check all mirror modifiers and both sides of the body before export.
6. Export GLB with named animation actions and explicit material inputs. Inspect the exported mesh, not only Blender's working scene. The Khronos Blender exporter is the reference glTF path. [S10]
7. Retarget a small acceptance set first: idle, walk, run, attack, hit and death. Map bone names and rest poses deliberately. Godot's BoneMap/SkeletonProfileHumanoid path addresses both; shared names alone do not prove compatibility. [S7]
8. Fit feet and hands after retarget. Check foot sliding, knee inversion, wrist twist, shoulder collapse, blade alignment, braid/cloak intersections and death-ground contact. Produce actual engine captures from normal and inspection cameras.
9. Accept the rig schema only after this single body works. Then test a short, tall and heavy company body with the same animation library before multiplying the roster.

For nonhuman rigs, use a common event and state interface with separate anatomical profiles. A canine gait, bird wing cycle and serpent motion must be authored for their anatomy. Share materials and effects where useful, but preserve creature weight and silhouette. Multiheaded creatures need independently reviewed neck chains and breath origins.

## 8. Godot integration and performance budgets

Use inherited character scenes containing the imported mesh/skeleton, collision/controller root, attachments and AnimationTree. Keep animation definitions separate from gameplay state and preserve stable asset IDs. Godot's AnimationTree controls transitions and blending over an AnimationPlayer library; it is not the source of the imported clips. [S9]

The production contract is meters, Y-up, a documented +Z character-facing convention at the asset boundary, ground at the feet, and no unexplained scale on the exported skeleton. The game may rotate a visual child to match its controller convention. Each rig has named sockets for hands, weapons, shield, back, head, projectile origin and relevant creature attacks. Collision shapes are authored independently of visual detail.

The following are **initial budgets to profile**, not measured performance promises:

| Asset/runtime class | Initial target | Acceptance concern |
| --- | --- | --- |
| Hero | 25–40k triangles at inspection, 10–18k at combat distance; 60–80 deform bones; 4 weighted influences/vertex; ≤4 visible material surfaces | Face/hands and garment folds survive LOD; weapon grips and motion remain correct |
| Ordinary human company member | 8–15k / 3–6k / 0.8–2k triangle LODs; 40–60 deform bones; ≤2 body material surfaces plus shared weapon | Several companies can animate simultaneously; gear variants do not multiply material count uncontrolled |
| Large creature | 12–30k near mesh; 40–80 bones; 2–3 surfaces | Preserve limbs, horns, wings and telegraphs under simplification |
| Boss | 35–70k near mesh; up to 120 deform bones only when anatomy warrants it; ≤4 primary surfaces | Budget phases, additional heads and effect overdraw together; no unmeasured exception |
| Character textures | 2K hero/major-creature sets, 1K shared troop sets; 4K only after camera evidence | Mipmaps and packed material channels; texture memory measured in the actual renderer |
| Company representation | Initially 3–8 visible 3D soldiers per ordinary company, bounded separately from simulation count | Six player companies plus opponents must remain readable; a numeral carries exact strength |
| Combat stress scene | Hero + approximately 96 animated visible bodies, a boss, dense vegetation and simultaneous effects | Profile frame time, animation cost, draw calls, skinning and transparency; never assume the software renderer predicts consumer GPU performance |
| Town stress scene | Visible work sites with bounded active workers; distant inhabitants update less often | Stop animation/controllers when irrelevant while preserving simulation and production state |
| Renderer target | Begin with 60 fps at 1080p on a declared midrange test PC; explicit 30 fps lower preset | Name hardware and captures when testing; no claim of this target being reached yet |

Use shared materials and texture atlases where they preserve readability. Split static vegetation into spatial MultiMesh groups so an entire forest is not one culling unit. MultiMesh batching is suitable for repeated foliage and props; it is not a complete solution for hundreds of independently skinned actors. [S19] Use character-specific animation distance policies and profile them separately.

Automatic LOD needs visual review. Godot generates mesh LOD for imported scenes, but its documentation notes possible artifacts, including on skinned meshes. [S20] The prototype already demonstrated a real failure: aggressive tree simplification removed the foliage silhouette. Do not accept lower triangle counts if trees become reeds or a hand loses its fingers. Use authored LODs for anatomy and critical silhouettes, alpha cutout for leaf cards where appropriate, limited transparent layers and controlled shadow distance.

A scene budget should initially aim below roughly 500 visible draw submissions and 1.5 million visible triangles at the action camera, then be revised from actual profiling. These are engineering starting points, not universal Godot limits. Effects, fill rate, animation evaluation and CPU simulation can bottleneck before triangle count. Keep forward/compatibility renderer differences explicit and test every renderer actually shipped.

## 9. Current art status and replacement obligations

| Existing asset group | Current evidence | Redesign disposition |
| --- | --- | --- |
| Nine Flare-based troop sheets and the rendered wolf sheet | Genuine frame sequences and local license/source manifests | Interim prototype; replace every world-character use with fully rigged 3D production assets |
| Current br-n518 werewolf GLB | Real skeleton, seven clips, prior native pose renders; 892 triangles | Useful import/state reference, not final creature-quality approval |
| Existing 13 runtime model entries | Fort/rocks/trees/houses/props/werewolf with retained sources and hashes | Candidate environment inventory; count individual modules/meshes before claiming catalog coverage |
| Generated manuscript sheets | Existing prompts/hashes and current independent inspection | Three anatomy/contact cells rejected; the icon grid contract rejected; see IMAGE_QA_REJECTIONS.md |
| Generated terrain/material images | Actual local files and prompts | Texture inputs requiring seam, scale, PBR and real-lighting review; not complete environments |
| Cinzel and EB Garamond | Local OFL fonts with pinned provenance | Retain if final native panel legibility passes; typography alone does not establish finished UI |
| Two audio files | Local licensed ambience and music | Small starting library; no claim of regional score, complete action audio or creature coverage |
| Quaternius Standard motion pack | Source-rig import/playback inventory in staging | Verified motion source only; retarget and action timing still require acceptance |
| Mara Veyne MPFB body/outfit/rig proof | Official selected CC0 sources, 53-bone rig, twelve retargeted clips; two independent v6 reviews and v8 native attack-clearance review | Accepted for development integration only; garment edges/materials, secondary motion, full armor catalog, final LOD and continuous controller gait remain open |
| Vowkeeper and Bellworn Cowl | Two project-authored visible item modules; actual native adapter/equipping, roll/fall clearance and weapon-policy verification | Two-item integration proof closed; final surface treatment and all other equipment remain work |

All current gameplay screenshots are prototype evidence. Generated art must never be presented as a screenshot of functionality that does not exist. The historical checkpoint can remain intact while the redesign rejects its art for future use.

## 10. Provenance, staging and promotion rules

Every external asset record needs a stable ID, original title, author, primary source URL, retrieval time, exact archive/member hash, license identifier and full notice, selected source files, transformations, tool versions and final exported hashes. Record whether a file is original, a derivative, a generated image or a technical conversion. Keep code-tool licenses separate from exported graphics licenses.

For generated images, preserve the prompt, source output, any supplied references, dimensions, alpha policy, hash and actual rejection/acceptance record. Acceptance is per image/cell, not per successful generation batch. Anatomy failures require a simpler composition or correction; cropping a third hand out of a critical interaction is not a substitute for a valid character pose.

Staging files do not automatically enter the game. The current staged animation directory is ignored by the editor, but future export presets must also explicitly exclude `assets/staging/*` because broad non-resource include filters can defeat an assumed boundary. Promote only reviewed GLB/material/AnimationLibrary resources and their provenance. Raw archives, tool code, unused FBX variants and intermediate renders belong in editable source/evidence, not the runtime PCK.

Original Draconia code may retain its MIT grant. That grant does not relicense CC0 assets, CC BY-SA-derived prototype art, OFL fonts or engine/tool components. Maintain a complete asset credit file and license folder in every distribution, and track modified assets separately. A license is necessary for reuse but does not by itself prove an asset fits the art direction or that a purported third-party upload owns the material.

## 11. Definition, tests and actual inspection gates

| Gate | Concrete artifact and review | Reject/rework examples |
| --- | --- | --- |
| Define | Asset brief, role, anatomy, silhouette, camera scale, required states, performance budget, provenance | Unspecified final use; a supposed melee model with no grip or attack requirement |
| Build | Editable source, exported mesh/materials, named clips, collision/socket map | Missing textures, control bones in runtime, half a mirrored body, unexplained transforms |
| Rules test | Action events, interruption, pause/resume, collision, death, save/reload and cooldown semantics | Animation seek applies damage twice; a canceled cast releases a projectile; root motion crosses a wall |
| Anatomy inspection | Front/back/side view and normal native camera; hands, feet, face, body proportions and equipment | Extra digits/limbs, detached wrist, inverted knee, floating weapon, foot inside ground |
| Motion inspection | Actual native idle/walk/run/attack/cast/hit/death captures, with equipment and terrain | Foot sliding, cloth through thighs, snapping shoulders, unreadable anticipation, death pose above ground |
| UI inspection | Real panels at supported sizes, localization, keyboard focus and reduced motion | Clipped icons, illegible labels, a neighboring atlas cell, scrolling text hidden by ornament |
| Performance inspection | Fixed recorded stress scene on named hardware/renderer, timings and resource counts | A frame-time claim from a static screenshot; GPU cost inferred only from triangle count |
| Accept or rework | Reviewer, exact resource hash, scene, observations and disposition | “PNG exists,” “45 clips found,” or a large automated test total presented as visual approval |

The first accepted gate should contain **one clothed hero, two contrasting humanoid companies, one creature, one visible production site and one small native action encounter**. That slice proves the reusable pipeline and visual standard. It does not replace the full catalog. After acceptance, expand by complete faction families and regional kits; do not mass-produce 162 creature appearances or 156 hero concepts around an unproven rig.

The full release art gate requires all 186 creature definitions and every offered hero identity to have their applicable animations, readable effects, approved portraits/cards and tested rule bindings; all nine regional kits and capitals must have their planned material/architecture/activity coverage. Manual play and visual review remain necessary alongside automated checks. Missing art stays visibly listed as missing, without relabeling an interim asset as production complete.

## 12. Source and evidence register

Primary web sources were checked on 2026-10-22. Research establishes the cited license/API/workflow facts; the design budgets and visual decisions above are Draconia production proposals.

- **S1:** Quaternius creator-hosted Standard upload and stated 45-animation free edition: https://opengameart.org/content/universal-animation-library
- **S2:** Official Universal Animation Library product and CC0 statement: https://quaternius.com/packs/universalanimationlibrary.html
- **S3:** Creator's current version history and edition distinction: https://quaternius.itch.io/universal-animation-library
- **S4:** Poly Haven asset license: https://polyhaven.com/license
- **S5:** Rico Cilliers, Modular Fort 01 primary asset page: https://polyhaven.com/a/modular_fort_01
- **S6:** ambientCG official asset license: https://docs.ambientcg.com/license/
- **S7:** Godot, Retargeting 3D Skeletons: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- **S8:** Godot AnimationMixer root-motion API: https://docs.godotengine.org/en/stable/classes/class_animationmixer.html
- **S9:** Godot AnimationTree transitions/blending: https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- **S10:** Official Khronos Blender glTF importer/exporter and round-trip validation workflow: https://github.com/KhronosGroup/glTF-Blender-IO
- **S11:** br-n518, Werewolf source and stated animation list: https://opengameart.org/content/werewolf-0
- **S12:** MakeHuman/MPFB split code and asset licenses: https://static.makehumancommunity.org/about/license.html
- **S13:** Official system asset inventory with per-entry licenses: https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html
- **S14:** MPFB getting started, rig before clothing: https://static.makehumancommunity.org/mpfb/docs/getting_started.html
- **S15:** Official suits02 inventory, selected RehmanPolanski garments: https://static.makehumancommunity.org/assets/assetpacks/suits02.html
- **S16:** MPFB export-copy workflow: https://static.makehumancommunity.org/mpfb/docs/exporting/export_copy.html
- **S17:** Daniel Andersson house source/license: https://opengameart.org/content/medieval-house-pack
- **S18:** Yughues forest source/license: https://opengameart.org/content/freebies-mundo-commissions
- **S19:** Godot MultiMesh batching and culling: https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html
- **S20:** Godot mesh LOD and artifact caveats: https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html
- **L1:** Existing local source facts: `ASSET_CREDITS.md`, `assets/models/manifest.json`, `assets/models/qa-report.json`, `assets/animated/source/flare-provenance.json`, `assets/audio/manifest.json`.
- **L2:** Measured new source inventory: `assets/staging/quaternius-universal-animation-library-standard-2025-04-16/manifest.json`, `clip-inventory.json`, `godot-qa-report.json` and the unchanged original ZIP.
- **L3:** Independent image rejections, exact source hashes and inspection limits: `docs/IMAGE_QA_REJECTIONS.md`.
