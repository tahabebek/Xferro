//
//  Alignments.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

extension VerticalAlignment {
    private enum CurrentAlignment : AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            return d[VerticalAlignment.center]
        }
    }
    static let verticalAlignment = VerticalAlignment(CurrentAlignment.self)
}

extension HorizontalAlignment {
    private enum CurrentAlignment : AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            return d[HorizontalAlignment.center]
        }
    }
    static let horizontalAlignment = HorizontalAlignment(CurrentAlignment.self)
}
