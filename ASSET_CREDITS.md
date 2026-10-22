# Draconia — artwork, model, audio and font credits

Draconia uses downloaded, licensed animated character artwork. These unit
animations are credited to their original artists. They are not AI-generated
unit animations and are not assets from Heroes of Might and Magic III or
Manor Lords. The static landscape and object illustrations are a separate
asset category created for this project.

## Animated units from Flare

Nine character atlases use the original rendered character art and animation
frames from **Flare: Empyrean Campaign**. The Flare repository states that its
art and data files are available under **Creative Commons
Attribution-ShareAlike 3.0**, with later versions permitted. The Draconia
repacked and composited atlases are distributed under **CC BY-SA 3.0**.

- Project: <https://flarerpg.org/>
- Repository: <https://github.com/flareteam/flare-game>
- Exact downloaded commit: `af6eee6d339ac98011864bfe89da837fe7769c28`
- License: <https://creativecommons.org/licenses/by-sa/3.0/>
- Upstream copyright and license statement: <https://github.com/flareteam/flare-game/blob/af6eee6d339ac98011864bfe89da837fe7769c28/README>
- Detailed upstream artist attribution: <https://github.com/flareteam/flare-game/wiki/Credits>

**Credit:** Clint Bellanger, Justin Nichol, and the Flare contributors.
Contributors retain copyright in their original contributions. Relevant
additional upstream credits include Jessica “Zeldyn” Cox for character
concepts, D. Sharon Pruitt for the distressed leather texture used by the
light armor source, Misha for the skeleton sword concept, and Justin Jacobs
for subsequent contributions. The complete upstream contributor list and
detailed per-file credits are bundled in `assets/licenses/` so this summary
does not replace the original notices.

| Draconia key / label | Downloaded visual source |
|---|---|
| `spearman` / Oștean | Male cloth armor, short sword and buckler |
| `archer` / Arcaș | Male leather armor and longbow |
| `swordsman` / Străjer | Male chain armor, sword and shield |
| `knight` / Cavaler | Male plate armor and greatsword; a foot soldier |
| `mage` / Solomonar | Male mage robes and staff |
| `griffin` / Iele | Long-haired female in robes, with casting animation and no wings |
| `skeleton` / Strigoi | Skeleton with sword and shield |
| `orc` / Spiriduș Blestemat | Goblin |
| `dragon` / Balaur | Fire wyvern |

The stable programming keys preserve compatibility with the game's unit
definitions. The Romanian names in this historical table record the earlier prototype roles; current display naming follows `docs/NAMING_AND_ART_LOCK.md`. In
particular, the `griffin` filename contains a female figure, not a griffin.

### Changes made to the Flare assets

The original source PNGs and animation definitions were downloaded to a
build cache unchanged. The selected equipment layers were composited in
the source game's layer order, using their exact per-frame origin offsets.
One three-quarter source view was selected and horizontally mirrored to
give a consistent right-facing battle orientation. Existing frames were
aligned, padded with transparency, and packed into PNG atlases. No anatomy,
clothing, textures, or animation poses were painted or redesigned. No
resizing or recoloring was applied to the Flare artwork.

Idle, movement, attack, death and hit animations use different actual source
frames. Four-frame standing cycles are played forward and backward as
specified upstream. The source animations are classic rendered game art;
they are not photorealistic contemporary character models.

`assets/animated/source/flare-provenance.json` records the exact source URL,
SHA-256 hash, and byte count for every used source PNG and animation
definition. The original animation definitions are included under
`assets/animated/source/flare-config/`. `pack_flare.py` documents the complete
technical composition and atlas packing process. Source PNGs can be fetched
at their pinned URLs to reproduce the atlases.

## Vârcolac: CC0 werewolf by br-n518

