import MarpleCore
import ExportKit

/// Module-marker namespace.
public enum ExportKitMarpleProbesModule {}

/// Convenience entry point for running every ExportKit probe in one
/// call against a single host.
///
/// ## Probe order
///
/// `runAll(host:)` runs probes sequentially in this order:
///
/// 1. ``ExportKitRegistryProbe``
/// 2. ``ExportKitRoundTripProbe``
/// 3. ``ExportKitImportWarningsProbe``
///
/// ## Side effects
///
/// All probes are pure: each constructs its own probe-local registry
/// and exporter/importer instances. None mutate `host.registry`.
public enum ExportKitMarpleProbes {
    /// Runs all three ExportKit probes against the supplied host and
    /// returns the results in declared order.
    public static func runAll(host: ExportKitProbeHost) async throws -> [ProbeResult] {
        try await [
            ExportKitRegistryProbe().run(host: host),
            ExportKitRoundTripProbe().run(host: host),
            ExportKitImportWarningsProbe().run(host: host),
        ]
    }
}
