#!/usr/bin/env python3
"""Build the complete Draconia GDD and complete hero-roster appendix.

Inputs are the authored Markdown and JSON catalogs, not a summarized rewrite.
Run with the provided Python runtime; PDF/font dependencies are runtime-owned.
The PDF skill's artifact marker must be invoked by the authoring workflow before
the first creation, not automatically on every rebuild of this script.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import unicodedata
from pathlib import Path

from fontTools.ttLib import TTFont as FontToolsFont
from fontTools.varLib.instancer import instantiateVariableFont
from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, CondPageBreak, Flowable, Frame, KeepTogether,
    LongTable, NextPageTemplate, PageBreak, PageTemplate, Paragraph, Spacer, TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents

ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parent
DEFAULT_OUTPUT = WORKSPACE / "output/pdf/Draconia-Game-Design.pdf"
PAPER = colors.HexColor("#F7F3E9")
INK = colors.HexColor("#262923")
MUTED = colors.HexColor("#62665A")
BRONZE = colors.HexColor("#86623D")
RULE = colors.HexColor("#D5C7AF")
WHITE = colors.white
PAGE_W, PAGE_H = A4
LEFT, RIGHT, TOP, BOTTOM = 49, 49, 55, 47
WIDTH = PAGE_W - LEFT - RIGHT
HEIGHT = PAGE_H - TOP - BOTTOM


def clean_text(text: str) -> str:
    """Keep document wording; use supported ASCII dashes in the PDF."""
    return (text.replace("\u2011", "-").replace("\u2010", "-")
            .replace("\u2012", "-").replace("\u2013", "-")
            .replace("\u2014", "-").replace("\u2212", "-")
            .replace("\u00a0", " ").replace("\u202f", " "))


def source_plain(text: str) -> str:
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", text)
    return clean_text(re.sub(r"[*`]", "", text))


def compact(text: str) -> str:
    return re.sub(r"[^a-z0-9]", "", unicodedata.normalize("NFKD", clean_text(text)).casefold())


def inline(text: str, table: bool = False) -> str:
    text = clean_text(text)
    saved: list[str] = []

    def protect(fragment: str) -> str:
        saved.append(fragment)
        return f"ZZINLINE{len(saved)-1}ZZ"

    def link(match: re.Match) -> str:
        label, target = match.group(1), match.group(2)
        label = inline(label, table)
        if target.startswith(("https://", "http://")):
            return protect(f'<link href="{html.escape(target, quote=True)}" color="#795B3B">{label}</link>')
        destinations = {"GAME_DESIGN.md": "part-design", "HERO_ROSTER.md": "part-heroes", "CREATURE_ROSTER.md": "creature-roster"}
        name = target.split("/")[-1]
        if name in destinations:
            return protect(f'<link href="#{destinations[name]}" color="#795B3B">{label}</link>')
        # These are labels referring to the separately supplied source bundle.
        return protect(label)

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, text)
    text = re.sub(r"`([^`]+)`", lambda m: protect('<font name="DesignMono" size="%s">%s</font>' % ("8.4" if table else "9.4", html.escape(m.group(1)))), text)
    text = html.escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    for index, fragment in enumerate(saved):
        text = text.replace(f"ZZINLINE{index}ZZ", fragment)
    return text


def setup_fonts(tmp: Path) -> None:
    tmp.mkdir(parents=True, exist_ok=True)
    for output_name, source, weight in [
        ("DesignBody", ROOT / "assets/ebgaramond.ttf", 450),
        ("DesignBold", ROOT / "assets/ebgaramond.ttf", 650),
        ("DesignTitle", ROOT / "assets/cinzel.ttf", 600),
    ]:
        target = tmp / f"{output_name}.ttf"
        font = FontToolsFont(source)
        if "fvar" in font:
            font = instantiateVariableFont(font, {"wght": weight}, inplace=True)
        # ReportLab caches TrueType faces by their internal PostScript name.
        # Distinct variable-font instances must not silently share the first
        # face's glyphs/metrics when regular and bold are both embedded.
        for record in font["name"].names:
            if record.nameID in [1, 4, 6, 16]:
                record.string = output_name.encode(record.getEncoding())
            elif record.nameID in [2, 17]:
                record.string = "Regular".encode(record.getEncoding())
        font.save(target)
        pdfmetrics.registerFont(TTFont(output_name, str(target)))
    mono = Path("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")
    if not mono.exists():
        raise FileNotFoundError("The installed DejaVu Sans Mono font is required for API blocks")
    pdfmetrics.registerFont(TTFont("DesignMono", str(mono)))
    pdfmetrics.registerFontFamily("DesignBody", normal="DesignBody", bold="DesignBold", italic="DesignBody", boldItalic="DesignBold")


def styles() -> dict[str, ParagraphStyle]:
    base = dict(fontName="DesignBody", textColor=INK, fontSize=11.8, leading=15.5,
                spaceAfter=8, allowWidows=0, allowOrphans=0, splitLongWords=1)
    result = {"body": ParagraphStyle("Body", **base)}
    result["bullet"] = ParagraphStyle("Bullet", parent=result["body"], leftIndent=14, firstLineIndent=0, bulletIndent=0, spaceAfter=6)
    result["h1"] = ParagraphStyle("Part", parent=result["body"], fontName="DesignTitle", fontSize=23, leading=30, spaceBefore=5, spaceAfter=17, keepWithNext=1)
    result["h2"] = ParagraphStyle("Chapter", parent=result["body"], fontName="DesignTitle", fontSize=16.5, leading=21.5, textColor=BRONZE, spaceBefore=20, spaceAfter=10, keepWithNext=1)
    result["h3"] = ParagraphStyle("Section", parent=result["body"], fontName="DesignBold", fontSize=13.2, leading=17, spaceBefore=14, spaceAfter=7, keepWithNext=1)
    result["h4"] = ParagraphStyle("Subsection", parent=result["body"], fontName="DesignTitle", fontSize=12, leading=16, textColor=BRONZE, spaceBefore=12, spaceAfter=8, keepWithNext=1)
    result["table"] = ParagraphStyle("Cell", parent=result["body"], fontSize=10.4, leading=13.4, spaceAfter=0, allowWidows=1, allowOrphans=1)
    result["table_header"] = ParagraphStyle("CellHeader", parent=result["table"], fontName="DesignBold", textColor=WHITE, fontSize=10.4, leading=13.4)
    result["code"] = ParagraphStyle("Code", parent=result["body"], fontName="DesignMono", fontSize=8.6, leading=12, leftIndent=9, rightIndent=9, spaceAfter=1)
    result["small"] = ParagraphStyle("Small", parent=result["body"], fontSize=10.5, leading=14, textColor=MUTED)
    result["reference"] = ParagraphStyle("Reference", parent=result["body"], fontSize=10.8, leading=14.2, spaceAfter=6)
    result["reference_bullet"] = ParagraphStyle("ReferenceBullet", parent=result["reference"], leftIndent=14, firstLineIndent=0, bulletIndent=0, spaceAfter=5)
    result["toc0"] = ParagraphStyle("ContentsMajor", parent=result["body"], fontName="DesignBold", fontSize=11.3, leading=16, leftIndent=0, firstLineIndent=0, spaceBefore=6, spaceAfter=3)
    result["toc1"] = ParagraphStyle("ContentsMinor", parent=result["body"], fontSize=10.6, leading=14.5, leftIndent=12, firstLineIndent=0, spaceBefore=0, spaceAfter=1)
    return result


class Cover(Flowable):
    def __init__(self, style: dict[str, ParagraphStyle]):
        super().__init__()
        self.width, self.height = WIDTH, HEIGHT - 4
        self.style = style

    def draw(self):
        c = self.canv
        w, h = self.width, self.height
        c.setStrokeColor(RULE)
        c.setLineWidth(0.8)
        c.rect(10, 12, w - 20, h - 24, stroke=1, fill=0)
        c.setStrokeColor(BRONZE)
        c.line(35, h - 55, w - 35, h - 55)
        c.setFillColor(BRONZE)
        c.setFont("DesignTitle", 11)
        c.drawCentredString(w / 2, h - 43, "A NATIVE STRATEGY AND ACTION GAME")
        c.setFillColor(INK)
        c.setFont("DesignTitle", 39)
        c.drawCentredString(w / 2, h - 140, "DRACONIA")
        c.setFont("DesignTitle", 14)
        c.drawCentredString(w / 2, h - 169, "OATHS OF THE CARPATHIANS")
        c.setStrokeColor(BRONZE)
        c.setLineWidth(1.2)
        cx, cy = w / 2, h - 223
        p = c.beginPath()
        p.moveTo(cx, cy + 15); p.lineTo(cx + 15, cy); p.lineTo(cx, cy - 15); p.lineTo(cx - 15, cy); p.close()
        c.drawPath(p, stroke=1, fill=0)
        c.line(cx - 88, cy, cx - 25, cy); c.line(cx + 25, cy, cx + 88, cy)
        title = Paragraph("Integrated Game Design<br/>and Complete Hero Roster", ParagraphStyle("CoverSubtitle", parent=self.style["h2"], fontSize=20, leading=27, alignment=TA_CENTER, textColor=INK))
        tw, th = title.wrap(w - 70, 100)
        title.drawOn(c, 35, h - 326)
        c.setFillColor(MUTED)
        c.setFont("DesignBody", 13)
        c.drawCentredString(w / 2, h - 363, "One chosen hero. Six companies. A realm that remembers.")
        card_w = (w - 78) / 4
        for index, (number, label) in enumerate([("9", "FACTIONS"), ("162", "RECRUITS"), ("156", "HERO CONCEPTS"), ("1", "CHOSEN HERO")]):
            x = 39 + index * card_w
            c.setStrokeColor(RULE)
            c.line(x + 5, h - 403, x + card_w - 5, h - 403)
            c.setFillColor(BRONZE)
            c.setFont("DesignTitle", 24)
            c.drawCentredString(x + card_w / 2, h - 439, number)
            c.setFillColor(MUTED)
            c.setFont("DesignTitle", 7.9)
            c.drawCentredString(x + card_w / 2, h - 460, label)
        note = Paragraph("<b>Production design, not a completion claim.</b><br/>The full system specification and named rosters are preserved here. Implemented mechanics, recorded checks and remaining acceptance gates are identified separately.", ParagraphStyle("CoverNote", parent=self.style["small"], alignment=TA_CENTER, fontSize=11.3, leading=15.6))
        nw, nh = note.wrap(w - 100, 120)
        note.drawOn(c, 50, 83)
        c.setStrokeColor(BRONZE)
        c.line(35, 64, w - 35, 64)
        c.setFillColor(MUTED)
        c.setFont("DesignTitle", 9)
        c.drawCentredString(w / 2, 43, "COMPLETE DESIGN EDITION  |  22 OCTOBER 2026")


class DesignDoc(BaseDocTemplate):
    def __init__(self, path: Path, **kwargs):
        super().__init__(str(path), pagesize=A4, leftMargin=LEFT, rightMargin=RIGHT,
                         topMargin=TOP, bottomMargin=BOTTOM, title="Draconia - Complete Game Design and Hero Roster",
                         author="Draconia project", subject="Integrated original game design, definitive creature catalog, complete hero roster and implementation evidence", **kwargs)
        for template_id in ["standard", "heroes"]:
            self.addPageTemplates(PageTemplate(id=template_id, frames=[Frame(LEFT, BOTTOM, WIDTH, HEIGHT, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)], onPage=self.on_page))
        self.part = "DESIGN AND PRODUCTION"
        self.heading_records = []

    def beforeDocument(self):
        super().beforeDocument()
        self.part = "DESIGN AND PRODUCTION"
        self.heading_records = []

    def on_page(self, canvas, doc):
        canvas.saveState()
        if doc.page == 1:
            canvas.setFillColor(PAPER)
            canvas.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)
        else:
            canvas.setFillColor(MUTED)
            canvas.setFont("DesignTitle", 8.2)
            canvas.drawString(LEFT, PAGE_H - 29, "DRACONIA  /  GAME DESIGN")
            header_part = "HERO ROSTER APPENDIX" if self.pageTemplate.id == "heroes" else "DESIGN AND PRODUCTION"
            canvas.drawRightString(PAGE_W - RIGHT, PAGE_H - 29, header_part)
            canvas.setStrokeColor(RULE)
            canvas.setLineWidth(0.5)
            canvas.line(LEFT, PAGE_H - 36, PAGE_W - RIGHT, PAGE_H - 36)
            canvas.line(LEFT, 33, PAGE_W - RIGHT, 33)
            canvas.setFont("DesignBody", 8.8)
            canvas.drawString(LEFT, 20, "22 OCTOBER 2026  |  DESIGN TARGETS AND VERIFIED SLICE")
            canvas.setFont("DesignTitle", 9)
            canvas.drawRightString(PAGE_W - RIGHT, 20, str(doc.page))
        canvas.restoreState()

    def afterFlowable(self, flowable):
        if hasattr(flowable, "part_label"):
            self.part = flowable.part_label
        if not hasattr(flowable, "bookmark_key"):
            return
        key = flowable.bookmark_key
        title = flowable.plain_heading
        self.canv.bookmarkPage(key)
        self.canv.addOutlineEntry(title, key, flowable.outline_level, closed=False)
        self.heading_records.append({"title": title, "page": self.page, "bookmark": key})
        if flowable.toc_level is not None:
            self.notify("TOCEntry", (flowable.toc_level, html.escape(title), self.page, key))


def table_widths(headers: list[str], part: str) -> list[float]:
    n = len(headers)
    joined = " ".join(headers).lower()
    if "exclusive promotion" in joined:
        weights = [0.22, 0.285, 0.285, 0.21]
    elif part == "heroes" and n == 5 and "signature" in joined:
        # The two prose columns need room; the class and role are short labels.
        # Preserve readable type while avoiding a single hero on a third page.
        weights = [0.18, 0.14, 0.14, 0.31, 0.23]
    elif part == "heroes" and n == 4 and "faction" in headers[0].lower():
        weights = [0.245, 0.16, 0.33, 0.265]
    elif part == "heroes" and n == 4 and "signature" in joined:
        weights = [0.20, 0.165, 0.35, 0.285]
    elif "gold / wood / ore" in joined:
        weights = [0.29, 0.18, 0.18, 0.35]
    elif n == 2:
        weights = [0.35, 0.65]
    elif n == 3:
        weights = [0.22, 0.39, 0.39]
    elif n == 4:
        weights = [0.205, 0.26, 0.28, 0.255]
    elif n == 5:
        weights = [0.17, 0.17, 0.22, 0.24, 0.20]
    else:
        weights = [1 / n] * n
    return [WIDTH * x for x in weights]


def build_markdown(path: Path, part: str, style: dict[str, ParagraphStyle], coverage: list[dict]) -> list:
    lines = path.read_text().splitlines()
    story: list = []
    index = 0
    heading_serial = 0
    last_outline_level = 0
    reference_section = False

    def track(text: str, kind: str) -> None:
        value = source_plain(text).strip()
        if value:
            coverage.append({"source": path.name, "kind": kind, "text": value})

    def add_heading(text: str, level: int, followed_by_table: bool = False):
        nonlocal heading_serial, last_outline_level
        heading_serial += 1
        key = f"{part}-h-{heading_serial}"
        if level == 1:
            key = "part-design" if part == "design" else "part-heroes"
        if text == "The definitive fifty-four family roster":
            key = "creature-roster"
        is_faction = (text.startswith("The ") and " - " in clean_text(text))
        if (part == "design" and level == 4 and is_faction) or (part == "heroes" and level == 3 and is_faction):
            story.append(PageBreak())
        else:
            story.append(CondPageBreak(165 if followed_by_table else 110 if level <= 2 else 90))
        heading_style = style[f"h{min(level, 4)}"]
        if followed_by_table:
            # Keep a meaningful header/first-row budget without forcing an
            # entire multi-page table onto the following page.
            heading_style = ParagraphStyle(f"TableHeading-{part}-{heading_serial}", parent=heading_style, keepWithNext=0)
        paragraph = Paragraph(inline(text), heading_style)
        paragraph.bookmark_key = key
        paragraph.plain_heading = source_plain(text)
        desired_level = max(0, level - 1)
        paragraph.outline_level = min(desired_level, last_outline_level + 1)
        last_outline_level = paragraph.outline_level
        paragraph.toc_level = (0 if level == 1 else 1 if level == 2 and (part == "heroes" or re.match(r"\d+\.", text)) else 1 if part == "heroes" and is_faction else None)
        if level == 1:
            paragraph.part_label = "DESIGN AND PRODUCTION" if part == "design" else "HERO ROSTER APPENDIX"
        story.append(paragraph)
        track(text, "heading")

    while index < len(lines):
        line = lines[index].strip()
        if not line:
            index += 1
            continue
        heading = re.match(r"^(#{1,4})\s+(.+)", line)
        if heading:
            if part == "design" and heading.group(2).startswith("26. Sources"):
                reference_section = True
            lookahead = index + 1
            while lookahead < len(lines) and not lines[lookahead].strip():
                lookahead += 1
            next_is_table = lookahead < len(lines) and lines[lookahead].strip().startswith("|")
            add_heading(heading.group(2), len(heading.group(1)), next_is_table)
            index += 1
            continue
        if line.startswith("```"):
            index += 1
            code = []
            while index < len(lines) and not lines[index].strip().startswith("```"):
                raw = lines[index]
                code.append(Paragraph(html.escape(clean_text(raw)).replace(" ", "&#160;"), style["code"]))
                track(raw, "code")
                index += 1
            story.append(Spacer(1, 5))
            story.extend(code)
            story.append(Spacer(1, 9))
            index += 1
            continue
        if line.startswith("|"):
            rows: list[list[str]] = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                cells = [s.strip() for s in lines[index].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", s.replace(" ", "")) for s in cells):
                    rows.append(cells)
                index += 1
            if not rows:
                continue
            count = len(rows[0])
            if any(len(row) != count for row in rows):
                raise ValueError(f"Uneven table in {path} near line {index}")
            formatted = []
            for row_index, row in enumerate(rows):
                formatted.append([Paragraph(inline(cell, table=True), style["table_header"] if row_index == 0 else style["table"]) for cell in row])
                for cell in row:
                    track(cell, "table_cell")
            table = LongTable(formatted, colWidths=table_widths(rows[0], part), repeatRows=1, splitByRow=1, hAlign="LEFT", spaceBefore=5, spaceAfter=12)
            table.setStyle(TableStyle([
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BACKGROUND", (0, 0), (-1, 0), INK),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [PAPER, WHITE]),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ("LINEBELOW", (0, 0), (-1, 0), 0.7, BRONZE),
                ("LINEBELOW", (0, 1), (-1, -1), 0.25, RULE),
            ]))
            story.append(table)
            continue
        bullet = re.match(r"^(?:([-*])|(\d+)\.)\s+(.+)", line)
        if bullet:
            text = bullet.group(3)
            index += 1
            while index < len(lines) and lines[index].startswith("  ") and lines[index].strip():
                text += " " + lines[index].strip()
                index += 1
            story.append(Paragraph(inline(text), style["reference_bullet"] if reference_section else style["bullet"], bulletText=(bullet.group(2) + "." if bullet.group(2) else "\u2022")))
            track(text, "list")
            continue
        paragraph = [line]
        index += 1
        while index < len(lines) and lines[index].strip() and not re.match(r"^(?:#{1,4}\s|\||```|[-*]\s|\d+\.\s)", lines[index].strip()):
            paragraph.append(lines[index].strip())
            index += 1
        text = " ".join(paragraph)
        story.append(Paragraph(inline(text), style["reference"] if reference_section else style["body"]))
        track(text, "paragraph")
    return story


def audit_pdf(output: Path, sources: list[Path], coverage: list[dict], headings: list[dict]) -> dict:
    reader = PdfReader(output)
    page_text = []
    all_links = []
    for page in reader.pages:
        text = page.extract_text() or ""
        kept = []
        for line in text.splitlines():
            if (line.startswith("DRACONIA  /  GAME DESIGN") or line in ["DESIGN AND PRODUCTION", "HERO ROSTER APPENDIX"]
                    or line.startswith("22 OCTOBER 2026  |") or re.fullmatch(r"\d+", line.strip())):
                continue
            kept.append(line)
        page_text.append("\n".join(kept))
        for annotation in page.get("/Annots", []):
            obj = annotation.get_object()
            if obj.get("/A", {}).get("/URI"):
                all_links.append(str(obj["/A"]["/URI"]))
    text = "\n".join(page_text)
    normalized = compact(text)
    missing = [block for block in coverage if len(compact(block["text"])) > 8 and compact(block["text"]) not in normalized]
    hero_catalog = json.loads((ROOT / "data/hero_roster.json").read_text())
    creature_catalog = json.loads((ROOT / "data/creature_roster.json").read_text())
    missing_heroes = [item["name"] for item in hero_catalog["heroes"] if compact(item["name"]) not in normalized]
    missing_units = [item["name"] for item in creature_catalog["units"] if compact(item["name"]) not in normalized]
    return {"output": str(output), "pages": len(reader.pages), "bytes": output.stat().st_size,
            "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
            "sources": [{"path": str(p), "words": len(p.read_text().split()), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources],
            "renderedSourceBlocks": len(coverage), "missingTextBlocks": missing,
            "heroNamesExpected": 156, "missingHeroNames": missing_heroes,
            "creatureNamesExpected": 162, "missingCreatureNames": missing_units,
            "externalLinks": sorted(set(all_links)), "headings": headings,
            "visualInspection": "Pending all-page raster/contact-sheet inspection; extraction alone does not establish layout quality."}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    tmp = WORKSPACE / "tmp/pdfs/draconia-design"
    setup_fonts(tmp / "fonts")
    st = styles()
    coverage: list[dict] = []
    sources = [ROOT / "docs/GAME_DESIGN.md", ROOT / "docs/HERO_ROSTER.md"]
    story = [Cover(st), PageBreak(), Paragraph("Contents", st["h1"]),
             Paragraph("Part I contains the complete integrated design, including every named faction family and promotion. Part II preserves the complete 156-hero design roster, identity rules and acceptance requirements. Roster entries are authored design concepts, not completed playable characters.", st["small"])]
    toc = TableOfContents()
    toc.levelStyles = [st["toc0"], st["toc1"]]
    toc.dotsMinLevel = 0
    story.extend([Spacer(1, 7), toc, PageBreak()])
    story.extend(build_markdown(sources[0], "design", st, coverage))
    story.append(NextPageTemplate("heroes"))
    story.append(PageBreak())
    story.append(Paragraph("PART II  /  COMPLETE HERO ROSTER", st["small"]))
    story.extend(build_markdown(sources[1], "heroes", st, coverage))
    doc = DesignDoc(args.output)
    doc.multiBuild(story, maxPasses=6)
    report = audit_pdf(args.output, sources, coverage, doc.heading_records)
    report_path = args.output.with_suffix(".report.json")
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({k: report[k] for k in ["output", "pages", "bytes", "renderedSourceBlocks", "missingHeroNames", "missingCreatureNames"]}, ensure_ascii=False))
    print("Missing full extracted blocks:", len(report["missingTextBlocks"]))
    print("External linked sources:", len(report["externalLinks"]))
    print("Report:", report_path)
    if report["missingHeroNames"] or report["missingCreatureNames"]:
        raise SystemExit("A named roster entry is missing from the PDF")


if __name__ == "__main__":
    main()
