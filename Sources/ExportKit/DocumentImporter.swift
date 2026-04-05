import Foundation
import UniformTypeIdentifiers

public protocol DocumentImporter: Sendable {
    var supportedTypes: [UTType] { get }
    func canImport(_ data: Data) -> Bool
    func importDocument(_ data: Data, options: ImportOptions) async throws -> ImportedDocument
}
