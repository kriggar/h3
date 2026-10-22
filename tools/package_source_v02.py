#!/usr/bin/env python3
"""Package the editable 0.2 project and optional art sources; never export a game.

Plan: python tools/package_source_v02.py --output /absolute/outside/project
Build art now: add --build --scope art
Final project: add --build --scope project (requires the action entry scene)
All archives preserve Draconia/... paths and are limited to 500,000,000 bytes.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import sys
import tempfile
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
MAX_ARCHIVE = 500_000_000
ART_RAW_BUDGET = 440_000_000
ROOT_FILES = {"project.godot", "main.tscn", "redesign.tscn", "export_presets.cfg", "README.md", "LICENSE.txt", "ASSET_CREDITS.md", "icon.svg", "icon.svg.import", ".gitignore"}
ROOT_DIRS = {"assets", "data", "docs", "game", "tests", "tools", "research"}
SKIP_DIRS = {".godot", ".git", ".openai", "builds", "dist", "export_templates", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".cache", ".venv", "venv", "node_modules", ".aws", ".ssh", ".gnupg", ".codex", ".agents"}
SKIP_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini", "export_credentials.cfg"}
BANNED_SUFFIXES = {".exe", ".dll", ".so", ".dylib", ".msi", ".wasm", ".pck", ".lod", ".snd", ".vid", ".h3m"}
ART_PREFIXES = ("assets/staging/", "assets/models/source/", "assets/animated/source/")
REQUIRED = {"project.godot", "redesign.tscn", "README.md", "LICENSE.txt", "ASSET_CREDITS.md", "game/redesign/game_shell.gd", "game/redesign/realm_rules.gd", "game/redesign/action_rules.gd", "game/redesign/item_rules.gd", "assets/models/mara/mara.glb", "assets/models/mara/equipment/manifest.json", "assets/models/mara/equipment/vowkeeper.glb", "assets/models/mara/equipment/bellworn-cowl.glb", "docs/GAME_DESIGN.md", "docs/HERO_ROSTER.md", "docs/CREATURE_ROSTER.md", "data/hero_roster.json", "data/creature_roster.json", "tools/package_source_v02.py", "assets/licenses/CC0-1.0.txt", "assets/licenses/GODOT-LICENSE.txt"}


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
    # Preserve the completed document without requiring an external download.
    bundled_pdf = PROJECT / "docs/Draconia-Game-Design.pdf"
    external_pdf = PROJECT.parent / "output/pdf/Draconia-Game-Design.pdf"
    if not bundled_pdf.exists() and external_pdf.is_file():
        entries.append({"path": external_pdf, "relative": "docs/Draconia-Game-Design.pdf", "group": "Godot-Project", "identity": identity(external_pdf)})
    if not any(entry["relative"] == "docs/Draconia-Game-Design.pdf" for entry in entries):
        raise PackageError("The complete design PDF is required in the editable-project distribution")
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


def runtime_closure(entries: list[dict]) -> dict:
    project_entries = [e for e in entries if e["group"] == "Godot-Project"]
    members = {e["relative"] for e in project_entries}
    missing = []
    count = 0
    for entry in project_entries:
        path, rel = entry["path"], entry["relative"]
        if ((rel.startswith("game/") and path.suffix == ".gd")
                or ("/" not in rel and path.suffix in [".tscn", ".godot"])):
            text = path.read_text(encoding="utf-8")
            for match in re.finditer(r'''["']res://([^"']+)["']''', text):
                target = match.group(1)
                if any(c in target for c in ["%", "{", "}", "$", "\\"]):
                    continue
                if target in members or any(member.startswith(target.rstrip("/") + "/") for member in members):
                    count += 1
                else:
                    missing.append({"source": rel, "reference": target})
        if path.suffix == ".gltf":
            data = json.loads(path.read_text())
            for resource in data.get("buffers", []) + data.get("images", []):
                uri = resource.get("uri", "")
                if not uri or uri.startswith("data:"):
                    continue
                from urllib.parse import unquote
                resolved = (path.parent / unquote(uri)).resolve()
                if PROJECT not in resolved.parents:
                    raise PackageError(f"glTF dependency escapes project: {rel}: {uri}")
                target = resolved.relative_to(PROJECT).as_posix()
                count += 1
                if target not in members:
                    missing.append({"source": rel, "reference": target})
    if missing:
        raise PackageError("Runtime resource omitted: " + json.dumps(missing, ensure_ascii=False))
    return {"checkedLiteralAndGltfReferences": count, "missing": []}


def application_config() -> dict:
    text = (PROJECT / "project.godot").read_text()
    found = {}
    for name, key in [("version", "config/version"), ("mainScene", "run/main_scene")]:
        m = re.search(r'^' + re.escape(key) + r'="([^"]+)"', text, re.M)
        found[name] = m.group(1) if m else ""
    return found


def groups(entries: list[dict], scope: str) -> list[tuple[str, list[dict]]]:
    result = []
    for label in ["Godot-Project", "Art-Sources", "Hero-Workshop"]:
        if scope == "project" and label != "Godot-Project" or scope == "art" and label == "Godot-Project":
            continue
        selected = [e for e in entries if e["group"] == label]
        if label == "Godot-Project":
            result.append((label, selected))
            continue
        chunks, chunk, total = [], [], 0
        for entry in selected:
            size = entry["identity"][0]
            if size > ART_RAW_BUDGET:
                raise PackageError(f"A single art file exceeds the conservative archive budget: {entry['relative']}")
            if chunk and total + size > ART_RAW_BUDGET:
                chunks.append(chunk); chunk = []; total = 0
            chunk.append(entry); total += size
        if chunk:
            chunks.append(chunk)
        for i, chunk in enumerate(chunks, 1):
            result.append((label if len(chunks) == 1 else f"{label}-{i:02}", chunk))
    return result


def readme(label: str, config: dict) -> str:
    common = """
