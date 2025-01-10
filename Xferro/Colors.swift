//
//  Colors.swift
//  Xferro
//
//  Created by Taha Bebek on 1/10/25.
//

import AppKit
import Foundation

let currentTheme = Colors.indigoAndTeal

enum Colors {
    static let favoriteColor = NSColor(hex: "#CDDC39")
    case purpleAndIndigo
    case deepPurpleAndIndigo
    case indigoAndTeal
    case tealAndIndigo

    var darkPrimary: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.darkPrimary
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.darkPrimary
        case .indigoAndTeal:
            IndigoAndTealPalette.darkPrimary
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var lightPrimary: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.lightPrimary
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.lightPrimary
        case .indigoAndTeal:
            IndigoAndTealPalette.lightPrimary
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var textAndIcon: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.textAndIcon
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.textAndIcon
        case .indigoAndTeal:
            IndigoAndTealPalette.textAndIcon
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var primary: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.primary
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.primary
        case .indigoAndTeal:
            IndigoAndTealPalette.primary
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var accent: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.accent
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.accent
        case .indigoAndTeal:
            IndigoAndTealPalette.accent
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var primaryText: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.primaryText
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.primaryText
        case .indigoAndTeal:
            IndigoAndTealPalette.primaryText
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var secondaryText: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.secondaryText
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.secondaryText
        case .indigoAndTeal:
            IndigoAndTealPalette.secondaryText
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
    var divider: NSColor {
        switch self {
        case .purpleAndIndigo:
            PurpleAndIndigoPalette.divider
        case .deepPurpleAndIndigo:
            DeepPurpleAndIndigoPalette.divider
        case .indigoAndTeal:
            IndigoAndTealPalette.divider
        case .tealAndIndigo:
            TealAndIndigoPalette.darkPrimary
        }
    }
}

enum PurpleAndIndigoPalette {
    static let darkPrimary = NSColor(hex: "#7B1FA2")
    static let lightPrimary = NSColor(hex: "#E1BEE7")
    static let primary = NSColor(hex: "#9C27B0")
    static let textAndIcon = NSColor(hex: "#FFFFFF")
    static let accent = NSColor(hex: "#4CAF50")
    static let primaryText = NSColor(hex: "#212121")
    static let secondaryText = NSColor(hex: "#757575")
    static let divider = NSColor(hex: "#BDBDBD")
}

enum DeepPurpleAndIndigoPalette {
    static let darkPrimary = NSColor(hex: "#512DA8")
    static let lightPrimary = NSColor(hex: "#D1C4E9")
    static let primary = NSColor(hex: "#673AB7")
    static let textAndIcon = NSColor(hex: "#FFFFFF")
    static let accent = NSColor(hex: "#536DFE")
    static let primaryText = NSColor(hex: "#212121")
    static let secondaryText = NSColor(hex: "#757575")
    static let divider = NSColor(hex: "#BDBDBD")
}

enum IndigoAndTealPalette {
    static let darkPrimary = NSColor(hex: "#303F9F")
    static let lightPrimary = NSColor(hex: "#C5CAE9")
    static let primary = NSColor(hex: "#3F51B5")
    static let textAndIcon = NSColor(hex: "#FFFFFF")
    static let accent = NSColor(hex: "#009688")
    static let primaryText = NSColor(hex: "#212121")
    static let secondaryText = NSColor(hex: "#757575")
    static let divider = NSColor(hex: "#BDBDBD")
}

enum TealAndIndigoPalette {
    static let darkPrimary = NSColor(hex: "#00796B")
    static let lightPrimary = NSColor(hex: "#B2DFDB")
    static let primary = NSColor(hex: "#009688")
    static let textAndIcon = NSColor(hex: "#FFFFFF")
    static let accent = NSColor(hex: "#536DFE")
    static let primaryText = NSColor(hex: "#212121")
    static let secondaryText = NSColor(hex: "#757575")
    static let divider = NSColor(hex: "#BDBDBD")
}

struct Theme {
    static func applyDefaultStyle(to button: NSButton) {
        button.wantsLayer = true
        button.layer?.backgroundColor = currentTheme.primary.cgColor
        button.contentTintColor = currentTheme.textAndIcon
    }

    static func applyDefaultStyle(to textField: NSTextField) {
        textField.textColor = currentTheme.primaryText
        textField.backgroundColor = currentTheme.lightPrimary
    }

    static func applySecondaryStyle(to textField: NSTextField) {
        textField.textColor = currentTheme.secondaryText
        textField.backgroundColor = .clear
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // RGBA (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
