#!/usr/bin/env python3
"""Package the editable 0.3 project and optional art sources; never export a game.

Plan: python tools/package_source_v03.py --output /absolute/outside/project
Build art now: add --build --scope art
Final project: add --build --scope project (requires the action entry scene)
Split a large project into whole-file parts: add --split-project
Verification evidence: add --build --scope verification
All archives preserve Draconia/... paths and are limited to 500,000,000 bytes.
"""
from __future__ import annotations
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import sys
import tempfile
import zipfile
from urllib.parse import unquote, urlsplit

PROJECT = Path(__file__).resolve().parents[1]
MAX_ARCHIVE = 500_000_000
ART_RAW_BUDGET = 440_000_000
PROJECT_RAW_BUDGET = 440_000_000
RELEASE_SERIES = "0.3"
ROOT_FILES = {"project.godot", "main.tscn", "redesign.tscn", "export_presets.cfg", "README.md", "LICENSE.txt", "ASSET_CREDITS.md", "icon.svg", "icon.svg.import", ".gitignore"}
ROOT_DIRS = {"assets", "data", "docs", "game", "tests", "tools", "research"}
SKIP_DIRS = {".godot", ".git", ".openai", "builds", "dist", "export_templates", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".cache", ".venv", "venv", "node_modules", ".aws", ".ssh", ".gnupg", ".codex", ".agents"}
SKIP_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini", "export_credentials.cfg"}
BANNED_SUFFIXES = {".exe", ".dll", ".so", ".dylib", ".msi", ".wasm", ".pck", ".lod", ".snd", ".vid", ".h3m"}
ART_PREFIXES = ("assets/staging/", "assets/models/source/", "assets/animated/source/")
REQUIRED = {"project.godot", "redesign.tscn", "README.md", "LICENSE.txt", "ASSET_CREDITS.md", "game/redesign/game_shell.gd", "game/redesign/realm_rules.gd", "game/redesign/action_rules.gd", "game/redesign/item_rules.gd", "assets/models/mara/mara.glb", "assets/models/mara/equipment/manifest.json", "assets/models/mara/equipment/vowkeeper.glb", "assets/models/mara/equipment/bellworn-cowl.glb", "docs/GAME_DESIGN.md", "docs/HERO_ROSTER.md", "docs/CREATURE_ROSTER.md", "data/hero_roster.json", "data/creature_roster.json", "tools/package_source_v03.py", "tools/package_native_v03.py", "assets/licenses/CC0-1.0.txt", "assets/licenses/GODOT-LICENSE.txt", "assets/licenses/GODOT-COPYRIGHT.txt", "assets/licenses/BUILDING-PBR-NOTICES.md", "assets/models/towns/ashen_crown/manifest.json"}


class PackageError(Exception):
    pass


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def identity(path: Path) -> tuple[int, int]:
    s = path.stat()
    return s.st_size, s.st_mtime_ns


def omitted(path: PurePosixPath) -> bool:
    if any(part in SKIP_DIRS for part in path.parts[:-1]):
        return True
    name = path.name
    return (name in SKIP_NAMES or name.endswith((".pyc", ".pyo", ".pending", ".tmp", ".blend1"))
            or ".pending." in name or name == ".env"
            or (name.startswith(".env.") and not name.endswith((".example", ".sample", ".template"))))


def group_for(relative: str) -> str:
    if relative.startswith(("docs/verification-logs/", "docs/screenshots/", "tests/",
                            "assets/staging/card-reconstruction/prior-runtime-installation/")):
        return "Verification"
    if relative.startswith("assets/staging/ileana-mpfb-proof/") and not relative.startswith("assets/staging/ileana-mpfb-proof/source/"):
        return "Hero-Workshop"
    if relative.startswith(ART_PREFIXES):
        return "Art-Sources"
    return "Godot-Project"