- Artist: **br-n518**
- Original title: **Werewolf**
- Original publication: 16 September 2018
- Source and license declaration: <https://opengameart.org/content/werewolf-0>
- Download: <https://opengameart.org/sites/default/files/werewolf_godot_export.zip>
- License: **CC0 1.0 Universal** — <https://creativecommons.org/publicdomain/zero/1.0/>

This is the artist's animated 3D werewolf, rendered into a transparent atlas
for the `wolf` / Vârcolac unit. Its original idle, run, attack, death and walk
clips are evaluated frame by frame from the COLLADA skeleton. The original
geometry, diffuse texture and animation poses are preserved. Technical
conversion consists of normalized skin-weight evaluation, an orthographic
camera, simple lighting, supersampling and atlas packing. These are real
articulated animation frames, not a transformed still image.

The downloaded model and textures are included under
`assets/animated/source/werewolf/`. Its acquisition hashes and processing
notes are in `werewolf-provenance.json`; `render_werewolf.py` reproduces the
atlas. The artist's source page and CC0 legal text are bundled under
`assets/licenses/`. Attribution is retained voluntarily even though CC0
does not require it.

## Optional ambient audio and music

Both background recordings below are distributed under **CC0 1.0
Universal**. Their original creators are credited voluntarily. These are
downloaded recordings, separate from any procedurally generated interface
tones. They are intended for an optional audio control and should begin
only after the player enables audio.

| Local file | Original recording | Author | Source |
|---|---|---|---|
| `assets/audio/forest.ogg` | Bird twitter forest loop | Chris Castiglione (`alienistcog`) | <https://freesound.org/people/alienistcog/sounds/125781/> |
| `assets/audio/chronicle.ogg` | *Medieval: The Bard's Tale*, loop version | RandomMind | <https://opengameart.org/content/medieval-the-bards-tale> |

The bird loop was obtained unchanged from the pinned Flare source at
`mods/fantasycore/soundfx/environment/bird_twitter_loop.ogg`. Flare's detailed
credits explicitly identify this recording, artist and CC0 license:
<https://github.com/flareteam/flare-game/wiki/Credits>. It is a 9.36-second
stereo loop, renamed `forest.ogg` for Draconia.

The medieval instrumental is the composer's original 57.73-second looping
WAV, downloaded from
<https://opengameart.org/sites/default/files/Loop_The_Bards_Tale.wav>.
It was transcoded to Ogg Vorbis quality 5 for a smaller download. Its
composition, timing and loop boundaries were not edited. The original
source page states CC0 and identifies the medieval, peaceful instrumental
character of the track. This recording is by RandomMind; its title is not
an attribution to a commercial game's soundtrack.

`assets/audio/manifest.json` records exact source URLs, original and output
hashes, durations, encoding, suggested quiet playback levels and
`autoplay: false`. A copy of the composer's source and license page is
`assets/licenses/BARDS-TALE-SOURCE-PAGE.html`; the CC0 legal text is bundled
as `assets/licenses/CC0-1.0.txt`.

## Cinzel display font

**Cinzel** by **Natanael Gama and the Cinzel Project Authors**, downloaded
from the official Google Fonts repository:
<https://github.com/google/fonts/tree/main/ofl/cinzel>.

The font is distributed unchanged under the **SIL Open Font License 1.1**.
The original notice is `assets/CINZEL-OFL.txt`; its source URL and SHA-256
are recorded in `assets/licenses/CINZEL-PROVENANCE.json`.

## Native 3D environment models and PBR materials

The native 3D environment uses downloaded, reuse-licensed meshes and textures.
These are separate from the generated landscape and manuscript illustrations in
`assets/generated/`. No 3D model below comes from Heroes III or Manor Lords.

### Poly Haven — CC0 1.0 Universal

Poly Haven releases these model and material assets under CC0:
<https://polyhaven.com/license>. A snapshot of that declaration is bundled as
`assets/licenses/POLYHAVEN-LICENSE-PAGE.html`, and the full CC0 text is
`assets/licenses/CC0-1.0.txt`.

