//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

extension StatusViewModel {
    func peekInfo(for deltaInfo: DeltaInfo, repository: Repository, head: Head) async -> PeekViewModel {
        let isStaged = deltaInfo.type == .staged
        let patchResult: PatchMaker.PatchResult = if isStaged {
            repository.stagedDiff(
                head: head,
                deltaInfo: deltaInfo
            )
        } else {
            repository.unstagedDiff(
                head: head,
                deltaInfo: deltaInfo
            )
        }

        switch patchResult {
        case .noDifference:
            return PeekViewModel(type: .noDifference(statusFileName: deltaInfo.statusFileName))
        case .binary:
            return PeekViewModel(type: .binary(statusFileName: deltaInfo.statusFileName))
        case .diff(let patchMaker):
            let patch = patchMaker.makePatch()
            var newHunks = [DiffHunk]()
            let hunkCount = patch.hunkCount
            for index in 0..<hunkCount {
                if let hunk = patch.hunk(
                    at: index,
                    delta: deltaInfo.delta,
                    type: deltaInfo.type,
                    repository: deltaInfo.repository
                ) {
                    newHunks.append(hunk)
                }
            }
            return PeekViewModel(type: .diff(DiffViewModel(
                hunks: newHunks,
                addedLinesCount: patch.addedLinesCount,
                deletedLinesCount: patch.deletedLinesCount,
                statusFileName: deltaInfo.statusFileName)
            ))
        }
    }
}
