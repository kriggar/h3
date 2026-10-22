# Draconia — nine-town art direction

Status: **production design**, revised 22 October 2026. No profile in this document is a completed or visually accepted capital. Dawnreach has a persistent native prototype; the other eight capital compositions are proposed work. The companion `data/town_visual_profiles.json` carries the same status and canonical identifiers.

## What the town reference establishes

The supplied Stronghold town image is a quality and composition reference: an immediately recognizable landscape, a low panoramic camera, a dominant landmark, dense supporting buildings, readable functional sites and convincing foreground/middle/background depth. Draconia must achieve those relationships with original fully 3D geography and architecture. A recolored common town, a painted backdrop, or a handful of isolated buildings on a flat lawn does not satisfy the brief. The historical screenshot is not a game asset.

Each capital must pass a clay-render comparison before material polish: remove color and labels, then verify that its skyline, terrain, roof grammar and public-space plan still identify it. Streets, retaining walls, water, foundations and access must connect the settlement into one place. Place ordinary homes and work yards around the functional buildings; leave deliberate squares and routes, not arbitrary empty plots.

## Mandatory building and card identity

The original painted card is the architectural reference. Build its visible design in Blender: silhouette, proportions, roofline, entrances, wall structure, ornament, heraldry, props and material palette. The resulting GLB/PackedScene is the actual purchased town building. A simpler model does not earn approval by replacing the painting with a render of itself. The original card remains visible in the interface, including during hover and press. Source Blend/GLB hashes, export settings, the locked card region and a side-by-side reference comparison bind the reviewed revision.

The retained original atlas is `assets/ui/manuscript/buildings.png`, 1774×887 pixels, SHA-256 `f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be`. Its four-by-two reading order is Granary, Training Yard, Market, Smithy, Oath Hall, Palisade, Wharf and Water Gate. Preserve fractional 443.5-pixel cells. On 22 October 2026 the user explicitly rejected the reverse approach of changing those paintings to fit existing Blender work. The previous model set and rendered cards are historical candidates. New source modules and staged reconstructions are documented in [CARD_RECONSTRUCTION.md](CARD_RECONSTRUCTION.md). Other manuscript art remains governed by the approved flat inked reference.

## Shared scene and upgrade contract

Use metres, +Y up, +Z building front and a ground-centred footprint origin. Every plot has a stable ID, a terrain-aligned foundation, a door/service approach, selectable volume and a maximum completed/upgraded envelope. Store buildings and upgrades in rules state; reconstruct the exact accepted scene after save/load. Normal buildings complete immediately on a legal purchase, subject to the persistent one-build-per-town-per-day rule. A short scaffold/assembly reveal is presentation only and cannot delay the benefit or restart on load. Reduced motion replaces the reveal with a brief fade or immediate appearance.

A base structure and an upgrade must share a recognizable core while adding real geometry: another store bay, defended gallery, waterwheel, forge flue, loading crane or courtyard extension. A color change, tooltip or larger scale does not count. Unit promotion exclusivity does not automatically imply that the building branches are mutually exclusive; the rules catalog controls that distinction. The wharf and water gate currently share Dawnreach’s riverside slot and remain mutually exclusive under the existing rules.

Animation follows the building state: occupied workshops work, blocked production idles, unbuilt plots do not emit smoke, and night lights follow the watch. Plan grounded work cycles with actual tools, visible load transfers and believable hand/foot contact. Wind drives cloth, trees and smoke coherently. Water has a visible flow direction, supported wheels and boat clearance. Ambient life never mutates resources or substitutes for a production rule. Do not claim workers, boats or creatures complete until their native motion is inspected.

## Nine distinct compositions

### Dawnreach — The Ashen Crown

**Identity:** A red-roofed river town climbs three irregular stone terraces to a timber-galleried court.

**Landscape and landmark:** A wooded Carpathian ridge ends above a river bend. Exposed limestone anchors retaining walls; orchards and narrow fields soften the approach. Dawnreach High Court: a broad timber hall between unequal stone towers, with a sheltered public stair below. The hall roof, not an oversized spire, dominates.

