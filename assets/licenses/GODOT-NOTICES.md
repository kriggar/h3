# Godot Engine redistribution notices

Draconia's native Windows and Linux builds use the official **Godot 4.7.2
stable** runtime. The installed editor reports
`4.7.2.stable.official.ed1daf0bf`.

The files in this directory were downloaded unchanged from the exact
`4.7.2-stable` tag of the official `godotengine/godot` repository:

| Bundled notice | Exact upstream URL | SHA-256 |
|---|---|---|
| `GODOT-LICENSE.txt` | <https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt> | `b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80` |
| `GODOT-COPYRIGHT.txt` | <https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt> | `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d` |

`GODOT-LICENSE.txt` contains the engine's MIT copyright and license notice.
`GODOT-COPYRIGHT.txt` contains the upstream notices and license texts for
third-party components used by Godot. Retaining the complete upstream file
avoids removing notices for a dependency included by an export template.

Include both files in each native binary package, alongside Draconia's
project license and the separate artwork, font and audio notices. These
notices are readable without an internet connection.

Official guidance:
<https://docs.godotengine.org/en/stable/about/complying_with_licenses.html>
and <https://godotengine.org/license/>.

The corresponding source URLs, file sizes, version and hashes are also
recorded in this directory's `manifest.json`.
