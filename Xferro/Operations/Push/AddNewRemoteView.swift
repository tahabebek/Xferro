//
//  AddNewRemoteView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/19/25.
//

import SwiftUI

struct AddNewRemoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(StatusViewModel.self) var statusViewModel
    @FocusState var isTextFieldFocused: Bool
    @State var name: String = ""
    @State var fetchURL: String = ""
    @State var pushURL: String = ""
    @State var invalidMessage: String?

    let title: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            .font(.title2)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Text("Name:")
                    TextField(
                        "Name",
                        text: $name,
                        axis: .vertical
                    )
                    .frame(width: 340)
                    .focused($isTextFieldFocused)
                }
                HStack {
                    Spacer()
                    Text("Fetch URL:")
                    TextField(
                        "Fetch URL",
                        text: $fetchURL,
                        axis: .vertical
                    )
                    .frame(width: 340)
                }
                HStack {
                    Spacer()
                    Text("Push URL:")
                    TextField(
                        "Push URL",
                        text: $pushURL,
                        prompt: Text("Same as fetch URL"),
                        axis: .vertical
                    )
                    .frame(width: 340)
                }
            }
            HStack {
                Spacer()
                Text(invalidMessage ?? "")
                    .foregroundStyle(.red)
                    .opacity(invalidMessage == nil ? 0 : 1)
                Spacer()
            }
            .padding(.bottom)
            HStack {
                Spacer()
                XFerroButton<Void>(
                    title: "Cancel",
                    isProminent: false,
                    onTap: {
                        dismiss()
                    }
                )
                XFerroButton<Void>(
                    title: "Add Remote",
                    onTap: {
                        if name.isEmptyOrWhitespace && fetchURL.isEmptyOrWhitespace {
                            invalidMessage = "Name and fetch URL are required."
                        } else if name.isEmptyOrWhitespace {
                            invalidMessage = "Name is required."
                        } else if fetchURL.isEmptyOrWhitespace {
                            invalidMessage = "Fetch URL is required."
                        } else {
                            dismiss()
                            Task {
                                await statusViewModel.onAddRemote(
                                    fetchURLString: fetchURL,
                                    pushURLString: pushURL.isEmpty ? fetchURL : pushURL,
                                    remoteName: name
                                )
                            }
                        }
                    }
                )
            }
            .padding(.bottom)
        }
        .animation(.default, value: invalidMessage)
        .textFieldStyle(.roundedBorder)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
