#!/usr/bin/env python3
"""Package already-exported 0.3 desktop binaries; never export or upload.

Plan: python3 tools/package_native_v03.py --output /absolute/deliverables/v0.3
After the release owner freezes inputs and checks Linux startup/render:
  add --build --linux-verified
  --linux-evidence defaults to docs/verification-logs/native-v03-exports.json.
The evidence must bind the actual exported Linux hash to a native boot log.
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
RELEASE_SERIES = "0.3"
DEFAULT_ARCHIVE_LABEL = "v0.3"
DEFAULT_LINUX_EVIDENCE = PROJECT / "docs/verification-logs/native-v03-exports.json"
BINARY_PATHS = {
    "Linux": PROJECT / "builds/v0.3/linux/Draconia.x86_64",
    "Windows": PROJECT / "builds/v0.3/windows/Draconia.exe",
}


class PackageError(Exception):
    pass


def validate_archive_label(value: str) -> str:
    """A release label is one short, portable filename component."""
    if (not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,79}", value)
            or ".." in value or value.endswith(".")):
        raise PackageError("Archive label must be 1-80 ASCII letters/digits/dots/underscores/hyphens, "
                           "begin with a letter/digit, and contain no '..' or trailing dot")
    return value


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


def application(*, enforce: bool = True) -> dict:
    text = (PROJECT / "project.godot").read_text(encoding="utf-8")
    found = {}
    for label, key in [("version", "config/version"), ("mainScene", "run/main_scene")]:
        match = re.search(r"^" + re.escape(key) + r'="([^"]+)"', text, re.M)
        found[label] = match.group(1) if match else ""
    if enforce and not configured_for_release(found):
        raise PackageError("The 0.3 action scene must be the configured entry before packaging")
    return found


def configured_for_release(config: dict) -> bool:
    return (bool(re.match(r"^0\.3(?:$|[.+-])", config["version"]))
            and config["mainScene"] == "res://redesign.tscn")


def evidence_path(value: str) -> Path:
    if not isinstance(value, str) or not value:
        raise PackageError("Linux verification evidence contains an empty/non-string path")
    path = Path(value)
    return path if path.is_absolute() else PROJECT / path


def linux_boot_evidence(path: Path, config: dict) -> tuple[dict, list[Path]]:
    """Bind the release owner's native boot record to this exact export.

    Schema follows docs/verification-logs/native-v02-exports.json, with a 0.3
    checkpoint. This reads evidence only: it does not launch the game or infer
    a full-playthrough/driver certification from startup.
    """
    path = path.resolve()
    file_identity(path)
    evidence = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(evidence, dict):
        raise PackageError("Linux evidence must be a JSON object")
    if evidence.get("checkpoint") != config["version"]:
        raise PackageError("Linux evidence checkpoint does not match project.godot")
    if evidence.get("acceptedForDevelopmentCheckpoint") is not True:
        raise PackageError("Linux native evidence has not been accepted for the development checkpoint")
    linux = evidence.get("Linux", {})
    if not isinstance(linux, dict):
        raise PackageError("Linux evidence is missing the Linux record")
    binary = BINARY_PATHS["Linux"]
    if evidence_path(linux.get("binary", "")).resolve() != binary.resolve():
        raise PackageError("Linux evidence refers to a different exported binary path")
    binary_identity = file_identity(binary)
    binary_sha = file_hash(binary)
    if linux.get("bytes") != binary_identity[0] or linux.get("sha256") != binary_sha:
        raise PackageError("Linux evidence size/hash does not match the exported binary")
    native = linux.get("native", {})
    if not isinstance(native, dict):
        raise PackageError("Linux evidence is missing the native boot record")
    command = native.get("command", [])
    if (native.get("mode") != "native" or type(native.get("exitCode")) is not int
            or native["exitCode"] != 0 or native.get("renderBackendPresent") is not True):
        raise PackageError("Linux build requires successful native startup with a rendering backend")
    if (not isinstance(command, list) or not command
            or not all(isinstance(arg, str) for arg in command)
            or evidence_path(command[0]).resolve() != binary.resolve()
            or any("headless" in arg.lower() for arg in command[1:])):
        raise PackageError("Linux evidence must launch this exported binary in native, non-headless mode")
    overrides = {"--script", "-s", "--main-pack", "--editor", "-e", "--path", "--project-manager", "-p"}
    if any(arg.split("=", 1)[0] in overrides for arg in command[1:]):
        raise PackageError("Linux boot evidence must use the exported game's own entry, without script/project/pack overrides")
    log = evidence_path(native.get("log", "")).resolve()
    log_identity = file_identity(log)
    log_text = log.read_text(encoding="utf-8", errors="replace")
    if not log_identity[0] or not re.search(r"OpenGL|Vulkan|Direct3D", log_text, re.I):
        raise PackageError("The retained Linux boot log lacks a native renderer startup record")
    log_sha = file_hash(log)
    recorded_log_sha = native.get("logSha256", "")
    if (not isinstance(recorded_log_sha, str)
            or not re.fullmatch(r"[0-9a-fA-F]{64}", recorded_log_sha)
            or recorded_log_sha.lower() != log_sha):
        raise PackageError("The retained Linux boot log requires its valid matching SHA-256")
    # Paths in the distributed summary are project-relative or basenames;
    # local XDG directories and command-line environment details are not copied.
    summary = {
        "checkpoint": evidence["checkpoint"], "binarySha256": binary_sha,
        "binaryBytes": binary_identity[0], "mode": "native", "exitCode": 0,
        "renderBackendPresent": True, "evidenceSha256": file_hash(path),
        "bootLogSha256": log_sha, "bootLogBytes": log_identity[0],
        "evidenceFile": path.name, "bootLogFile": log.name,
        "diagnostics": native.get("diagnostics", []),
        "scope": "Actual exported Linux startup/render in the recorded development environment; full playthrough and other drivers are separate.",
    }
    return summary, [path, log]


def platform_notice(platform: str, linux_verified: bool, archive_label: str = DEFAULT_ARCHIVE_LABEL) -> str:
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
    return f"""# Draconia {archive_label.removeprefix('v')} — {platform} package

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


