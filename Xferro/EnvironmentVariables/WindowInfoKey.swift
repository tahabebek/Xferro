//
//  WindowInfoKey.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

struct WindowInfoKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var windowInfo: CGSize {
        get { self[WindowInfoKey.self] }
        set { self[WindowInfoKey.self] = newValue }
    }
}

struct GraphWindowInfoKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var graphWindowInfo: CGSize {
        get { self[GraphWindowInfoKey.self] }
        set { self[GraphWindowInfoKey.self] = newValue }
    }
}
