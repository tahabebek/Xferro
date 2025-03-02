//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

enum HunkFactory {
    static func makeHunks(selectableItem: (any SelectableItem)?, deltaInfo: DeltaInfo?) -> ([DiffHunk], Int, Int) {
        guard let selectableItem, let deltaInfo else {
            return ([], 0, 0)
        }
        let patchMaker: PatchMaker?
        let isStaged = deltaInfo.type == .staged
        switch selectableItem {
        case let item as SelectableStatus:
            if isStaged {
                patchMaker = item.repository.stagedDiff(
                    head: item.head,
                    deltaInfo: deltaInfo
                )?.patchMaker
            } else {
                patchMaker = item.repository.unstagedDiff(
                    head: item.head,
                    deltaInfo: deltaInfo
                )?.patchMaker
            }
        case let item as SelectableCommit:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.commit.parents.first?.oid
            )?.patchMaker
        case let item as SelectableWipCommit:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.head.oid
            )?.patchMaker
        case let item as SelectableHistoryCommit:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.head.oid
            )?.patchMaker
        case let item as SelectableDetachedCommit:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.head.oid
            )?.patchMaker
        case let item as SelectableDetachedTag:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.head.oid
            )?.patchMaker
        case let item as SelectableTag:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.head.oid
            )?.patchMaker
        case let item as SelectableStash:
            patchMaker = item.repository.diffMaker(
                deltaInfo: deltaInfo,
                commitOID: item.oid,
                parentOID: item.head.oid
            )?.patchMaker
        default:
            fatalError()
        }
        let patch = patchMaker?.makePatch()
        if let patch {
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
            return (newHunks, patch.addedLinesCount, patch.deletedLinesCount)
        } else {
            return ([], 0, 0)
        }
    }
}
