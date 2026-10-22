#!/usr/bin/env python3
"""Compare matched native motion captures and produce reviewable evidence.

The before/after directories come from tools/animation_review.py. A valid
comparison requires identical scripted inputs and unchanged final sources.
Contact proxies are deliberately kept separate from real plant diagnostics.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import subprocess


BASELINE_COMMIT = "bc95b0de649c5ace85c975d198e24e5e06fb5a47"
SEGMENTS = ["Walk", "Run", "Turn in place", "Strafe"]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inputs(report: dict) -> list[dict]:
    keys = ["time", "segment", "action", "action_elapsed", "grounded", "speed", "position"]
    return [{key: sample[key] for key in keys} for sample in report["samples"]]


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    offset = (len(ordered) - 1) * fraction
    index = int(offset)
    return ordered[index] + (ordered[min(index + 1, len(ordered) - 1)] - ordered[index]) * (offset - index)


def speed_stats(values: list[float]) -> dict:
    return {
        "samples": len(values),
        "median_mps": statistics.median(values) if values else None,
        "p90_mps": percentile(values, 0.9),
        "maximum_mps": max(values) if values else None,
    }


def common_contact(report: dict) -> dict:
    """The same geometry proxy is available on both old and new controllers."""
    result = {}
    for segment in SEGMENTS:
        rows = [sample for sample in report["samples"] if sample["segment"] == segment]
        speeds = []
        for prior, sample in zip(rows, rows[1:]):
            if sample["time"] < rows[0]["time"] + 0.25 or not (sample["grounded"] and prior["grounded"]):
                continue
            for foot in range(2):
                if max(sample["balls_world"][foot][1], prior["balls_world"][foot][1]) < 0.04:
                    speeds.append(sample["ball_horizontal_speed"][foot])
        result[segment] = speed_stats(speeds)
    return result


def strong_contacts(report: dict) -> dict:
    """Only the final controller exposes explicit plant weights and ages."""
    result = {}
    for segment in SEGMENTS:
        rows = [sample for sample in report["samples"] if sample["segment"] == segment]
        strong, blended = [], []
        for prior, sample in zip(rows, rows[1:]):
            if sample["time"] < rows[0]["time"] + 0.25 or not (sample["grounded"] and prior["grounded"]):
                continue
            current, previous = sample["diagnostics"], prior["diagnostics"]
            for foot in range(2):
                if current["foot_contact_age"][foot] <= 2 / report["fps"]:
                    continue
                destination = strong if current["foot_weights"][foot] >= 0.8 and previous["foot_weights"][foot] >= 0.8 else blended
                destination.append(sample["ball_horizontal_speed"][foot])
        result[segment] = {"strong_plant": speed_stats(strong), "blended_contact": speed_stats(blended)}
    return result


def transition(report: dict, start: float) -> dict:
    rows = [sample for sample in report["samples"] if start <= sample["time"] < start + 0.16]
    worst = max(rows, key=lambda sample: sample["largest_bone_step_radians"])
    return {
        "window_seconds": [start, start + 0.16],
        "maximum_bone_step_degrees": math.degrees(worst["largest_bone_step_radians"]),
        "bone": worst["largest_bone_step_name"],
        "time_seconds": worst["time"],
        "first_frame_step_degrees": math.degrees(rows[0]["largest_bone_step_radians"]),
    }


def semantic(report: dict) -> dict:
    air = [sample for sample in report["samples"] if not sample["grounded"]]
    return {
        "airborne_frames": len(air),
        "airborne_clips": sorted({sample["clip"] for sample in air}),
        "authored_airborne_clip_count": len({sample["clip"] for sample in air if "jump" in sample["clip"]}),
        "jump_segment_clips": sorted({sample["clip"] for sample in report["samples"] if sample["segment"] == "Jump and land"}),
        "moving_hit_maximum_weight": max(sample["diagnostics"].get("hit_weight", 0.0) for sample in report["samples"] if sample["segment"] == "Moving hit"),
        "interaction_clips": sorted({sample["clip"] for sample in report["samples"] if sample["segment"] == "Interact"}),
    }


def overwrite(report: dict) -> dict:
    values = [sample["render_pose_overwrite_radians"] for sample in report["samples"]]
    return {
        "maximum_radians": max(values),
        "maximum_degrees": math.degrees(max(values)),
        "frames_above_0_002_radians": sum(value > 0.002 for value in values),
        "interpretation": "Values at or below 0.002 radians are quaternion/float measurement tolerance, not evidence of a visible overwritten pose.",
    }


def verify_sources(project: Path, after: dict) -> None:
    receipt = after.get("source_receipt", {})
    if not receipt.get("unchanged_during_capture"):
        raise ValueError("Final capture has no receipt proving unchanged source files")
    source_paths = {
        "harness": "tests/online/animation_review.gd",
        "avatar": "game/online/avatar.gd",
        "catalog": "game/online/catalog.gd",
        "foot_placement": "game/online/foot_placement.gd",
        "extended_library": "assets/online/animations/mara_extended.tres",
    }
    for name, digest in receipt["sha256_at_launch"].items():
        if sha(project / source_paths[name]) != digest:
            raise ValueError(f"Final source changed after capture: {source_paths[name]}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", required=True, type=Path, help="Baseline native capture directory")
    parser.add_argument("--after", required=True, type=Path, help="Final native capture directory")
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--gates", type=Path, help="Accepted controller regression JSON report")
    args = parser.parse_args()
    project = args.project.resolve()
    before = json.loads((args.before / "animation-review.json").read_text())
    after = json.loads((args.after / "animation-review.json").read_text())
    if inputs(before) != inputs(after):
        raise ValueError("Comparison did not use identical scripted input traces")
    for report in [before, after]:
        if report["native_run"]["exit_code"] or report["native_run"]["errors"] or not all(sample["finite"] for sample in report["samples"]):
            raise ValueError("Native capture failed or contains nonfinite poses")
    verify_sources(project, after)
    gates_path = args.gates or project / "docs/online/verification/animation-controller.json"
    gates = json.loads(gates_path.read_text())
    if gates["failures"]:
        raise ValueError("Controller gates failed")
    gate_receipt = gates.get("source_receipt", {})
    if gate_receipt:
        if not gate_receipt.get("unchanged_during_test"):
            raise ValueError("Controller sources changed during regression testing")
        tested_hashes = gate_receipt["sha256_at_launch"]
        for name, digest in after["source_receipt"]["sha256_at_launch"].items():
            if name in tested_hashes and tested_hashes[name] != digest:
                raise ValueError(f"Regression tests and native capture used different sources: {name}")

    video = project / "docs/online/videos/animation-before-after.mp4"
    video.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(args.before / "animation-review.mp4"), "-i", str(args.after / "animation-review.mp4"),
        "-filter_complex", "[0:v][1:v]hstack=inputs=2:shortest=1[v]", "-map", "[v]",
        "-c:v", "libx264", "-preset", "fast", "-crf", "23", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(video),
    ], check=True)

    report = {
        "scope": "Actual native Godot render of the unchanged Mara character on a labelled scripted review stage. This is animation presentation evidence, not gameplay footage or proof of production-quality character art.",
        "baseline": {"commit": BASELINE_COMMIT, "avatar_sha256": before["avatar_source_sha256"], "mara_sha256": before["mara_sha256"], "native_run": before["native_run"]},
        "after": {"avatar_sha256": after["avatar_source_sha256"], "mara_sha256": after["mara_sha256"], "source_receipt": after["source_receipt"], "native_run": after["native_run"]},
        "comparison_method": {
            "fps": after["fps"], "frames_per_capture": after["frames"], "duration_seconds": after["duration"], "bone_count": after["bone_count"],
            "identical_scripted_inputs": True,
            "input_trace_sha256": hashlib.sha256(json.dumps(inputs(after), separators=(",", ":"), sort_keys=True).encode()).hexdigest(),
            "harness_sha256": sha(project / "tests/online/animation_review.gd"),
            "harness": "tests/online/animation_review.gd", "runner": "tools/animation_review.py",
            "comparison_builder": "tools/compare_animation_reviews.py", "headless_gates": "tests/online/animation_controller_tests.gd",
        },
        "render_pose_overwrite": {"before": overwrite(before), "after": overwrite(after)},
        "semantic_motion": {"before": semantic(before), "after": semantic(after)},
        "transition_windows": {
            name: {"before": transition(before, time), "after": transition(after, time)}
            for name, time in [("idle_to_walk", 1.0), ("walk_to_run", 2.5), ("run_to_turn", 5.0), ("turn_to_strafe", 6.0), ("jump_launch", 7.0)]
        },
        "common_low_ball_contact_proxy": {
            "definition": "Same definition for both versions: after the first 0.25 seconds of each named segment, both consecutive grounded samples have ball bone world Y below 0.040 m on the flat stage. Report world XZ ball speed over one 24 fps sample. This includes toe roll and low swing/release; it is a proxy, not an assertion that the foot is rigidly planted.",
            "before": common_contact(before), "after": common_contact(after),
        },
        "strong_plant_contact": {
            "definition": "Final controller only: foot contact age exceeds two frames, foot plant weight >= 0.8 at both interval endpoints, first 0.25 seconds excluded. Baseline has no plant weights, so its low-ball proxy is not directly compared with these strong-plant figures. Blended acquisition/release is reported separately.",
            "before": None, "after": strong_contacts(after),
        },
        "controller_gates": {"report": str(gates_path.relative_to(project)) if gates_path.is_relative_to(project) else gates_path.name, "sha256": sha(gates_path), "checks": gates["checks"], "failures": gates["failures"], "source_receipt": gate_receipt, "metrics": gates["metrics"]},
        "limitations": [
            "Procedural turns and directional stride warping are not newly authored turn/strafe clips.",
            "Low-ball proxy tails include rapid step release; median improvement does not imply every frame improved.",
            "Deep crouches retain existing tunic stretching; the braid and garment geometry were not replaced.",
            "Mara mesh, materials, and original animation binary remain unchanged.",
            "Strike and cleave share the retained source attack; cleave has a derived torso follow-through.",
        ],
        "video": {
            "path": "docs/online/videos/animation-before-after.mp4", "bytes": video.stat().st_size, "sha256": sha(video),
            "width": 1920, "height": 720, "left": "Baseline bc95b0d", "right": "Animation overhaul",
            "before_video_sha256": sha(args.before / "animation-review.mp4"), "after_video_sha256": sha(args.after / "animation-review.mp4"),
        },
    }
    target = project / "docs/online/verification/animation-comparison.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"receipt": str(target), "video": str(video), "video_bytes": video.stat().st_size, "after_source": after["avatar_source_sha256"], "identical_inputs": True}, indent=2))


if __name__ == "__main__":
    main()
