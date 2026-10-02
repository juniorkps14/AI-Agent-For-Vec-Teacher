#!/usr/bin/env bash
# Rebuild the handbook (PDF + DOCX + GitHub markdown) from ../src/*.md
# Requires: pandoc 3.x, Node.js + playwright (chromium), Python 3 + python-docx + pypdf + lxml,
#           LibreOffice (for DOCX TOC page numbers), poppler-utils.
# Fonts: npm pack @fontsource/ibm-plex-sans-thai @fontsource/ibm-plex-mono into ../fonts/ (see README)
set -e
B="$(cd "$(dirname "$0")" && pwd)"; cd "$B"
SRC="../src/00-front.md ../src/01-prep.md ../src/10-day1.md ../src/20-day2.md ../src/30-day3.md ../src/90-appendix.md"
MD="-f markdown+task_lists+fenced_divs"
# PDF
pandoc $SRC $MD -t html5 --standalone --template=body.tpl.html --toc --toc-depth=2 --no-highlight -o body.html
node print.js body body.html pass1.pdf && python3 dests.py pass1.pdf pages.json
node print.js body body.html body.pdf pages.json
node print.js cover cover.html cover.pdf
python3 merge.py cover.pdf body.pdf ../AI-Agent-Teacher-Handbook.pdf
# DOCX
pandoc -o ref-default.docx --print-default-data-file reference.docx
python3 make_ref.py
pandoc $SRC $MD -t docx --reference-doc=reference.docx --toc --toc-depth=2 --no-highlight -o raw.docx
python3 post_docx.py raw.docx stage1.docx
python3 toc_fill.py stage1.docx stage2.docx
soffice --headless --convert-to pdf --outdir lo stage2.docx >/dev/null 2>&1
python3 toc_fill.py stage2.docx stage3.docx lo/stage2.pdf
python3 normalize_docx.py stage3.docx ../AI-Agent-Teacher-Handbook.docx
# GitHub markdown
pandoc $SRC $MD -t gfm --lua-filter=gfm.lua --wrap=none -o handbook-gfm.md
{ sed -n '1,/^---$/p' ../../docs/04-handbook.md; echo; cat handbook-gfm.md; } > gfm.tmp && mv gfm.tmp ../../docs/04-handbook.md
echo "done"
