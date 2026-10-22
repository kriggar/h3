#!/usr/bin/env python3
"""Prepare, seal, and export the painted-card reconstruction checkpoint.

The default command is a read-only plan. `freeze` records identities only;
`execute` is the sole mode that imports, exports, or launches Godot. Execute
requires the SHA-256 of the reviewed freeze and refuses existing output paths.
No ZIP is created here. Windows is cross-exported and remains runtime unverified.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import time
from urllib.parse import unquote, urlsplit

from native_export_probe import diagnostics, run_probe, save_json, sha256, utc


PROJECT = Path(__file__).resolve().parents[1]
ENGINE = PROJECT.parent / "analysis-tools/godot/Godot_v4.7.2-stable_linux.x86_64"
CHECKPOINT = "0.3.1-card-reconstruction"
MANIFEST = "assets/models/towns/ashen_crown/manifest.json"
INTEGRATION = "docs/verification-logs/card-reconstruction/runtime-integration.json"
CANDIDATE_INDEX = "docs/verification-logs/card-reconstruction/native-candidate-set-v1.json"
CANDIDATE_INDEX_SHA = "99dd463ff65e8f8af30794adf5780205c682b95439c13dfe36c05c3519526a5e"
ATLAS = "assets/ui/manuscript/buildings.png"
ATLAS_SHA = "f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be"
EXPECTED_MODELS = {
    "granary": "7d79a1dabd7e5099720be2c197b1fbc5d5e0f4c60a6cdd25241e6bb44cf07abf",
    "barracks": "b0ebdc51851348021af4014551a31126f0fa1e0c3ff0f55b01483197550cbe54",
    "market": "a6f77815f9874a5cd8164dc45742e7993a95dc09a212713157df15e3ae3179ba",
    "smithy": "969379f6a7802478f4c707cc2c826057b21e4e4ebd894f801db4fb38d3ac1d04",
    "shrine": "8118f71ac6b463da5c2df03fe875d06e5fc33f6d50080224b2604d3b28ba0a86",
    "palisade": "824b94d83182ad28ee29e1b4e5b5eccf321bab3f8b8c8cbcd6e7f7c8018bee8f",
    "wharf": "ae349a2788e4002f14986e1d7277bd86d5d5a205c421fe12961dd930d9bda558",
    "water_gate": "9f95beaab4338652de9b7cd2e317723bbf13c5243751f28e6dafded0cee2328b",
}
SOURCE_ONLY_PREFIXES = ("tools/", "tests/", "docs/", "research/", "builds/", "dist/",
                        "assets/staging/", "assets/models/source/", "assets/animated/source/",
                        ".openai/", ".git/", ".godot/editor/", ".godot/shader_cache/")
RUNTIME_PRIMARY = ("project.godot", "export_presets.cfg", "redesign.tscn", "main.tscn",
                   "icon.svg", "icon.svg.import", "README.md", "LICENSE.txt", "ASSET_CREDITS.md")
GATED_RUNTIME_CODE = ("game/redesign/game_shell.gd", "game/redesign/town_stage.gd",
                      "game/redesign/building_visuals.gd", "game/redesign/building_motion.gd",
                      "game/redesign/building_card_button.gd", "game/redesign/manuscript_art.gd",
                      "game/redesign/realm_rules.gd")
LIMITS = [
    "Development checkpoint: exact source/export binding, Linux startup/render, inspected Menu/Save & Quit, and retained autosave only.",
    "No exported-binary full playthrough, target-GPU performance, sound, or production-art acceptance.",
    "Linux uses X11, Mesa software rendering and the Dummy audio driver; other devices are unverified.",
    "Windows is cross-exported; no Windows executable is run.",
    "The original painted building atlas remains authoritative. No render replaces its cards.",
]


class GateError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise GateError(message)


def file_record(path: Path, *, relative_to: Path | None = None) -> dict:
    require(path.is_file() and not path.is_symlink(), f"Expected a regular file: {path}")
    before = path.stat()
    digest = sha256(path)
    after = path.stat()
    require((before.st_size, before.st_mtime_ns) == (after.st_size, after.st_mtime_ns),
            f"Input changed while hashing: {path}")
    return {"path": path.relative_to(relative_to).as_posix() if relative_to else str(path.resolve()),
            "bytes": after.st_size, "sha256": digest}


def path_in_project(project: Path, name: str) -> Path:
    require(isinstance(name, str) and bool(name), "Expected a nonempty project path")
    relative = name.removeprefix("res://")
    require(not Path(relative).is_absolute() and ".." not in PurePosixPath(relative).parts
            and "\\" not in relative, f"Unsafe project path: {name}")
    path = project / relative
    require(path.resolve().is_relative_to(project.resolve()), f"Path escaped project: {name}")
    require(not any(parent.is_symlink() for parent in [path, *path.parents]
                    if parent.is_relative_to(project)), f"Symlinked project path: {name}")
    return path


def application(project: Path) -> dict:
    text = (project / "project.godot").read_text(encoding="utf-8")
    result = {}
    for label, key in [("version", "config/version"), ("mainScene", "run/main_scene")]:
        found = re.search(r"^" + re.escape(key) + r'="([^"]+)"', text, re.M)
        result[label] = found.group(1) if found else ""
    return result


def validate_runtime_gate(project: Path, integration: dict) -> dict:
    """Check the owner's linked completed native gate, without circular hashing."""
    require(isinstance(integration, dict), "Runtime integration record must be a JSON object")
    gate = integration.get("runtimeGate", {})
    require(isinstance(gate, dict) and gate.get("passed") is True,
            "Actual installed-runtime construction/hover/save/reload gate is still pending")
    require(type(gate.get("exitCode")) is int and gate["exitCode"] == 0,
            "Runtime gate requires an explicit successful native exit code")
    require(type(gate.get("failures")) is int and gate["failures"] == 0,
            "Runtime integration gate requires an explicit zero failure count")
    require(type(gate.get("checks")) is int and gate["checks"] > 0,
            "Runtime gate requires the actual native check count")
    evidence = {}
    for label, digest_key in (("report", "reportSha256"), ("log", "logSha256")):
        digest = gate.get(digest_key)
        require(isinstance(digest, str) and re.fullmatch(r"[0-9a-fA-F]{64}", digest) is not None,
                f"Runtime gate requires a valid {digest_key}")
        path = path_in_project(project, gate.get(label, ""))
        record = file_record(path, relative_to=project)
        require(record["sha256"] == digest.lower(), f"Runtime gate {label} differs from its final SHA-256")
        evidence[label] = record
    native_report = json.loads((project / evidence["report"]["path"]).read_text(encoding="utf-8"))
    require(isinstance(native_report, dict), "Linked native report must be a JSON object")
    failures = native_report.get("failures")
    require((type(failures) is int and failures == 0) or (isinstance(failures, list) and not failures),
            "Linked native report records failures or has no explicit failure result")
    require(type(native_report.get("checks")) is int and native_report["checks"] == gate["checks"],
            "Linked native report check count differs from the integration record")
    text = (project / evidence["log"]["path"]).read_text(encoding="utf-8", errors="replace")
    require(bool(re.search(r"OpenGL API .*Compatibility|Vulkan .*Using Device", text)),
            "Linked runtime gate log has no actual native renderer record")
    _, blocking = diagnostics(text)
    require(not blocking, "Linked runtime gate log contains blocking diagnostics: " + "; ".join(blocking[:3]))
    sources = native_report.get("sourceHashes", {})
    require(isinstance(sources, dict), "Linked native report must retain its sourceHashes mapping")
    sources = {name.removeprefix("res://"): digest for name, digest in sources.items() if isinstance(name, str)}
    required = set(GATED_RUNTIME_CODE) | {ATLAS}
    required.update(f"assets/models/towns/ashen_crown/{name}.glb" for name in EXPECTED_MODELS)
    verified = []
    for relative in sorted(required):
        require(relative in sources and sha256(path_in_project(project, relative)) == sources[relative],
                f"Runtime source differs from the completed native gate: {relative}")
        verified.append({"path": relative, "sha256": sources[relative]})
    # runtime-integration.json is deliberately not in this source set. Its final
    # owner-supplied hash binds the linked report, never a hash of itself.
    return {"report": evidence["report"], "log": evidence["log"], "checks": gate["checks"],
            "failures": 0, "exitCode": 0, "runtimeSourcesVerified": verified}


