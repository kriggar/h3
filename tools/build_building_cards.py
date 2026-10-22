#!/usr/bin/env python3
"""Bind native same-scene cards to their actual Blender authoring source.

Run from an available native display (X11/Mesa is supported). This does not
create or approximate a building. All eight registered models must already be
Blender GLB exports, and every card is rendered through BuildingVisuals.create.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

IDS = ("granary", "barracks", "market", "smithy", "shrine", "palisade", "wharf", "water_gate")
ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = Path("assets/models/towns/ashen_crown")
CARD_DIR = Path("assets/ui/buildings/ashen_crown")


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def readable_path(path: Path, project: Path) -> str:
    try:
        return path.resolve().relative_to(project).as_posix()
    except ValueError:
        return str(path.resolve())


def inspect_glb(path: Path, project: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"Truncated GLB: {path}")
    magic, version, length = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError(f"Invalid GLB 2.0 header: {path}")
    cursor, document = 12, None
    while cursor < length:
        if cursor + 8 > length:
            raise ValueError(f"Truncated GLB chunk header: {path}")
        chunk_length, chunk_type = struct.unpack_from("<II", data, cursor)
        cursor += 8
        if cursor + chunk_length > length:
            raise ValueError(f"GLB chunk exceeds source bounds: {path}")
        if chunk_type == 0x4E4F534A:
            document = json.loads(data[cursor:cursor+chunk_length].rstrip(b" \x00"))
        cursor += chunk_length
    if not isinstance(document, dict) or not document.get("meshes"):
        raise ValueError(f"GLB has no mesh document: {path}")
    generator = str(document.get("asset", {}).get("generator", ""))
    if "blender" not in generator.lower():
        raise ValueError(f"A Blender-export provenance string is required: {path}")
    dependencies = []
    for kind in ("buffers", "images"):
        for entry in document.get(kind, []):
            uri = entry.get("uri", "")
            if not uri or uri.startswith("data:"):
                continue
            if "://" in uri or Path(uri).is_absolute():
                raise ValueError(f"External network/absolute dependency is not accepted: {uri}")
            dependency = (path.parent / uri).resolve()
            if not dependency.is_relative_to(project) or not dependency.is_file():
                raise ValueError(f"Dependency is missing or outside this project: {uri}")
            dependencies.append({"path":readable_path(dependency,project),"sha256":sha256(dependency)})
    return {
        "scenePath":"res://"+readable_path(path,project),
        "sourceSha256":sha256(path), "sourceBytes":len(data),
        "generator":generator, "dependencies":sorted(dependencies,key=lambda item:item["path"]),
        "gltfMeshCount":len(document.get("meshes",[])),
        "gltfMaterialCount":len(document.get("materials",[])),
    }


def atomic_copy(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True,exist_ok=True)
    temporary = target.with_name(target.name+".pending")
    shutil.copyfile(source,temporary)
    os.replace(temporary,target)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--project", type=Path, default=ROOT)
    parser.add_argument("--blend-source", type=Path, required=True,
                        help="Actual editable Blender source used for these eight exports.")
    parser.add_argument("--export-script", type=Path,
                        help="Optional actual Blender construction/export script to hash alongside the .blend.")
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--evidence-dir", type=Path)
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--treatment", choices=("raw","pigment"), default="raw")
    args = parser.parse_args()
    project = args.project.resolve()
    blend = args.blend_source.resolve()
    if not blend.is_file() or blend.suffix.lower() != ".blend" or blend.stat().st_size < 12:
        raise SystemExit("An actual editable Blender .blend file is required before publishing cards.")
    if not args.godot.is_file():
        raise SystemExit("The supplied Godot executable does not exist.")
    if args.size < 128 or args.size > 2048:
        raise SystemExit("Card size must be between 128 and 2048 pixels.")
    output = (args.output_dir or project/CARD_DIR).resolve()
    evidence = (args.evidence_dir or project/"docs/verification-logs/building-cards").resolve()
    sources = {identifier:inspect_glb(project/MODEL_DIR/f"{identifier}.glb",project) for identifier in IDS}
    blend_hash = sha256(blend)
    authoring = {"tool":"Blender","blendPath":readable_path(blend,project),"blendSha256":blend_hash,"blendBytes":blend.stat().st_size}
    if args.export_script:
        script = args.export_script.resolve()
        if not script.is_file():
            raise SystemExit("The supplied Blender export script does not exist.")
        authoring["exportScript"] = {"path":readable_path(script,project),"sha256":sha256(script)}
    evidence.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="draconia-building-cards-") as folder:
        temporary = Path(folder)
        environment = dict(os.environ)
        for key, suffix in (("XDG_DATA_HOME","data"),("XDG_CONFIG_HOME","config"),("XDG_CACHE_HOME","cache")):
            environment[key] = str(temporary/"user"/suffix)
        # Fresh imports prevent a changed GLB from being paired with a stale
        # .godot cache while its new source hash is written into the manifest.
        import_command = [str(args.godot.resolve()),"--headless","--path",str(project),"--import"]
        imported = subprocess.run(import_command,env=environment,capture_output=True,text=True)
        import_diagnostics = imported.stdout+imported.stderr
        (evidence/"native-import.log").write_text(import_diagnostics)
        (evidence/"native-import.exit-code").write_text(str(imported.returncode)+"\n")
        if imported.returncode or re.search(r"(?:SCRIPT ERROR:|SHADER ERROR:|^ERROR:)",import_diagnostics,re.MULTILINE):
            raise SystemExit(f"Fresh Godot import failed; inspect {evidence/'native-import.log'}")
        command = [str(args.godot.resolve()),"--path",str(project),"--rendering-method","gl_compatibility",
                   "--audio-driver","Dummy","--resolution","1024x768","--script","res://tools/render_building_cards.gd",
                   "--",f"--output-dir={temporary}",f"--size={args.size}",f"--treatment={args.treatment}","--verify-repeat"]
        run = subprocess.run(command,env=environment,capture_output=True,text=True)
        diagnostics = run.stdout+run.stderr
        (evidence/"native-render.log").write_text(diagnostics)
        (evidence/"native-render.exit-code").write_text(str(run.returncode)+"\n")
        if run.returncode or re.search(r"(?:SCRIPT ERROR:|SHADER ERROR:|^ERROR:)",diagnostics,re.MULTILINE):
            raise SystemExit(f"Native card render failed; inspect {evidence/'native-render.log'}")
        native = json.loads((temporary/"native-report.json").read_text())
        if native.get("failures") or set(native.get("renderedBuildings",{})) != set(IDS):
            raise SystemExit("Native identity evidence is incomplete; no cards were installed.")
        # Preserve provisional review pixels even if concurrent authoring
        # invalidates publication. They are evidence, never runtime cards.
        shutil.copyfile(temporary/"native-report.json",evidence/"native-report.json")
        for result in native["renderedBuildings"].values():
            for key in ("cardFile","rawCardFile"):
                atomic_copy(temporary/result[key],evidence/"candidate-images"/result[key])
        if sha256(blend) != blend_hash:
            raise SystemExit("Blender source changed during card rendering; no cards were installed.")
        if args.export_script and sha256(args.export_script.resolve()) != authoring["exportScript"]["sha256"]:
            raise SystemExit("Blender export script changed during card rendering; no cards were installed.")
        records = {}
        for identifier in IDS:
            original = sources[identifier]
            current = inspect_glb(project/MODEL_DIR/f"{identifier}.glb",project)
            result = native["renderedBuildings"][identifier]
            if original != current or result["sourceSha256"] != original["sourceSha256"]:
                raise SystemExit(f"Source/dependency changed during rendering: {identifier}")
            if result["signature"]["scenePath"] != original["scenePath"] or result["signature"]["instantiatedScenePath"] != original["scenePath"]:
                raise SystemExit(f"Card was not rendered from the registered scene: {identifier}")
            for key in ("cardFile","rawCardFile"):
                if not (temporary/result[key]).is_file():
                    raise SystemExit(f"Native output is missing: {identifier} {key}")
            if sha256(temporary/result["cardFile"]) != result["cardSha256"] or sha256(temporary/result["rawCardFile"]) != result["rawCardSha256"]:
                raise SystemExit(f"Rendered card bytes changed: {identifier}")
            records[identifier] = dict(original,**{key:value for key,value in result.items() if key not in ("ok","reason","sourceSha256")})
            records[identifier]["blendSha256"] = blend_hash
        tool_paths = [project/"game/redesign/building_visuals.gd",project/"game/redesign/building_card_studio.gd",
                      project/"game/redesign/pbr_lighting.gd",
                      project/"game/redesign/building_card_pigment.gdshader",project/"tools/render_building_cards.gd",Path(__file__).resolve()]
        manifest = {
            "schemaVersion":1,"status":"development_model_card_identity_proof",
            "scope":"Eight Ashen Crown building identity proofs; not nine finished towns or production-art acceptance.",
            "authoring":authoring,"buildings":records,
            "tools":[{"path":readable_path(path,project),"sha256":sha256(path)} for path in tool_paths],
            "nativeChecks":native["checks"],"nativeFailures":native["failures"],
        }
        # Publish the manifest last. Runtime card lookup rejects stale model or
        # PNG hashes while a developer replaces a card set.
        for identifier in IDS:
            for key in ("cardFile","rawCardFile"):
                atomic_copy(temporary/records[identifier][key],output/records[identifier][key])
        encoded = json.dumps(manifest,ensure_ascii=False,indent=2,sort_keys=True)+"\n"
        output.mkdir(parents=True,exist_ok=True)
        pending = output/"manifest.json.pending"
        pending.write_text(encoded)
        os.replace(pending,output/"manifest.json")
        shutil.copyfile(temporary/"native-report.json",evidence/"native-report.json")
        (evidence/"manifest.json").write_text(encoded)
        print(json.dumps({"cards":len(records),"nativeChecks":native["checks"],"nativeFailures":native["failures"],
                          "manifest":str(output/"manifest.json"),"manifestSha256":sha256(output/"manifest.json"),
                          "authoringBlendSha256":blend_hash,"evidence":str(evidence)},ensure_ascii=False))


if __name__ == "__main__":
    main()
