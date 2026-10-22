"""Bake licensed supplementary motions onto Mara's existing 53-bone rig.

Run with Blender 4.5+ in background mode. The Mara source GLB and editable
character are inputs only; neither is modified. A tiny carrier mesh is exported
solely to carry the original skeleton through glTF, then discarded by the Godot
extraction step. No replacement character is included in the runtime library.

Example arguments after Blender's ``--``:
  --target-blend /path/to/mara-pbr-v9.blend
  --source-blend /path/to/retarget-source.blend
  --grip-json /path/to/grip-v6-report.json
  --source-glb /path/to/AnimationLibrary_Godot_Standard.glb
  --mara-glb /path/to/assets/models/mara/mara.glb
  --output /tmp/mara-motion-bake/mara_extended.glb

The source motions are Quaternius Universal Animation Library Standard, CC0.
See assets/online/animations/PROVENANCE.json and the retained license notices.
"""

import argparse
import hashlib
import json
import math
import statistics
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector


CLIPS = [
    ("jump_start", "Jump_Start", False, False),
    ("jump_loop", "Jump_Loop", True, False),
    ("jump_land", "Jump_Land", False, False),
    ("interact", "PickUp_Table", False, False),
    ("hit_head", "Hit_Head", False, True),
    ("sprint", "Sprint_Loop", True, True),
]


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target-blend", type=Path, required=True)
    parser.add_argument("--source-blend", type=Path, required=True)
    parser.add_argument("--grip-json", type=Path, required=True)
    parser.add_argument("--source-glb", type=Path, required=True)
    parser.add_argument("--mara-glb", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--raw-report-only", action="store_true")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])


def digest(path):
    return hashlib.file_digest(path.open("rb"), "sha256").hexdigest()


def linear_keys(action):
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    for key in curve.keyframe_points:
                        key.interpolation = "LINEAR"


def set_action(rig, action):
    rig.animation_data_create()
    rig.animation_data.action = action
    if action.slots:
        rig.animation_data.action_slot = action.slots[0]


def mapping_for_rig():
    mapping = {
        "pelvis": "DEF-hips", "spine_01": "DEF-spine.001",
        "spine_02": "DEF-spine.002", "spine_03": "DEF-spine.003",
        "neck_01": "DEF-neck", "head": "DEF-head",
    }
    for side, source_side in [("l", "L"), ("r", "R")]:
        for target, source in [
            ("clavicle", "shoulder"), ("upperarm", "upper_arm"),
            ("lowerarm", "forearm"), ("hand", "hand"),
            ("thigh", "thigh"), ("calf", "shin"),
            ("foot", "foot"), ("ball", "toe"),
        ]:
            mapping[f"{target}_{side}"] = f"DEF-{source}.{source_side}"
        for target, source in [
            ("index", "f_index"), ("middle", "f_middle"),
            ("ring", "f_ring"), ("pinky", "f_pinky"), ("thumb", "thumb"),
        ]:
            for joint in range(1, 4):
                mapping[f"{target}_0{joint}_{side}"] = f"DEF-{source}.0{joint}.{source_side}"
    assert len(mapping) == 52
    return mapping


def boot_groups(boot):
    groups = {group.index: group.name for group in boot.vertex_groups}
    indices = {side: [] for side in ("l", "r")}
    for vertex in boot.data.vertices:
        weights = {
            side: sum(group.weight for group in vertex.groups
                      if groups[group.group].endswith("_" + side))
            for side in indices
        }
        indices[max(weights, key=weights.get)].append(vertex.index)
    return indices


def sample_pose(rig, boot, indices, sword, frame, end):
    scene = bpy.context.scene
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = boot.evaluated_get(dg)
    sword_ev = sword.evaluated_get(dg)
    feet = {}
    for side in ("l", "r"):
        vertices = [boot.matrix_world @ ev.data.vertices[i].co for i in indices[side]]
        feet[side] = {
            "lowestSole": min(vertex.z for vertex in vertices),
            "ankle": list(rig.pose.bones["foot_" + side].head),
        }
    return {
        "frame": frame, "phase": frame / end,
        "feet": feet,
        "pelvis": list(rig.pose.bones["pelvis"].head),
        "root": list(rig.pose.bones["Root"].location),
        "swordLowest": min((sword.matrix_world @ vertex.co).z
                            for vertex in sword_ev.data.vertices),
    }


def contact_windows(rows, side, threshold=0.035):
    ranges = []
    start = None
    for index, row in enumerate(rows):
        contact = row["feet"][side]["lowestSole"] <= threshold
        if contact and start is None:
            start = row["phase"]
        if start is not None and (not contact or index == len(rows) - 1):
            finish = rows[index - 1 if not contact else index]["phase"]
            ranges.append([round(start, 5), round(finish, 5)])
            start = None
    return ranges


def main():
    args = parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    initial_hash = digest(args.mara_glb)
    assert initial_hash == "8ada77b97e748814283fbf3f6efe960026674c0bf4ed04776610515c70fac94d"
    bpy.ops.wm.open_mainfile(filepath=str(args.target_blend), use_scripts=False)
    scene = bpy.context.scene
    scene.render.fps = 24
    dst = bpy.data.objects["IleanaRig"]
    boot = bpy.data.objects["Ileana.LeatherBoots"]
    sword = bpy.data.objects["Mara.Sword"]
    assert len(dst.data.bones) == 53
    for track in dst.animation_data.nla_tracks:
        track.mute = True
    source_names = [source for _, source, _, _ in CLIPS]
    with bpy.data.libraries.load(str(args.source_blend), link=False) as (library, imported):
        assert "Rig" in library.objects
        assert all(name in library.actions for name in source_names)
        imported.objects = ["Rig"]
        imported.actions = list(source_names)
    src = imported.objects[0]
    scene.collection.objects.link(src)
    for track in src.animation_data.nla_tracks:
        track.mute = True
    source_actions = {name: bpy.data.actions[name] for name in source_names}
    mapping = mapping_for_rig()
    rest = {bone.name: bone.matrix_local.copy() for bone in dst.data.bones}
    source_rest = {bone.name: bone.matrix_local.copy() for bone in src.data.bones}
    calibration = {}
    for target, source in mapping.items():
        target_rotation = rest[target].to_quaternion()
        source_rotation = source_rest[source].to_quaternion()
        if target.startswith(("upperarm", "lowerarm", "hand", "thigh", "calf", "foot", "ball",
                              "index", "middle", "ring", "pinky", "thumb")):
            target_y = target_rotation @ Vector((0, 1, 0))
            source_y = source_rotation @ Vector((0, 1, 0))
            target_rotation = target_y.rotation_difference(source_y) @ target_rotation
        calibration[target] = source_rotation.inverted() @ target_rotation
    hip_scale = rest["pelvis"].translation.z / source_rest["DEF-hips"].translation.z
    grip = {name: Quaternion(values) for name, values in
            json.loads(args.grip_json.read_text())["gripFingerRotations"].items()}
    indices = boot_groups(boot)
    actions = []
    reports = []
    for name, source_name, looping, armed in CLIPS:
        source_action = source_actions[source_name]
        set_action(src, source_action)
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        set_action(dst, action)
        start, end = map(float, source_action.frame_range)
        frames = max(2, round(end - start) + 1)
        for frame in range(frames):
            source_frame = start + (end - start) * frame / (frames - 1)
            scene.frame_set(math.floor(source_frame), subframe=source_frame % 1)
            bpy.context.view_layer.update()
            poses = {"Root": rest["Root"].copy()}
            root = dst.pose.bones["Root"]
            root.rotation_mode = "QUATERNION"
            root.matrix_basis = Matrix.Identity(4)
            for bone in dst.data.bones:
                target = bone.name
                if target not in mapping:
                    continue
                source = mapping[target]
                source_pose = src.pose.bones[source].matrix.copy()
                rotation = source_pose.to_quaternion() @ calibration[target]
                if bone.parent:
                    parent = bone.parent.name
                    local_rest = rest[parent].inverted() @ rest[target]
                    head = (poses[parent] @ local_rest).translation
                else:
                    local_rest = rest[target].copy()
                    head = rest[target].translation.copy()
                if target == "pelvis":
                    head = rest[target].translation + (source_pose.translation - source_rest[source].translation) * hip_scale
                matrix = Matrix.LocRotScale(head, rotation, Vector((1, 1, 1)))
                poses[target] = matrix
                basis = local_rest.inverted() @ (poses[bone.parent.name].inverted() @ matrix if bone.parent else matrix)
                pose = dst.pose.bones[target]
                pose.rotation_mode = "QUATERNION"
                pose.matrix_basis = basis
                if armed and target in grip:
                    pose.rotation_quaternion = grip[target]
                    pose.location = (0, 0, 0)
                pose.keyframe_insert("rotation_quaternion", frame=frame)
                pose.keyframe_insert("location", frame=frame)
            root.keyframe_insert("rotation_quaternion", frame=frame)
            root.keyframe_insert("location", frame=frame)
        linear_keys(action)
        raw = [sample_pose(dst, boot, indices, sword, frame, frames - 1) for frame in range(frames)]
        # Root adjusts only the target rig's small rest-proportion mismatch.
        # World translation/jump height remain the gameplay controller's job.
        # In-place running flight and the source's crouch/tuck are preserved.
        floor_correction = "none; inspection pass"
        if not args.raw_report_only:
            minimums = [min(row["feet"][side]["lowestSole"] for side in ("l", "r")) for row in raw]
            if name in ("jump_land", "interact", "hit_head"):
                offsets = [0.002 - low for low in minimums]
                floor_correction = "Per-frame lowest sole at 2 mm; preserve original landing compression."
            elif name == "sprint":
                offsets = [0.002 - min(minimums)] * frames
                floor_correction = "One constant floor offset; preserves authored flight."
            elif name == "jump_loop":
                offsets = [0.1371] * frames
                floor_correction = "Constant airborne baseline, shared with jump_start end; no ballistic root motion."
            else:
                offsets = []
                for frame, low in enumerate(minimums):
                    blend = min(frame / 3.0, 1.0)
                    blend = blend * blend * (3.0 - 2.0 * blend)
                    offset = (0.002 - minimums[0]) * (1.0 - blend) + 0.1371 * blend
                    offsets.append(max(offset, 0.002 - low) if frame <= 5 else offset)
                floor_correction = "Smooth takeoff baseline into jump_loop; retain knee tuck; no ballistic root motion."
            for frame, offset in enumerate(offsets):
                scene.frame_set(frame)
                root = dst.pose.bones["Root"]
                root.location.z = offset
                root.keyframe_insert("location", frame=frame)
            linear_keys(action)
            rows = [sample_pose(dst, boot, indices, sword, frame, frames - 1) for frame in range(frames)]
        else:
            rows = raw
        report = {
            "name": name, "source": source_name, "loop": looping, "armed": armed,
            "frames": frames, "fps": 24, "duration": (frames - 1) / 24,
            "sourceDuration": (end - start) / 24,
            "rawSamples": raw,
            "samples": rows,
            "floorCorrection": floor_correction,
        }
        report["lowestBoot"] = min(row["feet"][side]["lowestSole"] for row in rows for side in ("l", "r"))
        report["highestLowestBoot"] = max(min(row["feet"][side]["lowestSole"] for side in ("l", "r")) for row in rows)
        report["contactWindows"] = {side: contact_windows(rows, side) for side in ("l", "r")}
        velocities = []
        for a, b in zip(rows, rows[1:]):
            for side in ("l", "r"):
                fa, fb = a["feet"][side], b["feet"][side]
                if max(fa["lowestSole"], fb["lowestSole"]) < 0.04:
                    speed = (fb["ankle"][1] - fa["ankle"][1]) * 24
                    if speed > 0.1:
                        velocities.append(speed)
        report["estimatedForwardSpeedMetresPerSecond"] = statistics.median(velocities) if velocities else None
        reports.append(report)
        actions.append(action)
        print("RETARGETED", name, "duration", report["duration"], "boot range",
              report["lowestBoot"], report["highestLowestBoot"], flush=True)

    report = {
        "blenderVersion": bpy.app.version_string,
        "maraSourceUnchangedSha256": initial_hash,
        "sourceGlbSha256": digest(args.source_glb),
        "editableTargetSha256": digest(args.target_blend),
        "retargetSourceBlendSha256": digest(args.source_blend),
        "gripReferenceSha256": digest(args.grip_json),
        "mapping": mapping, "hipTranslationScale": hip_scale,
        "targetBones": [bone.name for bone in dst.data.bones],
        "clips": reports,
        "method": "Global rotations with limb rest-axis calibration and scaled pelvis displacement, using the exact final editable Mara rig. Source animation at 24 fps. No geometry or material changes.",
    }
    args.output.with_suffix(".json").write_text(json.dumps(report, indent=2) + "\n")
    assert digest(args.mara_glb) == initial_hash
    if args.raw_report_only:
        print("MARA_EXTENDED_INSPECTION_COMPLETE", flush=True)
        return

    # Retain no production mesh or source mannequin in this transfer asset.
    # A triangle bound to Root gives Godot an explicit glTF skin; the extractor
    # copies only bone animation tracks and saves no geometry at all.
    for obj in list(bpy.data.objects):
        if obj != dst:
            bpy.data.objects.remove(obj, do_unlink=True)
    for track in list(dst.animation_data.nla_tracks):
        dst.animation_data.nla_tracks.remove(track)
    for action in list(bpy.data.actions):
        if action not in actions:
            bpy.data.actions.remove(action)
    mesh = bpy.data.meshes.new("MotionTransferCarrier")
    mesh.from_pydata([(0, 0, 0), (0.001, 0, 0), (0, 0.001, 0)], [], [(0, 1, 2)])
    mesh.update()
    carrier = bpy.data.objects.new("MotionTransferCarrier", mesh)
    scene.collection.objects.link(carrier)
    carrier.parent = dst
    group = carrier.vertex_groups.new(name="Root")
    group.add([0, 1, 2], 1.0, "REPLACE")
    modifier = carrier.modifiers.new("Armature", "ARMATURE")
    modifier.object = dst
    for action in actions:
        track = dst.animation_data.nla_tracks.new()
        track.name = action.name
        track.strips.new(action.name, 0, action)
        track.mute = True
    set_action(dst, actions[0])
    scene.frame_set(0)
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    dst.select_set(True)
    carrier.select_set(True)
    bpy.context.view_layer.objects.active = dst
    bpy.ops.export_scene.gltf(
        filepath=str(args.output), export_format="GLB", use_selection=True,
        export_animations=True, export_animation_mode="ACTIONS", export_skins=True,
        export_all_influences=False, export_yup=True, export_force_sampling=True,
    )
    report["transferGlbSha256"] = digest(args.output)
    report["transferGlbBytes"] = args.output.stat().st_size
    args.output.with_suffix(".json").write_text(json.dumps(report, indent=2) + "\n")
    assert digest(args.mara_glb) == initial_hash
    print("MARA_EXTENDED_EXPORT_COMPLETE", args.output, flush=True)


if __name__ == "__main__":
    main()
