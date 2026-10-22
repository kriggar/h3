extends SceneTree
## Inspect new animation assets on the unchanged, actually skinned Mara mesh.
## The standard native review runner owns the display and isolated save paths.
const MODEL := preload("res://assets/models/mara/mara.glb")
const LIBRARY := preload("res://assets/online/animations/mara_extended.tres")
const NAMES := ["jump_start", "jump_loop", "jump_land", "interact", "hit_head", "sprint"]
const ARMED := ["hit_head", "sprint"]
var output := "/tmp/draconia-extended-motion-review"
var checks := 0
var failures: Array[String] = []
var bodies: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var skeletons: Array[Skeleton3D] = []
var title: Label
var subtitle: Label
var stage: Node3D

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures.append(message)
        push_error(message)

func _find_mesh(node: Node, part: String) -> MeshInstance3D:
    if node is MeshInstance3D and part in String(node.name):
        return node
    for child in node.get_children():
        var found := _find_mesh(child, part)
        if found != null:
            return found
    return null

func _skin_data(mesh: MeshInstance3D, skeleton: Skeleton3D) -> Dictionary:
    var surfaces: Array[Dictionary] = []
    var bindings: Array[Dictionary] = []
    for index in range(mesh.mesh.get_surface_count()):
        var arrays := mesh.mesh.surface_get_arrays(index)
        surfaces.append({"v": arrays[Mesh.ARRAY_VERTEX], "b": arrays[Mesh.ARRAY_BONES], "w": arrays[Mesh.ARRAY_WEIGHTS]})
    for index in range(mesh.skin.get_bind_count()):
        var bone := skeleton.find_bone(mesh.skin.get_bind_name(index))
        if bone < 0:
            bone = mesh.skin.get_bind_bone(index)
        check(bone >= 0, "Skin bind resolves on original Mara")
        bindings.append({"bone": bone, "pose": mesh.skin.get_bind_pose(index)})
    return {"surfaces": surfaces, "bindings": bindings}

func _skin_min(data: Dictionary, skeleton: Skeleton3D) -> Dictionary:
    skeleton.force_update_all_bone_transforms()
    var transforms: Array[Transform3D] = []
    for binding in data.bindings:
        transforms.append(skeleton.get_bone_global_pose(binding.bone) * binding.pose)
    var lowest := INF
    var highest := -INF
    var left := INF
    var right := INF
    for surface in data.surfaces:
        var influences: int = surface.b.size() / surface.v.size()
        for vertex in range(surface.v.size()):
            var point := Vector3.ZERO
            var left_weight := 0.0
            var right_weight := 0.0
            for influence in range(influences):
                var index: int = vertex * influences + influence
                var amount: float = surface.w[index]
                if amount <= 0.0:
                    continue
                var bind_index: int = surface.b[index]
                point += (transforms[bind_index] * surface.v[vertex]) * amount
                var name := String(skeleton.get_bone_name(data.bindings[bind_index].bone))
                if name.ends_with("_l"):
                    left_weight += amount
                if name.ends_with("_r"):
                    right_weight += amount
            lowest = minf(lowest, point.y)
            highest = maxf(highest, point.y)
            if left_weight > right_weight:
                left = minf(left, point.y)
            else:
                right = minf(right, point.y)
    return {"minimum": lowest, "maximum": highest, "left": left, "right": right}

func _seek(player: AnimationPlayer, name: String, time: float) -> void:
    player.play("extended/" + name)
    player.speed_scale = 0.0
    player.seek(time, true)
    player.advance(0.0)

func _add_stage() -> void:
    stage = Node3D.new()
    root.add_child(stage)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("191e25")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("a0b3ce")
    environment.environment.ambient_light_energy = 0.65
    stage.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-48, -32, 0)
    light.light_color = Color("ffe4bd")
    light.light_energy = 1.4
    light.shadow_enabled = true
    stage.add_child(light)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25, 140, 0)
    fill.light_color = Color("b9d3ee")
    fill.light_energy = 0.6
    stage.add_child(fill)
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(20, 20)
    floor.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("30353b")
    material.roughness = 0.94
    floor.material_override = material
    stage.add_child(floor)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.15
    camera.position = Vector3(0, 2.1, 8)
    stage.add_child(camera)
    camera.look_at(Vector3(0, 0.85, 0))
    camera.current = true
    var canvas := CanvasLayer.new()
    stage.add_child(canvas)
    title = Label.new()
    title.position = Vector2(36, 25)
    title.add_theme_font_size_override("font_size", 28)
    title.modulate = Color("e2d1ad")
    canvas.add_child(title)
    subtitle = Label.new()
    subtitle.position = Vector2(36, 65)
    subtitle.add_theme_font_size_override("font_size", 17)
    subtitle.modulate = Color("c7d2dd")
    canvas.add_child(subtitle)
    for index in range(4):
        var model := MODEL.instantiate() as Node3D
        model.position.x = (index - 1.5) * 1.22
        model.rotation.y = -0.25
        stage.add_child(model)
        var player := model.get_node("AnimationPlayer") as AnimationPlayer
        player.add_animation_library("extended", LIBRARY)
        player.speed_scale = 0.0
        bodies.append(model)
        players.append(player)
        skeletons.append(model.get_node("IleanaRig/Skeleton3D") as Skeleton3D)
        var label := Label.new()
        label.text = "PHASE %02d%%" % int([0.0, 0.2, 0.5, 0.85][index] * 100)
        label.position = Vector2(190 + index * 282, 790)
        label.add_theme_font_size_override("font_size", 18)
        label.modulate = Color("b9c5d2")
        canvas.add_child(label)

