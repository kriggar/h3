#!/usr/bin/env python3
"""Package existing final Draconia exports and editable sources.

Run only after the final Windows/Linux exports and verification have completed:
    python tools/package_release.py --output /absolute/path/outside/project

Standard library only. This script does not build, run, publish or upload a game.
It stages and checks all archives before replacing the four named output files.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import sys
import tempfile
from datetime import datetime, timezone
import zipfile


PROJECT = Path(__file__).resolve().parents[1]
PROJECT_NAME = "Draconia — Oaths of the Carpathians"
EXCLUDED_DIRECTORIES = {
    ".godot", ".git", ".openai", "builds", "dist", "export_templates",
    "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".cache",
    ".venv", "venv", "node_modules", ".aws", ".ssh", ".gnupg",
    ".codex", ".agents",
}
EXCLUDED_FILES = {".DS_Store", "Thumbs.db", "desktop.ini"}
REQUIRED_SOURCE = {
    "project.godot", "main.tscn", "export_presets.cfg", "README.md",
    "LICENSE.txt", "ASSET_CREDITS.md", "tools/package_release.py",
    "assets/CINZEL-OFL.txt", "assets/licenses/EBGARAMOND-OFL.txt",
    "assets/licenses/FLARE-CC-BY-SA-3.0.txt", "assets/licenses/CC0-1.0.txt",
    "assets/licenses/GODOT-LICENSE.txt", "assets/licenses/GODOT-COPYRIGHT.txt",
    "assets/models/manifest.json", "docs/VERIFICATION.md",
}


class ReleaseError(Exception):
    """A release input or integrity check failed."""


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def forbidden(relative: PurePosixPath, *, directory: bool = False) -> bool:
    parts = relative.parts if directory else relative.parts[:-1]
    if any(part in EXCLUDED_DIRECTORIES for part in parts):
        return True
    if directory:
        return False
    name = relative.name
    if name in EXCLUDED_FILES or name.endswith((".pyc", ".pyo", ".pending")):
        return True
    if ".pending." in name:
        return True
    # Keep public configuration examples; exclude real environment credentials.
    if name == ".env" or (
        name.startswith(".env.")
        and not name.endswith((".example", ".sample", ".template"))
    ):
        return True
    return False


def regular_file(path: Path) -> None:
    if path.is_symlink() or not path.is_file():
        raise ReleaseError(f"Expected a regular file, not a missing file or symlink: {path}")


def source_files() -> list[Path]:
    found: list[Path] = []
    for folder, directories, filenames in os.walk(PROJECT, followlinks=False):
        parent = Path(folder)
        kept = []
        for name in sorted(directories):
            child = parent / name
            relative = PurePosixPath(child.relative_to(PROJECT).as_posix())
            if forbidden(relative, directory=True):
                continue
            if child.is_symlink():
                raise ReleaseError(f"Source directory symlink requires review: {child}")
            kept.append(name)
        directories[:] = kept
        for name in sorted(filenames):
            path = parent / name
            relative = PurePosixPath(path.relative_to(PROJECT).as_posix())
            if not forbidden(relative):
                regular_file(path)
                found.append(path)
    members = {p.relative_to(PROJECT).as_posix() for p in found}
    missing = REQUIRED_SOURCE - members
    if missing:
        raise ReleaseError("Required source files missing: " + ", ".join(sorted(missing)))
    # Logs, .exit-code files, .uid files, .import files and .gdignore are retained.
    verification_logs = PROJECT / "docs" / "verification-logs"
    for path in verification_logs.rglob("*") if verification_logs.exists() else []:
        if path.is_file() and path.relative_to(PROJECT).as_posix() not in members:
            raise ReleaseError(f"Verification evidence would be omitted: {path}")
    return sorted(found)


def native_readme(platform: str) -> str:
    if platform == "Windows":
        launch = "Extract the entire ZIP, then double-click `Draconia.exe`."
        status = (
            "This Windows x86-64 build was cross-exported with Godot 4.7.2. "
            "It has not been runtime-tested on Windows."
        )
    else:
        launch = (
            "Extract the entire ZIP, then launch `Draconia.x86_64` from your file "
            "manager or run `./Draconia.x86_64` in a terminal in this folder. "
            "The archive preserves its executable bit. If your extractor drops "
            "permissions, run `chmod +x Draconia.x86_64` once."
        )
        status = (
            "The Linux x86-64 build's native startup and rendering were checked "
            "in the development environment using Godot 4.7.2 and the OpenGL "
            "Compatibility renderer. This is not a claim of testing every "
            "Linux distribution or graphics driver."
        )
    return f"""# {PROJECT_NAME}

## Launch

{launch}

