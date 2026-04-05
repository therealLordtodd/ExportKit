import Foundation
import UniformTypeIdentifiers

public final class ExportRegistry: @unchecked Sendable {
    private var exporters: [String: any DocumentExporter] = [:]
    private var importers: [UTType: any DocumentImporter] = [:]
    private let lock = NSLock()

    public init() {}

    public func register(exporter: any DocumentExporter) {
        lock.lock()
        defer { lock.unlock() }
        exporters[exporter.formatID] = exporter
    }

    public func register(importer: any DocumentImporter) {
        lock.lock()
        defer { lock.unlock() }
        for type in importer.supportedTypes {
            importers[type] = importer
        }
    }

    public func exporter(for formatID: String) -> (any DocumentExporter)? {
        lock.lock()
        defer { lock.unlock() }
        return exporters[formatID]
    }

    public func importer(for type: UTType) -> (any DocumentImporter)? {
        lock.lock()
        defer { lock.unlock() }
        return importers[type]
    }

    public var availableExportFormats: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(exporters.keys).sorted()
    }

    public var availableImportTypes: [UTType] {
        lock.lock()
        defer { lock.unlock() }
        return Array(importers.keys)
    }
}
