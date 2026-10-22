"""Read-only camera study of a staged Blend; never edits source/card/model.

Usage: Blender --background --python this.py -- granary
Saved images are secondary camera evidence, not replacement card art.
"""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:]
key=args[0]
if key not in ['granary','shrine']:raise ValueError('Scoped camera study requires granary or shrine')
candidate=ROOT/'assets/staging/card-reconstruction'/key
bpy.ops.wm.open_mainfile(filepath=str(candidate/(key+'.blend')))
scene=bpy.context.scene;camera=scene.camera
camera.data.type='PERSP';camera.data.lens=44
target=Vector((.25,-.45,2.70 if key=='shrine' else 2.35))
camera.location=Vector((9.,-15.,4.35 if key=='shrine' else 3.8))
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1300;scene.render.resolution_y=1100
scene.cycles.samples=32;scene.render.film_transparent=True
out=Path('/tmp/draconia-card-perspective')
out.mkdir(parents=True,exist_ok=True)
scene.render.filepath=str(out/(key+'-low-perspective.png'))
bpy.ops.render.render(write_still=True)
(out/(key+'-camera.json')).write_text(json.dumps({'sourceBlend':str(candidate/(key+'.blend')),'camera':{'type':'perspective','focalLengthMillimetres':44,'location':list(camera.location),'target':list(target)},'scope':'Read-only camera study; no asset, painting or native game scene changed'},indent=2)+'\n')
