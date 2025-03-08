//
//  DeltaInfo+DiffInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

extension DeltaInfo {
    func setDiffInfo(head: Head) async {
        let isStaged = type == .staged
        let patchResult: PatchMaker.PatchResult = if isStaged {
            repository.stagedDiff(
                head: head,
                deltaInfo: self
            )
        } else {
            repository.unstagedDiff(
                head: head,
                deltaInfo: self
            )
        }

        switch patchResult {
        case .noDifference:
            diffInfo = NoDiffInfo(statusFileName: statusFileName)
        case .binary:
            diffInfo = BinaryDiffInfo(statusFileName: statusFileName)
        case .diff(let patchMaker):
            let patch = patchMaker.makePatch()
            var newHunks = [DiffHunk]()
            let hunkCount = patch.hunkCount
            for index in 0..<hunkCount {
                if let hunk = patch.hunk(
                    at: index,
                    delta: delta,
                    type: type,
                    repository: repository
                ) {
                    newHunks.append(hunk)
                }
            }
            diffInfo = DiffInfo(
                hunks: newHunks,
                addedLinesCount: patch.addedLinesCount,
                deletedLinesCount: patch.deletedLinesCount,
                statusFileName: statusFileName)
        }
    }
}