def preflight(project: Path, engine: Path, integration_sha: str | None) -> dict:
    """No process, cache write, source freeze, or directory creation occurs here."""
    errors, models, gate_evidence = [], {}, {}
    config = application(project)
    if config != {"version": CHECKPOINT, "mainScene": "res://redesign.tscn"}:
        errors.append(f"Configure the exact {CHECKPOINT} action entry before freezing")
    if not engine.is_file():
        errors.append(f"Missing Godot executable: {engine}")
    if not integration_sha or not re.fullmatch(r"[0-9a-f]{64}", integration_sha):
        errors.append("A final, owner-supplied runtime-integration.json SHA-256 is required")
    try:
        require(sha256(project / ATLAS) == ATLAS_SHA, "The original painted atlas differs from the locked authority")
        require(sha256(project / CANDIDATE_INDEX) == CANDIDATE_INDEX_SHA, "The frozen source candidate index changed")
        manifest = json.loads((project / MANIFEST).read_text(encoding="utf-8"))
        require(isinstance(manifest, dict) and manifest.get("schemaVersion") == 4
                and manifest.get("status") == "reviewed_painted_card_reconstruction_development_integration"
                and manifest.get("runtimePromoted") is True
                and manifest.get("productionAccepted") is False,
                "Runtime manifest is not the reviewed reconstruction development integration")
        require(manifest.get("authority") == {"path": ATLAS, "sha256": ATLAS_SHA,
                                              "cardReplacementAllowed": False},
                "Runtime manifest must retain the exact painted-card authority")
        assets = manifest.get("assets", [])
        require(isinstance(assets, list) and len(assets) == len(EXPECTED_MODELS),
                "Runtime manifest must contain exactly the eight reviewed buildings")
        by_id = {asset["id"]: asset for asset in assets}
        require(set(by_id) == set(EXPECTED_MODELS), "Runtime building IDs differ from the frozen eight")
        for building_id, expected in EXPECTED_MODELS.items():
            row = by_id[building_id]
            name = f"assets/models/towns/ashen_crown/{building_id}.glb"
            record = file_record(path_in_project(project, name), relative_to=project)
            require(row.get("file") == building_id + ".glb"
                    and row.get("sha256") == record["sha256"] == expected
                    and row.get("bytes") == record["bytes"],
                    f"Installed {building_id} is not the reviewed reconstruction bytes")
            models[building_id] = record
        integration = json.loads((project / INTEGRATION).read_text(encoding="utf-8"))
        require(isinstance(integration, dict) and integration.get("schemaVersion") == 1
                and integration.get("checkpoint") == CHECKPOINT,
                "Runtime integration record has the wrong checkpoint/schema")
        require(integration.get("runtimePromoted") is True and integration.get("productionAccepted") is False,
                "Integration must state development promotion without production-art acceptance")
        if integration_sha:
            require(sha256(project / INTEGRATION) == integration_sha,
                    "Runtime integration evidence differs from the owner-supplied final SHA-256")
        gate_evidence = validate_runtime_gate(project, integration)
    except (GateError, OSError, ValueError, KeyError, TypeError) as error:
        errors.append(str(error))
    return {"schemaVersion": 1, "checkpoint": CHECKPOINT, "mode": "read-only-plan",
            "application": config, "runtimeManifest": MANIFEST, "integration": INTEGRATION,
            "expectedIntegrationSha256": integration_sha, "modelIdentities": models,
            "runtimeGateEvidence": gate_evidence,
            "readyToFreeze": not errors, "pendingGates": errors,
            "importsExecuted": False, "exportsExecuted": False, "nativeExecuted": False,
            "limits": LIMITS}


