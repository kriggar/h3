#!/usr/bin/env python3
"""Package exact verified desktop exports in two ordinary ZIPs per platform.

This is a distribution-size fallback. It never exports, edits or launches game
binaries. The Linux helper is exercised with --verify-only on extracted bytes.
The existing single-ZIP package_native_v03.py remains unchanged.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import zipfile

PROJECT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("draconia_native_single", PROJECT / "tools/package_native_v03.py")
assert SPEC and SPEC.loader
BASE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BASE)
CHUNK_BYTES = 440_000_000
LIMIT = 500_000_000
LABEL = "v0.3.1-card-reconstruction"
BLOCK = 1024 * 1024
PackageError = BASE.PackageError


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def chunk_inventory(binary: Path) -> dict:
    identity = BASE.file_identity(binary)
    digest = hashlib.sha256()
    chunks = []
    with binary.open("rb") as handle:
        offset = 0
        while offset < identity[0]:
            length = min(CHUNK_BYTES, identity[0] - offset)
            part_digest = hashlib.sha256()
            remaining = length
            while remaining:
                data = handle.read(min(BLOCK, remaining))
                if not data:
                    raise PackageError("Unexpected end of exported executable")
                digest.update(data)
                part_digest.update(data)
                remaining -= len(data)
            number = len(chunks) + 1
            chunks.append({"number": number, "path": f"parts/{binary.name}.part{number:02d}",
                           "offset": offset, "bytes": length, "sha256": part_digest.hexdigest()})
            offset += length
    if len(chunks) != 2:
        raise PackageError("This bounded checkpoint requires exactly two chunks per executable")
    if BASE.file_identity(binary) != identity:
        raise PackageError("Executable changed during inventory")
    return {"name": binary.name, "bytes": identity[0], "sha256": digest.hexdigest(), "chunks": chunks}


def linux_launcher(model: dict) -> bytes:
    checks = "\n".join(
        f'check_file "{part["path"]}" "{part["sha256"]}" || fail "Missing or damaged Part{part["number"]:02d}; extract both ZIPs into the same folder."'
        for part in model["chunks"])
    joined = " ".join(f'"{part["path"]}"' for part in model["chunks"])
    content = r'''#!/bin/sh
set -eu
cd -- "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
verify_only=0
case "${1-}" in
  "") [ "$#" -eq 0 ] || { echo "Usage: ./Start-Draconia.sh [--verify-only]" >&2; exit 2; } ;;
  --verify-only) [ "$#" -eq 1 ] || exit 2; verify_only=1 ;;
  *) echo "Usage: ./Start-Draconia.sh [--verify-only]" >&2; exit 2 ;;
esac
temporary=""
cleanup() { if [ -n "$temporary" ]; then rm -f -- "$temporary"; fi; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { printf '%s\n' "$*" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required to check this download."
check_file() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  actual=$(sha256sum -- "$1") || return 1
  actual=${actual%% *}
  [ "$actual" = "$2" ]
}
binary="@@BINARY@@"
expected="@@SHA@@"
if [ -e "$binary" ] || [ -L "$binary" ]; then
  check_file "$binary" "$expected" || fail "A different or damaged $binary already exists. It was not overwritten. Move it aside yourself before retrying."
else
  printf '%s\n' "Checking both downloaded parts..."
@@CHECKS@@
  temporary=$(mktemp "./.Draconia-assembly.XXXXXXXX") || fail "Cannot create a temporary file in this folder."
  cat -- @@JOINED@@ > "$temporary" || fail "Assembly failed; check free disk space."
  check_file "$temporary" "$expected" || fail "Assembled executable hash mismatch; nothing was installed."
  chmod 755 "$temporary"
  # An atomic hard-link install refuses an existing destination, including a
  # different executable created by another process during assembly.
  ln -T -- "$temporary" "$binary" || fail "Cannot install the verified executable without overwriting an existing file."
  rm -f -- "$temporary"
  temporary=""
fi
printf 'DRACONIA_ASSEMBLY_VERIFIED %s\n' "$expected"
if [ "$verify_only" -eq 1 ]; then exit 0; fi
[ -x "$binary" ] || fail "Verified executable is not executable. Run chmod +x Draconia.x86_64 and retry."
exec "./$binary"
'''
    return (content.replace("@@BINARY@@", model["name"]).replace("@@SHA@@", model["sha256"])
            .replace("@@CHECKS@@", checks).replace("@@JOINED@@", joined)).encode("utf-8")


def windows_launcher(model: dict) -> bytes:
    checks = "\r\n".join(
        f'call :check "{part["path"].replace("/", chr(92))}" "{part["sha256"]}"\r\nif errorlevel 1 goto part_failure'
        for part in model["chunks"])
    joined = "+".join(f'"{part["path"].replace("/", chr(92))}"' for part in model["chunks"])
    text = r'''@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "VERIFY_ONLY=0"
if "%~1"=="" goto args_ok
if /I not "%~1"=="--verify-only" goto usage
if not "%~2"=="" goto usage
set "VERIFY_ONLY=1"
:args_ok
set "TEMPFILE="
set "BINARY=@@BINARY@@"
set "EXPECTED=@@SHA@@"
if exist "%BINARY%" goto existing
echo Checking both downloaded parts...
@@CHECKS@@
:choose_temporary
set "TEMPFILE=.Draconia-assembly-%RANDOM%-%RANDOM%.tmp"
if exist "%TEMPFILE%" goto choose_temporary
copy /-Y /b @@JOINED@@ "%TEMPFILE%" <nul >nul
if errorlevel 1 goto failure
call :check "%TEMPFILE%" "%EXPECTED%"
if errorlevel 1 goto failure
set "DRACONIA_TEMP_FILE=%CD%\%TEMPFILE%"
set "DRACONIA_TARGET_FILE=%CD%\%BINARY%"
rem File.Move is an atomic same-volume rename and refuses an existing target.
rem No execution-policy setting is changed. Only local data is processed.
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [IO.File]::Move($env:DRACONIA_TEMP_FILE,$env:DRACONIA_TARGET_FILE)"
if errorlevel 1 goto failure
set "TEMPFILE="
goto verified
:existing
call :check "%BINARY%" "%EXPECTED%"
if errorlevel 1 goto existing_failure
:verified
echo DRACONIA_ASSEMBLY_VERIFIED %EXPECTED%
if "%VERIFY_ONLY%"=="1" exit /b 0
start "" "%CD%\%BINARY%"
exit /b 0
:check
set "DRACONIA_CHECK_FILE=%~f1"
set "DRACONIA_ACTUAL="
for /f "delims=" %%H in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; $f=Get-Item -Force -LiteralPath $env:DRACONIA_CHECK_FILE; if ($f.PSIsContainer -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint)) { exit 2 }; [Console]::WriteLine((Get-FileHash -LiteralPath $env:DRACONIA_CHECK_FILE -Algorithm SHA256).Hash)"') do set "DRACONIA_ACTUAL=%%H"
if /I "%DRACONIA_ACTUAL%"=="%~2" exit /b 0
exit /b 1
:part_failure
echo Missing or damaged part. Download and extract BOTH ZIP files into the same folder.
goto failure
:existing_failure
echo A different or damaged %BINARY% already exists. It was NOT overwritten.
echo Move it aside yourself before retrying.
goto failure
:usage
echo Usage: Start-Draconia.cmd [--verify-only]
exit /b 2
:failure
if defined TEMPFILE echo A failed or interrupted assembly may leave %TEMPFILE%. It is ignored on retry; remove it only after no assembler is running.
echo Assembly failed. Nothing unverified was launched. Check the message above and free disk space.
if "%VERIFY_ONLY%"=="0" pause
exit /b 1
'''
    text = text.replace("@@BINARY@@", model["name"]).replace("@@SHA@@", model["sha256"])
    text = text.replace("@@CHECKS@@", checks.replace("\r\n", "\n")).replace("@@JOINED@@", joined)
    return text.replace("\n", "\r\n").encode("ascii")


def instructions(platform: str, root: str, model: dict) -> str:
    if platform == "Linux":
        launch = ("Use a writable Linux filesystem supporting hard links, such as your ordinary ext4/btrfs home directory (not FAT/exFAT). "
                  "Run `./Start-Draconia.sh`. If your extractor drops executable permissions, run `sh Start-Draconia.sh`.")
        verified = ("This exact restored executable passed native Linux startup/render and the actual MENU → SAVE & QUIT flow with an isolated autosave. "
                    "The packaging check also reassembled this real executable from the ZIPs using this helper in verify-only mode.")
        check = "`sh Start-Draconia.sh --verify-only`"
    else:
        launch = "Double-click `Start-Draconia.cmd`. It uses the built-in PowerShell file-hash utility; it does not change execution policy."
        verified = ("The executable was cross-exported for Windows x86-64. Windows gameplay and the Windows launch helper have NOT been execution-tested in this environment. "
                    "The archived byte chunks and their reconstructed full-executable hash were checked on Linux.")
        check = "`Start-Draconia.cmd --verify-only` from Command Prompt"
    return f"""# Draconia {LABEL.removeprefix('v')} — {platform}: read this first

