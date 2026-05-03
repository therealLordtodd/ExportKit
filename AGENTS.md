# ExportKit Working Guide

## Repositories & Local Paths

| Package | Repository | Local Path |
|---------|------------|------------|
| **ExportKit** | https://github.com/therealLordtodd/ExportKit.git | `/Users/todd/Building - Apple/Packages/ExportKit` |

## Build & Test

- Build: `swift build`
- Test: `swift test`

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

## UI Posture

N/A — no UI surface. ExportKit defines protocols, registry, and a portable document model; it contains no `View` definitions or theme-driven rendering. Reviewed 2026-04-29 (Theme & HIG audit round 1).

## Security Posture

`ExportKit` is a Cat 2 document-contract package with opt-in AI and probe products. The core `ExportKit` target owns no credentials, network calls, filesystem reads or writes, database access, durable persistence, pasteboard access, UI, or concrete format implementation. It does own an in-memory `ExportRegistry` guarded by `NSLock`, importer/exporter protocols, and document values that can carry raw `Data`, image bytes, image/file/link `URL`s, metadata, source identifiers, headers/footers, footnotes, import warnings, and document text.

Concrete importers/exporters are host or downstream-package code. They own file access, save/open panels, destination-path allowlists, sandbox/security-scoped bookmarks, network fetches, format parsing, external renderer/tool invocation, sanitization, encryption, retention, logging/audit, and privacy review for document contents and metadata.

`ExportKitAISeams` exposes the `export.jobs` surface through host-supplied start/cancel callbacks. Hosts that link it own action authorization, confirmation UX, destination validation, cancellation semantics, status redaction, audit logging, and any AI policy around what may be exported. `ExportKitMarpleProbes` is developer/test infrastructure; do not expose probe fixtures, probe output, or probe artifacts as production user data.

## Performance Posture

Hot paths are `ExportRegistry.exporter(for:)` / `importer(for:)` lookups, exercised whenever a host resolves a format before performing an export or import. Lookups are dictionary `[String: DocumentExporter]` / `[UTType: DocumentImporter]` reads guarded by an `NSLock` — O(1) and allocation-free in the hit path. Document-model construction (`ExportableDocument`, blocks, sections) happens once per export and is the dominant cost when bytes are being produced; ExportKit owns only the model shape, not format-specific marshaling. Concurrency model is `final class: @unchecked Sendable` with an `NSLock` (deliberate: the registry is a process-wide singleton-like; an actor would force every lookup to hop). Reviewed 2026-04-29 (Speed & Clarity audit round 1).

## Testing
- Run `swift test` before committing.
- Add `ExportRegistryTests` for registration and lookup changes.
- Add model round-trip coverage in `ModelTests` when changing export schema.

---

## AI-Equal Infrastructure

This kit ships two opt-in library products that make it AI-controllable and AI-verifiable per the [AI-Equal Primitive Convention](../CONVENTIONS/ai-equal-primitive-convention.md):

- **`ExportKitMarpleProbes`** — `ExportKitProbeHost` + 3 `AppProbe` conformances:
  - `ExportKitRegistryProbe` — exporter registration / lookup round-trip
  - `ExportKitImportWarningsProbe` — import-warning surfacing
  - `ExportKitRoundTripProbe` — exportable-document round-trip fidelity
  Probe-authoring conventions live at `Sources/ExportKitMarpleProbes/CONVENTIONS.md`.
- **`ExportKitAISeams`** — `ExportAISurface` registering 1 `AISurface` (`export.jobs`) backed by host-supplied `@Sendable` callbacks. The surface exposes `surfaceState` (active job count, available formats, last export status, active jobs) and `surfaceActions` across two tiers:
  - `.observe` — `getAvailableFormats`, `getJobStatus`
  - `.act` — `startExport`, `cancelExport`

Human-only hosts link only `ExportKit` and pay zero cost. AI-equal hosts add the two products. Per the AI-Equal Primitive Convention v1.4 explicit-suffix amendment, the canonical name for the AISeams product is `ExportKitAISeams`; legacy references to `ExportKitSeams` are out-of-date.

---

## Family Membership — Document Editor

This primitive is a member of the Document Editor primitive family. It participates in shared conventions and consumes or publishes cross-primitive types used by the rich-text / document / editor stack.

**Before modifying public API, shared conventions, or cross-primitive types, consult:**
- `../RichTextEditorKit/docs/plans/2026-04-19-document-editor-dependency-audit.md` — who depends on whom, who uses which conventions
- `/Users/todd/Building - Apple/Packages/CONVENTIONS/` — shared patterns this primitive participates in
- `./MEMBERSHIP.md` in this primitive's root — specific list of conventions, shared types, and sibling consumers

**Changes that alter public API, shared type definitions, or convention contracts MUST include a ripple-analysis section in the commit or PR description** identifying which siblings could be affected and how.

Standalone consumers (apps just importing this primitive) are unaffected by this discipline — it applies only to modifications to the primitive itself.
