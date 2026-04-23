# ExportKit — Project Constitution

**Created:** 2026-04-16
**Authors:** Todd Cowing + Claude (Opus 4.7)

This document records the *why* behind foundational decisions. It is written for future collaborators — human and AI — who weren't in the room when these choices were made. The development plan tells you what we're building. AGENTS.md tells you how to build it. This document tells you why we made the decisions we made, and where we believe this is going.

Fill in the project-specific sections as decisions are made. The **Founding Principles** apply to every project in the portfolio without exception — they are the intent behind the work. The **Portfolio-Wide Decisions** are pre-filled conventional choices that follow from those principles; they apply unless explicitly overridden here with a documented reason.

---

## What ExportKit Is Trying to Be

ExportKit defines a shared, portable document model plus the protocols needed to export and import that model — the foundation layer other packages build on when they want to support Markdown, HTML, PDF, DOCX, or custom formats without inventing a new document contract each time. The package is deliberately small: it ships `DocumentExporter` and `DocumentImporter` protocols, portable types like `ExportableDocument`, `ExportBlock`, `ExportSection`, `DocumentMetadata`, and supporting structures for headers, footers, and footnotes — but no concrete format implementations, save panels, UI, or registry. That minimalism is the point; concrete Markdown/HTML/PDF/DOCX exporters belong in downstream packages.

---

## Foundational Decisions

### Shared Portfolio Doctrine

The shared founding principles and portfolio-wide defaults now live in the Foundation Libraries wiki:

- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/portfolio-doctrine.md`

Use this local constitution for project-specific decisions, not copied portfolio boilerplate.

---

### Project-Specific Decisions

*Add an entry here for every significant architectural, tooling, or directional decision made for this project. Write it at decision time, not retroactively. Future collaborators need to understand the reasoning, not just the outcome.*

#### ExportKit Is Format-Agnostic

**Decision:** ExportKit defines protocols and a portable document model only. Concrete Markdown, HTML, PDF, DOCX, and similar exporters live in downstream packages, not in this package.

**Why:** Format bindings change; the document contract should not. Keeping ExportKit format-free lets multiple exporters coexist on one stable model and lets downstream packages pick their own dependencies (PDFKit, a Markdown renderer, etc.) without dragging them into every consumer.

**Trade-offs accepted:** Callers must wire format-specific exporters themselves. ExportKit alone cannot write a file.

---

#### No Shipped Registry

**Decision:** The package does not ship a global registry of exporters/importers. Host apps select and wire their own exporters.

**Why:** A registry would turn a small contract library into a plugin framework before anyone needs one. Hosts are the right layer to know which formats they support and how to surface them.

**Trade-offs accepted:** There is no "discover all exporters" seam out of the box. Apps that want one build a thin registry on top — and do so only when they actually need it.

---

#### Two Content Shapes: `blocks` for Flat Documents, `sections` for Paginated Ones

**Decision:** `ExportableDocument` carries both a flat `blocks` array and an optional `sections` array. Use `blocks` for simple formats (Markdown, plain text) and `sections` only for formats that truly understand pages, headers, footers, and per-section layout (PDF, DOCX).

**Why:** Most exporters only care about a linear block stream. Pushing section/page semantics onto every exporter would force each one to flatten; pushing blocks onto every page-aware exporter would lose layout fidelity. Supporting both shapes lets simple formats stay simple and paginated formats keep their structure.

**Trade-offs accepted:** Authors composing documents have to pick the right shape for their target format. Exporters that ignore sections must at least handle a document that has both.

---

#### Non-Fatal Fidelity Is Expressed as `ImportWarning`, Not Errors

**Decision:** Importers use `ImportedDocument.warnings` to report partial-fidelity imports rather than hard-failing every time a feature cannot round-trip.

**Why:** Real documents from real formats rarely round-trip perfectly. Treating every fidelity gap as a fatal error would make the importer useless; silently dropping information would hide the problem. Warnings give callers the information they need to decide.

**Trade-offs accepted:** Callers must actually look at warnings for those cases where fidelity matters.

---

*Add more entries as decisions are made.*

---

## Tech Stack and Platform Choices

**Platform:** macOS 15+, iOS 17+, tvOS 15+, watchOS 8+, visionOS 1+ (per README)
**Primary language:** Swift 6 (SPM)
**UI framework:** None — this is a pure data/contract library
**Data layer:** In-memory value types (`ExportableDocument`, `ExportBlock`, `ExportSection`, `DocumentMetadata`, …); no persistence or network

**Why this stack:** ExportKit is a protocols-and-values library. It has zero external dependencies so every Apple platform can consume it cheaply. Concrete format support (and its framework dependencies) lives downstream.

---

## Who This Is Built For

*Who are the primary users or operators of this software? Humans, AI agents, or both? This shapes everything from UI density to conductorship defaults.*

[ ] Primarily humans
[ ] Primarily AI agents
[ ] Both, roughly equally
[ ] Both — humans build it, AIs operate it
[X] Both — AIs build it, humans operate it

**Notes:** ExportKit has no UI. Its direct consumers are other packages and host apps; its ultimate runtime audience is humans reading exported documents. AI agents are the primary implementers and maintainers.

---

## Where This Is Going

[To be filled in as project direction crystallizes.]

---

## Open Questions

*None recorded yet.*

---

## Amendment Process

Use this process whenever a foundational decision changes or a new decision is added.

1. Update the relevant section in this constitution in the same change as the code/docs that motivated the update.
2. For each new or changed decision entry, include:
   - **Decision**
   - **Why**
   - **Trade-offs accepted**
   - **Revisit trigger** (what condition should cause reconsideration)
3. Add a matching row in the **Decision Log** with date and a concise summary.
4. If the amendment changes implementation rules, update `AGENTS.md` and any affected style guide files in the same change.
5. Record who approved the amendment (human + AI collaborator when applicable).

Minor wording clarifications that do not change meaning do not require a new decision entry, but should still be noted in the Decision Log.

---

## Decision Log

*Brief chronological record of significant decisions. Add an entry whenever a non-trivial decision is made that isn't already captured in the sections above.*

| Date | Decision | Decided by |
|------|----------|------------|
| 2026-04-16 | Constitution created and Founding Principles established | Both |
