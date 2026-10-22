extends SceneTree
## Actual world/HUD/session capture with scripted input, not pose injection.
## The Python runner supplies an isolated user directory and --fixed-fps=20.
const C := preload("res://game/online/catalog.gd")
const FPS := 20
const DURATION := 16.0
var output := "/tmp/draconia-gameplay-motion"
var capture_frames := true
var game: Node3D
var caption: Label
var detail: Label
var samples: Array[Dictionary] = []
var events: Array[Dictionary] = []
var failures: Array[String] = []
var checks := 0
var timeline_time := 0.0
var issued: Dictionary = {}

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures.append(message)
        push_error(message)

func _label_capture() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 30
    game.add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(292, 7)
    panel.size = Vector2(373, 53)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.035, 0.039, 0.9)
    style.border_color = Color("9e875f")
    style.set_border_width_all(1)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    panel.add_theme_stylebox_override("panel", style)
    layer.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    panel.add_child(box)
    caption = Label.new()
    caption.text = "NATIVE GAME · SCRIPTED INPUT"
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size", 15)
    caption.modulate = Color("ecd9b0")
    box.add_child(caption)
    detail = Label.new()
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail.add_theme_font_size_override("font_size", 13)
    detail.modulate = Color("d0d7d0")
    box.add_child(detail)

func _scenario(time: float) -> Dictionary:
    var value := {"segment": "Thornwatch / live world and HUD", "move": Vector2.ZERO,
        "yaw": PI, "jump": false, "ability": ""}
    if time >= 1.0 and time < 3.2:
        value.merge({"segment": "Run / acceleration and stride", "move": Vector2(0, -1)}, true)
    elif time >= 3.2 and time < 4.0:
        value.merge({"segment": "Stop / turn in place", "yaw": lerpf(PI, PI * 0.5, (time - 3.2) / 0.8)}, true)
    elif time >= 4.0 and time < 5.5:
        value.merge({"segment": "Lateral travel / stable facing", "move": Vector2(0.55, 0), "yaw": PI}, true)
    elif time >= 5.5 and time < 7.0:
        value.merge({"segment": "Jump / actual gravity and landing", "move": Vector2(0, -0.45), "jump": time < 5.55}, true)
    elif time >= 7.0 and time < 8.15:
        value.merge({"segment": "Wayfarer's Step / actual roll", "move": Vector2(-1, 0) if time < 7.1 else Vector2.ZERO,
            "yaw": -PI * 0.5, "ability": "roll"}, true)
    elif time >= 8.15 and time < 8.8:
        value.merge({"segment": "Recovery / turn toward camera", "yaw": lerpf(-PI * 0.5, 0.35, (time - 8.15) / 0.65)}, true)
    elif time >= 8.8 and time < 10.6:
        value.merge({"segment": "Iron Vow / cast and native effects", "yaw": 0.35, "ability": "ward"}, true)
    elif time >= 10.6 and time < 11.5:
        value.merge({"segment": "Run / turn and stop", "move": Vector2(-0.25, 0.65), "yaw": -0.367}, true)
    elif time >= 11.5 and time < 13.0:
        value.merge({"segment": "Mooncleave / committed weapon action", "yaw": 0.35, "ability": "cleave"}, true)
    elif time >= 13.0 and time < 14.2:
        value.merge({"segment": "Backpedal / stable facing", "move": Vector2(0, 0.40), "yaw": PI}, true)
    elif time >= 14.2:
        value.merge({"segment": "Return to idle / live town", "yaw": lerpf(PI, 0.35, clampf((time - 14.2) / 0.9, 0.0, 1.0))}, true)
    return value

func _on_event(event: Dictionary) -> void:
    events.append({"capture_time": timeline_time, "event": event.duplicate(true)})