All ZIPs use the same `Draconia/` root. Extract optional archives beside the
editable-project ZIP, merging that folder to restore original source paths.
Do not place art archives inside the project or execute downloaded binaries.
No original Heroes executable, proprietary resource archive, raw disassembly
bundle, engine executable, export cache, credentials or save file is included.
Authored research reports retain identifiers and limitations; their original
private analysis evidence is not part of this editable game distribution.

Project code and project-authored additions use LICENSE.txt. Downloaded art,
fonts and tools retain their own licenses, including CC0, CC BY-SA, OFL and
GPL for the MPFB tool source. A source-code MIT notice does not relabel them.
Read ASSET_CREDITS.md and the per-asset manifests/notices before redistribution.
Archive integrity is distinct from gameplay, platform and visual acceptance.
"""
    if label == "Godot-Project":
        return f"""# Draconia 0.2 editable source

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

The complete design PDF is in `docs/Draconia-Game-Design.pdf`, with editable
Markdown and JSON catalogs beside it. Its implementation ledger is dated;
use the latest recorded verification files for subsequent changes.

The optional Art-Sources and Hero-Workshop archives are not required to run
or edit the imported Godot scenes. They preserve original Blender/OBJ/DAE,
retargeting work, acquisition evidence and the source tool for deeper art work.
{common}
"""
    return f"""# Draconia 0.2 optional {label}

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


