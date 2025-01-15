//
//  TreeNodeShape.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

enum TreeNodeShape: Equatable {
    case rectangle(width: CGFloat, height: CGFloat)
    case circle(radius: CGFloat)
    
    var width: CGFloat {
        switch self {
        case .rectangle(width: let width, height: _):
            return width
        case .circle(radius: let radius):
            return radius * 2
        }
    }
    
    var height: CGFloat {
        switch self {
        case .rectangle(width: _, height: let height):
            return height
        case .circle(radius: let radius):
            return radius * 2
        }
    }
}