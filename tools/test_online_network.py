#!/usr/bin/env python3
"""Exercise real ENet transport in independent native Godot processes.

Fixture scripts may place entities on the trusted server to shorten setup;
movement, action RPCs, state replication, reward checks, identity, persistence,
late join and disconnect always use the production Session/Realm code.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output-dir")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = Path(args.output_dir or tempfile.mkdtemp(prefix="draconia-online-network-")).resolve()
    output.mkdir(parents=True, exist_ok=True)
    # Isolated user data prevents fixtures from changing a player's real saves.
    isolation = Path(tempfile.mkdtemp(prefix="draconia-online-processes-"))
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    children: list[tuple[str, subprocess.Popen, object]] = []

    def start(role: str, data_identity: str) -> subprocess.Popen:
        env = os.environ.copy()
        for key, subdir in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")):
            env[key] = str(isolation / data_identity / subdir)
        log = (output / f"{role}.log").open("w")
        process = subprocess.Popen(
            [args.godot, "--headless", "--path", str(project), "--script", "res://tests/online/network_worker.gd", "--",
             f"--role={role}", f"--out={output}", f"--port={port}"],
            cwd=project, env=env, stdout=log, stderr=subprocess.STDOUT,
        )
        children.append((role, process, log))
        return process

    def wait_file(filename: str, timeout: float = 15.0) -> dict:
        deadline = time.monotonic() + timeout
        path = output / filename
        while time.monotonic() < deadline:
            if path.exists():
                try:
                    return json.loads(path.read_text())
                except json.JSONDecodeError:
                    pass
            failed = [role for role, process, _ in children if process.poll() not in (None, 0)]
            if failed:
                raise RuntimeError("Worker failed: " + ", ".join(failed))
            time.sleep(0.04)
        raise TimeoutError(f"Timed out waiting for {filename}")

    failure = ""
    try:
        host = start("server", "host")
        wait_file("server-ready.json")
        first = start("client_a", "client-a")
        wait_file("server-ready_late.json")
        second = start("client_b", "client-b")
        wait_file("client_a-report.json")
        wait_file("server-report.json")
        wait_file("client_b-report.json")
        for process in (first, second, host):
            process.wait(timeout=5)
        resumed_host = start("resume_server", "host")
        wait_file("resume_server-ready.json")
        resumed_client = start("resume_client", "client-a")
        wait_file("resume_server-report.json")
        wait_file("resume_client-report.json")
        for process in (resumed_host, resumed_client):
            process.wait(timeout=5)
    except (RuntimeError, TimeoutError, subprocess.TimeoutExpired) as error:
        failure = str(error)
    finally:
        for _, process, log in children:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            log.close()
    reports = []
    for role, process, _ in children:
        report_path = output / f"{role}-report.json"
        report = json.loads(report_path.read_text()) if report_path.exists() else {"role": role, "passed": False, "checks": 0, "failures": ["No completion report"]}
        report["exit_code"] = process.returncode
        log = (output / f"{role}.log").read_text()
        report["runtime_errors"] = [line for line in log.splitlines() if "SCRIPT ERROR" in line or line.startswith("ERROR:")]
        report["passed"] = bool(report["passed"] and process.returncode == 0 and not report["runtime_errors"])
        reports.append(report)
    result = {"suite": "independent_process_enet", "passed": not failure and len(reports) == 5 and all(r["passed"] for r in reports),
              "checks": sum(r["checks"] for r in reports), "failure": failure, "processes": reports,
              "scope": "Localhost native ENet, 2 concurrent clients, late join, duplicate reward rejection, same-name isolation, server restart/profile reconnect and host loss.",
              "not_tested": "WAN routing/NAT, internet latency or load capacity, public account authentication."}
    (output / "network-report.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
