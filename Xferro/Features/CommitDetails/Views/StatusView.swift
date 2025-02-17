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
    @State private var currentSelectedItem = Dictionary<OID, DeltaInfo>()
    @State var selectedStagedIds = Dictionary<OID, Set<DeltaInfo>>()
    @State var selectedUnstagedIds = Dictionary<OID, Set<DeltaInfo>>()
    @State var selectedUntrackedIds = Dictionary<OID, Set<DeltaInfo>>()
    @State var commitSummary = Dictionary<OID, String>()

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
            }
        }
        .animation(.default, value: statusViewModel.selectableStatus)
        .animation(.default, value: statusViewModel.stagedDeltaInfos)
        .animation(.default, value: statusViewModel.unstagedDeltaInfos)
        .animation(.default, value: statusViewModel.untrackedDeltaInfos)
        .animation(.default, value: statusViewModel.statusEntries)
        .animation(.default, value: currentSelectedItem)
        .animation(.default, value: selectedStagedIds)
        .animation(.default, value: selectedUnstagedIds)
        .animation(.default, value: selectedUntrackedIds)
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

    private var changeBox: some View {
        ZStack {
            Color(hex: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: true) {
                if statusViewModel.stagedDeltaInfos.isEmpty &&
                    statusViewModel.unstagedDeltaInfos.isEmpty &&
                    statusViewModel.untrackedDeltaInfos.isEmpty {
                    Text("Empty")
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
            .padding(6)
            .padding(.top, 4)
        }
    }

    private var actionBox: some View {
        ZStack {
            Color(hex: 0x15151A)
                .cornerRadius(8)
            VStack(alignment: .leading) {
                HStack {
                    Form {
                        TextField("Summary", text: Binding(
                            get: { commitSummary[statusViewModel.selectableStatus.oid] ?? "" },
                            set: { commitSummary[statusViewModel.selectableStatus.oid] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                    }
                }
                HStack {
                    commitButton
                    amendButton
                    stageAllAndCommitButton
                    stageAllAndAmendButton
                    Spacer()
                }
                HStack {
                    stageAllCommitAndPushButton
                    stageAllCommitAndForcePushButton
                    Spacer()
                }
                HStack {
                    stageAllAmendAndPushButton
                    stageAllAmendAndForcePushButton
                    Spacer()
                }
                HStack {
                    pushStashButton
                    popStashButton
                    applyStashButton
                    Spacer()
                }
                HStack {
                    addCustomButton
                    Spacer()
                }
            }
            .padding()
        }
    }

    private var untrackedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.untrackedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        stageSelectedUntrackedButton(deltaInfo: deltaInfo)
                            .padding(.trailing, 8)
                    }
                }
            }
        } header: {
            HStack {
                Text("Untracked files")
                Spacer()
                stageAllUntrackedButton
                .padding(.trailing, 8)
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
                            .padding(.trailing, 8)
                    }
                }
            }
        } header: {
            HStack {
                Text("Unstaged changes")
                Spacer()
                stageAllUnstagedButton
                .padding(.trailing, 8)
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
                            .padding(.trailing, 8)
                    }
                }
            }
        } header: {
            HStack {
                Text("Staged changes")
                Spacer()
                unstageAllStagedButton
                .padding(.trailing, 8)
            }
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder private func rowForDeltaInfo(_ deltaInfo: DeltaInfo) -> some View {
        let oldFileName = deltaInfo.delta.oldFile?.path != nil ? URL(filePath: deltaInfo.delta.oldFile!.path).lastPathComponent : nil
        let newFileName = deltaInfo.delta.newFile?.path != nil ? URL(filePath: deltaInfo.delta.newFile!.path).lastPathComponent : nil
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
