//
//  String++.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

extension String {
    var isEmptyOrWhitespace: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true
    }

    func delimited(by character: Character) -> String {
        "\(character)\(self)\(character)"
    }

    static func concatenate(
        separator: String,
        @_SpecializedArrayBuilder<String> _ strings: () throws -> [String]
    ) rethrows -> Self {
        try strings().joined(separator: separator)
    }

    var firstCharacterCapitalized: String {
        prefix(1).capitalized + dropFirst()
    }

    func hasPrefix(_ prefix: String, caseInsensitive: Bool) -> Bool {
        if caseInsensitive {
            return range(of: prefix, options: [.anchored, .caseInsensitive]) != nil
        } else {
            return hasPrefix(prefix)
        }
    }

    func numberOfOccurences(of character: Character) -> Int {
        lazy.filter({ $0 == character }).count
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + String(dropFirst())
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    mutating func replaceSubstring(
        _ substring: Substring,
        with replacement: String
    ) {
        replaceSubrange(substring.bounds, with: replacement)
    }

    mutating func replace<String: StringProtocol>(
        occurencesOf target: String,
        with string: String
    ) {
        self = replacingOccurrences(of: target, with: string, options: .literal, range: nil)
    }

    mutating func replace<String: StringProtocol>(
        firstOccurenceOf target: String,
        with string: String
    ) {
        guard let range = range(of: target, options: .literal) else {
            return
        }

        replaceSubrange(range, with: string)
    }

    func droppingPrefix(_ prefix: String) -> String
    {
        guard hasPrefix(prefix)
        else { return self }

        return String(self[prefix.endIndex...])
    }

    var lines: [String]
    {
        components(separatedBy: .newlines)
    }

    enum LineEndingStyle: String
    {
        case crlf
        case lf
        case unknown

        var string: String
        {
            switch self
            {
            case .crlf: return "\r\n"
            case .lf:   return "\n"
            case .unknown: return "\n"
            }
        }
    }

    var lineEndingStyle: LineEndingStyle
    {
        if range(of: "\r\n") != nil {
            return .crlf
        }
        if range(of: "\n") != nil {
            return .lf
        }
        return .unknown
    }
}

infix operator +/ : AdditionPrecedence

extension String
{
    static func +/ (left: String, right: String) -> String
    {
        let right = right.droppingPrefix("/")

        if left.hasSuffix("/") {
            return left + right
        }
        else {
            return "\(left)/\(right)"
        }
    }
}

extension String {
    var hash: Hash {
        generateHash(self)
    }
}