**Composition:** Foreground: The river landing and outer gate frame the bottom corners; a cart track curves past clustered workshops. Middle distance: Dense but permeable red-roofed lanes surround a triangular market and grain court. Purchased buildings occupy the near edge of the relevant district. Background: The high court and crest eyrie rise above a wooded saddle. Distant ridges and river continuation remain real terrain.

**Circulation and open space:** A bent processional lane connects water, market and high court through two visible stairs; side alleys serve housing. Keep the market triangle and the long stair to the hall legible. Avoid an empty rectangular lawn.

**Districts:** River landing and defensive water approach; Grain and market court; Craft lane and training yard; Upper oath court and household; Orchard edge and animal yards.

**Materials:** weathered oak framing; limewashed infill; irregular limestone courses; muted red fired-clay roof tiles; undyed linen and faded russet cloth.

**Visible life:** grain sacks carried to the raised store; smith bellows, hammer and short sparks; shoppers stopping beneath awnings; watch changes on the upper walk; banners and laundry responding to one wind field; small ferry crossing behind the wharf.

**Upgrade integration:** A granary gains a real side store and covered loading platform; a training yard gains a roofed equipment gallery; a gate gains a walkable overhead chamber. Upgrades retain the original entrance and public route.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Hearth Muster — Hearthguard | A shield-lined muster court beneath a timber gallery |
| Border Lodge — Briarbow Hunters | A forest-edge lodge with a covered bow range |
| Redmane Stable — Redmane Riders | A stable court with a ramp, tack racks and an exercise paddock |
| Bell Court — Bellwardens | A secular bell court with medicine workbenches and covered seating |
| Hound Yard — Oathhounds | A shaded kennel courtyard with broad runs and water troughs |
| Crest Eyrie — Dawncrest Griffins | A stone ledge with a sheltered perch and a large clear flight approach |

**Reuse candidates:** fort, house_1, house_2, house_3, house_4, pine, broadleaf, rocks, barrel. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** eight matched civic building scenes in the current construction pass; high-court roof/gallery and asymmetrical gateway; terraced terrain, retaining-wall joins and public stairs; covered market stalls, grain handling and smith tools; creature recruitment courts and eyrie.

**Current boundary:** Dawnreach has one persistent development town with all eight reviewed card-directed Blender reconstructions installed. Flat foundation cores, entrance approaches, terrain-material roads, retaining-wall openings and the two exclusive riverside installations have been corrected around the exact models. The wider high court, ambient housing, vegetation, terrain and water style remain unfinished. Final production-path construction/save/reload and export reports remain separate gates; no finished-capital acceptance is implied.

### Briarhollow — The Thornweald Court

**Identity:** An inhabited forest hollow arranged around open glades and enormous root buttresses, with low crescent roofs below an unbroken living canopy.

**Landscape and landmark:** A damp wooded basin with a shallow stream, mossy outcrops and mature broadleaf trees. The town follows natural clearings rather than felling a square. The Oldgrowth Seat spans the roots of three ancient trees; its inhabited timber terraces have stairs, railings and visibly supported floors.

**Composition:** Foreground: A low root bridge and herb beds lead into the glade; fallen trunks and working gardens create scale. Middle distance: Small clustered shelters sit around three distinct clearings, with the Measure Ring deliberately open and free of traffic. Background: The Oldgrowth Seat frames a pale break in the canopy; the Wyrm Hollow disappears into a wooded ridge.

**Circulation and open space:** A figure-eight footpath serves the stream crossing, nursery and communal ring without walking through the ritual space. Preserve the central dance ring and the gaps beneath roots; foliage may frame but cannot conceal selectable roofs.

**Districts:** Stream and herb gardens; Nursery and craft clearings; Measure Ring and guest shelters; Oldgrowth terraces; Outer glades and creature hollows.

**Materials:** split chestnut and living root; aged bark shingles; pale woven linen; moss-dark stone; small copper or bone fasteners.

**Visible life:** gardeners sorting herbs; slow water and hanging seed gourds; a wingless Veilkin rehearsal with clear foot contact; wind passing through canopy at varied phases; controlled lantern insects away from labels; woodworkers repairing supported walkways.

