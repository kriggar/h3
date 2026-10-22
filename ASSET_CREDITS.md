# Draconia — The Blackbriar March: asset credits

## Current third-person build

The active third-person game uses the unchanged Mara hero and Quaternius-derived
motions, Yughues forest meshes, Daniel Andersson timber houses, the br-n518
werewolf, and the credited CC0 environment/material library below. Raw model
files are reused in a newly authored region. Original procedural geometry covers
terrain/ridges, towers, props, NPC silhouettes, ground cover, UI ornament and VFX.
NPC and creature art remains development art, not a photorealistic production roster.

The old Flare sprite atlases, strategy illustrations, town cards, old card-based
building models and earlier audio were removed from the active project in this
reboot. Their previous versions and complete notices remain in Git history.
The new runtime does not load those assets or the old strategy-game scripts.

### New painted interface icons

`assets/online/icons/abilities.png` contains eight original AI-generated painted
icons created for this project using the built-in image-generation tool. No
commercial-game icons or reference-repository artwork was copied. The atlas was
visually inspected for coherent silhouettes and objects; exact runtime regions
handle its slightly uneven row boundary. The full prompt, source and hash are
recorded in `assets/online/icons/PROVENANCE.md`. Generated art has no third-party
asset-license grant implied by the source-code MIT license.

### New synthesized audio

The nine WAV files in `assets/online/audio/` were synthesized for this project by
`tools/build_online_audio.py`: wind/birds, a quiet harmonic theme, blade, impact,
footstep, ward, reward, level and healing cues. No recorded song or commercial
sound effect was sampled. These original synthesis assets are released under
CC0-1.0; the generator follows the project's MIT code license. The asset manifest
records exact hashes and durations. Mixing and broader sound design remain
production work.

### User-supplied environmental photographs

Four ground photographs supplied by the user on 22 October 2026 form the basis
of the new surfaces in `assets/online/terrain/`: packed dirt, weathered cracked
mineral stone, meadow grass/clover, and pebble gravel. The built-in image editor
prepared square base-color textures with more even illumination and repeatable
detail. The first gravel candidate was rejected for conspicuous duplicated stone
clusters; a revised version is used in the game.

`PROVENANCE.json` records each original upload name and hash, output hash, exact
editing prompt, and dimensions. `GRAVEL_REVISION.json` records the corrective
prompt. The source photographs were supplied by the user for this project;
rights remain with their respective owner. Neither those photographs nor their
derived textures are relicensed as CC0 or MIT by this repository. Only the
prepared runtime textures are bundled here.

These are photo-derived color maps, not measured photogrammetry material sets.
Texture scale and roughness are authored in the renderer; there are no claimed
measured normal, displacement, or roughness maps from these single photographs.

### Fonts and engine

Cinzel is retained under SIL Open Font License 1.1, with its notice in
`assets/CINZEL-OFL.txt` and exact provenance in
`assets/licenses/CINZEL-PROVENANCE.json`. EB Garamond remains available under its
bundled OFL notice. Godot supplies its built-in UI font. The game's own Godot and
component notices are bundled in `assets/licenses/GODOT-*`.

## Retained model and material sources

The source/evidence staging paths mentioned below are historical authoring paths,
not required runtime downloads. The current repository bundles each runtime model
and its texture dependencies. It does not require Blender or MPFB to run.

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

The active third-person game uses `assets/models/werewolf/werewolf.glb`,
converted from **br-n518**'s
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


Retain these credits and the applicable source notices when redistributing the assets.