## Download both files

You need **{root}-Part01.zip** AND **{root}-Part02.zip**. These are ordinary independent ZIPs, not special split-ZIP volumes.

1. Extract BOTH ZIPs into the SAME parent folder. Each contains the same `{root}` directory. Merge those directories; identical instructions and licenses may be replaced by their identical copies. Do not leave Part01 and Part02 in separate extraction folders.
2. Open the resulting `{root}` folder. Its `parts/` directory must contain both `.part01` and `.part02` files.
3. {launch}

The helper checks each part, assembles `{model['name']}` locally, and checks its complete SHA-256 before installation or launch. It makes no network requests. This is packaging of the exact verified bytes, not an installer or another game build.

Allow **3 GB free disk space** for the downloads, extracted parts and assembled executable for your chosen platform. The executable itself is {model['bytes']:,} bytes. The first launch needs space for both extracted parts and the assembled executable. After a successful verification you may remove the ZIPs and `parts/`; keep the executable, this folder's credits and licenses. Later launches can use the verified executable directly or the same Start helper.

## Safe recovery

The helper refuses to replace a different existing executable. Move such a file aside yourself if you intend to restore this build. An interrupted assembly cannot become the final executable without passing the hash check. A hard interruption may leave an ignored `.Draconia-assembly.*` / `.Draconia-assembly-*.tmp` file. After confirming no assembler is running, you may remove only that temporary assembly file and retry. Never rename a partial file to the game executable.

