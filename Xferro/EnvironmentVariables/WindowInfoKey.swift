//
//  WindowSizeKey.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

struct WindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var windowSize: CGSize {
        get { self[WindowSizeKey.self] }
        set { self[WindowSizeKey.self] = newValue }
    }
}
