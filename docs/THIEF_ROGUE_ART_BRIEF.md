# Thief and Rogue: model, motion and feedback brief

**Status: production design only, 22 October 2026.** This brief adds no runtime character, animation, ability or approved portrait and does not alter Mara v8. The canonical catalog currently has 20 classes, nine factions, eight ancestries and 156 champion concepts. Those counts are design scope, not acquired or accepted art. The player still chooses exactly one hero for the campaign.

The authority for class mechanics and IDs is [`data/class_catalog.json`](../data/class_catalog.json); both classes currently have empty `supportedSkills` lists. Individual identities and ancestries come from [`data/hero_roster.json`](../data/hero_roster.json). Art must follow those rules rather than advertise extra abilities.

## Distinct readable identities

| | Thief | Rogue |
|---|---|---|
| Core read | Prepared traveller who manipulates the environment and escapes | Precise close-range fighter who earns and spends an opening |
| Body silhouette | Short practical wool coat, clear elbows and knees, compact asymmetric tool belt, visible rolled cord and small pouches | Fitted layered jacket or light brigandine, readable forearm protection, two distinct short-blade/sheath positions and a narrow unobstructed waist |
| Equipment | Canonical short blades, sling or light crossbow; light armor and finite tools | Canonical paired daggers, short sword or hand crossbow; light/medium armor |
| Material direction | Weathered wool, linen, oiled leather, dull iron and occasional muted ochre cord | Dark russet, charcoal wool, worn leather, small steel edges and restrained copper fittings |
| Rest and movement | Hands can reach tools; watchful pauses and controlled low movement | A compact ready stance with clear blade separation, decisive foot placement and recoveries |
| Avoid | A sack-covered silhouette, a giant decorative key, permanent smoke, or a heavy combat stance that hides the tool role | A generic all-black hood that hides the individual, permanently glowing blades, or theatrical spins unrelated to a legal attack |

Both belong to the grounded Eastern European high-fantasy world: practical garments, weathered settlements and woods, distinct fantastic ancestry, and original folklore detailing. Faction fabric, fasteners and local craft can personalize the kit without replacing its class silhouette. The Thief's current catalog association is the Ironroad Compact; the Rogue's is the Vesper Court. Neither association makes an ancestry inherently criminal or hostile.

Portraits and ability illustrations use the exact approved manuscript sheet language: flat inked half-figures, crisp contours, restrained hatching, muted red/blue/green and plain warm parchment. No halos, saint framing or gold arches around the head. The tools/blades shown must correspond to the accepted model. Prefer an anatomically clear half-figure with few readable objects to a crowded arrangement of hands and equipment.

## Body, rig and modular equipment

Create one fully clothed, adult, reviewed class proof at a time. Shared humanoid skeleton conventions can reduce retarget work; an ancestry, sex or body-shape variant still requires its own proportions, garment fit and native-camera inspection. Mara's current 53-bone rig is a technical reference, not an approved universal body for every champion.

Reserve main hand, offhand, head, torso, hands, legs, feet, cloak/back and belt-tool attachment contracts. A held tool has a defined grip origin and orientation; it must be visibly attached during every contact action. Rogue paired blades require two actual grip solutions, sheath locations and independent hide/stow rules. Thief tool changes require a finite visible prop set: lock tool/key, compact trap/line, distraction/smoke container and escape-line fixture as supported by the implemented abilities. Do not show all tools permanently floating around the character.

| Ancestry | Specific fit/readability gate for either class |
|---|---|
| Hearthborn | Preserve an intentional range of adult faces and bodies; check actual hand size, sleeves and blade/tool grip on the selected body |
| Veilkin | Keep the accepted full-body, wingless silhouette and grounded garment contact; a glamour effect does not excuse missing feet or a floating tool |
| Gravebound | Retain coherent living-figure anatomy and individuality; pallor or bond markings must not erase hands, eyes or the class silhouette |
| Gloamkin | Treat any transformed form as a separate anatomy/equipment acceptance problem; human garments cannot simply stretch through claws, changed limbs or a muzzle |
| Emberkin | Make heat-related markings readable within believable skin/materials; light effects must not conceal deformation or make ordinary gear look fireproof |
| Reedkin | Check garment drape, wet-material response and ground contact; a water-touched identity does not imply permanent swimming motion or a water halo |
| Cairnkin | Approve actual proportions before retargeting; adjust reach and equipment fit instead of uniformly scaling a human rig and claiming the result complete |
| Stormmarked | Keep identity markings subordinate to face, hands and weapon readability; ambient sparks cannot stand in for authored class action |