| Asset | Original creator | Primary source |
|---|---|---|
| Modular Fort 01 | Rico Cilliers | <https://polyhaven.com/a/modular_fort_01> |
| Rock Moss Set 02 | Kless Gyzen | <https://polyhaven.com/a/rock_moss_set_02> |
| Wine Barrel 01 | James Ray Cock | <https://polyhaven.com/a/wine_barrel_01> |
| Treasure Chest | Rico Cilliers | <https://polyhaven.com/a/treasure_chest> |
| Fir Sapling, retained original reference | Rico Cilliers; photography by Rob Tuytel | <https://polyhaven.com/a/fir_sapling> |
| Forest Ground 01 | Rob Tuytel | <https://polyhaven.com/a/forrest_ground_01> |
| Brown Mud Leaves 01 | Rob Tuytel | <https://polyhaven.com/a/brown_mud_leaves_01> |

The original glTF models and their dependencies were downloaded unchanged and
checked against the publisher's MD5 values. SHA-256 records are also retained.
Models use the publisher's 1K texture set; the two ground-material sets use 2K
albedo, OpenGL normal and roughness images. The barrel and chest have additional
real-time GLB copies with simplified geometry. Their texture artwork and UV
mapping are preserved. The original files remain alongside those copies.

### Dense pine and broadleaf trees — Yughues, CC0

The final dense conifer and broadleaf models are by **Yughues (Hugues Muller)**,
from **Freebies — Mundo commissions**, shared with the commissioning client's
agreement under CC0:
<https://opengameart.org/content/freebies-mundo-commissions>.
The original archive is <https://opengameart.org/sites/default/files/Mundo.7z>.
The source declaration is bundled in
`assets/licenses/YUGHUES-FOREST-SOURCE-PAGE.html`.

`assets/models/forest/pine.glb` and `broadleaf.glb` retain the creator's original
geometry and diffuse/alpha/normal textures. Technical changes are format
conversion, centering, normalization to one metre tall, and a two-sided alpha
cutout material for real-time rendering. The pine has 784 triangles and the
broadleaf tree has 1,080 triangles. They are textured foliage-card meshes, not
painted cone approximations.

For compatibility with existing scene code,
`assets/models/fir_sapling/fir_sapling_lod.glb` contains three instances of this
**Yughues pine**, with the names `fir_sapling_a`, `fir_sapling_b`, and
`fir_sapling_c`. It is not an adaptation of Poly Haven's fir. The original
Poly Haven fir remains separately as `fir_sapling_1k.gltf`; the preliminary
aggressively reduced fir was replaced after visual inspection found loss of
foliage. The three compatibility instances share the same mesh; their position,
scale and rotation are varied by the game.

### Timber-frame houses — Daniel Andersson, CC0

The four detailed village houses are by **Daniel Andersson**, from the
**Medieval House Pack** published under CC0:
<https://opengameart.org/content/medieval-house-pack>.
The exact original ZIP URLs and hashes are in the model manifest. The source
page and the original BlendSwap license notices from those ZIPs are included in
`assets/licenses/MEDIEVAL-HOUSES-SOURCE-PAGE.html` and the four
`MEDIEVAL-HOUSE-*-LICENSE.html` files.

`assets/models/medieval_village/medieval_house_01.glb` through
`medieval_house_04.glb` were converted from the original Blender files.
Legacy materials were connected to their matching original packed texture
images; one missing external wood-material link was restored using the
included wood texture. The meshes were joined, centered, grounded, and exported
with the glTF Y-up convention. Original geometry, UVs and texture images are
retained; roughness was set for the new PBR renderer. The original Blender
files are retained under `assets/models/source/medieval-village/`.

