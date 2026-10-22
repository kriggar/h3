#!/usr/bin/env python3
"""Format/gate regressions only: no Godot import, export, native launch, or ZIP."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import signal
import struct
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

import export_card_checkpoint as release
import package_native_v03 as packager
from native_export_probe import diagnostics


class ExportGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="draconia-export-parser-test-")
        self.root = Path(self.temporary.name)
        self.manifest = b'{"schemaVersion":4,"fixture":true}'
        self.scene_path = ".godot/imported/granary.glb-00000000000000000000000000000000.scn"
        self.scene = b"fixture scene bytes"
        self.source = "assets/models/towns/ashen_crown/granary.glb"
        self.bindings = {self.source: {"sourceSha256": "1" * 64, "sourceMd5": "2" * 32,
                                     "cache": {"path": self.scene_path,
                                               "sha256": hashlib.sha256(self.scene).hexdigest()}}}

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def fixture(self, extra: list[tuple[str, bytes]] | None = None,
                remap: str | None = None) -> Path:
        rows = [(release.MANIFEST, self.manifest),
                ("project.binary", (release.CHECKPOINT + "\0res://redesign.tscn").encode()),
                ("game/redesign/game_shell.gdc", b"compiled fixture"),
                ("redesign.tscn.remap", b'[remap]\npath="res://.godot/exported/entry.scn"\n'),
                (".godot/exported/entry.scn", b"fixture entry"),
                (self.source + ".import", ('[remap]\npath="res://' + (remap or self.scene_path) + '"\n').encode()),
                (self.scene_path, self.scene)] + (extra or [])
        data, directory = bytearray(), bytearray(struct.pack("<I", len(rows)))
        for name, contents in rows:
            encoded = name.encode()
            encoded += b"\0" * ((4 - len(encoded) % 4) % 4)
            directory.extend(struct.pack("<I", len(encoded)) + encoded)
            directory.extend(struct.pack("<QQ", len(data), len(contents)))
            directory.extend(hashlib.md5(contents).digest() + struct.pack("<I", 0))
            data.extend(contents)
        base = 104
        header = struct.pack("<4sIIIIIQQ", b"GDPC", 4, 4, 7, 2, 0, base, base + len(data))
        pack = header + bytes(base - len(header)) + bytes(data) + bytes(directory)
        executable = b"\x7fELF" + bytes(12) + pack + struct.pack("<Q4s", len(pack), b"GDPC")
        path = self.root / "fixture.x86_64"
        path.write_bytes(executable)
        return path

    def verify(self, path: Path, bindings: dict | None = None, manifest: bytes | None = None) -> dict:
        return release.verify_embedded_pack(path, project=self.root,
                    bindings=self.bindings if bindings is None else bindings,
                    expected_manifest_sha=hashlib.sha256(manifest or self.manifest).hexdigest())

    def test_valid_pack_hashes_every_member_and_binds_import(self) -> None:
        result = self.verify(self.fixture())
        self.assertEqual(result["pack"]["resourceCount"], 7)
        self.assertTrue(all(row["md5Verified"] and len(row["sha256"]) == 64 for row in result["files"]))
        self.assertEqual(result["sourceImportBindings"][0]["source"], self.source)

    def test_corrupted_member_is_rejected(self) -> None:
        path = self.fixture()
        data = bytearray(path.read_bytes())
        data[16 + 104] ^= 1
        path.write_bytes(data)
        with self.assertRaisesRegex(release.GateError, "digest mismatch"):
            self.verify(path)

    def test_duplicate_path_is_rejected(self) -> None:
        with self.assertRaisesRegex(release.GateError, "duplicated"):
            self.verify(self.fixture([(release.MANIFEST, self.manifest)]))

    def test_source_only_payload_is_rejected(self) -> None:
        with self.assertRaisesRegex(release.GateError, "Source-only"):
            self.verify(self.fixture([("assets/models/source/author.blend", b"not runtime")]))

    def test_missing_remap_target_is_rejected(self) -> None:
        with self.assertRaisesRegex(release.GateError, "remap is absent or stale"):
            self.verify(self.fixture(remap=".godot/imported/stale.scn"))

    def test_stale_cached_model_is_rejected(self) -> None:
        bindings = json.loads(json.dumps(self.bindings))
        bindings[self.source]["cache"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(release.GateError, "differs from the fresh cache"):
            self.verify(self.fixture(), bindings=bindings)

    def test_wrong_manifest_is_rejected(self) -> None:
        with self.assertRaisesRegex(release.GateError, "manifest is stale"):
            self.verify(self.fixture(), manifest=b"older manifest")

    def test_pack_path_traversal_is_rejected(self) -> None:
        with self.assertRaisesRegex(release.GateError, "Unsafe"):
            self.verify(self.fixture([("../outside", b"invalid")]))

    def glb(self, uri: str) -> tuple[Path, dict]:
        path = self.root / "assets/hero.glb"
        path.parent.mkdir(exist_ok=True)
        document = json.dumps({"asset": {"version": "2.0"}, "images": [{"uri": uri}]}).encode()
        document += b" " * ((4 - len(document) % 4) % 4)
        path.write_bytes(struct.pack("<4sII", b"glTF", 2, 20 + len(document))
                         + struct.pack("<II", len(document), 0x4E4F534A) + document)
        record = release.file_record(path, relative_to=self.root)
        return path, {record["path"]: {"bytes": record["bytes"], "sha256": record["sha256"]}}

    def test_external_texture_closure_is_bound(self) -> None:
        path, inventory = self.glb("cloth.png")
        texture = path.parent / "cloth.png"
        texture.write_bytes(b"fixture texture")
        record = release.file_record(texture, relative_to=self.root)
        inventory[record["path"]] = {"bytes": record["bytes"], "sha256": record["sha256"]}
        closure = release.glb_dependency_closure(self.root, inventory)
        self.assertEqual(closure["assets/hero.glb"][0]["sha256"], record["sha256"])

    def test_missing_external_texture_is_rejected(self) -> None:
        _, inventory = self.glb("omitted.png")
        with self.assertRaisesRegex(release.GateError, "omitted from runtime inventory"):
            release.glb_dependency_closure(self.root, inventory)

    def test_external_network_uri_is_rejected(self) -> None:
        _, inventory = self.glb("https://invalid.example/texture.png")
        with self.assertRaisesRegex(release.GateError, "Nonlocal"):
            release.glb_dependency_closure(self.root, inventory)

    def test_external_escape_is_rejected(self) -> None:
        _, inventory = self.glb("../../outside.png")
        with self.assertRaisesRegex(release.GateError, "escaped project"):
            release.glb_dependency_closure(self.root, inventory)

    def test_unknown_warning_and_shutdown_leak_block(self) -> None:
        _, blocking = diagnostics("WARNING: ObjectDB instances leaked at exit\nERROR: 2 resources still in use\n")
        self.assertEqual(len(blocking), 2)
        self.assertEqual(diagnostics("WARNING: unexplained warning")[1], ["WARNING: unexplained warning"])

    def test_only_known_virtual_vsync_warning_is_nonblocking(self) -> None:
        line = "WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported"
        self.assertEqual(diagnostics(line), ([line], []))

    def test_archive_label_preserves_default_and_accepts_checkpoint(self) -> None:
        self.assertEqual(packager.validate_archive_label(packager.DEFAULT_ARCHIVE_LABEL), "v0.3")
        label = packager.validate_archive_label("v0.3.1-card-reconstruction")
        self.assertIn("# Draconia 0.3.1-card-reconstruction — Windows package",
                      packager.platform_notice("Windows", False, label))
        self.assertIn("Windows runtime behavior has not been verified",
                      packager.platform_notice("Windows", False, label))

    def test_unsafe_archive_labels_are_rejected(self) -> None:
        for label in ("", "../outside", "x/y", "x\\y", "two words", "x\n", "v0..3", "name.", "x" * 81):
            with self.subTest(label=label), self.assertRaises(packager.PackageError):
                packager.validate_archive_label(label)

    def gate_fixture(self, failures=None) -> dict:
        paths = set(release.GATED_RUNTIME_CODE) | {release.ATLAS}
        paths.update(f"assets/models/towns/ashen_crown/{name}.glb" for name in release.EXPECTED_MODELS)
        sources = {}
        for relative in paths:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(("synthetic fixture " + relative).encode())
            sources["res://" + relative] = release.sha256(path)
        report = self.root / "evidence/report.json"
        report.parent.mkdir(exist_ok=True)
        report.write_text(json.dumps({"checks": 3, "failures": [] if failures is None else failures,
                                      "sourceHashes": sources}))
        log = report.parent / "native.log"
        log.write_text("OpenGL API 4.6 Compatibility - synthetic format fixture\n")
        return {"runtimeGate": {"passed": True, "checks": 3, "failures": 0, "exitCode": 0,
                "report": "evidence/report.json", "reportSha256": release.sha256(report),
                "log": "evidence/native.log", "logSha256": release.sha256(log)}}

    def test_gate_accepts_explicit_zero_count_or_empty_failure_array(self) -> None:
        for failures in (0, []):
            with self.subTest(failures=failures):
                result = release.validate_runtime_gate(self.root, self.gate_fixture(failures))
                self.assertEqual(result["checks"], 3)
                self.assertEqual(len(result["runtimeSourcesVerified"]), 16)

    def test_gate_rejects_changed_report_bytes(self) -> None:
        gate = self.gate_fixture()
        (self.root / "evidence/report.json").write_text("{}")
        with self.assertRaisesRegex(release.GateError, "report differs from its final SHA"):
            release.validate_runtime_gate(self.root, gate)

    def test_gate_rejects_runtime_source_changed_after_native_test(self) -> None:
        gate = self.gate_fixture()
        (self.root / release.GATED_RUNTIME_CODE[0]).write_text("changed runtime")
        with self.assertRaisesRegex(release.GateError, "differs from the completed native gate"):
            release.validate_runtime_gate(self.root, gate)

    def test_gate_rejects_missing_failure_result(self) -> None:
        gate = self.gate_fixture()
        del gate["runtimeGate"]["failures"]
        with self.assertRaisesRegex(release.GateError, "explicit zero failure count"):
            release.validate_runtime_gate(self.root, gate)

    def test_gate_rejects_native_shutdown_warning(self) -> None:
        gate = self.gate_fixture()
        log = self.root / "evidence/native.log"
        with log.open("a") as stream:
            stream.write("WARNING: ObjectDB instances leaked at exit\n")
        gate["runtimeGate"]["logSha256"] = release.sha256(log)
        with self.assertRaisesRegex(release.GateError, "blocking diagnostics"):
            release.validate_runtime_gate(self.root, gate)

    def test_stage_cancellation_terminates_and_waits_for_owned_child(self) -> None:
        timer = threading.Timer(0.3, lambda: os.kill(os.getpid(), signal.SIGINT))
        timer.start()
        try:
            record = release.run_owned_process([sys.executable, "-c", "import time; time.sleep(30)"],
                        cwd=self.root, env=os.environ.copy(), log=self.root / "cancel.log", timeout=5)
        finally:
            timer.cancel()
            timer.join()
        self.assertTrue(record["cancelled"] and record["forcedTermination"])
        self.assertEqual(record["exitCode"], -signal.SIGTERM)
        with self.assertRaises(ChildProcessError):
            os.waitpid(record["processId"], os.WNOHANG)

    def test_stage_timeout_kills_an_unresponsive_owned_child(self) -> None:
        child_code = "import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); print('READY',flush=True); time.sleep(30)"
        log = self.root / "timeout.log"
        record = release.run_owned_process([sys.executable, "-c", child_code], cwd=self.root,
                    env=os.environ.copy(), log=log, timeout=1, stop_timeout=0.1)
        self.assertIn("READY", log.read_text())
        self.assertTrue(record["forcedTermination"] and record["forcedKill"])
        self.assertEqual(record["exitCode"], -signal.SIGKILL)
        with self.assertRaises(ChildProcessError):
            os.waitpid(record["processId"], os.WNOHANG)

    def test_stage_spawn_failure_has_no_unowned_child(self) -> None:
        with patch.object(release.subprocess, "Popen", side_effect=OSError("synthetic spawn failure")):
            record = release.run_owned_process(["fixture"], cwd=self.root, env=os.environ.copy(),
                        log=self.root / "spawn.log", timeout=1)
        self.assertEqual(record["exceptionType"], "OSError")
        self.assertIsNone(record["exitCode"])
        self.assertNotIn("forcedTermination", record)

    def test_normal_stage_exit_needs_no_forced_cleanup(self) -> None:
        log = self.root / "normal.log"
        record = release.run_owned_process([sys.executable, "-c", "print('owned child normal exit')"],
                    cwd=self.root, env=os.environ.copy(), log=log, timeout=5)
        self.assertEqual(record["exitCode"], 0)
        self.assertNotIn("failure", record)
        self.assertNotIn("forcedTermination", record)
        self.assertIn("owned child normal exit", log.read_text())
        with self.assertRaises(ChildProcessError):
            os.waitpid(record["processId"], os.WNOHANG)


if __name__ == "__main__":
    unittest.main(verbosity=2)
