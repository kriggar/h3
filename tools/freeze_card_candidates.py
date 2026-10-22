#!/usr/bin/env python3
"""Bind a native reconstruction review to immutable staging file hashes.

This reads candidates and writes a review input file. It never imports, edits,
promotes, or renders a building and never rewrites the authoritative painting.
Run only after the model authors have frozen the requested candidates.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import pathlib
import shutil
import struct

IDS = ("granary", "barracks", "market", "smithy", "shrine", "palisade", "wharf", "water_gate")
ATLAS = "assets/ui/manuscript/buildings.png"
ATLAS_SHA = "f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be"


def sha(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def glb_summary(path: pathlib.Path) -> dict:
    raw = path.read_bytes()
    if len(raw) < 20 or struct.unpack_from("<4sII", raw) != (b"glTF", 2, len(raw)):
        raise ValueError(f"Invalid GLB container: {path}")
    length, kind = struct.unpack_from("<II", raw, 12)
    if kind != 0x4E4F534A or 20 + length > len(raw):
        raise ValueError(f"Missing GLB JSON: {path}")
    data = json.loads(raw[20 : 20 + length])
    for entry in data.get("buffers", []) + data.get("images", []):
        uri = entry.get("uri", "")
        if uri and not uri.startswith("data:"):
            raise ValueError(f"Candidate must embed all dependencies: {path}: {uri}")
    return {
        "embeddedDependenciesOnly": True,
        "animationNames": [entry.get("name", "") for entry in data.get("animations", [])],
        "meshCount": len(data.get("meshes", [])),
        "materialCount": len(data.get("materials", [])),
        "imageCount": len(data.get("images", [])),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[1])
    parser.add_argument("--ids", required=True, help="Comma-separated frozen candidate IDs")
    parser.add_argument("--out", required=True, type=pathlib.Path, help="New JSON input file; an existing file is never overwritten")
    parser.add_argument("--stage-editor-fixtures", action="store_true", help="Copy identical GLB bytes to export-excluded test fixtures for normal Godot import; no native gate may be using those fixtures")
    args = parser.parse_args()
    project = args.project.resolve()
    ids = [value.strip() for value in args.ids.split(",") if value.strip()]
    if not ids or len(set(ids)) != len(ids) or any(value not in IDS for value in ids):
        parser.error("Choose one or more distinct registered building IDs.")
    if args.out.exists():
        parser.error("The output exists. Choose a new review input path.")
    if sha(project / ATLAS) != ATLAS_SHA:
        parser.error("The authoritative painting differs from the locked original.")
    records = []
    for candidate_id in ids:
        relative = pathlib.PurePosixPath("assets/staging/card-reconstruction") / candidate_id
        directory = project / relative
        manifest_path = directory / "manifest.json"
        manifest_bytes = manifest_path.read_bytes()
        manifest = json.loads(manifest_bytes)
        if manifest.get("id") != candidate_id or manifest.get("authority", {}).get("sha256") != ATLAS_SHA:
            raise ValueError(f"Candidate identity/painting authority mismatch: {candidate_id}")
        if manifest.get("runtimePromoted", False):
            raise ValueError(f"This gate is for unpromoted staging candidates: {candidate_id}")
        files = manifest["files"]
        for key, expected_name in (("glb", candidate_id + ".glb"), ("blend", candidate_id + ".blend")):
            if files[key]["file"] != expected_name:
                raise ValueError(f"Unexpected {key} filename for {candidate_id}")
            if sha(directory / expected_name) != files[key]["sha256"]:
                raise ValueError(f"Unfrozen or stale {key} manifest for {candidate_id}")
        previews = files.get("previews", [])
        if not previews:
            raise ValueError(f"A source preview is required for {candidate_id}")
        preview = previews[0]
        if pathlib.PurePosixPath(preview["file"]).name != preview["file"]:
            raise ValueError(f"Unexpected preview path for {candidate_id}")
        if sha(directory / preview["file"]) != preview["sha256"]:
            raise ValueError(f"Unfrozen or stale preview for {candidate_id}")
        record = {
            "id": candidate_id,
            "manifestPath": "res://" + str(relative / "manifest.json"),
            "manifestSha256": hashlib.sha256(manifest_bytes).hexdigest(),
            "glbPath": "res://" + str(relative / (candidate_id + ".glb")),
            "glbSha256": files["glb"]["sha256"],
            "blendPath": "res://" + str(relative / (candidate_id + ".blend")),
            "blendSha256": files["blend"]["sha256"],
            "previewPath": "res://" + str(relative / preview["file"]),
            "previewSha256": preview["sha256"],
            "glb": glb_summary(directory / (candidate_id + ".glb")),
        }
        # Detect a concurrent export even while building the review input.
        if sha(manifest_path) != record["manifestSha256"] or sha(directory / (candidate_id + ".glb")) != record["glbSha256"]:
            raise ValueError(f"Candidate changed while being bound: {candidate_id}")
        if args.stage_editor_fixtures:
            fixture_relative = pathlib.PurePosixPath("tests/fixtures/card-reconstruction-native") / (candidate_id + ".glb")
            fixture = project / fixture_relative
            fixture.parent.mkdir(parents=True, exist_ok=True)
            temporary = fixture.with_suffix(".glb.tmp")
            shutil.copyfile(directory / (candidate_id + ".glb"), temporary)
            if sha(temporary) != record["glbSha256"]:
                temporary.unlink()
                raise ValueError(f"Candidate changed while staging its editor fixture: {candidate_id}")
            temporary.replace(fixture)
            record["editorFixturePath"] = "res://" + str(fixture_relative)
            record["editorFixtureSha256"] = sha(fixture)
        records.append(record)
    result = {
        "schemaVersion": 1,
        "createdUtc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "purpose": "Staging-only native technical/visual review input; no visual acceptance or promotion.",
        "authority": {"path": "res://" + ATLAS, "sha256": ATLAS_SHA},
        "recommendedLoadMode": "editor" if args.stage_editor_fixtures else "raw",
        "candidates": records,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("x", encoding="utf-8") as handle:
        json.dump(result, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(json.dumps({"freeze": str(args.out.resolve()), "sha256": sha(args.out), "ids": ids}))


if __name__ == "__main__":
    main()