The additional modest timber shack in `assets/models/medieval_house/` is
**medieval_house_1** by **Paul Wortmann**, CC0:
<https://opengameart.org/content/medievalhouse1>.
Its original notice credits **Beaterator** for the CC0 brick source and
**AnyRPG** for the CC0 wood/roof texture sources. The original `credits.txt` is
retained beside the model; a source-page snapshot is in
`assets/licenses/TIMBER-SHACK-SOURCE-PAGE.html`. Its OBJ was converted to glTF,
using the included albedo and normal textures. The unrelated ground used in
the author's preview was not copied.

### Live skinned Vârcolac model — br-n518, CC0

In addition to the previously documented sprite atlas, the game can use
`assets/models/werewolf/werewolf.glb`, converted from the same **br-n518**
werewolf's original Blender source:
<https://opengameart.org/sites/default/files/werewolf_source.7z>.
The source and CC0 declaration remain
<https://opengameart.org/content/werewolf-0>.

The original Mirror modifier was evaluated to include both sides of the body,
skin weights were normalized, the author's rig constraints were sampled into
animation tracks, and diffuse/normal images were connected to a PBR material.
The full-body mesh has 892 triangles. Its original seven actions are preserved:
idle, walk, run, attack, death, idle sniff and idle bare-teeth. The original
Blender file and textures are retained in `assets/models/source/werewolf/`.
Actual Godot-rendered poses were checked after import; the earlier raw DAE
import is retained only as source/reference and is not the recommended runtime
scene. This is a low-polygon original asset, not a newly authored photorealistic
creature.

`assets/models/manifest.json` records runtime paths, source URLs, authors,
license categories, processing notes, hashes and sizes. Editable sources and
conversion scripts are under `assets/models/source/`; its `.gdignore` prevents
those source Blender files from being automatically imported into the game.
All downloaded 3D artwork above remains **CC0 1.0 Universal**. The project's MIT
license applies to original project code and does not relabel third-party art,
fonts or their original notices.

## EB Garamond reading font

**EB Garamond**, copyright 2017 **The EB Garamond Project Authors**, is provided
unchanged from the official Google Fonts repository under the **SIL Open Font
License 1.1**. The original project listed in its notice is
<https://github.com/octaviopardo/EBGaramond12>.

- Runtime file: `assets/ebgaramond.ttf`, upright variable weight font.
- Official source: <https://github.com/google/fonts/tree/f8c1d3d6cc75e30d77130bdcbfbff27e3b6233fe/ofl/ebgaramond>.
- Pinned Google Fonts commit: `f8c1d3d6cc75e30d77130bdcbfbff27e3b6233fe`.
- Full original license: `assets/licenses/EBGARAMOND-OFL.txt`.
- Exact download URLs, byte counts and SHA-256 hashes:
  `assets/licenses/EBGARAMOND-PROVENANCE.json`.

## Mara Veyne — staged MakeHuman/MPFB character and Quaternius motion proof

`assets/models/mara/mara.glb` is the first **fully skinned 3D hero integration
proof**. Its adult female body, eyes, eyebrows, eyelashes and braid come from
the MakeHuman community's **CC0** core/system assets. Its selected tunic,
trousers and boots are **RehmanPolanski's CC0** assets, listed in the official
MakeHuman *Suits 02* catalog. Only those selected garment entries were used;
unrelated catalog items were not imported.

- Official split between tool and asset licenses:
  <https://static.makehumancommunity.org/about/license.html>.
- Core/system source catalog:
  <https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html>.
- Selected garment source catalog:
  <https://static.makehumancommunity.org/assets/assetpacks/suits02.html>.
- MPFB tool version **2.0.18**, source commit
  `d0a32e57a7f915cb2f2b95410e2117648c7bbb7e`:
  <https://github.com/makehumancommunity/mpfb2/tree/d0a32e57a7f915cb2f2b95410e2117648c7bbb7e>.

The tool's **GPL-3.0-or-later code license** is separate from the **CC0 asset
license**. The MPFB source tool is retained in the editable source staging
area with its full code and asset notices; it is not required by the shipped
game. The retained MakeHuman embedded notices identify the MakeHuman
community, Data Collection AB, Joel Palmius and Jonas Hauquier. The runtime
asset notice is `assets/licenses/MAKEHUMAN-CC0-ASSET-NOTICE.md`.

