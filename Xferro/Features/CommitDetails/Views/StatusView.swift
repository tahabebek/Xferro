//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    @Environment(CommitsViewModel.self) var commitsViewModel
    @Environment(StatusViewModel.self) var statusViewModel
    @Environment(DiscardPopup.self) var discardPopup
    @State private var currentSelectedItem = Dictionary<OID, DeltaInfo>()
    @State var commitSummary = Dictionary<OID, String>()
    @FocusState var isTextFieldFocused: Bool
    @State var discardDeltaInfo: DeltaInfo? = nil

    var body: some View {
        VSplitView {
            actionBox
                .padding(.bottom, 4)
            changeBox
                .padding(.top, 4)
                .layoutPriority(.greatestFiniteMagnitude)
        }
        .onAppear {
            setInitialSelection()
        }
        .onChange(of: statusViewModel.selectableStatus) { oldValue, newValue in
            if oldValue.oid != newValue.oid {
                setInitialSelection()
                isTextFieldFocused = false
            }
        }
        .onChange(of: discardDeltaInfo) { _, newValue in
            if let newValue, discardPopup.isPresented == false {
                discardPopup.show(title: discardAlertTitle(deltaInfo: newValue)) {
                    discard(deltaInfo: newValue)
                    self.discardDeltaInfo = nil
                } onCancel: {
                    self.discardDeltaInfo = nil
                }
            }
        }
        .animation(.default, value: statusViewModel.selectableStatus)
        .animation(.default, value: statusViewModel.stagedDeltaInfos)
        .animation(.default, value: statusViewModel.unstagedDeltaInfos)
        .animation(.default, value: statusViewModel.untrackedDeltaInfos)
        .animation(.default, value: currentSelectedItem)
        .animation(.default, value: commitSummary)
        .padding(.horizontal, 6)
    }

    private func setInitialSelection() {
        if currentSelectedItem[statusViewModel.selectableStatus.oid] == nil {
            if let firstItem = statusViewModel.stagedDeltaInfos.first {
                currentSelectedItem[statusViewModel.selectableStatus.oid] = firstItem
            } else if let firstItem = statusViewModel.unstagedDeltaInfos.first {
                currentSelectedItem[statusViewModel.selectableStatus.oid] = firstItem
            } else if let firstItem = statusViewModel.untrackedDeltaInfos.first {
                currentSelectedItem[statusViewModel.selectableStatus.oid] = firstItem
            }
        }
    }

    var hasChanges: Bool {
        !statusViewModel.stagedDeltaInfos.isEmpty ||
        !statusViewModel.unstagedDeltaInfos.isEmpty ||
        !statusViewModel.untrackedDeltaInfos.isEmpty
    }

    private var changeBox: some View {
        ZStack {
            Color(hex: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: true) {
                if !hasChanges {
                    Text("No changes.")
                }
                LazyVStack(spacing: 4) {
                    if statusViewModel.stagedDeltaInfos.isNotEmpty {
                        stagedView
                    }
                    if statusViewModel.unstagedDeltaInfos.isNotEmpty {
                        unstagedView
                    }
                    if statusViewModel.untrackedDeltaInfos.isNotEmpty {
                        untrackedView
                    }
                }
            }
            .padding()
            .padding(.top, 4)
        }
    }

    private func discardAlertTitle(deltaInfo: DeltaInfo) -> String {
        let oldFilePath = deltaInfo.oldFilePath
        let newFilePath = deltaInfo.newFilePath
        var title: String = "Are you sure you want to discard all the changes"

        if let oldFilePath, let newFilePath, oldFilePath == newFilePath {
            title += " to\n\(oldFilePath)?"
        } else if let oldFilePath, let newFilePath {
            title += " to\n\(oldFilePath), and\n\(newFilePath)?"
        } else if let oldFilePath {
            title += " to\n\(oldFilePath)?"
        } else if let newFilePath {
            title += " to\n\(newFilePath)?"
        }
        return title
    }

    func discard(deltaInfo: DeltaInfo) {
        let oldFileURL = deltaInfo.oldFileURL
        let newFileURL = deltaInfo.newFileURL
        var fileURLs = [URL]()

        if let oldFileURL, let newFileURL, oldFileURL == newFileURL {
            fileURLs.append(oldFileURL)
        } else {
            if let oldFileURL {
                fileURLs.append(oldFileURL)
            }
            if let newFileURL {
                fileURLs.append(newFileURL)
            }
        }
        commitsViewModel.discardFileButtonTapped(
            repository: statusViewModel.repository,
            fileURLs: fileURLs
        )
    }

    private var actionBox: some View {
        ZStack {
            Color(hex: 0x15151A)
                .cornerRadius(8)
            VStack(alignment: .leading) {
                HStack {
                    Form {
                        TextField(
                            "Message",
                            text: Binding(
                                get: { commitSummary[statusViewModel.selectableStatus.oid] ?? "" },
                                set: { commitSummary[statusViewModel.selectableStatus.oid] = $0 }
                            ),
                            prompt: Text("Message for commit, amend or stash"),
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .padding(.bottom, 8)
                    }
                }
                HStack {
                    Spacer()
                    commitButton
                    amendButton
                    stageAllAndCommitButton
                    stageAllAndAmendButton
                    Spacer()
                }
                HStack {
                    Spacer()
                    stageAllCommitAndPushButton
                    stageAllCommitAndForcePushButton
                    Spacer()
                }
                HStack {
                    Spacer()
                    stageAllAmendAndPushButton
                    stageAllAmendAndForcePushButton
                    Spacer()
                }
                HStack {
                    Spacer()
                    pushStashButton
                    popStashButton
                    applyStashButton
                    addCustomButton
                    Spacer()
                }
            }
            .padding()
        }
        .padding(.vertical)
    }

    private var untrackedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.untrackedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        stageSelectedUntrackedButton(deltaInfo: deltaInfo)
                        ignoreSelectedUntrackedButton(deltaInfo: deltaInfo)
                        discardSelectedButton(deltaInfo: deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Untracked files")
                Spacer()
                stageAllUntrackedButton
            }
            .padding(.bottom, 4)
        }
    }

    private var unstagedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.unstagedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        stageSelectedUnstagedButton(deltaInfo: deltaInfo)
                        discardSelectedButton(deltaInfo: deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Unstaged changes")
                Spacer()
                stageAllUnstagedButton
            }
            .padding(.bottom, 4)
        }

    }

    private var stagedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.stagedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        unstageSelectedStagedButton(deltaInfo: deltaInfo)
                        discardSelectedButton(deltaInfo: deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Staged changes")
                Spacer()
                unstageAllStagedButton
            }
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder private func rowForDeltaInfo(_ deltaInfo: DeltaInfo) -> some View {
        let oldFileName = deltaInfo.oldFilePath
        let newFileName = deltaInfo.newFilePath
        Group {
            switch deltaInfo.delta.status {
            case .unmodified:
                fatalError(.impossible)
            case .added:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .green,
                        imageName: "a.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .deleted:
                if let oldFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: oldFileName,
                        color: .red,
                        imageName: "d.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .modified:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .blue,
                        imageName: "m.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .renamed:
                if let oldFileName, let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: "\(oldFileName) -> \(newFileName)",
                        color: .yellow,
                        imageName: "r.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .copied:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .green,
                        imageName: "c.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .ignored:
                fatalError(.unimplemented)
            case .untracked:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .red,
                        imageName: "questionmark.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .typeChange:
                if let oldFileName, let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: "\(oldFileName) -> \(newFileName)",
                        color: .yellow,
                        imageName: "r.square"
                    )
                } else {
                    fatalError(.impossible)
                }
                fatalError(.unimplemented)
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 48)
        .onTapGesture {
            currentSelectedItem[statusViewModel.selectableStatus.oid] = deltaInfo
        }
    }

    private func fileView(
        deltaInfo: DeltaInfo,
        text: String,
        color: Color,
        imageName: String
    ) -> some View {
        HStack {
            Image(systemName: imageName).foregroundColor(color)
            Text(text)
                .font(.body)
                .foregroundStyle(currentSelectedItem[statusViewModel.selectableStatus.oid] == deltaInfo ? Color.accentColor : Color.fabulaFore1)
            Spacer()
        }
    }
}
