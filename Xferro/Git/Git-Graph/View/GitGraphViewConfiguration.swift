//
//  GitGraphViewConfiguration.swift
//  Xferro
//
//  Created by Taha Bebek on 1/30/25.
//

import SwiftUI

struct GitGraphViewConfiguration {
    // Visual constants for the graph
    let commitRadius: CGFloat = 6
    let columnWidth: CGFloat = 40    // Horizontal space between branches
    let rowHeight: CGFloat = 50      // Vertical space between commits
    let branchLineWidth: CGFloat = 2
    let backgroundColor: Color = currentTheme.lightPrimary.suiColor
}
