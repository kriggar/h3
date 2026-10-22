#!/usr/bin/env python3
"""Acquire a small, attributable CC0 material selection from its primary source.

Authoring only. The game never contacts a texture service. Original downloads
are retained unchanged and their published MD5 plus local SHA-256 are checked.
"""
from __future__ import annotations
import concurrent.futures
import hashlib
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/models/source/characters/pbr-sources"
HEADERS = {"User-Agent": "DraconiaAssetAuthoring/0.3 (local-development-material-acquisition)"}
ASSETS = ("caban", "rough_linen", "brown_leather")


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=45) as response:
        return response.read()


def download(asset: str, channel: str, record: dict) -> dict:
    directory = DEST / asset
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / record["url"].rsplit("/", 1)[-1]
    content = target.read_bytes() if target.exists() else fetch(record["url"])
    assert hashlib.md5(content).hexdigest() == record["md5"], f"Published checksum mismatch: {target.name}"
    assert len(content) == record["size"], f"Published size mismatch: {target.name}"
    if not target.exists():
        target.write_bytes(content)
    return {"asset": asset, "channel": channel, "path": str(target.relative_to(ROOT)),
            "url": record["url"], "bytes": len(content), "md5": record["md5"],
            "sha256": hashlib.sha256(content).hexdigest()}


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    selected = []
    jobs = []
    for asset in ASSETS:
        saved = {}
        for kind in ("info", "files"):
            path = DEST / f"{asset}-{kind}.json"
            data = json.loads(path.read_text()) if path.exists() else json.loads(fetch(f"https://api.polyhaven.com/{kind}/{asset}"))
            path.write_text(json.dumps(data, indent=2) + "\n")
            saved[kind] = data
        info = saved["info"]
        selected.append({"id": asset, "name": info["name"], "authors": info["authors"],
                         "source": f"https://polyhaven.com/a/{asset}", "license": "CC0-1.0",
                         "licenseUrl": "https://polyhaven.com/license", "dimensionsMillimetres": info["dimensions"],
                         "role": {"caban": "Madder wool and charcoal cowl", "rough_linen": "Undyed linen and woven binding",
                                  "brown_leather": "Belt, weapon grips and boot surface"}[asset]})
        for channel in ("Diffuse", "arm", "nor_gl"):
            # Preserve the normal losslessly; albedo and scalar channels use
            # the source's high-quality JPEG. No screen-lit preview is used.
            fmt = "png" if channel == "nor_gl" else "jpg"
            jobs.append((asset, channel, saved["files"][channel]["2k"][fmt]))
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        records = list(pool.map(lambda job: download(*job), jobs))
    manifest = {"schemaVersion": 1, "purpose": "Offline character material authoring", "assets": selected,
                "files": records, "status": "Downloaded and checksum-verified; native material acceptance is separate"}
    (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"assets": len(selected), "files": len(records), "bytes": sum(x["bytes"] for x in records),
                      "manifest": str(DEST / "manifest.json")}))


if __name__ == "__main__":
    main()
