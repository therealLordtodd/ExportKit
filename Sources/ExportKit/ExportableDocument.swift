import CoreGraphics
import Foundation

public struct DocumentMetadata: Codable, Sendable, Equatable {
    public var title: String
    public var author: String?
    public var subject: String?
    public var keywords: [String]
    public var createdAt: Date?
    public var modifiedAt: Date?

    public init(
        title: String,
        author: String? = nil,
        subject: String? = nil,
        keywords: [String] = [],
        createdAt: Date? = nil,
        modifiedAt: Date? = nil
    ) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

public struct ExportBlock: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var sourceIdentifier: String?
    public var type: ExportBlockType
    public var content: ExportBlockContent

    public init(
        id: UUID = UUID(),
        sourceIdentifier: String? = nil,
        type: ExportBlockType,
        content: ExportBlockContent
    ) {
        self.id = id
        self.sourceIdentifier = sourceIdentifier
        self.type = type
        self.content = content
    }
}

public enum ExportBlockType: String, Codable, Sendable {
    case paragraph
    case heading
    case blockQuote
    case codeBlock
    case list
    case table
    case image
    case divider
}

public enum ExportBlockContent: Codable, Sendable, Equatable {
    case text(ExportTextContent)
    case heading(ExportTextContent, level: Int)
    case blockQuote(ExportTextContent)
    case codeBlock(code: String, language: String?)
    case list(ExportTextContent, ordered: Bool, indentLevel: Int)
    case table(rows: [[ExportTextContent]], columnWidths: [CGFloat]?, caption: ExportTextContent?)
    case image(data: Data?, url: URL?, altText: String?, size: CGSize?)
    case divider
}

public struct ExportTextContent: Codable, Sendable, Equatable {
    public var runs: [ExportTextRun]

    public init(runs: [ExportTextRun]) {
        self.runs = runs
    }

    public static func plain(_ text: String) -> ExportTextContent {
        ExportTextContent(runs: [ExportTextRun(text: text)])
    }

    public var plainText: String {
        runs.map(\.text).joined()
    }
}

public struct ExportTextRun: Codable, Sendable, Equatable {
    public var text: String
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool
    public var code: Bool
    public var link: URL?

    public init(
        text: String,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        code: Bool = false,
        link: URL? = nil
    ) {
        self.text = text
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.code = code
        self.link = link
    }
}

public struct ExportPageMargins: Codable, Sendable, Equatable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat

    public init(
        top: CGFloat,
        leading: CGFloat,
        bottom: CGFloat,
        trailing: CGFloat
    ) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

public struct ExportPageTemplate: Codable, Sendable, Equatable {
    public var size: CGSize
    public var margins: ExportPageMargins
    public var columns: Int
    public var columnSpacing: CGFloat
    public var headerHeight: CGFloat
    public var footerHeight: CGFloat

    public init(
        size: CGSize,
        margins: ExportPageMargins,
        columns: Int = 1,
        columnSpacing: CGFloat = 18,
        headerHeight: CGFloat = 0,
        footerHeight: CGFloat = 0
    ) {
        self.size = size
        self.margins = margins
        self.columns = columns
        self.columnSpacing = columnSpacing
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
    }
}

public struct ExportHeaderFooter: Codable, Sendable, Equatable {
    public var left: ExportTextContent
    public var center: ExportTextContent
    public var right: ExportTextContent

    public init(
        left: ExportTextContent = ExportTextContent(runs: []),
        center: ExportTextContent = ExportTextContent(runs: []),
        right: ExportTextContent = ExportTextContent(runs: [])
    ) {
        self.left = left
        self.center = center
        self.right = right
    }
}

public struct ExportHeaderFooterConfiguration: Codable, Sendable, Equatable {
    public var firstHeader: ExportHeaderFooter?
    public var firstFooter: ExportHeaderFooter?
    public var header: ExportHeaderFooter?
    public var footer: ExportHeaderFooter?
    public var evenHeader: ExportHeaderFooter?
    public var evenFooter: ExportHeaderFooter?
    public var differentFirstPage: Bool
    public var differentOddEven: Bool

    public init(
        firstHeader: ExportHeaderFooter? = nil,
        firstFooter: ExportHeaderFooter? = nil,
        header: ExportHeaderFooter? = nil,
        footer: ExportHeaderFooter? = nil,
        evenHeader: ExportHeaderFooter? = nil,
        evenFooter: ExportHeaderFooter? = nil,
        differentFirstPage: Bool = false,
        differentOddEven: Bool = false
    ) {
        self.firstHeader = firstHeader
        self.firstFooter = firstFooter
        self.header = header
        self.footer = footer
        self.evenHeader = differentOddEven ? (evenHeader ?? header) : evenHeader
        self.evenFooter = differentOddEven ? (evenFooter ?? footer) : evenFooter
        self.differentFirstPage = differentFirstPage
        self.differentOddEven = differentOddEven
    }

    public var hasAnyHeaderContent: Bool {
        firstHeader != nil || header != nil || evenHeader != nil
    }

    public var hasAnyFooterContent: Bool {
        firstFooter != nil || footer != nil || evenFooter != nil
    }

    public func resolvedHeaderFooter(
        pageNumber: Int,
        pageIndexInSection: Int
    ) -> (header: ExportHeaderFooter?, footer: ExportHeaderFooter?) {
        if differentFirstPage, pageIndexInSection == 0 {
            return (firstHeader, firstFooter)
        }

        if differentOddEven, pageNumber.isMultiple(of: 2) {
            return (evenHeader, evenFooter)
        }

        return (header, footer)
    }

