# The Blackbriar March — implemented design

## Core promise

Play one persistent traveller in a dangerous, readable fantasy borderland.
Travel and combat happen in the same third-person world. Completing a task changes
the character: new equipment, a level, an attribute choice, or the next chapter.
A friend can join the same private realm. The implementation provides one
introductory quest chain; a complete MMO remains a larger production goal.

## The playable loop

**Thornwatch → task → travel → fight or gather → collect personal spoils →
return → guaranteed reward → improve the hero.**

The road teaches melee range and targeting. The eastern wood teaches navigation
and avoiding unnecessary fights. The Hollow King tests telegraph recognition,
rolling, healing, and resource use. The final reward provides a completion point.
Rewards do not depend on spending money or deliberately obscured odds.

## One coherent class

The Highlander Vanguard uses a sword, resolve, and protective warding. Swordfall
is deliberate single-target damage; Mooncleave rewards placing multiple foes in
a forward arc. Iron Vow trades resource and a long cooldown for recovery and
protection. Wayfarer's Step supplies movement and brief evasion. Rowan Draught
consumes inventory. UI and combat rules share the same ability definitions.

There is currently one character/race/class combination. A larger roster should
follow explicit class identities and authored motions, not arbitrary collections
of abilities or renamed copies of this kit.

## Progression

Levels cap at 20 and grant two attribute points. Might increases weapon power;
Vitality increases health and some armor; Spirit increases resolve and recovery.
Equipment adds explicit power, armor, and vitality. Art never determines stats.

The seven items occupy weapon, chest, or ring slots. Quest rewards are guaranteed.
Ordinary enemies produce currency; briarbound foes and the boss produce defined
gear. Repeated owned equipment converts to currency. Random affixes and a large
visual armor catalog are not implemented in this build.

## Realms

Solo and hosted modes execute the same simulation. The host validates bounded
movement/action intentions, range, resources, cooldowns, ownership, prerequisites,
and reward state. Damage occurs once at the authoritative impact time; an animation
cannot apply additional damage.

Enemy attacks lock an impact position during the visible windup. Moving out or
rolling matters. Eligible nearby contributors receive kill credit and personal
loot. Disconnected players cannot collect future awards through a stale peer ID.

Profiles are host-owned and saved atomically. Clients retain private reconnect
keys. Restarting a realm resets encounters while preserving progression. Public
accounts, hosting, persistent world services, sharding, interest management,
operations, and MMO load tests remain separate future systems.

## Art and motion contract

Mara's accepted model, sword, source motions, and PBR dependencies are unchanged.
The real model also appears in the portrait and character sheet. The new world
uses a perspective camera behind her with orbit, zoom, shared movement collision,
and camera collision. Terrain, layout, landmarks, interface, and presentation are
authored for this third-person mode.

Source roll, cast, and death motions were unarmed: hide the sword for those states,
then restore it. Attack contact matches the authoritative timeline. Ground motion
matches source foot speed. Physical jumping exists, but no authored jump clip was
added to the retained animation set.

Native reviews caught overbright terrain, noisy sampling, geometric mountains,
UI overlap, focus recovery, and solid-prop collision mismatches. Development NPC
and creature art, visual equipment, final deformation/secondary motion, content
variety, and target hardware profiling remain explicit production work.
