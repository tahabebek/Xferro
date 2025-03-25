//
//  StatusViewModel+ActivityOperation.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import Foundation

extension StatusViewModel {
    func performOperation(
        title: String,
        successMessage: String,
        _ operation: @escaping () async throws -> Void
    ) async {
        Task {
            var activity: Activity = ProgressManager.shared.startActivity(name: title)
            defer {
                ProgressManager.shared.updateProgress(activity, progress: 1.0)
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
