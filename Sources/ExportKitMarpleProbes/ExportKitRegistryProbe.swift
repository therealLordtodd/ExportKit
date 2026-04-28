import Foundation
import MarpleCore
import ExportKit
import UniformTypeIdentifiers

/// Verifies the `ExportRegistry` lookup contract:
///
/// 1. Registering an exporter makes it discoverable via
///    `exporter(for: formatID)` and listed by `availableExportFormats`.
/// 2. Re-registering an exporter under the same formatID replaces the
///    prior entry without growing the registered count.
/// 3. Importers register against multiple `UTType`s and become
///    discoverable via `importer(for:)` for each declared type.
/// 4. `availableExportFormats` returns sorted unique format ids.
///
/// ## Side effects
///
/// Constructs a probe-local `ExportRegistry`. Does not touch
/// `host.registry`.
public struct ExportKitRegistryProbe: AppProbe {
    public typealias Host = ExportKitProbeHost

    public let name = "export-kit.registry"
    public let budget = ProbeBudget(timeout: .seconds(5))

    public init() {}

    public func run(host: Host) async throws -> ProbeResult {
        _ = host

        let startedAt = ContinuousClock.now
        var assertions: [ProbeAssertion] = []

        let registry = ExportRegistry()
        let markdown = ProbeExporter(formatID: "markdown", fileExtension: "md", utType: .plainText)
        let html = ProbeExporter(formatID: "html", fileExtension: "html", utType: .html)
        registry.register(exporter: markdown)
        registry.register(exporter: html)

        // 1. Registered exporters are discoverable.
        let markdownLookup = registry.exporter(for: "markdown")
        let unknownLookup = registry.exporter(for: "doesnotexist")
        assertions.append(ProbeAssertion(
            description: "Registered exporter is discoverable by formatID; unknown returns nil",
            passed: markdownLookup != nil && unknownLookup == nil,
            detail: "markdown=\(markdownLookup != nil) unknown=\(unknownLookup != nil)"
        ))

        // 2. Re-registering replaces in place.
        let markdownReplacement = ProbeExporter(formatID: "markdown", fileExtension: "markdown", utType: .text)
        registry.register(exporter: markdownReplacement)
        let formatsAfterReplace = registry.availableExportFormats.sorted()
        assertions.append(ProbeAssertion(
            description: "Re-registering an exporter under the same formatID replaces in place",
            passed: formatsAfterReplace == ["html", "markdown"]
                && (registry.exporter(for: "markdown") as? ProbeExporter)?.fileExtension == "markdown",
            detail: "formats=\(formatsAfterReplace)"
        ))

        // 3. Importers register against multiple UTTypes.
        let importer = ProbeImporter(supportedTypes: [.html, .rtf])
        registry.register(importer: importer)
        let htmlImporter = registry.importer(for: .html)
        let rtfImporter = registry.importer(for: .rtf)
        let pdfImporter = registry.importer(for: .pdf)
        assertions.append(ProbeAssertion(
            description: "Importer registers against every declared UTType",
            passed: htmlImporter != nil && rtfImporter != nil && pdfImporter == nil,
            detail: "html=\(htmlImporter != nil) rtf=\(rtfImporter != nil) pdf=\(pdfImporter != nil)"
        ))

        // 4. availableExportFormats returns sorted ids.
        let plain = ProbeExporter(formatID: "plain", fileExtension: "txt", utType: .plainText)
        registry.register(exporter: plain)
        let sortedFormats = registry.availableExportFormats
        assertions.append(ProbeAssertion(
            description: "availableExportFormats returns ids in sorted order",
            passed: sortedFormats == sortedFormats.sorted() && Set(sortedFormats).count == sortedFormats.count,
            detail: "formats=\(sortedFormats)"
        ))

        let outcome: ProbeOutcome = assertions.allSatisfy(\.passed) ? .passed : .failed
        return ProbeResult(
            probeName: name,
            outcome: outcome,
            assertions: assertions,
            duration: startedAt.duration(to: .now)
        )
    }
}

/// A small probe-only exporter that records calls and returns the
/// document round-tripped through JSON-encoded blocks. Suitable for
/// asserting the exporter contract without depending on a real format.
internal struct ProbeExporter: DocumentExporter {
    let formatID: String
    let fileExtension: String
    let utType: UTType

    func export(_ document: ExportableDocument, options: ExportOptions) async throws -> Data {
        let payload = ProbeExportPayload(
            formatID: formatID,
            metadata: document.metadata,
            blocks: document.blocks,
            options: ProbeExportOptions(
                includeMetadata: options.includeMetadata,
                imageQuality: options.imageQuality
            )
        )
        return try JSONEncoder().encode(payload)
    }
}

internal struct ProbeImporter: DocumentImporter {
    let supportedTypes: [UTType]
    let warnings: [ImportWarning]

    init(supportedTypes: [UTType], warnings: [ImportWarning] = []) {
        self.supportedTypes = supportedTypes
        self.warnings = warnings
    }

    func canImport(_ data: Data) -> Bool { !data.isEmpty }

    func importDocument(_ data: Data, options: ImportOptions) async throws -> ImportedDocument {
        if let payload = try? JSONDecoder().decode(ProbeExportPayload.self, from: data) {
            return ImportedDocument(
                blocks: payload.blocks,
                metadata: payload.metadata,
                images: [:],
                warnings: warnings
            )
        }
        return ImportedDocument(
            blocks: [],
            metadata: DocumentMetadata(title: "Imported"),
            warnings: warnings
        )
    }
}

internal struct ProbeExportPayload: Codable {
    let formatID: String
    let metadata: DocumentMetadata
    let blocks: [ExportBlock]
    let options: ProbeExportOptions
}

internal struct ProbeExportOptions: Codable {
    let includeMetadata: Bool
    let imageQuality: Double
}
