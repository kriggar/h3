#!/usr/bin/env python3
"""Package the current painting-led Blender workshop, never a playable release.

Plan:
  python tools/package_card_workshop.py --output /absolute/outside/project
  Add --evidence docs/verification-logs/card-reconstruction/CURRENT_BATCH
Build after all eight authoring owners have frozen their candidates:
  add --build --blender /absolute/path/to/blender

Each output is an ordinary independently readable ZIP, below 500,000,000 bytes.
Extract every numbered part into the same directory to restore Draconia/....
No source, candidate, original card, or runtime model is modified.
"""
from __future__ import annotations

import argparse
import ast
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import subprocess
import sys
import tempfile
import zipfile


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = "assets/models/source/towns/card_reconstruction"
STAGING = "assets/staging/card-reconstruction"
IDS = ("granary", "barracks", "market", "smithy",
       "shrine", "palisade", "wharf", "water_gate")
ATLAS = "assets/ui/manuscript/buildings.png"
ATLAS_SHA = "f1b2e11a4e82ae1aa84818acbed8653dee4303fa33c93ec10483662145e451be"
MAX_ZIP = 500_000_000
RAW_BUDGET = 440_000_000
TITLE = "Draconia-Card-Reconstruction-Workshop"
README = "docs/CARD_RECONSTRUCTION_WORKSHOP.md"
SKIP_DIRS = {"__pycache__", ".godot", ".git", ".openai", ".cache"}
SKIP_SUFFIXES = {".pyc", ".pyo", ".blend1", ".pending", ".tmp", ".zip"}
BANNED_SUFFIXES = {".exe", ".dll", ".so", ".pck", ".lod", ".snd", ".vid", ".h3m"}
HISTORICAL_INPUTS = {
    f"{STAGING}/barracks/iterations/native-review-v2/barracks.glb":
        "verify_barracks.py: unchanged exported door geometry and curves",
    f"{STAGING}/barracks/iterations/native-review-v2/manifest.json":
        "Provenance of the explicit Training Yard comparison input",
    f"{STAGING}/smithy/iterations/03/manifest.json":
        "inspect_smithy_chamber.py: original overall bounds",
    f"{STAGING}/smithy/iterations/04/smithy.glb":
        "inspect_roof_palette.py: exact pre-roof-factor embedded model",
    f"{STAGING}/smithy/iterations/04/manifest.json":
        "Provenance of the explicit Smithy palette comparison input",
    f"{STAGING}/wharf/iterations/03/wharf.glb":
        "inspect_roof_palette.py: exact pre-roof-factor embedded model",
    f"{STAGING}/wharf/iterations/03/manifest.json":
        "Provenance of the explicit Wharf palette comparison input",
}


class PackageError(Exception):
    pass


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def stamp(path: Path) -> tuple[int, int]:
    s = path.stat()
    return s.st_size, s.st_mtime_ns


def project_path(value: str) -> Path:
    """Map original absolute provenance into the current project by its suffix."""
    p = Path(value)
    if not p.is_absolute():
        candidate = PROJECT / p
    elif p.is_relative_to(PROJECT):
        candidate = p
    elif "/voievod/" in value:
        candidate = PROJECT / value.split("/voievod/", 1)[1]
    elif "/Draconia/" in value:
        candidate = PROJECT / value.split("/Draconia/", 1)[1]
    else:
        raise PackageError(f"Unmapped external source path: {value}")
    resolved = candidate.resolve()
    if not resolved.is_relative_to(PROJECT):
        raise PackageError(f"Source escapes project: {value}")
    return resolved


def omitted(path: Path) -> bool:
    return (any(p in SKIP_DIRS for p in path.parts)
            or path.suffix.lower() in SKIP_SUFFIXES
            or path.name.endswith(("~", ".blend2"))
            or ".pending." in path.name)