func _run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output = argument.trim_prefix("--output-dir=")
    DirAccess.make_dir_recursive_absolute(output)
    root.size = Vector2i(1440, 900)
    _add_stage()
    await process_frame
    var skeleton := skeletons[0]
    var boots := _find_mesh(bodies[0], "LeatherBoots")
    var sword := _find_mesh(bodies[0], "Mara_Sword")
    check(boots != null and sword != null, "Original skinned boots and sword are available")
    var boot_data := _skin_data(boots, skeleton)
    var sword_data := _skin_data(sword, skeleton)
    var reports: Array[Dictionary] = []
    for clip_name: String in NAMES:
        var animation := LIBRARY.get_animation(clip_name)
        var samples: Array[Dictionary] = []
        var lowest_boot := INF
        var highest_boot := -INF
        var lowest_sword := INF
        var previous_rotations: Array[Quaternion] = []
        var maximum_step_radians := 0.0
        var frames := int(ceil(animation.length * 120.0))
        for frame in range(frames + 2):
            # Half-sample offset checks interpolation between the calibration
            # keys instead of merely replaying the same bake sample positions.
            var time := minf(maxf(frame - 0.5, 0.0) / 120.0, animation.length - 0.000001)
            _seek(players[0], clip_name, time)
            var rotations: Array[Quaternion] = []
            for bone in range(skeleton.get_bone_count()):
                var position := skeleton.get_bone_pose_position(bone)
                var rotation := skeleton.get_bone_pose_rotation(bone)
                var scale := skeleton.get_bone_pose_scale(bone)
                check(position.is_finite() and rotation.is_finite() and scale.is_finite(), "Finite native bone transform")
                check(absf(rotation.length() - 1.0) < 0.0005, "Normalized native quaternion")
                rotations.append(rotation)
                if not previous_rotations.is_empty():
                    maximum_step_radians = maxf(maximum_step_radians, rotation.angle_to(previous_rotations[bone]))
            previous_rotations = rotations
            var sole := _skin_min(boot_data, skeleton)
            var blade := _skin_min(sword_data, skeleton)
            lowest_boot = minf(lowest_boot, sole.minimum)
            highest_boot = maxf(highest_boot, sole.minimum)
            lowest_sword = minf(lowest_sword, blade.minimum)
            var left_ankle := skeleton.get_bone_global_pose(skeleton.find_bone("foot_l")).origin
            var right_ankle := skeleton.get_bone_global_pose(skeleton.find_bone("foot_r")).origin
            var left_hand := skeleton.get_bone_global_pose(skeleton.find_bone("hand_l")).origin
            var right_hand := skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).origin
            var pelvis := skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin
            samples.append({"time": time, "left_sole": sole.left, "right_sole": sole.right,
                "lowest_sword": blade.minimum, "left_ankle": [left_ankle.x, left_ankle.y, left_ankle.z],
                "right_ankle": [right_ankle.x, right_ankle.y, right_ankle.z],
                "left_hand": [left_hand.x, left_hand.y, left_hand.z],
                "right_hand": [right_hand.x, right_hand.y, right_hand.z],
                "pelvis": [pelvis.x, pelvis.y, pelvis.z]})
        check(lowest_boot >= 0.0, "Native boot soles remain above the floor between calibration samples: " + clip_name)
        if clip_name in ARMED:
            check(lowest_sword > 0.02, "Native armed clip keeps sword clear of floor: " + clip_name)
        var loop_difference := 0.0
        if animation.loop_mode == Animation.LOOP_LINEAR:
            _seek(players[0], clip_name, 0.0)
            var first: Array[Quaternion] = []
            for bone in range(skeleton.get_bone_count()):
                first.append(skeleton.get_bone_pose_rotation(bone))
            _seek(players[0], clip_name, animation.length - 0.000001)
            for bone in range(skeleton.get_bone_count()):
                loop_difference = maxf(loop_difference, first[bone].angle_to(skeleton.get_bone_pose_rotation(bone)))
            check(loop_difference < 0.003, "Native loop seam is continuous: " + clip_name)
        reports.append({"name": clip_name, "duration": animation.length,
            "native_minimum_sole_metres": lowest_boot, "native_peak_lowest_sole_metres": highest_boot,
            "native_minimum_sword_metres": lowest_sword, "loop_rotation_difference_radians": loop_difference,
            "maximum_frame_rotation_radians_at_120fps": maximum_step_radians, "samples": samples})
        title.text = "DRACONIA / MARA  ·  " + clip_name.to_upper().replace("_", " ")
        subtitle.text = "Actual Godot capture · original 53-bone character · licensed Quaternius motion retarget · %.3f s" % animation.length
        for index in range(4):
            _seek(players[index], clip_name, float([0.0, 0.2, 0.5, 0.85][index]) * animation.length)
            _find_mesh(bodies[index], "Mara_Sword").visible = clip_name in ARMED
            bodies[index].position.y = 0.2 if clip_name == "jump_loop" else 0.0
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png(output + "/" + clip_name + ".png") == OK,
            "Native pose review capture: " + clip_name)
    var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures,
        "clips": reports, "mara_sha256": FileAccess.get_sha256("res://assets/models/mara/mara.glb"),
        "library_sha256": FileAccess.get_sha256("res://assets/online/animations/mara_extended.tres"),
        "method": "Native Godot skeletal playback at 120 samples/s with half-sample offset; exact original CPU-skinned boot and blade vertices; real rendered pose sheets."}
    var file := FileAccess.open(output + "/acceptance.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    print("EXTENDED_MOTION_ACCEPTANCE ", JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures}))
    stage.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
