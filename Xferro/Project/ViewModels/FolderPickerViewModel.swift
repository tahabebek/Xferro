//
//  FolderPickerViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Foundation
import Observation

@Observable class FolderPickerViewModel {
    var selectedFolderURL: URL?

    func usedDidSelectFolder(_ folder: URL) {
        let gotAccess = folder.startAccessingSecurityScopedResource()
        if !gotAccess { return }
        do {
            let bookmarkData = try folder.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            UserDefaults.standard.set(bookmarkData, forKey: folder.path)
        } catch {
            print("Failed to create bookmark: \(error)")
        }

        folder.stopAccessingSecurityScopedResource()
        selectedFolderURL = folder
    }

    static func startAccessingFolder(_ folder: URL) {
        guard let bookmarkData = UserDefaults.standard.data(forKey: folder.path) else {
            fatalError("Failed to access repository")
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                print("Bookmark data is stale.")
            }

            guard url.startAccessingSecurityScopedResource() else {
                fatalError("Failed to access repository")
            }
        } catch {
            fatalError()
        }
    }

    static func stopAccessingFolder(_ folder: URL) {
        folder.stopAccessingSecurityScopedResource()
    }
}