def collect(evidence: list[str]) -> tuple[list[dict], dict]:
    entries: dict[str, dict] = {}

    def add(path: Path, role: str) -> None:
        if path.is_symlink():
            raise PackageError(f"Symlink is not a portable workshop input: {path}")
        path = path.resolve()
        if not path.is_file() or not path.is_relative_to(PROJECT):
            raise PackageError(f"Missing/nonlocal workshop input: {path}")
        rel = path.relative_to(PROJECT).as_posix()
        if omitted(Path(rel)):
            return
        if path.suffix.lower() in BANNED_SUFFIXES:
            raise PackageError(f"Executable/proprietary payload forbidden: {rel}")
        with path.open("rb") as stream:
            magic = stream.read(4)
        if magic.startswith(b"MZ") or magic == b"\x7fELF":
            raise PackageError(f"Executable signature forbidden: {rel}")
        record = entries.setdefault(rel, {
            "path": path, "relative": rel, "identity": stamp(path), "roles": []})
        if role not in record["roles"]:
            record["roles"].append(role)

    def tree(relative: str, role: str) -> None:
        folder = PROJECT / relative
        if not folder.is_dir() or folder.is_symlink():
            raise PackageError(f"Missing/nonregular source directory: {relative}")
        for base, directories, files in os.walk(folder, followlinks=False):
            directories[:] = [d for d in sorted(directories) if d not in SKIP_DIRS]
            for d in directories:
                if (Path(base) / d).is_symlink():
                    raise PackageError(f"Source symlink directory: {Path(base)/d}")
            for name in sorted(files):
                add(Path(base) / name, role)

    for rel in [README, "LICENSE.txt", "ASSET_CREDITS.md", ATLAS,
                "docs/CARD_RECONSTRUCTION.md", "tools/package_card_workshop.py",
                "assets/models/source/towns/prepare_building_pbr.py",
                "assets/models/source/characters/prepare_surface_maps.py",
                "assets/models/source/characters/mara-pbr-v9/prepared/preparation.json",
                "assets/models/source/characters/mara-pbr-v9/prepared/rough_linen_neutral_albedo_2k.png"]:
        add(PROJECT / rel, "workshop_document_or_rebuild_input")
    tree(SOURCE, "current_authoring_and_source_inspection")
    tree("assets/models/source/towns/pbr-sources", "architectural_pbr_source_and_notices")
    # The original neutral-linen preparation script also processes caban,
    # brown leather and steel. Preserve its complete input closure, not just
    # the single neutral image currently consumed by buildings.
    tree("assets/models/source/characters/pbr-sources", "neutral_linen_preparer_input_closure")
    tree("assets/licenses", "license_and_provenance_notice")
    if (PROJECT / "assets/CINZEL-OFL.txt").is_file():
        add(PROJECT / "assets/CINZEL-OFL.txt", "retained_license_notice")
    for rel in ("tests/render_card_reconstruction.gd",
                "tests/render_card_camera_compare.gd"):
        if (PROJECT / rel).is_file():
            add(PROJECT / rel, "native_inspection_script_requires_full_game_project")
            if (PROJECT / (rel + ".uid")).is_file():
                add(PROJECT / (rel + ".uid"), "native_script_uid")

    candidates = {}
    freeze_rows = {}
    for name, bank in (("root-freeze.json", "candidates"),
                       ("assets-agent-freeze.json", "assets")):
        path = PROJECT / STAGING / name
        if path.is_file():
            data = json.loads(path.read_text())
            for record in data.get(bank, []):
                freeze_rows[record["id"]] = record
            add(path, "current_author_freeze_index")
    for bid in IDS:
        folder = PROJECT / STAGING / bid
        manifest_path = folder / "manifest.json"
        m = json.loads(manifest_path.read_text())
        if m.get("id") != bid or m.get("authority", {}).get("sha256") != ATLAS_SHA:
            raise PackageError(f"Wrong candidate ID or painted authority: {bid}")
        if m.get("runtimePromoted") or m.get("accepted"):
            raise PackageError(f"Workshop expects a staged unaccepted candidate: {bid}")
        # Current root-level files only. No recursive iteration-tree sweep.
        for p in sorted(folder.iterdir()):
            if p.is_file():
                add(p, "current_candidate_or_local_evidence")
        if not (folder / ".gdignore").is_file():
            raise PackageError(f"Candidate import exclusion missing: {bid}")
        for kind in ("glb", "blend"):
            record = m["files"][kind]
            p = folder / record["file"]
            if sha(p) != record["sha256"]:
                raise PackageError(f"Candidate artifact changed since manifest: {bid}/{kind}")
        for preview in m["files"].get("previews", []):
            if sha(folder / preview["file"]) != preview["sha256"]:
                raise PackageError(f"Candidate preview changed: {bid}/{preview['file']}")
        for record in m["sourceFiles"]:
            p = project_path(record["path"])
            if sha(p) != record["sha256"]:
                raise PackageError(f"Authoring dependency changed since export: {bid}: {p}")
            add(p, "manifest_bound_authoring_dependency")
        for relative, expected in m["materialProvenance"]["sourceManifestHashes"].items():
            p = PROJECT / "assets/models/source/towns/pbr-sources" / relative
            if sha(p) != expected:
                raise PackageError(f"Material provenance manifest changed: {bid}: {relative}")
        freeze = freeze_rows.get(bid)
        if freeze:
            for key, expected in (("glbSha256", m["files"]["glb"]["sha256"]),
                                  ("blendSha256", m["files"]["blend"]["sha256"]),
                                  ("manifestSha256", sha(manifest_path))):
                if freeze.get(key) != expected:
                    raise PackageError(f"Author freeze index is stale: {bid}: {key}")
        revision = (freeze.get("revision") if freeze else
                    m.get("roofPaletteRevision", m.get("clothCorrection", {})).get("revision"))
        candidates[bid] = {
            "manifest": manifest_path.relative_to(PROJECT).as_posix(),
            "manifestSha256": sha(manifest_path),
            "glbSha256": m["files"]["glb"]["sha256"],
            "blendSha256": m["files"]["blend"]["sha256"],
            "revision": revision or m.get("reviewState", {}).get("revision"),
            "status": m.get("status"),
            "godotBounds": m["godotBounds"],
            "godotMotionBounds": m["godotMotionBounds"],
            "productionAccepted": False,
        }
    # Preserve stage ignores at each authoring boundary when present.
    for rel in ("assets/staging/.gdignore", "assets/models/source/.gdignore",
                f"{STAGING}/.gdignore"):
        if (PROJECT / rel).is_file():
            add(PROJECT / rel, "godot_import_exclusion")
    for rel, reason in HISTORICAL_INPUTS.items():
        add(PROJECT / rel, "explicit_historical_verification_input")
    for value in evidence:
        p = project_path(value)
        rel = p.relative_to(PROJECT).as_posix()
        if not rel.startswith("docs/verification-logs/card-reconstruction/"):
            raise PackageError(f"Evidence must be inside the card-reconstruction log tree: {rel}")
        if p.is_dir():
            tree(rel, "selected_native_or_source_review_evidence")
        else:
            add(p, "selected_native_or_source_review_evidence")
    if sha(PROJECT / ATLAS) != ATLAS_SHA:
        raise PackageError("The locked original painted atlas changed")
    result = sorted(entries.values(), key=lambda row: row["relative"])
    for row in result:
        row["bytes"] = row["identity"][0]
        row["sha256"] = sha(row["path"])
        if stamp(row["path"]) != row["identity"]:
            raise PackageError(f"Input changed while inventoried: {row['relative']}")
    return result, candidates