def build_archive(folder: Path, platform: str, inputs: list[Path], identities: dict[Path, tuple[int, int]],
                  linux_verified: bool, verification: dict,
                  archive_label: str = DEFAULT_ARCHIVE_LABEL) -> dict:
    archive_label = validate_archive_label(archive_label)
    root = f"Draconia-{platform}-{archive_label}"
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
        notice = platform_notice(platform, linux_verified, archive_label).encode("utf-8")
        member = root + "/PLATFORM-NOTES.md"
        info = zipfile.ZipInfo(member, date_time=(2026, 10, 22, 0, 0, 0))
        info.create_system = 3
        info.external_attr = (stat.S_IFREG | 0o644) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(info, notice)
        records.append({"path": member, "bytes": len(notice), "sha256": hashlib.sha256(notice).hexdigest()})
        details = {"releaseSeries": RELEASE_SERIES, "archiveLabel": archive_label,
                   "checkpoint": verification.get("checkpoint"), "platform": platform,
                   "runtimeVerified": platform == "Linux",
                   "verification": verification if platform == "Linux" else
                       {"status": "cross-exported; Windows runtime unverified"}}
        evidence = (json.dumps(details, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
        member = root + "/VERIFICATION.json"
        info = zipfile.ZipInfo(member, date_time=(2026, 10, 22, 0, 0, 0))
        info.create_system = 3
        info.external_attr = (stat.S_IFREG | 0o644) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(info, evidence)
        records.append({"path": member, "bytes": len(evidence), "sha256": hashlib.sha256(evidence).hexdigest()})
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


def package(output: Path, *, build: bool = False, linux_verified: bool = False,
            linux_evidence: Path = DEFAULT_LINUX_EVIDENCE,
            archive_label: str = DEFAULT_ARCHIVE_LABEL) -> dict:
    archive_label = validate_archive_label(archive_label)
    output = output.resolve()
    if output == PROJECT or PROJECT in output.parents:
        raise PackageError("Output must be outside the project")
    config = application(enforce=build)
    inputs = notices()
    identities = {path: file_identity(path) for path in inputs}
    pending = []
    if not configured_for_release(config):
        pending.append("Configure version 0.3 and res://redesign.tscn after release verification")
    platforms = {}
    for platform, path in BINARY_PATHS.items():
        if path.exists():
            identities[path] = file_identity(path)
        else:
            pending.append(f"Missing final {platform} export: {path.relative_to(PROJECT)}")
        platforms[platform] = {"binary": path.relative_to(PROJECT).as_posix(),
                               "bytes": identities[path][0] if path in identities else None,
                               "archive": f"Draconia-{platform}-{archive_label}.zip"}
    if not linux_verified:
        pending.append("Release owner must supply --linux-verified after reviewing the exported Linux boot")
    verification, evidence_inputs = {}, []
    try:
        verification, evidence_inputs = linux_boot_evidence(linux_evidence, config)
        identities.update({path: file_identity(path) for path in evidence_inputs})
    except (PackageError, OSError, ValueError) as error:
        pending.append(f"Linux verification evidence pending: {error}")
    plan = {"schemaVersion": 2, "releaseSeries": RELEASE_SERIES, "archiveLabel": archive_label,
            "application": config, "maximumArchiveBytes": LIMIT,
            "platforms": platforms,
            "documentationAndNoticeFiles": len(inputs), "buildRequested": build,
            "linuxVerificationDeclared": linux_verified, "linuxEvidenceBound": bool(verification),
            "windowsRuntimeVerified": False, "pendingBuildGates": pending, "archivesBuilt": False}
    output.mkdir(parents=True, exist_ok=True)
    (output / f"native-plan-{archive_label}.json").write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(plan, ensure_ascii=False, indent=2), flush=True)
    if not build:
        return plan
    if pending:
        raise PackageError("Final native build gates are incomplete: " + "; ".join(pending))
    with tempfile.TemporaryDirectory(prefix="draconia-native-stage-", dir=output) as temporary:
        stage = Path(temporary)
        artifacts = []
        for platform in ["Linux", "Windows"]:
            print(f"Packaging verified inputs for {platform}", flush=True)
            artifacts.append(build_archive(stage, platform, inputs, identities, linux_verified, verification, archive_label))
        if any(file_identity(path) != expected for path, expected in identities.items()) or notices() != inputs or application() != config:
            raise PackageError("Release inputs changed during packaging; wait for the freeze and rerun")
        verified_again, _ = linux_boot_evidence(linux_evidence, config)
        if verified_again != verification:
            raise PackageError("Linux binary/evidence changed during packaging")
        manifest = {"schemaVersion": 2, "releaseSeries": RELEASE_SERIES, "archiveLabel": archive_label,
                    "application": config, "createdUtc": datetime.now(timezone.utc).isoformat(),
                    "artifacts": artifacts, "linuxVerification": verification,
                    "windowsRuntimeVerified": False, "status": "archive integrity checked; platform limits remain explicit"}
        name = f"release-native-{archive_label}.json"
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
    parser.add_argument("--linux-evidence", type=Path, default=DEFAULT_LINUX_EVIDENCE,
                        help="Accepted 0.3 export/native-boot evidence JSON; hashes must match this exact Linux binary")
    parser.add_argument("--build-root", type=Path, default=PROJECT / "builds/v0.3",
                        help="Project builds directory containing linux/ and windows/; preserves earlier exported checkpoints")
    parser.add_argument("--archive-label", default=DEFAULT_ARCHIVE_LABEL,
                        help="Filename-safe archive/checkpoint label; default v0.3 preserves existing names")
    args = parser.parse_args()
    if not args.output.is_absolute():
        parser.error("Output must be an absolute path")
    build_root = args.build_root.resolve()
    if not build_root.is_relative_to((PROJECT / "builds").resolve()):
        parser.error("Build root must be within this project's builds directory")
    BINARY_PATHS.update({"Linux": build_root / "linux/Draconia.x86_64",
                         "Windows": build_root / "windows/Draconia.exe"})
    try:
        result = package(args.output, build=args.build, linux_verified=args.linux_verified,
                         linux_evidence=args.linux_evidence, archive_label=args.archive_label)
        if args.build:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (PackageError, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"Native packaging failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
