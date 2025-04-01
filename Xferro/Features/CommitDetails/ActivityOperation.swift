//
//  ActivityOperation.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import Foundation

func withActivityOperation(title: String? = nil, _ operation: @escaping () async throws -> Void) async {
    Task {
        if let title {
            Task { @MainActor in
                ProgressManager.shared.startActivity(name: title)
            }
        }
        do {
            try await operation()
            if title != nil {
                Task { @MainActor in
                    ProgressManager.shared.stopActivity()
                }
            }
        } catch {
            await MainActor.run {
                AppDelegate.showErrorMessage(error: RepoError.unexpected(error.localizedDescription))
            }
        }
    }
}
