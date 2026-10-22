#!/usr/bin/env python3
"""Verify the exported game's own Linux entry and inspected Menu/Save & Quit.

This helper does not run at import. The release runner calls run_probe only
after export. It never injects a script, a project path, a PCK override, or a
forced quit timer. A reviewer supplies button coordinates after each actual
window capture; no coordinates from an older UI are assumed.
"""
from __future__ import annotations

import ctypes
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import time
from typing import Callable


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def save_json(path: Path, value: dict) -> None:
    temporary = path.with_name(path.name + ".writing")
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def diagnostics(text: str) -> tuple[list[str], list[str]]:
    expression = (r"(^\s*(SCRIPT ERROR|ERROR|WARNING):)|leaked|still in use|"
                  r"RID allocations|GL_INVALID|shader compilation failed|audio.*drain.*timeout")
    lines = [line.strip() for line in text.splitlines() if re.search(expression, line, re.I)]
    blocking = [line for line in lines
                if not ("Could not set V-Sync mode" in line and "not supported" in line)]
    return lines, blocking


def x11_window_for_pid(pid: int, display_name: str) -> int | None:
    """Select only a window that advertises the launched process's own PID."""
    x = ctypes.CDLL("libX11.so.6")
    ulong, uint, void = ctypes.c_ulong, ctypes.c_uint, ctypes.c_void_p
    x.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x.XOpenDisplay.restype = void
    x.XDefaultRootWindow.argtypes = [void]
    x.XDefaultRootWindow.restype = ulong
    x.XInternAtom.argtypes = [void, ctypes.c_char_p, ctypes.c_int]
    x.XInternAtom.restype = ulong
    x.XQueryTree.argtypes = [void, ulong, ctypes.POINTER(ulong), ctypes.POINTER(ulong),
                            ctypes.POINTER(ctypes.POINTER(ulong)), ctypes.POINTER(uint)]
    x.XQueryTree.restype = ctypes.c_int
    x.XGetWindowProperty.argtypes = [void, ulong, ulong, ctypes.c_long, ctypes.c_long,
                                    ctypes.c_int, ulong, ctypes.POINTER(ulong),
                                    ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ulong),
                                    ctypes.POINTER(ulong),
                                    ctypes.POINTER(ctypes.POINTER(ctypes.c_ubyte))]
    x.XGetWindowProperty.restype = ctypes.c_int
    x.XFree.argtypes = [void]
    x.XCloseDisplay.argtypes = [void]
    display = x.XOpenDisplay(display_name.encode())
    if not display:
        return None
    try:
        atom = x.XInternAtom(display, b"_NET_WM_PID", 0)
        queue = [x.XDefaultRootWindow(display)]
        visited = 0
        while queue and visited < 2000:
            window = queue.pop(0)
            visited += 1
            actual, count, remaining = ulong(), ulong(), ulong()
            fmt = ctypes.c_int()
            data = ctypes.POINTER(ctypes.c_ubyte)()
            result = x.XGetWindowProperty(display, window, atom, 0, 1, 0, 0,
                                          ctypes.byref(actual), ctypes.byref(fmt),
                                          ctypes.byref(count), ctypes.byref(remaining),
                                          ctypes.byref(data))
            found = False
            if result == 0 and data:
                found = (fmt.value == 32 and count.value == 1
                         and ctypes.cast(data, ctypes.POINTER(ulong))[0] == pid)
                x.XFree(data)
            if found:
                return int(window)
            root, parent, child_count = ulong(), ulong(), uint()
            children = ctypes.POINTER(ulong)()
            if x.XQueryTree(display, window, ctypes.byref(root), ctypes.byref(parent),
                            ctypes.byref(children), ctypes.byref(child_count)) and children:
                queue.extend(int(children[index]) for index in range(child_count.value))
                x.XFree(children)
    finally:
        x.XCloseDisplay(display)
    return None


