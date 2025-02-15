//
//  StatusViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Observation

@Observable final class StatusViewModel {
    enum StatusType: Int, Identifiable {
        var id: Int { rawValue }

        case staged = 0
        case unstaged = 1
        case untracked = 2
    }

    struct DeltaInfo: Identifiable {
        var id: String { delta.id + type.id.formatted() }
        
        let delta: Diff.Delta
        let type: StatusType
    }

    var stagedDeltaInfos: [DeltaInfo] = []
    var unstagedDeltaInfos: [DeltaInfo] = []
    var untrackedDeltaInfos: [DeltaInfo] = []
    var selectableStatus: SelectableStatus
    private let statusManager: StatusManager

    init(
        selectableStatus: SelectableStatus,
        statusEntries: [StatusEntry],
        statusManager: StatusManager = .shared
    ) {
        self.selectableStatus = selectableStatus
        self.statusManager = statusManager

        var stagedDeltaInfos: [DeltaInfo] = []
        var unstagedDeltaInfos: [DeltaInfo] = []
        var untrackedDeltaInfos: [DeltaInfo] = []
        let handleDelta: (Diff.Delta, StatusType) -> Void = { delta, type in
            switch delta.status {
            case .unmodified, .ignored:
                break
            case .added, .deleted, .modified, .renamed, .copied, .typeChange:
                switch type {
                case .staged:
                    stagedDeltaInfos.append(DeltaInfo(delta: delta, type: type))
                case .unstaged:
                    unstagedDeltaInfos.append(DeltaInfo(delta: delta, type: type))
                case .untracked:
                    fatalError(.impossible)
               }
            case .untracked:
                untrackedDeltaInfos.append(DeltaInfo(delta: delta, type: .untracked))
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }
        for statusEntry in statusEntries {
            var handled: Bool = false
            if let stagedDelta = statusEntry.stagedDelta {
                handled = true
                handleDelta(stagedDelta, .staged)
            }

            if let unstagedDelta = statusEntry.unstagedDelta {
                handled = true
                handleDelta(unstagedDelta, .unstaged)
            }

            guard handled else {
                fatalError(.unimplemented)
            }
        }

        self.stagedDeltaInfos = stagedDeltaInfos
        self.unstagedDeltaInfos = unstagedDeltaInfos
        self.untrackedDeltaInfos = untrackedDeltaInfos
    }
}
