# ExportKit

ExportKit provides the common document export/import contracts and a portable export model for downstream format implementations.

## Quick Start

```swift
import ExportKit
import UniformTypeIdentifiers

struct PlainTextExporter: DocumentExporter {
    let formatID = "plain-text"
    let fileExtension = "txt"
    let utType = UTType.plainText

    func export(_ document: ExportableDocument, options: ExportOptions) async throws -> Data {
        document.blocks
            .map { block in
                if case let .text(text) = block.content {
                    return text.plainText
                }
                return ""
            }
            .joined(separator: "\n")
            .data(using: .utf8) ?? Data()
    }
}

let registry = ExportRegistry()
registry.register(exporter: PlainTextExporter())
let exporter = registry.exporter(for: "plain-text")
```

## Key Types
- `DocumentExporter`: Async export protocol returning `Data`.
- `DocumentImporter`: Async import protocol returning `ImportedDocument`.
- `ExportRegistry`: Thread-safe registry for exporters and importers.
- `ExportableDocument`: Metadata, flat blocks, optional sections, footnote configuration, and image data.
- `ExportSection`: Section blocks, page template, header/footer configuration, footnotes, and start page number.
- `ExportBlock`, `ExportBlockContent`, `ExportTextContent`, and `ExportTextRun`: Portable block and text model.
- `ExportOptions` and `ImportOptions`: Format-independent options.

## Common Operations
- Register exporters by stable `formatID`.
- Use `ExportHeaderFooterConfiguration.resolvedHeaderFooter(pageNumber:pageIndexInSection:)` when rendering page chrome.
- Use `ExportNumberingStyle.render(number:)` for footnote and page-related numbering.
- Put binary image data in `ExportableDocument.images` and refer to IDs from image blocks.

## Testing

Run:

```bash
swift test
```
