import Foundation
import MarpleCore
import ExportKit
import UniformTypeIdentifiers

/// Verifies the exporter → importer round-trip contract on a stable
/// fixture document.
///
/// 1. A registered exporter exports the fixture without throwing.
/// 2. The matching registered importer imports the resulting payload
///    without throwing.
/// 3. The round-tripped document preserves block count and metadata
///    title (the basic identity contract).
/// 4. `ExportOptions` are surfaced to the exporter (verified via the
///    probe exporter's payload).
///
/// ## Side effects
///
/// Constructs a probe-local `ExportRegistry` with `ProbeExporter` /
/// `ProbeImporter`. Does not touch `host.registry`.
public struct ExportKitRoundTripProbe: AppProbe {
    public typealias Host = ExportKitProbeHost

    public let name = "export-kit.round-trip"
    public let budget = ProbeBudget(timeout: .seconds(5))

    public init() {}

    public func run(host: Host) async throws -> ProbeResult {
        _ = host

        let startedAt = ContinuousClock.now
        var assertions: [ProbeAssertion] = []

        let registry = ExportRegistry()
        let exporter = ProbeExporter(formatID: "probe-fmt", fileExtension: "pf", utType: .data)
        let importer = ProbeImporter(supportedTypes: [.data])
        registry.register(exporter: exporter)
        registry.register(importer: importer)

        let fixture = ExportableDocument(
            blocks: [
                ExportBlock(
                    type: .heading,
                    content: .heading(.plain("Probe Fixture"), level: 1)
                ),
                ExportBlock(
                    type: .paragraph,
                    content: .text(.plain("Round-trip probe paragraph."))
                ),
                ExportBlock(
                    type: .codeBlock,
                    content: .codeBlock(code: "let x = 1", language: "swift")
                ),
            ],
            metadata: DocumentMetadata(title: "Probe Document", author: "MarpleProbe")
        )

        // 1. Resolve and run the exporter.
        guard let resolvedExporter = registry.exporter(for: "probe-fmt") else {
            assertions.append(ProbeAssertion(
                description: "Registered exporter resolves by formatID",
                passed: false,
                detail: "exporter resolution returned nil"
            ))
            return ProbeResult(
                probeName: name,
                outcome: .failed,
                assertions: assertions,
                duration: startedAt.duration(to: .now)
            )
        }
        let exportOptions = ExportOptions(includeMetadata: true, imageQuality: 0.42)
        let exported = try await resolvedExporter.export(fixture, options: exportOptions)
        assertions.append(ProbeAssertion(
            description: "Exporter produces non-empty output for the fixture",
            passed: !exported.isEmpty,
            detail: "exportedBytes=\(exported.count)"
        ))

        // 2. Resolve and run the matching importer.
        guard let resolvedImporter = registry.importer(for: .data) else {
            assertions.append(ProbeAssertion(
                description: "Registered importer resolves by UTType",
                passed: false,
                detail: "importer resolution returned nil"
            ))
            return ProbeResult(
                probeName: name,
                outcome: .failed,
                assertions: assertions,
                duration: startedAt.duration(to: .now)
            )
        }
        let imported = try await resolvedImporter.importDocument(
            exported,
            options: ImportOptions(preserveFormatting: true)
        )

        // 3. Round-trip preserves block count and metadata title.
        assertions.append(ProbeAssertion(
            description: "Round-trip preserves block count and metadata title",
            passed: imported.blocks.count == fixture.blocks.count
                && imported.metadata.title == fixture.metadata.title,
            detail: "blocks=\(imported.blocks.count)/\(fixture.blocks.count) title=\(imported.metadata.title)"
        ))

        // 4. ExportOptions are surfaced through to the exporter — decode
        //    the payload and check the imageQuality round-tripped.
        let decoded = try JSONDecoder().decode(ProbeExportPayload.self, from: exported)
        assertions.append(ProbeAssertion(
            description: "ExportOptions surface to the exporter",
            passed: decoded.options.imageQuality == 0.42 && decoded.options.includeMetadata,
            detail: "options=\(decoded.options)"
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
