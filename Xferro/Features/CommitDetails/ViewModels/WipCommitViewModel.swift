//
//  WipCommitViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Observation
import OrderedCollections

@Observable final class WipCommitViewModel {
    var files: [OldNewFile] = []
    var selectableWipCommit: SelectableWipCommit?
    var currentFile: OldNewFile? = nil
    var repositoryInfo: RepositoryInfo?
    private var unsortedFiles: OrderedDictionary<String, OldNewFile> = [:] {
        didSet {
            files = Array(unsortedFiles.values.elements).sorted { $0.statusFileName < $1.statusFileName }
        }
    }

    func updateStatus(
        newSelectableWipCommit: SelectableWipCommit,
        repositoryInfo: RepositoryInfo?
    ) {
        currentFile = nil
        guard let repositoryInfo else { return }
        guard newSelectableWipCommit.repositoryId == repositoryInfo.repository.idOfRepo else {
            fatalError(.invalid)
        }

        Task {
            let files = await getFilesComparedFromOwnerToWip(
                repository: repositoryInfo.repository,
                newSelectableStatus: newSelectableWipCommit,
                head: repositoryInfo.head
            )
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.unsortedFiles = files
                self.repositoryInfo = repositoryInfo
                self.selectableWipCommit = newSelectableWipCommit
                self.setInitialSelection()
            }
        }
    }

    // if a file is in wip but not in owner, it will look like an addition
    private func getFilesComparedFromOwnerToWip(
        repository: Repository,
        newSelectableStatus: SelectableWipCommit,
        head: Head
    ) async -> OrderedDictionary<String, OldNewFile> {
        var files: OrderedDictionary<String, OldNewFile> = [:]
        let owner = newSelectableStatus.owner
        let diff: Diff = repository.diff(
            from: owner.oid,
            to: newSelectableStatus.commit.oid
        ).mustSucceed(repository.gitDir)
        
        for delta in diff.deltas {
            let key = (delta.oldFilePath ?? "") + (delta.newFilePath ?? "")
            let file = OldNewFile(
                old: delta.oldFilePath,
                new: delta.newFilePath,
                status: delta.status,
                repository: repository,
                head: head,
                key: key
            )
            await file
                .setDiffInfoComparedToOwner(
                    commit: newSelectableStatus.commit,
                    owner: newSelectableStatus.owner
                )
            files[key] = file
        }

        return files
    }

    func actionTapped(_ action: WipCommitActionButtonsView.BoxAction) async throws {
    }

    func setInitialSelection() {
        if currentFile == nil {
            if let firstItem = files.first {
                currentFile = firstItem
            }
        }
    }
}
