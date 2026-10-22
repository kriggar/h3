extends SceneTree
const World = preload("res://game/online/world.gd")
const Realm = preload("res://game/online/realm.gd")
var world: Node3D
var realm: RefCounted
var output := "/tmp/draconia-third-person-world"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="):output=arg.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1440,900)
	realm=Realm.new()
	realm.add_player(1,"Mara Veyne")
	world=World.new()
	world.controls_enabled=false
	root.add_child(world)
	world.set_snapshot(realm.snapshot(),1)
	for i: int in range(12):await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/third-person-town.png")
	var p: Dictionary=realm.state.players["1"]
	p.pos=[0.0,0.0,-5.0]
	p.pos[1]=preload("res://game/online/catalog.gd").ground_y(0,-5)
	world.set_snapshot(realm.snapshot(),1)
	for i: int in range(15):await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/third-person-road.png")
	print("WORLD_PROBE_READY ",world.actors.size()," actors; camera perspective=",world.camera.projection==Camera3D.PROJECTION_PERSPECTIVE)
	quit()
