# Draconia native 3D assets

All artwork catalogued by `manifest.json` is CC0 1.0 Universal. Original authors,
source URLs, archive hashes, conversion notes and final hashes are recorded in
that manifest and the project `ASSET_CREDITS.md`. The font and animated sprite
licenses are separate.

## Runtime scenes

Paths below are relative to `res://assets/models/`. These are real meshes with
materials; they are not screenshots or pre-rendered backgrounds.

| Scene | Use and integration |
|---|---|
| `modular_fort_01/modular_fort_01_1k.gltf` | 22 named fort modules; select wall, gate or tower nodes and reset their showroom positions. 28,218 triangles for the whole kit. |
| `rock_moss_set_02/rock_moss_set_02_1k.gltf` | Seven individual textured rocks; select a child and normalize its transformed AABB. |
| `forest/pine.glb` | Dense original Yughues conifer, 784 triangles, normalized to 1 metre tall. |
| `forest/broadleaf.glb` | Yughues broadleaf tree, 1,080 triangles, normalized to 1 metre tall. |
| `fir_sapling/fir_sapling_lod.glb` | Compatibility scene containing three instances of the **Yughues pine**, named `fir_sapling_a/b/c`. The path does not identify its creator. Reset X offsets 0/1/2 before placing individual copies. |
| `medieval_village/medieval_house_01.glb` through `04.glb` | Four Daniel Andersson houses, centered and grounded. Respectively 17,011 / 12,760 / 17,300 / 12,238 triangles. |
| `medieval_house/medieval_house.gltf` | Additional Paul Wortmann rural shack, 204 triangles, 2K textures. |
| `wine_barrel_01/wine_barrel_lod.glb` | Whole textured barrel assembly, 4,819 triangles. Preserve its lid, base and bung children. |
| `treasure_chest/treasure_chest_lod.glb` | Whole textured chest assembly, 11,008 triangles. Preserve lid, handles and lock children. |
| `werewolf/werewolf.glb` | Full-body skinned br-n518 werewolf, 892 triangles. Use this scene instead of the retained raw DAE reference. |

All runtime scenes use glTF Y-up. Houses are centered in X/Z with their lowest
point at Y=0. Forest materials use two-sided alpha **MASK**, cutoff 0.4 and
roughness 0.95; changing them to alpha blending causes unnecessary sorting and
overdraw problems.

The original Poly Haven `fir_sapling_1k.gltf` remains as reference. Its dense
needle geometry was unsuitable for large real-time forests. The preliminary
decimated version lost foliage and was replaced with the Yughues pine; it is
not a runtime alternative.

## Werewolf animation

The Godot import exposes `idle`, `run`, `walk`, `attack`, `death`, `idle_sniff`
and `idle_bare_teeth` on its `AnimationPlayer`. The native importer removes the
original `-loop` suffix from idle, run and walk. Default forward is **+Z**;
rotate +90 degrees around Y to face +X or -90 degrees to face -X.

Bind-pose mesh AABB: position `(-4.721181, 0, -3.254076)`, size
`(9.442362, 6.784301, 4.725657)`. A uniform scale of approximately `0.3832`
gives a 2.6-metre bind-pose height. Frame the animated body rather than its
wide bind-pose arms. The evaluated Mirror modifier is included, and the
original rig's constraints have been sampled into animation tracks.

`qa-report.json` records texture/dependency validation and actual Godot-rendered
pose hashes. The final idle, attack and death samples visibly deform the full
mesh. This does not substitute for the game's integration tests.

## Materials and editable sources

`materials/forrest_ground_01/` and `materials/brown_mud_leaves_01/` each contain
`albedo.jpg`, `normal.jpg` (OpenGL convention), and `roughness.jpg` at 2K.
Use repeating UVs and linear sampling for normal/roughness maps.

`source/` retains the original house Blender files, selected original forest
OBJ/TGA sources, the original werewolf Blender rig/textures, metadata snapshots
and conversion scripts. Its `.gdignore` prevents these development sources
from being imported as game resources. Also exclude `assets/models/source/*`
in native export presets. Godot import sidecars (`.import`) are legitimate
source settings and should be retained in the editable project.

Converters were run with official Blender **4.5.14 LTS** (archive SHA-256
`9ba871ff2ecd36526b77432745980b7e6664ecd0c7ca11c48849073dcfe06da3`). For example:

```sh
blender --background --factory-startup --disable-autoexec \
  --python assets/models/source/convert_houses.py -- \
  assets/models/source/medieval-village assets/models/medieval_village
```

`convert_forest.py` takes `source/mundo` and an output directory;
`convert_werewolf.py` takes `source/werewolf` and an output directory.
The latter writes `werewolf.glb` after completing its temporary export.
The forest exporter must be followed by the documented alpha-mask setting
and compatibility-node construction; those final settings are in the GLBs
and `manifest.json`.

The optional geometry simplifier uses `@gltf-transform/core`, `functions` and
`extensions` **4.5.0**, plus `meshoptimizer` **0.25.0**. It preserves UVs and
materials. Chest settings were ratio `0.08`, error `0.005`; barrel settings
were ratio `0.25`, error `0.003`. Keep all original artwork notices when
redistributing these editable sources.
