# Third-person realm verification

These tests exercise the new `game/online` runtime. Historical strategy-game
tests do not establish that this replacement works.

## Authoritative rules

Run with a Godot 4 executable from the project directory:

```bash
godot --headless --path . --script tests/online/test_realm.gd
```

The suite creates in-memory realms and does not touch a player's save files.
It checks malformed and non-finite input, bounded speed, stale input expiry,
building/world collision, physical jump/landing, delayed and once-only damage,
cooldowns and resource costs, real combat actions, all three quest chapters,
quest reward replay rejection, ownership and duplicate loot claims, equipment
and attributes, merchant proximity and atomic transactions, profile sanitizing
and JSON roundtrips, fixed boss telegraphs, contributor rewards, disconnected
contributors, death/respawn, and bounded plain-text realm chat.

An optional `-- --report=/absolute/path/report.json` writes a structured result.

## Independent-process network test

```bash
python tools/test_online_network.py --godot /absolute/path/to/godot --output-dir /tmp/draconia-network-test
```

This starts actual native Godot processes using the production `Session` and
`Realm` over loopback ENet/UDP. Each client has independent, temporary user data.
It exercises client movement, an authoritative combat action, confirmed death,
two claims for one loot pile, forged unowned equipment rejection, late join,
same-name profile isolation, bounded shared chat, peer departure, host loss,
server restart, and restoration using the server-issued reconnect key.

The trusted server fixture positions the player near an enemy and adjusts the
enemy's health to shorten setup. These are explicit fixture changes in
`network_worker.gd`; there are no debug/admin RPCs or test hooks in the production
runtime. Resulting movement, abilities, rewards, state replication, and saves
still flow through production code. The full rules suite separately exercises
ordinary enemy and boss health and complete quest rewards.

The runner writes per-process logs, individual reports, and an aggregate
`network-report.json`. It also checks nonzero exits and native script/runtime
errors, rather than trusting a success string. Test saves and private reconnect
keys stay in isolated temporary user data and are not included in reports.

This verifies private-realm behavior on localhost. It does not establish WAN
connectivity through arbitrary routers, packet-loss/latency tolerance, public
authentication, or capacity beyond the explicitly tested concurrent clients.
The runtime currently allows four adventurers, and the integration scenario
tests two concurrent remote clients.

## Actual shipped host/join scene

```bash
python tools/test_online_entry.py --godot /absolute/path/to/godot --output-dir /tmp/draconia-entry-test --headless-host
```

Both processes load the real `online.tscn` with its main menu, Session, world,
avatars, and HUD. The test invokes the actual host/join paths and waits for the
first shared snapshot. It checks real replicated movement, both remote names,
party rows, chat through HUD-to-main-to-Session, host loss, lobby recovery, and
starting solo afterward. It does not insert peers, replace snapshots, or edit
the server's state. The successful release run has 50 checks.

Without `--headless-host`, the host uses a native window and attempts a real
two-player capture. On Linux without a display, pass `--xvfb` and, if necessary,
`--xvfb-lib-path`. The release's attempted native-host run timed out amid severe
llvmpipe stalls; the headless full-scene result must not be represented as a
rendered multiplayer performance test.

## World and animation contract

```bash
godot --headless --path . --script res://tests/online/world_scene_tests.gd
```

This suite prints a JSON receipt after checking the retained model, source
motions, timing/blending, weapon state, interactions, shared collisions, and
camera obstruction. It does not replace native visual inspection.

## Native UI and full-scene acceptance

```bash
python tools/ui_run_probe.py --godot /absolute/path/to/godot --output-dir /tmp/draconia-ui-test
python tools/run_native_review.py --godot /absolute/path/to/godot --output-dir /tmp/draconia-native-test
```

Run these with a working native display. On headless Linux, provide an Xvfb
executable with `--xvfb`. The UI runner's optional library argument is
`--xvfb-library-dir`; the full-scene runner uses `--xvfb-lib-path`.
Each runner isolates user data and captures its actual Godot viewport.

The UI fixture covers layout, real pointer dispatch, focus recovery, party rows,
progression controls, and death controls. The full-scene acceptance loads the
shipped entry and exercises movement, panels, quests, spell/roll weapon states,
chat, saving/re-entry, death while paused, and respawning. Some trusted position
and death-state fixtures shorten UI setup; separate rules and transport suites
cover authoritative invariants. This is scripted acceptance, not a long manual
playthrough or target-hardware benchmark.

Release receipts and actual screenshots are in
`docs/online/RELEASE_REVIEW.md` and its `verification/` and `screenshots/` folders.

## Normal close and audio release

```bash
godot --headless --path . --script res://tests/online/shutdown_probe.gd -- --solo --shutdown-route=window --report=/tmp/window-quit.json
godot --headless --path . --script res://tests/online/shutdown_probe.gd -- --solo --shutdown-route=menu --report=/tmp/menu-quit.json
```

Use separate temporary application user-data directories for these commands.
They load the shipped scene and invoke its actual window-close notification or
Save & Quit button. The harness does not quit on a successful run: production
must save, release the active audio, and finish engine shutdown. Check both the
JSON assertions and the process exit/log for leaked resources. The combined
release run has 41 checks and no warnings or leaked audio objects.

## Environment photograph inspection

```bash
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --resolution 1440x900 --script res://tests/online/material_probe.gd -- --output-dir=/tmp/draconia-material-review
```

This requires a native display or Xvfb; it is not a headless test. It instantiates
the actual world, captures town/woodland views and four material closeups, and
writes measured texture hashes, dimensions, mipmaps, bindings, authored scales,
collider count, and the preserved Mara hash. It intentionally hides the HUD.
The release report's `visual_review` and `native_capture` annotations were added
after inspecting the actual images and process log; they are not automated
assertions produced by this harness.