def x11_click(window: int, position: list[int], display_name: str) -> None:
    x = ctypes.CDLL("libX11.so.6")
    void, ulong = ctypes.c_void_p, ctypes.c_ulong

    class Button(ctypes.Structure):
        _fields_ = [("type", ctypes.c_int), ("serial", ulong), ("send_event", ctypes.c_int),
                    ("display", void), ("window", ulong), ("root", ulong), ("subwindow", ulong),
                    ("time", ulong), ("x", ctypes.c_int), ("y", ctypes.c_int),
                    ("x_root", ctypes.c_int), ("y_root", ctypes.c_int),
                    ("state", ctypes.c_uint), ("button", ctypes.c_uint),
                    ("same_screen", ctypes.c_int)]

    class Event(ctypes.Union):
        _fields_ = [("type", ctypes.c_int), ("xbutton", Button), ("pad", ctypes.c_long * 24)]

    x.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x.XOpenDisplay.restype = void
    x.XDefaultRootWindow.argtypes = [void]
    x.XDefaultRootWindow.restype = ulong
    x.XTranslateCoordinates.argtypes = [void, ulong, ulong, ctypes.c_int, ctypes.c_int,
                                       ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int),
                                       ctypes.POINTER(ulong)]
    x.XTranslateCoordinates.restype = ctypes.c_int
    x.XSendEvent.argtypes = [void, ulong, ctypes.c_int, ctypes.c_long, ctypes.POINTER(Event)]
    x.XSendEvent.restype = ctypes.c_int
    x.XWarpPointer.argtypes = [void, ulong, ulong, ctypes.c_int, ctypes.c_int,
                              ctypes.c_uint, ctypes.c_uint, ctypes.c_int, ctypes.c_int]
    x.XSetInputFocus.argtypes = [void, ulong, ctypes.c_int, ulong]
    x.XSync.argtypes = [void, ctypes.c_int]
    x.XCloseDisplay.argtypes = [void]
    display = x.XOpenDisplay(display_name.encode())
    if not display:
        raise RuntimeError("X11 display is unavailable for the inspected button click")
    try:
        root = x.XDefaultRootWindow(display)
        root_x, root_y, child = ctypes.c_int(), ctypes.c_int(), ulong()
        if not x.XTranslateCoordinates(display, window, root, *position,
                                       ctypes.byref(root_x), ctypes.byref(root_y),
                                       ctypes.byref(child)):
            raise RuntimeError("Own-window coordinate lookup failed")
        x.XSetInputFocus(display, window, 2, 0)
        x.XWarpPointer(display, 0, window, 0, 0, 0, 0, *position)
        x.XSync(display, 0)
        event = Event()
        button = event.xbutton
        button.send_event, button.display, button.window = 1, display, window
        button.root, button.x, button.y = root, *position
        button.x_root, button.y_root, button.button, button.same_screen = root_x.value, root_y.value, 1, 1
        for kind, mask, state in [(4, 1 << 2, 0), (5, 1 << 3, 1 << 8)]:
            button.type, button.state = kind, state
            if not x.XSendEvent(display, window, 1, mask, ctypes.byref(event)):
                raise RuntimeError("Native mouse-button delivery failed")
            x.XSync(display, 0)
            time.sleep(0.1)
    finally:
        x.XCloseDisplay(display)


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        head = stream.read(24)
    if len(head) != 24 or head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        raise RuntimeError("Native capture is not a complete PNG header")
    return struct.unpack(">II", head[16:24])


def capture_window(window: int, path: Path, env: dict) -> dict:
    result = subprocess.run(["/usr/bin/import", "-window", str(window), str(path)],
                            env=env, capture_output=True, timeout=20)
    if result.returncode or not path.is_file():
        raise RuntimeError("Native own-window capture failed: "
                           + result.stderr.decode(errors="replace")[:500])
    width, height = png_dimensions(path)
    if width < 640 or height < 400:
        raise RuntimeError(f"Unexpected native game capture dimensions: {width}x{height}")
    return {"path": str(path), "sha256": sha256(path), "bytes": path.stat().st_size,
            "width": width, "height": height, "windowId": window}


