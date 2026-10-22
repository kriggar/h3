# Painted-card reconstruction export procedure

This procedure targets **0.3.1-card-reconstruction**. It does not change the
game, the painted atlas, the model authoring sources, the earlier native builds,
or the immutable Blender workshop archives. The default runner command only
reads the project. The final runtime renderer must have exited and the release
owner must supply the accepted integration record's SHA-256 before freezing.

## Plan, freeze, and execute

Run from the editable project's root:

```sh
python3 tools/export_card_checkpoint.py plan
```

After the final native construction, hover, rest, purchase, and save/reload gate
has been recorded in `docs/verification-logs/card-reconstruction/runtime-integration.json`:

```sh
python3 tools/export_card_checkpoint.py freeze \
  --integration-sha256 FINAL_INTEGRATION_SHA256 \
  --output /absolute/new/runtime-export-freeze.json
```

The integration record retains `schemaVersion: 1`,
`checkpoint: "0.3.1-card-reconstruction"`, `runtimePromoted: true`, and
`productionAccepted: false`. Its final gate has the following fields; paths
refer to the actual successful attempt and are not tied to an attempt number:

```json
{
  "runtimeGate": {
    "status": "passed_actual_native_construction_hover_save_reload",
    "passed": true,
    "checks": 1,
    "failures": 0,
    "exitCode": 0,
    "report": "docs/verification-logs/card-reconstruction/ACTUAL_SUCCESSFUL_ATTEMPT/report.json",
    "reportSha256": "ACTUAL_REPORT_SHA256",
    "log": "docs/verification-logs/card-reconstruction/ACTUAL_SUCCESSFUL_ATTEMPT/native.log",
    "logSha256": "ACTUAL_LOG_SHA256"
  }
}
```

`checks: 1` is an illustrative placeholder: use the actual count in the linked
report. That report must have the same `checks`, explicit zero failures (integer
`0` or an empty array), and `sourceHashes` mapping `res://` paths to SHA-256. The
runner verifies the seven relevant runtime scripts, all eight model files, and
the painted atlas against that mapping. The completed native log must contain a
renderer record and no blocking diagnostics. The final integration SHA is
provided separately by the release owner; the record is never hashed through
itself, and old partial/failed reports cannot substitute for the successful one.

The freeze is an identity snapshot, not a native acceptance claim. It retains
the exact new runtime asset manifest, original atlas, all eight reviewed model
hashes, complete gameplay/runtime asset inventory, the root README/license/credits,
`.uid` and `.import` source settings, GLB external image/buffer dependencies,
engine bytes, and runner source hashes. Authoring directories and caches are excluded from the runtime source
inventory. The optional art-source archives preserve the authoring inputs.

Only after the release owner's handoff, use the returned freeze hash:

```sh
env DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 \
python3 tools/export_card_checkpoint.py execute \
  --freeze /absolute/new/runtime-export-freeze.json \
  --freeze-sha256 REVIEWED_FREEZE_SHA256 \
  --build-root /workspace/scratch/06ef9dc6bbe2/voievod/builds/v0.3-card-reconstruction \
  --evidence /workspace/scratch/06ef9dc6bbe2/voievod/docs/verification-logs/native-v031-card-reconstruction-attempt01
```

The runner refuses existing build/evidence directories. A failed attempt stays
intact; use a distinct attempt path for a later retry. It imports once, exports
Linux and Windows sequentially, then launches the actual Linux executable with
isolated user data and a fresh shader cache. No script/project/PCK override or
forced quit timer is passed to the game. Source/import settings must remain
identical through the process. Earlier build files are hashed before and after.
Each import/export process is explicitly owned through normal exit, timeout,
or cancellation. A failed stage is terminated and waited for, with a kill only
after a bounded unsuccessful termination wait; its failure and raw log remain.

## Inspect the real menu before clicking

The process prints a control-file path and saves a PNG of its own PID-tagged X11
window. Inspect that image and ask the release owner for button coordinates if
the current layout is unclear. Write the following JSON **atomically** to the
printed control path, using the actual capture hash and observed MENU position:

```json
{"sequence":1,"action":"open_menu","position":[1380,48],"observedCaptureSha256":"ACTUAL_STARTUP_CAPTURE_SHA256"}
```

The position above illustrates the schema; it is **not an approved coordinate**.
After the runner captures the opened menu, inspect it and send the observed
SAVE & QUIT position, bound to that new capture:

```json
{"sequence":2,"action":"save_quit","position":[0,0],"observedCaptureSha256":"ACTUAL_MENU_CAPTURE_SHA256"}
```

The `[0,0]` example is a placeholder. A sequential `{"sequence":N,"action":"capture"}`
request refreshes the current screenshot when necessary. Old capture hashes,
out-of-window coordinates, skipped sequence numbers, and unexpected action
phases are rejected. Inputs target only the newly launched executable's window.

Acceptance requires a clean normal exit through this flow, the actual native
renderer log, unchanged binary/source bytes, and one valid isolated autosave.
Timeout, forced termination, a script/shader/resource leak, or an unexplained
warning fails the attempt. The known unsupported V-Sync warning from the virtual
display is retained and specifically classified as nonblocking.

## Export resource evidence

Each embedded PCK is parsed from the executable footer. Every member gets a
computed MD5 compared with its directory entry and a SHA-256. The verifier checks
path uniqueness, file bounds, source-only exclusions, application version/entry,
runtime manifest bytes, and remap targets. For imported GLBs, their external
images, and the painted atlas, the fresh import's source MD5 must match the source
file, and the PCK's imported resource bytes must match that fresh cache exactly.
This binds the imported model, rather than merely checking a familiar filename.

The attempt directory retains commands, environments, durations, logs, source
snapshots, PCK member inventories, captures, and the copied autosave. `exports.json`
matches the evidence schema consumed by `tools/package_native_v03.py`:

```sh
python3 tools/package_native_v03.py \
  --archive-label v0.3.1-card-reconstruction \
  --build-root /workspace/scratch/06ef9dc6bbe2/voievod/builds/v0.3-card-reconstruction \
  --linux-evidence /absolute/new/native-v031-card-reconstruction-attempt01/exports.json \
  --output /absolute/deliverables/0.3.1-card-reconstruction
```

That command is still a packaging plan. The release owner separately authorizes
`--build --linux-verified` after reviewing the successful actual-binary evidence.
The optional archive label produces distinct filenames and internal roots:
`Draconia-Linux-v0.3.1-card-reconstruction.zip` and
`Draconia-Windows-v0.3.1-card-reconstruction.zip`. Omitting the option retains
the packager's original v0.3 names. Use a new output directory for this checkpoint.

## Verification limits

This verifies a development checkpoint's startup, renderer, exact resource
packaging, and normal menu exit. It does not certify a full campaign, sound
(the driver is Dummy), target-GPU performance (the renderer is software Mesa),
every Linux distribution, Windows runtime behavior, production art, or the old
window-manager close path. Windows remains explicitly cross-exported and untested.

Pure-Python parser/gate checks can be run independently while Godot is busy:

```sh
python3 tools/test_export_card_checkpoint.py
```

Those synthetic-format regressions exercise corruption, stale model/manifest,
unsafe path, missing texture, and shutdown diagnostic rejection. They are not
substitutes for the actual exported-binary run.
