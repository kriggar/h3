# Ashen Crown: eight authored, animated PBR buildings

These original Draconia buildings were constructed in **Blender 4.5.14 LTS**.
They contain physical roof tiles, timber framing, planks, stone courses,
doors, access stairs and working local mechanisms. The licensed PBR maps
are listed in `assets/licenses/BUILDING-PBR-NOTICES.md`; they supplement the
original geometry rather than supplying a photographed building facade.

Canonical IDs are `granary`, `barracks` (training yard), `market`, `smithy`,
`shrine` (secular Oath Hall), `palisade`, `wharf` and `water_gate`. Coordinates
are metres, +Y up and +Z front, with a ground-centred main footprint. Props,
access stairs and docks produce asymmetric bounds. Use the exact rest and
evaluated motion envelopes in `manifest.json`, not a guessed square size.

## Animation contract

Each imported scene has an `AnimationPlayer` at `AnimationPlayer`. Each
contains the exact names `hover` and `RESET`. `hover` spans 0–3.0 seconds at
30 source samples per second. Time 0 and time 3 are identical rest poses.
`RESET` is a constant 1/30-second rest clip covering every animated property
and blend-shape weight. glTF does not encode loop flags: the runtime driver
sets the loop policy. On focus exit or disposal, restore RESET and all
captured rest transforms/weights. No building root or fixed Structure mesh
is animated.

| Building | Authored hover action |
| --- | --- |
| Granary | Door opens inward around its actual hinge pins, then closes |
| Training yard | Pennant deforms below its fixed, tied crossbar |
| Market | Free awning hems move; balance beam tips and the hanging pans counter-rotate |
| Smithy | Hinged bellows top and fitted leather folds perform three compression strokes; door opens inward |
| Oath Hall | Two doors open inward; wall banners move outward from their mounts |
| Palisade | Two inward gates and the mounted pennant move |
| Wharf | Cargo rises 42 cm, the pulley rope shortens and the windlass rotates; shed door opens |
| Water Gate | Portcullis rises 73 cm within its guides; both ropes and the windlass stay connected |

The same unchanged GLB must serve the town and the building card. Cards use
the canonical rest pose and the same material resources. Hover previews may
play the authored clip. Any source geometry/material change requires a fresh
import, review and card/provenance regeneration.

Use 4× MSAA for the town and building-preview viewports. Native comparison
showed that the bridge's narrow, correctly separated plank joints alias into
dots without anti-aliasing. This setting changes rasterization, not source
geometry, materials or the shared-model identity contract.

## Source and review boundary

The packed source is
`assets/models/source/towns/ashen_crown/ashen_crown_master.blend`.
Construction and technical-map preparation scripts, original CC0 maps,
source hashes and final native review evidence are retained in that ignored
authoring tree. Native builds need the GLBs, their manifest, the asset credits
and complete license folder, not Blender or the authoring sources.

The eight GLBs contain **113,860 triangles and 77,551,936 bytes**. Their PBR
images are embedded. This is a reviewed development art/animation pass.
Worker AI, production simulation, smoke/spark systems, upgrade variants,
full capital composition, close-camera prop sculpting and LOD/populated-town
performance acceptance remain separate work. Tiny fruit and coal props are
still original simple materials; wood end sections and stone bevel/wear
variation, faceted fruit/sacks, LODs and target-GPU performance need further
refinement. No flawless or complete nine-town claim
is made.
