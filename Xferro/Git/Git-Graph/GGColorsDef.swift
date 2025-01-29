//
//  GGColorsDef.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

struct GGColorsDef {
    let matches: [(pattern: String, colors: [String])]
    let unknown: [String]
}

/// Named ANSI colors mapping to their 256-color palette indices
private let NAMED_COLORS: [String: UInt8] = [
    "black": 0,
    "red": 1,
    "green": 2,
    "yellow": 3,
    "blue": 4,
    "magenta": 5,
    "cyan": 6,
    "white": 7,
    "bright_black": 8,
    "bright_red": 9,
    "bright_green": 10,
    "bright_yellow": 11,
    "bright_blue": 12,
    "bright_magenta": 13,
    "bright_cyan": 14,
    "bright_white": 15
]

/// Converts a color name to the index in the 256-color palette.
func toTerminalColor(_ color: String) throws -> UInt8 {
    if let namedColor = NAMED_COLORS[color] {
        return namedColor
    }

    if let numericColor = UInt8(color) {
        return numericColor
    }

    throw GGColorError.colorNotFound(color)
}
enum GGColorError: Error {
    case colorNotFound(String)
}