def build_archive(folder: Path, label: str, selected: list[dict], config: dict) -> dict:
    path = folder / f"Draconia-0.2-{label}.zip"
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
        base_label = "Godot-Project" if label == "Godot-Project" else label
        notice_name = "SOURCE-PACKAGE-README.md" if label == "Godot-Project" else f"{label.upper()}-README.md"
        add_bytes(archive, "Draconia/" + notice_name, readme(base_label, config).encode())
        index_name = f"Draconia/{label}-inventory.json"
        add_bytes(archive, index_name, (json.dumps({"schemaVersion": 1, "kind": label, "application": config, "sourceFileCount": len(records), "files": records}, ensure_ascii=False, indent=2) + "\n").encode())
    if path.stat().st_size > MAX_ARCHIVE:
        raise PackageError(f"Archive exceeds 500 MB: {path.name} ({path.stat().st_size} bytes)")
    expected = {"Draconia/" + e["relative"] for e in selected} | {"Draconia/" + notice_name, index_name}
    with zipfile.ZipFile(path) as archive:
        if len(archive.namelist()) != len(expected) or set(archive.namelist()) != expected:
            raise PackageError(f"Member inventory mismatch: {path.name}")
        if archive.testzip():
            raise PackageError(f"CRC failure: {path.name}")
        for record in records:
            h = hashlib.sha256()
            with archive.open("Draconia/" + record["path"]) as f:
                for block in iter(lambda: f.read(1024 * 1024), b""):
                    h.update(block)
            if h.hexdigest() != record["sha256"]:
                raise PackageError(f"Archived hash mismatch: {record['path']}")
    return {"filename": path.name, "kind": label, "sourceFiles": len(records), "entries": len(expected), "uncompressedSourceBytes": sum(r["bytes"] for r in records), "bytes": path.stat().st_size, "sha256": digest(path), "checks": {"crc": "passed", "perFileSha256": "passed", "exactMembers": "passed", "executableAndProprietaryPayloadFilter": "passed", "under500MB": True}}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--scope", choices=["all", "project", "art"], default="all")
    parser.add_argument("--build", action="store_true", help="Without this flag, print and save the inventory plan only")
    parser.add_argument("--allow-legacy-entry", action="store_true", help="Development snapshots only; final project normally requires redesign.tscn")
    args = parser.parse_args()
    if not args.output.is_absolute():
        parser.error("Output must be an absolute directory outside the project")
    output = args.output.resolve()
    if output == PROJECT or PROJECT in output.parents:
        parser.error("Output must be outside the project")
    try:
        entries, skips = inventory()
        config = application_config()
        closure = runtime_closure(entries)
        planned = groups(entries, args.scope)
        summaries = [{"archive": f"Draconia-0.2-{label}.zip", "sourceFiles": len(files), "uncompressedBytes": sum(e["identity"][0] for e in files)} for label, files in planned]
        output.mkdir(parents=True, exist_ok=True)
        plan = {"schemaVersion": 1, "application": config, "maximumArchiveBytes": MAX_ARCHIVE, "scope": args.scope, "planned": summaries, "runtimeClosure": closure, "excludedCategories": skips, "rawOriginalGameEvidenceIncluded": False, "externalOriginalGameFilesTraversed": False}
        (output / f"source-plan-{args.scope}.json").write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps(plan, ensure_ascii=False, indent=2), flush=True)
        if not args.build:
            return 0
        if args.scope != "art" and not args.allow_legacy_entry and (config["mainScene"] != "res://redesign.tscn" or not config["version"].startswith("0.2")):
            raise PackageError("Final project requires the configured 0.2 action entry; root must switch it after verification")
        artifacts = []
        with tempfile.TemporaryDirectory(prefix="draconia-source-stage-", dir=output) as temp:
            stage = Path(temp)
            for label, files in planned:
                print(f"Building {label}: {len(files)} source files", flush=True)
                artifacts.append(build_archive(stage, label, files, config))
            # Detect new/deleted files and edits anywhere in the selected scope.
            after, _ = inventory()
            before_set = {(e["relative"], e["identity"]) for _, files in planned for e in files}
            after_set = {(e["relative"], e["identity"]) for _, files in groups(after, args.scope) for e in files}
            if before_set != after_set:
                raise PackageError("Selected source inventory changed during packaging; rerun after edits finish")
            manifest = {"schemaVersion": 1, "createdUtc": datetime.now(timezone.utc).isoformat(), "application": config, "scope": args.scope, "artifacts": artifacts, "runtimeClosure": closure, "limits": {"maximumArchiveBytes": MAX_ARCHIVE}, "excluded": plan["excludedCategories"], "status": "source preservation and archive integrity verified; gameplay acceptance is separate"}
            manifest_name = f"source-release-{args.scope}.json"
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
