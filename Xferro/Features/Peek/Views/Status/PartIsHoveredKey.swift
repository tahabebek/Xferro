//
//  PartIsHoveredKey.swift
//  Xferro
//
//  Created by Taha Bebek on 3/9/25.
//


import SwiftUI

private struct PartIsHoveredKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var partIsHovered: Bool {
        get { self[PartIsHoveredKey.self] }
        set { self[PartIsHoveredKey.self] = newValue }
    }
}
