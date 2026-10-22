#!/usr/bin/env python3
"""Rasterize every design-PDF page and record reproducible layout checks.

The contact sheets still require human visual inspection. This script never
marks them accepted merely because extraction or page bounds succeeded.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path

import pdfplumber
from PIL import Image, ImageDraw, ImageFont
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parent


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", type=Path, default=WORKSPACE / "output/pdf/Draconia-Game-Design.pdf")
    parser.add_argument("--render-dir", type=Path, default=WORKSPACE / "tmp/pdfs/draconia-design/final-render")
    parser.add_argument("--dpi", type=int, default=110)
    parser.add_argument("--poppler", default="pdftoppm", help="Optional direct Poppler executable; the default uses PATH")
    args = parser.parse_args()
    args.render_dir.mkdir(parents=True, exist_ok=True)
    reader = PdfReader(args.pdf)
    page_count = len(reader.pages)
    # Work only on this script's generated image names, never arbitrary files.
    for old in args.render_dir.glob("page-*.png"):
        old.unlink()
    for old in args.render_dir.glob("contact-*.jpg"):
        old.unlink()
    cache = args.render_dir / "fontcache"
    cache.mkdir(exist_ok=True)
    fontconfig = args.render_dir / "fonts.conf"
    fontconfig.write_text(f'<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "fonts.dtd">\n<fontconfig><dir>/usr/share/fonts</dir><cachedir>{cache}</cachedir></fontconfig>\n')
    env = dict(os.environ)
    env["FONTCONFIG_FILE"] = str(fontconfig)
    command = [args.poppler, "-r", str(args.dpi), "-png", str(args.pdf), str(args.render_dir / "page")]
    run = subprocess.run(command, env=env, capture_output=True, text=True)
    (args.render_dir / "render.log").write_text(run.stdout + run.stderr)
    if run.returncode:
        raise SystemExit(f"PDF rendering failed ({run.returncode}); see render.log")
    pages = sorted(args.render_dir.glob("page-*.png"))
    if len(pages) != page_count:
        raise SystemExit(f"Expected {page_count} page images, found {len(pages)}")
    label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
    sheets = []
    for start in range(0, len(pages), 12):
        batch = pages[start:start+12]
        rows = (len(batch) + 3) // 4
        sheet = Image.new("RGB", (1540, 18 + rows * 580), "#d8d8d8")
        draw = ImageDraw.Draw(sheet)
        for index, path in enumerate(batch):
            with Image.open(path) as source:
                image = source.convert("RGB")
            image.thumbnail((360, 514), Image.Resampling.LANCZOS)
            x = 16 + (index % 4) * 382 + (360-image.width)//2
            y = 18 + (index // 4) * 580
            sheet.paste(image, (x, y))
            draw.text((x, y + image.height + 7), f"Page {start+index+1}", fill="#111111", font=label_font)
        path = args.render_dir / f"contact-{start//12+1:02}.jpg"
        sheet.save(path, quality=94)
        sheets.append(str(path))
    out_of_bounds = []
    low_fill = []
    page_chars = []
    with pdfplumber.open(args.pdf) as document:
        for number, page in enumerate(document.pages, 1):
            page_chars.append(len(page.chars))
            wrong = [c for c in page.chars if c["x0"] < 25 or c["x1"] > page.width-25 or c["top"] < 14 or c["bottom"] > page.height-12]
            if wrong:
                out_of_bounds.append({"page": number, "count": len(wrong), "text": "".join(c["text"] for c in wrong)})
            body = [c for c in page.chars if c["top"] > 45 and c["bottom"] < page.height-39]
            if number > 3 and body and max(c["bottom"] for c in body) < page.height*.5:
                low_fill.append({"page": number, "bodyChars": len(body), "bodyBottom": round(max(c["bottom"] for c in body), 1)})
    report_path = args.pdf.with_suffix(".report.json")
    report = json.loads(report_path.read_text())
    sha = hashlib.sha256(args.pdf.read_bytes()).hexdigest()
    if report["sha256"] != sha:
        raise SystemExit("PDF content no longer matches the authoring report; rebuild first")
    report["renderVerification"] = {"pdfSha256": sha, "command": command, "exitCode": run.returncode,
        "renderedPages": len(pages), "dpi": args.dpi, "renderDirectory": str(args.render_dir),
        "contactSheets": sheets, "charsPerPage": page_chars, "charactersOutsideSafePageBounds": out_of_bounds,
        "lowFillPagesToReview": low_fill, "rendererDiagnostics": (run.stdout + run.stderr).strip(),
        "visualReviewStatus": "pending"}
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"pagesRendered": len(pages), "contactSheets": len(sheets), "outOfBounds": out_of_bounds, "lowFillPages": low_fill, "rendererDiagnostics": (run.stdout + run.stderr).strip(), "report": str(report_path)}, ensure_ascii=False))
    if out_of_bounds:
        raise SystemExit("Text outside safe page bounds requires review")


if __name__ == "__main__":
    main()
