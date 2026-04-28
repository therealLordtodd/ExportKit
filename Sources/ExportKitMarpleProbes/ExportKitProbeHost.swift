import Foundation
import ExportKit

/// The dependency bundle every ExportKit Marple probe runs against.
///
/// `ExportRegistry` is `Sendable` (`@unchecked Sendable` with internal
/// locking), so the host is `Sendable` too. Probes typically construct
/// their own probe-local registry to avoid cross-probe contamination.
public struct ExportKitProbeHost: Sendable {
    /// The registry under test. Probes typically construct their own
    /// registry internally, but the host's registry is exposed here so
    /// probes that inspect host wiring can reference it.
    public let registry: ExportRegistry

    public init(registry: ExportRegistry) {
        self.registry = registry
    }
}