def inventory() -> tuple[list[dict], dict]:
    entries = []
    skipped = Counter()
    for folder, directories, files in os.walk(PROJECT, followlinks=False):
        parent = Path(folder)
        relative_dir = parent.relative_to(PROJECT)
        kept = []
        for name in sorted(directories):
            child = parent / name
            rel = child.relative_to(PROJECT).as_posix()
            if name in SKIP_DIRS or (parent == PROJECT and name not in ROOT_DIRS):
                skipped["cache/build/private-or-unlisted-directory"] += 1
                continue
            if rel == "research/evidence":
                skipped["raw-original-game-analysis-evidence"] += 1
                continue
            if child.is_symlink():
                raise PackageError(f"Included source directory is a symlink: {rel}")
            kept.append(name)
        directories[:] = kept
        for name in sorted(files):
            path = parent / name
            rel = path.relative_to(PROJECT).as_posix()
            if parent == PROJECT and name not in ROOT_FILES:
                skipped["unlisted-root-file"] += 1
                continue
            if rel.startswith("research/") and rel not in ["research/RE_FINDINGS.md", "research/EVIDENCE_INDEX.md"]:
                skipped["non-release-research-file"] += 1
                continue
            if omitted(PurePosixPath(rel)):
                skipped["cache/backup/private-file"] += 1
                continue
            if path.is_symlink() or not path.is_file():
                raise PackageError(f"Expected a regular source file: {rel}")
            entries.append({"path": path, "relative": rel, "group": group_for(rel), "identity": identity(path)})
    members = {e["relative"] for e in entries if e["group"] == "Godot-Project"}
    missing = REQUIRED - members
    if missing:
        raise PackageError("Required project files missing: " + ", ".join(sorted(missing)))
    # Current Markdown is the complete design. Do not silently insert the old
    # external PDF, whose building-art contract was explicitly superseded.
    # A revised PDF may be included deliberately after its separate review.
    return sorted(entries, key=lambda e: e["relative"]), dict(skipped)


def check_file(entry: dict) -> None:
    rel = entry["relative"]
    lower = rel.lower()
    if PurePosixPath(lower).suffix in BANNED_SUFFIXES or "heroes3.exe" in lower or "hd_launcher.exe" in lower:
        raise PackageError(f"Executable/proprietary game payload is forbidden: {rel}")
    with entry["path"].open("rb") as f:
        magic = f.read(4)
    if magic.startswith(b"MZ") or magic == b"\x7fELF":
        raise PackageError(f"Executable signature is forbidden in a source archive: {rel}")
    if entry["path"].suffix.lower() == ".zip":
        with zipfile.ZipFile(entry["path"]) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                name = PurePosixPath(info.filename)
                if name.is_absolute() or ".." in name.parts:
                    raise PackageError(f"Unsafe nested source ZIP path: {rel}: {info.filename}")
                if name.suffix.lower() in BANNED_SUFFIXES:
                    raise PackageError(f"Executable/proprietary member in source ZIP: {rel}: {info.filename}")
                with archive.open(info) as f:
                    signature = f.read(4)
                if signature.startswith(b"MZ") or signature == b"\x7fELF":
                    raise PackageError(f"Executable signature inside source ZIP: {rel}: {info.filename}")


def model_json(path: Path) -> dict:
    """Read glTF JSON, including the JSON chunk in an actual GLB 2 container.

    Format reference: https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html
    Only JSON is loaded; large binary chunks are bounded and skipped by seek.
    GLB containers may still reference external images and buffers.
    """
    if path.suffix.lower() == ".gltf":
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    else:
        size = path.stat().st_size
        with path.open("rb") as handle:
            header = handle.read(12)
            if len(header) != 12:
                raise PackageError(f"Truncated GLB header: {path}")
            magic, version, declared = struct.unpack("<4sII", header)
            if magic != b"glTF" or version != 2 or declared != size:
                raise PackageError(f"Invalid GLB magic/version/declared length: {path}")
            data = None
            index = 0
            while handle.tell() < size:
                chunk_header = handle.read(8)
                if len(chunk_header) != 8:
                    raise PackageError(f"Truncated GLB chunk header: {path}")
                length, kind = struct.unpack("<II", chunk_header)
                if length % 4 or handle.tell() + length > size:
                    raise PackageError(f"Invalid GLB chunk length/alignment: {path}")
                if index == 0 and kind != 0x4E4F534A:
                    raise PackageError(f"The first GLB chunk is not JSON: {path}")
                if kind == 0x4E4F534A:
                    if index != 0:
                        raise PackageError(f"Duplicate GLB JSON chunk: {path}")
                    data = json.loads(handle.read(length).decode("utf-8-sig"))
                else:
                    handle.seek(length, os.SEEK_CUR)
                index += 1
    if not isinstance(data, dict):
        raise PackageError(f"Missing or non-object glTF JSON: {path}")
    asset = data.get("asset", {})
    if not isinstance(asset, dict) or not str(asset.get("version", "")).startswith("2."):
        raise PackageError(f"Unsupported glTF asset version: {path}")
    return data