The game is included in the executable. No Godot editor, installer, browser,
Heroes III installation or separately downloaded game data is needed.
Keep the accompanying license and credit files with this distribution.

## This release

This is the first playable single-player Draconia campaign: lead Ileana,
develop towns, recruit troops, restore three oaths and challenge Cetatea
Nopții. It is an original Romanian-folklore fantasy game. The wider planned
faction roster, additional campaigns, map editor and multiplayer are not
included in this release. The environment and battlefields use native 3D;
some troop types use downloaded animated sprite artwork.

## Controls

- Adventure: click a destination to inspect it, then click it again or use
  the travel action. Drag the map to pan; use the mouse wheel to zoom.
- `H`: find Ileana. `E`: end the day. `T`: towns. `J`: chronicle.
- `Esc`: back, clear the current action or open the menu.
- `Ctrl+S` (or `Cmd+S`): save campaign progress.
- Battle: click a reachable hex to move or an enemy to attack. `W` waits,
  `D` defends and `A` toggles automatic battle. Arrow keys and `Enter`
  provide keyboard targeting. `Esc` cancels a selected spell.
- Battlefield camera: use the mouse wheel to change inspection distance;
  hold the right or middle mouse button and drag to turn the view.
- Enable optional audio from the game's sound control when desired.

## Saves and backups

Campaign progress is autosaved after completed campaign actions and battle
resolution. In-progress tactical turns are not a separate save checkpoint.
Use the Chronicle's save export to keep a portable `Draconia-Day-….json`
backup outside the game folder, particularly before updating the game or
starting a new chronicle. Starting a new chronicle replaces the active
autosave. Importing a valid backup replaces active progress.

The local autosave is `draconia-save.json` in the game's Godot application
data directory, separate from this extracted folder. Sound settings are
stored separately.

## Verification status

{status}

Automated campaign, tactical and application checks and their recorded
results are supplied in the separate editable Godot project archive. A
complete manual playthrough on every target platform has not been claimed.

## Credits and licenses