**Upgrade integration:** A bower becomes a supported arcaded shelter; nursery beds expand along an existing root wall; a communal ring gains carved boundary stones while its floor stays open.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Root Nursery — Thornlings | Root beds and low propagating frames |
| Briar Bower — Briarwitches | An herb bower with drying bundles and a preparation table |
| Hollow Glade — Hollowstags | A quiet deer glade with a wide living arch |
| Measure Ring — Veilkin Envoys | A flat circular dance floor ringed by low stones |
| Oldgrowth Seat — Mosswardens | A buttressed old-growth platform with large grounded access |
| Wyrm Hollow — Duskwood Wyrms | A long low wooded hollow with a clear creature exit |

**Reuse candidates:** broadleaf, pine, rocks, barrel. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** ancient landmark trees and structural root meshes; crescent shingle roofs and supported timber platforms; root bridges and herb beds; dance-floor boundary kit; six creature-specific recruitment spaces.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Stormcairn — The Cloudspire Conclave

**Identity:** A sparse chain of mountain schools bridges separate crags around a great copper weather instrument; large sky gaps define the silhouette.

**Landscape and landmark:** A high pass with cliffs, scree shelves, hanging cloud and a distant snow line. Architecture grips actual ledges with deep foundations. The Storm Dial, a low circular observatory crowned by a tilted copper ring and grounded stone counterweights, stands on the central crag.

**Composition:** Foreground: A steep arrival stair and sheltered pack yard establish the climb; ropes and low walls protect the exposed edge. Middle distance: Compact slate-roofed schools occupy three ledges connected by visibly engineered timber-and-stone bridges. Background: The Crown Aerie occupies a separate peak against open sky; a long mountain chain gives depth without filling every gap.

**Circulation and open space:** A zigzag stair climbs to the school court, then divides into a weather terrace and a high aerie route. Keep open sky between the main masses and a clear flying approach; never bridge every crag into a continuous wall.

**Districts:** Pass arrival and garrison; Sheltered school court; Instrument and casting terraces; Animal crag; Crown Aerie.

**Materials:** cold gray mountain stone; dark split slate; oxidized copper instruments; weather-blackened timber; blue-gray wool windbreaks.

**Visible life:** weather vanes and weighted wind ropes; scholars aligning instruments; rook keepers moving between lofts; cloud shadows crossing cliff faces; controlled rain chains and runoff; a distant creature landing after a readable approach.

**Upgrade integration:** The school adds a real instrument wing and storm shutters; a terrace gains a supported bridge and a second measuring station; new mass must not close the skyline gaps.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Pass Garrison — Galeguard | A low pass guardhouse and sheltered drill apron |
| Rook Loft — Rookcallers | A multi-level timber loft with real bird perches |
| Windwalk Terrace — Windstriders | A narrow training terrace with rope anchors |
| Storm School — Tempest Sages | A court around a copper weather ring |
| Horn Crag — Cloudhorn Beasts | A broad crag shelter and sure-footed animal ramp |
| Crown Aerie — Crownwyrms | A large supported landing ledge with strong wind clearance |

**Reuse candidates:** rocks, fort, pine. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** stepped cliff foundations and bridges; slate-roofed school kit; weather dial and copper instruments; exposed ledge safety details; aerie and horn-beast access.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Duskharrow — The Vesper Court

**Identity:** A dense stone city fills a narrow ravine beneath two unequal bell towers, with stacked galleries and a long reflecting canal.

**Landscape and landmark:** An enclosed valley with black water, bare orchard slopes and layered limestone cliffs. Mist stays low enough to preserve door and bridge readability. The Court of Last Bells joins a tall narrow bell tower to a broad inhabited hall across a suspended covered gallery.

**Composition:** Foreground: A low canal quay and stone bridge frame the entrance; worn steps descend to water without blocking the main route. Middle distance: Narrow courtyards and tall slate roofs stack along both banks. The Crimson Hall faces a quiet long square. Background: The unequal bell towers and a terraced memorial garden close the ravine; only a thin band of sky remains.