These constraints do not prescribe a fixed body size, moral alignment, class or faction for an ancestry. They are production checks against the canonical descriptions.

## Required motion and ability promises

Both proofs need real skinned idle/ready, walk/run, start/stop/turn, hit/recovery, legal evasion and death motion, with the actual equipped kit. Add low movement only where supported by gameplay. A jump, vault, line escape or invisibility effect needs a corresponding traversal/concealment rule before the art advertises it. Existing Mara sword/cast clips are not automatically accepted as lock work, trap deployment or paired-dagger combat.

| Planned Thief ID | Authored action target | Icon and VFX must show |
|---|---|---|
| `lift_key` | Short deliberate reach to a registered target/socket, followed by a visible hand withdrawal | The actual key/tool action and eligible target; no promise of unrestricted theft or duplicate rewards |
| `disarm_trap` | Crouch/kneel, focused tool contact, a legible safe completion or interruption | The same trap mechanism used in the world; a quiet state change rather than an unrelated explosion |
| `false_sound` | A clear throw/place/release motion for the chosen distraction source | Its actual origin and audible/visible destination; the effect must not imply damage if the rule only distracts |
| `smoke_bomb` | Grip, committed release and recovery, with the container leaving the hand once | The actual thrown object, landing point and bounded smoke area/duration; smoke cannot conceal hit/target feedback indiscriminately |
| `tripwire` | A readable low placement sequence with supported endpoints and recovery | The real installed trap and trigger space; the icon cannot advertise a large snare if the world object is a narrow line |
| `escape_line` | A visible line connection to a valid authored anchor, movement and dismount | The real allowed route and anchor; no teleport through solid walls or an unsupported hovering rope |

| Planned Rogue ID | Authored action target | Icon and VFX must show |
|---|---|---|
| `backstab` | A compact committed strike from the earned approach, then a readable recovery | The same blade and direction of attack; target-specific contact height must work on the actual enemy anatomy |
| `venom_edge` | A deliberate application or other approved preparation action using the real blade/prop | Restrained poison treatment and bounded status feedback; no permanent fire trail or unrelated area burst |
| `hamstring` | A distinct low attack with sufficient floor and garment clearance | The low strike and its actual movement/status consequence, without promising a knockdown the rules do not grant |
| `throat_feint` | A readable feint/check that communicates a brief interruption opportunity | The actual feint/interrupt action and opening; a graphic wound illustration is unnecessary and would misrepresent a non-damaging feint |
| `sidestep` | A lateral weight transfer/evasion with planted entry and exit | The actual short displacement and finite evasion timing; not the current forward roll with a different label |
| `expose_weakness` | A deliberate read/mark or setup gesture defined with the combat designer | The actual eligible target and finite opening marker; no global reveal, permanent debuff or second unrelated attack |

These are acceptance targets, not final timing or balance specifications. Rules own legal targets, commitment, reach, damage, status duration and cooldown. Animation and effects must match their telegraph → active → recovery intervals. Authored root motion can guide gait but cannot move the collision root independently. Test the action against a valid target, a miss, an immune/ineligible target and interruption where allowed.

## A bounded first proof

Build one class kit and one representative action before expanding its full skill set. For Thief, prove tool handling and a real trap/disarm interaction. For Rogue, prove both blade grips, one precise attack and lateral evasion. Review normal-speed native footage plus diagnostic close views with hands, shoulders, feet, sheath clearance and actual effects visible. Then test legal transitions: move into action, repeated action, interruption, weapon/tool stow, death and save/load reconstruction.

Reject extra or fused digits, a tool floating outside the palm, intersecting blades, cloth passing through knees, unexplained foot sliding, missing contact, duplicated released props, and a card/effect that promises a different action. Require a source Blend, exported model/clip hashes, socket/prop manifest and accepted native captures for each proof. A successful import, one still or reused icon does not close those gates. No “flawless animation” claim is made until the particular implemented motions and transitions have survived this review and any observed defects have been reworked.

See [`ANIMATION_ACCEPTANCE_PLAN.md`](ANIMATION_ACCEPTANCE_PLAN.md) for the shared pipeline and [`NAMING_AND_ART_LOCK.md`](NAMING_AND_ART_LOCK.md) for the visual reference and campaign constraints.
