#!/usr/bin/env python3
"""Package already-exported 0.2 desktop binaries; never export or upload.

Plan: python3 tools/package_native_v02.py --output /absolute/deliverables/v0.2
After the release owner freezes inputs and checks Linux startup/render:
  add --build --linux-verified
Windows is always labelled cross-exported and runtime unverified.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
LIMIT = 500_000_000
BINARY_PATHS = {
    "Linux": PROJECT / "builds/v0.2/linux/Draconia.x86_64",
    "Windows": PROJECT / "builds/v0.2/windows/Draconia.exe",
}


class PackageError(Exception):
    pass


def file_identity(path: Path) -> tuple[int, int]:
    if path.is_symlink() or not path.is_file():
        raise PackageError(f"Expected a regular file: {path}")
    value = path.stat()
    return value.st_size, value.st_mtime_ns


def file_hash(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def notices() -> list[Path]:
    result = [PROJECT / name for name in
              ["README.md", "ASSET_CREDITS.md", "LICENSE.txt", "assets/CINZEL-OFL.txt"]]
    result += sorted(path for path in (PROJECT / "assets/licenses").rglob("*") if path.is_file())
    for path in result:
        file_identity(path)
    if not (PROJECT / "assets/licenses/GODOT-LICENSE.txt") in result:
        raise PackageError("Godot engine license is missing")
    return result


def application() -> dict:
    text = (PROJECT / "project.godot").read_text(encoding="utf-8")
    found = {}
    for label, key in [("version", "config/version"), ("mainScene", "run/main_scene")]:
        match = re.search(r"^" + re.escape(key) + r'="([^"]+)"', text, re.M)
        found[label] = match.group(1) if match else ""
    if not found["version"].startswith("0.2") or found["mainScene"] != "res://redesign.tscn":
        raise PackageError("The 0.2 action scene must be the configured entry before packaging")
    return found


def platform_notice(platform: str, linux_verified: bool) -> str:
    if platform == "Linux":
        launch = ("Extract the whole archive and run `./Draconia.x86_64` from this folder, "
                  "or launch the executable in your file manager. The ZIP preserves its "
                  "executable permission. If your extractor drops that permission, run "
                  "`chmod +x Draconia.x86_64` once.")
        status = ("Native startup and rendering of this exported build were checked in the "
                  "development Linux environment with Godot 4.7.2 and its OpenGL Compatibility "
                  "renderer. This is not testing of every distribution or graphics driver."
                  if linux_verified else
                  "This exported Linux executable has not been marked runtime verified by "
                  "the release owner. Archive integrity does not establish runtime behavior.")
    else:
        launch = "Extract the whole archive, then double-click `Draconia.exe`."
        status = ("This Windows x86-64 build was cross-exported with Godot 4.7.2. "
                  "Windows runtime behavior has not been verified in this environment.")
    return f"""# Draconia 0.2 — {platform} package

## Launch

{launch}

The game data is embedded in the executable. No editor, installer, browser,
original Heroes installation or separately downloaded proprietary data is
required. Keep all accompanying credits and licenses with the distribution.

## Verification boundary

{status}

The included README.md describes the current development slice and controls.
It is copied from the same frozen project documentation, not a generated
summary of an earlier campaign. This remains an unfinished development build;
archive checks and a successful startup are not full campaign acceptance.

## Credits

