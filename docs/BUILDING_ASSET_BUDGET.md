# Reconstructed building asset structure

## Scope and conclusion

This is a read-only inspection of the eight installed painted-card reconstructions
for checkpoint `0.3.1-card-reconstruction`. Their bytes match the promoted
`assets/models/towns/ashen_crown/manifest.json` and the frozen per-building native
index in `docs/verification-logs/card-reconstruction/native-candidate-set-v1.json`.
No model, material, animation, import setting or runtime code changed during this
inspection.

The inspection found repeated image data across buildings and unusually many
separately animated Water Gate chain links. These are concrete optimization
opportunities. They do **not** establish a loading defect or explain the slow
software-rendered construction test. No target-device performance acceptance
follows from this document.

## Installed scene structure

These are GLB scene nodes, instantiated meshes and full-resolution primitive
surfaces. They are not measured draw calls or rendered-frame triangle counts.

| Building | Scene nodes | Mesh instances | Surfaces | Material definitions | Triangles | Embedded images |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Granary | 3 | 2 | 19 | 16 | 70,442 | 16 |
| Training Yard | 5 | 4 | 22 | 15 | 25,340 | 18 |
| Market | 9 | 8 | 29 | 14 | 62,606 | 12 |
| Smithy | 7 | 6 | 20 | 18 | 41,188 | 15 |
| Oath Hall | 6 | 5 | 25 | 14 | 71,700 | 15 |
| Palisade | 6 | 5 | 25 | 13 | 27,416 | 15 |
| Wharf | 5 | 4 | 18 | 12 | 50,172 | 15 |
| Water Gate | 80 | 79 | 91 | 11 | 59,780 | 13 |
| **Complete catalog** | **121** | **113** | **249** | **113** | **408,644** | **119** |

The eight files total **127,694,128 bytes** and contain **678,009 base mesh
vertices**. Every mesh definition is referenced; there is no unused duplicate
scene mesh in this set.

The complete catalog is not a legal simultaneously constructed town. The Wharf
and Water Gate occupy mutually exclusive alternatives. Including the six common
buildings, the two complete legal branches contain:

| River choice | Building mesh instances | Building surfaces | Building triangles |
| --- | ---: | ---: | ---: |
| Wharf | 34 | 158 | 348,864 |
| Water Gate | 109 | 231 | 358,472 |

These figures exclude the rest of the environment, interface, character,
lighting, effects and shadow rendering.

## Embedded textures

All 119 image records are embedded in the GLBs.

| Image dimensions | Records across the eight assets |
| --- | ---: |
| 512 × 512 | 16 |
| 1024 × 1024 | 84 |
| 1024 × 1026 | 12 |
| 1254 × 1254 | 1 |
| 2048 × 2048 | 6 |
| **Total** | **119** |

The 119 records contain **23 unique byte-identical image payloads**. Their
encoded storage is 100,703,160 bytes; keeping one copy of each unique payload
would store 22,162,216 bytes. The difference, **78,540,944 encoded bytes**, is a
cross-file duplication measurement, not a promised reduction in resident texture
memory.

Wood, iron and sandstone maps recur in all eight assets. Roof maps recur in
seven; the same 2048-square neutral linen albedo is embedded in six. No individual
GLB contains repeated image payloads within itself.

The files have 286 texture descriptors, reducing to 119 distinct descriptors
within their respective files when descriptor names are ignored. Repeated
descriptors reference the same image and sampler; this does not imply 286
separate resident textures.

The 113 material definitions reduce to 38 distinct configurations across the
catalog when names are ignored and image references are normalized by payload
and sampler. Different tint, normal strength and other settings remain distinct.
No individual file contains identical material configurations within itself.

## What the existing native evidence establishes

The final normally imported model reports record texture dimensions and pixel
hashes, mipmaps on every textured channel, and unchanged material descriptors
before and after motion sampling. They also identify shared content across
channels, including packed ARM images used for ambient occlusion, roughness and
metallic data.

Those reports do not record live texture instance IDs or rendering-resource IDs.
They therefore cannot establish whether matching images in different buildings
share a live resource or occupy separate allocations. Distinct extracted texture
paths are consistent with separate file resources; that observation is not a
GPU-memory measurement.

The long construction-test blocks contain loading, UI interaction, screenshot
readback, assertions, animation observations and deliberate waits. Their wall
time cannot be treated as frame time, nor can it identify which of these stages
dominates. A performance claim requires a separate measured run on stated
hardware with an appropriate town branch and camera.

## Bounded optimization work

**Share identical image resources first.** A future import/material revision can
reuse identical wood, stone, iron, roof and linen images while preserving each
material's tint, UV behavior, channel interpretation and normal strength. The
original cards and architectural geometry remain the authority. Compare actual
imported pixels and material settings, then repeat the affected motion and
runtime checks before promoting such a revision.

**Preserve the existing static consolidation.** Seven buildings already use only
two to eight mesh instances; there is no general one-node-per-brick problem.
Market has three static canopy meshes separate from Structure that could be
joined by material without combining the four animated cloth groups. The actual
benefit still needs measurement.

**Treat Water Gate chains as a distinct animation problem.** The two chains use
74 individually animated link meshes, accounting for 74 of the building's 91
surfaces and 8,904 triangles. Its Hover animation contains 230 channels; the other
buildings have three to nine. A deliberate rig or instancing revision may reduce
scene overhead while retaining every link's route. Blindly joining those links
would destroy their current motion and is not an acceptable optimization.

Target-hardware frame timings, resident memory, cold loading, LOD transitions and
continuous visual motion review remain unapproved. This document records asset
structure and next measurement questions; it adds no gameplay test pass or
production-quality score.
