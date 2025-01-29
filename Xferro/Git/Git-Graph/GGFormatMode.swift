//
//  GGFormatMode.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

enum GGFormatMode {
    static let space = 1
    static let plus = 2
    static let minus = 3
}

struct GGPlaceholders {
    static let base = [
        "n", "H", "h", "P", "p", "d", "s", "an", "ae", "ad", "as", "cn", "ce", "cd", "cs", "b", "B"
    ]

    static let formats: [[String]] = base.map { placeholder in
        [
            "%\(placeholder)",
            "% \(placeholder)",
            "%+\(placeholder)",
            "%-\(placeholder)"
        ]
    }
}
