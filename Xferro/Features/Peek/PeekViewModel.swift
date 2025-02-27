//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

@Observable class PeekViewModel {
    struct Hunks: Equatable, Identifiable {
        static func == (lhs: PeekViewModel.Hunks, rhs: PeekViewModel.Hunks) -> Bool {
            print(lhs.id)
            print(rhs.id)
            let result = lhs.id == rhs.id
            print(result)
            return result
        }

        var id: String {
            hunks.map(\.id).joined(separator: ",") + deltaInfo.id + randomValue.formatted()
        }
        let randomValue: CGFloat
        let deltaInfo: DeltaInfo
        let hunks: [DiffHunk]
        init(hunks: [DiffHunk], deltaInfo: DeltaInfo, randomValue: CGFloat) {
            self.hunks = hunks
            self.deltaInfo = deltaInfo
            self.randomValue = randomValue
        }
    }

    var hunks: Hunks?
    var randomValue: CGFloat = 1.0 / CGFloat.random(in: 1000..<10000)

    init(selectableItem: any SelectableItem, deltaInfo: DeltaInfo) {
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
                if let hunk = patch.hunk(at: index) {
                    newHunks.append(hunk)
                }
            }
            randomValue = 1.0 / CGFloat.random(in: 1000..<10000)
            hunks = Hunks(hunks: newHunks, deltaInfo: deltaInfo, randomValue: randomValue)
        } else {
            hunks = nil
        }
    }
}