Read `ASSET_CREDITS.md`, `LICENSE.txt`, `assets/CINZEL-OFL.txt` and the complete
`assets/licenses/` folder included here. Original project code uses MIT;
downloaded artwork, fonts and the engine retain their respective CC0,
CC BY-SA, OFL, MIT and third-party notices. The MIT grant does not relabel
those assets. This native package contains no proprietary Heroes III or
Manor Lords assets.
"""


def write_file(archive: zipfile.ZipFile, source: Path, member: str,
               *, executable: bool = False) -> None:
    regular_file(source)
    before = source.stat()
    info = zipfile.ZipInfo.from_file(source, member, strict_timestamps=False)
    info.create_system = 3  # Unix metadata, including Linux executable bits.
    mode = stat.S_IMODE(before.st_mode)
    if executable:
        mode |= 0o111
    info.external_attr = (stat.S_IFREG | mode) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    with source.open("rb") as src, archive.open(info, "w", force_zip64=True) as dst:
        shutil.copyfileobj(src, dst, 1024 * 1024)
    after = source.stat()
    if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
        raise ReleaseError(f"Input changed while packaging; rerun after edits finish: {source}")


def write_text(archive: zipfile.ZipFile, member: str, content: str) -> None:
    info = zipfile.ZipInfo(member, date_time=(2026, 1, 1, 0, 0, 0))
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | 0o644) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    archive.writestr(info, content.encode("utf-8"))


def check_archive(path: Path, root: str, expected: set[str],
                  *, source: bool = False, linux_binary: str | None = None) -> int:
    with zipfile.ZipFile(path) as archive:
        corrupt = archive.testzip()
        if corrupt:
            raise ReleaseError(f"ZIP CRC failure: {path.name}: {corrupt}")
        names = archive.namelist()
        if len(names) != len(set(names)) or set(names) != expected:
            raise ReleaseError(f"Archive member set differs from its planned inputs: {path.name}")
        for name in names:
            member = PurePosixPath(name)
            if member.is_absolute() or ".." in member.parts or member.parts[0] != root:
                raise ReleaseError(f"Unsafe or unexpected ZIP path: {name}")
            if source and forbidden(PurePosixPath(*member.parts[1:])):
                raise ReleaseError(f"Forbidden cache/private file entered source archive: {name}")
        if linux_binary:
            mode = archive.getinfo(linux_binary).external_attr >> 16
            if not mode & 0o111:
                raise ReleaseError("Linux executable permission was not preserved")
        return len(names)


def package(output: Path) -> dict:
    sources = source_files()
    binaries = {
        "Windows": PROJECT / "builds/windows/Draconia.exe",
        "Linux": PROJECT / "builds/linux/Draconia.x86_64",
    }
    binary_records = {}
    for platform, path in binaries.items():
        regular_file(path)
        with path.open("rb") as handle:
            signature = handle.read(4)
        if not (signature.startswith(b"MZ") if platform == "Windows"
                else signature == b"\x7fELF"):
            raise ReleaseError(f"Invalid {platform} executable signature: {path}")
        binary_records[platform] = {"sha256": sha256(path), "bytes": path.stat().st_size}
    notices = [PROJECT / "LICENSE.txt", PROJECT / "ASSET_CREDITS.md",
               PROJECT / "assets/CINZEL-OFL.txt"]
    notices += sorted(p for p in (PROJECT / "assets/licenses").rglob("*") if p.is_file())
    for notice in notices:
        regular_file(notice)
    output.mkdir(parents=True, exist_ok=True)
    artifacts = []
    with tempfile.TemporaryDirectory(prefix="draconia-stage-", dir=output) as folder:
        stage = Path(folder)
        source_zip = stage / "Draconia-Godot-project.zip"
        expected = {"Draconia/" + p.relative_to(PROJECT).as_posix() for p in sources}
        with zipfile.ZipFile(source_zip, "w", compression=zipfile.ZIP_DEFLATED,
                             compresslevel=6, allowZip64=True) as archive:
            for path in sources:
                write_file(archive, path, "Draconia/" + path.relative_to(PROJECT).as_posix())
        count = check_archive(source_zip, "Draconia", expected, source=True)
        artifacts.append({"filename": source_zip.name, "kind": "editable-godot-project",
                          "archiveRoot": "Draconia", "entries": count,
                          "bytes": source_zip.stat().st_size, "sha256": sha256(source_zip)})
        for platform, binary in binaries.items():
            root = "Draconia-" + platform
            archive_path = stage / (root + ".zip")
            binary_member = root + "/" + binary.name
            expected = {binary_member, root + "/README.md"}
            with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED,
                                 compresslevel=6, allowZip64=True) as archive:
                write_file(archive, binary, binary_member, executable=platform == "Linux")
                write_text(archive, root + "/README.md", native_readme(platform))
                for notice in notices:
                    name = root + "/" + notice.relative_to(PROJECT).as_posix()
                    write_file(archive, notice, name)
                    expected.add(name)
            count = check_archive(archive_path, root, expected,
                                  linux_binary=binary_member if platform == "Linux" else None)
            with zipfile.ZipFile(archive_path) as archive:
                h = hashlib.sha256()
                with archive.open(binary_member) as handle:
                    for block in iter(lambda: handle.read(1024 * 1024), b""):
                        h.update(block)
                if h.hexdigest() != binary_records[platform]["sha256"]:
                    raise ReleaseError(f"Packaged executable hash changed: {platform}")
            artifacts.append({"filename": archive_path.name, "kind": "native-game",
                              "platform": platform, "archiveRoot": root, "entries": count,
                              "bytes": archive_path.stat().st_size, "sha256": sha256(archive_path),
                              "executable": {"filename": binary.name, **binary_records[platform]}})
        manifest = {
            "schemaVersion": 1, "project": PROJECT_NAME,
            "createdUtc": datetime.now(timezone.utc).isoformat(),
            "godotVersion": "4.7.2-stable", "artifacts": artifacts,
            "checks": {"zipCrc": "passed", "expectedMembers": "passed",
                       "sourceForbiddenFiles": "passed", "executableHashes": "passed",
                       "linuxExecutableBit": "preserved"},
            "verification": {"Windows": "Cross-exported; not runtime-tested on Windows.",
                             "Linux": "Native startup/render checked in development environment.",
                             "scope": "Archive integrity does not replace game testing."},
        }
        (stage / "release-manifest.json").write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        # Manifest is the final completion marker; no incomplete ZIP is published.
        for item in artifacts:
            os.replace(stage / item["filename"], output / item["filename"])
        os.replace(stage / "release-manifest.json", output / "release-manifest.json")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path,
                        help="Absolute output directory outside the Godot project")
    args = parser.parse_args()
    if not args.output.is_absolute():
        parser.error("--output must be an absolute path")
    output = args.output.resolve()
    if output == PROJECT or PROJECT in output.parents:
        parser.error("--output must be outside the project (including through symlinks)")
    if output.exists() and not output.is_dir():
        parser.error("--output exists and is not a directory")
    try:
        manifest = package(output)
    except (ReleaseError, OSError, zipfile.BadZipFile) as exc:
        print(f"Release packaging failed: {exc}", file=sys.stderr)
        return 1
    for artifact in manifest["artifacts"]:
        print(f"{artifact['filename']}  {artifact['bytes']} bytes  SHA256 {artifact['sha256']}")
    print(f"Release complete: {output / 'release-manifest.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