**Circulation and open space:** A canal-side route connects quay, hall and foundry; short stairs reach upper courts and crypt doors. The reflecting canal and long hall square are the main open shapes; avoid scattering graves uniformly across the scene.

**Districts:** Canal and quay; Vigil courts and memorial terraces; Crimson household; Mourning galleries; Bell foundry and heavy access court.

**Materials:** weathered pale limestone; dark slate; black iron grilles; old bronze bells; deep wine-red wool and faded mourning linen.

**Visible life:** slow bell mechanisms and ropes; custodians carrying lamps; cloth moving in protected courts; boatmen crossing still water; brief foundry pours behind screened openings; crows settling on roof ridges.

**Upgrade integration:** A crypt court opens an additional masonry bay; the foundry adds a hoist and heavier casting floor; a hall gains a side gallery while its original arch remains readable.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Vigil Crypt — Gravewights | A recessed vigil court with a broad crypt entrance |
| Ossuary Range — Bonefletchers | A roofed stone archery range |
| Pall Stable — Pall Riders | A paved stable court and low vaulted shelter |
| Mourning Gallery — Veilmourners | An inhabited gallery with a coherent accessible floor |
| Crimson Hall — Bloodbound Courtiers | A narrow-bladed guard court before a wine-dark hall |
| Great Bell Foundry — Bell Colossi | A bronze bell workshop with a heavy outward-facing assembly apron |

**Reuse candidates:** fort, rocks, barrel. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** ravine canal walls and bridges; tall narrow stone-house and gallery kit; two unequal bell towers with moving mechanisms; foundry and heavy colossus assembly area; memorial terraces and creature entrances.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Fangrest — The Gloamfang Clans

**Identity:** A low, spread-out alpine settlement circles a great hearth beneath broken stone teeth; long log roofs follow the bowl of the valley.

**Landscape and landmark:** A cold mountain bowl with pine edges, snow remnants, streams and sheltered rock overhangs. Paths follow contour lines and animal trails. The Split-Hearth Hall is two offset longhouses joined around an open stone fire court, with a tall carved signal mast rather than a castle spire.

**Composition:** Foreground: Hunting racks, timber sledges and a stream crossing frame the approach, leaving a broad route for large animals. Middle distance: Low houses form an incomplete ring around the pack hearth; kennels and a moon court sit on separate lateral terraces. Background: The Ancient Winter Den opens beneath a rock shelf, with the split peaks behind it and no urban skyline.

**Circulation and open space:** A broad crescent track links hunting yards, hearth and dens; narrow human shortcuts cross between terraces. The open hearth court and large-animal paths remain broad; heavy creatures never squeeze through human doorways.

**Districts:** Hunting arrival and smoke racks; Communal hearth ring; Moon court; Pine-edge dens; Winter den and animal trail.

**Materials:** dark horizontal logs; split timber shingles; dry-laid granite; felt and repaired hide windbreaks; small iron and bone fittings.

**Visible life:** smoke rising in sheltered plumes; meat and hide preparation; human and wolf patrols sharing routes; snow shake from pine branches; quiet circle gestures; sledges and water carrying.

**Upgrade integration:** The pack hall extends with a real second log bay; dens gain stone thresholds and shelter depth; a training court adds racks and a covered exercise edge.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Pack Hearth — Packwardens | A communal fire court and weapon racks |
| Moon Lodge — Moontrackers | A low hunter lodge with a sheltered bow lane |
| Rime Den — Rimewolves | A pine-edge run with stone dens and troughs |
| Moon Circle — Moonbinders | A quiet open circle with covered observers |
| Gloam Court — Gloamfangs | A broad longhouse court sized for digitigrade bodies |
| Ancient Winter Den — Whitepelt Ancients | A deep overhang shelter and large turning apron |

**Reuse candidates:** pine, rocks, barrel, broadleaf. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** horizontal-log hall kit; racked hides, smoke shelters and sledges; snow-edge terrain treatments; large creature den openings; split-hearth landmark and carved signal mast.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Cindervault — The Emberhorn Dominion

**Identity:** A heavy terraced copper city steps into a mineral basin, with a broad horn-roofed palace above furnaces and cooling channels.

