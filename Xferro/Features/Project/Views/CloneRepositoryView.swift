//
//  CloneRepositoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/28/25.
//

import SwiftUI

struct CloneRepositoryView: View {
    @FocusState var isTextFieldFocused: Bool

    @State var remoteSource: String = ""
    @State var localSource: String = ""
    @State var destinationPath: String = ""
    @State var destinationFolderName: String = ""
    @State var invalidMessage: String?
    @State var isRemote: Bool = true

    let onCancel: () -> Void
    let onClone: (String, String, String, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            titleView
            settingsView
            invalidMessageView
                .padding(.bottom)
            HStack {
                Spacer()
                XFButton<Void>(
                    title: "Cancel",
                    isProminent: false,
                    onTap: onCancel
                )
                XFButton<Void>(
                    title: "Clone",
                    onTap: {
                        if isRemote {
                            if remoteSource.isEmptyOrWhitespace {
                                invalidMessage = "Please enter a URL"
                                return
                            }
                        } else {
                            if localSource.isEmptyOrWhitespace {
                                invalidMessage = "Please select a local repository"
                                return
                            }
                        }
                        
                        if destinationPath.isEmptyOrWhitespace {
                            invalidMessage = "Please enter a destination folder"
                            return
                        }
                        if destinationFolderName.isEmptyOrWhitespace {
                            invalidMessage = "Please enter a destination folder name"
                            return
                        }
                        onClone(destinationPath, isRemote ? remoteSource : localSource, destinationFolderName, isRemote)
                    }
                )
            }
        }
        .padding()
        .padding(.bottom)
        .animation(.default, value: invalidMessage)
        .textFieldStyle(.roundedBorder)
        .onAppear {
            isTextFieldFocused = true
        }
        .onChange(of: remoteSource) {
            destinationFolderName = (remoteSource.components(separatedBy: "/").last ?? "")
                .replacingOccurrences(of: ".git", with: "")
        }
        .onChange(of: localSource) {
            destinationFolderName = (localSource.components(separatedBy: "/").last ?? "")
        }
        .onChange(of: isRemote) {
            if isRemote {
                destinationFolderName = (remoteSource.components(separatedBy: "/").last ?? "")
                    .replacingOccurrences(of: ".git", with: "")
            } else {
                destinationFolderName = (localSource.components(separatedBy: "/").last ?? "")
            }
        }
    }
    
    var invalidMessageView: some View {
        HStack {
            Spacer()
            Text(invalidMessage ?? "")
                .font(.validationError)
                .foregroundStyle(.red)
                .opacity(invalidMessage == nil ? 0 : 1)
            Spacer()
        }
    }
    
    var settingsView: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $isRemote) {
                Text("Clone a local repository").tag(false)
                Text("Clone a remote repository").tag(true)
            }
            .pickerStyle(.menu)
            .padding(.bottom)
            Group {
                if !isRemote {
                    localSettingsView
                }
                else {
                    remoteSettingsView
                }
                HStack {
                    Text("Destination Folder:")
                    Spacer()
                    TextField("Destination Folder", text: $destinationPath)
                    XFButton<Void>(
                        title: "Choose...",
                        isProminent: false,
                        onTap: {
                            chooseDestinationFolder()
                        }
                    )
                }
                HStack {
                    Text("Clone as:")
                    Spacer()
                    TextField("Clone as", text: $destinationFolderName)
                }
            }
        }
        .font(.formField)
    }
    
    var remoteSettingsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("URL:")
                Spacer()
                TextField("URL", text: $remoteSource)
                    .textEditorStyle(.plain)
                    .onAppear {
                        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                            // Check for Command+V
                            if event.modifierFlags.contains(.command) && event.characters == "v" {
                                if let pasteboardString = NSPasteboard.general.string(forType: .string) {
                                    remoteSource = pasteboardString
                                    return nil // Event handled
                                }
                            }
                            return event // Pass the event along
                        }
                    }
                    .focused($isTextFieldFocused)
            }
        }
        .padding(.leading, 8)
    }

    var localSettingsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Source Folder:")
                Spacer()
                TextField("Source Folder", text: $localSource)
                XFButton<Void>(
                    title: "Choose...",
                    isProminent: false,
                    onTap: {
                        chooseSourceFolder()
                    }
                )
            }
        }
        .padding(.leading, 8)
    }
    
    var titleView: some View {
        Text("Clone Repository")
        .font(.formHeading)
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, 8)
    }
    
    func chooseDestinationFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Destination Folder"
        openPanel.message = "Choose a folder to clone the repository into"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        openPanel.begin { result in
            guard result == .OK, let selectedURL = openPanel.url else { return }
            destinationPath = selectedURL.path
        }
    }
    
    func chooseSourceFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Source Folder"
        openPanel.message = "Choose a folder to clone the repository from"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        openPanel.begin { result in
            guard result == .OK, let selectedURL = openPanel.url else { return }
            localSource = selectedURL.path
        }
    }
}