def run_probe(binary: Path, evidence: Path, *, display: str = ":97", timeout: int = 900,
              on_update: Callable[[dict], None] | None = None) -> dict:
    """Run one cold native process and retain successes and failures separately.

    Write control.json atomically with sequential sequence numbers and actions:
      {"sequence":1,"action":"open_menu","position":[x,y],
       "observedCaptureSha256":"<sha from actual startup capture>"}
      {"sequence":2,"action":"save_quit","position":[x,y],
       "observedCaptureSha256":"<sha from actual menu capture>"}
    An action "capture" with the next sequence number refreshes the current view.
    """
    binary, evidence = binary.resolve(), evidence.resolve()
    if not binary.is_file() or binary.is_symlink():
        raise RuntimeError("The native probe requires a regular exported executable")
    evidence.mkdir(parents=True, exist_ok=True)
    log_path = evidence / "linux-native-menu-quit.log"
    result_path = evidence / "linux-native-menu-quit.json"
    if log_path.exists() or result_path.exists():
        raise RuntimeError("Native probe evidence exists; use a new attempt directory")
    work = Path(tempfile.mkdtemp(prefix="draconia-card-native-"))
    env = os.environ.copy()
    env.update(DISPLAY=display, LIBGL_ALWAYS_SOFTWARE="1", GODOT_SILENCE_ROOT_WARNING="1")
    for name, key in [("data", "XDG_DATA_HOME"), ("config", "XDG_CONFIG_HOME"),
                      ("cache", "XDG_CACHE_HOME")]:
        directory = work / name
        directory.mkdir()
        env[key] = str(directory)
    control = work / "control.json"
    command = [str(binary), "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
               "--display-driver", "x11", "--windowed", "--resolution", "1440x900",
               "--position", "0,0", "--verbose"]
    record = {
        "mode": "native", "command": command, "workingDirectory": str(work),
        "binarySha256": sha256(binary), "freshUserData": True, "coldShaderCache": True,
        "controlFile": str(control), "startedUtc": utc(), "captures": [], "events": [],
        "environment": {key: env[key] for key in ["DISPLAY", "LIBGL_ALWAYS_SOFTWARE",
                       "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"]},
        "userData": env["XDG_DATA_HOME"], "log": str(log_path), "passed": False,
        "exitMechanism": "Inspected GUI MENU, then inspected SAVE & QUIT; no forced quit timer",
        "limits": ["Startup/render and normal menu exit only; no complete playthrough.",
                   "Dummy audio does not verify audible sound; software rendering does not verify target-GPU performance.",
                   "Window-manager close is not certified by this test; the earlier failing attempt remains historical evidence."],
    }

    def publish() -> None:
        save_json(result_path, record)
        if on_update:
            on_update(record)

    started = time.monotonic()
    process: subprocess.Popen | None = None
    phase, sequence, capture_number = "starting", 0, 0
    next_capture = 20.0
    captured_phase = ""
    publish()
    print("NATIVE_CONTROL", control, flush=True)
    try:
        with log_path.open("xb") as log:
            process = subprocess.Popen(command, cwd=work, env=env, stdout=log, stderr=subprocess.STDOUT)
            record["processId"] = process.pid
            print("NATIVE_PROCESS", process.pid, flush=True)
            while process.poll() is None:
                elapsed = time.monotonic() - started
                if elapsed > timeout:
                    record["timeoutSeconds"] = timeout
                    raise RuntimeError("Native process did not finish the inspected menu flow within the timeout")
                window = x11_window_for_pid(process.pid, display) if elapsed >= 5 else None
                if elapsed >= next_capture and window:
                    capture_number += 1
                    label = "startup" if phase == "starting" else phase
                    item = capture_window(window, evidence / f"linux-native-{capture_number:02}-{label}.png", env)
                    item.update(seconds=round(elapsed, 3), processId=process.pid, phase=label)
                    record["captures"].append(item)
                    captured_phase = label
                    if phase == "starting":
                        phase = "awaiting_menu_coordinates"
                    record["phase"] = phase
                    print("NATIVE_CAPTURE", json.dumps(item), flush=True)
                    print("AWAIT_INSPECTED_COORDINATES", phase, flush=True)
                    next_capture = float("inf")
                    publish()
                if control.exists():
                    try:
                        instruction = json.loads(control.read_text(encoding="utf-8"))
                    except json.JSONDecodeError:
                        # A non-atomic external write cannot trigger a partial click.
                        time.sleep(0.2)
                        continue
                    request_sequence = instruction.get("sequence")
                    if type(request_sequence) is not int or request_sequence < 1:
                        raise RuntimeError("Native control requires a positive integer sequence")
                    if request_sequence > sequence:
                        if request_sequence != sequence + 1:
                            raise RuntimeError("Native control sequence skipped an event")
                        action = instruction.get("action")
                        if action == "capture":
                            next_capture = elapsed
                        elif action in ("open_menu", "save_quit"):
                            expected_phase = "awaiting_menu_coordinates" if action == "open_menu" else "awaiting_quit_coordinates"
                            if phase != expected_phase or not record["captures"]:
                                raise RuntimeError("The requested button has no captured, current UI phase")
                            capture = record["captures"][-1]
                            if (instruction.get("observedCaptureSha256") != capture["sha256"]
                                    or sha256(Path(capture["path"])) != capture["sha256"]):
                                raise RuntimeError("Button coordinates must cite the current actual native capture SHA-256")
                            if action == "save_quit" and captured_phase != "awaiting_quit_coordinates":
                                raise RuntimeError("SAVE & QUIT requires an actual captured menu after opening it")
                            position = instruction.get("position")
                            if (not isinstance(position, list) or len(position) != 2
                                    or any(type(value) is not int for value in position)
                                    or not 0 <= position[0] < capture["width"]
                                    or not 0 <= position[1] < capture["height"]):
                                raise RuntimeError("Button coordinates lie outside the inspected window capture")
                            if not window or window != capture["windowId"]:
                                raise RuntimeError("The exported process window changed after inspection")
                            x11_click(window, position, display)
                            record["events"].append({"action": action, "sequence": request_sequence,
                                "seconds": round(elapsed, 3), "windowId": window, "processId": process.pid,
                                "localPosition": position, "observedCaptureSha256": capture["sha256"]})
                            if action == "open_menu":
                                phase = "awaiting_quit_coordinates"
                                next_capture = elapsed + 2
                            else:
                                phase = "awaiting_normal_exit"
                                record["menuQuitClicked"] = True
                                record["quitClickSeconds"] = round(elapsed, 3)
                                next_capture = elapsed + 15
                            print("NATIVE_CLICK", action, position, flush=True)
                        else:
                            raise RuntimeError("Native control permits only capture, open_menu, and save_quit")
                        sequence = request_sequence
                        record["phase"] = phase
                        publish()
                time.sleep(0.2)
            record["exitCode"] = process.wait()
    except BaseException as error:
        record["failure"] = str(error) or type(error).__name__
        if process is not None and process.poll() is None:
            record["forcedTermination"] = True
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                record["forcedKill"] = True
                process.kill()
                process.wait(timeout=10)
        record["exitCode"] = process.returncode if process is not None else None
    finally:
        record["durationSeconds"] = round(time.monotonic() - started, 3)
        record["completedUtc"] = utc()
        if log_path.exists():
            record["logSha256"] = sha256(log_path)
            record["logBytes"] = log_path.stat().st_size
            text = log_path.read_text(encoding="utf-8", errors="replace")
            record["diagnostics"], record["blockingDiagnostics"] = diagnostics(text)
            record["renderBackendPresent"] = bool(re.search(r"OpenGL API .*Compatibility|Vulkan .*Using Device", text))
        else:
            record["blockingDiagnostics"] = ["No native process log was created"]
            record["renderBackendPresent"] = False
        record["binaryUnchanged"] = binary.is_file() and sha256(binary) == record["binarySha256"]
        saves = list((work / "data").rglob("draconia-action-autosave.json"))
        record["saveArtifacts"] = []
        if len(saves) == 1:
            try:
                saved = json.loads(saves[0].read_text(encoding="utf-8"))
                if not isinstance(saved, dict):
                    raise ValueError("The isolated autosave is not a JSON object")
                target = evidence / "linux-native-menu-autosave.json"
                shutil.copyfile(saves[0], target)
                record["saveArtifacts"].append({"path": str(target), "bytes": target.stat().st_size,
                    "sha256": sha256(target), "schema": saved.get("schema"),
                    "nonemptyRealm": bool(saved.get("realm")), "isolatedSource": str(saves[0])})
            except (OSError, ValueError, TypeError) as error:
                record["saveError"] = str(error)
        else:
            record["saveError"] = f"Expected one isolated autosave, found {len(saves)}"
        record["passed"] = bool(record.get("exitCode") == 0 and record.get("menuQuitClicked")
            and record["binaryUnchanged"] and record["renderBackendPresent"]
            and not record["blockingDiagnostics"] and not record.get("failure")
            and not record.get("forcedTermination") and len(record["saveArtifacts"]) == 1
            and record["saveArtifacts"][0]["schema"] == "draconia-native-1"
            and record["saveArtifacts"][0]["nonemptyRealm"])
        if record.get("quitClickSeconds") is not None:
            record["shutdownAfterQuitSeconds"] = round(record["durationSeconds"] - record["quitClickSeconds"], 3)
        (evidence / "linux-native-menu-quit.exit-code").write_text(str(record.get("exitCode")) + "\n")
        publish()
        print("NATIVE_PROBE_FINISHED", record["passed"], record.get("exitCode"), flush=True)
    return record
