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

**Acceptance is limited to an integration proof.** The reviewed rig has a
coherent body and sword grip, but garment materials and mask edges, secondary
braid motion, the full equipment catalog, final identity detail and LOD
optimization remain production work. The controller must release or hide
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
and original additions retain the project's applicable release terms. No new
external asset or commercial-game equipment was downloaded for these items.

`assets/models/mara/equipment/manifest.json` records exact hashes, item IDs,
attachment transforms, hidden base meshes and the measured cowl clearance
curves. The v8 hero correction changes only the attack's right-hand rotation
channel to keep both blades above ground. Source scripts, editable Blender
files, reviewed native images and the actual dungeon adapter verification
remain in `assets/staging/ileana-mpfb-proof/`. These are two accepted
development integration proofs, not completed armor sets or final production
surface art.

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

## Original Ashen Crown civic models constructed in Blender

The eight models under `assets/models/towns/ashen_crown/` are original
Draconia project geometry authored and exported using **Blender 4.5.14 LTS**:
Granary, Training Yard (`barracks`), Market, Smithy, secular Oath Hall
(`shrine`), Palisade, Wharf and Water Gate. Their individual roof tiles,
planks, timber framing, stone courses, doors, access stairs and props are
3D geometry. Six small material textures were baked from original Blender
shader nodes. No downloaded model, external image texture or proprietary
game artwork is incorporated in these eight assets.

The user-supplied town reference provided a composition/quality brief;
the earlier project building atlas provided a silhouette/material brief.
Neither reference is a texture projected onto these buildings. Final town
cards must be native renders of the same authoritative GLBs, with the same
geometry/material resources and completed pose.

The packed editable source is
`assets/models/source/towns/ashen_crown/ashen_crown_master.blend`, and its
original construction/export script is
`assets/models/source/towns/build_ashen_crown.py`. The six source bakes,
reviewed source renders and correction/limitation notes are retained in
that ignored authoring folder. Runtime `manifest.json` records source and
export hashes, actual bounds and triangle counts. All eight together have
66,352 triangles and 11,039,468 bytes of embedded-texture GLB data.

These models passed a bounded static development integration review in
Blender and native Godot, including the final palisade's front/rear access.
This does not complete worker/production animations, building upgrades,
close-camera material polish, LODs or the nine planned capital scenes.
Their original source scripts follow the project's source-code license;
this provenance statement does not change any downloaded asset's license.