Motion source: **Quaternius**, *Universal Animation Library — Standard*,
creator upload dated **16 April 2025**, CC0:
<https://opengameart.org/content/universal-animation-library> and
<https://quaternius.com/packs/universalanimationlibrary.html>.
The original creator notice is
`assets/licenses/QUATERNIUS-ANIMATION-NOTICE.txt`; the full CC0 text is
`assets/licenses/CC0-1.0.txt`. This specific source archive contains 45
animation entries plus a T-pose record; the differently advertised larger
library is not claimed to be included.

Project changes comprise adult macro proportions, rig fitting, covered-body
export masking, restrained garment material assignments, retargeting and
floor-contact corrections, right-hand grip correction, and a simple original
sword mesh. The original tunic and trouser texture artwork is retained in
staging but is not used on the model; the boot texture is retained. The source
yellow motion mannequin is not used as character artwork. No commercial-game
character or animation was extracted for this model.

The original selected source members, their individual hashes and official
license evidence are retained under
`assets/staging/ileana-mpfb-proof/`. The complete downloaded motion archive
and its hash remain under
`assets/staging/quaternius-universal-animation-library-standard-2025-04-16/`.
Both staging folders are excluded from runtime imports. The runtime model
manifest records the promoted version, hash, named clips and integration
contract. Original third-party assets remain CC0; project-authored additions
retain the project's applicable release terms.

**Acceptance is limited to development integration.** The v9 revision adds
licensed PBR garment/equipment surfaces and original skin microdetail, with
245 native checks and ten inspected material/pose captures. The reviewed rig
has a coherent body and sword grip, but collar/cowl edges, tunic deformation,
secondary braid motion, the full equipment catalog, final face identity and
LOD optimization remain production work. The controller must release or hide
the held sword for the unarmed death/roll/casting source motions. A still
image alone does not establish locomotion foot-slide or final gameplay quality.

### Two project-authored earned equipment modules

`assets/models/mara/equipment/vowkeeper.glb` is the original Draconia
**Vowkeeper** sword: a fullered blade, curved bronze quillons, bound grip and
open ring pommel. It has 1,088 triangles and attaches to the hero's right-hand
bone. `bellworn-cowl.glb` is the original **Bellworn Cowl**, with 5,288
triangles, an open face and a braid opening. Its fitted capelet was projected
against the licensed tunic surface and receives compatible garment weights;
it shares the existing 53-bone skin rather than adding another animated rig.

The module geometry and material choices are project-authored. Their fit and
rigging derive from the CC0 character/garment basis described above. The
underlying sources retain CC0, MPFB tool code retains its separate license,
and original additions retain the project's applicable release terms. The
v9 surface pass uses the licensed CC0 material sources listed below. No
commercial-game equipment geometry was extracted for these items.

`assets/models/mara/equipment/manifest.json` records exact hashes, item IDs,
attachment transforms, hidden base meshes and the measured cowl clearance
curves. The v8 hero correction changes only the attack's right-hand rotation
channel to keep both blades above ground. Source scripts, editable Blender
files, reviewed native images and the actual dungeon adapter verification
remain in `assets/staging/ileana-mpfb-proof/`. These are two accepted
development integration proofs, not completed armor sets or final production
surface art.

### Character PBR surface sources — v9

The following texture sources are retained under
`assets/models/source/characters/pbr-sources/`, with original metadata,
download URLs, byte counts, remote checksums where supplied and local SHA-256
hashes. Runtime derivatives are shared under `assets/models/mara/materials/`.

