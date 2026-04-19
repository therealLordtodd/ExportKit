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

### Founding Principles

These are the core architectural and philosophical commitments that shape every project in this portfolio. They are not defaults to be overridden — they are the intent behind the work. Every other decision, in this document or elsewhere, should be consistent with these principles.

---

#### Layered Architecture — Primitives, Kits, Host Apps

**Decision:** Every app in this portfolio is built as a thin host layer on top of a stack of shared primitives and kits. Before building any feature or component, check `/Users/todd/Programming/Packages/` for existing primitives and kits that already solve part of the problem — if one exists, use it. When building something novel, always ask: *"Can this feature or component be a primitive or a kit?"* If yes, build it at the primitive or kit layer first, then let the host app wrap it.

**Why:** This is a layered system in the Unix sense — small, sharp, composable foundation pieces that stack into larger capabilities, with host apps as the outermost wrapper. Reuse is not a secondary concern; it is the entire point. Foundation code only becomes solid when it is used everywhere, in real apps, under real load. Every app is both a consumer of primitives and a proving ground that justifies their existence with real usage and bug testing. Re-implementing a capability that already exists in `Packages/` weakens the foundation and forks maintenance across copies that will drift.

**How this shapes decisions:**
- **During design:** browse `Packages/` first. The names are descriptive. Don't rebuild what exists.
- **During implementation:** if new work is even partly general-purpose, extract it as a primitive or kit *before* the host app depends on it.
- **During review:** duplicating existing primitive functionality is a code review finding, not a stylistic preference.

---

#### Built for Humans and AI Together

**Decision:** As far as is reasonable, every app in this portfolio is designed for both human and AI operation. AI agents are first-class operators of these apps, not observers. Every app is wired into the four backbone packages that give AI the ability to interact with, debug, and use the software we build:

- **AISeamsKit** — the controllability seam. Exposes app surfaces so AI can act on them.
- **Marple** — app inspection. Lets AI introspect the structure and state of running UI.
- **LoggingKit** — structured logging. Gives AI a filterable, queryable event stream of what the app is doing in real time.
- **Ansel** — screen capture. Lets AI visually perceive what is on screen.

An app that is not wired into these backbone packages is a human-only app, not a collaboration app.

**Why:** This whole adventure is a giant collaboration engine. Our apps are the places where humans and AIs do work *together* — not just UIs that humans drive while an AI watches from the outside. An AI that cannot see, name, or act on a surface cannot collaborate on it; it can only give advice. The four backbone packages are what turn a human app into a collaboration app: perception (Ansel), introspection (Marple), observation (LoggingKit), and action (AISeamsKit).

Several entries later in this document — the UI element naming convention, the centralized logging architecture, the style check — exist *because* of this principle. They are the mechanical implementation of "the AI can reach this." When a design decision affects whether an AI can operate a surface, this principle is the tiebreaker.

**How this shapes decisions:**
- New features are designed with the question *"Can an AI do this?"* If no, document why.
- New UI elements are named and exposed — anonymous inline controls are invisible to AI and violate this principle.
- New apps integrate AISeamsKit, Marple, LoggingKit, and Ansel by default, not as a follow-up. Adding them retroactively is harder than wiring them in from day one.

---

### Portfolio-Wide Decisions (Pre-Filled)

These are the conventional choices that follow from the Founding Principles above — tooling, process, and style defaults that apply across the portfolio. Override only with a documented reason.

---

#### Plane for Project Management

**Decision:** Use Plane as the project management system across all projects in this portfolio.

**Why Plane specifically:** Plane is fully open source under a license that permits free use, modification, and distribution without fee or permission. It is actively maintained by a team outside this portfolio — we benefit from ongoing improvements without owning the maintenance burden. It is not the most polished PM tool available, but it is solid, actively developed, and ours to use however we need.

The strategic upside: if we ever need full control over the PM layer — to integrate it more deeply with tooling, to fork it, to modify its behavior — someone has already done the foundational engineering work. We are not locked into a vendor and we are not starting from zero.

**What lives in Plane:** Milestones, issues, sprints, code review findings, and pages for key design docs. **What does not:** ephemeral session annotations, scratch work, and anything that lives naturally in source files (AGENTS.md, style guides, plans).

---

#### Open Source and Permissive Licensing as a Default Preference

**Decision:** When choosing tools, infrastructure, and dependencies, prefer open source with permissive licenses over proprietary alternatives, all else being equal.

**Why:** Vendor lock-in is a long-term cost that is invisible at the start of a project and painful at the end. Open source tools can be forked, self-hosted, modified, and used without recurring fees or permission. When a proprietary tool is clearly superior for a specific capability, use it — but document why and note the lock-in risk.

---

#### UI Element Naming Convention

**Decision:** Every interactive UI element is a named computed property following the `[dataObject][property][ElementType]` pattern. Every ViewModel exposes `uiElementContext`.

**Why:** Named elements are grep-able, referable in natural language, and inspectable by AI agents. Anonymous inline controls are invisible to tooling and create a gap between what the code says and what the AI can reason about. This convention exists because the AI needs to be able to say "the clientNameSearchField" and find it, and the human needs to be able to say "that search field at the top" and have the AI know exactly what they mean.

The full convention and suffix list is in `AGENTS.md` and `Style Guide/Unified Standards.md`. This entry explains why it's a first-class rule rather than a style preference.

---

#### Centralized Logging Architecture

**Decision:** All logging goes through the project's centralized logging facade (e.g., `AppLog`). Never use `print()` or raw logging APIs.

**Why:** Raw `print()` statements are invisible to structured log viewers, cannot be filtered by category or level, and leak into production builds. The 9-file fan-out logging architecture (facade → multiple sinks → error log) exists because developer observation of a running system requires structured, filterable, searchable output — not a stream of undifferentiated strings. The architecture spec is in `Style Guide/platform-notes/Apple Apps.md`.

---

#### Automated Style Check in Build Pipeline

**Decision:** Every Apple app target includes a `Style Check` Run Script build phase that executes `scripts/style_check.sh`.

**Why:** Style and naming checks need to run continuously, not only during ad-hoc reviews. Wiring the check into the build gives immediate feedback in Xcode, keeps conventions visible for humans and AI agents, and reduces drift between style guide intent and actual code.

**Implementation note:** Use non-strict mode (`STYLE_CHECK_STRICT=0`) during active refactor periods and strict mode (`STYLE_CHECK_STRICT=1`) in CI or when hard enforcement is desired.

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