**Landscape and landmark:** An ochre and charcoal escarpment cut by engineered terraces, ore yards and clear cooling water. The ground is mineral rather than a uniform lava field. The Horn Palace: massive stepped masonry with two swept copper roof ridges and a wide shaded giant-scale entrance.

**Composition:** Foreground: Ore carts, cooling troughs and a guarded bridge occupy the lower work terrace. Middle distance: Furnace courts and workers shelters interlock in a dense industrial band, with tall chimneys grouped instead of evenly repeated. Background: The palace spans the upper rim; the Deep Furnace opens into the cliff and throws restrained light from within.

**Circulation and open space:** A broad haul road climbs two switchbacks from the ore yard to palace and deep furnace; narrower maintenance bridges cross water channels. Keep a clear haul route and large creature assembly courts; fire and smoke cannot cover the production entrances.

**Districts:** Ore and cart yard; Cooling-water works; Worker and copper range quarter; Augur and forge courts; Palace rim and deep furnace.

**Materials:** dark cut basalt; ochre plaster; hammered copper with varied patina; blackened timber; iron grilles and soot.

**Visible life:** bellows driven through visible linkages; furnace shutters opening on short cycles; workers moving ore carts; cooling steam at water contact; hammers and restrained sparks; hounds resting beside warm walls.

**Upgrade integration:** A furnace adds a real flue and cooling run; a copper range gains a reinforced gallery; palace expansions use heavy buttresses rather than floating ornament.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Cinder Yard — Cinderlings | A compact repair yard with tool benches |
| Copper Range — Copperthrowers | A broad throwing court with reinforced targets |
| Coal Kennel — Furnace Hounds | A low stone coal kennel with controlled heat |
| Augur Furnace — Ember Augurs | A furnace court with measuring bowls and screened fire |
| Horn Palace — Emberhorns | A giant-scale copper-roofed palace apron |
| Deep Furnace — Furnace Drakes | A deep basalt portal with a broad drake turning space |

**Reuse candidates:** rocks, fort, barrel. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** copper roof and giant-scale masonry kit; furnaces, flues and bellows; cooling channels and cart tracks; horn-palace landmark; drake entrance and heavy doors.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Reedhaven — The Reedbound League

**Identity:** A horizontal town of reed roofs and narrow islands stretches across braided water around a low mirrored court.

**Landscape and landmark:** A shallow delta with open channels, reed beds, muddy banks and distant flat water. Piles and pontoons visibly carry every building. The Mirror Court is a low crescent hall on two islands joined by an open water court, with a broad reed roof and reflective basin.

**Composition:** Foreground: Fishing boats, mooring piles and a plank landing establish scale; open water fills a major part of the frame. Middle distance: Stilt houses form two staggered island bands joined by angled boardwalks. Working docks face different channels. Background: The Mirror Court and a long channel lead toward reed islands and low distant woodland, preserving a flat horizon.

**Circulation and open space:** A loop of boardwalks links the dry islands; boats follow separate channels with clear bridge headroom. Water channels are the town squares. Do not fill them with decorative platforms or constant fog.

**Districts:** Fishing and trade landings; Dry dwelling islands; Glasspool and reed nursery; Mirror Court; Large creature pools and delta exit.

**Materials:** water-dark timber piles; pale reed thatch; woven reed screens; river stone; weathered copper and undyed sailcloth.

**Visible life:** boats rowing along registered channels; nets raised from real supports; waterwheel and mill linkage; current around piles; reeds bending with shared wind; quiet ripples from aquatic creatures.

**Upgrade integration:** A dock gains additional piles, a real crane and warehouse bay; a pool expands behind a visible retaining edge; new boardwalks preserve navigation channels.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Reed Muster — Reedwardens | A dry spear muster platform |
| Mire Range — Mirebow Stalkers | A reed-screened bow lane |
| Glasspool — Glassfin Sprites | A shallow clear pool with low observation boards |
| Mirror Court — Mirror Oracles | A basin court linked to the crescent hall |
| Bogback Pool — Bogback Turtles | A broad sloped turtle pool with dry basking bank |
| Delta Deep — Deltawyrms | A deep channel mouth with a clear creature approach |

