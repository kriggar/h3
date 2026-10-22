extends SceneTree
## Run with a native display. Outputs are provisional until the Python wrapper
## binds them to the actual Blender source and atomically installs the manifest.

const Visuals = preload("res://game/redesign/building_visuals.gd")
const Studio = preload("res://game/redesign/building_card_studio.gd")
var failures: Array[String] = []
var checks: int = 0
var output_dir: String = ""
var ids: Array[String] = []
var resolution: int = 512
var treatment: String = "raw"
var repeat_first: bool = false
var azimuth_offset: float = 0.0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("BUILDING IDENTITY: " + message)
	return condition

func _arguments() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
		elif argument.begins_with("--ids="):
			for building_id: String in argument.trim_prefix("--ids=").split(",",false):
				ids.append(building_id)
		elif argument.begins_with("--size="):
			resolution = int(argument.trim_prefix("--size="))
		elif argument.begins_with("--treatment="):
			treatment = argument.trim_prefix("--treatment=")
		elif argument == "--verify-repeat":
			repeat_first = true
		elif argument.begins_with("--azimuth-offset="):
			azimuth_offset=float(argument.trim_prefix("--azimuth-offset="))
		else:
			return false
	if ids.is_empty():
		ids.assign(Visuals.IDS)
	return output_dir.is_absolute_path() and resolution >= 128 and resolution <= 2048 and treatment in ["raw","pigment"]

func _mesh_resources(node: Node, result: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var materials: Array = []
		for index: int in range(node.mesh.get_surface_count()):
			materials.append(node.get_active_material(index))
		result.append({"mesh":node.mesh,"materials":materials})
	for child: Node in node.get_children():
		_mesh_resources(child,result)

func _run() -> void:
	if not _arguments():
		push_error("Expected --output-dir=/absolute/path [--ids=granary,...] [--size=512] [--treatment=raw|pigment] [--verify-repeat]")
		quit(2)
		return
	if DisplayServer.get_name() == "headless":
		push_error("This test requires native rendering; headless dummy pixels are not accepted.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	var references: Node3D = Node3D.new()
	references.name = "TownFactoryIdentityReferences"
	root.add_child(references)
	_check(Visuals.create("not_a_registered_building",references) == null,"unknown building cannot instantiate a substitute")
	_check(Visuals.definition("../granary").is_empty(),"registry cannot accept an arbitrary scene path")
	var results: Dictionary = {}
	for building_id: String in ids:
		var entry: Dictionary = Visuals.definition(building_id)
		if not _check(not entry.is_empty(),building_id+": registered visual identity"):
			continue
		var town: Node3D = Visuals.create(building_id,references)
		var duplicate: Node3D = Visuals.create(building_id,references)
		if not _check(town != null and duplicate != null,building_id+": both factory instances load the source GLB"):
			continue
		var signature: Dictionary = Visuals.signature(town)
		_check(str(signature.instantiatedScenePath) == str(entry.scenePath),building_id+": actual PackedScene path equals registry path")
		_check(signature == Visuals.signature(duplicate),building_id+": independent instances have identical geometry, materials and bounds")
		var town_resources: Array = []
		var card_resources: Array = []
		_mesh_resources(town,town_resources)
		_mesh_resources(duplicate,card_resources)
		_check(not town_resources.is_empty() and town_resources == card_resources,building_id+": instances retain the same imported mesh/material resources")
		town.position = Vector3(12,2,-8)
		town.rotation.y = 0.7
		_check(signature == Visuals.signature(town),building_id+": town placement does not rewrite source identity")
		var result: Dictionary = await Studio.render_card(root,building_id,resolution,treatment,azimuth_offset)
		if not _check(bool(result.get("ok",false)),building_id+": native card validates: "+str(result.get("reason",""))):
			town.queue_free()
			duplicate.queue_free()
			continue
		_check(signature == result.signature,building_id+": town factory and native card use identical source geometry/materials")
		_check(bool(result.sourceUnchanged) and bool(result.alphaMatchesRaw),building_id+": render/treatment preserves model and exact alpha silhouette")
		var raw_path: String = output_dir.path_join(building_id+".raw.png")
		var card_path: String = output_dir.path_join(building_id+".png")
		_check(result.rawImage.save_png(raw_path) == OK and result.image.save_png(card_path) == OK,building_id+": both native images saved")
		result.erase("image")
		result.erase("rawImage")
		result["cardFile"] = building_id+".png"
		result["rawCardFile"] = building_id+".raw.png"
		result["cardSha256"] = FileAccess.get_sha256(card_path)
		result["rawCardSha256"] = FileAccess.get_sha256(raw_path)
		if repeat_first and results.is_empty():
			var again: Dictionary = await Studio.render_card(root,building_id,resolution,treatment,azimuth_offset)
			var repeated_path: String = output_dir.path_join(building_id+".repeat.png")
			var repeated: bool = bool(again.get("ok",false)) and again.image.save_png(repeated_path) == OK and FileAccess.get_sha256(repeated_path) == str(result.cardSha256)
			_check(repeated,building_id+": repeated native render has identical pixels in this renderer")
			result["repeatPixelsMatch"] = repeated
		results[building_id] = result
		print("BUILDING_CARD ",JSON.stringify({"id":building_id,"geometrySha256":signature.geometrySha256,"materialSha256":signature.materialSha256,"alpha":result.alpha,"cardSha256":result.cardSha256}))
		town.queue_free()
		duplicate.queue_free()
		await process_frame
	var report: Dictionary = {"schemaVersion":1,"pipelineVersion":Studio.PIPELINE_VERSION,"checks":checks,"failures":failures,"renderedBuildings":results,"scope":"Native same-model card pipeline proof; not production-art or nine-town acceptance."}
	var file: FileAccess = FileAccess.open(output_dir.path_join("native-report.json"),FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"\t",true,true)+"\n")
		file.close()
	else:
		failures.append("native report could not be written")
	references.queue_free()
	await process_frame
	await process_frame
	print("BUILDING_CARD_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"buildings":results.size(),"report":output_dir.path_join("native-report.json")}))
	quit(0 if failures.is_empty() and results.size() == ids.size() else 1)
