//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @State private var currentSelectedItem: StatusViewModel.DeltaInfo?
    @State private var selectedStagedIds: Set<String> = []
    @State private var selectedUnstagedIds: Set<String> = []
    @State private var selectedUntrackedIds: Set<String> = []
    @State private var commitSummary: String = ""

    var body: some View {
        VSplitView {
            changeBox
                .layoutPriority(1)
                .padding(.bottom, 4)
            commitBox
                .padding(.top, 4)
        }
        .onAppear {
            if currentSelectedItem == nil {
                setInitialSelection()
            }
        }
        .onChange(of: statusViewModel.selectableStatus) { oldValue, newValue in
            if oldValue.oid != newValue.oid {
                setInitialSelection()
            }
        }
        .padding(.horizontal, 6)
    }

    private func setInitialSelection() {
        if let firstItem = statusViewModel.stagedDeltaInfos.first {
            currentSelectedItem = firstItem
        } else if let firstItem = statusViewModel.unstagedDeltaInfos.first {
            currentSelectedItem = firstItem
        } else if let firstItem = statusViewModel.untrackedDeltaInfos.first {
            currentSelectedItem = firstItem
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
                .disabled(!commitSummary.isNotEmptyOrWhitespace || selectedStagedIds.isEmpty)
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
                            get: { selectedUntrackedIds.contains(deltaInfo.id) },
                            set: { isSelected in
                                if isSelected {
                                    currentSelectedItem = deltaInfo
                                    selectedUntrackedIds.insert(deltaInfo.id)
                                } else {
                                    selectedUntrackedIds.remove(deltaInfo.id)
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
                Text("Untracked")
                    .foregroundStyle(.red)
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
                .disabled(selectedUntrackedIds.isEmpty)
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
                            get: { selectedUnstagedIds.contains(deltaInfo.id) },
                            set: { isSelected in
                                if isSelected {
                                    currentSelectedItem = deltaInfo
                                    selectedUnstagedIds.insert(deltaInfo.id)
                                } else {
                                    selectedUnstagedIds.remove(deltaInfo.id)
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
                Text("Not staged")
                    .foregroundStyle(.red)
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
                .disabled(selectedUnstagedIds.isEmpty)
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
                            get: { selectedStagedIds.contains(deltaInfo.id) },
                            set: { isSelected in
                                if isSelected {
                                    currentSelectedItem = deltaInfo
                                    selectedStagedIds.insert(deltaInfo.id)
                                } else {
                                    selectedStagedIds.remove(deltaInfo.id)
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
                Text("Staged")
                    .foregroundStyle(.green)
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
                .disabled(selectedStagedIds.isEmpty)
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
                    HStack {
                        Image(systemName: "a.square").foregroundColor(Color.green)
                        Text(newFileName)
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
                } else {
                    fatalError(.impossible)
                }
            case .deleted:
                if let oldFileName {
                    HStack {
                        Image(systemName: "d.square").foregroundColor(Color.red)
                        Text(oldFileName)
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
                } else {
                    fatalError(.impossible)
                }
            case .modified:
                if let newFileName {
                    HStack {
                        Image(systemName: "m.square").foregroundColor(Color.blue)
                        Text(newFileName)
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
                } else {
                    fatalError(.impossible)
                }
            case .renamed:
                if let oldFileName, let newFileName {
                    HStack {
                        Image(systemName: "r.square").foregroundColor(Color.yellow)
                        Text("\(oldFileName) -> \(newFileName)")
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
                } else {
                    fatalError(.impossible)
                }
            case .copied:
                if let newFileName {
                    HStack {
                        Image(systemName: "a.square").foregroundColor(Color.green)
                        Text(newFileName)
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
                } else {
                    fatalError(.impossible)
                }
            case .ignored:
                fatalError(.unimplemented)
            case .untracked:
                if let newFileName {
                    HStack {
                        Image(systemName: "questionmark").foregroundColor(Color.red)
                        Text(newFileName)
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
                } else {
                    fatalError(.impossible)
                }
            case .typeChange:
                if let newFileName {
                    HStack {
                        Image(systemName: "m.square").foregroundColor(Color.blue)
                        Text(newFileName)
                            .foregroundStyle(currentSelectedItem == deltaInfo ? Color.accentColor : Color.white)
                        Spacer()
                    }
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
            currentSelectedItem = deltaInfo
        }
    }
}
