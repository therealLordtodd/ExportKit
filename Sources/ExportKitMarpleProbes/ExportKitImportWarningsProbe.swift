import Foundation
import MarpleCore
import ExportKit
import UniformTypeIdentifiers

/// Verifies that importer-emitted `ImportWarning` values are surfaced
/// to callers via the `ImportedDocument.warnings` array.
///
/// 1. An importer that returns warnings surfaces them on the imported
///    document.
/// 2. Warning order and content are preserved.
/// 3. `canImport` returns the importer's predicate value (the registry
///    does not call it; it's the consumer's contract).
/// 4. An importer with no warnings yields an empty warnings array.
///
/// ## Side effects
///
/// Constructs probe-local importers. Does not touch `host.registry`.
public struct ExportKitImportWarningsProbe: AppProbe {
    public typealias Host = ExportKitProbeHost

    public let name = "export-kit.import-warnings"
    public let budget = ProbeBudget(timeout: .seconds(5))

    public init() {}

    public func run(host: Host) async throws -> ProbeResult {
        _ = host

        let startedAt = ContinuousClock.now
        var assertions: [ProbeAssertion] = []

        // 1 + 2. Importer surfaces warnings preserving order.
        let warnings = [
            ImportWarning(message: "Unknown block type encountered", context: "block 12"),
            ImportWarning(message: "Image data unavailable", context: "imageURL=https://example.com/x.png"),
            ImportWarning(message: "Footnote anchor missing"),
        ]
        let warningImporter = ProbeImporter(supportedTypes: [.html], warnings: warnings)
        let registry = ExportRegistry()
        registry.register(importer: warningImporter)

        let resolved = registry.importer(for: .html)
        let imported = try await resolved!.importDocument(
            Data("payload".utf8),
            options: ImportOptions(preserveFormatting: true)
        )

        assertions.append(ProbeAssertion(
            description: "Importer warnings surface on the imported document",
            passed: imported.warnings.count == warnings.count,
            detail: "count=\(imported.warnings.count)"
        ))
        assertions.append(ProbeAssertion(
            description: "Warning order and content are preserved",
            passed: imported.warnings == warnings,
            detail: "warnings=\(imported.warnings.map(\.message))"
        ))

        // 3. canImport reflects the importer's predicate.
        let canImportNonEmpty = warningImporter.canImport(Data("x".utf8))
        let canImportEmpty = warningImporter.canImport(Data())
        assertions.append(ProbeAssertion(
            description: "canImport reflects the importer's predicate",
            passed: canImportNonEmpty && !canImportEmpty,
            detail: "nonEmpty=\(canImportNonEmpty) empty=\(canImportEmpty)"
        ))

        // 4. No-warning importer yields empty warnings array.
        let cleanImporter = ProbeImporter(supportedTypes: [.plainText])
        let cleanImported = try await cleanImporter.importDocument(
            Data("x".utf8),
            options: ImportOptions()
        )
        assertions.append(ProbeAssertion(
            description: "Importer with no warnings yields empty warnings array",
            passed: cleanImported.warnings.isEmpty,
            detail: "count=\(cleanImported.warnings.count)"
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
