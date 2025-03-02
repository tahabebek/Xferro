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
        let handleDelta: (Repository, Diff.Delta, StatusType) -> Void = { repository, delta, type in
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

    func stageOrUnstageTapped(stage: Bool) {
        stageOrUnstageTapped(stage: stage, deltaInfos: stagedDeltaInfos)
    }
    
    func stageOrUnstageTapped(stage: Bool, deltaInfos: [DeltaInfo]) {
        for deltaInfo in deltaInfos {
            switch deltaInfo.delta.status {
            case .unmodified:
                fatalError(.unexpected)
            case .added, .modified, .copied, .untracked:
                guard let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.invalid)
                }
                if stage {
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .deleted:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path else {
                    fatalError(.invalid)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                }
            case .renamed, .typeChange:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path,
                      let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.invalid)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .ignored, .unreadable, .conflicted:
                fatalError(.unimplemented)
            }
        }
    }

    func stageAllTapped() {
        repository.stage(path: ".").mustSucceed()
    }

    @discardableResult
    func commitTapped(message: String) -> Commit {
        repository.commit(message: message).mustSucceed()
    }

    func splitAndCommitTapped( message: String) -> Commit {
        fatalError(.unimplemented)
    }

    func amendTapped( message: String?) {
        let headCommit: Commit = repository.commit().mustSucceed()
        var newMessage = message
        if newMessage == nil || (newMessage ?? "").isEmptyOrWhitespace {
            newMessage = headCommit.summary
        }

        guard let newMessage, !newMessage.isEmptyOrWhitespace else {
            fatalError(.unsupported)
        }
        repository.amend(message: newMessage).mustSucceed()
    }

    func ignoreTapped(deltaInfo: DeltaInfo) {
        guard let path = deltaInfo.newFilePath else {
            fatalError(.illegal)
        }
        repository.ignore(path)
    }

    func discardTapped(fileURLs: [URL]) {
        for fileURL in fileURLs {
            if fileURL.isDirectory {
                RepoManager().git(repository, ["restore", fileURL.appendingPathComponent("*").path])
            } else {
                RepoManager().git(repository, ["restore", fileURL.path])
            }
        }
    }

    func discardAllTapped() {
        RepoManager().git(repository, ["add", "."])
        RepoManager().git(repository, ["reset", "--hard"])
    }
}