To assemble and verify without starting the game, use {check}. Missing or damaged parts are rejected. Download the affected ZIP again if its chunk fails verification.

Expected executable SHA-256:

`{model['sha256']}`

The exact part sizes and hashes are in `native-parts.json`.

## Verification boundary

{verified}

This remains a development checkpoint, not a full campaign or production-art acceptance. The Linux test used X11, Mesa software rendering and Dummy audio: it does not certify audible sound, target-GPU performance, every operating system or a complete playthrough. The prior window-manager-close issue is not certified by the successful menu exit.

No editor, browser, original Heroes installation or proprietary game data is required. Read `README.md` for the actual playable scope and controls. The original painted building cards remain authoritative.

## Licenses

Keep `ASSET_CREDITS.md`, `LICENSE.txt`, `assets/CINZEL-OFL.txt` and the complete `assets/licenses/` folder with the distribution. Downloaded art, fonts and engine components keep their original licenses. No proprietary Heroes III or Manor Lords assets are included.
"""


def write_bytes(archive: zipfile.ZipFile, member: str, data: bytes, *, executable: bool = False) -> dict:
    info = zipfile.ZipInfo(member, date_time=(2026, 10, 22, 0, 0, 0))
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | (0o755 if executable else 0o644)) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    archive.writestr(info, data)
    return {"path": member, "bytes": len(data), "sha256": sha(data)}


def write_chunk(archive: zipfile.ZipFile, binary: Path, root: str, part: dict) -> dict:
    info = zipfile.ZipInfo(f"{root}/{part['path']}", date_time=(2026, 10, 22, 0, 0, 0))
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | 0o644) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    value = hashlib.sha256()
    with binary.open("rb") as source, archive.open(info, "w", force_zip64=True) as target:
        source.seek(part["offset"])
        remaining = part["bytes"]
        while remaining:
            data = source.read(min(BLOCK, remaining))
            if not data:
                raise PackageError("Unexpected short executable read")
            target.write(data)
            value.update(data)
            remaining -= len(data)
    if value.hexdigest() != part["sha256"]:
        raise PackageError("Executable chunk changed while packaging")
    return {"path": info.filename, "bytes": part["bytes"], "sha256": part["sha256"]}


def verify_zip(path: Path, expected: list[dict]) -> dict:
    expected_names = {entry["path"] for entry in expected}
    if path.stat().st_size >= LIMIT:
        raise PackageError(f"{path.name}: {path.stat().st_size} bytes violates the strict sub-500 MB limit")
    with zipfile.ZipFile(path) as archive:
        if len(archive.namelist()) != len(expected_names) or set(archive.namelist()) != expected_names:
            raise PackageError("ZIP exact-member validation failed")
        if archive.testzip() is not None:
            raise PackageError("ZIP CRC validation failed")
        for record in expected:
            digest = hashlib.sha256()
            size = 0
            with archive.open(record["path"]) as handle:
                for data in iter(lambda: handle.read(BLOCK), b""):
                    digest.update(data)
                    size += len(data)
            if size != record["bytes"] or digest.hexdigest() != record["sha256"]:
                raise PackageError(f"Archived member differs: {record['path']}")
    return {"filename": path.name, "bytes": path.stat().st_size, "sha256": BASE.file_hash(path),
            "entries": len(expected), "files": expected,
            "checks": {"crc": "passed", "exactMembers": "passed", "perFileSha256": "passed", "under500MB": True}}


def reconstructed_archive_hash(paths: list[Path], root: str, model: dict) -> dict:
    total = 0
    digest = hashlib.sha256()
    for path, part in zip(paths, model["chunks"], strict=True):
        with zipfile.ZipFile(path) as archive, archive.open(f"{root}/{part['path']}") as handle:
            for data in iter(lambda: handle.read(BLOCK), b""):
                digest.update(data)
                total += len(data)
    if total != model["bytes"] or digest.hexdigest() != model["sha256"]:
        raise PackageError("Archived chunks do not reconstruct the exact accepted executable")
    return {"bytes": total, "sha256": digest.hexdigest(), "fromActualArchivedChunks": True}


def linux_assembly_proof(stage: Path, paths: list[Path], root: str, model: dict) -> dict:
    proof = {"platform": "Linux", "mode": "actual extracted helper, --verify-only; game never launched",
             "cases": [], "passed": False}
    proof_path = stage.parent / "linux-assembly-verification.json"
    proof_path.write_bytes(json_bytes(proof))
    with tempfile.TemporaryDirectory(prefix="linux-assembly-proof-", dir=stage) as temp:
        destination = Path(temp)
        for path in paths:
            with zipfile.ZipFile(path) as archive:
                for info in archive.infolist():
                    output = (destination / info.filename).resolve()
                    if not output.is_relative_to(destination.resolve()) or info.is_dir():
                        raise PackageError("Unexpected extraction member")
                    output.parent.mkdir(parents=True, exist_ok=True)
                    with archive.open(info) as source, output.open("wb") as target:
                        shutil.copyfileobj(source, target, BLOCK)
                    output.chmod((info.external_attr >> 16) & 0o777)
        folder = destination / root
        launcher = folder / "Start-Draconia.sh"
        binary = folder / model["name"]
        orphan = folder / ".Draconia-assembly.orphan-proof"
        orphan.write_bytes(b"ignored interrupted assembly sentinel\n")
        orphan_sha = BASE.file_hash(orphan)

        def run_case(name: str, success: bool) -> dict:
            started = time.monotonic()
            child = subprocess.Popen([str(launcher), "--verify-only"], cwd=folder,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     text=True, start_new_session=True)
            try:
                stdout, stderr = child.communicate(timeout=180)
            except BaseException as error:
                try:
                    os.killpg(child.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    stdout, stderr = child.communicate(timeout=3)
                except subprocess.TimeoutExpired:
                    try:
                        os.killpg(child.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    stdout, stderr = child.communicate(timeout=10)
                proof["cases"].append({"name": name, "exitCode": child.returncode,
                                       "stdout": stdout, "stderr": stderr,
                                       "passed": False, "interruptedBy": repr(error),
                                       "ownedChildReaped": True})
                proof_path.write_bytes(json_bytes(proof))
                raise
            record = {"name": name, "command": ["./Start-Draconia.sh", "--verify-only"],
                      "exitCode": child.returncode, "seconds": round(time.monotonic() - started, 3),
                      "stdout": stdout, "stderr": stderr,
                      "expectedSuccess": success, "passed": (child.returncode == 0) == success}
            proof["cases"].append(record)
            proof_path.write_bytes(json_bytes(proof))
            if not record["passed"]:
                raise PackageError(f"Actual Linux assembly case failed: {name}: {record}")
            return record

        run_case("complete actual archived executable", True)
        if (BASE.file_hash(binary) != model["sha256"] or binary.stat().st_size != model["bytes"]
                or not (binary.stat().st_mode & 0o111)):
            raise PackageError("Linux helper restored incorrect bytes or executable permissions")
        proof["restoredBinary"] = {"bytes": binary.stat().st_size, "sha256": BASE.file_hash(binary),
                                   "executableBit": True}
        run_case("already exact executable is reused", True)
        binary.unlink()  # Disposable extracted output, never the frozen export.
        part = folder / model["chunks"][1]["path"]
        missing = part.with_suffix(part.suffix + ".missing-proof")
        part.rename(missing)
        try:
            run_case("missing Part02 rejected", False)
            if binary.exists():
                raise PackageError("Missing-part rejection installed an executable")
        finally:
            missing.rename(part)
        with part.open("r+b") as handle:
            first = handle.read(1)
            handle.seek(0)
            handle.write(bytes([first[0] ^ 0x80]))
        try:
            run_case("corrupted Part02 rejected", False)
            if binary.exists():
                raise PackageError("Corrupt-part rejection installed an executable")
        finally:
            with part.open("r+b") as handle:
                handle.write(first)
        if BASE.file_hash(part) != model["chunks"][1]["sha256"]:
            raise PackageError("Disposable corruption fixture was not restored")
        binary.write_bytes(b"different existing executable; must remain unchanged\n")
        sentinel_sha = BASE.file_hash(binary)
        run_case("different existing executable refused", False)
        if BASE.file_hash(binary) != sentinel_sha:
            raise PackageError("Helper overwrote a different existing executable")
        if BASE.file_hash(orphan) != orphan_sha:
            raise PackageError("Helper touched an interrupted file it did not own")
        proof["interruptedSentinelUntouched"] = True
        proof["differentExistingExecutableUntouched"] = True
        proof["passed"] = True
    proof["disposableExtractionRemoved"] = True
    proof_path.write_bytes(json_bytes(proof))
    return proof


def build_platform(stage: Path, platform: str, inputs: list[Path], identities: dict,
                   evidence: dict, verification: dict) -> tuple[list[dict], dict]:
    binary = BASE.BINARY_PATHS[platform]
    model = chunk_inventory(binary)
    expected = evidence[platform]
    if model["sha256"] != expected["sha256"] or model["bytes"] != expected["bytes"]:
        raise PackageError(f"{platform} bytes differ from the accepted export evidence")
    with binary.open("rb") as handle:
        signature = handle.read(4)
    if not (signature == b"\x7fELF" if platform == "Linux" else signature[:2] == b"MZ"):
        raise PackageError(f"{platform} executable signature mismatch")
    root = f"Draconia-{platform}-{LABEL}"
    helper_name = "Start-Draconia.sh" if platform == "Linux" else "Start-Draconia.cmd"
    helper = linux_launcher(model) if platform == "Linux" else windows_launcher(model)
    details = {"schemaVersion": 1, "checkpoint": evidence["checkpoint"], "archiveLabel": LABEL,
               "platform": platform, "binary": model, "chunkSizeLimit": CHUNK_BYTES,
               "delivery": "two independent ordinary ZIPs; extract both into the same folder",
               "runtimeVerified": platform == "Linux", "windowsHelperExecutionVerified": False,
               "exportEvidenceSha256": verification["evidenceSha256"],
               "helper": {"path": helper_name, "sha256": sha(helper)},
               "verificationBoundary": "Linux startup/render and menu save/quit only; Windows cross-exported and runtime unverified."}
    common = [("START-HERE.md", instructions(platform, root, model).encode("utf-8")),
              ("native-parts.json", json_bytes(details)),
              ("VERIFICATION.json", json_bytes({"platform": platform, "linuxVerification": verification,
                 "windowsRuntimeVerified": False, "windowsHelperExecutionVerified": False,
                 "gameplayScope": "development checkpoint; no full-playthrough, sound or target-GPU acceptance"}))]
    artifacts = []
    paths = []
    for part in model["chunks"]:
        path = stage / f"{root}-Part{part['number']:02d}.zip"
        print(f"Writing {path.name}", flush=True)
        records = []
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as archive:
            records.append(write_chunk(archive, binary, root, part))
            for source in inputs:
                records.append(BASE.write_file(archive, source, f"{root}/{source.relative_to(PROJECT).as_posix()}", identities[source]))
            for name, data in common:
                records.append(write_bytes(archive, f"{root}/{name}", data))
            records.append(write_bytes(archive, f"{root}/{helper_name}", helper, executable=platform == "Linux"))
        verified = verify_zip(path, records)
        verified.update({"platform": platform, "part": part["number"], "partCount": 2,
                         "rawChunkBytes": part["bytes"], "rawChunkSha256": part["sha256"]})
        artifacts.append(verified)
        paths.append(path)
    restored = reconstructed_archive_hash(paths, root, model)
    proof = {"platform": platform, "binary": model, "archivedReconstruction": restored,
             "helperExecutionVerified": False, "runtimeVerified": platform == "Linux"}
    if platform == "Linux":
        print("Checking actual Linux extracted reassembly and rejection cases (no game launch)", flush=True)
        proof["actualLinuxAssembly"] = linux_assembly_proof(stage, paths, root, model)
        proof["helperExecutionVerified"] = True
    return artifacts, proof


def package(output: Path, build_root: Path, evidence_path: Path, *, build: bool, linux_verified: bool) -> dict:
    output = output.resolve()
    if output == PROJECT or output.is_relative_to(PROJECT):
        raise PackageError("Delivery output must be outside the project")
    build_root = build_root.resolve()
    if not build_root.is_relative_to(PROJECT / "builds"):
        raise PackageError("Build root must be within project/builds")
    BASE.BINARY_PATHS.update({"Linux": build_root / "linux/Draconia.x86_64",
                              "Windows": build_root / "windows/Draconia.exe"})
    config = BASE.application(enforce=True)
    if config["version"] != LABEL.removeprefix("v"):
        raise PackageError("This bounded multipart tool is for the frozen card-reconstruction checkpoint")
    if not linux_verified:
        raise PackageError("The release owner must supply --linux-verified")
    verification, evidence_files = BASE.linux_boot_evidence(evidence_path, config)
    evidence = json.loads(evidence_path.read_text())
    windows = evidence.get("Windows", {})
    if (windows.get("crossExportExitCode") != 0 or windows.get("runtimeVerified") is not False
            or Path(windows.get("binary", "")).resolve() != BASE.BINARY_PATHS["Windows"].resolve()):
        raise PackageError("Windows evidence must bind this exact successful, explicitly unverified cross-export")
    inputs = BASE.notices()
    tracked = inputs + evidence_files + list(BASE.BINARY_PATHS.values()) + [PROJECT / "project.godot", Path(__file__), PROJECT / "tools/package_native_v03.py"]
    identities = {path: BASE.file_identity(path) for path in tracked}
    source_hashes = {str(path.relative_to(PROJECT)): BASE.file_hash(path) for path in tracked if path.is_relative_to(PROJECT)}
    output.mkdir(parents=True, exist_ok=True)
    plan = {"schemaVersion": 1, "checkpoint": config["version"], "archiveLabel": LABEL,
            "mode": "multipart exact-binary packaging", "chunkBytes": CHUNK_BYTES,
            "maximumArchiveBytesExclusive": LIMIT, "buildRequested": build,
            "linuxEvidence": verification, "windowsRuntimeVerified": False,
            "freeDiskBytesBefore": shutil.disk_usage(output).free}
    plan_path = output / f"native-multipart-plan-{LABEL}.json"
    if plan_path.exists():
        raise PackageError("Use a new output directory; preserve the previous packaging plan")
    plan_path.write_bytes(json_bytes(plan))
    print(json.dumps(plan, indent=2), flush=True)
    if not build:
        return plan
    if shutil.disk_usage(output).free < 2_300_000_000:
        raise PackageError("At least 2.3 GB free is required for sequential archives and actual Linux reassembly")
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="native-multipart-stage-", dir=output) as temp:
        stage = Path(temp)
        artifacts = []
        proofs = []
        for platform in ["Linux", "Windows"]:
            current, proof = build_platform(stage, platform, inputs, identities, evidence, verification)
            artifacts += current
            proofs.append(proof)
        if BASE.notices() != inputs or BASE.application() != config:
            raise PackageError("Frozen release documentation/configuration changed while packaging")
        for path, identity in identities.items():
            if BASE.file_identity(path) != identity or BASE.file_hash(path) != source_hashes[str(path.relative_to(PROJECT))]:
                raise PackageError(f"Frozen packaging input changed: {path}")
        again, _ = BASE.linux_boot_evidence(evidence_path, config)
        if again != verification:
            raise PackageError("Linux runtime evidence changed during packaging")
        receipt = {"schemaVersion": 1, "checkpoint": config["version"], "archiveLabel": LABEL,
                   "createdUtc": datetime.now(timezone.utc).isoformat(), "durationSeconds": round(time.monotonic()-started, 3),
                   "status": "all four ordinary ZIPs verified; exact Linux extracted reassembly passed",
                   "artifacts": artifacts, "platformProofs": proofs,
                   "frozenInputSha256": source_hashes, "allFrozenInputsUnchanged": True,
                   "linuxVerification": verification, "windowsRuntimeVerified": False,
                   "windowsHelperExecutionVerified": False,
                   "limits": ["No runtime/export bytes changed.", "No game was launched by this packaging process.",
                              "Linux helper ran only in verify-only mode; Windows helper was not executed.",
                              "Full campaign, audible sound, target-GPU and production-art acceptance remain separate."],
                   "freeDiskBytesBeforePublication": shutil.disk_usage(output).free}
        receipt_name = f"release-native-multipart-{LABEL}.json"
        (stage / receipt_name).write_bytes(json_bytes(receipt))
        for artifact in artifacts:
            target = output / artifact["filename"]
            if target.exists():
                raise PackageError("Refusing to replace an existing archive")
        for artifact in artifacts:
            os.replace(stage / artifact["filename"], output / artifact["filename"])
        os.replace(stage / receipt_name, output / receipt_name)
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--build-root", required=True, type=Path)
    parser.add_argument("--linux-evidence", required=True, type=Path)
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--linux-verified", action="store_true")
    args = parser.parse_args()
    if not args.output.is_absolute() or not args.linux_evidence.is_absolute():
        parser.error("Output and evidence paths must be absolute")
    try:
        result = package(args.output, args.build_root, args.linux_evidence,
                         build=args.build, linux_verified=args.linux_verified)
        print(json.dumps({"status": result.get("status", "plan only"),
                          "artifacts": [{key: value for key, value in entry.items() if key != "files"}
                                        for entry in result.get("artifacts", [])]}, indent=2))
        return 0
    except (PackageError, OSError, ValueError, zipfile.BadZipFile, subprocess.SubprocessError) as error:
        print(f"Multipart packaging failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
