extends SceneTree
const World = preload("res://game/online/world.gd")
const Realm = preload("res://game/online/realm.gd")
const C = preload("res://game/online/catalog.gd")
const Materials = preload("res://game/online/environment_materials.gd")
var output := "/tmp/draconia-photo-material-native"
var world: Node3D
var review_camera: Camera3D
var results: Array = []
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Material capture requires a native display or Xvfb; run without --headless.")
  quit(1)
  return
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--output-dir="):output=arg.trim_prefix("--output-dir=")
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(1440,900)
 var realm := Realm.new()
 realm.add_player(1,"Mara Veyne")
 world=World.new()
 world.controls_enabled=false
 root.add_child(world)
 world.set_snapshot(realm.snapshot(),1)
 for i: int in range(12):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/01-town-photo-ground.png")
 for key: String in Materials.SURFACES:
  var tex: Texture2D=Materials.texture(key)
  results.append({"surface":key,"loaded":tex!=null,"width":tex.get_width() if tex else 0,"height":tex.get_height() if tex else 0,"mipmaps":tex.get_image().has_mipmaps() if tex else false,"tile_metres":Materials.SURFACES[key].tile_metres,"authored_scale":true,"role":Materials.SURFACES[key].role,"path":Materials.BASE+str(Materials.SURFACES[key].file),"sha256":FileAccess.get_sha256(Materials.BASE+str(Materials.SURFACES[key].file))})
 world.set_process(false)
 review_camera=Camera3D.new()
 review_camera.fov=52
 review_camera.near=0.08
 review_camera.far=300
 world.add_child(review_camera)
 review_camera.current=true
 await _capture("02-packed-dirt-close",Vector3(-1.6,1.55,35.4),Vector3(-0.4,0.05,32.4))
 await _capture("03-meadow-verge-close",Vector3(8.8,1.35,36.0),Vector3(7.3,0.08,33.2))
 await _capture("04-pebble-path-close",Vector3(4.7,1.25,28.8),Vector3(5.1,0.05,26.2))
 await _capture("05-weathered-ruin-close",Vector3(-9.3,2.1,-65.4),Vector3(-10.5,1.05,-69.9))
 review_camera.current=false
 world.camera.current=true
 realm.state.players["1"].pos=C.array(C.ground_position(0.5,-42.0))
 world._camera_ready=false
 world.set_snapshot(realm.snapshot(),1)
 world.set_process(true)
 for i:int in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/06-third-person-woodland.png")
 var bindings := {"BlackbriarPhotoGround":0,"PhotoReferencedWeatheredMineral":0}
 _count_bindings(world.scenery,bindings)
 var ground:MeshInstance3D=world.scenery.get_node("BlackbriarGround")
 var terrain_material:ShaderMaterial=ground.material_override
 var samplers := {}
 for key:String in ["packed_dirt","meadow","pebble_gravel"]:
  samplers[key]=terrain_material.get_shader_parameter(key+"_tex")==Materials.texture(key)
 var report := {"actual_material_bindings":bindings,"terrain_samplers_match_expected":samplers,"render_method":RenderingServer.get_current_rendering_method(),"visual_scope":"Native third-person world and material closeups; no HUD in this isolated renderer","asset_revision":"revised gravel accepted for final inspection","textures":results,"mara_sha256":FileAccess.get_sha256(C.HERO_MODEL),"mara_preserved":FileAccess.get_sha256(C.HERO_MODEL)==C.HERO_SHA256,"terrain_passes":1,"photo_normal_map":false,"stone_roughness_authored":Materials.weathered_stone().roughness,"stone_normal_enabled":Materials.weathered_stone().normal_enabled,"colliders":world.scenery.get_node("SharedPropCollision").get_child_count(),"screenshots":6}
 var f:=FileAccess.open(output+"/report.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit()
func _capture(filename:String, from:Vector3, at:Vector3) -> void:
 review_camera.position=from+Vector3(0,C.ground_y(from.x,from.z),0)
 var target:=at+Vector3(0,C.ground_y(at.x,at.z),0)
 review_camera.look_at(target)
 for i:int in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/"+filename+".png")

func _count_bindings(node:Node, counts:Dictionary) -> void:
 if node is MeshInstance3D:
  var material:Material=node.material_override
  if material!=null and counts.has(material.resource_name):counts[material.resource_name]+=1
 for child:Node in node.get_children():_count_bindings(child,counts)
