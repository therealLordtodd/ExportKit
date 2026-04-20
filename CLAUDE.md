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

---

## Family Membership — Document Editor

This primitive is a member of the Document Editor primitive family. It participates in shared conventions and consumes or publishes cross-primitive types used by the rich-text / document / editor stack.

**Before modifying public API, shared conventions, or cross-primitive types, consult:**
- `/Users/todd/Programming/Packages/docs/plans/2026-04-19-document-editor-dependency-audit.md` — who depends on whom, who uses which conventions
- `/Users/todd/Programming/Packages/CONVENTIONS/` — shared patterns this primitive participates in
- `./MEMBERSHIP.md` in this primitive's root — specific list of conventions, shared types, and sibling consumers

**Changes that alter public API, shared type definitions, or convention contracts MUST include a ripple-analysis section in the commit or PR description** identifying which siblings could be affected and how.

Standalone consumers (apps just importing this primitive) are unaffected by this discipline — it applies only to modifications to the primitive itself.