def local_model_dependency(path: Path, uri: str) -> str | None:
    """Resolve only portable, local URIs; never fetch model dependencies."""
    if not isinstance(uri, str):
        raise PackageError(f"Non-string glTF URI: {path}")
    parsed = urlsplit(uri)
    if parsed.scheme.lower() == "data":
        return None
    if (not uri or parsed.scheme or parsed.netloc or parsed.query or parsed.fragment
            or re.search(r"%(?![0-9a-fA-F]{2})", uri)):
        raise PackageError(f"Non-local or invalid glTF dependency URI: {path}: {uri}")
    decoded = unquote(parsed.path, encoding="utf-8", errors="strict")
    if (not decoded or decoded.startswith("/") or "\\" in decoded
            or any(ord(char) < 32 for char in decoded)
            or re.match(r"^[a-zA-Z]:", decoded)):
        raise PackageError(f"Non-portable glTF dependency path: {path}: {uri}")
    resolved = (path.parent / decoded).resolve()
    if PROJECT not in resolved.parents:
        raise PackageError(f"glTF dependency escapes project: {path}: {uri}")
    return resolved.relative_to(PROJECT).as_posix()


def runtime_closure(entries: list[dict]) -> dict:
    project_entries = [e for e in entries if e["group"] == "Godot-Project"]
    members = {e["relative"] for e in project_entries}
    missing = []
    count = 0
    formats = Counter()
    external = []
    for entry in project_entries:
        path, rel = entry["path"], entry["relative"]
        if ((rel.startswith("game/") and path.suffix == ".gd")
                or path.suffix in [".tscn", ".tres"]
                or rel == "project.godot"):
            text = path.read_text(encoding="utf-8")
            for match in re.finditer(r'''["']res://([^"']+)["']''', text):
                target = match.group(1)
                if any(c in target for c in ["%", "{", "}", "$", "\\"]):
                    continue
                if target in members or any(member.startswith(target.rstrip("/") + "/") for member in members):
                    count += 1
                else:
                    missing.append({"source": rel, "reference": target})
        if path.suffix.lower() in [".gltf", ".glb"]:
            data = model_json(path)
            formats[path.suffix.lower().lstrip(".")] += 1
            for section in ["buffers", "images"]:
                resources = data.get(section, [])
                if not isinstance(resources, list):
                    raise PackageError(f"Invalid glTF {section} collection: {rel}")
                for index, resource in enumerate(resources):
                    if not isinstance(resource, dict):
                        raise PackageError(f"Invalid glTF {section} entry: {rel}")
                    if "uri" not in resource:
                        continue  # Embedded bufferView/GLB BIN payload.
                    target = local_model_dependency(path, resource["uri"])
                    if target is None:
                        continue
                    count += 1
                    external.append({"source": rel, "kind": section, "index": index,
                                     "uri": resource["uri"], "reference": target})
                    if target not in members:
                        missing.append({"source": rel, "reference": target})
    if missing:
        raise PackageError("Runtime resource omitted: " + json.dumps(missing, ensure_ascii=False))
    return {"checkedLiteralAndModelReferences": count, "modelContainers": dict(formats),
            "externalModelReferences": external,
            "uniqueExternalDependencies": sorted({row["reference"] for row in external}),
            "dependencyPolicy": "Every local model URI must be a member of the main Godot-Project ZIP; embedded/data URIs require no external file; network and out-of-project URIs are rejected.",
            "missing": []}


