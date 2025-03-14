//
//  TextWrapping.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

enum TextWrapping: RawRepresentable, CaseIterable {
    static let allCases: [TextWrapping] = [
        .windowWidth,
        .columns(80),
        .none,
    ]

    case windowWidth
    case columns(Int)
    case none

    var rawValue: Int {
        switch self {
        case .windowWidth: 0
        case .columns(let count): count
        case .none: -1
        }
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .windowWidth
        case -1:
            self = .none
        case 1...:
            self = .columns(rawValue)
        default:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .windowWidth: "Wrap to window"
        case .columns(let count): "Wrap to \(count) columns"
        case .none: "No wrapping"
        }
    }
}

extension TextWrapping: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension TextWrapping: Equatable {
    static func == (a: TextWrapping, b: TextWrapping) -> Bool {
        switch (a, b) {
        case (.windowWidth, .windowWidth),
            (.none, .none):
            return true
        case (.columns(let c1), .columns(let c2)):
            return c1 == c2
        default:
            return false
        }
    }
}
