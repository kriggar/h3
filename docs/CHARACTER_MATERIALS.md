# Character materials — Mara v9 development pass

## Accepted scope

Mara, the loose starter sword, Vowkeeper and the Bellworn Cowl now use real
UV-mapped surface textures in the native Godot renderer. This is an accepted
**development material integration**, with remaining character art work
listed below. It is not approval of finished photorealistic character art or
of the other 155 hero concepts.

The actual imported-scene review passed **245 checks, zero failures**, with
ten native captures. The review compares the original v8 model with the v9
candidate, verifies the 53 bone names/rest transforms and twelve clip names
and lengths, checks actual material maps/UVs/mipmaps, and inspects the fitted
sword/cowl, attack and walk poses. The separate build manifest verifies that
the original animation binary, node hierarchy and skin records are retained.
Equipment in this studio review is a visual fixture; it does not claim that a
player earned the items in this session.

Evidence: [native report](verification-logs/character-pbr/native-report.json),
[visual review](verification-logs/character-pbr/visual-review.json), and the
ten [native captures](screenshots/character-pbr/).

## Surface sources and treatment

| Surface | Source | Runtime treatment |
|---|---|---|
| Madder tunic and blue cowl | Poly Haven **Caban** | Neutralized source color, authored cloth dyes, physical-scale UVs, normal and spatial roughness maps |
| Trousers, binding and lining | Poly Haven **Rough Linen** | Neutralized source color, restrained natural dyes, physical-scale weave, normal and roughness maps |
| Belt and sword grips | Poly Haven **Brown Leather** | Darkened color, leather grain normal and roughness variation |
| Steel, bronze and fasteners | ambientCG **Metal012** | Authored metallic colors and roughness, OpenGL normals; this source is procedural PBR, not a photographic scan |
| Skin | Existing CC0 MakeHuman skin color | Original Blender-baked micro-normal and roughness detail; no new skin scan is claimed |
| Boots, eyes and hair | Existing licensed character textures | Retained artwork, revised roughness/transparency and correct filtering |

The three Poly Haven sources and ambientCG source are CC0. Exact download
URLs, original checksums, authored transformations and output SHA-256 hashes
are retained in `assets/models/source/characters/pbr-sources/` and the
candidate manifest. Creator credits and license notices are in
`ASSET_CREDITS.md`. Source material licenses remain separate from project
geometry and tool-code licenses.

Poly Haven sources:
[Caban](https://polyhaven.com/a/caban),
[Rough Linen](https://polyhaven.com/a/rough_linen),
[Brown Leather](https://polyhaven.com/a/brown_leather),
[license](https://polyhaven.com/license).
ambientCG sources:
[Metal012](https://ambientcg.com/a/Metal012),
[license](https://docs.ambientcg.com/license/).

## Actual geometry and rendering changes

The neck's covered-body mask was lowered to restore skin beneath the tunic
opening. The coarse polygon-colored sleeve patches were replaced by a
consistent cloth surface, and four rounded woven bindings were added at the
collar, cuffs and hem. Only the body and tunic mesh buffers were replaced.
The original bone names/order, inverse bind matrices, node transforms and
animation channels remain intact. The base model is now **41,590 triangles,
nine mesh objects, fourteen surfaces, thirteen materials and fifty-three
bones**. It remains above the intended final combat asset budget.

Weapon and cowl UVs were added where the original modules had none. The
equipment attachment matrices, original module positions, skin bindings and
measured roll/death clearance curves are unchanged.

Godot's glTF image resources in this import lacked mip levels despite the
sampler requesting them. `HeroAppearance.prepare_materials` now builds cached
mipmapped textures, renormalizes normal-map mips and uses anisotropic
filtering. Repeated refreshes retain the same prepared material. This fixes
the distracting cloth speckle visible in the earlier native review. The
shared reflection environment supplies readable metal responses in the
character folio and dungeon while preserving their own light direction and
background.

An integrated six-cycle create/render/dispose review exposed repeated texture
copies when source scenes were released and reloaded with new renderer IDs.
The runtime now retains a bounded cache of the four registered character and
equipment scenes, so prepared maps are shared across folios and dungeons.
The final lifecycle regression passes 25 assertions: each closed cycle has
exactly 448,371,637 texture bytes and no orphan nodes. That resident cache is
substantial; stable use is not a final GPU-budget or performance approval.
The current fitted-equipment adapter separately passes 18 checks, including
every sampled roll/death controller tick and one-time loose-sword release.
Its redundant temporary sky allocation was removed, and the final native
shutdown has no texture-leak diagnostic. See
[runtime integration](verification-logs/character-pbr/runtime-integration.json).

## Editable Blender sources and reproducibility

The packed editable snapshot is
`assets/models/source/characters/mara-pbr-v9/mara-pbr-v9.blend`.
It contains the exact promoted GLB geometry, rig and materials, with all
twenty image resources packed. Separate collections contain the two
equipment modules and loose sword. Its `packed-source.json` records the
source-file and runtime snapshot hashes.

This is an editable GLB import snapshot. The earlier retargeting master in
`assets/staging/ileana-mpfb-proof/work/` remains the numerical animation
authority. Arbitrarily re-exporting the snapshot through Blender is not a
claim of byte-for-byte preservation of the accepted motion channels.

Rebuild order:

1. `tools/fetch_character_materials.py` retrieves the licensed sources.
2. Blender runs `prepare_surface_maps.py`, then `repair_costume_seams.py`,
   then `bake_skin_details.py`, under `assets/models/source/characters/`.
3. `tools/build_character_pbr.py` constructs the staged GLBs and shared maps
   and validates the animation/skin preservation contract.
4. `pack_character_pbr_source.py` packs the editable exact-output snapshot.
5. `tools/prepare_character_import_review.py` creates a separate test project
   with the immutable v8 baseline. Import it in Godot, then run
   `tests/render_character_pbr.gd` with an isolated user-data directory
   beginning `/tmp/draconia-character-pbr`.
6. Review the native images before promoting any new candidate. The existing
   native report records the reviewed bytes; running a new test does not
   automatically approve new art.

## Open production work

- The front neckline still has an uneven inner edge, and the rounded binding
  reads as trim rather than a finished tailored collar.
- The cowl rim is visibly stepped at close range. The tunic hem pinches in
  the sampled walking pose, and elbow/sleeve deformation needs a tailored
  mesh and weight pass.
- The face, eyes, hair silhouette and surface response need a final identity
  pass. The braid has no secondary motion.
- Boots retain their prior color texture; a dedicated baked normal/roughness
  set is still needed. Materials shared across the future armor catalog do
  not create the missing fitted armor meshes.
- Lower LODs, material consolidation, target-GPU profiling and full continuous
  animation/contact review remain open. Native software-rendered captures
  prove integration and visible appearance at the inspected poses, not
  target-hardware frame rate or flawless motion.

These limitations are preserved in the runtime manifest. The material pass
improves the running character and establishes a reproducible surface
pipeline without relabeling the development model as finished production art.
