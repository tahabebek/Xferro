//
//  WipHeaderView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct WipHeaderView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage var autoCommitEnabled: Bool
    @AppStorage var autoPushEnabled: Bool

    @State var errorString: String? = nil
    @State var showButtons = false
    @State var options: [XFButtonOption<Remote>] = []
    @State var selectedRemoteForPush: Remote? = nil

    let viewModel: WipCommitsViewModel
    let onAddManualWipCommitTapped: () -> Void
    let onDeleteWipWorktreeTapped: () -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void
    let onPushTapped: (String, Remote?, Repository.PushType) async throws -> Void

    init(
        viewModel: WipCommitsViewModel,
        onAddManualWipCommitTapped: @escaping () -> Void,
        onDeleteWipWorktreeTapped: @escaping () -> Void,
        onAddRemoteTapped: @escaping () -> Void,
        onGetLastSelectedRemoteIndex: @escaping (String) -> Int,
        onSetLastSelectedRemote: @escaping (Int, String) -> Void,
        onPushTapped: @escaping (String, Remote?, Repository.PushType) async throws -> Void
    ) {
        self._autoCommitEnabled = .init(
            wrappedValue: false,
            PreferenceKeys.autoCommitEnabled,
            store: UserDefaults.standard
        )
        self._autoPushEnabled = .init(
            wrappedValue: false,
            PreferenceKeys.autoPushEnabled,
            store: UserDefaults.standard
        )
        self.viewModel = viewModel
        self.onAddManualWipCommitTapped = onAddManualWipCommitTapped
        self.onDeleteWipWorktreeTapped = onDeleteWipWorktreeTapped
        self.onAddRemoteTapped = onAddRemoteTapped
        self.onGetLastSelectedRemoteIndex = onGetLastSelectedRemoteIndex
        self.onSetLastSelectedRemote = onSetLastSelectedRemote
        self.onPushTapped = onPushTapped
    }

    var body: some View {
        HStack(spacing: 0) {
            VerticalHeader( title: "Work in Progress", info: InfoTexts.wip) {
                buttons
                    .padding()
            }
        }
        .frame(height: Dimensions.verticalHeaderHeight)
        .animation(.default, value: autoCommitEnabled)
    }

    var buttons: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !autoCommitEnabled {
                XFButton<Void>(
                    title: "Commit Wip",
                    info: XFButtonInfo(info: ""),
                    onTap: {
                        dismiss()
                        onAddManualWipCommitTapped()
                    }
                )
            }
            if !autoPushEnabled {
                XFButton<Remote>(
                    title: "Push",
                    options: $options,
                    selectedOptionIndex: Binding<Int>(
                        get: {
                            onGetLastSelectedRemoteIndex("push")
                        }, set: { value, _ in
                            onSetLastSelectedRemote(value, "push")
                        }
                    ),
                    addMoreOptionsText: "Add Remote...",
                    onTapOption: { option in
                        selectedRemoteForPush = option.data
                    },
                    onTapAddMore: {
                        onAddRemoteTapped()
                    },
                    onTap: {
                        Task {
                            do {
                                dismiss()
                                try await onPushTapped(viewModel.branchName, selectedRemoteForPush, .force)
                            } catch {
                                errorString = error.localizedDescription
                            }
                        }
                    }
                )
                .onChange(of: viewModel.repositoryInfo.remotes.count) {
                    options = viewModel.repositoryInfo.remotes.map {
                        XFButtonOption(title: $0.name!, data: $0)
                    }
                }
                .task {
                    selectedRemoteForPush = viewModel.repositoryInfo.remotes[
                        onGetLastSelectedRemoteIndex("push")
                    ]
                }
            }
            if !autoPushEnabled || !autoPushEnabled {
                Divider()
            }
            XFButton<Void>(
                title: "Delete all wip commits of \(viewModel.repositoryInfo.repository.nameOfRepo)",
                onTap: {
                    dismiss()
                    showButtons = false
                }
            )
            XFButton<Void>(
                title: "Delete wip commits of \(viewModel.item.selectableItem.wipDescription.uncapitalizingFirstLetter())",
                onTap: {
                    dismiss()
                    showButtons = false
                }
            )
            Divider()
            settings
        }
    }

    var settings: some View {
        Group {
            HStack {
                Text("Automatically commit wip on save")
                Spacer()
                Toggle("", isOn: $autoCommitEnabled)
                    .toggleStyle(.switch)
            }
            HStack {
                Text("Automatically push wip commits")
                Spacer()
                Toggle("", isOn: $autoPushEnabled)
                    .toggleStyle(.switch)
            }
        }
        .font(.formField)
    }
}
