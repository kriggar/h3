# Included investigation evidence

Read [RE_FINDINGS.md](RE_FINDINGS.md) for the observed facts, interpretations, and limits of the investigation. The game rules are independently implemented; these records are development evidence, not a runtime dependency or a recovered original source tree.

The source bundle preserves the most expensive-to-reproduce records:

- [REA installation receipt](evidence/tool-verification/installation-summary.json), [doctor checks](evidence/tool-verification/doctor.json), and [synthetic decompilation smoke test](evidence/tool-verification/smoke-decompile.json).
- [Uploaded full-game overview](evidence/full-game/overview.json), [evidence bundle](evidence/full-game/evidence-bundle.json), and [analysis snapshot](evidence/full-game/analysis-snapshot.json).
- The selected full-game procedure records alongside those bundles, with their original research filenames. Some filenames describe early hypotheses that were corrected in RE_FINDINGS.md; use the report's observed-entry table when interpreting them.
- [HD launcher static summary](evidence/hd-launcher/static-summary.json) and its associated PE, resource, and bootstrap observations.

Paths referring to `analysis-tools/` or `research/rea-evidence/` inside the records identify the original investigation workspace. The bundled equivalents are under `research/evidence/` as listed above. The original programs, complete proprietary game archives, REA installation, JDK, and Ghidra installation are not distributed in the game project. Install the referenced tools separately and provide your own original files to repeat that analysis.