    enum CodingKeys: String, CodingKey {
        case firstHeader
        case firstFooter
        case header
        case footer
        case evenHeader
        case evenFooter
        case differentFirstPage
        case differentOddEven
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            firstHeader: try container.decodeIfPresent(ExportHeaderFooter.self, forKey: .firstHeader),
            firstFooter: try container.decodeIfPresent(ExportHeaderFooter.self, forKey: .firstFooter),
            header: try container.decodeIfPresent(ExportHeaderFooter.self, forKey: .header),
            footer: try container.decodeIfPresent(ExportHeaderFooter.self, forKey: .footer),
            evenHeader: try container.decodeIfPresent(ExportHeaderFooter.self, forKey: .evenHeader),
            evenFooter: try container.decodeIfPresent(ExportHeaderFooter.self, forKey: .evenFooter),
            differentFirstPage: try container.decodeIfPresent(Bool.self, forKey: .differentFirstPage) ?? false,
            differentOddEven: try container.decodeIfPresent(Bool.self, forKey: .differentOddEven) ?? false
        )
    }
}

public enum ExportFootnotePlacement: String, Codable, Sendable, Equatable {
    case pageBottom
    case sectionEnd
    case documentEnd
}

public enum ExportNumberingStyle: String, Codable, Sendable, Equatable {
    case arabic
    case roman
    case alpha
    case symbol

    public func render(number: Int) -> String {
        switch self {
        case .arabic:
            return String(number)
        case .roman:
            return roman(number)
        case .alpha:
            return alpha(number)
        case .symbol:
            let symbols = ["*", "†", "‡", "§", "¶"]
            return symbols[(max(number, 1) - 1) % symbols.count]
        }
    }

    private func alpha(_ number: Int) -> String {
        guard number > 0 else { return "a" }
        let scalar = UnicodeScalar(((number - 1) % 26) + 65)!
        return String(Character(scalar)).lowercased()
    }

    private func roman(_ number: Int) -> String {
        guard number > 0 else { return "I" }
        let values: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
        ]
        var remainder = number
        var result = ""
        for (value, symbol) in values {
            while remainder >= value {
                result += symbol
                remainder -= value
            }
        }
        return result
    }
}

public struct ExportFootnoteConfiguration: Codable, Sendable, Equatable {
    public var placement: ExportFootnotePlacement
    public var numberingStyle: ExportNumberingStyle
    public var restartPerSection: Bool

    public init(
        placement: ExportFootnotePlacement = .pageBottom,
        numberingStyle: ExportNumberingStyle = .arabic,
        restartPerSection: Bool = true
    ) {
        self.placement = placement
        self.numberingStyle = numberingStyle
        self.restartPerSection = restartPerSection
    }
}

public struct ExportFootnote: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var anchorSourceIdentifier: String
    public var content: ExportTextContent

    public init(
        id: UUID = UUID(),
        anchorSourceIdentifier: String,
        content: ExportTextContent
    ) {
        self.id = id
        self.anchorSourceIdentifier = anchorSourceIdentifier
        self.content = content
    }
}

public struct ExportSection: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var blocks: [ExportBlock]
    public var pageTemplate: ExportPageTemplate
    public var headerFooter: ExportHeaderFooterConfiguration?
    public var footnotes: [ExportFootnote]
    public var startPageNumber: Int?

    public init(
        id: UUID = UUID(),
        blocks: [ExportBlock],
        pageTemplate: ExportPageTemplate,
        headerFooter: ExportHeaderFooterConfiguration? = nil,
        footnotes: [ExportFootnote] = [],
        startPageNumber: Int? = nil
    ) {
        self.id = id
        self.blocks = blocks
        self.pageTemplate = pageTemplate
        self.headerFooter = headerFooter
        self.footnotes = footnotes
        self.startPageNumber = startPageNumber
    }
}

public struct ExportableDocument: Sendable {
    public var blocks: [ExportBlock]
    public var metadata: DocumentMetadata
    public var sections: [ExportSection]
    public var footnoteConfiguration: ExportFootnoteConfiguration?
    public var images: [UUID: Data]

    public init(
        blocks: [ExportBlock],
        metadata: DocumentMetadata,
        sections: [ExportSection] = [],
        footnoteConfiguration: ExportFootnoteConfiguration? = nil,
        images: [UUID: Data] = [:]
    ) {
        self.blocks = blocks
        self.metadata = metadata
        self.sections = sections
        self.footnoteConfiguration = footnoteConfiguration
        self.images = images
    }
}

public struct ImportedDocument: Sendable {
    public var blocks: [ExportBlock]
    public var metadata: DocumentMetadata
    public var images: [UUID: Data]
    public var warnings: [ImportWarning]

    public init(
        blocks: [ExportBlock],
        metadata: DocumentMetadata,
        images: [UUID: Data] = [:],
        warnings: [ImportWarning] = []
    ) {
        self.blocks = blocks
        self.metadata = metadata
        self.images = images
        self.warnings = warnings
    }
}

public struct ImportWarning: Sendable, Equatable {
    public var message: String
    public var context: String?

    public init(message: String, context: String? = nil) {
        self.message = message
        self.context = context
    }
}

public struct ExportOptions: Sendable, Equatable {
    public var includeMetadata: Bool
    public var imageQuality: Double

    public init(includeMetadata: Bool = true, imageQuality: Double = 0.8) {
        self.includeMetadata = includeMetadata
        self.imageQuality = imageQuality
    }
}

public struct ImportOptions: Sendable, Equatable {
    public var preserveFormatting: Bool

    public init(preserveFormatting: Bool = true) {
        self.preserveFormatting = preserveFormatting
    }
}
