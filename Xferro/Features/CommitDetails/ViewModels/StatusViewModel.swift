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
    var currentDeltaInfo: DeltaInfo? {
        willSet {
            if let newValue {
                scrollToFile = newValue.id
            }
        }
    }
    var commitSummary: String = ""
    var scrollToFile: String? = nil

    let selectableStatus: SelectableStatus
    let repository: Repository
    let head: Head

    init(selectableStatus: SelectableStatus, repository: Repository, head: Head) {
        self.selectableStatus = selectableStatus
        self.repository = repository
        self.head = head

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
                handleDelta(repository, stagedDelta, .staged)
            }

            if let unstagedDelta = statusEntry.unstagedDelta {
                handled = true
                handleDelta(repository,unstagedDelta, .unstaged)
            }

            guard handled else {
                fatalError(.unimplemented)
            }
        }

        self.stagedDeltaInfos = stagedDeltaInfos
        self.unstagedDeltaInfos = unstagedDeltaInfos
        self.untrackedDeltaInfos = untrackedDeltaInfos
    }

    func actionTapped(_ action: StatusActionButtonsView.BoxAction) async {
        switch action {
        case .splitAndCommit:
            await commitTapped()
            fatalError(.unimplemented)
        case .amend:
            await amendTapped()
        case .stageAll:
            await stageAllTapped()
        case .stageAllAndCommit:
            await stageAllTapped()
            await commitTapped()
        case .stageAllAndAmend:
            await stageAllTapped()
            await amendTapped()
        case .stageAllCommitAndPush:
            await stageAllTapped()
            await commitTapped()
            fatalError(.unimplemented)
        case .stageAllAmendAndPush:
            await stageAllTapped()
            await amendTapped()
            fatalError(.unimplemented)
        case .stageAllCommitAndForcePush:
            await stageAllTapped()
            await commitTapped()
            fatalError(.unimplemented)
        case .stageAllAmendAndForcePush:
            await stageAllTapped()
            await amendTapped()
            fatalError(.unimplemented)
        case .stash:
            fatalError(.unimplemented)
        case .popStash:
            fatalError(.unimplemented)
        case .applyStash:
            fatalError(.unimplemented)
        case .discardAll:
            await discardAllTapped()
        case .addCustom:
            fatalError(.unimplemented)
        }
    }

    func trackAllTapped() async {
        await stageOrUnstageTapped(stage: true, deltaInfos: untrackedDeltaInfos)
    }

    func trackTapped(stage: Bool, deltaInfos: [DeltaInfo]) async {
        await stageOrUnstageTapped(stage: true, deltaInfos: deltaInfos)
    }

    func stageOrUnstageTapped(stage: Bool) async {
        if stage {
            await stageOrUnstageTapped(stage: stage, deltaInfos: unstagedDeltaInfos)
        } else {
            await stageOrUnstageTapped(stage: stage, deltaInfos: stagedDeltaInfos)
        }
    }
    
    func stageOrUnstageTapped(stage: Bool, deltaInfos: [DeltaInfo]) async {
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

    func stageAllTapped() async {
        repository.stage(path: ".").mustSucceed()
    }

    @discardableResult
    func commitTapped() async -> Commit {
        let commit: Commit = repository.commit(message: commitSummary).mustSucceed()
        commitSummary = ""
        return commit
    }

    func splitAndCommitTapped() async -> Commit {
        fatalError(.unimplemented)
    }

    func amendTapped() async {
        let headCommit: Commit = repository.commit().mustSucceed()
        var newMessage = commitSummary
        if newMessage.isEmptyOrWhitespace {
            newMessage = headCommit.summary
        }

        guard !newMessage.isEmptyOrWhitespace else {
            fatalError(.unsupported)
        }
        repository.amend(message: newMessage).mustSucceed()
        commitSummary = ""
    }

    func ignoreTapped(deltaInfo: DeltaInfo) async {
        guard let path = deltaInfo.newFilePath else {
            fatalError(.illegal)
        }
        repository.ignore(path)
    }

    func discardTapped(deltaInfo: DeltaInfo) async {
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
        for fileURL in fileURLs {
            if fileURL.isDirectory {
                RepoManager().git(repository, ["restore", fileURL.appendingPathComponent("*").path])
            } else {
                RepoManager().git(repository, ["restore", fileURL.path])
            }
        }
    }
    
    func discardAlertTitle(deltaInfo: DeltaInfo) -> String {
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

    func discardAllTapped() async {
        RepoManager().git(repository, ["add", "."])
        RepoManager().git(repository, ["reset", "--hard"])
    }

    func setInitialSelection() {
        if currentDeltaInfo == nil {
            var item: DeltaInfo?
            if let firstItem = stagedDeltaInfos.first {
                item = firstItem
            } else if let firstItem = unstagedDeltaInfos.first {
                item = firstItem
            } else if let firstItem = untrackedDeltaInfos.first {
                item = firstItem
            }
            if let item {
                currentDeltaInfo = item
            }
        }
    }

    var hasChanges: Bool {
        !stagedDeltaInfos.isEmpty ||
        !unstagedDeltaInfos.isEmpty ||
        !untrackedDeltaInfos.isEmpty
    }
}
