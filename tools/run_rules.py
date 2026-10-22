#!/usr/bin/env python3
"""Run Draconia's headless rules suites with isolated saves and retained logs.

Requires Python 3.8+ and a Godot 4 editor executable. Examples:
    python tools/run_rules.py
    python tools/run_rules.py --godot /path/to/godot --output-dir rules-results
    python tools/run_rules.py --suites action_rules dungeon_catalog

The runner copies the exact rules, data, tests, and JSON fixtures into small
temporary projects. Each suite receives a unique application name, separate
data/config/cache directories, and an explicit log path. This keeps tests away
from player saves on every supported desktop platform without modifying the
real project or copying its large asset tree. Reports retain source hashes;
this is a logic gate, not a test of the native main scene or asset imports.
"""

import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
import uuid


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SUITES = (
    "realm", "hunts", "progression", "hero_identity", "item_rules",
    "action_rules", "dungeon_catalog", "expedition_guidance",
)
SOURCE_PATHS = (
    "game/redesign/realm_rules.gd",
    "game/redesign/hunt_rules.gd",
    "game/redesign/action_rules.gd",
    "game/redesign/item_rules.gd",
    "game/redesign/hero_identity.gd",
    "game/redesign/dungeon_catalog.gd",
    "game/redesign/expedition_chart.gd",
    "game/redesign/manuscript_theme.gd",
    "game/redesign/manuscript_frame.gd",
    "data/class_catalog.json",
    "data/hero_roster.json",
)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def input_paths(suites):
    paths = set(SOURCE_PATHS)
    paths.update("tests/test_{}.gd".format(name) for name in suites)
    paths.update(path.relative_to(PROJECT_ROOT).as_posix()
                 for path in (PROJECT_ROOT / "tests/fixtures").rglob("*.json"))
    return sorted(paths)


def input_hashes(paths):
    return {name: sha256(PROJECT_ROOT / name) for name in paths}


def parse_summaries(output):
    summaries = []
    lines = []
    for line in output.splitlines():
        match = re.search(r"ACTION RULES: (\d+) groups, (\d+) checks, (\d+) failures", line)
        if match:
            summaries.append(dict(zip(("groups", "checks", "failures"), map(int, match.groups()))))
            lines.append(line)
            continue
        if line.startswith("{") or "_SUMMARY " in line:
            try:
                record = json.loads(line[line.index("{"):])
            except (ValueError, json.JSONDecodeError):
                continue
            if isinstance(record, dict) and "checks" in record and "failures" in record:
                summaries.append(record)
                lines.append(line)
    return summaries, lines


def prepare_suite(directory, name, run_id, snapshot, paths):
    project = directory / "project"
    project.mkdir(parents=True)
    for relative in paths:
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(snapshot / relative, target)
    application_name = "DraconiaRules-{}-{}".format(run_id, name)
    (project / "project.godot").write_text(
        'config_version=5\n\n[application]\nconfig/name={name}\n\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n'.format(
            name=json.dumps(application_name)), encoding="utf-8")
    # Verify the actual engine-resolved identity before any suite can run.
    bootstrap = '''extends "res://tests/test_{suite}.gd"

func _initialize() -> void:
\tvar directory: String = OS.get_user_data_dir()
\tif directory.replace("\\\\", "/").get_file() != {application_name}:
\t\tpush_error("Rules runner could not verify isolated application storage.")
\t\tquit(1)
\t\treturn
\tprint("RULES_STORAGE ", JSON.stringify({{"applicationName":{application_name},"userDataDir":directory}}))
\tsuper._initialize()
'''.format(suite=name, application_name=json.dumps(application_name))
    (project / "run_suite.gd").write_text(bootstrap, encoding="utf-8")
    return project, application_name


