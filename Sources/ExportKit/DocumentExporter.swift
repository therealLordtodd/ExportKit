import Foundation
import UniformTypeIdentifiers

public protocol DocumentExporter: Sendable {
    var formatID: String { get }
    var fileExtension: String { get }
    var utType: UTType { get }
    func export(_ document: ExportableDocument, options: ExportOptions) async throws -> Data
}
