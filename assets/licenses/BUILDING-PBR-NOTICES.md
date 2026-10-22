# Ashen Crown architectural PBR sources

The building geometry, UV layout, mechanisms and hover animation are original
Draconia project work constructed in Blender. The material images listed here
are downloaded **CC0-1.0** assets. The project's source-code license does not
replace those source notices. The complete CC0 text accompanies this file.

| Material source | Creator credit | Original page | Building use |
| --- | --- | --- | --- |
| Rough Wood | Rob Tuytel | https://polyhaven.com/a/rough_wood | Timber beams, boards, doors, docks and wooden props |
| Clay Roof Tiles 02 | Amal Kumar | https://polyhaven.com/a/clay_roof_tiles_02 | Individual modeled clay tiles and ridge pieces |
| Sandstone Cracks | Rob Tuytel | https://polyhaven.com/a/sandstone_cracks | Authored stone blocks and arches |
| Clay Plaster | Amal Kumar | https://polyhaven.com/a/clay_plaster | Oath Hall plaster infill |
| Rough Linen | colormass — photography; Rico Cilliers — processing | https://polyhaven.com/a/rough_linen | Canvas, dyed banners, sacks and small rope surface detail |
| Brown Leather | Rob Tuytel | https://polyhaven.com/a/brown_leather | Smithy bellows |
| Metal012 | Lennart Demes / ambientCG | https://ambientcg.com/a/Metal012 | Iron fittings, tools, bronze-tinted handles and windlasses |

Primary license pages:

- Poly Haven: https://polyhaven.com/license
- ambientCG: https://docs.ambientcg.com/license/
- CC0 legal text: https://creativecommons.org/publicdomain/zero/1.0/legalcode

Poly Haven's asset license applies to its downloaded assets; it does not
license its website text or sample renders as game artwork. Only the actual
downloaded PBR map files are used. Metal012 is described here as a creator
supplied PBR material, without a photography claim.

## Adaptation and preservation

The models use the downloaded albedo, OpenGL normal and packed
occlusion/roughness/metal channels. Original standalone roughness maps are
also retained. Material factors tint dyed cloth, age timber and restrain the
clay palette; the exporter preserves those factors. Source image pixels are
unchanged except the explicitly documented technical metal derivatives:
512-pixel, 8-bit normal conversion and AO/roughness/metal channel packing.
The 1K metal originals remain intact.

Timber UVs follow the length of each board or beam. Stone, plaster, leather
and fine linen use recorded metre-scale source dimensions. Roof UVs select
11 inspected tile interiors from the original image, with the physical mesh
providing seams, curved surfaces and overlap. Sack cloth uses a documented
coarser 0.9 m interpretation of the fine linen weave with cylindrical UVs.
The metal source has no measured size; its 0.5 m repeat is an authored choice.
These decisions are not claims that the original buildings were scanned.

Exact source URLs, original file sizes and SHA-256 values are in
`assets/models/source/towns/pbr-sources/manifest.json` and its `metal012/`
and `runtime/` manifests. The original API metadata, maps, technical
preparation script and a packed editable Blender master are retained in the
optional editable art-source bundle. The runtime GLBs embed their image data
and make no network requests.

`rusty_metal_02` was acquired for inspection and rejected because the painted
sheet-metal appearance did not suit these buildings. It is not incorporated
into any exported building. Fruit, bread, coal and tiny shadow inserts retain
original project materials; this pass does not claim photographic coverage
of every small prop.