def run_suite(name, args, run_id, snapshot, paths, expected_hashes):
    directory = args.output_dir / name
    directory.mkdir()
    project, application_name = prepare_suite(directory, name, run_id, snapshot, paths)
    env = os.environ.copy()
    for variable, leaf in (
        ("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
        ("XDG_CACHE_HOME", "cache"), ("APPDATA", "appdata"),
        ("LOCALAPPDATA", "localappdata"),
    ):
        target = directory / leaf
        target.mkdir()
        env[variable] = str(target)
    env["GODOT_SILENCE_ROOT_WARNING"] = "1"
    log_path = directory / "godot.log"
    command = [args.godot, "--headless", "--path", str(project),
               "--log-file", str(directory / "engine.log"),
               "--script", "res://run_suite.gd"]
    before = input_hashes(paths)
    started = time.monotonic()
    launch_error = None
    with log_path.open("w", encoding="utf-8") as log:
        try:
            process = subprocess.run(command, cwd=project, env=env, stdout=log,
                                     stderr=subprocess.STDOUT, timeout=args.timeout)
            status = process.returncode
        except subprocess.TimeoutExpired:
            status = "timeout"
            launch_error = "Suite exceeded the {} second limit.".format(args.timeout)
        except OSError as error:
            status = "launch_error"
            launch_error = str(error)
    after = input_hashes(paths)
    output = log_path.read_text(encoding="utf-8", errors="replace")
    summaries, summary_lines = parse_summaries(output)
    diagnostics = [line for line in output.splitlines()
                   if line.startswith(("ERROR:", "SCRIPT ERROR:")) or "FAIL:" in line]
    if launch_error:
        diagnostics.append(launch_error)
    storage = None
    for line in output.splitlines():
        if line.startswith("RULES_STORAGE "):
            storage = json.loads(line[len("RULES_STORAGE "):])
    stable = before == expected_hashes == after
    summary = summaries[-1] if summaries else {}
    passed = (status == 0 and stable and bool(summary)
              and summary.get("failures") == 0 and not diagnostics
              and bool(storage) and storage.get("applicationName") == application_name)
    report = {
        "suite": name, "passed": passed, "exit_code": status,
        "checks": summary.get("checks", 0), "failures": summary.get("failures"),
        "seconds": round(time.monotonic() - started, 3), "command": command,
        "source_revision_stable": stable,
        "source_hashes_before": before, "source_hashes_after": after,
        "test_sha256": expected_hashes["tests/test_{}.gd".format(name)],
        "summary": summary, "summary_lines": summary_lines,
        "diagnostics": diagnostics, "isolated_storage": storage,
        "log": str(log_path), "log_sha256": sha256(log_path),
    }
    write_json(directory / "result.json", report)
    print("{} {:22s} {:4d} checks  {:.2f}s".format(
        "PASS" if passed else "FAIL", name, int(report["checks"]), report["seconds"]), flush=True)
    for message in diagnostics:
        print("  " + message, flush=True)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--godot", default="godot", help="Godot 4 executable or command on PATH (default: godot)")
    parser.add_argument("--output-dir", type=Path, help="New or empty result directory (default: a retained temporary directory)")
    parser.add_argument("--suites", nargs="+", choices=DEFAULT_SUITES, default=list(DEFAULT_SUITES))
    parser.add_argument("--jobs", type=int, default=3, help="Parallel suite processes (default: 3)")
    parser.add_argument("--timeout", type=int, default=180, help="Maximum seconds per suite (default: 180)")
    args = parser.parse_args()
    if args.jobs < 1 or args.timeout < 1:
        parser.error("--jobs and --timeout must be positive")
    if len(args.suites) != len(set(args.suites)):
        parser.error("each suite may be selected only once")
    candidate = Path(args.godot).expanduser()
    executable = str(candidate.resolve()) if candidate.is_file() else shutil.which(args.godot)
    if not executable:
        parser.error("Godot was not found; supply --godot with the path to its editor executable")
    args.godot = str(Path(executable).resolve())
    if args.output_dir is None:
        args.output_dir = Path(tempfile.mkdtemp(prefix="draconia-rules-"))
    else:
        args.output_dir = args.output_dir.expanduser().resolve()
        if args.output_dir.exists() and (not args.output_dir.is_dir() or any(args.output_dir.iterdir())):
            parser.error("--output-dir must be new or empty so earlier evidence is preserved")
        args.output_dir.mkdir(parents=True, exist_ok=True)
    paths = input_paths(args.suites)
    missing = [name for name in paths if not (PROJECT_ROOT / name).is_file()]
    if missing:
        parser.error("Required project files are missing: " + ", ".join(missing))
    expected_hashes = input_hashes(paths)
    snapshot = args.output_dir / "source"
    snapshot.mkdir()
    for relative in paths:
        target = snapshot / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(PROJECT_ROOT / relative, target)
        if sha256(target) != expected_hashes[relative]:
            parser.error("Project changed while making the test snapshot; rerun after edits finish")
    run_id = uuid.uuid4().hex
    write_json(args.output_dir / "source-manifest.json", expected_hashes)
    print("Rules results: {}".format(args.output_dir), flush=True)
    started = time.monotonic()
    with concurrent.futures.ThreadPoolExecutor(max_workers=min(args.jobs, len(args.suites))) as pool:
        futures = [pool.submit(run_suite, name, args, run_id, snapshot, paths, expected_hashes)
                   for name in args.suites]
        results = [future.result() for future in futures]
    stable = input_hashes(paths) == expected_hashes
    report = {
        "passed": stable and all(item["passed"] for item in results),
        "checks": sum(int(item["checks"]) for item in results),
        "failures": sum(int(item["failures"] or 0) for item in results),
        "source_revision_stable": stable,
        "seconds": round(time.monotonic() - started, 3),
        "project_root": str(PROJECT_ROOT), "godot": args.godot,
        "source_hashes": expected_hashes, "suites": results,
        "scope": "Headless rules and guidance only; separate native-scene and visual checks are required.",
    }
    write_json(args.output_dir / "report.json", report)
    print("{}: {} suites, {} checks, {} reported assertion failures. Report: {}".format(
        "PASS" if report["passed"] else "FAIL", len(results), report["checks"],
        report["failures"], args.output_dir / "report.json"), flush=True)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
