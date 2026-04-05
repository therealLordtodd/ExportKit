import CoreGraphics
import Foundation
import Testing
@testable import ExportKit

@Suite("ExportKit Model Tests")
struct ModelTests {
    @Test func documentMetadataCodableRoundTrip() throws {
        let metadata = DocumentMetadata(title: "Test Doc", author: "Todd", keywords: ["swift", "test"])
        let data = try JSONEncoder().encode(metadata)
        let decoded = try JSONDecoder().decode(DocumentMetadata.self, from: data)
        #expect(decoded == metadata)
    }

    @Test func exportTextContentPlain() {
        let content = ExportTextContent.plain("Hello world")
        #expect(content.plainText == "Hello world")
        #expect(content.runs.count == 1)
    }

    @Test func exportTextRunDefaults() {
        let run = ExportTextRun(text: "plain")
        #expect(run.bold == false)
        #expect(run.italic == false)
        #expect(run.link == nil)
    }

    @Test func exportBlockCodableRoundTrip() throws {
        let block = ExportBlock(
            type: .table,
            content: .table(
                rows: [[.plain("Q1"), .plain("Q2")]],
                columnWidths: [160, 120],
                caption: .plain("Quarterly Results")
            )
        )
        let data = try JSONEncoder().encode(block)
        let decoded = try JSONDecoder().decode(ExportBlock.self, from: data)
        #expect(decoded == block)
    }

    @Test func exportImageBlockPreservesDeclaredSize() throws {
        let block = ExportBlock(
            type: .image,
            content: .image(
                data: Data([0x89, 0x50, 0x4E, 0x47]),
                url: nil,
                altText: "Chart",
                size: CGSize(width: 320, height: 180)
            )
        )
        let data = try JSONEncoder().encode(block)
        let decoded = try JSONDecoder().decode(ExportBlock.self, from: data)
        #expect(decoded == block)
    }

    @Test func exportBlockTypeRawValues() {
        #expect(ExportBlockType.paragraph.rawValue == "paragraph")
        #expect(ExportBlockType.codeBlock.rawValue == "codeBlock")
    }

    @Test func importWarningStoresContext() {
        let warning = ImportWarning(message: "Lost formatting", context: "Table cell B2")
        #expect(warning.message == "Lost formatting")
        #expect(warning.context == "Table cell B2")
    }

    @Test func exportFootnoteConfigurationCodableRoundTrip() throws {
        let configuration = ExportFootnoteConfiguration(
            placement: .documentEnd,
            numberingStyle: .roman,
            restartPerSection: false
        )
        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(ExportFootnoteConfiguration.self, from: data)
        #expect(decoded == configuration)
        #expect(decoded.numberingStyle.render(number: 4) == "IV")
    }
}
