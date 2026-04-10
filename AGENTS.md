# ExportKit Working Guide

## Purpose
ExportKit defines the shared importer/exporter protocols and portable export document model used by concrete document exporters.

## Key Directories
- `Sources/ExportKit`: Export/import protocols, registry, options, document metadata, blocks, sections, page templates, headers/footers, and footnotes.
- `Tests/ExportKitTests`: Registry and model tests.

## Architecture Rules
- Keep ExportKit format-agnostic. Concrete Markdown, HTML, PDF, DOCX, or other implementations belong in downstream packages.
- Use `ExportableDocument.sections` for section-aware exports; keep `blocks` for flat/simple documents and compatibility.
- Preserve `ExportHeaderFooterConfiguration` first/odd/even semantics across formats.
- Keep `ExportRegistry` thread-safe when adding or looking up importers/exporters.

## Testing
- Run `swift test` before committing.
- Add `ExportRegistryTests` for registration and lookup changes.
- Add model round-trip coverage in `ModelTests` when changing export schema.
