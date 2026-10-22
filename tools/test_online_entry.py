#!/usr/bin/env python3
"""Test actual online.tscn host/join/HUD/world callbacks in two processes.

The host renders natively in an isolated X display. The independent client
loads the same complete scene headlessly. All peers and game snapshots are real.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import select
import socket
import subprocess
import tempfile
import time


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--xvfb")
    parser.add_argument("--xvfb-lib-path")
    parser.add_argument("--headless-host", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    isolation = Path(tempfile.mkdtemp(prefix="draconia-entry-network-"))
    env = os.environ.copy()
    env.update(LIBGL_ALWAYS_SOFTWARE="1", GALLIUM_DRIVER="llvmpipe", LP_NUM_THREADS="4")
    if args.xvfb_lib_path:
        env["LD_LIBRARY_PATH"] = args.xvfb_lib_path
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    children: list[tuple[str, subprocess.Popen, object]] = []
    xvfb = None
    xlog = (output / "xvfb.log").open("w")
    failure = ""
    started = time.monotonic()

    def start(role: str) -> subprocess.Popen:
        local_env = env.copy()
        for key, name in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")):
            local_env[key] = str(isolation / role / name)
        flags = ["--rendering-method", "gl_compatibility", "--resolution", "1440x900"] if role == "host" and not args.headless_host else ["--headless"]
        if args.verbose:
            flags.append("--verbose")
        log = (output / f"{role}.log").open("w")
        process = subprocess.Popen(
            [args.godot, "--path", str(project), "--audio-driver", "Dummy", *flags,
             "--script", "res://tests/online/entry_network_probe.gd", "--",
             f"--role={role}", f"--out={output}", f"--test-port={port}"],
            cwd=project, env=local_env, stdout=log, stderr=subprocess.STDOUT,
        )
        children.append((role, process, log))
        return process

    def wait_file(name: str, timeout: float) -> None:
        deadline = min(started + 45.0, time.monotonic() + timeout)
        while time.monotonic() < deadline:
            if (output / name).exists():
                return
            for role, process, _ in children:
                if process.poll() not in (None, 0):
                    raise RuntimeError(f"{role} exited with {process.returncode}")
            time.sleep(0.05)
        raise TimeoutError("Timed out waiting for " + name)

    try:
        if not args.headless_host:
            if not args.xvfb:
                raise RuntimeError("Use --xvfb for native capture or --headless-host for the bounded integration gate")
            read_fd, write_fd = os.pipe()
            xvfb = subprocess.Popen(
                [args.xvfb, "-displayfd", str(write_fd), "-screen", "0", "1600x1000x24", "-nolisten", "tcp"],
                env=env, pass_fds=(write_fd,), stdout=xlog, stderr=subprocess.STDOUT,
            )
            os.close(write_fd)
            try:
                ready, _, _ = select.select([read_fd], [], [], 10)
                if not ready:
                    raise RuntimeError("Xvfb did not announce an isolated display")
                display = os.read(read_fd, 64).decode().strip()
            finally:
                os.close(read_fd)
            if not display.isdecimal():
                raise RuntimeError("Xvfb startup failed")
            env["DISPLAY"] = ":" + display
        host = start("host")
        wait_file("host-ready.json", 18)
        client = start("client")
        wait_file("host-report.json", 25)
        wait_file("client-report.json", 5)
        host.wait(timeout=3)
        client.wait(timeout=3)
    except (RuntimeError, TimeoutError, subprocess.TimeoutExpired) as error:
        failure = str(error)
    finally:
        for _, process, log in children:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            log.close()
        if xvfb is not None:
            xvfb.terminate()
            try:
                xvfb.wait(timeout=2)
            except subprocess.TimeoutExpired:
                xvfb.kill()
                xvfb.wait()
        xlog.close()
    reports = []
    for role, process, _ in children:
        path = output / f"{role}-report.json"
        report = json.loads(path.read_text()) if path.exists() else {"role": role, "checks": 0, "passed": False, "failures": ["No completion report"]}
        text = (output / f"{role}.log").read_text()
        report["runtime_errors"] = [line for line in text.splitlines() if re.search(r"SCRIPT ERROR|^ERROR:|leaked|still in use|GL_INVALID", line)]
        report["exit_code"] = process.returncode
        report["passed"] = bool(report["passed"] and process.returncode == 0 and not report["runtime_errors"])
        reports.append(report)
    captures = [{"file": path.name, "bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in sorted(output.glob("*.png"))]
    result = {"suite": "shipped_entry_multiplayer", "passed": not failure and len(reports) == 2 and all(report["passed"] for report in reports),
              "checks": sum(report["checks"] for report in reports), "seconds": round(time.monotonic() - started, 2),
              "failure": failure, "processes": reports, "captures": captures,
              "method": "Two independent Godot processes instantiate shipped online.tscn; " + ("both headless" if args.headless_host else "native GL Compatibility host and headless client") + ". Real main menu paths, production Session networking, world actors, HUD party/chat and disconnect-to-lobby callbacks.",
              "limits": "Scripted menu and client-input intents; not a manual mouse playthrough, WAN test, or hardware performance benchmark."}
    (output / "entry-network-report.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
