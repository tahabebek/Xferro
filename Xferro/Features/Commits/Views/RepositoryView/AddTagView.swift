//
//  AddTagView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

struct AddTagView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState var isNameFieldFocused: Bool
    @FocusState var isMessageFieldFocused: Bool

    @State var name: String = ""
    @State var invalidMessage: String?
    @State var message: String = ""
    @State var shouldPush: Bool = false
    @State var selectedRemoteName: String = ""

    let remotes: [String]
    let onCreateTag: (String, String?, String, Bool) -> Void

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
                    onTap: {
                        dismiss()
                    }
                )
                XFButton<Void>(
                    title: "Create Tag",
                    onTap: {
                        if name.isEmptyOrWhitespace {
                            invalidMessage = "Please select a remote branch"
                            return
                        }
                        if selectedRemoteName.isEmptyOrWhitespace {
                            invalidMessage = "Please select a remote"
                            return
                        }

                        onCreateTag(
                            name,
                            message.isEmptyOrWhitespace ? nil : message,
                            selectedRemoteName,
                            shouldPush
                        )
                        dismiss()
                    }
                )
            }
        }
        .textFieldStyle(.roundedBorder)
        .onAppear {
            selectedRemoteName = remotes.first ?? ""
            isNameFieldFocused = true
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
        .font(.formField)
    }

    var settingsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Name:")
                    .padding(.trailing, 24)
                Spacer()
                TextField(
                    "Required",
                    text: $name,
                    axis: .vertical
                )
                .focused($isNameFieldFocused)
            }
            HStack {
                Text("Message:")
                Spacer()
                TextEditor(text: $message)
                .frame(height: 100)
                .padding(.top, 8)
                .focused($isMessageFieldFocused)
            }
            HStack {
                Text("Push:")
                    .padding(.trailing, 24)
                Toggle("", isOn: $shouldPush)
                Spacer()
            }
            HStack {
                SearchablePickerView(
                    items: remotes,
                    selectedItem: $selectedRemoteName,
                    title: "Push to remote:"
                )
            }
            .padding(.vertical)
            .frame(maxHeight: shouldPush ? .infinity : 0)
            .opacity(shouldPush ? 1 : 0)
        }
        .animation(.default, value: shouldPush)
        .padding(.leading, 8)
        .font(.formField)
    }

    var titleView: some View {
        Text("Create a New Tag")
            .font(.formHeading)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
    }
}
