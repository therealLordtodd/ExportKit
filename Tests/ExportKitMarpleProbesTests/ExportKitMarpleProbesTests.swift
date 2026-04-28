import Foundation
import MarpleCore
import Testing
import ExportKit
@testable import ExportKitMarpleProbes

@Suite("ExportKitMarpleProbes")
struct ExportKitMarpleProbesTests {

    private func makeHost() -> ExportKitProbeHost {
        ExportKitProbeHost(registry: ExportRegistry())
    }

    @Test("Registry probe passes against a fresh host")
    func registryProbePasses() async throws {
        let probe = ExportKitRegistryProbe()
        let result = try await probe.run(host: makeHost())
        #expect(result.outcome == .passed)
        #expect(result.probeName == "export-kit.registry")
        for assertion in result.assertions {
            #expect(assertion.passed, "Assertion failed: \(assertion.description) — \(assertion.detail ?? "")")
        }
    }

    @Test("Round-trip probe passes against a fresh host")
    func roundTripProbePasses() async throws {
        let probe = ExportKitRoundTripProbe()
        let result = try await probe.run(host: makeHost())
        #expect(result.outcome == .passed)
        #expect(result.probeName == "export-kit.round-trip")
        for assertion in result.assertions {
            #expect(assertion.passed, "Assertion failed: \(assertion.description) — \(assertion.detail ?? "")")
        }
    }

    @Test("Import-warnings probe passes against a fresh host")
    func importWarningsProbePasses() async throws {
        let probe = ExportKitImportWarningsProbe()
        let result = try await probe.run(host: makeHost())
        #expect(result.outcome == .passed)
        #expect(result.probeName == "export-kit.import-warnings")
        for assertion in result.assertions {
            #expect(assertion.passed, "Assertion failed: \(assertion.description) — \(assertion.detail ?? "")")
        }
    }

    @Test("runAll executes the three probes in declared order")
    func runAllReturnsThreeResults() async throws {
        let results = try await ExportKitMarpleProbes.runAll(host: makeHost())
        #expect(results.count == 3)
        #expect(results.map(\.probeName) == [
            "export-kit.registry",
            "export-kit.round-trip",
            "export-kit.import-warnings",
        ])
        #expect(results.allSatisfy { $0.outcome == .passed })
    }

    @Test("Probe budgets are reasonable (≤ 5 seconds each)")
    func probeBudgetsBounded() {
        #expect(ExportKitRegistryProbe().budget.timeout <= .seconds(5))
        #expect(ExportKitRoundTripProbe().budget.timeout <= .seconds(5))
        #expect(ExportKitImportWarningsProbe().budget.timeout <= .seconds(5))
    }
}
