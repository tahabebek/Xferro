//
//  BranchViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/2/25.
//

import Foundation
import Observation

@Observable final class BranchViewModel {
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?
    let onDeleteBranchTapped: ((String) -> Void)?
    let onIsCurrentBranch: ((Branch, Head) -> Bool)?

    init(
        onUserTapped: ((any SelectableItem) -> Void)?,
        onIsSelected: ((any SelectableItem) -> Bool)?,
        onDeleteBranchTapped: ((String) -> Void)?,
        onIsCurrentBranch: ((Branch, Head) -> Bool)?
    )
    {
        self.onUserTapped = onUserTapped
        self.onIsSelected = onIsSelected
        self.onDeleteBranchTapped = onDeleteBranchTapped
        self.onIsCurrentBranch = onIsCurrentBranch
    }
}
