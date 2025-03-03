//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

extension StatusViewModel {
    func peekInfo(for deltaInfo: DeltaInfo) -> PeekInfo {
        let patchMaker: PatchMaker
        let isStaged = deltaInfo.type == .staged
        let patchResult: PatchMaker.PatchResult = if isStaged {
            selectableStatus.repository.stagedDiff(
                head: selectableStatus.head,
                deltaInfo: deltaInfo
            )
        } else {
            selectableStatus.repository.unstagedDiff(
                head: selectableStatus.head,
                deltaInfo: deltaInfo
            )
        }

        switch patchResult {
        case .noDifference:
            return PeekInfo(type: .noDifference(statusFileName: deltaInfo.statusFileName))
        case .binary:
            return PeekInfo(type: .binary(statusFileName: deltaInfo.statusFileName))
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
            return PeekInfo(type: .diff(PeekInfo.Diff(
                hunks: newHunks,
                addedLinesCount: patch.addedLinesCount,
                deletedLinesCount: patch.deletedLinesCount,
                statusFileName: deltaInfo.statusFileName)
            ))
        }
    }
}