def application_config() -> dict:
    text = (PROJECT / "project.godot").read_text()
    found = {}
    for name, key in [("version", "config/version"), ("mainScene", "run/main_scene")]:
        m = re.search(r'^' + re.escape(key) + r'="([^"]+)"', text, re.M)
        found[name] = m.group(1) if m else ""
    return found


def archive_name(label: str, config: dict) -> str:
    version = str(config.get("version", ""))
    if not re.fullmatch(r"0\.3(?:[.+-][A-Za-z0-9][A-Za-z0-9.+-]*)?", version):
        raise PackageError("Source archive requires a filename-safe configured 0.3 checkpoint")
    return f"Draconia-{version}-{label}.zip"


def is_project_label(label: str) -> bool:
    return label == "Godot-Project" or bool(re.fullmatch(r"Godot-Project-[0-9]{2,}", label))


def groups(entries: list[dict], scope: str, *, split_project: bool = False) -> list[tuple[str, list[dict]]]:
    result = []
    for label in ["Godot-Project", "Verification", "Art-Sources", "Hero-Workshop"]:
        if (scope == "project" and label != "Godot-Project"
                or scope == "art" and label not in ("Art-Sources", "Hero-Workshop")
                or scope == "verification" and label != "Verification"):
            continue
        selected = [e for e in entries if e["group"] == label]
        if label == "Godot-Project" and not split_project:
            result.append((label, selected))
            continue
        budget = PROJECT_RAW_BUDGET if label == "Godot-Project" else ART_RAW_BUDGET
        chunks, chunk, total = [], [], 0
        for entry in selected:
            size = entry["identity"][0]
            if size > budget:
                kind = "project" if label == "Godot-Project" else "art"
                raise PackageError(f"A single {kind} file exceeds the conservative archive budget: {entry['relative']}")
            if chunk and total + size > budget:
                chunks.append(chunk); chunk = []; total = 0
            chunk.append(entry); total += size
        if chunk:
            chunks.append(chunk)
        for i, chunk in enumerate(chunks, 1):
            numbered = len(chunks) > 1 or (label == "Godot-Project" and split_project)
            result.append((f"{label}-{i:02}" if numbered else label, chunk))
    return result