def model_closure(entries: list[dict]) -> dict:
    models = []
    for entry in entries:
        if entry["path"].suffix.lower() != ".glb":
            continue
        raw = entry["path"].read_bytes()
        if len(raw) < 20:
            raise PackageError(f"Truncated GLB: {entry['relative']}")
        magic, version, size = struct.unpack_from("<4sII", raw)
        if magic != b"glTF" or version != 2 or size != len(raw):
            raise PackageError(f"Invalid GLB header: {entry['relative']}")
        pos, document, binary = 12, None, None
        while pos < len(raw):
            if pos + 8 > len(raw):
                raise PackageError("Truncated GLB chunk header")
            length, kind = struct.unpack_from("<II", raw, pos)
            pos += 8
            if length % 4 or pos + length > len(raw):
                raise PackageError("Invalid GLB chunk length")
            chunk = raw[pos:pos + length]
            if kind == 0x4E4F534A:
                if document is not None or pos != 20:
                    raise PackageError("Invalid/duplicate GLB JSON chunk")
                document = json.loads(chunk)
            elif kind == 0x004E4942:
                if binary is not None:
                    raise PackageError("Duplicate GLB BIN chunk")
                binary = chunk
            pos += length
        if not isinstance(document, dict) or binary is None:
            raise PackageError("Missing GLB JSON or embedded BIN")
        if str(document.get("asset", {}).get("version")) != "2.0":
            raise PackageError("Unsupported glTF version")
        buffers = document.get("buffers", [])
        if len(buffers) != 1 or "uri" in buffers[0]:
            raise PackageError(f"Model does not have one embedded buffer: {entry['relative']}")
        declared = buffers[0].get("byteLength", -1)
        if not 0 <= len(binary) - declared <= 3:
            raise PackageError("GLB buffer length differs from embedded bytes")
        views = document.get("bufferViews", [])
        for view in views:
            if view.get("buffer", 0) != 0:
                raise PackageError("GLB view refers to an unavailable buffer")
            start, length = view.get("byteOffset", 0), view.get("byteLength", -1)
            if start < 0 or length < 0 or start + length > declared:
                raise PackageError("GLB view exceeds its embedded buffer")
        images = []
        for image in document.get("images", []):
            if "uri" in image or "bufferView" not in image:
                raise PackageError(f"External/unbound GLB image: {entry['relative']}")
            index = image["bufferView"]
            if not isinstance(index, int) or not 0 <= index < len(views):
                raise PackageError("Invalid GLB image view")
            view = views[index]
            start = view.get("byteOffset", 0)
            data = binary[start:start + view["byteLength"]]
            mime = image.get("mimeType")
            good = ((mime == "image/png" and data.startswith(b"\x89PNG\r\n\x1a\n"))
                    or (mime == "image/jpeg" and data.startswith(b"\xff\xd8")))
            if not good:
                raise PackageError("Embedded GLB image MIME/signature mismatch")
            images.append({"name": image.get("name"), "mimeType": mime,
                           "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
        clips = sorted(a.get("name", "") for a in document.get("animations", []))
        if "/iterations/" not in entry["relative"] and clips != ["RESET", "hover"]:
            raise PackageError(f"Current model lacks the agreed animation clips: {entry['relative']}")
        models.append({"path": entry["relative"], "sha256": entry["sha256"],
                       "embeddedBufferBytes": declared, "images": images,
                       "clips": clips, "externalDependencies": []})
    return {"scope": "Actual GLB 2 JSON/BIN bounds, embedded image signatures and dependency closure",
            "models": models, "externalDependencies": [], "passed": True}


def source_closure(entries: list[dict], candidates: dict) -> dict:
    members = {row["relative"]: row for row in entries}
    imports = []
    external_modules = set()
    for row in entries:
        if not row["relative"].startswith(SOURCE + "/") or row["path"].suffix != ".py":
            continue
        tree = ast.parse(row["path"].read_text(), filename=row["relative"])
        for node in ast.walk(tree):
            names = ([n.name.split(".")[0] for n in node.names] if isinstance(node, ast.Import)
                     else [node.module.split(".")[0]] if isinstance(node, ast.ImportFrom) and node.module
                     else [])
            for name in names:
                local = f"{SOURCE}/{name}.py"
                if (PROJECT / local).is_file():
                    if local not in members:
                        raise PackageError(f"Local Python import omitted: {local}")
                    imports.append({"from": row["relative"], "to": local})
                else:
                    external_modules.add(name)
    material_checks = []
    def check_material(relative: str, expected: str, label: str) -> None:
        if relative not in members or members[relative]["sha256"] != expected:
            raise PackageError(f"Missing/changed material source or derivative: {relative}")
        material_checks.append({"path": relative, "sha256": expected, "scope": label})
    town_prefix = "assets/models/source/towns/pbr-sources/"
    town = json.loads((PROJECT / town_prefix / "manifest.json").read_text())
    for asset in town["assets"]:
        for record in asset["maps"].values():
            check_material(town_prefix + record["file"], record["sha256"], "publisher map bytes")
    metal = json.loads((PROJECT / town_prefix / "metal012/manifest.json").read_text())
    for record in metal["files"]:
        check_material(town_prefix + "metal012/" + Path(record["path"]).name,
                       record["sha256"], "unchanged copy of publisher steel map")
    runtime = json.loads((PROJECT / town_prefix / "runtime/manifest.json").read_text())
    check_material("assets/models/source/towns/" + runtime["script"],
                   runtime["scriptSha256"], "retained metal derivative script")
    for record in runtime["files"]:
        check_material(town_prefix + record["file"], record["sha256"], "recorded technical derivative")
    # Exact original material files consumed by the broader neutral-bake script.
    character = json.loads((PROJECT / "assets/models/source/characters/pbr-sources/manifest.json").read_text())
    for record in character["files"]:
        rel = record["path"]
        if Path(rel).suffix.lower() == ".zip":
            continue  # Extracted maps plus archive hash/provenance remain.
        check_material(rel, record["sha256"], "neutral-linen preparer complete original input")
    sack = json.loads((PROJECT / SOURCE / "prepared/sack_linen_preparation.json").read_text())
    for key in ("source", "output", "authoringScript"):
        record = sack[key]
        check_material(record["file"], record["sha256"], "separate building sack bake")
    reports = {}
    for bid, candidate in candidates.items():
        matched = []
        for row in entries:
            if row["path"].suffix != ".json":
                continue
            try:
                d = json.loads(row["path"].read_text())
            except (UnicodeError, json.JSONDecodeError):
                continue
            if not isinstance(d, dict):
                continue
            source = d.get("source", {})
            source = source if isinstance(source, dict) else {}
            glb = d.get("glbSha256", source.get("glbSha256", source.get(bid + ".glb")))
            blend = d.get("blendSha256", source.get("blendSha256", source.get(bid + ".blend")))
            failures = d.get("failed", d.get("failures"))
            if glb == candidate["glbSha256"] and blend == candidate["blendSha256"] and failures == 0:
                if not isinstance(d.get("checks"), list) or not d["checks"]:
                    continue
                if not all(check.get("passed") is True for check in d["checks"]):
                    continue
                validator = (d.get("validationScriptSha256") or d.get("scriptSha256")
                             or source.get("inspectionScriptSha256") or source.get("inspectionSha256"))
                if validator and not any(x["sha256"] == validator and x["path"].suffix == ".py" for x in entries):
                    raise PackageError(f"Source report validator omitted/changed: {row['relative']}")
                matched.append({"path": row["relative"], "sha256": row["sha256"],
                                "checks": len(d["checks"]), "failures": 0,
                                "scope": d.get("scope")})
        reports[bid] = matched
    return {"localModuleEdges": imports, "blenderOrPythonModules": sorted(external_modules),
            "verifiedMaterialInputsAndDerivatives": material_checks,
            "boundedSourceReportsMatchingCurrentArtifacts": reports,
            "missingCurrentSourceReports": [bid for bid, records in reports.items() if not records],
            "historicalVerificationInputs": HISTORICAL_INPUTS,
            "absoluteManifestPaths": "Original provenance remains verbatim; package verification resolves its project-relative suffix. Regeneration writes new local paths."}


def native_closure(entries: list[dict], candidates: dict) -> dict:
    members = {row["relative"]: row for row in entries}
    indexes = [row for row in entries
               if row["path"].name.startswith("native-candidate-set-")
               and row["path"].suffix == ".json"]
    if not indexes:
        return {"status": "no_current_native_index_selected", "verified": False}
    if len(indexes) != 1:
        raise PackageError("Select one authoritative current native-candidate-set index")
    entry = indexes[0]
    data = json.loads(entry["path"].read_text())
    if (data["authority"]["sha256"] != ATLAS_SHA
            or data["authority"].get("cardReplacementAllowed") is not False
            or set(data["candidates"]) != set(IDS)
            or data.get("runtimePromoted") is not False):
        raise PackageError("Native index authority, scope or current roster is inconsistent")
    verified_captures = set()
    for bid, record in data["candidates"].items():
        for key in ("glbSha256", "blendSha256", "manifestSha256"):
            if record[key] != candidates[bid][key]:
                raise PackageError(f"Native evidence binds a different candidate: {bid}/{key}")
        for flag in ("nativeTechnicalPass", "exactRestoredPose",
                     "sourcePreservedDuringLiveMotion", "allTexturedChannelsHaveMipmaps"):
            if record.get(flag) is not True:
                raise PackageError(f"Current native technical gate not met: {bid}/{flag}")
        for capture in record["captures"]:
            rel = capture["path"]
            if rel not in members or members[rel]["sha256"] != capture["sha256"]:
                raise PackageError(f"Native inspected capture missing/changed: {rel}")
            verified_captures.add(rel)
    reports = []
    for name, record in data["reports"].items():
        for path_key, hash_key in (("path", "sha256"), ("reviewPath", "reviewSha256")):
            rel = record[path_key]
            if rel not in members or members[rel]["sha256"] != record[hash_key]:
                raise PackageError(f"Native report/review missing or changed: {rel}")
        if record["failures"] != 0:
            raise PackageError(f"Native evidence index records unresolved failure: {name}")
        reports.append({"name": name, **record})
    return {"status": "current_native_evidence_byte_bound", "verified": True,
            "index": entry["relative"], "indexSha256": entry["sha256"],
            "currentModels": len(data["candidates"]),
            "verifiedInspectedCurrentModelCaptures": len(verified_captures),
            "reports": reports, "countPolicy": data["countPolicy"],
            "wholeTownAcceptance": data["finalWholeTownAcceptance"],
            "productionArtAcceptance": False}


# Executed only in an isolated extraction. It does not save the packed scenes.
# It separately exercises actual construction code with the expensive exporter
# stubbed, so this is dependency closure rather than a claimed rerender test.
BLENDER_AUDIT = r'''
import bpy, hashlib, json, runpy, sys, traceback
from pathlib import Path
args=sys.argv[sys.argv.index("--")+1:]
root=Path(args[0]).resolve(); out=Path(args[1])
inventory=json.loads((root/"workshop-inventory.json").read_text())
members={r["path"]:r for r in inventory["files"]}
source=root/"assets/models/source/towns/card_reconstruction"
staging=root/"assets/staging/card-reconstruction"
ids=inventory["buildingIds"]
report={"scope":"Read-only packed Blender images and isolated actual construction dependency closure; no source render, animation re-acceptance or production-art approval",
        "blenderVersion":bpy.app.version_string,"packedScenes":[],"construction":[],"failures":[]}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
try:
 if tuple(bpy.app.version[:3]) != (4,5,14):
  raise RuntimeError("This frozen workshop audit requires Blender 4.5.14; received "+bpy.app.version_string)
 for bid in ids:
  path=staging/bid/(bid+".blend")
  before=sha(path)
  bpy.ops.wm.open_mainfile(filepath=str(path))
  if bpy.data.libraries:raise RuntimeError("Linked external Blender library in "+bid)
  rows=[]
  for image in bpy.data.images:
   if image.source!="FILE" or image.users==0:continue
   if not image.packed_file or image.packed_file.size<=0:
    raise RuntimeError("Unpacked used file image: "+bid+":"+image.name)
   data=bytes(image.packed_file.data); digest=hashlib.sha256(data).hexdigest()
   matches=[rel for rel,r in members.items() if r["sha256"]==digest]
   if not matches:raise RuntimeError("Packed source image has no preserved source bytes: "+bid+":"+image.name)
   rows.append({"name":image.name,"packedBytes":len(data),"sha256":digest,"preservedSources":matches,
                "size":list(image.size),"colorSpace":image.colorspace_settings.name})
  if not rows:raise RuntimeError("No packed material images in "+bid)
  if sha(path)!=before:raise RuntimeError("Packed master changed during inspection")
  report["packedScenes"].append({"id":bid,"sha256":before,"usedPackedImages":rows,"libraries":0,"unchanged":True})
 sys.path.insert(0,str(source))
 import common
 original_export=common.export_candidate
 def inspect_construction(builder,building_id,output_dir=None,**kw):
  if output_dir is not None:raise RuntimeError("Unexpected alternate authoring destination")
  objects=builder.finish()
  if not objects:raise RuntimeError("Builder made no meshes")
  paths=[]
  for image in bpy.data.images:
   if image.source!="FILE" or image.users==0:continue
   p=Path(bpy.path.abspath(image.filepath)).resolve()
   if not p.is_relative_to(root):raise RuntimeError("Construction read outside extracted workshop: "+str(p))
   if not p.is_file():raise RuntimeError("Construction dependency missing: "+str(p))
   relative=p.relative_to(root).as_posix()
   if relative not in members:raise RuntimeError("Uninventoried construction input: "+relative)
   paths.append(relative)
  manifest=json.loads((staging/building_id/"manifest.json").read_text())
  script=Path(kw["authoring_script"]).resolve()
  manifest["sourceFiles"]=[{"path":str(source/"common.py"),"sha256":sha(source/"common.py")},
                           {"path":str(script),"sha256":sha(script)}]
  report["construction"].append({"id":building_id,"groups":len(builder.groups),
      "vertices":sum(len(g[0]) for g in builder.groups.values()),
      "materialInputs":sorted(set(paths)),"actualBuilderExecuted":True,
      "exportAndRenderExecuted":False})
  return manifest
 common.export_candidate=inspect_construction
 for bid in ids:
  bpy.ops.wm.read_factory_settings(use_empty=True)
  # The import cache contains helpers only; each entry runs its actual main.
  runpy.run_path(str(source/(bid+".py")),run_name="__main__")
 common.export_candidate=original_export
except Exception:
 report["failures"].append(traceback.format_exc())
finally:
 out.write_text(json.dumps(report,indent=2)+"\n")
if report["failures"]:raise RuntimeError(report["failures"][0])
print("WORKSHOP_BLENDER_DEPENDENCIES",len(report["packedScenes"]),"packed scenes",len(report["construction"]),"actual builders",flush=True)
'''


def portable_entries(entries: list[dict]) -> list[dict]:
    return [{"path": row["relative"], "bytes": row["bytes"], "sha256": row["sha256"],
             "roles": row["roles"]} for row in entries]


def check_snapshot(entries: list[dict]) -> None:
    for row in entries:
        if stamp(row["path"]) != row["identity"] or sha(row["path"]) != row["sha256"]:
            raise PackageError(f"Input changed after inventory: {row['relative']}")


def split_entries(entries: list[dict]) -> list[list[dict]]:
    chunks, chunk, size = [], [], 0
    for row in entries:
        if row["bytes"] > RAW_BUDGET:
            raise PackageError(f"Single file exceeds portable part budget: {row['relative']}")
        if chunk and size + row["bytes"] > RAW_BUDGET:
            chunks.append(chunk)
            chunk, size = [], 0
        chunk.append(row)
        size += row["bytes"]
    if chunk:
        chunks.append(chunk)
    return chunks


def verify_zip(path: Path, expected: dict[str, tuple[int, str]]) -> dict:
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or set(names) != set(expected):
            raise PackageError(f"Unexpected/duplicate archive members: {path.name}")
        for info in archive.infolist():
            member = PurePosixPath(info.filename)
            if member.is_absolute() or ".." in member.parts or not info.filename.startswith("Draconia/"):
                raise PackageError(f"Unsafe member path: {info.filename}")
            if stat.S_ISLNK(info.external_attr >> 16):
                raise PackageError(f"Symlink member: {info.filename}")
            count, digest = 0, hashlib.sha256()
            with archive.open(info) as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    count += len(block)
                    digest.update(block)
            # ZipExtFile reads validate the member CRC as well as this SHA.
            if (count, digest.hexdigest()) != expected[info.filename]:
                raise PackageError(f"Archive member hash/size differs: {info.filename}")
    if path.stat().st_size >= MAX_ZIP:
        raise PackageError(f"Archive exceeds strict 500 MB cap: {path.name}")
    return {"members": len(expected), "allMemberSha256AndCrcVerified": True,
            "bytes": path.stat().st_size, "sha256": sha(path)}


def build(output: Path, entries: list[dict], inventory: dict,
          blender: Path, chunks: list[list[dict]]) -> dict:
    missing = inventory["sourceClosure"]["missingCurrentSourceReports"]
    if missing:
        raise PackageError("No successful current source-mechanics report for: " + ", ".join(missing))
    if not inventory["nativeEvidence"]["verified"]:
        raise PackageError("Select the final native-candidate-set index and all of its report/capture directories")
    if not blender.is_absolute() or not blender.is_file():
        raise PackageError("--blender must point to an existing absolute executable")
    metadata = json_bytes(inventory)
    names = [f"{TITLE}-{i+1:02}.zip" for i in range(len(chunks))]
    for name in names:
        if (output / name).exists() or (output / (name + ".pending")).exists():
            raise PackageError(f"Choose a new output directory; preserve existing artifact: {name}")
    pending = []
    zip_reports = []
    check_snapshot(entries)
    try:
        for index, chunk in enumerate(chunks):
            path = output / (names[index] + ".pending")
            expected = {}
            with zipfile.ZipFile(path, "x", compression=zipfile.ZIP_DEFLATED,
                                 compresslevel=6, allowZip64=True) as archive:
                for row in chunk:
                    member = "Draconia/" + row["relative"]
                    archive.write(row["path"], member)
                    expected[member] = (row["bytes"], row["sha256"])
                info = zipfile.ZipInfo("Draconia/workshop-inventory.json", (2026, 1, 1, 0, 0, 0))
                info.external_attr = (stat.S_IFREG | 0o644) << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, metadata)
                expected[info.filename] = (len(metadata), hashlib.sha256(metadata).hexdigest())
            report = verify_zip(path, expected)
            report["file"] = names[index]
            zip_reports.append(report)
            pending.append(path)
            print(f"Verified archive part {index+1}/{len(chunks)}: {report['bytes']} bytes", flush=True)
        # Open only the extracted copies, with packed textures. Actual builder
        # execution also occurs here; it cannot write the original candidates.
        with tempfile.TemporaryDirectory(prefix="draconia-card-workshop-", dir=output) as temp:
            extracted = Path(temp)
            for path in pending:
                with zipfile.ZipFile(path) as archive:
                    archive.extractall(extracted)
            root = extracted / "Draconia"
            for row in inventory["files"]:
                p = root / row["path"]
                if not p.is_file() or p.stat().st_size != row["bytes"] or sha(p) != row["sha256"]:
                    raise PackageError(f"Extraction did not preserve member: {row['path']}")
            audit = extracted / "audit_blender_workshop.py"
            audit.write_text(BLENDER_AUDIT)
            report_path = output / "blender-dependency-report.json"
            log_path = output / "blender-dependency.log"
            cmd = [str(blender), "--background", "--factory-startup", "--disable-autoexec",
                   "--threads", "2", "--python-exit-code", "1", "--python", str(audit),
                   "--", str(root), str(report_path)]
            with log_path.open("xb") as log:
                process = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, check=False)
            audit_result = json.loads(report_path.read_text()) if report_path.is_file() else {}
            if (process.returncode or audit_result.get("failures")
                    or len(audit_result.get("packedScenes", [])) != 8
                    or len(audit_result.get("construction", [])) != 8):
                raise PackageError(f"Blender dependency audit failed; retained log: {log_path}")
            log_text = log_path.read_text(errors="replace")
            if re.search(r"Traceback|Error:|Segmentation fault", log_text):
                raise PackageError(f"Blender error found despite exit code; inspect {log_path}")
            blender_evidence = {
                "command": cmd, "exitCode": process.returncode,
                "log": log_path.name, "logSha256": sha(log_path),
                "report": report_path.name, "reportSha256": sha(report_path),
                "scriptSha256": hashlib.sha256(BLENDER_AUDIT.encode()).hexdigest(),
                "blenderExecutableSha256": sha(blender),
                "scope": audit_result["scope"]}
        check_snapshot(entries)
        for path, name in zip(pending, names):
            path.rename(output / name)
        return {"status": "verified_candidate_workshop_not_playable_release",
                "archives": zip_reports, "blenderDependencyAudit": blender_evidence}
    except Exception:
        # Failed attempt evidence stays in the output directory, with .pending
        # names so it cannot be mistaken for a successfully published archive.
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--evidence", action="append", default=[],
                        help="Project-relative current source/native report file or directory; repeatable")
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--blender", type=Path)
    args = parser.parse_args()
    if not args.output.is_absolute():
        raise PackageError("--output must be absolute")
    output = args.output.resolve()
    if output == PROJECT or output.is_relative_to(PROJECT):
        raise PackageError("Output must be outside the editable project")
    output.mkdir(parents=True, exist_ok=True)
    entries, candidates = collect(args.evidence)
    inventory = {
        "schemaVersion": 1,
        "createdUtc": datetime.now(timezone.utc).isoformat(),
        "title": TITLE, "buildingIds": list(IDS), "candidates": candidates,
        "status": "staged original-painting-led candidates; no production-art approval",
        "paintedAuthority": {"file": ATLAS, "sha256": ATLAS_SHA, "unchanged": True},
        "files": portable_entries(entries),
        "modelClosure": model_closure(entries),
        "sourceClosure": source_closure(entries, candidates),
        "nativeEvidence": native_closure(entries, candidates),
        "selectedEvidence": args.evidence,
        "exclusions": ["Runtime game/executables and external research",
                       "Generated Godot/Python caches and Blender automatic backups",
                       "Redundant complete iteration trees; only named verifier inputs retained",
                       "Duplicate source download ZIPs; extracted inputs and original provenance retained"],
        "limitations": [
            "Workshop preserves source bytes and dependencies; it is not a playable release.",
            "Painted cards remain design authority; native model renders must not replace them.",
            "Passed technical checks do not grant visual production approval or target-GPU performance acceptance.",
            "Unseen rear construction is authored interpretation of illustrative perspective.",
            "Authored local hover motion is not worker AI, construction simulation or physical bearing/fluid simulation.",
            "Native inspection scripts need the corresponding full Draconia project; its runtime is intentionally absent.",
            "Original absolute provenance is retained; regenerate a working copy before rerunning validators that read absolute sourceFiles paths."
        ]}
    chunks = split_entries(entries)
    plan = {"files": len(entries), "rawBytes": sum(row["bytes"] for row in entries),
            "archiveParts": len(chunks), "rawPartBudgets": [sum(r["bytes"] for r in c) for c in chunks],
            "strictArchiveLimitBytes": MAX_ZIP,
            "missingCurrentSourceReports": inventory["sourceClosure"]["missingCurrentSourceReports"],
            "candidateHashes": {bid: d["glbSha256"] for bid, d in candidates.items()}}
    plan_path = output / "workshop-plan.json"
    if args.build and plan_path.exists():
        raise PackageError("Build into a fresh output directory so prior plans/evidence remain immutable")
    plan_path.write_bytes(json_bytes({"plan": plan, "inventory": inventory}))
    print(json.dumps(plan, indent=2), flush=True)
    if not args.build:
        print("Plan only; no archive, Blender run, or source mutation.", flush=True)
        return 0
    if args.blender is None:
        raise PackageError("--build requires --blender for actual packed-source and construction checks")
    receipt = build(output, entries, inventory, args.blender, chunks)
    receipt.update({"createdUtc": datetime.now(timezone.utc).isoformat(),
                    "inventorySha256": hashlib.sha256(json_bytes(inventory)).hexdigest(),
                    "planSha256": sha(plan_path),
                    "inputFileCount": len(entries), "inputRawBytes": plan["rawBytes"],
                    "readme": README, "productionAccepted": False})
    (output / "workshop-receipt.json").write_bytes(json_bytes(receipt))
    (output / "README.md").write_bytes((PROJECT / README).read_bytes())
    print(json.dumps(receipt, indent=2), flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (PackageError, OSError, ValueError, KeyError, zipfile.BadZipFile) as exc:
        print("WORKSHOP PACKAGING BLOCKED:", exc, file=sys.stderr)
        raise SystemExit(1)
