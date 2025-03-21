//
//  Activity.swift
//  Xferro
//
//  Created by Taha Bebek on 3/20/25.
//

import Foundation

final class Activity: Hashable {
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    let name: String
    var progress: Double // 0.0 to 1.0

    init(name: String, progress: Double = 0.0) {
        self.name = name
        self.progress = progress
    }
}
