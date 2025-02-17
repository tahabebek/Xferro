//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @State private var currentSelectedItem = Dictionary<OID, StatusViewModel.DeltaInfo>()
    @State private var selectedStagedIds = Dictionary<OID, Set<String>>()
    @State private var selectedUnstagedIds = Dictionary<OID, Set<String>>()
    @State private var selectedUntrackedIds = Dictionary<OID, Set<String>>()
    @State private var commitSummary: String = ""

    var body: some View {
        VSplitView {
            commitBox
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
        .animation(.default, value: currentSelectedItem)
        .animation(.default, value: selectedStagedIds)
        .animation(.default, value: selectedUnstagedIds)
        .animation(.default, value: selectedUntrackedIds)
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

    private var commitBox: some View {
        ZStack {
            Color(hex: 0x15151A)
                .cornerRadius(8)
            HStack {
                Form {
                    TextField("Summary", text: $commitSummary)
                        .textFieldStyle(.roundedBorder)
                }
                Spacer()
                Button {
                } label: {
                    Text("Commit")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!commitSummary.isNotEmptyOrWhitespace || selectedStagedIds.isEmpty(key: statusViewModel.selectableStatus.oid))
            }
            .padding(.horizontal, 8)
        }
    }

    private var untrackedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.untrackedDeltaInfos) { deltaInfo in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { selectedUntrackedIds.contains(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id) },
                            set: { isSelected in
                                if isSelected {
                                    currentSelectedItem[statusViewModel.selectableStatus.oid] = deltaInfo
                                    selectedUntrackedIds.insert(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id)
                                } else {
                                    selectedUntrackedIds.remove(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id)
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .labelsHidden()
                        rowForDeltaInfo(deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Untracked files")
                Spacer()
                Button {
                } label: {
                    Text("Track all")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                } label: {
                    Text("Track selected")
                }
                .controlSize(.small)
                .disabled(selectedUntrackedIds.isEmpty(key: statusViewModel.selectableStatus.oid))
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
                        Toggle("", isOn: Binding(
                            get: { selectedUnstagedIds.contains(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id) },
                            set: { isSelected in
                                if isSelected {
                                    currentSelectedItem[statusViewModel.selectableStatus.oid] = deltaInfo
                                    selectedUnstagedIds.insert(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id)
                                } else {
                                    selectedUnstagedIds.remove(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id)
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .labelsHidden()
                        rowForDeltaInfo(deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Not staged files")
                Spacer()
                Button {
                } label: {
                    Text("Stage all")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                } label: {
                    Text("Stage selected")
                }
                .disabled(selectedUnstagedIds.isEmpty(key: statusViewModel.selectableStatus.oid))
                .controlSize(.small)
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
                        Toggle("", isOn: Binding(
                            get: { selectedStagedIds.contains(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id) },
                            set: { isSelected in
                                if isSelected {
                                    currentSelectedItem[statusViewModel.selectableStatus.oid] = deltaInfo
                                    selectedStagedIds.insert(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id)
                                } else {
                                    selectedStagedIds.remove(key: statusViewModel.selectableStatus.oid, value: deltaInfo.id)
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .labelsHidden()
                        rowForDeltaInfo(deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Staged files")
                Spacer()
                Button {
                } label: {
                    Text("Unstage all")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                } label: {
                    Text("Unstage selected")
                }
                .controlSize(.small)
                .disabled(selectedStagedIds.isEmpty(key: statusViewModel.selectableStatus.oid))
                .padding(.trailing, 8)
            }
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder private func rowForDeltaInfo(_ deltaInfo: StatusViewModel.DeltaInfo) -> some View {
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
                        imageName: "a.square"
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
                fatalError(.unimplemented)
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 36)
        .onTapGesture {
            currentSelectedItem[statusViewModel.selectableStatus.oid] = deltaInfo
        }
    }

    private func fileView(
        deltaInfo: StatusViewModel.DeltaInfo,
        text: String,
        color: Color,
        imageName: String
    ) -> some View {
        HStack {
            Image(systemName: imageName).foregroundColor(color)
            Text(text)
                .font(.title3)
                .foregroundStyle(currentSelectedItem[statusViewModel.selectableStatus.oid] == deltaInfo ? Color.accentColor : Color.fabulaFore1)
            Spacer()
        }
    }
}
