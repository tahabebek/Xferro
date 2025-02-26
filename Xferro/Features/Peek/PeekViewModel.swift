//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

@Observable final class PeekViewModel {
    struct PeekInfo {
        var selectableItem: any SelectableItem
        var deltaInfo: DeltaInfo
    }
    var patch: Patch?
    
    @ObservationIgnored var peekInfo: PeekInfo? {
        didSet {
            let patchMaker: PatchMaker?
            if let peekInfo, let filePath = peekInfo.deltaInfo.newFilePath ?? peekInfo.deltaInfo.oldFilePath {
                switch peekInfo.selectableItem {
                case let item as SelectableStatus:
                    patchMaker = item.repository.stagedDiff(head: item.head, file: filePath)?.patchMaker
                case let item as SelectableCommit:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.commit.parents.first?.oid
                    )?.patchMaker
                case let item as SelectableWipCommit:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.head.oid
                    )?.patchMaker
                case let item as SelectableHistoryCommit:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.head.oid
                    )?.patchMaker
                case let item as SelectableDetachedCommit:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.head.oid
                    )?.patchMaker
                case let item as SelectableDetachedTag:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.head.oid
                    )?.patchMaker
                case let item as SelectableTag:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.head.oid
                    )?.patchMaker
                case let item as SelectableStash:
                    patchMaker = item.repository.diffMaker(
                        forFile: filePath,
                        commitOID: item.oid,
                        parentOID: item.head.oid
                    )?.patchMaker
                default:
                    fatalError()
                }
            } else {
                patchMaker = nil
            }
            self.patch = patchMaker?.makePatch()
        }
    }

    init(peekInfo: PeekInfo?) {
        self.peekInfo = peekInfo
    }
}
