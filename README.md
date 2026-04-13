# ExportKit

`ExportKit` defines a shared document model plus the protocols needed to export and import that model. It is the foundation layer other packages can build on when they want to support Markdown, HTML, PDF, DOCX, or custom formats without inventing a new document contract each time.

This package is deliberately small. It does not ship concrete format implementations, save panels, UI, or a registry.

## When To Use It

Use `ExportKit` when you want:

- a portable document model that multiple exporters can consume
- one importer/exporter contract across several format-specific packages
- a way to preserve metadata, images, headers, footers, sections, and footnotes in a structured form

Do not use it if you just need one quick file export path and do not expect to share a model across formats.

## What Ships

The package has two main surfaces:

- `DocumentExporter` and `DocumentImporter` protocols
- portable document types like `ExportableDocument`, `ExportBlock`, `ExportTextContent`, `ExportSection`, `DocumentMetadata`, `ImportedDocument`, `ExportOptions`, and `ImportOptions`

The model supports both simple flat documents and paginated/sectioned documents.

## Core Types

| Type | What it does |
| --- | --- |
| `DocumentExporter` | Protocol for exporting an `ExportableDocument` to `Data` |
| `DocumentImporter` | Protocol for importing raw data into an `ImportedDocument` |
| `ExportableDocument` | The top-level document container |
| `ExportBlock` | One content block with type, content, and optional source identifier |
| `ExportBlockContent` | Block variants like text, heading, code block, table, image, and divider |
| `ExportTextContent` | Rich text as a series of runs |
| `ExportTextRun` | One styled text run with flags like bold, italic, code, and link |
| `ExportSection` | Section-aware content for paginated formats |
| `ExportPageTemplate` | Page size, margins, columns, and header/footer dimensions |
| `ExportHeaderFooterConfiguration` | Header/footer content and first-page or odd/even rules |
| `ExportFootnoteConfiguration` | Footnote placement and numbering behavior |
| `ImportedDocument` | Parsed document result plus images and warnings |
| `ImportWarning` | Non-fatal import fidelity warnings |

## Examples

### 1. Build a portable document

```swift
import ExportKit

let document = ExportableDocument(
    blocks: [
        ExportBlock(
            type: .heading,
            content: .heading(.plain("Quarterly Report"), level: 1)
        ),
        ExportBlock(
            type: .paragraph,
            content: .text(.plain("Revenue increased 18% year over year."))
        ),
        ExportBlock(
            type: .codeBlock,
            content: .codeBlock(code: "print(\"hello\")", language: "swift")
        ),
    ],
    metadata: DocumentMetadata(
        title: "Quarterly Report",
        author: "Finance Team",
        keywords: ["finance", "q1"]
    )
)
```

This is the heart of the package: create one structured representation, then let different exporters consume it.

### 2. Implement a simple exporter

```swift
import ExportKit
import UniformTypeIdentifiers

struct PlainTextExporter: DocumentExporter {
    let formatID = "plain-text"
    let fileExtension = "txt"
    let utType = UTType.plainText

    func export(_ document: ExportableDocument, options: ExportOptions) async throws -> Data {
        let body = document.blocks.map { block in
            switch block.content {
            case .text(let content):
                return content.plainText
            case .heading(let content, _):
                return content.plainText
            default:
                return ""
            }
        }
        .joined(separator: "\n\n")

        return Data(body.utf8)
    }
}
```

### 3. Implement a simple importer

```swift
import ExportKit
import UniformTypeIdentifiers

struct PlainTextImporter: DocumentImporter {
    let supportedTypes: [UTType] = [.plainText]

    func canImport(_ data: Data) -> Bool {
        String(data: data, encoding: .utf8) != nil
    }

    func importDocument(_ data: Data, options: ImportOptions) async throws -> ImportedDocument {
        let text = String(decoding: data, as: UTF8.self)

        return ImportedDocument(
            blocks: [
                ExportBlock(type: .paragraph, content: .text(.plain(text)))
            ],
            metadata: DocumentMetadata(title: "Imported Text")
        )
    }
}
```

### 4. Model a paginated document with headers, footers, and footnotes

```swift
import CoreGraphics
import ExportKit

let pageTemplate = ExportPageTemplate(
    size: CGSize(width: 612, height: 792),
    margins: ExportPageMargins(top: 72, leading: 72, bottom: 72, trailing: 72),
    columns: 1,
    headerHeight: 32,
    footerHeight: 32
)

let section = ExportSection(
    blocks: [
        ExportBlock(type: .paragraph, content: .text(.plain("Section content")))
    ],
    pageTemplate: pageTemplate,
    headerFooter: ExportHeaderFooterConfiguration(
        header: ExportHeaderFooter(center: .plain("Report Header")),
        footer: ExportHeaderFooter(right: .plain("Page"))
    )
)

let pagedDocument = ExportableDocument(
    blocks: [],
    metadata: DocumentMetadata(title: "Paged Report"),
    sections: [section],
    footnoteConfiguration: ExportFootnoteConfiguration(
        placement: .pageBottom,
        numberingStyle: .roman,
        restartPerSection: true
    )
)
```

Use sections when the destination format actually understands pages, headers, footers, or section-specific layout.

### 5. Carry inline formatting and links

```swift
let text = ExportTextContent(runs: [
    ExportTextRun(text: "Read the "),
    ExportTextRun(text: "full report", bold: true, link: URL(string: "https://example.com/report")),
    ExportTextRun(text: ".")
])
```

This gives exporters a structured way to render emphasis and links without parsing raw markup strings later.

## Wiring It Into Your App

The clean integration pattern is:

1. Convert your editor or domain model into `ExportableDocument`.
2. Hand that model to one or more concrete exporters implemented in your app or sibling packages.
3. For imports, parse raw data into `ImportedDocument`, then map that back into your app’s source-of-truth model.

Good host-app habits:

- keep `sourceIdentifier` populated when you need to trace exported blocks back to app objects
- use `document.blocks` for simple formats like Markdown or plain text
- use `document.sections` only for paginated formats that genuinely care about page templates and headers/footers
- keep exporter selection and dependency wiring in the host app, since `ExportKit` does not own a registry

The absence of a registry is intentional. It keeps the package focused on contracts and shared structure instead of turning it into a plugin framework before you actually need one.

## Constraints And Notes

- `ExportKit` does not include Markdown, HTML, PDF, or DOCX exporters by itself.
- It does not include UI for exporting or importing.
- Images can be carried inline in block content, in `document.images`, or both, depending on your exporter strategy.
- `ImportedDocument.warnings` is the right place to record partial-fidelity imports instead of hard-failing every time a feature cannot round-trip perfectly.

## Platform Support

- macOS 12+
- iOS 15+
- tvOS 15+
- watchOS 8+
- visionOS 1+
