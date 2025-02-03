//
//  GGColumn.swift
//  Xferro
//
//  Created by Taha Bebek on 2/1/25.
//

import SwiftUI

struct GGColumn: Identifiable {
    var id: Int { index }
    let index: Int
    let color: Color = .random()
}
