//
//  XferroFonts.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

extension String {
    static let fontName = "Adelle Sans"
    static let diffViewFontName = "JetBrains Mono"
}

extension CGFloat {
    static let heading0Size: CGFloat = 25
    static let heading1Size: CGFloat = 23
    static let heading2Size: CGFloat = 21
    static let paragraph1Size: CGFloat = 19
    static let paragraph2Size: CGFloat = 17
    static let paragraph3Size: CGFloat = 16
    static let paragraph4Size: CGFloat = 15
    static let paragraph5Size: CGFloat = 14
    static let paragraph6Size: CGFloat = 13
    static let small: CGFloat = 12
    static let tiniest: CGFloat = 10
    static let diffViewFontSize: CGFloat = 13
    static let diffViewLineHeight: CGFloat = 16
}

extension Font {
    static let heading0 = Font.custom(String.fontName, size: CGFloat.heading0Size)
    static let heading1 = Font.custom(String.fontName, size: CGFloat.heading1Size)
    static let heading2 = Font.custom(String.fontName, size: CGFloat.heading2Size)
    static let paragraph1 = Font.custom(String.fontName, size: CGFloat.paragraph1Size)
    static let paragraph2 = Font.custom(String.fontName, size: CGFloat.paragraph2Size)
    static let paragraph3 = Font.custom(String.fontName, size: CGFloat.paragraph3Size)
    static let paragraph4 = Font.custom(String.fontName, size: CGFloat.paragraph4Size)
    static let paragraph5 = Font.custom(String.fontName, size: CGFloat.paragraph5Size)
    static let paragraph6 = Font.custom(String.fontName, size: CGFloat.paragraph6Size)
    static let small = Font.custom(String.fontName, size: CGFloat.small)
    static let tiniest = Font.custom(String.fontName, size: CGFloat.tiniest)

    static let formHeading = heading2
    static let formField = paragraph4
    static let commitCircle = small
    static let wipCommitCircle = tiniest
    static let accessoryButton = paragraph6
    static let validationError = Font.custom(String.fontName, size: CGFloat.small)
    static let diff = Font.custom(String.diffViewFontName, size: CGFloat.diffViewFontSize)
}

extension NSFont {
    static let segmentedControl = NSFont(name: .fontName, size: .paragraph4Size)!
}
