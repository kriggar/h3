#!/usr/bin/env python3
"""Create an isolated native Godot import project for the exact PBR candidate."""
from pathlib import Path
import hashlib
import shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=Path('/tmp/draconia-character-import-review')
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'project.godot').write_text('''config_version=5
[application]
config/name="Draconia Character Material Review"
[display]
window/size/viewport_width=1280
window/size/viewport_height=1000
[rendering]
renderer/rendering_method="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
[draconia]
pbr_import_review=true
''')
for relative in ('assets/models/mara','assets/staging/mara-pbr-v9/candidate'):
    shutil.copytree(ROOT/relative,OUT/relative,dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns('*.import','.gdignore'))
# Keep the comparison reproducible after the accepted candidate is promoted.
# The isolated runtime path deliberately contains the original v8 baseline.
baseline=ROOT/'assets/staging/mara-pbr-v9/accepted-v8/mara.glb'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='753067c5fa7bc0d2e58c482aa861c96dd640aa7ed844e6e1791699fdd16e3fda'
shutil.copy2(baseline,OUT/'assets/models/mara/mara.glb')
for relative in ('game/redesign/hero_appearance.gd','game/redesign/item_rules.gd','tests/render_character_pbr.gd'):
    target=OUT/relative;target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
print(OUT)