**Reuse candidates:** barrel, rocks, broadleaf, timber_shack. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** reed roofs and stilt foundations; boardwalk joints and working mooring kit; boats, nets and waterwheel; mirror-court landmark; tortoise ramps and large delta channel.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Crossmere — The Ironroad Compact

**Identity:** A dense bridge-and-market town converges on a tall guild counting house, with different roof bands marking nine incoming roads.

**Landscape and landmark:** A broad river crossing where raised roads meet on firm terraces. Warehouses, hedged fields and caravan yards fill the edges. The Ninefold Exchange rises above a covered bridge: a narrow timber counting tower over a wide masonry guild hall and open loading arcade.

**Composition:** Foreground: A caravan yard, scales and a gatehouse frame the arrival road; the bridge crosses diagonally through the scene. Middle distance: Dense workshops and market lanes fan around a central exchange square. Roof pitch and frontage width vary by district. Background: The counting tower, a crane yard and the road forks lead toward farms and a distant wooded ridge.

**Circulation and open space:** Three visible approach roads meet the exchange; back lanes serve goods so carts do not pass through every public stall. Leave the exchange square and cart-turning courts usable. Density comes from roofs and working edges, not obstructed roads.

**Districts:** Caravan arrival and stable yard; Exchange square; Guild and bolt-work lane; Writ quarter; Engine assembly and bridge loading.

**Materials:** repaired timber framing; brick and river-stone lower floors; mixed red tile and gray shingle roofs; faded striped canvas; iron fittings and wax-seal colors.

**Visible life:** carts queueing at the scale; porters passing parcels along loading bays; clerks stamping documents; a working bridge crane; shop shutters and awning adjustments; engine crews moving heavy components.

**Upgrade integration:** A guild hall gains a second working bay and visible hoist; the exchange gains a covered loading arcade; engine works expand into a reserved assembly apron.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Guild Muster — Guildblades | A guild militia court behind a public arcade |
| Bolt Hall — Boltwardens | A crossbow hall with covered benches and a range |
| Wayfarer Stable — Roadstriders | A caravan stable with a large turning yard |
| Writ House — Writbinders | A public writ house with seal desks |
| Ironback Yard — Ironback Brutes | A reinforced labor court with oversize harness storage |
| Waystone Works — Waystone Engines | A timber-and-stone assembly hall with outward-facing heavy doors |

**Reuse candidates:** house_1, house_2, house_3, house_4, barrel, chest, fort, broadleaf. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** counting-house landmark and covered bridge; guild frontage and loading arcade kit; scales, carts and hoists; working crossbow hall; articulated-engine assembly yard.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

### Stonewake — The Deepcairn Pact

**Identity:** A subterranean town forms a crescent of occupied stone terraces around a daylight shaft, with low heavy lintels and a great suspended stone chime.

**Landscape and landmark:** A cut mountain hall opens toward a real exterior gorge. Rock walls, descending galleries and an unseen deep shaft create depth without a flat cave backdrop. The Echo Seat is an inhabited stepped stone hall beneath a suspended lithic chime, carried by visible timber-and-iron engineering.

**Composition:** Foreground: A broad stone arrival bridge crosses the daylight shaft; lamps and worn stair edges define safe routes. Middle distance: Dense low-roofed workshops and homes form a descending crescent around the shaft. Hoists occupy its far edge. Background: The Echo Seat and Deepcoil Vault recede into separate side halls; warm task lights reveal their thresholds without illuminating the whole cavern uniformly.

**Circulation and open space:** A broad ramp joins three working terraces; small stairs and lift platforms offer visible secondary circulation. Keep the shaft void and main ramp legible. Dark areas must support depth without hiding building selection or route edges.

**Districts:** Daylight bridge and cairn muster; Dwelling and flint-work terrace; Echo hall court; Runeshell forge and hoists; Sett and Deepcoil thresholds.

**Materials:** cut gray stone with tool marks; weathered iron ties; heavy dark timber braces; warm linen lamp shades; small mineral inlays with restrained light.