func _run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output = argument.trim_prefix("--output-dir=")
        elif argument == "--metrics-only":
            capture_frames = false
    if DisplayServer.get_name() == "headless":
        capture_frames = false
    DirAccess.make_dir_recursive_absolute(output + "/frames")
    root.size = Vector2i(960, 600)
    game = load("res://online.tscn").instantiate()
    root.add_child(game)
    for unused in range(6):
        await process_frame
    game._begin("solo")
    check(game.playing and game.session.mode == "solo", "Actual solo session begins")
    # This harness replaces physical keyboard polling with deterministic session
    # inputs. Everything after Session.send_input remains the production path:
    # realm validation/physics, 15 Hz snapshots, world presentation and HUD.
    for connection in game.world.input_changed.get_connections():
        game.world.input_changed.disconnect(connection.callable)
    game.session.event_received.connect(_on_event)
    game.world.camera_distance = 4.25
    game.world.camera_pitch = 0.15
    game.world.camera_yaw = 0.35
    _label_capture()
    for unused in range(8):
        await process_frame
    var start: Vector3 = C.vector(game.session.realm.state.players["1"].pos)
    var avatar: Node3D = game.world.actors["p_1"].avatar
    check(FileAccess.get_sha256(C.HERO_MODEL) == C.HERO_SHA256, "Exact accepted Mara model is preserved")
    check(game.hud.visible and not game.menu_open, "Production HUD is visible and menus are closed")
    check(game.world.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Production third-person perspective camera")
    var airborne_frames := 0
    var maximum_height := 0.0
    var maximum_distance := 0.0
    var visible_frames := 0
    var clips: Dictionary = {}
    var actions: Dictionary = {}
    var snapshots: Array[String] = []
    for frame in range(int(DURATION * FPS)):
        timeline_time = float(frame) / FPS
        var command := _scenario(timeline_time)
        var move: Vector2 = command.move
        game.session.send_input({"move": [move.x, move.y], "yaw": float(command.yaw), "jump": command.jump})
        if command.ability != "" and not issued.has(command.ability):
            issued[command.ability] = timeline_time
            game.hud.activate_ability(command.ability)
        detail.text = str(command.segment)
        if capture_frames:
            await RenderingServer.frame_post_draw
        else:
            await process_frame
        var authoritative: Dictionary = game.session.realm.state.players["1"]
        var position := C.vector(authoritative.pos)
        var height := position.y - C.ground_y(position.x, position.z)
        var grounded: bool = authoritative.grounded
        if not grounded:
            airborne_frames += 1
        maximum_height = maxf(maximum_height, height)
        maximum_distance = maxf(maximum_distance, position.distance_to(start))
        if avatar.visible:
            visible_frames += 1
        var animation: String = avatar._clip
        clips[animation] = int(clips.get(animation, 0)) + 1
        actions[str(authoritative.action)] = int(actions.get(str(authoritative.action), 0)) + 1
        var diagnostics: Dictionary = avatar.animation_diagnostics() if avatar.has_method("animation_diagnostics") else {}
        check(position.is_finite(), "Authoritative position remains finite")
        samples.append({"time": timeline_time, "segment": command.segment, "input_move": [move.x, move.y],
            "input_yaw": command.yaw, "input_jump": command.jump, "realm_time": game.session.realm.state.time,
            "position": C.array(position), "grounded": grounded, "height": height,
            "action": authoritative.action, "action_time": authoritative.action_time,
            "clip": animation, "clip_time": diagnostics.get("clip_time", avatar.animator.current_animation_position),
            "visible": avatar.visible, "sword_visible": avatar.sword.visible,
            "camera_position": C.array(game.world.camera.global_position), "hud_visible": game.hud.visible})
        if capture_frames:
            var pixels := root.get_texture().get_image()
            check(pixels.save_jpg(output + "/frames/%05d.jpg" % frame, 0.88) == OK, "Saved real native frame")
            if frame in [36, 115, 145, 188, 240, 306]:
                var filename := "gameplay-%03d.png" % frame
                pixels.save_png(output + "/" + filename)
                snapshots.append(filename)
    var final_player: Dictionary = game.session.realm.state.players["1"]
    check(airborne_frames >= 8 and maximum_height > 0.65, "Realm physics produced a real jump")
    check(bool(final_player.grounded), "Realm returned player to ground")
    check(maximum_distance > 6.0, "Actual authoritative movement traversed the town")
    check(actions.has("roll") and actions.has("ward") and actions.has("cleave"), "All requested abilities were accepted by the realm")
    check(visible_frames >= int(DURATION * FPS) - 2, "Character remains visible through the third-person camera")
    check(not bool(final_player.dead) and game.hud.visible, "Live character and production HUD remain available")
    var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures,
        "scope": "Actual native game world, production HUD, third-person camera and Mara; scripted inputs routed through real Session/Realm; isolated solo save.",
        "setup": "Default fresh solo spawn; camera zoom set to4.25m, pitch0.15rad and orbit0.35rad. Physical-input signal disconnected only in harness; Session.send_input supplies deterministic controls. Abilities are sent through the actual HUD. No Avatar.apply_state calls, synthetic poses, player teleport or direct action-state injection.",
        "timing": "Godot --fixed-fps20; ordinary production physics and frame callbacks; playback encoded at20fps.",
        "fps": FPS, "duration": DURATION, "frames": samples.size(), "captured": capture_frames,
        "resolution": [960, 600], "airborne_frames": airborne_frames, "maximum_height": maximum_height,
        "maximum_distance_from_spawn": maximum_distance, "visible_frames": visible_frames,
        "clips": clips, "actions": actions, "events": events, "snapshots": snapshots, "samples": samples,
        "mara_sha256": FileAccess.get_sha256(C.HERO_MODEL),
        "avatar_source_sha256": FileAccess.get_sha256("res://game/online/avatar.gd"),
        "world_source_sha256": FileAccess.get_sha256("res://game/online/world.gd"),
        "foot_placement_source_sha256": FileAccess.get_sha256("res://game/online/foot_placement.gd"),
        "limits": "A short scripted solo animation review, not a multiplayer stress test or gameplay completion claim. MP4 is silent; no audio track is synthesized."}
    var file := FileAccess.open(output + "/gameplay-motion-review.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    game.session.stop()
    if game.soundscape != null:
        game.soundscape.shutdown()
    game.queue_free()
    # The audio mixer releases stream references on wall-clock time, even when
    # fixed-fps/headless simulation advances far faster than a physical second.
    var drain_until := Time.get_ticks_msec() + 160
    var remaining_frames := 8
    while remaining_frames > 0 or Time.get_ticks_msec() < drain_until:
        await process_frame
        remaining_frames -= 1
    print("GAMEPLAY_MOTION_REVIEW ", JSON.stringify({"passed": failures.is_empty(), "frames": samples.size(), "failures": failures}))
    quit(0 if failures.is_empty() else 1)
