# ExportKit — Document Editor Family Membership

This primitive is a member of the Document Editor primitive family. It is the **canonical owner of the Exporter protocol** — the format-agnostic export/import protocol layer used by document-style and other content-authoring primitives.

## Conventions This Primitive Participates In

- [x] [shared-types](../CONVENTIONS/shared-types-convention.md) — **canonical owner** of Exporter protocol
- [ ] [typed-static-constants](../CONVENTIONS/typed-static-constants-convention.md) — not participating
- [x] [document-editor-family-membership](../CONVENTIONS/document-editor-family-membership.md)

## Shared Types This Primitive Defines

- **Exporter protocol** — format-agnostic export/import contract
- Exporter registries / lookup surface
- Consumed by: `DocumentPrimitive`, `RichTextEditorKit`, hosts that register exporters

## Shared Types This Primitive Imports

- (none from the family — Foundation only)

## Siblings That Hard-Depend on This Primitive

- `DocumentPrimitive` — uses ExportKit for document export/import
- `RichTextEditorKit` — re-exports export surface

## Ripple-Analysis Checklist Before Modifying Public API

1. **Exporter protocol changes are HIGH-RIPPLE** — affects DocumentPrimitive, RichTextEditorKit, and every host-registered exporter (file-format exporters, print exporters, etc.).
2. Changes to the registration / lookup model: affects every place where hosts wire up exporters at startup.
3. Adding new protocol requirements without default implementations: breaks existing exporters; use default impls.
4. Consult [dependency audit §5](../RichTextEditorKit/docs/plans/2026-04-19-document-editor-dependency-audit.md).
5. Document ripple impact in the commit/PR.

## Note — Potentially Consumed Outside the Family

ExportKit is conceptually general-purpose (export/import for any document-style content). It's currently deeply integrated with DocumentPrimitive and assigned to the Document Editor family for that reason. If future consumers outside the document-editor stack adopt ExportKit (e.g., todo/PM export, calendar export, grid export), consider whether ExportKit graduates to "shared infra predating TodoEmpire/DocumentEditor" or stays in the DocumentEditor family with broader consumers documented here.

## Scope of Membership

Applies to modifications of ExportKit's own code. Consumers just importing for their own app are unaffected.
