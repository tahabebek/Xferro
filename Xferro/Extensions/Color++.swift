//
//  Color++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/1/25.
//

import SwiftUI

extension Color {
    static func random() -> Self {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }

    init(hexValue: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hexValue >> 16) & 0xff) / 255,
            green: Double((hexValue >> 08) & 0xff) / 255,
            blue: Double((hexValue >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
    
    var nsColor: NSColor {
        if let cgColor {
            NSColor(cgColor: cgColor) ?? .white
        } else {
            NSColor.white
        }
    }
}
