# Heroes III investigation — evidence and limits

Prepared 22 October 2026 for the DRACONIA project.

## Result and scope

**REA was installed and its native Ghidra backend was used to statically inspect an original Heroes III demo executable and the user-supplied full `Heroes3.exe`.** The demo's original resource archives and map header were also parsed. Four selected procedure bodies from the full executable and two demo table-loading procedures were inspected. This is a bounded reverse-engineering investigation, not a full decompilation of Heroes III, a recovered original source tree, or proof of exact behavioral fidelity.

The original programs were not executed as part of this investigation. REA imported the binaries into ephemeral analysis databases without changing their source bytes. DRACONIA uses independently written Godot rules and separately licensed/generated artwork; the original executables, extracted tables and proprietary artwork are not game dependencies.

Evidence categories throughout this document are deliberately separated:

- **Observed:** bytes, hashes, archive fields, disassembly, references, and provider-generated analysis records actually examined.
- **Interpretation:** a likely meaning of those observations, identified as a candidate where types or call semantics remain unresolved.
- **Reference implementation:** behavior found in public VCMI source. It is useful context and is not evidence that the original executable has identical internals.

## 1. Installed analysis tools

The local installation record reports REA **6.7.0**, Ghidra **12.1.4**, and Temurin JDK **21.0.12.1+1**. The checked-out REA repository is [morluto/rea](https://github.com/morluto/rea), commit `8413ec08f732b5ef4ecaeee1c4b9bfe8924a7e9d`. The scoped doctor passed **9 selected checks**. A synthetic native test function was successfully decompiled before any original-game conclusions were drawn.

Local installation receipt: `analysis-tools/verification/installation-summary.json`; detailed checks: `doctor.json` and `smoke-decompile.json` in the same directory. The launch wrapper is `analysis-tools/rea`. The analysis session client and tool catalog are `research/rea-session.mjs` and `research/rea-evidence/tool-catalog.json` in the investigation workspace.

The initial synthetic smoke test only established that the native pipeline worked. The subsequent original-game records below establish that actual Heroes III targets were opened and inspected. Ghidra's completed auto-analysis and its procedure inventory do not mean every function was semantically understood.

## 2. Exact target identities

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Uploaded `Heroes3.exe` | 2,732,032 | `210939b92cdbf3bc0331ac0c9a5d52e814bfdb8142df500f8360f50eea880f15` |
| Original demo executable | 2,068,480 | `fd9e66162d6632abdcfa686188bde15a1fd2a0fba8324da92a25be6cbaf754e3` |
| Uploaded `HD_Launcher.exe` | 302,592 | `9fcd3fa166047d5944358e07cf993402837cc6fd8c3083e9ca7c6e322504d74c` |
| Demo `Data/H3BITMAP.LOD` | 22,712,791 | `1fbe015219c5b2a74bba1f35ef55a52aaaa2b29970b888dac9c537a11df521de` |
| Demo `Data/H3SPRITE.LOD` | 46,999,681 | `3661268945c002ed5120ed050259ff78227e9f1e42fe06f477adfed3c0b4c21f` |
| Demo `Maps/H3demo.h3m` | 10,011 | `3dcf2ca27e4317456022d3d64eafdbe4a2d677b9ce6fded5b577045dc577fa49` |

Both game executables were identified as native x86 PE files. The uploaded full executable contains UTF-16LE text identifying **“Heroes of Might and Magic III Complete”** at file offset `0x29595e` and **“Version 4.0”** at `0x2959c6`. Its version-resource region also contains ProductName **“Heroes of Might and Magic® III: The Shadow of Death”** and ProductVersion **“4.0”**. Those are embedded claims from this exact file, not an independent vendor-authenticity check. They should be preserved together rather than resolving the naming difference by assumption. There is **no established “build 8” designation** in this report.

The full executable's preferred image base is `0x400000`. Its REA/Ghidra overview reports **11,785 defined procedures** and **5,891 defined strings**. The demo overview reports **7,000 defined procedures** and **3,117 defined strings**. These are provider inventories; unidentified functions, undefined strings, compiler-generated fragments and imperfect boundaries remain possible. See `research/rea-evidence/full/open.json`, `full/overview.json`, `open-heroes3-demo.json` and `heroes3-overview.json`.

The full executable was supplied without its matching complete-version data archives. Archive and table findings below are therefore **demo-specific**; they must not silently be relabeled as observations of the full edition's resource data.

## 3. Original demo archives and map

The reproducible standard-library parser is `research/inspect_heroes_demo.py`. Its input files, archive member hashes, counts and selected table observations are recorded in `research/demo-resources/summary.json`, `h3bitmap-inventory.json` and `h3sprite-inventory.json`.

| Observation | Measured result |
| --- | --- |
| Bitmap archive members | 1,038: 962 PCX, 63 TXT, 9 FNT, 1 XMI, 3 PAL |
| Sprite archive members | 3,013: 1,889 DEF and 1,124 MSK |
| Combined members checked | 4,051; directory/member bounds, duplicate names and payload overlap checked |
| Compression | Every compressed member completed zlib decompression and matched its declared full size |
| Sprite metadata | 27,877 frame references across 1,889 DEF files; references are not necessarily unique images |
| Creature table | 122 nonempty `CRTRAITS.TXT` records |
| Spell table | 80 numeric records: 10 adventure, 60 combat and 10 abilities; the combat section includes a disabled Fear entry |
| Demo map | Gzip stream inflates to 45,031 bytes; name “Dead and Buried”; format field 14; 36 × 36 with underground enabled |
| Header coverage | First 168 decoded map bytes parsed, including eight player-header records; remaining map terrain/object/event data not semantically parsed |

Both LOD files start with `LOD\0`. The member count is at byte offset 8 and the 32-byte member directory starts at `0x5c`. A member record includes a 16-byte name, payload offset, decoded size, an uninterpreted field, and compressed size. A zero compressed size denotes a stored member. DEF directory metadata was read and bounded; sprite pixel/RLE data was not exported as artwork.

Ten gameplay tables were extracted for analysis only: `CRTRAITS`, `SPTRAITS`, `BUILDING`, `MOVEMENT`, `RESTYPES`, `HCTRAITS`, `HOTRAITS`, `CRANIM`, `BLDGNEUT` and `BLDGSPEC`. For example, the demo Pikeman row stores 10 HP, 4 attack, 5 defense, 1–3 damage and 60 gold cost; the Archer row stores 12 shots. The repeated `Low`/`High` headings in the creature table were distinguished as damage versus map population ranges. Stored data alone does not prove every row is playable or every field is used at runtime.

Reproduction from the original investigation workspace:

```bash
python research/inspect_heroes_demo.py \
  --input analysis-input/heroes3-demo/extracted/Program_Files \
  --output research/demo-resources
```

The full table-by-table account, hashes and parser limits are in `research/heroes-demo-resource-notes.md`. No original asset archive or extracted table was incorporated into DRACONIA.

## 4. Demo native references connect tables to code

The demo native pass went beyond finding filenames in an archive:

| Demo observation | Evidence |
| --- | --- |
| `crtraits.txt` string at `0x5d7330` has an instruction reference at `0x46f411` | `creature-xrefs.json` |
| That reference belongs to a procedure starting at **`0x46f410`**, body through `0x46f561` | `creature-procedure.json`, `creature-loader.json` |
| The procedure passes the filename to another function, checks its result and performs repeated record-processing calls | `creature-loader.json` pseudocode and assembly |
| `movement.txt` at `0x5d9d10` has a reference at `0x4b545d` | `movement-xrefs.json` |
| Its containing procedure starts at **`0x4b5370`**, body through `0x4b558f`; it also references `ballist.txt` | `movement-procedure.json`, `movement-loader.json` |
| `h3sprite.lod` has five observed instruction references | `sprites-xrefs.json` |

These records support the interpretation that original native code loads the named configuration resources. The movement procedure's filename is a research label: it includes ballista-table work as well, so it must not be presented as only the final movement-cost calculation. No dynamic scenario was executed to prove every table value's effect.

## 5. Full executable: actual procedure addresses

**A requested address may be inside a function. The address in a research filename or query is not automatically its entry point.** REA resolved the following bodies in the uploaded full executable:

| Stored evidence file | Requested address | Actual observed entry/body | Supported reading |
| --- | --- | --- | --- |
| `attacker-damage-bonuses.json` and `damage-procedure.json` | `0x443560` | **`0x443320`**, through `0x4437a7`, 1,160 bytes | Candidate damage-bonus calculation, with unit-type branches and hero-related helper calls |
| `damage-reduction.json` | `0x4438b0` | **`0x443840`**, through `0x443b83`, 836 bytes | Candidate deathblow/special-damage logic; the filename is misleading |
| `casualties.json` | `0x443db0` | **`0x443d90`**, through `0x443e2b`, 156 bytes | Candidate defensive multiplier calculation; it does not establish casualty counting |
| `hero-mobility.json` | `0x4e4c00` | **`0x4e4990`**, through `0x4e4d85`, 1,014 bytes | Candidate hero movement allowance with a seven-slot minimum-speed loop and additional branches |

All files above are under `research/rea-evidence/full/` in the investigation workspace. The provider names these functions `FUN_...`; descriptive names in this document are interpretations, not recovered original symbols.

### Damage-related observations

At `0x443320`, the decompiled view shows a difference between two helper results multiplied by **0.05**, capped at **3.0**, plus several unit-type-specific branches and calls to hero-related helpers. This is consistent with an attack-advantage contribution. It does **not** by itself establish the entire final damage formula, every parameter's meaning, rounding order, damage range generation or all special abilities. The x87 floating-point/`__ftol` representation contains decompiler ambiguities.

At `0x443840`, the function calls `0x443320`, tests creature-type fields against `0x43` and `0x92`, and contains probability-dependent branches that add an input amount. One branch compares a random-helper result with 20; another reads a threshold from a table. Message/animation-related calls follow. This supports a **deathblow/special-damage candidate**, not a general damage-reduction label. Full mapping of IDs, probabilities and arguments remains a validation task.

At `0x443d90`, a value starts at **1.0**, may be replaced by one of two stored float fields, may be multiplied by **0.5** under a status condition, and may be multiplied by a value from helper `0x4e4310`. The observed body supports a **defensive-factor candidate**. It does not subtract hit points or establish how remaining creatures are counted, despite its `casualties.json` filename.

### Mobility observations

The procedure at `0x4e4990` has an explicit loop over **seven army entries**. It skips a sentinel value, reads a field from a creature-record table and tracks the minimum, with specialty-related branches able to adjust that field. This is evidence for a slowest-creature contribution to movement allowance. Other branches read further tables, inspect repeated equipment-like slots and add bonuses. Some quantities are obscured in the decompiled floating-point view; the complete land/sea movement formula and every modifier were not established.

The full executable also defines the strings `crtraits.txt` at `0x675514`, `movement.txt` at `0x679cdc`, `h3sprite.lod` at `0x682ee8` and `sptraits.txt` at `0x68830c`. These string observations are in `full/gameplay-strings.json`; their presence alone is weaker evidence than a traced dataflow.

Selected reproducibility identifiers:

| Record | REA evidence ID |
| --- | --- |
| Full overview | `ev_d49cff6ce7bfafb2ee5fadf4dd1228afe26bdf5ce23e635750cc0f435228e661` |
| Attacker-bonus candidate | `ev_7660c4cf558926ef34e88009de0647afd39269e3f010c9ef0d46c9eca83c83eb` |
| Special-damage candidate | `ev_0aac1bfb1c484e9d652cb54a083aa3a2cd1b9b0f1976c2e853fcc83642003744` |
| Defensive-factor candidate | `ev_54ab3fbcab637e94d28638973ac50b25dc0868cbc0827c517ced08827205710b` |
| Hero mobility | `ev_e88a616f3e995594d51e8c86ab6be5cb0a56b31e9643cfd7d8303cdcf852a837` |

The exported evidence bundle and analysis snapshot preserve additional call/reference and assembly data. They remain analysis evidence, not a portable recreation of the game's original source.

## 6. HD launcher is a separate component

The uploaded `HD_Launcher.exe` was inspected with REA PE/resource operations, objdump and bounded parsing. Its small application-entry routine at preferred address `0x40103a` checks the current-directory buffer requirement, calls `LoadLibraryA("HD_LauncherNative.dll")`, obtains export `Start`, and calls that function pointer. The native DLL was not supplied in this pass.

This EXE therefore does not establish the complete HD-mod settings UI, renderer, executable selection or launch behavior. Its embedded version reports `5.7.0.7`; that is a file claim, not verification against an official release. The detailed observations and limitations are in `research/hd-launcher-notes.md` and `research/launcher-evidence/`. It must not be confused with analysis of the game engine itself.

## 7. Public-source reference and remaining investigation

VCMI was separately inspected at commit `1cdc6927dbf64af96b18ce5392085d136d424778`. Its [archive reader](https://github.com/vcmi/vcmi/blob/1cdc6927dbf64af96b18ce5392085d136d424778/lib/filesystem/CArchiveLoader.cpp), [map reader](https://github.com/vcmi/vcmi/blob/1cdc6927dbf64af96b18ce5392085d136d424778/lib/mapping/MapFormatH3M.cpp), [damage calculator](https://github.com/vcmi/vcmi/blob/1cdc6927dbf64af96b18ce5392085d136d424778/scripts/damage/damageCalculator.lua) and broader engine architecture informed interpretation and test design. The earlier `research/heroes-architecture-notes.md` records that source-reference phase; its statement that no original binary had yet been supplied describes that earlier stage. This document adds the subsequent original-file and native-code evidence.

The following are still unestablished: exhaustive original combat rules and rounding; complete spell/ability interactions; original strategic AI; original save-game layout; full H3M terrain/object/event semantics; runtime behavior of the inspected candidates; equivalence across editions; and complete-HD-mod behavior. Ghidra's inventory counts do not close these gaps.

The next evidence-producing step would be small controlled original-game scenarios, with a recorded executable/data hash and expected outcomes, compared against explicitly typed candidate rules. That would validate or falsify interpretations. DRACONIA's present rules instead make deliberate original design choices: fixed movement allowance plus a chosen skill, a smaller spell/creature library, its own campaign/economy, and an original oath/night system. Passing its native Godot tests establishes consistency of this new game, not exact reproduction of Heroes III.
