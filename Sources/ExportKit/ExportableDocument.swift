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
    public var type: ExportBlockType
    public var content: ExportBlockContent

    public init(
        id: UUID = UUID(),
        type: ExportBlockType,
        content: ExportBlockContent
    ) {
        self.id = id
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
    case table(rows: [[ExportTextContent]])
    case image(data: Data?, url: URL?, altText: String?)
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

public struct ExportableDocument: Sendable {
    public var blocks: [ExportBlock]
    public var metadata: DocumentMetadata
    public var images: [UUID: Data]

    public init(
        blocks: [ExportBlock],
        metadata: DocumentMetadata,
        images: [UUID: Data] = [:]
    ) {
        self.blocks = blocks
        self.metadata = metadata
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
