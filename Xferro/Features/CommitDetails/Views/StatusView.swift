//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @State private var multiSelection: Set<String> = []
    var body: some View {
        List(selection: $multiSelection) {
            Section {
                ForEach(statusViewModel.stagedDeltaInfos) { deltaInfo in
                    rowForDeltaInfo(deltaInfo)
                }
            } header: {
                HStack {
                    Text("Changes staged for commit")
                    Spacer()
                    Text("\(statusViewModel.stagedDeltaInfos.count) changed files")
                        .font(.caption)
                        .opacity(0.5)
                }
            }
            Section {
                ForEach(statusViewModel.unstagedDeltaInfos) { deltaInfo in
                    rowForDeltaInfo(deltaInfo)
                }
            } header: {
                HStack {
                    Text("Changes not staged for commit")
                    Spacer()
                    Text("\(statusViewModel.unstagedDeltaInfos.count) changed files")
                        .font(.caption)
                        .opacity(0.5)
                }
            }
            Section {
                ForEach(statusViewModel.untrackedDeltaInfos) { deltaInfo in
                    rowForDeltaInfo(deltaInfo)
                }
            } header: {
                HStack {
                    Text("Untracked Files")
                    Spacer()
                    Text("\(statusViewModel.untrackedDeltaInfos.count) changed files")
                        .font(.caption)
                        .opacity(0.5)
                }
            }
        }
    }

    @ViewBuilder private func rowForDeltaInfo(_ deltaInfo: StatusViewModel.DeltaInfo) -> some View {
        let oldFileName = deltaInfo.delta.oldFile?.path != nil ? URL(filePath: deltaInfo.delta.oldFile!.path).lastPathComponent : nil
        let newFileName = deltaInfo.delta.newFile?.path != nil ? URL(filePath: deltaInfo.delta.newFile!.path).lastPathComponent : nil
        switch deltaInfo.delta.status {
        case .unmodified:
            fatalError(.impossible)
        case .added:
            if let newFileName {
                HStack {
                    Text(newFileName)
                    Spacer()
                    Image(systemName: "a.square").foregroundColor(Color.green)
                }
            } else {
                fatalError(.impossible)
            }
        case .deleted:
            if let oldFileName {
                HStack {
                    Text(oldFileName)
                    Spacer()
                    Image(systemName: "d.square").foregroundColor(Color.red)
                }
            } else {
                fatalError(.impossible)
            }
        case .modified:
            if let newFileName {
                HStack {
                    Text(newFileName)
                    Spacer()
                    Image(systemName: "m.square").foregroundColor(Color.blue)
                }
            } else {
                fatalError(.impossible)
            }
        case .renamed:
            if let oldFileName, let newFileName {
                HStack {
                    Text("\(oldFileName) -> \(newFileName)")
                    Spacer()
                    Image(systemName: "r.square").foregroundColor(Color.yellow)
                }
            } else {
                fatalError(.impossible)
            }
        case .copied:
            if let newFileName {
                HStack {
                    Text(newFileName)
                    Spacer()
                    Image(systemName: "a.square").foregroundColor(Color.green)
                }
            } else {
                fatalError(.impossible)
            }
        case .ignored:
            fatalError(.unimplemented)
        case .untracked:
            if let newFileName {
                HStack {
                    Text(newFileName)
                    Spacer()
                    Image(systemName: "questionmark").foregroundColor(Color.red)
                }
            } else {
                fatalError(.impossible)
            }
        case .typeChange:
            if let newFileName {
                HStack {
                    Text(newFileName)
                    Spacer()
                    Image(systemName: "m.square").foregroundColor(Color.blue)
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
}

