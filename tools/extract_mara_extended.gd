extends SceneTree
## Convert the temporary Blender transfer GLB into a skeleton-only library.
## Run: godot --headless --path . --script res://tools/extract_mara_extended.gd --
##   --input=/tmp/mara-motion-bake/mara_extended.glb
##   --output=res://assets/online/animations/mara_extended.tres

const MODEL := "res://assets/models/mara/mara.glb"
const NAMES := ["jump_start", "jump_loop", "jump_land", "interact", "hit_head", "sprint"]
const LOOPS := ["jump_loop", "sprint"]
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func _find_type(node: Node, kind: String) -> Node:
    if node.is_class(kind):
        return node
    for child in node.get_children():
        var found := _find_type(child, kind)
        if found != null:
            return found
    return null

func _find_boots(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and "LeatherBoots" in String(node.name):
        return node
    for child in node.get_children():
        var found := _find_boots(child)
        if found != null:
            return found
    return null

func _boot_data(mesh: MeshInstance3D, skeleton: Skeleton3D) -> Dictionary:
    var surfaces: Array = []
    var bindings: Array = []
    for index in range(mesh.mesh.get_surface_count()):
        var arrays := mesh.mesh.surface_get_arrays(index)
        surfaces.append({"v": arrays[Mesh.ARRAY_VERTEX], "b": arrays[Mesh.ARRAY_BONES], "w": arrays[Mesh.ARRAY_WEIGHTS]})
    for index in range(mesh.skin.get_bind_count()):
        var bone := skeleton.find_bone(mesh.skin.get_bind_name(index))
        if bone < 0:
            bone = mesh.skin.get_bind_bone(index)
        check(bone >= 0, "Original native boot bind must resolve")
        bindings.append({"bone": bone, "pose": mesh.skin.get_bind_pose(index)})
    return {"surfaces": surfaces, "bindings": bindings}

func _lowest_boot(data: Dictionary, skeleton: Skeleton3D) -> float:
    skeleton.force_update_all_bone_transforms()
    var transforms: Array[Transform3D] = []
    for binding in data.bindings:
        transforms.append(skeleton.get_bone_global_pose(binding.bone) * binding.pose)
    var lowest := INF
    for surface in data.surfaces:
        var influences: int = surface.b.size() / surface.v.size()
        for vertex in range(surface.v.size()):
            var point := Vector3.ZERO
            for influence in range(influences):
                var index: int = vertex * influences + influence
                var amount: float = surface.w[index]
                if amount > 0.0:
                    point += (transforms[surface.b[index]] * surface.v[vertex]) * amount
            lowest = minf(lowest, point.y)
    return lowest

func _compact_tracks(animation: Animation) -> void:
    for track in range(animation.get_track_count()):
        # Retain original 24 fps key times, not interpolated import samples.
        # The temporary 120 fps importer rate preserves every source contact.
        for key in range(animation.track_get_key_count(track) - 2, 0, -1):
            var frame := animation.track_get_key_time(track, key) * 24.0
            if absf(frame - roundf(frame)) > 0.00002:
                animation.track_remove_key(track, key)
        var first: Variant = animation.track_get_key_value(track, 0)
        var constant := true
        for key in range(1, animation.track_get_key_count(track)):
            var value: Variant = animation.track_get_key_value(track, key)
            if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
                constant = constant and absf(value.x - first.x) < 0.000001 and absf(value.y - first.y) < 0.000001 and absf(value.z - first.z) < 0.000001 and absf(value.w - first.w) < 0.000001
            else:
                constant = constant and value.distance_to(first) < 0.000001
        if constant:
            for key in range(animation.track_get_key_count(track) - 1, 0, -1):
                animation.track_remove_key(track, key)
        elif animation.loop_mode == Animation.LOOP_LINEAR:
            # Source Sprint_Loop has a 0.65-degree left-arm endpoint mismatch.
            # Close that final pose explicitly; keep all earlier authored keys.
            animation.track_set_key_value(track, animation.track_get_key_count(track) - 1, first)

func _correct_native_floor(animation: Animation, name: String, player: AnimationPlayer,
        skeleton: Skeleton3D, boots: Dictionary, skeleton_path: String) -> Dictionary:
    var root_track := animation.find_track(NodePath(skeleton_path + ":Root"), Animation.TYPE_POSITION_3D)
    var root_bone := skeleton.find_bone("Root")
    var frames := int(round(animation.length * 120.0))
    var points: Array[Vector3] = []
    var offsets: Array[float] = []
    var minimum := INF
    var maximum_offset := 0.0
    player.play("motion_bake/" + name)
    player.speed_scale = 0.0
    for frame in range(frames + 1):
        var time := minf(frame / 120.0, animation.length - 0.000001)
        player.seek(time, true)
        player.advance(0.0)
        var low := _lowest_boot(boots, skeleton)
        var offset := maxf(0.002 - low, 0.0)
        minimum = minf(minimum, low)
        maximum_offset = maxf(maximum_offset, offset)
        points.append(skeleton.get_bone_pose_position(root_bone))
        offsets.append(offset)
    # Sprint uses one constant offset so its original flight and weight transfer
    # remain intact. Other grounded poses only receive local clearance fixes.
    for key in range(animation.track_get_key_count(root_track) - 1, -1, -1):
        animation.track_remove_key(root_track, key)
    for frame in range(frames + 1):
        var offset: float = maximum_offset if name == "sprint" else offsets[frame]
        var point: Vector3 = points[frame] + Vector3(0, offset, 0)
        if frame == frames and animation.loop_mode == Animation.LOOP_LINEAR:
            point = points[0] + Vector3(0, maximum_offset if name == "sprint" else offsets[0], 0)
        animation.track_insert_key(root_track, frame / 120.0, point)
    return {"minimum_native_sole_before": minimum, "maximum_correction_metres": maximum_offset,
        "correction_sample_rate": 120, "method": "constant offset preserving flight" if name == "sprint" else "minimum 2 mm native skinned sole clearance"}

func _run() -> void:
    var source := "/tmp/mara-motion-bake/mara_extended.glb"
    var destination := "res://assets/online/animations/mara_extended.tres"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--input="):
            source = argument.trim_prefix("--input=")
        if argument.begins_with("--output="):
            destination = argument.trim_prefix("--output=")
    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var result := document.append_from_file(source, state)
    check(result == OK, "Cannot read transfer GLB: " + str(result))
    if result != OK:
        quit(1)
        return
    # 120 is an exact multiple of the 24 fps authored clips. The default 30
    # resamples away contact keys and creates a small seam on 16-frame sprint.
    var transfer := document.generate_scene(state, 120, false, false)
    var model := load(MODEL).instantiate() as Node3D
    root.add_child(transfer)
    root.add_child(model)
    var skeleton := _find_type(transfer, "Skeleton3D") as Skeleton3D
    var target := _find_type(model, "Skeleton3D") as Skeleton3D
    var player := _find_type(transfer, "AnimationPlayer") as AnimationPlayer
    check(skeleton != null and target != null and player != null, "Missing animation source or target skeleton")
    if skeleton == null or target == null or player == null:
        transfer.free()
        model.free()
        quit(1)
        return
    check(skeleton.get_bone_count() == 53, "Transfer must have all 53 original Mara bones")
    check(target.get_bone_count() == 53, "Target changed from the accepted 53-bone rig")
    var max_rest_error := 0.0
    for index in range(target.get_bone_count()):
        var bone_name := target.get_bone_name(index)
        var source_index := skeleton.find_bone(bone_name)
        check(source_index >= 0, "Missing source bone " + bone_name)
        if source_index < 0:
            continue
        var original := target.get_bone_rest(index)
        var imported := skeleton.get_bone_rest(source_index)
        max_rest_error = maxf(max_rest_error, original.origin.distance_to(imported.origin))
        for axis in range(3):
            max_rest_error = maxf(max_rest_error, original.basis[axis].distance_to(imported.basis[axis]))
    check(max_rest_error < 0.00002, "Rest rig differs from Mara: " + str(max_rest_error))
    var library := AnimationLibrary.new()
    var clips: Array[Dictionary] = []
    print("TRANSFER_CLIPS ", player.get_animation_list())
    var target_path := String(model.get_path_to(target))
    for clip_name in NAMES:
        var source_name: String = clip_name
        if not player.has_animation(source_name):
            # Godot's import naming conventions may remove a loop suffix.
            source_name = clip_name.trim_suffix("_loop")
        check(player.has_animation(source_name), "Missing requested clip " + clip_name)
        if not player.has_animation(source_name):
            continue
        var animation := player.get_animation(source_name).duplicate(true) as Animation
        animation.resource_name = clip_name
        animation.loop_mode = Animation.LOOP_LINEAR if clip_name in LOOPS else Animation.LOOP_NONE
        var rotation_bones: Array[String] = []
        var key_count := 0
        for index in range(animation.get_track_count() - 1, -1, -1):
            var path := animation.track_get_path(index)
            var kind := animation.track_get_type(index)
            if kind not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D] or path.get_subname_count() != 1:
                animation.remove_track(index)
                continue
            var bone_name := String(path.get_subname(0))
            check(target.find_bone(bone_name) >= 0, "Unknown target bone " + bone_name)
            animation.track_set_path(index, NodePath(target_path + ":" + bone_name))
            if kind == Animation.TYPE_ROTATION_3D:
                rotation_bones.append(bone_name)
            for key in range(animation.track_get_key_count(index)):
                var value: Variant = animation.track_get_key_value(index, key)
                check(value.is_finite(), "Nonfinite transform in " + clip_name + ":" + bone_name)
                if kind == Animation.TYPE_ROTATION_3D:
                    check(absf(value.length() - 1.0) < 0.0001, "Unnormalized quaternion in " + clip_name + ":" + bone_name)
                key_count += 1
        # The glTF importer drops channels identical to the rest pose. Restore
        # those constants explicitly so a clip never inherits a changed finger,
        # clavicle or root transform from the previously playing animation.
        for bone_index in range(target.get_bone_count()):
            var bone_name := String(target.get_bone_name(bone_index))
            var path := NodePath(target_path + ":" + bone_name)
            var rest := target.get_bone_rest(bone_index)
            for kind in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
                if animation.find_track(path, kind) >= 0:
                    continue
                var track := animation.add_track(kind)
                animation.track_set_path(track, path)
                var value: Variant = rest.origin
                if kind == Animation.TYPE_ROTATION_3D:
                    value = rest.basis.get_rotation_quaternion().normalized()
                    rotation_bones.append(bone_name)
                elif kind == Animation.TYPE_SCALE_3D:
                    value = rest.basis.get_scale()
                animation.track_insert_key(track, 0.0, value)
                key_count += 1
        check(rotation_bones.size() == 53, "Missing full-rig rotation tracks in " + clip_name)
        check(animation.length > 0.0, "Empty clip " + clip_name)
        _compact_tracks(animation)
        library.add_animation(clip_name, animation)
        clips.append({"name": clip_name, "duration": animation.length,
            "loop": animation.loop_mode == Animation.LOOP_LINEAR,
            "tracks": animation.get_track_count(), "keys": key_count})
    check(library.get_animation_list().size() == NAMES.size(), "Incomplete supplementary library")
    var target_player := _find_type(model, "AnimationPlayer") as AnimationPlayer
    target_player.add_animation_library("motion_bake", library)
    var boots := _boot_data(_find_boots(model), target)
    for clip in clips:
        var animation := library.get_animation(clip.name)
        clip["native_floor"] = _correct_native_floor(animation, clip.name, target_player, target, boots, target_path)
        var key_count := 0
        for track in range(animation.get_track_count()):
            key_count += animation.track_get_key_count(track)
        clip["keys"] = key_count
    target_player.remove_animation_library("motion_bake")
    if failures.is_empty():
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
        check(ResourceSaver.save(library, destination) == OK, "Could not save native animation library")
    var report := {"passed": failures.is_empty(), "failures": failures,
        "mara_source_sha256": FileAccess.get_sha256(MODEL),
        "transfer_sha256": FileAccess.get_sha256(source),
        "library_sha256": FileAccess.get_sha256(destination) if failures.is_empty() else "",
        "target_skeleton_path": target_path, "target_bones": target.get_bone_count(),
        "maximum_rest_error": max_rest_error, "clips": clips}
    var report_path := source.get_basename() + "-import.json"
    var report_file := FileAccess.open(report_path, FileAccess.WRITE)
    report_file.store_string(JSON.stringify(report, "  ") + "\n")
    report_file.close()
    print(JSON.stringify(report))
    transfer.free()
    model.free()
    quit(0 if failures.is_empty() else 1)
