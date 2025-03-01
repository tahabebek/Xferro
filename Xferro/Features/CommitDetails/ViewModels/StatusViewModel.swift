//
//  StatusViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Observation

@Observable final class StatusViewModel {
    var stagedDeltaInfos: [DeltaInfo] = []
    var unstagedDeltaInfos: [DeltaInfo] = []
    var untrackedDeltaInfos: [DeltaInfo] = []
    var selectableStatus: SelectableStatus
    var repository: Repository {
        selectableStatus.repository
    }

    var currentDeltaInfo: DeltaInfo?

    init(selectableStatus: SelectableStatus) {
        self.selectableStatus = selectableStatus

        var stagedDeltaInfos: [DeltaInfo] = []
        var unstagedDeltaInfos: [DeltaInfo] = []
        var untrackedDeltaInfos: [DeltaInfo] = []
        let handleDelta: (Repository, Diff.Delta, DeltaInfo.StatusType) -> Void = { repository, delta, type in
            switch delta.status {
            case .unmodified, .ignored:
                break
            case .added, .deleted, .modified, .renamed, .copied, .typeChange:
                switch type {
                case .staged:
                    stagedDeltaInfos.append(
                        DeltaInfo(delta: delta, type: type, repository: repository)
                    )
                case .unstaged:
                    unstagedDeltaInfos.append(
                        DeltaInfo(delta: delta, type: type, repository: repository)
                    )
                case .untracked:
                    fatalError(.impossible)
               }
            case .untracked:
                untrackedDeltaInfos.append(
                    DeltaInfo(delta: delta, type: .untracked, repository: repository)
                )
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }
        for statusEntry in selectableStatus.statusEntries {
            var handled: Bool = false
            if let stagedDelta = statusEntry.stagedDelta {
                handled = true
                handleDelta(selectableStatus.repository, stagedDelta, .staged)
            }

            if let unstagedDelta = statusEntry.unstagedDelta {
                handled = true
                handleDelta(selectableStatus.repository,unstagedDelta, .unstaged)
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