**Visible life:** counterweighted lift cycles; miners and porters carrying real loads; stone chimes moving sparingly; covered lamps and drifting dust in daylight; forge work behind shutters; badgers emerging into a clear service court.

**Upgrade integration:** A forge gains a heavier lintel, second assembly bay and hoist; a dwelling terrace extends into a supported gallery; the echo hall gains chime frames without reducing the shaft void.

| Canonical recruitment site | Authored spatial requirement |
|---|---|
| Cairn Muster — Cairnguard | A stone muster apron beside the daylight bridge |
| Flint Range — Flintshot Slingers | A compact sling court with deep backstop |
| Flintclaw Sett — Flintclaw Badgers | A broad excavated sett with grounded animal ramps |
| Echo Hall — Echo Keepers | A covered chime hall with clear internal circulation |
| Runeshell Forge — Runeshell Guardians | A heavy forge and guardian assembly apron |
| Deepcoil Vault — Deepcairn Wurms | A tall deep portal with a wide serpent emergence channel |

**Reuse candidates:** rocks, fort, barrel, chest. These are available source kits, not proof of this capital’s completion.

**Bespoke work:** authored cavern and terrace shell; low stone-house and brace kit; counterweight hoists and lift platforms; echo-seat/chime landmark; badger sett and deep-serpent threshold.

**Current boundary:** No dedicated accepted 3D capital scene is implemented for this profile.

## Immediate Dawnreach construction pass

All eight reviewed Blender reconstructions are now installed at the stable runtime paths `assets/models/towns/ashen_crown/{granary,barracks,market,smithy,shrine,palisade,wharf,water_gate}.glb`. The exact source exports, packed editable `.blend` files, authoring modules, settings and candidate-stage manifests remain under `assets/staging/card-reconstruction/<id>/`; the installed manifest records development promotion separately. The legacy `shrine` ID displays as the secular Oath Hall. The original paintings remain the architectural authority and unchanged construction-card artwork. Canonical completed/rest geometry and local functional motion retain the reviewed design; production acceptance remains false.

The final staged town passed **168 native checks, zero failures and eight inspected captures**, using the exact eight final models. That populated presentation fixture covers flat foundation cores and continuous terrain blends, roads in the ground material, real entrance spurs, clear Market/Smithy work areas, Wharf steps/pile support/boat waterline, a supported Water Gate upper basin/channel/lower outlet, and restoration of the unbuilt riverside. The separate actual-runtime purchase/save/reload gate passes 1,506 assertions with zero failures, eight real purchases, fifteen captures and exit 0 in an explicitly funded QA realm; it exercises both legitimate saved river branches through the interface. Exported-binary startup, resource binding and normal-exit evidence is recorded separately in VERIFICATION.md. See [CARD_RECONSTRUCTION.md](CARD_RECONSTRUCTION.md) and the [town integration handoff](verification-logs/card-reconstruction/town-layout-attempt03/integration-handoff.md); these results do not finish nine capitals or establish performance, pedestrian navigation or simulated water.

| Building | Required silhouette and visible working detail |
|---|---|
| Granary | Raised timber store, red tiled gable, external loading stair, door, vent slats, sacks/platform and structural braces |
| Training Yard | Low defensive court with small roofed towers, a clear entrance, targets, equipment racks and a flag mast |
| Market | Two differently sized striped-canvas stalls, actual posts, sagging canopy, stocked counters, baskets and a clear aisle |
| Smithy | Masonry fire bay, red tiled roof, real chimney, timber lean-to, anvil, fuel stack, bellows and accessible work frontage |
| Oath Hall | Broad timber public hall, carved porch and doors, red roof, two secular heraldic banners and visible seating; no portrait-icon treatment |
| Palisade | Sharpened log wall, supported wall walk, roofed guard posts, gate leaves and an open approach |
| Wharf | Piled plank deck, visible braces, mooring posts, small working crane and a structurally coherent boat; no water plane baked into the building |
| Water Gate | Stone arch, unequal or paired roofed towers, operable gate parts, chain/beam mechanism and a grounded defensive apron |

## Existing native kit useful for the terrace redesign

