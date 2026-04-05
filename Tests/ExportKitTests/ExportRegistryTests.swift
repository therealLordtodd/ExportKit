import Foundation
import Testing
import UniformTypeIdentifiers
@testable import ExportKit

struct MockExporter: DocumentExporter {
    let formatID: String
    let fileExtension: String
    let utType: UTType

    func export(_ document: ExportableDocument, options: ExportOptions) async throws -> Data {
        Data()
    }
}

struct MockImporter: DocumentImporter {
    let supportedTypes: [UTType]

    func canImport(_ data: Data) -> Bool { true }

    func importDocument(_ data: Data, options: ImportOptions) async throws -> ImportedDocument {
        ImportedDocument(blocks: [], metadata: DocumentMetadata(title: "Imported"))
    }
}

@Suite("ExportRegistry Tests")
struct ExportRegistryTests {
    @Test func registerAndRetrieveExporter() {
        let registry = ExportRegistry()
        let exporter = MockExporter(formatID: "markdown", fileExtension: "md", utType: .plainText)
        registry.register(exporter: exporter)
        #expect(registry.exporter(for: "markdown") != nil)
        #expect(registry.exporter(for: "html") == nil)
    }

    @Test func registerAndRetrieveImporter() {
        let registry = ExportRegistry()
        let importer = MockImporter(supportedTypes: [.html])
        registry.register(importer: importer)
        #expect(registry.importer(for: .html) != nil)
        #expect(registry.importer(for: .pdf) == nil)
    }

    @Test func availableFormats() {
        let registry = ExportRegistry()
        registry.register(exporter: MockExporter(formatID: "html", fileExtension: "html", utType: .html))
        registry.register(exporter: MockExporter(formatID: "markdown", fileExtension: "md", utType: .plainText))
        let formats = registry.availableExportFormats
        #expect(formats.count == 2)
        #expect(formats.contains("html"))
        #expect(formats.contains("markdown"))
    }
}