def readme(label: str, config: dict, *, project_archives: list[str] | None = None) -> str:
    common = """
All ZIPs use the same `Draconia/` root. Extract optional archives beside the
editable-project ZIP, merging that folder to restore original source paths.
Unpack their contents before opening the Godot project.
No original Heroes executable, proprietary resource archive, raw disassembly
bundle, engine executable, export cache, credentials or private player save is included.
Labeled test save fixtures are retained with their verification evidence.
Authored research reports retain identifiers and limitations; their original
private analysis evidence is not part of this editable game distribution.

Project code and project-authored additions use LICENSE.txt. Downloaded art,
fonts and tools retain their own licenses, including CC0, CC BY-SA, OFL and
GPL for the MPFB tool source. A source-code MIT notice does not relabel them.
Read ASSET_CREDITS.md and the per-asset manifests/notices before redistribution.
Archive integrity is distinct from gameplay, platform and visual acceptance.
"""
    if label == "Godot-Project":
        required_parts = ""
        if project_archives is not None:
            if not project_archives or len(project_archives) != len(set(project_archives)):
                raise PackageError("Split-project instructions require the complete unique archive list")
            names = "\n".join(f"- `{name}`" for name in project_archives)
            required_parts = f"""## All project parts are required

This editable project is distributed across **{len(project_archives)} ordinary ZIP files**:

{names}

Download and extract **every named Godot project ZIP into the same parent
folder**, merging their common `Draconia/` directory. Do not open the project
until all parts are extracted. No individual part is a complete runnable
project: code, scenes, models and their shared textures may be in different
parts. These are whole files, not byte chunks; no assembly helper is needed.
The identically named SOURCE-PACKAGE-README.md is byte-identical in every part
and may safely replace its identical copy during extraction. Keep the distinct
Godot-Project-NN-inventory.json files; each describes only its own part.
Runtime dependency closure was checked over the combined complete project,
not separately over each ZIP. Optional Verification or art archives cannot
substitute for a missing required Godot project part.

"""
            common = common.replace("editable-project ZIP, merging that folder", "merged editable project, merging that folder")
        return f"""# Draconia {config['version']} editable source

{required_parts}\
This is the native action-rebuild source snapshot, not a full-game completion
claim. Exactly one chosen playable hero remains the campaign rule. The
current implemented protagonist is Mara Veyne; the larger named hero and
creature rosters are design catalogs. The source includes the previous hex
campaign separately for preservation, not as proof of action-rebuild scope.

## Run

Use the standard Godot 4.7.2 editor, import `project.godot`, allow first asset
import to finish and press F5. Configured version: `{config['version']}`.
Configured entry: `{config['mainScene']}`. The new action scene is
`redesign.tscn`; it can also be opened directly and run with F6.
The .NET editor, a browser and an original Heroes installation are unnecessary.
No `.godot` import cache is supplied; Godot creates its own on first import.

The separate native desktop downloads for this checkpoint use Part01 and
Part02 ZIPs per platform. Their START-HERE.md explains extraction into the same
folder and local hash-checked assembly with the Start helper. Follow those
version-specific instructions before the root README's generic native launch
sentence. Native reassembly is not needed to open this Godot source project.

The complete current design is `docs/GAME_DESIGN.md`, with editable Markdown
and JSON catalogs beside it. The earlier external PDF is deliberately not
inserted: its building-art direction predates the corrected reference contract.
The original painted cards define the buildings; model renders do not replace
those cards. Read `docs/CARD_RECONSTRUCTION.md` for this checkpoint's scope.

The separate Verification archive contains test scripts, fixtures, native
captures and source-bound reports. Merge it into the same Draconia folder to
inspect or rerun those tests. Historical evidence remains dated and does not
automatically certify the current assets. Candidate-authoring tests also need
the optional Card Reconstruction Workshop and the stated Blender installation.

The optional Art-Sources and Hero-Workshop archives are not required to run
or edit the imported Godot scenes. They preserve original Blender/OBJ/DAE,
retargeting work, acquisition evidence and the source tool for deeper art work.
Keep external GLB material/buffer files in their original relative locations.
The package inventory checks those dependencies, including shared Mara maps;
copying only a GLB may discard required materials.
{common}
"""
    if label.startswith("Verification"):
        return f"""# Draconia 0.3 verification sources and evidence

Merge this archive into the same `Draconia/` folder as the Godot project.
This package preserves test scripts, named test fixtures, native screenshots,
failed attempts and scoped reports. Read the source hashes and stated scope
of each report. A historic pass is not a pass for a later revision, and a
camera-only comparison is not an additional animation or gameplay test.

The current review is recorded in `docs/CARD_RECONSTRUCTION.md` and
`docs/VERIFICATION.md`. Source geometry checks additionally require the Card
Reconstruction Workshop and Blender. The full optional historical Art-Sources
set is needed only for tests explicitly referring to earlier authoring work.
{common}
"""
    return f"""# Draconia 0.3 optional {label}

This archive preserves editable art and provenance rather than game exports.
Art-Sources contains original model/sprite inputs, source motion packs and
selected MPFB body/clothing/tool sources. Hero-Workshop contains retargeting
scripts, editable intermediate/final Blender files, derived GLBs and native
inspection evidence. Historical proofs remain labelled in their manifests.
The promoted runtime meshes are already in the main editable-project ZIP.

These archives are preservation checkpoints, not a claim that every historical
proof is accepted production art. Rebuild scripts may name the recorded local
tools or paths and require those dependencies to be installed separately.
{common}
"""


def add_bytes(archive: zipfile.ZipFile, member: str, data: bytes) -> None:
    info = zipfile.ZipInfo(member, date_time=(2026, 10, 22, 0, 0, 0))
    info.create_system = 3; info.external_attr = (stat.S_IFREG | 0o644) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    archive.writestr(info, data)