The available kit is inventoried in `assets/models/manifest.json`. All environment candidates below retain their downloaded CC0 notices. Original newly authored town models are tracked separately.

| Source path | Exact pieces / use | Limit |
|---|---|
| `assets/models/modular_fort_01/modular_fort_01_1k.gltf` | `modular_fort_01_wall_thick_straight_01/02`, `wall_thick_corner_01/02`, `wall_thick_end_01/02` with the same `modular_fort_01_` prefix: retaining and defensive terrace structure | Reset showroom offsets and inspect depth/joins; do not simply stretch a wall into every foundation |
| Same fort source | `modular_fort_01_wall_walkway_straight_01/02`, `modular_fort_01_wall_walkway_corner_01/02`, `modular_fort_01_wall_walkway_end_01`, `modular_fort_01_wall_stairs_straight_01` | Useful real stairs and wall walks; connect endpoints and keep rise/run plausible |
| Same fort source | `modular_fort_01_tower_round`, `modular_fort_01_wall_thin_gate_01`, `modular_fort_01_wall_thin_straight_01/02/03/04` | Interim outer defense and distant keep mass; bespoke high-court architecture still required |
| `assets/models/medieval_village/medieval_house_01.glb` through `_04.glb` | Four grounded timber-house assemblies for supporting lanes | Repeated source houses remain supporting fabric; eight purchased civic buildings get their own authoritative models |
| `assets/models/forest/pine.glb`, `broadleaf.glb` | Grounded 1 m normalized trees; 784 / 1,080 triangles | Use meaningful species/height clusters and preserve alpha masking; unsuitable as the bespoke ancient-tree landmark |
| `assets/models/rock_moss_set_02/rock_moss_set_02_1k.gltf` | `rock_moss_set_02_rock07` through `rock13` | Seven small natural rocks; larger terrain should be authored rather than one huge stretched boulder |
| `assets/models/wine_barrel_01/wine_barrel_lod.glb` | Barrel assembly, 4,819 triangles | Share meshes; too expensive for hundreds of tiny background props without lower LOD |
| `assets/models/treasure_chest/treasure_chest_lod.glb` | Chest with distinct lid/handles/lock | 11,008 triangles; reserve for visible focal props, not every crate |

## Acceptance and production accounting

The profile inventory contains nine town designs and fifty-four canonical recruitment-site concepts. It contains zero accepted finished capitals. The current eight-model Ashen Crown pass does not fulfill fifty-four recruitment buildings, nine architectural kits or the planned upgrade catalog. Reused rocks, houses and trees do not become unique faction architecture merely by changing material color.

For each building: lock the original card and visible landmarks; define footprint/front/state and the rule it represents; reconstruct in Blender; compare an aligned three-quarter view to the unchanged painting; correct architectural differences; export and inspect normals, UVs, materials, bounds and source dependencies; verify purchase/save reconstruction and actual world hover; then record review or rework. A rendered image is evidence only for the pose and camera shown. File identity, successful import and total test counts cannot approve an architectural mismatch.

For each town: compare all nine clay silhouettes; inspect empty, partly built and fully built layouts; verify no path, door or important roof is occluded by a new purchase; inspect several watches and water/wind states; exercise picking through foreground geometry; verify persistent upgrades and mutually exclusive slots; record native frame time, draw submissions, visible triangles and texture memory at the real camera. Tune LOD and repeated mesh instancing from those measurements. Do not claim a frame budget from geometry counts alone.

The authored 3D scene supplies world views and gameplay screenshots. The original paintings supply construction-card art and govern model design. Label Blender previews as Blender previews and native captures as native captures; neither can be represented as a finished game or substitute for a missing playable system.

## Sources within the project

- User-supplied visual reference: `upload/image(1).png` (composition only).
- Canonical faction names: `docs/NAMING_AND_ART_LOCK.md`.
- Fifty-four family/site names: `data/creature_roster.json` and `docs/CREATURE_ROSTER.md`.
- Current purchase/state boundary: `game/redesign/realm_rules.gd` and `town_stage.gd`.
- Existing source assets, pieces, counts and licenses: `assets/models/manifest.json` and `ASSET_CREDITS.md`.
