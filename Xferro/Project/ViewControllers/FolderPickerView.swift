//
//  FolderPickerView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import SwiftUI

struct FolderPickerView: View {
    let onSelect: (URL) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Select a folder to track changes. It doesn't have to be a git repository.")
                .font(.title2)
            Button {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.message = "Select a folder"

                if panel.runModal() == .OK {
                    if let selectedFolder = panel.urls.first {
                        guard selectedFolder.startAccessingSecurityScopedResource() else {
                            print("Failed to access the selected folder")
                            return
                        }
                        do {
                            let bookmarkData = try selectedFolder.bookmarkData(
                                options: .withSecurityScope,
                                includingResourceValuesForKeys: nil,
                                relativeTo: nil
                            )

                            UserDefaults.standard.set(bookmarkData, forKey: selectedFolder.path)
                            onSelect(selectedFolder)
                        } catch {
                            print("Failed to create bookmark: \(error)")
                        }

                        selectedFolder.stopAccessingSecurityScopedResource()
                    }
                }

            } label: {
                Image(systemName: "folder.badge.plus")
                    .padding()
            }
        }
    }
}
