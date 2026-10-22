#!/usr/bin/env python3
"""Render the native HUD fixture with isolated data and real GUI input events.

Example:
  python tools/ui_run_probe.py --godot /path/to/godot --output-dir /tmp/ui-review
Pass --xvfb /path/to/Xvfb when no display is available. Optional native Xvfb
library dependencies belong in --xvfb-library-dir, never in the game archive.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import select
import shutil
import subprocess
import sys
import tempfile


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--xvfb", default=None)
    parser.add_argument("--xvfb-library-dir", default=None)
    args = parser.parse_args()
    if not args.godot:
        parser.error("Provide --godot or install Godot on PATH")
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    project = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory(prefix="draconia-ui-") as isolated:
        env = os.environ.copy()
        for key, folder in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
            env[key] = str(Path(isolated) / folder)
        env.update(LIBGL_ALWAYS_SOFTWARE="1", GALLIUM_DRIVER="llvmpipe")
        if args.xvfb_library_dir:
            env["LD_LIBRARY_PATH"] = args.xvfb_library_dir
        display_process = None
        descriptor = None
        xlog = None
        try:
            if args.xvfb or (sys.platform.startswith("linux") and not env.get("DISPLAY")):
                binary = args.xvfb or shutil.which("Xvfb")
                if not binary:
                    parser.error("A display or --xvfb is required for rendered screenshots")
                descriptor, write_descriptor = os.pipe()
                xlog = (output / "xvfb.log").open("w")
                display_process = subprocess.Popen(
                    [binary, "-displayfd", str(write_descriptor), "-screen", "0", "1600x1000x24", "-nolisten", "tcp"],
                    env=env, pass_fds=(write_descriptor,), stdout=xlog, stderr=subprocess.STDOUT,
                )
                os.close(write_descriptor)
                ready, _, _ = select.select([descriptor], [], [], 15)
                if not ready:
                    raise RuntimeError("Xvfb did not announce a display; see xvfb.log")
                display = os.read(descriptor, 64).decode().strip()
                if not display.isdecimal():
                    raise RuntimeError("Xvfb failed to start; see xvfb.log")
                env["DISPLAY"] = ":" + display
            command = [args.godot, "--path", str(project), "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/online/hud_probe.gd", "--", "--output-dir=" + str(output)]
            with (output / "godot.log").open("w") as log:
                result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=180)
            text = (output / "godot.log").read_text()
            if result.returncode or "SCRIPT ERROR" in text or "FAILED:" in text or any(line.startswith("ERROR:") for line in text.splitlines()):
                print(text, file=sys.stderr)
                return result.returncode or 1
            report_path = output / "report.json"
            report = json.loads(report_path.read_text())
            report["source_sha256"] = {path: hashlib.sha256((project / path).read_bytes()).hexdigest() for path in ["game/online/hud.gd", "game/online/ui_frame.gd", "game/online/ui_minimap.gd", "game/online/avatar.gd", "game/online/catalog.gd", "game/online/realm.gd", "assets/online/icons/abilities.png", "tests/online/hud_probe.gd"]}
            report_path.write_text(json.dumps(report, indent=2) + "\n")
            print(json.dumps({"exit_code": result.returncode, "report": str(report_path), "log": str(output / "godot.log")}))
            return result.returncode
        finally:
            if descriptor is not None:
                os.close(descriptor)
            if display_process is not None:
                display_process.terminate()
                try:
                    display_process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    display_process.kill()
                    display_process.wait()
            if xlog is not None:
                xlog.close()


if __name__ == "__main__":
    raise SystemExit(main())