def build_archive(folder: Path, label: str, selected: list[dict], config: dict,
                  *, project_archives: list[str] | None = None) -> dict:
    path = folder / archive_name(label, config)
    project_part = is_project_label(label)
    split_part = project_part and label != "Godot-Project"
    if split_part and (not project_archives or path.name not in project_archives):
        raise PackageError("A split project archive requires its complete named project set")
    if project_archives is not None and not split_part:
        raise PackageError("The project archive set applies only to numbered Godot project parts")
    records = []
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as archive:
        for entry in selected:
            source = entry["path"]
            if identity(source) != entry["identity"]:
                raise PackageError(f"Input changed since inventory: {entry['relative']}")
            check_file(entry)
            member = "Draconia/" + entry["relative"]
            info = zipfile.ZipInfo.from_file(source, member, strict_timestamps=False)
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | stat.S_IMODE(source.stat().st_mode)) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            h = hashlib.sha256()
            with source.open("rb") as src, archive.open(info, "w", force_zip64=True) as dst:
                for block in iter(lambda: src.read(1024 * 1024), b""):
                    h.update(block); dst.write(block)
            if identity(source) != entry["identity"]:
                raise PackageError(f"Input changed during packaging: {entry['relative']}")
            records.append({"path": entry["relative"], "bytes": entry["identity"][0], "sha256": h.hexdigest()})
        base_label = "Godot-Project" if project_part else label
        notice_name = "SOURCE-PACKAGE-README.md" if project_part else f"{label.upper()}-README.md"
        notice_data = readme(base_label, config, project_archives=project_archives).encode()
        add_bytes(archive, "Draconia/" + notice_name, notice_data)
        index_name = f"Draconia/{label}-inventory.json"
        index = {"schemaVersion": 1, "kind": label, "application": config, "sourceFileCount": len(records), "files": records}
        if split_part:
            index.update({"projectSplitMode": True, "projectArchiveCount": len(project_archives),
                          "requiredProjectArchives": project_archives,
                          "projectPart": project_archives.index(path.name) + 1})
        index_data = (json.dumps(index, ensure_ascii=False, indent=2) + "\n").encode()
        add_bytes(archive, index_name, index_data)
    generated = [
        {"path": notice_name, "bytes": len(notice_data), "sha256": hashlib.sha256(notice_data).hexdigest()},
        {"path": index_name.removeprefix("Draconia/"), "bytes": len(index_data), "sha256": hashlib.sha256(index_data).hexdigest()},
    ]
    if path.stat().st_size > MAX_ARCHIVE:
        raise PackageError(f"Archive exceeds 500 MB: {path.name} ({path.stat().st_size} bytes)")
    expected = {"Draconia/" + e["relative"] for e in selected} | {"Draconia/" + notice_name, index_name}
    with zipfile.ZipFile(path) as archive:
        if len(archive.namelist()) != len(expected) or set(archive.namelist()) != expected:
            raise PackageError(f"Member inventory mismatch: {path.name}")
        if archive.testzip():
            raise PackageError(f"CRC failure: {path.name}")
        for record in records + generated:
            h = hashlib.sha256()
            with archive.open("Draconia/" + record["path"]) as f:
                for block in iter(lambda: f.read(1024 * 1024), b""):
                    h.update(block)
            if h.hexdigest() != record["sha256"]:
                raise PackageError(f"Archived hash mismatch: {record['path']}")
    return {"filename": path.name, "kind": label, "sourceFiles": len(records), "entries": len(expected), "uncompressedSourceBytes": sum(r["bytes"] for r in records), "generatedFiles": generated, "bytes": path.stat().st_size, "sha256": digest(path), "checks": {"crc": "passed", "perFileSha256IncludingGeneratedMetadata": "passed", "exactMembers": "passed", "executableAndProprietaryPayloadFilter": "passed", "under500MB": True}}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--scope", choices=["all", "project", "art", "verification"], default="all")
    parser.add_argument("--build", action="store_true", help="Without this flag, print and save the inventory plan only")
    parser.add_argument("--split-project", action="store_true",
                        help="Opt-in whole-file Godot-Project-NN ZIPs, each at most 440 MB raw; all project parts are required")
    args = parser.parse_args()
    if args.split_project and args.scope not in ("all", "project"):
        parser.error("--split-project applies only to --scope all or --scope project")
    if not args.output.is_absolute():
        parser.error("Output must be an absolute directory outside the project")
    output = args.output.resolve()
    if output == PROJECT or PROJECT in output.parents:
        parser.error("Output must be outside the project")
    try:
        entries, skips = inventory()
        config = application_config()
        closure = runtime_closure(entries)
        planned = groups(entries, args.scope, split_project=args.split_project)
        project_archives = [archive_name(label, config) for label, _ in planned if is_project_label(label)]
        project_metadata = {}
        if args.scope in ("all", "project"):
            project_metadata = {"projectSplitMode": args.split_project,
                                "projectArchiveCount": len(project_archives),
                                "projectArchives": project_archives,
                                "projectChunkRawBudget": PROJECT_RAW_BUDGET if args.split_project else None}
        if args.split_project:
            closure["dependencyPolicy"] = ("Every local model URI must be a member of the combined complete Godot-Project archive set; "
                                           "embedded/data URIs require no external file; network and out-of-project URIs are rejected. "
                                           "Individual project parts need not be independently runnable.")
            closure["requiredProjectArchives"] = project_archives
        summaries = [{"archive": archive_name(label, config), "sourceFiles": len(files), "uncompressedBytes": sum(e["identity"][0] for e in files)} for label, files in planned]
        output.mkdir(parents=True, exist_ok=True)
        configured = config["mainScene"] == "res://redesign.tscn" and bool(re.match(r"^0\.3(?:$|[.+-])", config["version"]))
        plan = {"schemaVersion": 2, "releaseSeries": RELEASE_SERIES, "application": config, "maximumArchiveBytes": MAX_ARCHIVE, "artChunkRawBudget": ART_RAW_BUDGET, "scope": args.scope, "planned": summaries, "runtimeClosure": closure, "excludedCategories": skips, "rawOriginalGameEvidenceIncluded": False, "externalOriginalGameFilesTraversed": False, "projectVersionAndEntryReady": configured, "archivesBuilt": False}
        plan.update(project_metadata)
        (output / f"source-plan-v0.3-{args.scope}.json").write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps(plan, ensure_ascii=False, indent=2), flush=True)
        if not args.build:
            return 0
        if args.scope in ("all", "project") and not configured:
            raise PackageError("Final project requires the configured 0.3 action entry; root must switch it after verification")
        artifacts = []
        with tempfile.TemporaryDirectory(prefix="draconia-source-stage-", dir=output) as temp:
            stage = Path(temp)
            for label, files in planned:
                print(f"Building {label}: {len(files)} source files", flush=True)
                artifacts.append(build_archive(stage, label, files, config,
                                               project_archives=project_archives if args.split_project and is_project_label(label) else None))
            # Detect new/deleted files and edits anywhere in the selected scope.
            after, _ = inventory()
            before_set = {(e["relative"], e["identity"]) for _, files in planned for e in files}
            after_set = {(e["relative"], e["identity"]) for _, files in groups(after, args.scope, split_project=args.split_project) for e in files}
            if before_set != after_set:
                raise PackageError("Selected source inventory changed during packaging; rerun after edits finish")
            manifest = {"schemaVersion": 2, "releaseSeries": RELEASE_SERIES, "createdUtc": datetime.now(timezone.utc).isoformat(), "application": config, "scope": args.scope, "artifacts": artifacts, "runtimeClosure": closure, "limits": {"maximumArchiveBytes": MAX_ARCHIVE, "artChunkRawBudget": ART_RAW_BUDGET}, "excluded": plan["excludedCategories"], "status": "source preservation and archive integrity verified; gameplay acceptance is separate"}
            manifest.update(project_metadata)
            manifest_name = f"source-release-v0.3-{args.scope}.json"
            (stage / manifest_name).write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
            for artifact in artifacts:
                os.replace(stage / artifact["filename"], output / artifact["filename"])
            os.replace(stage / manifest_name, output / manifest_name)
        print(json.dumps(manifest, ensure_ascii=False, indent=2), flush=True)
        return 0
    except (PackageError, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"Source packaging failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
