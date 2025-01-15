//
//  Dimensions.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import Foundation

enum Dimensions {
    static let commitsViewWidth: CGFloat = 400
    static let commitDetailsViewWidth: CGFloat = 400
    static let fileDetailsViewWidth: CGFloat = 600
    static let nodeHorizontalSpacing: CGFloat = 60.0
    static let nodeVerticalSpacing: CGFloat = 40.0
    static let appWidth: CGFloat = Dimensions.commitsViewWidth + Dimensions.commitDetailsViewWidth + Dimensions.fileDetailsViewWidth
    static let appHeight: CGFloat = 800

    static let commitsViewPriority: Double = 1
    static let commitDetailsPriority: Double = 2
    static let fileDetailsViewPriority: Double = 3
}
