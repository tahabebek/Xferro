//
//  ActivityOperation.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import Foundation

enum ActivityOperation {
    static func perform(
        title: String,
        successMessage: String,
        _ operation: @escaping () async throws -> Void
    ) async {
        Task {
            let activity = ProgressManager.shared.startActivity(name: title)
            defer {
                Task { @MainActor in
                    ProgressManager.shared.updateProgress(activity, progress: 1.0)
                }
            }
            do {
                try await operation()
            } catch {
                await MainActor.run {
                    AppDelegate.showErrorMessage(error: RepoError.unexpected(error.localizedDescription))
                }
            }
        }
    }
}
