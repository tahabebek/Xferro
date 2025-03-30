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
    var activity: Activity?
    
    func updateMessage(message: String) {
        activity?.name = message
    }

    func startActivity(name: String) {
        activity = Activity(name: name)
    }
    
    func stopActivity() {
        print("Activity stopped: \(activity?.name ?? "nil")")
        activity = nil
    }
}