Read ASSET_CREDITS.md, LICENSE.txt, assets/CINZEL-OFL.txt and assets/licenses/.
Downloaded art, fonts and engine components retain their respective licenses.
No proprietary Heroes III or Manor Lords assets are included.
"""


def write_file(archive: zipfile.ZipFile, path: Path, member: str, expected: tuple[int, int], executable: bool = False) -> dict:
    if file_identity(path) != expected:
        raise PackageError(f"Input changed before packaging: {path}")
    info = zipfile.ZipInfo.from_file(path, member, strict_timestamps=False)
    mode = stat.S_IMODE(path.stat().st_mode)
    if executable:
        mode |= 0o111
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | mode) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    value = hashlib.sha256()
    with path.open("rb") as source, archive.open(info, "w", force_zip64=True) as target:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            target.write(block)
            value.update(block)
    if file_identity(path) != expected:
        raise PackageError(f"Input changed while packaging: {path}")
    return {"path": member, "bytes": expected[0], "sha256": value.hexdigest()}


def build_archive(folder: Path, platform: str, inputs: list[Path], identities: dict[Path, tuple[int, int]], linux_verified: bool) -> dict:
    root = f"Draconia-{platform}-v0.2"
    output = folder / (root + ".zip")
    binary = BINARY_PATHS[platform]
    with binary.open("rb") as handle:
        signature = handle.read(4)
    if not (signature == b"\x7fELF" if platform == "Linux" else signature.startswith(b"MZ")):
        raise PackageError(f"Invalid {platform} executable signature")
    records = []
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as archive:
        records.append(write_file(archive, binary, root + "/" + binary.name, identities[binary], platform == "Linux"))
        for path in inputs:
            records.append(write_file(archive, path, root + "/" + path.relative_to(PROJECT).as_posix(), identities[path]))
        notice = platform_notice(platform, linux_verified).encode("utf-8")
        member = root + "/PLATFORM-NOTES.md"
        info = zipfile.ZipInfo(member, date_time=(2026, 10, 22, 0, 0, 0))
        info.create_system = 3
        info.external_attr = (stat.S_IFREG | 0o644) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(info, notice)
        records.append({"path": member, "bytes": len(notice), "sha256": hashlib.sha256(notice).hexdigest()})
    if output.stat().st_size > LIMIT:
        raise PackageError(f"{output.name} exceeds 500 MB")
    expected = {record["path"] for record in records}
    with zipfile.ZipFile(output) as archive:
        if len(archive.namelist()) != len(expected) or set(archive.namelist()) != expected or archive.testzip():
            raise PackageError(f"Archive member/CRC verification failed: {output.name}")
        for record in records:
            value = hashlib.sha256()
            with archive.open(record["path"]) as handle:
                for block in iter(lambda: handle.read(1024 * 1024), b""):
                    value.update(block)
            if value.hexdigest() != record["sha256"]:
                raise PackageError(f"Archived file hash mismatch: {record['path']}")
        if platform == "Linux" and not ((archive.getinfo(root + "/" + binary.name).external_attr >> 16) & 0o111):
            raise PackageError("Linux executable permission was not preserved")
    return {
        "filename": output.name, "platform": platform, "entries": len(records),
        "bytes": output.stat().st_size, "sha256": file_hash(output), "files": records,
        "runtimeVerification": ("native startup/render checked in development environment" if linux_verified else "not verified") if platform == "Linux" else "cross-exported; Windows runtime unverified",
        "checks": {"crc": "passed", "exactMembers": "passed", "perFileSha256": "passed", "under500MB": True,
                   "linuxExecutableBit": "preserved" if platform == "Linux" else "not applicable"},
    }


def package(output: Path, *, build: bool = False, linux_verified: bool = False) -> dict:
    output = output.resolve()
    if output == PROJECT or PROJECT in output.parents:
        raise PackageError("Output must be outside the project")
    config = application()
    inputs = notices()
    identities = {path: file_identity(path) for path in inputs + list(BINARY_PATHS.values())}
    plan = {"schemaVersion": 1, "application": config, "maximumArchiveBytes": LIMIT,
            "platforms": {key: {"binary": path.relative_to(PROJECT).as_posix(), "bytes": identities[path][0],
                                "archive": f"Draconia-{key}-v0.2.zip"} for key, path in BINARY_PATHS.items()},
            "documentationAndNoticeFiles": len(inputs), "buildRequested": build,
            "linuxVerificationDeclared": linux_verified, "windowsRuntimeVerified": False}
    print(json.dumps(plan, ensure_ascii=False, indent=2), flush=True)
    if not build:
        return plan
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="draconia-native-stage-", dir=output) as temporary:
        stage = Path(temporary)
        artifacts = []
        for platform in ["Linux", "Windows"]:
            print(f"Packaging verified inputs for {platform}", flush=True)
            artifacts.append(build_archive(stage, platform, inputs, identities, linux_verified))
        if any(file_identity(path) != expected for path, expected in identities.items()) or notices() != inputs or application() != config:
            raise PackageError("Release inputs changed during packaging; wait for the freeze and rerun")
        manifest = {"schemaVersion": 1, "application": config, "createdUtc": datetime.now(timezone.utc).isoformat(),
                    "artifacts": artifacts, "status": "archive integrity checked; platform limits remain explicit"}
        name = "release-native-v0.2.json"
        (stage / name).write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        for artifact in artifacts:
            os.replace(stage / artifact["filename"], output / artifact["filename"])
        os.replace(stage / name, output / name)
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--build", action="store_true", help="Actually package; default only prints a plan")
    parser.add_argument("--linux-verified", action="store_true", help="Release owner declares this exported Linux binary passed native startup/render verification")
    args = parser.parse_args()
    if not args.output.is_absolute():
        parser.error("Output must be an absolute path")
    try:
        result = package(args.output, build=args.build, linux_verified=args.linux_verified)
        if args.build:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (PackageError, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"Native packaging failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
