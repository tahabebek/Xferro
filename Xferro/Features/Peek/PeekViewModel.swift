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
            lhs.id == rhs.id
        }

        var id: String {
            hunks.map(\.id).joined(separator: ",") + deltaInfo.id
        }
        let deltaInfo: DeltaInfo
        let hunks: [DiffHunk]
        init(hunks: [DiffHunk], deltaInfo: DeltaInfo) {
            self.hunks = hunks
            self.deltaInfo = deltaInfo
        }
    }

    var hunks: Hunks?
    var isStaged: Bool = false
    var selectableItem: (any SelectableItem)?
    
    // Returns whether any lines are currently selected
    var hasSelectedLines: Bool {
        guard let hunks = hunks?.hunks else { return false }
        return hunks.contains { hunk in
            hunk.parts.contains { part in
                part.lines.contains { line in
                    line.isSelected && line.isAdditionOrDeletion
                }
            }
        }
    }

    init(selectableItem: any SelectableItem, deltaInfo: DeltaInfo) {
        let patchMaker: PatchMaker?
        self.isStaged = deltaInfo.type == .staged
        self.selectableItem = selectableItem
        switch selectableItem {
        case let item as SelectableStatus:
            if self.isStaged {
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
            hunks = Hunks(hunks: newHunks, deltaInfo: deltaInfo)
        } else {
            hunks = nil
        }
    }
    
    // Stage selected lines
    func stageSelectedLines() -> Bool {
        guard let hunksData = hunks, 
              let item = selectableItem as? SelectableStatus,
              !isStaged else { return false }
        
        let deltaInfo = hunksData.deltaInfo
        
        // Create a patch from selected lines (simplified)
        // In a real implementation, you'd create a proper git patch
        let selectedHunks = hunksData.hunks.filter { hunk in
            hunk.parts.contains { part in
                part.lines.contains { $0.isSelected && $0.isAdditionOrDeletion }
            }
        }
        
        if selectedHunks.isEmpty { return false }
        
        // This would typically use a partial application of patch
        // For now, we're just staging the whole file as a simplification
        if let path = deltaInfo.newFilePath ?? deltaInfo.oldFilePath {
            return item.repository.stage(path: path).isSuccess
        }
        
        return false
    }
    
    // Unstage selected lines
    func unstageSelectedLines() -> Bool {
        guard let hunksData = hunks, 
              let item = selectableItem as? SelectableStatus,
              isStaged else { return false }
        
        let deltaInfo = hunksData.deltaInfo
        
        // Same simplification - in a real implementation you'd apply a partial patch
        if let path = deltaInfo.newFilePath ?? deltaInfo.oldFilePath {
            return item.repository.unstage(path: path).isSuccess
        }
        
        return false
    }
    
    // Discard selected lines
    func discardSelectedLines() -> Bool {
        guard let hunksData = hunks, 
              let item = selectableItem as? SelectableStatus else { return false }
        
        let deltaInfo = hunksData.deltaInfo
        
        // For discard, we need to get the file and modify it
        // This is a simplified version that discards the whole file
        if let fileURL = deltaInfo.newFileURL ?? deltaInfo.oldFileURL {
            let manager = RepoManager()
            manager.git(item.repository, ["restore", fileURL.path])
            return true
        }
        
        return false
    }
}
