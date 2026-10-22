#!/usr/bin/env python3
"""Render actual Draconia gameplay through Session/Realm and encode an MP4.

Owns an isolated temporary X display and save directory. The resulting footage
is labelled as native game with scripted inputs. No generated frames or audio.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--xvfb")
    parser.add_argument("--xvfb-lib-path")
    parser.add_argument("--metrics-only", action="store_true")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    isolation = Path(tempfile.mkdtemp(prefix="draconia-gameplay-motion-"))
    env = os.environ.copy()
    env.update(XDG_DATA_HOME=str(isolation / "data"),
               XDG_CONFIG_HOME=str(isolation / "config"),
               XDG_CACHE_HOME=str(isolation / "cache"),
               LIBGL_ALWAYS_SOFTWARE="1", GALLIUM_DRIVER="llvmpipe")
    if args.xvfb_lib_path:
        env["LD_LIBRARY_PATH"] = args.xvfb_lib_path
    display_process = None
    xlog = None
    try:
        if args.xvfb and not args.metrics_only:
            read_fd, write_fd = os.pipe()
            xlog = (output / "xvfb.log").open("w")
            display_process = subprocess.Popen(
                [args.xvfb, "-displayfd", str(write_fd), "-screen", "0", "1280x800x24", "-nolisten", "tcp"],
                env=env, pass_fds=(write_fd,), stdout=xlog, stderr=subprocess.STDOUT)
            os.close(write_fd)
            try:
                ready, _, _ = select.select([read_fd], [], [], 15)
                if not ready:
                    raise RuntimeError("Xvfb did not announce a display")
                display = os.read(read_fd, 64).decode().strip()
            finally:
                os.close(read_fd)
            if not display.isdecimal():
                raise RuntimeError("Xvfb startup failed")
            env["DISPLAY"] = ":" + display
        command = [args.godot, "--path", str(project), "--audio-driver", "Dummy",
                   "--resolution", "960x600", "--fixed-fps", "20",
                   "--script", "res://tests/online/gameplay_motion_review.gd"]
        if args.metrics_only:
            command.append("--headless")
        else:
            command += ["--rendering-method", "gl_compatibility"]
        command += ["--", "--output-dir=" + str(output)]
        if args.metrics_only:
            command.append("--metrics-only")
        started = time.monotonic()
        with (output / "godot.log").open("w") as log:
            run = subprocess.run(command, cwd=project, env=env, stdout=log,
                                 stderr=subprocess.STDOUT, timeout=240)
        text = (output / "godot.log").read_text()
        errors = [line for line in text.splitlines()
                  if re.search(r"SCRIPT ERROR|^ERROR:|leaked|still in use|GL_INVALID", line)]
        report_path = output / "gameplay-motion-review.json"
        report = json.loads(report_path.read_text()) if report_path.exists() else {}
        report["native_run"] = {"exit_code": run.returncode,
            "seconds": round(time.monotonic() - started, 2), "errors": errors,
            "rendering": "headless metrics" if args.metrics_only else "native GL Compatibility / llvmpipe"}
        if run.returncode == 0 and not errors and report.get("passed") and report.get("captured"):
            movie = output / "gameplay-animation-review.mp4"
            encode = subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-framerate", str(report["fps"]),
                 "-i", str(output / "frames/%05d.jpg"), "-c:v", "libx264", "-crf", "21",
                 "-preset", "fast", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(movie)],
                capture_output=True, text=True, timeout=90)
            if encode.returncode:
                errors.append("Encoding failed: " + encode.stderr)
            else:
                report["video"] = {"file": movie.name, "bytes": movie.stat().st_size,
                    "sha256": hashlib.sha256(movie.read_bytes()).hexdigest()}
                shutil.rmtree(output / "frames")
        report_path.write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps({"passed": report.get("passed", False),
            "frames": report.get("frames", 0), "seconds": report["native_run"]["seconds"],
            "errors": errors, "video": report.get("video"), "report": str(report_path)}, indent=2))
        return 0 if run.returncode == 0 and not errors and report.get("passed") else 1
    finally:
        if display_process is not None:
            display_process.terminate()
            try:
                display_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                display_process.kill()
                display_process.wait()
        if xlog:
            xlog.close()
        shutil.rmtree(isolation, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