def runtime_inventory(project: Path) -> dict:
    """Gameplay/assets plus authored import settings; caches and author sources excluded."""
    paths = [project / name for name in RUNTIME_PRIMARY if (project / name).is_file()]
    for folder in ("game", "data", "assets"):
        for root, directories, filenames in os.walk(project / folder, followlinks=False):
            root_path = Path(root)
            kept = []
            for name in directories:
                path = root_path / name
                relative = path.relative_to(project).as_posix() + "/"
                if relative.startswith(SOURCE_ONLY_PREFIXES) or name in (".godot", "__pycache__"):
                    continue
                require(not path.is_symlink(), f"Runtime directory is a symlink: {relative}")
                kept.append(name)
            directories[:] = kept
            for name in filenames:
                path = root_path / name
                relative = path.relative_to(project).as_posix()
                if relative.startswith(SOURCE_ONLY_PREFIXES) or name.endswith((".pending", ".blend1", ".pyc")):
                    continue
                paths.append(path)
    return {record["path"]: {"bytes": record["bytes"], "sha256": record["sha256"]}
            for record in [file_record(path, relative_to=project) for path in sorted(set(paths))]}


def inventory_digest(records: dict) -> str:
    return hashlib.sha256(json.dumps(records, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def glb_dependency_closure(project: Path, inventory: dict) -> dict:
    """Resolve external images/buffers from actual GLB JSON, never filename guesses."""
    result = {}
    for relative in sorted(inventory):
        if not relative.endswith(".glb"):
            continue
        path = path_in_project(project, relative)
        with path.open("rb") as stream:
            header = stream.read(12)
            require(len(header) == 12, f"Truncated GLB: {relative}")
            magic, version, size = struct.unpack("<4sII", header)
            require(magic == b"glTF" and version == 2 and size == path.stat().st_size,
                    f"Invalid GLB header: {relative}")
            length, kind = struct.unpack("<II", stream.read(8))
            require(kind == 0x4E4F534A and 0 < length <= size - 20, f"Missing GLB JSON: {relative}")
            document = json.loads(stream.read(length).rstrip(b"\x00 \t\r\n"))
        dependencies = []
        for category in ("images", "buffers"):
            for index, entry in enumerate(document.get(category, [])):
                uri = entry.get("uri")
                if uri is None or uri.startswith("data:"):
                    continue
                parsed = urlsplit(uri)
                require(not parsed.scheme and not parsed.netloc and not parsed.query and not parsed.fragment,
                        f"Nonlocal GLB dependency: {relative}: {uri}")
                decoded = unquote(parsed.path)
                require(decoded and not Path(decoded).is_absolute() and "\\" not in decoded,
                        f"Unsafe GLB dependency: {relative}: {uri}")
                target = (path.parent / decoded).resolve()
                require(target.is_relative_to(project.resolve()), f"GLB dependency escaped project: {uri}")
                dependency = target.relative_to(project.resolve()).as_posix()
                require(dependency in inventory, f"GLB dependency omitted from runtime inventory: {dependency}")
                dependencies.append({"category": category, "index": index, "uri": uri,
                                     "path": dependency, **inventory[dependency]})
        result[relative] = dependencies
    return result


def create_freeze(project: Path, engine: Path, integration_sha: str, output: Path) -> dict:
    plan = preflight(project, engine, integration_sha)
    require(plan["readyToFreeze"], "; ".join(plan["pendingGates"]))
    require(not output.exists(), "Freeze path already exists; preserve it and choose a new path")
    records = runtime_inventory(project)
    closure = glb_dependency_closure(project, records)
    freeze = {"schemaVersion": 1, "checkpoint": CHECKPOINT, "createdUtc": utc(),
              "status": "identity_snapshot_only_not_export_or_native_acceptance",
              "project": str(project.resolve()), "engine": file_record(engine),
              "integration": file_record(project / INTEGRATION, relative_to=project),
              "runtimeManifest": file_record(project / MANIFEST, relative_to=project),
              "candidateIndex": file_record(project / CANDIDATE_INDEX, relative_to=project),
              "lockedAtlas": file_record(project / ATLAS, relative_to=project),
              "models": plan["modelIdentities"], "runtimeSources": records,
              "runtimeGateEvidence": plan["runtimeGateEvidence"],
              "runtimeSourceInventorySha256": inventory_digest(records),
              "inventoryScope": "project/export/entry/icon files, root README/license/credits, game/, data/, runtime assets/, including .uid and .import settings; authoring and caches excluded",
              "glbExternalDependencies": closure,
              "runnerSources": [file_record(Path(__file__).resolve(), relative_to=project),
                                file_record(Path(__file__).with_name("native_export_probe.py"), relative_to=project)],
              "limits": LIMITS}
    # Detect a concurrent mutation even if it happens after a file was first read.
    require(runtime_inventory(project) == records, "Runtime changed during freeze creation")
    require(sha256(project / INTEGRATION) == integration_sha, "Integration record changed during freeze creation")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(freeze, indent=2, ensure_ascii=False) + "\n")
    return {"freeze": str(output.resolve()), "sha256": sha256(output),
            "runtimeFiles": len(records), "models": len(plan["modelIdentities"]),
            "externalGlbDependencies": sum(len(items) for items in closure.values()),
            "exportsExecuted": False, "nativeExecuted": False}


def verify_freeze(project: Path, engine: Path, path: Path, expected_sha: str) -> dict:
    require(re.fullmatch(r"[0-9a-f]{64}", expected_sha) is not None, "A valid freeze SHA-256 is required")
    require(sha256(path) == expected_sha, "Freeze differs from the reviewed SHA-256")
    freeze = json.loads(path.read_text(encoding="utf-8"))
    require(freeze.get("schemaVersion") == 1 and freeze.get("checkpoint") == CHECKPOINT,
            "Wrong export freeze schema/checkpoint")
    require(Path(freeze["project"]).resolve() == project.resolve(), "Freeze belongs to another project")
    require(file_record(engine) == freeze["engine"], "Godot executable changed after freeze")
    plan = preflight(project, engine, freeze["integration"]["sha256"])
    require(plan["readyToFreeze"], "; ".join(plan["pendingGates"]))
    require(plan["runtimeGateEvidence"] == freeze["runtimeGateEvidence"],
            "Completed runtime gate evidence/source binding changed after freeze")
    for key in ("integration", "runtimeManifest", "candidateIndex", "lockedAtlas"):
        record = freeze[key]
        require(file_record(path_in_project(project, record["path"]), relative_to=project) == record,
                f"Frozen evidence changed: {key}")
    for record in freeze["runnerSources"]:
        require(file_record(path_in_project(project, record["path"]), relative_to=project) == record,
                "Export/probe tooling changed after freeze")
    current = runtime_inventory(project)
    require(current == freeze["runtimeSources"], "Runtime source/import settings differ from the reviewed freeze")
    require(inventory_digest(current) == freeze["runtimeSourceInventorySha256"], "Freeze inventory digest is inconsistent")
    require(glb_dependency_closure(project, current) == freeze["glbExternalDependencies"], "GLB dependency closure changed")
    return freeze


def import_bindings(project: Path, freeze: dict) -> dict:
    """Bind source MD5 to the fresh import and the exact cache bytes exported."""
    sources = set(freeze["glbExternalDependencies"])
    sources.add(ATLAS)
    for dependencies in freeze["glbExternalDependencies"].values():
        sources.update(row["path"] for row in dependencies if row["category"] == "images")
    bindings = {}
    for relative in sorted(sources):
        source = path_in_project(project, relative)
        metadata = source.with_name(source.name + ".import")
        text = metadata.read_text(encoding="utf-8")
        remap = re.search(r'^path="res://([^"\n]+)"', text, re.M)
        if not remap:
            remap = re.search(r'^path\.s3tc="res://([^"\n]+)"', text, re.M)
        require(remap is not None, f"No desktop import remap for {relative}")
        destination = remap.group(1)
        require(destination.startswith(".godot/imported/"), f"Unexpected import target: {destination}")
        cache = path_in_project(project, destination)
        match = re.fullmatch(r"(.+-[0-9a-f]{32})(?:\.[^.]+)+", cache.name)
        require(match is not None, f"Unrecognized Godot cache name: {cache.name}")
        digest_file = cache.parent / (match.group(1) + ".md5")
        digest_text = digest_file.read_text(encoding="utf-8")
        source_md5 = hashlib.md5(source.read_bytes()).hexdigest()
        found = re.search(r'^source_md5="([0-9a-f]{32})"', digest_text, re.M)
        require(found is not None and found.group(1) == source_md5,
                f"Import cache source digest is stale: {relative}")
        bindings[relative] = {"sourceSha256": sha256(source), "sourceMd5": source_md5,
                              "importSettings": file_record(metadata, relative_to=project),
                              "importDigest": file_record(digest_file, relative_to=project),
                              "cache": file_record(cache, relative_to=project)}
    return bindings


def read_exact(stream, length: int) -> bytes:
    data = stream.read(length)
    require(len(data) == length, "Truncated embedded PCK")
    return data


def verify_embedded_pack(binary: Path, *, project: Path, bindings: dict,
                         expected_manifest_sha: str, checkpoint: str = CHECKPOINT) -> dict:
    """Read actual bytes of every member; verify bounds, MD5, SHA and key remaps."""
    total = binary.stat().st_size
    require(total > 52, "Export is too small to contain an embedded PCK")
    with binary.open("rb") as stream:
        stream.seek(-12, 2)
        pack_size, marker = struct.unpack("<Q4s", read_exact(stream, 12))
        require(marker == b"GDPC" and 0 < pack_size <= total - 12, "Missing/invalid embedded PCK footer")
        start = total - 12 - pack_size
        stream.seek(start)
        header = struct.unpack("<4sIIIIIQQ", read_exact(stream, 40))
        require(header[0] == b"GDPC" and header[1] in (3, 4) and header[2:5] == (4, 7, 2)
                and not header[5] & 1, "Unexpected PCK version, engine, or encryption")
        file_base, directory = start + header[6], start + header[7]
        require(start + 40 <= file_base <= directory < start + pack_size, "Invalid PCK offsets")
        stream.seek(directory)
        count, = struct.unpack("<I", read_exact(stream, 4))
        require(0 < count < 100000, "Unexpected PCK resource count")
        members, names = [], set()
        for _ in range(count):
            length, = struct.unpack("<I", read_exact(stream, 4))
            require(0 < length < 65536, "Unexpected PCK path length")
            name = read_exact(stream, length).rstrip(b"\x00").decode("utf-8").removeprefix("res://")
            require(name and not name.startswith("/") and "\\" not in name and "\x00" not in name
                    and ".." not in PurePosixPath(name).parts and name not in names,
                    f"Unsafe or duplicated PCK member: {name}")
            require(not name.startswith(SOURCE_ONLY_PREFIXES), f"Source-only path leaked into export: {name}")
            names.add(name)
            offset, size = struct.unpack("<QQ", read_exact(stream, 16))
            md5 = read_exact(stream, 16).hex()
            flags, = struct.unpack("<I", read_exact(stream, 4))
            require(flags == 0, f"Unsupported encrypted/removed PCK member: {name}")
            absolute = file_base + offset
            require(file_base <= absolute <= directory and absolute + size <= directory,
                    f"PCK member exceeds its file data extent: {name}")
            members.append({"path": name, "offsetInExecutable": absolute, "bytes": size,
                            "md5FromDirectory": md5, "flags": flags})
        require(stream.tell() <= start + pack_size, "PCK directory exceeds the pack")
        ordered = sorted(members, key=lambda row: row["offsetInExecutable"])
        for first, second in zip(ordered, ordered[1:]):
            require(first["offsetInExecutable"] + first["bytes"] <= second["offsetInExecutable"],
                    "PCK data members overlap")
        small = {}
        for row in members:
            stream.seek(row["offsetInExecutable"])
            remaining, md5, digest = row["bytes"], hashlib.md5(), hashlib.sha256()
            keep = row["path"].endswith((".import", ".remap")) or row["path"] == "project.binary"
            captured = bytearray()
            while remaining:
                block = read_exact(stream, min(1024 * 1024, remaining))
                remaining -= len(block)
                md5.update(block)
                digest.update(block)
                if keep:
                    require(row["bytes"] < 2 * 1024 * 1024, "Unexpectedly large resource remap")
                    captured.extend(block)
            require(md5.hexdigest() == row["md5FromDirectory"], f"PCK member digest mismatch: {row['path']}")
            row["sha256"] = digest.hexdigest()
            row["md5Verified"] = True
            if keep:
                small[row["path"]] = bytes(captured)
        by_name = {row["path"]: row for row in members}
        require(MANIFEST in by_name and by_name[MANIFEST]["sha256"] == expected_manifest_sha,
                "Embedded runtime manifest is stale or missing")
        require("project.binary" in small and checkpoint.encode() in small["project.binary"]
                and b"res://redesign.tscn" in small["project.binary"],
                "Embedded application version/main entry is not the frozen checkpoint")
        require("redesign.tscn.remap" in small and "game/redesign/game_shell.gdc" in by_name,
                "Exported action entry or compiled GameShell is missing")
        matched = []
        for source, binding in bindings.items():
            cache = binding["cache"]
            target = cache["path"]
            require(target in by_name and by_name[target]["sha256"] == cache["sha256"],
                    f"Embedded imported resource differs from the fresh cache: {source}")
            remap_name = source + ".import"
            require(remap_name in small and ("res://" + target).encode() in small[remap_name],
                    f"Embedded source remap is absent or stale: {source}")
            matched.append({"source": source, "sourceSha256": binding["sourceSha256"],
                            "sourceMd5": binding["sourceMd5"], "embeddedResource": target,
                            "embeddedSha256": cache["sha256"]})
        for name, data in small.items():
            if not name.endswith(".remap"):
                continue
            match = re.search(rb'^path="res://([^"\n]+)"', data, re.M)
            if match:
                require(match.group(1).decode() in by_name, f"Export remap target is absent: {name}")
        stream.seek(start)
        remaining, digest = pack_size, hashlib.sha256()
        while remaining:
            block = read_exact(stream, min(1024 * 1024, remaining))
            remaining -= len(block)
            digest.update(block)
    return {"pack": {"container": str(binary.resolve()), "storage": "Embedded in executable; no separate PCK file",
                     "offsetBytes": start, "bytes": pack_size, "sha256": digest.hexdigest(),
                     "hashRange": "PCK header through end padding, excluding the 12-byte footer",
                     "formatVersion": header[1], "engineVersion": "4.7.2", "resourceCount": count,
                     "sourceOnlyPayloadsExcluded": True, "everyMemberMd5AndSha256Verified": True},
            "sourceImportBindings": matched, "files": members}


def previous_build_inventory(project: Path, new_root: Path) -> dict:
    result = {}
    for path in sorted((project / "builds").rglob("*")):
        if path.is_file() and not path.resolve().is_relative_to(new_root.resolve()):
            record = file_record(path, relative_to=project)
            result[record["path"]] = {"bytes": record["bytes"], "sha256": record["sha256"]}
    return result


def run_owned_process(command: list[str], *, cwd: Path, env: dict, log: Path,
                      timeout: float, stop_timeout: float = 10) -> dict:
    """Own a stage child through normal exit, timeout, or exceptional cancellation."""
    process = None
    record = {}
    try:
        with log.open("xb") as stream:
            process = subprocess.Popen(command, cwd=cwd, env=env, stdout=stream, stderr=subprocess.STDOUT)
            record["processId"] = process.pid
            process.wait(timeout=timeout)
    except BaseException as error:
        record["failure"] = str(error) or type(error).__name__
        record["exceptionType"] = type(error).__name__
        if isinstance(error, subprocess.TimeoutExpired):
            record["timeoutSeconds"] = timeout
        if isinstance(error, KeyboardInterrupt):
            record["cancelled"] = True
        if process is not None and process.poll() is None:
            record["forcedTermination"] = True
            process.terminate()
            try:
                process.wait(timeout=stop_timeout)
            except subprocess.TimeoutExpired:
                record["forcedKill"] = True
                process.kill()
                process.wait(timeout=stop_timeout)
    finally:
        record["exitCode"] = process.returncode if process is not None else None
    return record


def execute(project: Path, engine: Path, freeze_path: Path, freeze_sha: str,
            build_root: Path, evidence: Path, display: str) -> dict:
    freeze = verify_freeze(project, engine, freeze_path, freeze_sha)
    require(build_root.resolve().is_relative_to((project / "builds").resolve()), "Build root must be inside project/builds")
    require(not build_root.exists(), "Build output already exists; preserve it and use a new attempt path")
    require(evidence.resolve().is_relative_to((project / "docs/verification-logs").resolve()),
            "Evidence must be in a new project verification-logs directory")
    require(not evidence.exists(), "Evidence attempt exists; never overwrite an earlier attempt")
    evidence.mkdir(parents=True)
    build_root.mkdir(parents=True)
    work = Path(tempfile.mkdtemp(prefix="draconia-card-export-"))
    report_path = evidence / "exports.json"
    report = {"schemaVersion": 1, "checkpoint": CHECKPOINT, "engine": "4.7.2.stable.official.ed1daf0bf",
              "engineSha256": sha256(engine), "acceptedForDevelopmentCheckpoint": False,
              "startedUtc": utc(), "workDirectory": str(work), "buildRoot": str(build_root.resolve()),
              "freeze": file_record(freeze_path), "integration": freeze["integration"],
              "runtimeManifest": freeze["runtimeManifest"], "stages": [], "limits": LIMITS}

    def publish() -> None:
        save_json(report_path, report)

    def stage(label: str, command: list[str], env: dict, timeout: int = 900) -> dict:
        log = evidence / (label + ".log")
        started = time.monotonic()
        record = {"stage": label, "command": command, "workingDirectory": str(project),
                  "startedUtc": utc(), "log": str(log),
                  "environment": {key: env.get(key, "") for key in ("DISPLAY", "LIBGL_ALWAYS_SOFTWARE",
                                  "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME")}}
        print("START", label, flush=True)
        record.update(run_owned_process(command, cwd=project, env=env, log=log, timeout=timeout))
        record["durationSeconds"] = round(time.monotonic() - started, 3)
        record["completedUtc"] = utc()
        if log.is_file():
            record["logSha256"] = sha256(log)
            record["logBytes"] = log.stat().st_size
            record["diagnostics"], record["blockingDiagnostics"] = diagnostics(log.read_text(errors="replace"))
        else:
            record["blockingDiagnostics"] = ["No stage log was created"]
        (evidence / (label + ".exit-code")).write_text(str(record["exitCode"]) + "\n")
        report["stages"].append(record)
        publish()
        print("END", label, record["exitCode"], record["durationSeconds"], flush=True)
        require(record["exitCode"] == 0 and not record["blockingDiagnostics"] and not record.get("failure")
                and not record.get("forcedTermination"),
                f"{label} failed; retain and inspect its raw log")
        return record

    publish()
    try:
        for record in freeze["runnerSources"]:
            shutil.copyfile(project / record["path"], evidence / Path(record["path"]).name)
        shutil.copyfile(freeze_path, evidence / "runtime-export-freeze.json")
        shutil.copyfile(project / INTEGRATION, evidence / "runtime-integration-at-export.json")
        shutil.copyfile(project / MANIFEST, evidence / "building-manifest-at-export.json")
        shutil.copyfile(project / freeze["runtimeGateEvidence"]["report"]["path"],
                        evidence / "runtime-gate-report-at-export.json")
        shutil.copyfile(project / freeze["runtimeGateEvidence"]["log"]["path"],
                        evidence / "runtime-gate-native-at-export.log")
        old = previous_build_inventory(project, build_root)
        save_json(evidence / "previous-builds-inventory.json", old)
        report["previousBuildInventorySha256"] = inventory_digest(old)
        env = os.environ.copy()
        env.update(DISPLAY=display, LIBGL_ALWAYS_SOFTWARE="1", GODOT_SILENCE_ROOT_WARNING="1",
                   XDG_DATA_HOME=str(project.parent / "analysis-tools/godot/data"),
                   XDG_CONFIG_HOME=str(work / "editor/config"), XDG_CACHE_HOME=str(work / "editor/cache"))
        for key in ("XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            Path(env[key]).mkdir(parents=True)
        report["import"] = stage("final-editor-import", [str(engine), "--headless", "--path", str(project),
                                                          "--editor", "--import"], env)
        require(runtime_inventory(project) == freeze["runtimeSources"],
                "Editor import changed source/import settings; record the change and obtain a new freeze")
        bindings = import_bindings(project, freeze)
        save_json(evidence / "fresh-import-bindings.json", bindings)
        report["freshImportBindings"] = file_record(evidence / "fresh-import-bindings.json")
        report["runtimeSourceInventorySha256"] = freeze["runtimeSourceInventorySha256"]
        for platform, preset, filename in [("Linux", "Linux", "Draconia.x86_64"),
                                           ("Windows", "Windows Desktop", "Draconia.exe")]:
            binary = build_root / platform.lower() / filename
            binary.parent.mkdir()
            exported = stage(platform.lower() + "-release-export", [str(engine), "--headless", "--path", str(project),
                                     "--export-release", preset, str(binary)], env)
            with binary.open("rb") as stream:
                magic = stream.read(4)
            require(magic == b"\x7fELF" if platform == "Linux" else magic.startswith(b"MZ"),
                    f"Unexpected {platform} executable signature")
            if platform == "Linux":
                binary.chmod(binary.stat().st_mode | 0o111)
            record = file_record(binary)
            report[platform] = {"binary": record.pop("path"), **record, "export": exported,
                                "runtimeVerified": False,
                                "crossExportExitCode": exported["exitCode"] if platform == "Windows" else None}
            publish()
            packed = verify_embedded_pack(binary, project=project, bindings=bindings,
                                           expected_manifest_sha=freeze["runtimeManifest"]["sha256"])
            inventory_path = evidence / (platform.lower() + "-embedded-pck-inventory.json")
            save_json(inventory_path, packed)
            report[platform]["embeddedPck"] = {**packed["pack"], "inventory": str(inventory_path),
                                               "inventorySha256": sha256(inventory_path)}
            require(runtime_inventory(project) == freeze["runtimeSources"], "Runtime source changed during export")
            require(import_bindings(project, freeze) == bindings, "Fresh import bytes changed during export")
            publish()
        report["runtimeSourceUnchangedDuringExports"] = True

        def native_update(native: dict) -> None:
            report["Linux"]["native"] = native
            publish()

        native = run_probe(Path(report["Linux"]["binary"]), evidence, display=display, on_update=native_update)
        report["Linux"]["native"] = native
        require(native.get("passed") is True, "Actual exported Linux Menu/Save & Quit probe failed")
        verify_freeze(project, engine, freeze_path, freeze_sha)
        require(previous_build_inventory(project, build_root) == old, "A previous native build changed")
        for platform in ("Linux", "Windows"):
            binary = Path(report[platform]["binary"])
            require(sha256(binary) == report[platform]["sha256"], f"{platform} binary changed after export")
        report["previousBuildsUnchanged"] = True
        report["Linux"]["runtimeVerified"] = True
        report["Windows"]["runtimeVerified"] = False
        report["acceptedForDevelopmentCheckpoint"] = True
        report["completedUtc"] = utc()
        publish()
        print("CARD_CHECKPOINT_EXPORT_PASSED", report_path, flush=True)
        return report
    except BaseException as error:
        report["failure"] = str(error) or type(error).__name__
        report["acceptedForDevelopmentCheckpoint"] = False
        report["completedUtc"] = utc()
        publish()
        print("CARD_CHECKPOINT_EXPORT_FAILED", report_path, str(error), flush=True)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=PROJECT)
    parser.add_argument("--engine", type=Path, default=ENGINE)
    modes = parser.add_subparsers(dest="mode")
    plan = modes.add_parser("plan", help="Read-only readiness check; no engine process")
    plan.add_argument("--integration-sha256")
    freeze = modes.add_parser("freeze", help="Seal identities after the owner releases the final runtime gate")
    freeze.add_argument("--integration-sha256", required=True)
    freeze.add_argument("--output", type=Path, required=True)
    run = modes.add_parser("execute", help="Import/export and probe only after explicit release-owner handoff")
    run.add_argument("--freeze", type=Path, required=True)
    run.add_argument("--freeze-sha256", required=True)
    run.add_argument("--build-root", type=Path, default=PROJECT / "builds/v0.3-card-reconstruction")
    run.add_argument("--evidence", type=Path,
                     default=PROJECT / "docs/verification-logs/native-v031-card-reconstruction-attempt01")
    run.add_argument("--display", default=":97")
    args = parser.parse_args()
    try:
        project, engine = args.project.resolve(), args.engine.resolve()
        if args.mode in (None, "plan"):
            result = preflight(project, engine, getattr(args, "integration_sha256", None))
        elif args.mode == "freeze":
            require(args.output.is_absolute(), "Freeze output must be an absolute path")
            result = create_freeze(project, engine, args.integration_sha256, args.output)
        else:
            result = execute(project, engine, args.freeze.resolve(), args.freeze_sha256,
                             args.build_root.resolve(), args.evidence.resolve(), args.display)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
        return 0
    except (GateError, OSError, ValueError, KeyError, struct.error) as error:
        print(f"Checkpoint gate: {error}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
