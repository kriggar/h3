# Photograph-derived environment surfaces

These four runtime images were prepared from the user's ground photographs.
They are connected to the actual third-person environment, not merely stored as
unused artwork. All four are 1254 × 1254 PNGs.

| Runtime file | Photograph | In-game use | Tile width |
|---|---|---|---|
| `packed_dirt_albedo.png` | The first pale, gritty ground photo | Road centres and the village square | 1.8 metres |
| `cracked_stone_albedo.png` | The second cracked aggregate/asphalt photo | Ruin faces, waystones, obelisks, rubble and the old seal; adapted to mineral stone | 1.2 metres |
| `meadow_albedo.png` | The third grass and clover photo | Village ground and grassy verges | 1.1 metres |
| `pebble_gravel_albedo.png` | The fourth rounded aggregate photo | Cross paths, the watchhall approach, and market foot traffic | 0.75 metres |

The material implementation is `game/online/environment_materials.gd` and
`game/online/terrain_blend.gdshader`. The terrain uses one shader pass with four
color samples: the three new ground surfaces and the retained deeper-forest
litter. Broad, irregular masks blend paths into the surrounding ground.
Ruined stone uses world-space triplanar mapping. Textures have mipmaps and
anisotropic filtering for angled ground views.

Color maps were prepared with the built-in `image_gen` editing tool. Exact
prompts, source upload identities/hashes, output hashes and the rejected gravel
attempt are recorded in `PROVENANCE.json`; its targeted revision prompt is in
`GRAVEL_REVISION.json`. The original uploads remain unchanged.

This is not a measured photogrammetry scan. Roughness is an authored scalar;
normal, height and displacement maps were not inferred and presented as
measurements. The old unrelated forest normal map is not applied to these new
photographic surfaces. Lighting, geometry, and small ground-cover meshes still
provide the scene's form and depth.

The photos were supplied by the user for this project; rights remain with their
respective owner. The repository's MIT code license and other assets' CC0 notices
do not relicense these photos or derivatives.