| Source | Creator credit | License | Use |
|---|---|---|---|
| [Caban](https://polyhaven.com/a/caban) | colormass photography; Rico Cilliers processing, Poly Haven | CC0 | Madder wool tunic and charcoal-blue cowl |
| [Rough Linen](https://polyhaven.com/a/rough_linen) | colormass photography; Rico Cilliers processing, Poly Haven | CC0 | Trousers, woven binding and cowl lining |
| [Brown Leather](https://polyhaven.com/a/brown_leather) | Rob Tuytel, Poly Haven | CC0 | Belt and sword grip surfaces |
| [Metal012](https://ambientcg.com/a/Metal012) | Lennart Demes, ambientCG | CC0 | Steel, bronze and fastener surfaces; source metadata identifies procedural PBR |

Official terms: <https://polyhaven.com/license> and
<https://docs.ambientcg.com/license/>. Original source notices are retained;
the shared full license is `assets/licenses/CC0-1.0.txt`.

Project changes comprise neutralized cloth albedo, authored dye/metal colors,
physical-scale UV assignment, OpenGL normal conversion to lossless 8-bit PNG,
packed roughness/metal channels, restrained surface strengths and runtime
anisotropic mip filtering. The skin keeps its original MakeHuman color
texture and adds an original Blender micro-normal/roughness bake; it is not
a newly acquired skin scan. Boots, hair and eyes retain their original
licensed artwork. The original node/skin/animation records remain unchanged;
only body/tunic mesh buffers were repaired for neck coverage and cloth trim.

Rebuild scripts, the packed editable Blender source, exact output hashes and
qualified review are documented in `docs/CHARACTER_MATERIALS.md`. These are
surface improvements to one development hero and two fitted items, not
completed photorealistic character or armor rosters.

### Historical sprite atlas verification

`assets/animated/animations.json` is the runtime manifest. Image paths are
relative to the project root and can be prefixed with `res://` in Godot.
Frame rectangles and anchors use pixels; frame durations use milliseconds.
Each unit supplies `contentBounds`, `displayHeight`, and `drawScale` so
transparent atlas padding does not make the visible figure too small.

All ten atlases were decoded, their hashes checked, frame rectangles checked
against their sheet bounds, and the images inspected. Distinct frame hashes
confirm that the advertised animation states contain changing artwork.
The machine-readable report is `assets/animated/source/qa-report.json`.

Retain this credit file and the applicable licenses when redistributing the
downloaded or adapted artwork. The CC BY-SA requirement applies to the Flare
artwork and its adaptations; this notice does not assign that license to
unrelated code or independently created illustrations.

## Current buildings reconstructed from the original painted cards

The original Draconia manuscript atlas at
`assets/ui/manuscript/buildings.png` is the visual authority for these eight
buildings. Its SHA-256 remains
`f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be`.
The construction interface displays the unchanged paintings. Blender models
are reconstructed to match their architecture, roofs, entrances, heraldry and
props; a rendered model never replaces the reference card.

The independent construction modules are under
`assets/models/source/towns/card_reconstruction/`, with packed editable scenes,
embedded GLBs and individual source/material manifests in
`assets/staging/card-reconstruction/`. These are original project geometry
and local mechanisms, using the retained licensed PBR sources credited below.
Source export, technical checks, development integration and final artistic
acceptance are separate states recorded in the reconstruction evidence.
The reviewed current GLBs are installed under
`assets/models/towns/ashen_crown/`; that directory's schema-4 manifest binds
each installed file to its individual source and review. Across the complete
eight-building set they contain 408,644 triangles and 127,694,128 bytes of
embedded image/model data. This is development integration, with remaining
art refinements recorded in `docs/BUILDING_RECONSTRUCTION_REVIEW.md`.

The cloth uses the documented neutral-yarn derivative retained with Mara's
source. The Granary additionally uses a building-specific sack-linen bake,
created by `prepare_sack_linen.py` from the unchanged Rough Linen photograph.
Its preparation/pixel reports, original source hash and bake hash are retained
under the reconstruction source's `prepared/` directory. Material color
factors tint these derivatives. Original normal/ARM maps remain in use. None
of the building paintings is projected onto geometry, and the original
photographs and existing character bake are unchanged.

## Historical Ashen Crown civic models constructed in Blender

The previous eight-model set installed under `assets/models/towns/ashen_crown/`
before the card reconstruction consists of original
Draconia project geometry and local mechanisms constructed and exported in
**Blender 4.5.14 LTS**: Granary, Training Yard (`barracks`), Market, Smithy,
secular Oath Hall (`shrine`), Palisade, Wharf and Water Gate. Their individual
roof tiles, planks, timber framing, stone courses, doors, access stairs and
props are actual 3D geometry. No downloaded building model or proprietary
game artwork is incorporated into these eight assets.

Their major surfaces now use downloaded **CC0-1.0** PBR maps from the
original creators: **Rough Wood** and **Sandstone Cracks** by Rob Tuytel,
**Clay Roof Tiles 02** and **Clay Plaster** by Amal Kumar, **Rough Linen**
with photography by colormass and processing by Rico Cilliers, and
**Brown Leather** by Rob Tuytel, all from **Poly Haven**; plus **Metal012**
by Lennart Demes / **ambientCG**. Exact asset links, channel URLs, hashes,
physical UV scales and technical adaptations are retained in
`assets/licenses/BUILDING-PBR-NOTICES.md` and
`assets/models/source/towns/pbr-sources/manifest.json` with its metal and
technical-derivative manifests. The full CC0 text is bundled. Original map
pixels are unchanged except the documented resolution/channel conversion
for small iron normal and packed roughness/metal maps. Material tints and
normal strengths are preserved in the actual GLB exports.

The user-supplied town reference provided a composition/quality brief.
The original project building atlas supplied the architectural reference.
Neither was projected as a texture onto the models. The later approach of
replacing those paintings with native model renders was explicitly rejected
on 22 October 2026. Its model/render identity evidence is retained as history;
it does not govern the current interface or establish a match to the cards.

Each model contains authored `hover` and `RESET` animations. The three-second
showcase moves local doors, banners, awning cloth, scales, bellows or hoists
as appropriate; it does not move the whole architecture. Time zero and the
three-second endpoint share the rest pose, including morph weights. This
is authored showcase motion, not worker AI or an economic production cycle.

The packed editable source is
`assets/models/source/towns/ashen_crown/ashen_crown_master.blend`; its
construction/export script is
`assets/models/source/towns/build_ashen_crown.py`. The ignored authoring tree
retains the original downloaded maps/API metadata, scripts, packed master,
source audits, native renders and earlier static/animation-only checkpoints.
The previous runtime manifest, preserved with the prior-runtime-installation
archive, records exact source/export hashes, rest and evaluated motion bounds,
material settings and triangle counts. Those previous eight GLBs contain
**113,860 triangles and 77,551,936 bytes** of locally embedded image/model data.

The final batch passed bounded Blender/source and independent native Godot
review of materials, moving mechanisms, rest restoration and targeted
clearances. A Wharf support cap was lowered to resolve a misleading native
silhouette; the bridge's separated plank joints require 4× MSAA to avoid
small-scale edge aliasing. Faceted fruit/sacks, timber end sections, stone
wear, LODs, target-GPU performance, working population, upgrade variants and
the other eight capital sets remain production work. The original source
scripts follow the project's code license; the downloaded textures retain
CC0 and their source notices. This statement does not relabel other art.

## Original synthesized spell cues

The 18 short WAV cues in `assets/audio/spells/` were synthesized locally for
Draconia by `tools/build_spell_audio.py`. They contain no downloaded sound
recording or sampled commercial-game audio. These original sound assets are
released under **CC0-1.0**; the synthesis script follows the project's **MIT**
code license. `assets/audio/spells/manifest.json` records the cue definitions,
output hashes and scope. Their presence does not certify final mixing,
accessibility or every gameplay sound event.
