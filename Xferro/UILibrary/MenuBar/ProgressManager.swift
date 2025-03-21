//
//  ProgressManager.swift
//  Xferro
//
//  Created by Taha Bebek on 3/20/25.
//

import Foundation
import Observation

@Observable final class ProgressManager {
    static let shared = ProgressManager()
    var activities: Set<Activity> = []

    var isActive: Bool {
        !activities.isEmpty
    }
    var currentActivityName: String {
        isActive ? activities.first?.name ?? "Processing..." : "Idle"
    }

    func startActivity(name: String) -> Activity {
        let activity = Activity(name: name, progress: 0)
        activities.insert(activity)
        return activity
    }
    func updateProgress(_ activity: Activity, progress: Double) {
        Task { @MainActor in
            if progress >= 1.0 {
                activities.remove(activity)
            }
        }
    }
}
