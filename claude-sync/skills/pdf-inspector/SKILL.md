---
name: pdf-inspector
description: Classify PDFs (text-based / scanned / image-based / mixed) and convert them to clean Markdown without OCR, using firecrawl/pdf-inspector. Use when a PDF needs text extraction, Markdown conversion, or an OCR-needed check — especially large PDFs, PDFs of unknown provenance, or before deciding whether OCR is required.
---

# pdf-inspector

Python bindings for [firecrawl/pdf-inspector](https://github.com/firecrawl/pdf-inspector) (Rust). No permanent install needed — run through `uv` (cached per machine after first use):

```bash
uv run --with pdf-inspector python -c "
import pdf_inspector
r = pdf_inspector.process_pdf('document.pdf')
print(r.pdf_type)              # text_based | scanned | image_based | mixed
print(r.pages_needing_ocr)     # page numbers lacking extractable text
print(r.markdown or '')        # Markdown conversion (None if unavailable)
"
```

## API surface

Full signatures + result types: [references/api.pyi](references/api.pyi) (exact type stub shipped with the package — read it before non-trivial use).

- `process_pdf(path, pages=None)` — classification + markdown + OCR routing in one call. Default choice. Returns `PdfResult`: `pdf_type`, `markdown`, `page_count`, `pages_needing_ocr`, `title`, `confidence`, `is_complex_layout`, `pages_with_tables`, `pages_with_columns`, `has_encoding_issues`, `processing_time_ms`.
- `classify_pdf(path)` — lightweight classification only (10–50ms; type, page count, OCR pages, confidence). Use to decide whether OCR pipeline is needed.
- `detect_pdf(path)` — fast detection, no text extraction.
- `extract_text(path)` — plain text.
- `extract_text_with_positions(path, pages=None)` — `TextItem` list: text, x/y/width/height, font, font_size, bold/italic/underline/strikeout, page.
- `extract_text_in_regions(path, page_regions)` — `page_regions = [(page_0indexed, [[x1,y1,x2,y2], ...]), ...]`; per-region `needs_ocr` flag.
- `extract_pages_markdown(path, pages=None)` — per-page markdown + document-wide layout classification (tables, columns, OCR needs).
- Every function has a `_bytes` variant for in-memory PDFs.

**Index caveat:** `pages` args and `PdfClassification.pages_needing_ocr` are 0-indexed; `PdfResult` and `PagesExtractionResult` page lists (`pages_needing_ocr`, `pages_with_tables`, `pages_with_columns`) are 1-indexed (verified empirically). Check api.pyi when mixing.

## When to use vs built-in Read

- Read tool handles PDFs natively page-by-page — fine for reading/viewing.
- Use pdf-inspector when you need: machine-readable Markdown output to a file, scanned-vs-text classification, OCR-needed page lists, positional/font data, or batch processing many PDFs cheaply.

## Recipe: PDF → Markdown file

```bash
uv run --with pdf-inspector python -c "
import pdf_inspector, sys
r = pdf_inspector.process_pdf(sys.argv[1])
open(sys.argv[2], 'w').write(r.markdown or '')
print(r.pdf_type, 'ocr-needed pages:', r.pages_needing_ocr)
" input.pdf output.md
```

Requires `uv` on the machine (`brew install uv` / `pip install uv`).
