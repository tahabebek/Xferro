//
//  SourceCodeLocation.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

public enum SourceCodeLocation: Codable, Hashable, SourceCodeLocationInitiable, Sendable {
    case regular(file: String, line: UInt)
    case exact(Preprocessor.Point)
    case unavailable
}

extension SourceCodeLocation {
     var file: String? {
        switch self {
        case .regular(let file, _):
            return file
        case .exact(let point):
            return point.file
        case .unavailable:
            return nil
        }
    }

     var function: String? {
        switch self {
        case .regular(_, _):
            return nil
        case .exact(let point):
            return point.function
        case .unavailable:
            return nil
        }
    }

     var line: UInt? {
        switch self {
        case .regular(_, let line):
            return line
        case .exact(let point):
            return point.line
        case .unavailable:
            return nil
        }
    }

     var column: UInt? {
        switch self {
        case .regular(_, _):
            return nil
        case .exact(let point):
            return point.column
        case .unavailable:
            return nil
        }
    }
}

extension SourceCodeLocation {
     func drop(_ field: Preprocessor.Point.CodingKeys) -> Self {
        switch self {
        case .regular:
            fatalError()
        case .exact(let point):
            return .exact(point.drop(field))
        case .unavailable:
            return self
        }
    }
}

public extension SourceCodeLocation {
     init(_ point: Preprocessor.Point) {
        self = .exact(point)
    }

     init(_ location: SourceCodeLocation) {
        self = location
    }

     init(
        file: StaticString,
        fileID: StaticString? = nil,
        function: StaticString,
        line: UInt,
        column: UInt?
    ) {
        self.init(
            Preprocessor.Point(
                file: file,
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

     init(
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) {
        self.init(
            file: fileID,
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

     init(
        file: String,
        fileID: String? = nil,
        function: String,
        line: UInt,
        column: UInt?
    ) {
        self.init(
            Preprocessor.Point(
                file: file,
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

// MARK: - Conformances

extension SourceCodeLocation: CustomStringConvertible {
     public var description: String {
        switch self {
        case let .regular(file, line):
            return "file: \(file), line: \(line)"
        case let .exact(point):
            return point.description
        case .unavailable:
            return "<unavailable>"
        }
    }
}

// MARK: - Auxiliary

 protocol SourceCodeLocationInitiable {
    init(_ location: SourceCodeLocation)
}

extension SourceCodeLocationInitiable {
     init(
        file: StaticString,
        fileID: StaticString? = nil,
        function: StaticString,
        line: UInt,
        column: UInt?
    ) {
        self.init(
            SourceCodeLocation(
                file: file,
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

     init(
        file: String,
        fileID: String? = nil,
        function: String,
        line: UInt,
        column: UInt?
    ) {
        self.init(
            SourceCodeLocation(
                file: file,
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}
