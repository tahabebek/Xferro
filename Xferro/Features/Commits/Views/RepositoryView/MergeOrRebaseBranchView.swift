//
//  MergeOrRebaseBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import SwiftUI

struct MergeOrRebaseBranchView: View {
    @Binding var mergeOrRebaseSourceBranch: String
    @Binding var mergeOrRebaseTargetBranch: String

    let localBranches: [String]

    var body: some View {
        VStack(alignment: .leading) {
            sourceBranchView
            targetBranchView
        }
    }

    var sourceBranchView: some View {
        SearchablePickerView(
            items: localBranches,
            selectedItem: $mergeOrRebaseSourceBranch,
            title: "Source Branch:"
        )
        .padding(.leading, 8)
        .padding(.bottom)
    }

    var targetBranchView: some View {
        SearchablePickerView(
            items: localBranches,
            selectedItem: $mergeOrRebaseTargetBranch,
            title: "Destination Branch:"
        )
        .padding(.leading, 8)
        .padding(.bottom)
    }
}
