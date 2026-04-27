import AISeamsKit
import ExportKit

/// AI surface exposing export job management and format discovery.
///
/// ExportKit is a protocol-and-model package with no view model state.
/// This surface wraps an ``ExportRegistry`` for format discovery and
/// exposes callback-driven export/cancel operations that the host app
/// wires to its own job management layer.
public struct ExportAISurface: AISurface, Sendable {

    // MARK: - State backing

    /// The registry used to discover available export formats.
    public var registry: ExportRegistry

    /// Number of currently active export jobs.
    public var activeJobCount: Int

    /// Status description of the last completed or failed export.
    public var lastExportStatus: String?

    // MARK: - Job descriptor

    /// Lightweight snapshot of an active export job for AI consumption.
    public struct JobDescriptor: Sendable {
        public let id: String
        public let format: String
        public let destination: String
        public let status: String

        public init(id: String, format: String, destination: String, status: String) {
            self.id = id
            self.format = format
            self.destination = destination
            self.status = status
        }
    }

    /// Descriptors for currently active export jobs.
    public var activeJobs: [JobDescriptor]

    // MARK: - Callbacks

    /// Handler for starting an export. Receives (format, destination).
    public var onStartExport: @Sendable (String, String) async throws -> Void

    /// Handler for cancelling the current export.
    public var onCancelExport: @Sendable () async throws -> Void

    // MARK: - Initialization

    public init(
        registry: ExportRegistry = ExportRegistry(),
        activeJobCount: Int = 0,
        lastExportStatus: String? = nil,
        activeJobs: [JobDescriptor] = [],
        onStartExport: @escaping @Sendable (String, String) async throws -> Void = { _, _ in },
        onCancelExport: @escaping @Sendable () async throws -> Void = {}
    ) {
        self.registry = registry
        self.activeJobCount = activeJobCount
        self.lastExportStatus = lastExportStatus
        self.activeJobs = activeJobs
        self.onStartExport = onStartExport
        self.onCancelExport = onCancelExport
    }

    // MARK: - AISurface

    public var surfaceID: String { "export.jobs" }

    public var surfaceDescription: String {
        "Export job manager — discover formats, start exports, and monitor job status."
    }

    public var surfaceActions: [AIAction] {
        let formats = registry.availableExportFormats

        return [
            // Observe
            AIAction(
                id: "getAvailableFormats",
                description: "List all registered export formats.",
                tier: .observe
            ) { _ in
                AIActionResult.succeeded(data: [
                    "formats": .array(formats.map { .string($0) }),
                    "count": .int(formats.count),
                ])
            },

            AIAction(
                id: "getJobStatus",
                description: "Get status of active export jobs.",
                tier: .observe
            ) { _ in
                let jobValues: [SurfaceValue] = activeJobs.map { job in
                    .object([
                        "id": .string(job.id),
                        "format": .string(job.format),
                        "destination": .string(job.destination),
                        "status": .string(job.status),
                    ])
                }
                return .succeeded(data: [
                    "jobs": .array(jobValues),
                    "activeCount": .int(activeJobCount),
                ])
            },

            // Act
            AIAction(
                id: "startExport",
                description: "Start a new export job with the given format and destination.",
                tier: .act,
                parameters: [
                    AIActionParameter(
                        name: "format",
                        description: "The export format identifier (e.g. pdf, docx, html).",
                        type: .string,
                        required: true
                    ),
                    AIActionParameter(
                        name: "destination",
                        description: "The output file path or URL.",
                        type: .string,
                        required: true
                    ),
                ]
            ) { params in
                guard let format = params["format"]?.stringValue else {
                    return .failed(code: "missing_parameter", message: "Missing required 'format' parameter.")
                }
                guard let destination = params["destination"]?.stringValue else {
                    return .failed(code: "missing_parameter", message: "Missing required 'destination' parameter.")
                }
                guard formats.contains(format) else {
                    return .failed(
                        code: "unknown_format",
                        message: "Unknown format '\(format)'. Available: \(formats.joined(separator: ", "))."
                    )
                }
                try await onStartExport(format, destination)
                return .succeeded()
            },

            AIAction(
                id: "cancelExport",
                description: "Cancel the current export job.",
                tier: .act
            ) { _ in
                guard activeJobCount > 0 else {
                    return .failed(code: "no_active_export", message: "No active export to cancel.")
                }
                try await onCancelExport()
                return .succeeded()
            },
        ]
    }

    public var surfaceState: [String: SurfaceValue] {
        var state: [String: SurfaceValue] = [
            "activeJobCount": .int(activeJobCount),
            "availableFormats": .array(registry.availableExportFormats.map { .string($0) }),
        ]
        if let lastExportStatus {
            state["lastExportStatus"] = .string(lastExportStatus)
        } else {
            state["lastExportStatus"] = .null
        }
        return state
    }

    public var surfaceSchema: [SurfaceStateField]? {
        [
            SurfaceStateField(name: "activeJobCount", description: "Number of currently running export jobs.", type: .int),
            SurfaceStateField(name: "availableFormats", description: "List of registered export format IDs.", type: .array(.string)),
            SurfaceStateField(name: "lastExportStatus", description: "Status of the most recent export, or null.", type: .string),
        ]
    }
}
